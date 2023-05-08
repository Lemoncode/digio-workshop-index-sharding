# 01 Config local sharded cluster in MongoDB

# Config server

Vamos a comenzar configurando el `config server`. Recordando que tanto éste server como los `shards` son `replica set`.

Añadimos un fichero `docker-compose.yml` donde vamos a añadir todo los servidores que necesitemos. Es importante definirlo en un solo docker-compose.yml para que esten todos los contenedores dentro de la misma red:

La parte más importante es el comando que lanzamos para arrancar el contenedor, usando el flag [--configsvr](https://www.mongodb.com/docs/manual/reference/program/mongod/#std-option-mongod.--configsvr) para indicar que es un servidor config-server y el flag [--replSet](https://www.mongodb.com/docs/manual/reference/program/mongod/#std-option-mongod.--replSet) para indicar que forma parte de un replica set.

Como estamos en local usamos el flag [--bind_ip](https://www.mongodb.com/docs/manual/reference/program/mongod/#std-option-mongod.--bind_ip) a localhost.

_./docker-compose.yml_

```yaml
version: '3.8'
services:

  config-server-1:
    container_name: config-server-1
    image: mongo:6
    command: mongod --configsvr --replSet config-server --port 27017 --dbpath /data/db
    ports:
      - 40001:27017
    volumes:
      - config-server-1:/data/db

  config-server-2:
    container_name: config-server-2
    image: mongo:6
    command: mongod --configsvr --replSet config-server --port 27017 --dbpath /data/db
    ports:
      - 40002:27017
    volumes:
      - config-server-2:/data/db

  config-server-3:
    container_name: config-server-3
    image: mongo:6
    command: mongod --configsvr --replSet config-server --port 27017 --dbpath /data/db
    ports:
      - 40003:27017
    volumes:
      - config-server-3:/data/db

volumes:
  config-server-1: {}
  config-server-2: {}
  config-server-3: {}

```

> [Configuring a config server](https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/)

# Shards

Añadimos una configuración muy parecida pero esta vez para cada uno de los `shards`:

La parte más importante es el comando que lanzamos para arrancar el contenedor, usando el flag [--shardsvr](https://www.mongodb.com/docs/manual/reference/program/mongod/#std-option-mongod.--shardsvr) para indicar que es un servidor shard y aqui tambien utilizamos el flag `--replSet`.

_./docker-compose.yml_

```diff
...
    volumes:
      - shard1-server-3:/data/db

+ shard1-server-1:
+   container_name: shard1-server-1
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard1 --port 27017 --dbpath /data/db
+   ports:
+     - 50001:27017
+   volumes:
+     - shard1-server-1:/data/db

+ shard1-server-2:
+   container_name: shard1-server-2
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard1 --port 27017 --dbpath /data/db
+   ports:
+     - 50002:27017
+   volumes:
+     - shard1-server-2:/data/db

+ shard1-server-3:
+   container_name: shard1-server-3
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard1 --port 27017 --dbpath /data/db
+   ports:
+     - 50003:27017
+   volumes:
+     - shard1-server-3:/data/db

volumes:
  config-server-1: {}
  config-server-2: {}
  config-server-3: {}
+ shard1-server-1: {}
+ shard1-server-2: {}
+ shard1-server-3: {}

```

> [Configuring a Shard](https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/#create-the-shard-replica-sets)

Configuración del `shard2`:

_./docker-compose.yml_

```diff
...
    volumes:
      - shard1-server-3:/data/db

+ shard2-server-1:
+   container_name: shard2-server-1
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard2 --port 27017 --dbpath /data/db
+   ports:
+     - 50004:27017
+   volumes:
+     - shard2-server-1:/data/db

+ shard2-server-2:
+   container_name: shard2-server-2
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard2 --port 27017 --dbpath /data/db
+   ports:
+     - 50005:27017
+   volumes:
+     - shard2-server-2:/data/db

+ shard2-server-3:
+   container_name: shard2-server-3
+   image: mongo:6
+   command: mongod --shardsvr --replSet shard2 --port 27017 --dbpath /data/db
+   ports:
+     - 50006:27017
+   volumes:
+     - shard2-server-3:/data/db

volumes:
  config-server-1: {}
  config-server-2: {}
  config-server-3: {}
  shard1-server-1: {}
  shard1-server-2: {}
  shard1-server-3: {}
+ shard2-server-1: {}
+ shard2-server-2: {}
+ shard2-server-3: {}

```

# Mongos (router)

Por último vamos a configurar el router, el `mongos`:

Ojo que aqui hay que usar el nombre del `replica set` que le pusimos al config server. Ademas en vez de usar el comando `mongod` estamos usando el comando `mongos`.

Aqui es importante usar el flag `--bind_ip_all` o `--bind_ip 0.0.0.0` son sinónimos, para que pueda conectarse a todos los servidores.

_./docker-compose.yml_

```diff
...
    volumes:
      - shard2-server-3:/data/db
      
+ mongos-router:
+   container_name: mongos-router
+   image: mongo:6
+   command: mongos --configdb config-server/config-server-1:27017,config-server-2:27017,config-server-3:27017 --bind_ip_all --port 27017
+   ports:
+     - 60000:27017

volumes:
  config-server-1: {}
  config-server-2: {}
  config-server-3: {}
  shard1-server-1: {}
  shard1-server-2: {}
  shard1-server-3: {}
  shard2-server-1: {}
  shard2-server-2: {}
  shard2-server-3: {}

```

- [Config mongos](https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/#start-a-mongos-for-the-sharded-cluster)

# Ejecutando contenedores

Arrancamos todos los contenedores usando el comando `docker-compose` en background para no ocupar el terminal usando el flag `-d` (modo detach):

```bash
docker-compose up -d

```

Una vez ha terminado, podemos ver que tenemos `10` contenedores de mongo ejecutandose en los puertos indicados.

```bash
docker ps

```

Con esto no hemos terminado de configurarlo, ya que nos falta iniciar cada uno de los `replica set` con el método [rs.initiate](https://www.mongodb.com/docs/manual/reference/method/rs.initiate/#mongodb-method-rs.initiate)

Para ello, tenemos que conectarnos a la consola de mongo (desde nuestra máquina si tenemos mongo instalado o conectándonos a algun contenedor) y ejecutarlo.

## Iniciando el config server

Podemos elegir cualquiera de los 3 servidores donde usar el comando, ya que solamente lo tenemos que ejecutar en uno, vamos a conectarnos al primero, en el `40001`.

```
docker exec -it config-server-1 mongosh

```

Y ahora en esta consola ejecutamos el siguiente comando:

```mongosh
rs.initiate(
  {
    _id: "config-server",
    configsvr: true,
    members: [
      { _id: 0, host: "config-server-1:27017" },
      { _id: 1, host: "config-server-2:27017" },
      { _id: 2, host: "config-server-3:27017" }
    ]
  }
)

```

> `_id`: nombre del replicaset
>
> `configsvr`: activamos la opción para decir que es un config server
>
> `members`: añadimos cada miembro del replica set. Ojo que aqui estamos usando el nombre del contenedor y el puerto interno de éste. En un escenario en producción, cada servidor del replica set estaría en una IP diferente.

Con el comando `rs.status()` podemos ver que _role_ (Primary o Secondary) ha cogido cada servidor.

```mongosh
rs.status()

```

Nos salimos de la consola de `server 40001`:

```mongosh
exit

```

## Iniciando los shards

Y hacemos la misma operación para el `shard1`:

```bash
docker exec -it shard1-server-1 mongosh

```

```mongosh
rs.initiate(
  {
    _id: "shard1",
    members: [
      { _id: 0, host: "shard1-server-1:27017" },
      { _id: 1, host: "shard1-server-2:27017" },
      { _id: 2, host: "shard1-server-3:27017" }
    ]
  }
)

rs.status()

exit

```

> Ojo que aqui no usamos el flag `configsvr`.

Y para el `shard2`:

```bash
docker exec -it shard2-server-1 mongosh

```

```mongosh
rs.initiate(
  {
    _id: "shard2",
    members: [
      { _id: 0, host: "shard2-server-1:27017" },
      { _id: 1, host: "shard2-server-2:27017" },
      { _id: 2, host: "shard2-server-3:27017" }
    ]
  }
)

rs.status()

exit

```

## Configurando el router mongos

Por último, vamos a configurar el router `mongos` para que sepa donde enroutar a cada uno de los shards:

```bash
docker exec -it mongos-router mongosh

```

Ahora añadimos los dos `shards` al router:

```mongosh
sh.addShard( "shard1/shard1-server-1:27017,shard1-server-2:27017,shard1-server-3:27017")

sh.addShard( "shard2/shard2-server-1:27017,shard2-server-2:27017,shard2-server-3:27017")

sh.status()

exit

```

Mientras mantegamos los `volumes` de nuestros contenedores, no vamos a necesitar volver a configurar nuestro sharded cluster.

Se puede añadir un fichero de bash, para que ejecute todos esos comandos por si en algun momento necesitamos volverlos a ejecutar:

_./init-sharded-cluster.sh_

```bash
#!/bin/bash

docker exec config-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'config-server',
    configsvr: true,
    members: [
      { _id: 0, host: 'config-server-1:27017' },
      { _id: 1, host: 'config-server-2:27017' },
      { _id: 2, host: 'config-server-3:27017' }
    ]
  }
)
"

docker exec shard1-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'shard1',
    members: [
      { _id: 0, host: 'shard1-server-1:27017' },
      { _id: 1, host: 'shard1-server-2:27017' },
      { _id: 2, host: 'shard1-server-3:27017' }
    ]
  }
)
"

docker exec shard2-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'shard2',
    members: [
      { _id: 0, host: 'shard2-server-1:27017' },
      { _id: 1, host: 'shard2-server-2:27017' },
      { _id: 2, host: 'shard2-server-3:27017' }
    ]
  }
)
"

docker exec mongos-router mongosh --eval "
sh.addShard( 'shard1/shard1-server-1:27017,shard1-server-2:27017,shard1-server-3:27017')
sh.addShard( 'shard2/shard2-server-1:27017,shard2-server-2:27017,shard2-server-3:27017')
"

```

Y lo ejecutamos:

```bash
sh init-sharded-cluster.sh

```

## Parar contenedores

Si queremos parar todos los contenedores podemos usar el comando:

```bash
docker-compose down

```
