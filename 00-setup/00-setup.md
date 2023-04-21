# Introducción

En esta primera sección vamos a instalar todas las herramientas necesarias para poder realizar el curso. Veremos una guía de instalación para cada una de las herramientas que vamos a utilizar.

En el curso vamos a utilizar MongoDB dockerizado. 

¿Qué quiere decir esto? 

- Usaremos Docker.
- Dentro de Docker, vamos a crear un contenedor con MongoDB.
- Instalaremos una base de datos de ejemplo en el contenedor de MongoDB. En este caso, vamos a utilizar la base de datos de ejemplo de MongoDB, que se llama "sample_mflix", donde podemos encontrar una base de datos de películas con información de actores, directores, comentarios, etc.

De esta forma no tenemos que instalar MongoDB en nuestro equipo, y además, vamos a tener una base de datos de ejemplo para poder trabajar sobre ella.

# Prerequisitos

Para seguir el curso, necesitamos tener instalado:

- Docker
- MongoDB Compass
- Visual Studio Code

# Instalación mongo dockerizado

Hasta hace unos años lo más normal era instalarte en tu máquina el motor de base de datos de turno,
por ejemplo _MongoDB_, ¿Qué problemas nos podemos encontrar siguiendo esta aproximación?

- Puede que vayamos a instalar una versión de un motor y nos de problemas en nuestra máquina.
- Es un rollo cuando salimos del proyecto y vamos dejando "motores" zombies que ya no usamos.
- Otras veces no tenemos exactamente la misma versión que producción y eso puede traer problemas.
- También es muy normal, que hayas hecho tantas pruebas que quieras partir de una versión limpia, o asegurarte que no hay nada que hayas tocado diferente a producción, tanto en settings del motor como con el contenido o estructura de tu base de datos.
- El peor de los casos es cuando estamos entre dos proyectos y uno no usa la última versión del motor y el otro sí ¿Qué hacemos vamos desinstalando una e instalando la otra dependiendo del proyecto
en el que estemos trabajando?

## Manos a la obra

Partimos de que ya tenemos instalado Docker en nuestro equipo. Ahora vamos a ir a la terminal el shell de linux o mac ó el cmd de Windows) y vamos a indicarle en un comando:
  - Que se baje la imagen de mongo (en concreto la versión 6.0.5).
  - Que vamos a exponer el puerto 27017 del contenedor docker y lo mapee al puerto 27017 de tu máquina física (este es el puerto en el que por defecto suele correr **MongoDB**).
  - Y que a ese contenedor lo llame _my-mongo-db_ y lo ejecute.

```bash
docker run --name my-mongo-db -p 27017:27017 -d mongo:6.0.5
```

- Veremos que empieza a descargarse la imagen en nuestra máquina. Esto puede tardar un poco, dependiendo de la velocidad de nuestra conexión a internet.

- Una vez finalizado, si queremos comprobar que el contenedor se ha creado y está ejecutandose podemos lanzar el siguiente comando:

```bash
docker ps
```

- Ya que tenemos el contenedor listo vamos entrar en él en modo interactivo, es decir abrir una shell de bash
  sobre la que podremos tirar comandos dentro del mismo contenedor:

```bash
docker exec -it my-mongo-db sh
```

Con el flag `it` estamos diciendo que lo ejecutamos en modo interactivo, es decir aparece
un nuevo _prompt_ en el terminal desde que el podemos ejecutar comandos estando dentro
del contenedor (sale como simbolo de línea de comandos una almohadilla).

En nuestro caso vamos a lanzar _mongo_

```bash
# mongosh
```

Y vamos a hacer la siguiente prueba:

- Crearemos una base de datos y
- Añadiremos una colección y elemento.
- Lo listaremos.

Una vez que hayamos terminado, nos saldremos de mongo y de la consola interactive que hemos abierto.

Vamos a por los comandos, miramos las bases de datos que hay creadas por defecto

```bash
show dbs
```

Vamos a cambiarnos a la base de datos _my-db_ como esta no existe nos la crea:

```
use my-db
```

Mostramos la lista de colecciones que tiene esa nueva base de datos

```
show collections
```

Esta vacía, vamos a hacer un insert en una colección que llamaremos _clients_

