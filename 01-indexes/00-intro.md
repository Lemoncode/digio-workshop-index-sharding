# Indices

## Para que sirven

Los índices en Mongo nos permiten hacer que una consulta tarde menos en ejecutarse, a cambio de que la inserción / actualización de datos sea más lenta.

Esto empieza a traer cuenta cuando tenemos colecciones grandes y consultas que se usan mucho y tardan en ejecutarse.

Primeras reglas de perogrullo cuando me planteo usar un índice:

- ¿Hay muchos datos?
- ¿Hay consultas que se usan mucho y tardan en ejecutarse? Es decir una consulta que tira un administrador de vez en cuando no nos debería de preocupar mucho.
- ¿Cuanto estoy escribiendo datos?

## ¿Cómo funcionan?

Cuando pensamos en un índice podemos pensar en un libro, la tabla de índice del final en la que podemos buscar por palabras clave y nos dice en que página está esa palabra.

Es decir si quiero buscar una palabra mejor que ir página por página, me voy a buscar en la parte de atrás y tardo menos, es decir:

- Si no utilizo el indice tendría que ir pagina por pagina buscando, eso es lo que en Mongo lo llamamos hacer un _collection scan_ (COLLSCAN).
- Si utilizo el indice, voy a la parte de atrás y me salto todas las páginas que no me interesan, esto es mucho más rápido es lo que en Mongo llamamos un _index scan_ (IXSCAN), pero ojo:
  - Estoy pagando el pato de _añadir páginas al libro_
  - Si el libro fuera online y estuviera vivo (el autor lo va actualizando), tendría que ir recalculando el índice cada vez que introdujera nuevas páginas (esto es lo que en Mongo se llama _reindexing_), y esto tiene un coste, lo podemos comparar con cuando un usuario introduce e

Los índices en Mongo son como un árbol binario, donde cada nodo es un documento de la colección.

¿Se puede usar más de un índice en una consulta?

- MongoDB soporta los XXXX en una consulta, pero normalmente no los usa ya que da peor rendimiento que un indice compuesto.

- Lo normal es que se use un sólo indice, a ser que tengamos una consulta con un OR que puede usar más de uno.

¿Los Indices son siempre igual de efectivos? No, si hacemos un matching exacto el índice es más efectivo que si hacemos una consulta por rango.

Que campos, no tiene sentido un indi e en un booleano por ejemplo

## Tipos de indices

Para empezar MongoDB nos crea un índice por cada campo **\_id**, así que ese campo ya lo tenemos cubierto.

Después podemos crear indices:

- Simples: Un índice que solo tiene un campo (por ejemplo el campo nombre de cliente).
- Compuestos: Un índice que tiene varios campos (por ejemplo el campo nombre de cliente y el edad).

# Indices simples

Consultas normales sin indices:

Una que consulte por un año de pelicula

Otra que consulte por un rango de años

Otra que ordene por año

Explicar aquí constraint indice _unique_ true:

https://learn.mongodb.com/learn/course/mongodb-indexes/lesson-2-creating-a-single-field-index-in-mongodb/learn

Minuto 2:09

Si voy a insertar algo duplicado pega un castañazo

Vamos a por el _Explain_ commando o _mongo compass_

Explain --> Winning plan es el plan que gano, Mongo se puede plantear varios planes y el que gana es el que mejor rendimiento tiene.

¿Puedo yo elegir el plan que quiero que se ejecute? Le puedes dar "pistas" hint... pero salvo que pilotes un huevo mejor deja a Mongo que es "muy listo"

Veamos una query:

Fetch stage (sólo lee los documentos que el índice a identificado)
IXScan

---

Aquí ordenamos por fecha nacimiento y ordenamos por email
¿Qué pasa aquí que sólo pilalría el indice de fecha de nacimiento?... nos van haciendo falta indices compuestos

Aquí habría que tener en cuenta la parte de rejected plan y ver que miro el indice de sort

---

Probar una con COLLSCAN otro campo

# Multikey index, array fields in index

Podemos indexar primitivas, subdomcumentos,subarrays

Solo podemos indicar un campo del array por indice,
es decir si un indice esta compuesto por multiples campos solo uno de ellos puede ser un array (esto tenemos que probarlo).

Internamente cuando mongo se encuentre un campo array en un indice lo descompone y crea un indica por cada valor encontrar como un indice individual.

Si creamos un indice en un campo array (vamos a por uno que sea simple), fiujate
que en el explain, winnning plan nos dice

```
isMultikey: true,
multiKeyPaths: {accounts: ['accounts']}
```

¿Qué pasa si son subdocumentos? Tenemos que probarlo

# Indices compuestos

Indice en multiples fichero, admite muli key (arrays) pero como comentamos un sólo un campo array por índice

Ejercicio,

Indice por tres campos

Ver que puedo si tengo

active, birthdate, name

que por querty por active y birthdate aprovecha el indice

y si es active solo tb

y si es birthdate no

Y si sort active?

probar una query parcial y tb probar a mover campos y que mongo reordena

Orden para indices (ojo ejercicios):

- ESR:
  - Primero equality (reduce query time y menos documentos va a al grano)
  - Despues sort (si lo tenemos bien montado el sort no lo hace en memoria, eso es importante)
  - Despues comparación de rango (aquí es mejor que el rango esta al final para evitar in memory sort)

Ojo aquí el sort order importantes,

https://learn.mongodb.com/learn/course/mongodb-indexes/lesson-4-working-with-compound-indexes-in-mongodb/learn?page=1

Tercer video (3:35), muy interesante el explain, te dice que tira del scan
tira de un indice simple, hace un fetch y un filter, y despues el stage: sort, lo hace en memoria (memLimit)

Si creamos el ornde e equality, y sortm ,ojo y descending y ascending

Jugar despues con los ordenes si lo invertimos va, pero si los bailmos (los dos 1), seguramente lo haga todo en memoria

Probamos uno exacto, fijate uqe no hay sort

por otro lado hacemo fetch para leer los documentos completos, pero si el indice tuveria esos cmapos directamente se podrían servir del indice, si lo devolvemos los campos del indice (proyección)

Ahora en vez de FETCH tenemos 'PROJECTION_COVERED', no hay fetch

# Borrando inidices

HideIndex, el indice se sigue actualizando pero no se usa en las queries

# Otro indices

TTL indexes

Text Indexes

# ATLAS

El index advisor

Las busquedas de texto con ATLAS
