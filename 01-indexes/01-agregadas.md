# Queries agregadas

Aggregation optiomization
https://www.mongodb.com/docs/manual/reference/operator/aggregation/project/

## Consejos

1. Project al final??

2. $lookup, lo más tarde posible, antes filtrar

3. Sorting antes del group (después del group no se puede usar indices)

4. Limit si lo podemos usar antes

5. $skip cuanto antes

# A base de ejemplos

# Look up rendimiento

Vamos a hacer ahora un consulta en la que vamos a hacer un lookup, y vamos a ver que pasa con el rendimiento, y como podemos mejorarlo.

Esta sería la consulta:

```mql
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

Vamos a ejecutar la query y a ver que pasa:

\*\* Pantallazo stats si encuentras campo que diga COLLSCAN o similar, aquí por lop menos poner miliseconds

Comenta que el problema esta en que:

1. En este caso, es un problema que se podía haber arreglado en fase de modelado, agregando un campo calculado comentarios (true/false) en la colección de movies, y así no tener que hacer el lookup.
2. Al hacer un lookup estamos recorriendo sobre campo movie_id de comment y tenemos un _collscan_ en comments, que es lo que nos esta matando el rendimiento.
3. Que podemos hacer: vamos a probar crear un índice en la colección de comments, sobre el campo movie_id, y vamos a ver que pasa.

```mql
db.comments.createIndex({ movie_id: 1 });
```

Volvemos a ejecutar la query y vemos que pasa:

Y poner useIndex y Miliseconds

*** 

Siguiente ejemplo una consulta con dos lookups, sin indices poner dos indices y ver si se usan los indices

## Project al final

\_\_ Decir que mymovies

Primera consulta

```mql
use("mymovies")

db.movies
 .aggregate([
 { $match: { countries: "Spain" } },
 { $project: { title: 1, countries: 1 } },
 ]).explain("executionStats")
```

Cpomentar COLLSCAN, tiempo ejecucion, etc...

Creamos un indice por countries

\_\_\_Comando aqui ( mongo compass)

Vemos que se usa

Cambiamos el orden

```
use("mymovies")

db.movies
 .aggregate([
 { $project: { title: 1, countries: 1 } },
 { $match: { countries: "Spain" } },
 ]).explain("executionStats")
```

Comentar que no se usa el indice !! NOPES

--> Braulio ver mejoras project en versiones modernas

# Material

Material interesante: https://medium.com/mongodb-performance-tuning/optimizing-the-order-of-aggregation-pipelines-44c7e3f4d5dd

https://medium.com/@abhidas/improving-the-performance-of-mongodb-aggregation-d223a2b19f11

https://www.practical-mongodb-aggregations.com/guides/performance.html

Db Koda

https://www.dbkoda.com/aggregation

Optimizaciones automáticas

https://www.xuchao.org/docs/mongodb/core/aggregation-pipeline-optimization.html

Muy bueno este caso real

https://stackoverflow.com/questions/62368259/mongo-aggregate-query-optimization

Este es mas normalito

http://oracleappshelp.com/mongodb-aggregation-pipeline-optimization/

Este se ve raro

https://github.com/mongodb/docs/blob/master/source/core/aggregation-pipeline-optimization.txt