```
db.clients.insertOne({ name: "Client 1" })
```

Ahora, si podemos ver la colección clientes en la base de datos, hacemos un _show collections_:

```
show collections
```

Y podemos ver que hemos insertado esa fila (añadimos la llamada _pretty_ para que formatee el _json_ resultante por consola):

```
db.clients.find().pretty()
```

para finalizar salimos de la consola de comandos de mongo

```
exit
```

Y salimos del interfaz interactivo del contenedor

```
exit
```

De esta manera podríamos tener varios contenedores de Docker con versiones diferentes de **MongoDb** instaladas.

También podemos conectarnos desde nuestra máquina local al **Mongo** que tenemos corriendo en el contenedor,
si arrancamos por ejemplo _compass_, funciona incluso con la conexión por defecto, esto va tan directo, porque hemos mapeado
el puerto por defecto que utiliza **mongoDB** en nuestro contenedor al puerto por defecto de nuestra máquina,
así _Mongo Compass_ lo toma como la base de datos en local que está instalada en nuestra máquina.

Cuando ya no nos haga falta un contenedor en concreto lo único que tenemos que hacer es eliminarlo con el siguiente comando:

```bash
docker container rm my-mongo-db -f
```

En este comando le hemos dicho que elimine el contenedor _my-mongo-db_ que hemos creado, y el
parametro _-f_ es para forzar su eliminación (así si hay una instancia corriendo la pararía primero).

# Base de datos de ejemplo

En el paso anterior vimos como instanciar un contenedor de **Docker** basado en una imagen que tuviera un MongoDB, y después nos pusimos por línea de comandos a crear una mini base de datos. Esto no esta mal, peeerooo en el mundo real, trabajamos con bases de datos que contienen un montón de información, lo normal es que restauremos un backup y nos pongamos a trabajar usando información cuanto menos parecida a la real.

_¿Cómo podemos hacer ésto con Docker?_

## Manos a la obra

Vamos a asumir que ya tenemos nuestro contenedor de mongo del ejemplo anterior funcionando,
podemos comprobarlo ejecutando el siguiente comando:

```bash
docker ps
```

En caso de que no, puedes seguir los primeros pasos del ejemplo anterior.

Vamos a ir a este [repositorio](https://github.com/Lemoncode/m-flix-backup) y clonamos el repositorio con Visual Studio Code.

Aquí podemos ver una carpeta _m-flix, si entramos podemos ver el backup de varias colecciones

```
cd m-flix

```

```
ls
```

Volvemos al nivel superior.

```
cd ..
```

Ahora, tenemos que en nuestro disco duro local está disponible el backup, pero nuestro contenedor de Docker que corre la imagen de Mongo tiene su propio espacio local, no puede acceder directamente
a ese fichero, ¿Qué podemos hacer? Usando un comando de **Docker** podemos copiar ese fichero desde nuestro local a nuestro contenedor:

Aquí lo que hacemos es decirle que vamos a copiar el contenido de lo que hay en mi carpeta _backup_ en el contenedor, en concreto lo copiaremos a la ruta _/opt/app/_

> Para seguir los ejemplos puedes tanto utilizar el nombre del contenedor que hemos
> establecido al crearlo _my-mongo-db_ o reemplazarlo por el identificador de contenedor de la instancia de mongo que estés ejecutando.

```bash
docker cp m-flix my-mongo-db:/opt/app
```

Y restauramos el backup

```bash
docker exec my-mongo-db mongorestore --db mymovies opt/app
```

Con _docker exec_ le estamos diciendo que ejecute el comando _mongorestore_ en el contenedor _my-mongo-db_, que restaure la base de datos que está en la ruta _opt/app_ y la llame _mymovies_.

Ahora podemos entrar en nuestro contenedor:

```
docker exec -it my-mongo-db sh
```

Arrancamos el terminal de mongo

```bash
mongosh
```

Seleccionamos la base de datos recien restaurada:

```
use mymovies
```

Vemos que colecciones tenemos disponibles

```
show collections
```

Y ejecutamos una query contra la colección _movies_

```
db.movies.find().pretty()
```

Y como puedes ver tenemos todos los datos disponibles.
