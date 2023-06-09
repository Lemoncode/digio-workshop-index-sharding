# Queries agregadas

Las consultas agregadas son muy potentes, pero en el mundo real se pueden convertir en un infierno de rendimiento.

Hay ciertos sitios donde se puede tocar para que vayan mejor, pero si al final quieres manipular millones de registros, por mucho que optimices esas consultas van a ir lentas.

Aggregation optiomization
https://www.mongodb.com/docs/manual/reference/operator/aggregation/project/

## Consejos

¿Qué podemos hacer para mejorar el rendimiento de las consultas agregadas?

1. $match lánzalo cuanto antes así se reduce el número de documentos que se van a procesar

2. $lookup este es un matador de rendimiento, si estás usando $lookup:

- Plantéate si has modelado bien tu base de datos documental.
- Llevátelo lo más adelante que puedas en la consulta, sobre todo después de filtrar.
- Crea índices sobre los campos que se usan en el $lookup

3. $project llevátelo al final de la consulta, y solo los campos que necesites, ojo que si te pones a crear campos custom puede que ya no puedas utilizar índices en la colección.

4. Ojo cuando hagas un group by se acabo lo que se daba de usar indices etc...

5. $limit o $skip, ejecútalo lo antes posible en la consulta (siempre que no te altere los resultados)

## Optimizador de consultas agregadas

Todo lo que hemos dicho está muy bien, pero si lanzamos la siguiente consulta:

Y después lo cambiamos para que vaya mal:

Nos da el mismo resultado ¿Qué ha pasado aquí?

Pues que MongoDb trae un optimizador de consultas agregadas, que se encarga de reordenar las etapas de la consulta para que vaya lo más rápido posible.

