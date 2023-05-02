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

## Project al final

__ Decir que mymovies

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

___Comando aqui ( mongo compass)

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
