# 04 Non empty sharding collection

Vamos a crear sharded collections de colecciones que ya tienen datos. Partimos del ejemplo anterior _03-sharding-collection_.

Para ello ejecutamos:

```bash
npm install

```

Arrancamos el proyecto con:

```bash
npm start

```

> Este comando también arranca `docker-compose` en paralelo.

Y si aún no lo has ejecutado, inicializa el sharded cluster:

```bash
sh init-sharded-cluster.sh

```

Nos conectamos antes al router para borrar la colección de movies:

```bash
docker exec -it mongos-router mongosh

```

```mongosh
db.movies.drop();

```

# Ranged sharding

En muchos proyectos reales, lo más normal es tener ya una base de datos con todos los datos de nuestra aplicación, y aplicar el sharding a posteriori.
Vamos a recuperar la colección de clientes:

_./src/index.ts_

```diff
import './load-env.js';
import { MongoClient } from 'mongodb';
import { envConstants } from './env.constants.js';

const client = new MongoClient(envConstants.MONGODB_URI);

const db = client.db();

+ await db.collection('clients').insertMany([
+   {
+     name: 'Carmen Puertos',
+     city: 'Málaga',
+     zipCode: '29003',
+   },
+   {
+     name: 'Antonio Marquez',
+     city: 'Málaga',
+     zipCode: '29010',
+   },
+   {
+     name: 'Isidoro Rodriguez',
+     city: 'Málaga',
+     zipCode: '29009',
+   },
+ ]);

- const count = await db.collection('movies').countDocuments();
+ const count = await db.collection('clients').countDocuments();
console.log({ count });

```

Lanzamos la aplicación:

```bash
npm start

```

Si ahora intentamos ver el estados del sharding sobre esta colección

```mongosh
docker exec -it mongos-router mongosh

use my-db

db.clients.getShardDistribution();

```

> Error: `Collection movies is not sharded`
> Como vemos podemos guardar datos de una colección que no tiene habilitado el sharding en un sharded cluster.

Vamos a intentar habilitar el sharding de la colección `clients`:

```mongosh
sh.shardCollection("my-db.clients", { "zipCode": 1 })

```

Al contener ya datos, te lanza un error para que te encargues de crear un índice para ese campo: `MongoServerError: Please create an index that starts with the proposed shard key before sharding the collection`:

```mongosh
db.clients.createIndex({ "zipCode": 1 });

```

> Ojo que el índice también lo tenemos que crear de tipo `ranged`, si fuese `hashed`, aquí tendría el valor `hash`.

Ahora si habilitamos el sharding:

```mongosh
sh.shardCollection("my-db.clients", { "zipCode": 1 })

```

Y comprobamos la distribución de esta colección:

```mongosh
db.clients.getShardDistribution()
sh.status()

```

Vemos que en este caso se han ido todos los documentos al shard primario de la base de datos, (en mi caso el `shard2`), ya que si aplicamos [ranged sharding a una colección con datos](https://www.mongodb.com/docs/manual/core/ranged-sharding/#shard-a-populated-collection), el balanceador migrará los datos después de haber creado los rangos si es necesario.

Creamos los mismos rangos y zonas que en el ejemplo anterior:

```mongosh
sh.addShardToZone("shard1", "malaga-oeste");
sh.addShardToZone("shard2", "malaga-este");

sh.updateZoneKeyRange("my-db.clients", { "zipCode": "29001"}, { "zipCode": "29010"}, "malaga-oeste");
sh.updateZoneKeyRange("my-db.clients", { "zipCode": "29010"}, { "zipCode": "29019"}, "malaga-este");

```

Comprobamos los rangos:

```mongosh
sh.status()

```

Comprobamos la distribución:

```mongosh
db.clients.getShardDistribution()

```

Ahora si se han distribuido acorde a los rangos.


# Hashed sharding

Vamos a recuperar la colección de clientes:

_./src/index.ts_

```diff
import './load-env.js';
import { MongoClient } from 'mongodb';
import { envConstants } from './env.constants.js';

const client = new MongoClient(envConstants.MONGODB_URI);

const db = client.db();

+ await db.collection('movies').insertMany([
+   {
+     title: 'The Godfather',
+     genres: ['crime', 'drama'],
+   },
+   {
+     title: 'The Godfather: Part II',
+     genres: ['crime', 'drama'],
+   },
+   {
+     title: 'The Dark Knight',
+     genres: ['action', 'crime', 'drama'],
+   },
+   {
+     title: 'Parasite',
+     genres: ['drama', 'thriller'],
+   },
+ ]);

- const count = await db.collection('clients').countDocuments();
+ const count = await db.collection('movies').countDocuments();
console.log({ count });

```

Lanzamos la aplicación:

```bash
npm start

```

Paramos la aplicación, y si ahora intentamos ver el estados del sharding sobre esta colección, pasa lo mismo que antes:

```mongosh
db.movies.getShardDistribution();

```

> Error: `Collection movies is not sharded`
> Como vemos podemos guardar datos de una colección que no tiene habilitado el sharding en un sharded cluster.

Vamos a intentar habilitar el sharding de la colección `movies`:

```mongosh
sh.shardCollection("my-db.movies", { "_id": "hashed" })

```

Al contener ya datos, te lanza un error para que te encargues de crear un índice para ese campo: `MongoServerError: Please create an index that starts with the proposed shard key before sharding the collection`:

```mongosh
db.movies.createIndex({ "_id": "hashed" });

```

> Ojo que el índice también lo tenemos que crear de tipo `"hashed"`, al contrario que ranged que tendría el valor `1`.

Ahora si habilitamos el sharding:

```mongosh
sh.shardCollection("my-db.movies", { "_id": "hashed" });

```

Y comprobamos la distribución de esta colección:

```mongosh
db.movies.getShardDistribution()
sh.status()

```

Al igual que pasaba antes, todos los documentos se han ido al shard principal. En el caso de aplicar [hashed sharding a una colección con datos](https://www.mongodb.com/docs/manual/core/hashed-sharding/#shard-a-populated-collection), igual que con el ranged, se crea un rango inicial que cubre todos los casos, ir al shard primario. Pero en este caso, el balanceador mueve los rangos del inicial cuando necesite balancear la carga, en base a la [política que tiene configurada](https://www.mongodb.com/docs/manual/core/sharding-balancer-administration/).

Es decir, que para minimizar el impacto del balanceo en un cluster, éste solo empieza cuando ha alcanzado la fecha de [migration thresholds](https://www.mongodb.com/docs/manual/core/sharding-balancer-administration/?_ga=2.192756526.529764977.1673855781-81077363.1657918112#migration-thresholds).