Mira este post oficial sobre el [optimizador de consultas agregadas](https://www.mongodb.com/docs/manual/core/aggregation-pipeline-optimization/)

# Ejemplos 1 - ¿Buenas prácticas o optimizer?

Vamos a pedir en una consulta agregada, las películas que se estrenaron en el año 2014, vamos a realizar un _$project_ con un campo calculado, y vamos a añadir después un adicional .

Vamos a hacerlo bien (el $match primero).

```mql
use("mymovies");

db.movies
 .aggregate([
  {$match: {year: 2014, countries: "Spain"}},
  {$project: {title: 1, year: 1, countries: 1,
    avgYear: {$avg: ["$duration", "$year"]}}},
 ], {explain: true})
```

Vamos a ver el query planner, _parsedQuery_ y _executionMillis_

Vamos a hacerlo _mal_ (el $match de paises después).

```mql
use("mymovies");

db.movies
 .aggregate([
  {$match: {year: 2014}},
  {$project: {title: 1, year: 1, countries: 1,
    avgYear: {$avg: ["$duration", "$year"]}}},

  {$match: { countries: "Spain"} }
 ], {explain: true})
```

Vamos a ver el query planner, _parsedQuery_ y _executionMillis_ (puede que incluso exection millis sea más bajo porque ya está precalenteada la caché)

Vemos que da igual que en la query pongamos el $match antes o después, el optimizer se encarga de reordenar las etapas para que vaya lo más rápido posible.

Y vamos a darle una vuelta de tuerca más, vamos forzar un match contra el campo calculado:

```mql
use("mymovies");

db.movies
 .aggregate([
  {$match: {year: 2014}},
  {$project: {title: 1, year: 1, countries: 1,
    avgYear: {$avg: ["$duration", "$year"]}}},

  {$match: { countries: "Spain", avgYear: 2014} }
 ], {explain: true})
```

Aquí sube la parte del match de _countries_

## Ejemplo 2 - El $lookup de la muerte

Resulta que en la base de datos de movies, tenemos una colección de películas y otra de comentarios de películas,... sería buena idea mostrar las películas y sus comentarios... nada malo puede pasar ¿Verdad? probemos la siguiente consulta agregada:

```
use("mymovies")

db.movies.aggregate([
  {
    $lookup: {
      from: "comments",
      localField: "_id",
      foreignField: "movie_id",
      as: "comentarios",
    },
  },
  {
  $project: {
    title: 1,
    comentarios: 1,
    year: 1,
  },
  },
  {
    $addFields: {
    count: { $size: "$comentarios" },
    },
  },
  {
    $match: {
     count: { $gt: 0 },
    },
  },
 ]).explain("executionStats")
```

Vamos a ejecutar la consulta y a ver que pasa:

La consulta, con el explain, se queda colgada, y no termina nunca.

Si queremos ver algo de info, una opción es en el match poner un filtro, por ejemplo, que sea del año 1980:

```diff
  {
    $match: {
+     year: 1980,
     count: { $gt: 0 },
    },
  },
```

Fijate que curioso, que el optimizador de consultas sube _year_ arriba.

Y mira aquí en el stage del _$lookup_ el _totalDocsExamined_ ¿8 millones de documentos :-@?

```js
    {
      "$lookup": {
        "from": "comments",
        "as": "comentarios",
        "localField": "_id",
        "foreignField": "movie_id"
      },
      "totalDocsExamined": 8853328,
```

¿Qué problema hay aquí? El lookup es muy costoso, por cada película se pone a buscar los comentarios, y lo hace realizando un collscan por cada una de ellas, es decir en comentarios tenemos, que hay más de 50K comentarios.

¿Qué podemos hacer para mejorar el rendimiento? Fíjate que el lookup va de

movies.\_id --> comments.movie_id

¿Y si pusiéramos un índice en _movie_id_ en la coleccion de comments?

```mql
db.comments.createIndex({ movie_id: 1 });
```

Vamos probar de nuevo:

- Vemos que se ejecuta como un tiro.
- Si lanzamos un explain("executionStats"), podemos ver que se usa el índice que hemos creado.

Con esto hemos salvado la bala, pero... si esta consulta es importante, esto se podría haber resuelto en fase de modelado:

- Podríamos haber usado el _computed pattern_ y tener precalculado cuantos comentarios tienen una película (así podemos hacer un match temprano filtrando las películas que tienen comentarios).
- Si queremos mostrar los _n_ primero comentarios de un grupo de películas, podríamos haber utilizado el _subset_ pattern y haber almacenado los _n_ primeros, o _n_ comentarios más importantes en la propia colección de películas (Después si hacen falta todos ya los leemos de una película en concreto).
- Otro tema importante hubiera sido filtrar... ¿Realmente necesitamos tirar la consulta contra toooodas las películas de la colección?

## Ejemplo 3 - El $lookup de la muerte (II)

Vamos a seguir dándole cariño a la consulta de comentarios, indicamos que lo normal es filtrar por un criterio, por ejemplo dame los comentarios asociados a las películas que se estrenaron en un año dado.

```mql
use("mymovies")

db.movies.aggregate([
  {
    $match: {
      year: 2015 ,
    }
  },
  {
    $lookup: {
      from: "comments",
      localField: "_id",
      foreignField: "movie_id",
      as: "comentarios",
    },
  },
  {
  $project: {
    title: 1,
    comentarios: 1,
    year: 1,
  },
  },
  {
    $addFields: {
    count: { $size: "$comentarios" },
    },
  },
  {
    $match: {
     count: { $gt: 0 },
    },
  },
 ]).explain("executionStats")
```

> Apuntamos milisegundos e indices

Si lanzamos la consulta vemos que usamos el índice de comentarios, pero para filtrar por año vamos a pico y pala (COLLSCAN), ¿Qué pasa si creamos un indice por año? ¿Qué creeis que va a pasar?

A. Que se usa el indice de años como ganador y se descarta el de comentarios.
B. Que se usa el indice de comentarios y se descarta el de año
C. Que se usan los dos indices

Vamos a crear el indice:

```mql
db.movies.createIndex({ year: 1 });
```

Y volvemos a lanzar la consulta.

Podemos ver que ha bajado el tiempo, y ¡ utiliza los dos índices ! (indexesUsed, en executionStats)

# Más temas a tener en cuenta

- Cuando lanzamos consultas agregadas que mueven muchos datos (limite de 100 Mb), el servidor puede devolver un error de memoria, para evitar esto, podemos usar el parámetro _allowDiskUse_ que permite que se escriban los datos en disco (ojo qu hay operadores que no lo soportan, addToSet, push...), aunque lo normal es que esto sea un _mal olor_ (** comprobar mongo oficial**).

- Cuidado que los indices se pueden perder cuando usamos $project, $group, $unwind, así que antes usemos lo que tenga indices (match, sorting...) y después usemos $project

- Una vez que hemos hecho el match, utilicemos $project para reducir al mínimo el número de campos que vayan a pasar por la tuberia.

# Material

Enlaces de interés:

- [Cómo funciona el optimizador de consulta de MongoDB](https://www.mongodb.com/docs/manual/core/aggregation-pipeline-optimization/)

- [La importancia del modelado en Mongo (foro y empleado de MongoDB contestando)](https://www.mongodb.com/community/forums/t/multiple-lookup-in-aggregate/109436)

- [Mongo Optimization tips](https://www.youtube.com/watch?v=trEGalB0EZM&ab_channel=codedamn)

- [Pipeline performance considerations](https://www.practical-mongodb-aggregations.com/guides/performance.html)

- [Caso real interesante](https://stackoverflow.com/questions/62368259/mongo-aggregate-query-optimization)
