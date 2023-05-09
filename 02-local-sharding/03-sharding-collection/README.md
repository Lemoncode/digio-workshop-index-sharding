# 03 Sharding a collection

Vamos a empezar este ejemplo a partir del anterior _02-boilerplate_.

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

## Ranged sharding

En este ejemplo, vamos a crear 2 colecciones para aplicarles sharding, hay que decir que el `sharding` va a nivel de una colección no la base de datos, es decir, que dentro de nuestro cluster podemos tener colecciones que tengan o no el sharding aplicado.

Además, dependiendo de si ya tenemos datos en la colección o no, tendremos que añadir algun paso extra para habilitar el sharding.

Lo primero que vamos a hacer es habilitarlo en la colección `clients` que esta totalmente vacía, para ello nos conectamos a la consola del servidor `mongos` (el router) y lo habilitamos:

```bash
docker exec -it mongos-router mongosh

```

Comentar que la entidad cliente va a tener la siguiente firma:

```typescript
interface Client {
  _id: ObjectId;
  name: string;
  city: string;
  zipCode: string;
}

```

Por lo que antes de habilitar el sharding, debemos pensar en que campo o campos se van a utilizar como `shard key` y de que tipo [ranged sharding](https://www.mongodb.com/docs/manual/core/ranged-sharding/#std-label-sharding-ranged) o [hashed sharding](https://www.mongodb.com/docs/manual/core/hashed-sharding/#std-label-sharding-hashed).

En este caso, si consideramos que vamos a guardar la ficha de clientes de Málaga, podemos repartir a los clientes por su zipCode que va desde el 29001 hasta el 290018, en concreto, en el `shard1` del `29001 <= zipCode < 29010` y en el `shard2` `29010 <= zipCode < 29019`:

```mongosh
sh.shardCollection("my-db.clients", { "zipCode": 1 })

```

> Habilitamos el sharding en la colección clientes, y de tipo _raged_. Además, creará automaticamente un índice sobre el campos zipCode para dicha colección.

En mongo, la parte de los rangos se maneja con [zones](https://www.mongodb.com/docs/manual/tutorial/manage-shard-zone/#manage-shard-zones) donde se puede asociar una misma zona con varios shards y viceversa, ademas de indicar un rango para cada zona. En este caso lo vamos a hacer simple:

```mongosh
sh.addShardToZone("shard1", "malaga-oeste");
sh.addShardToZone("shard2", "malaga-este");

sh.updateZoneKeyRange("my-db.clients", { "zipCode": "29001"}, { "zipCode": "29010"}, "malaga-oeste");
sh.updateZoneKeyRange("my-db.clients", { "zipCode": "29010"}, { "zipCode": "29019"}, "malaga-este");

```

> [addShardToZone](https://www.mongodb.com/docs/manual/reference/method/sh.addShardToZone/#mongodb-method-sh.addShardToZone)
>
> [updateZoneKeyRange](https://www.mongodb.com/docs/manual/reference/method/sh.updateZoneKeyRange/#mongodb-method-sh.updateZoneKeyRange)
>
> Más info sobre [shard a collection](https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/#shard-a-collection) y [manage shard zone](https://www.mongodb.com/docs/manual/tutorial/manage-shard-zone/)

Podemos comprobar la distribución del sharding actual:

```mongosh
use my-db

db.clients.getShardDistribution()

sh.status()

```

Ahora por ejemplo, vamos a insertar varios clientes:

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

const count = await db.collection('clients').countDocuments();
console.log({ count });

```

Borra o comenta el nuevo código después de insertar los clientes (para no insertar dos veces lo mismo):

_./src/index.ts_

```diff
import './load-env.js';
import { MongoClient } from 'mongodb';
import { envConstants } from './env.constants.js';

const client = new MongoClient(envConstants.MONGODB_URI);

const db = client.db();

- await db.collection('clients').insertMany([
-   {
-     name: 'Carmen Puertos',
-     city: 'Málaga',
-     zipCode: '29003',
-   },
-   {
-     name: 'Antonio Marquez',
-     city: 'Málaga',
-     zipCode: '29010',
-   },
-   {
-     name: 'Isidoro Rodriguez',
-     city: 'Málaga',
-     zipCode: '29009',
-   },
- ]);

const count = await db.collection('clients').countDocuments();
console.log({ count });

```

Ahora podemos comprobar el estado actual de los shards:

```mongosh
db.clients.getShardDistribution()

```

> Como podemos comprobar 2 documentos estan en el `shard1` y uno en el `shard2`.

Si nos conectamos desde `MongoCompass` por ejemplo al servidor `mongodb://localhost:60000` podemos ver que de cara a la aplicación, todo esto del sharding es transparente, ya que vemos la información como si estuviese en un solo servidor.

## Hashed sharding

Vamos a borrar la colección actual de clientes para no meter ruido:

```mongosh
db.clients.drop();

```

Si creamos otra colección, pero en este caso, no se puede definir un rango apropiado por el cual repartir los datos, la mejor opción es tirar por [hashed sharding](https://www.mongodb.com/docs/manual/core/hashed-sharding/#std-label-sharding-hashed) para que te los reparta equitativamente entre todos los `shards`.

> [Hashed sharding shard key](https://www.mongodb.com/docs/manual/core/hashed-sharding/#hashed-sharding-shard-key)

Vamos a habilitar el sharding de la colección `movies`, pero esta vez, de tipo `hashed`:

```mongosh
sh.shardCollection("my-db.movies", { "_id": "hashed" });

```

Automáticamente ha creado 4 rangos para la shard key (`_id`).

Añadimos datos:

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

Y comprobamos la distribución de esta colección:

```mongosh
db.movies.getShardDistribution()
sh.status()

```
