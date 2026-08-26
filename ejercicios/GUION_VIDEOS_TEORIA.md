# Guion — Vídeos de teoría (Docker)

**Formato:** 7 vídeos cortos para grabar antes de la sesión en directo.
Duración total aprox. **60–70 min**.
Cada bloque incluye: objetivo del vídeo, guion narrado (puedes leerlo casi
literal o usarlo como apoyo), qué sección de [TEORIA.md](./TEORIA.md)
desarrolla y qué ejercicio desbloquea.

**Esta es la primera sesión del módulo: no se asume ningún conocimiento
previo de contenedores.** Sí se asume soltura con la terminal y nociones
básicas de Python y SQL.

> ⚠️ Antes de grabar, comprueba que los alumnos han recibido
> **[REQUISITOS.md](./REQUISITOS.md)**. Menciónalo en el vídeo 1: si llegan
> sin Docker instalado, los vídeos no sirven de nada.

---

## Mapa de los vídeos

| # | Vídeo | Duración | Teoría | Desbloquea |
|---|---|---|---|---|
| 1 | ¿Por qué contenedores? Imagen vs contenedor | 8 min | §1, §2.0 | — |
| 2 | Ejecutar contenedores: ciclo de vida | 10 min | §2.1–2.5 | Ej. 1, 2 |
| 3 | Imágenes: registries, nombres, tags y capas | 10 min | §3 | Ej. 5 bis |
| 4 | Dockerfile: construir tu propia imagen | 10 min | §3.2, §4 | Ej. 4, 5 |
| 5 | Volúmenes y puertos | 12 min | §5, §6 | Ej. 3 |
| 6 | Docker Compose: varios servicios que se hablan | 12 min | §7, §8, §9 | Ej. 6, 7 |
| 7 | Desarrollo real y el stack de Airflow | 8 min | §10, §11 | Ej. 8, 9, 10 |

Si tienes que recortar, los vídeos **3 y 7** son los más prescindibles: el 3
se puede leer, y el 7 se puede dar en directo al abrir el bloque 4.

---

## Vídeo 1 — ¿Por qué contenedores? Imagen vs contenedor (8 min)

**Teoría:** TEORIA.md §1 y §2.0

**Objetivo:** que entiendan qué problema resuelve Docker y que interioricen
la distinción imagen/contenedor, que es la fuente del 80 % de la confusión
inicial.

**Guion:**

> Vamos a empezar por el problema, no por la herramienta. Seguro que os ha
> pasado, o os va a pasar: escribís un script de Python que funciona
> perfectamente en vuestro portátil, se lo pasáis a un compañero, y a él le
> peta. Versión distinta de pandas, una librería del sistema que a vosotros
> os venía instalada, otra versión de Python. La frase "pues en mi máquina
> funciona" es un clásico, y es un clásico caro: en un equipo de datos se
> pierden días enteros en esto.
>
> Docker resuelve ese problema empaquetando **la aplicación y todo lo que
> necesita para ejecutarse** en una única unidad que se comporta igual en
> cualquier sitio.
>
> Y aquí viene la distinción más importante de todo el módulo, la que tenéis
> que tener clarísima antes de tocar un comando. Hay **dos** conceptos, no
> uno.
>
> La **imagen** es una plantilla de solo lectura. Contiene un sistema de
> archivos: las librerías, los binarios, vuestro código. Es estática, no se
> ejecuta, está ahí guardada ocupando disco. Pensadla como una **clase** en
> programación orientada a objetos. O, si preferís algo más de andar por
> casa, como una **receta de cocina**.
>
> El **contenedor** es una instancia en ejecución de esa imagen. Es un
> proceso vivo, con su propio sistema de archivos temporal encima de la
> imagen. Siguiendo la analogía: es el **objeto** instanciado de esa clase,
> o el **plato ya cocinado**.
>
> De una misma imagen podéis levantar veinte contenedores a la vez, igual
> que de una clase instanciáis veinte objetos, o de una receta salen veinte
> platos. Y son independientes entre sí.
>
> Última pieza: el **registry**, que es el servidor donde viven las imágenes
> para poder descargarlas y compartirlas. El público por defecto se llama
> **Docker Hub**, y vais a acabar teniendo cuenta en él.
>
> Una pregunta que siempre sale: ¿esto no es una máquina virtual? No. Y la
> diferencia es la clave de por qué Docker triunfó. Una máquina virtual
> emula hardware y arranca un sistema operativo completo, con su propio
> kernel: tarda minutos, ocupa gigas y necesita gigas de RAM. Un contenedor
> **comparte el kernel de la máquina anfitriona** y solo aísla los procesos,
> la red y el sistema de archivos usando mecanismos de Linux que se llaman
> namespaces y cgroups.
>
> ¿La consecuencia práctica? Un contenedor arranca en **milisegundos**, no
> en minutos. Y eso significa que en un portátil normal podéis tener
> **decenas o cientos** de contenedores, cuando de máquinas virtuales
> tendríais cinco como mucho. Ese salto de escala es lo que hace posible
> todo lo que veremos después.

**Puntos clave a remarcar en cámara:**
- Imagen = plantilla estática (clase, receta). Contenedor = instancia viva (objeto, plato).
- De una imagen salen N contenedores independientes.
- Contenedor ≠ VM: comparte kernel, no emula hardware. Arranca en ms, no en minutos.
- Registry = donde viven las imágenes. Docker Hub es el público por defecto.
- Recordarles que instalen Docker antes de clase (REQUISITOS.md).

---

## Vídeo 2 — Ejecutar contenedores: el ciclo de vida (10 min)

**Teoría:** TEORIA.md §2.1 a §2.5
**Desbloquea:** ejercicios 1 y 2

**Objetivo:** que sepan arrancar, listar, inspeccionar y borrar contenedores,
y sobre todo que entiendan **por qué un contenedor "se muere solo"**.

**Guion:**

> Vamos con los comandos, pero enfocados a un concepto que confunde a todo
> el mundo al principio.
>
> Un contenedor **vive exactamente lo que viva su proceso principal**. No es
> como una máquina virtual, que arrancas y se queda encendida esperando. Si
> ejecutáis un contenedor cuyo comando es `echo hola`, imprime "hola",
> el proceso termina, y el contenedor **se para inmediatamente**. No está
> roto: ha hecho su trabajo. Esto es lo que hace que mucha gente piense que
> "Docker no funciona" en su primer intento.
>
> Los estados por los que pasa un contenedor son: **created** cuando existe
> pero no ha arrancado, **running** mientras el proceso vive, **exited**
> cuando el proceso ha terminado, y **removed** cuando lo borráis de verdad.
>
> Y aquí un detalle importante: un contenedor **exited no ha desaparecido**.
> Sigue en disco, ocupando espacio, con su sistema de archivos intacto. Por
> eso `docker ps` no os lo muestra, pero `docker ps -a` sí. Y por eso podéis
> resucitarlo con `docker start`. La gente acumula decenas de contenedores
> parados sin darse cuenta y luego se pregunta dónde ha ido su disco duro.
>
> Los comandos que vais a usar cada día son pocos:
> `docker run` para crear y arrancar, `docker ps` para ver qué está vivo,
> `docker ps -a` para ver también los muertos, `docker logs` para ver qué ha
> escrito por pantalla, `docker exec` para meteros dentro, `docker stop`
> para parar y `docker rm` para borrar.
>
> De los flags de `docker run`, quedaos con cuatro. **`-d`** lo lanza en
> segundo plano y os devuelve la terminal; sin él, os quedáis enganchados a
> su salida. **`--name`** le pone un nombre en vez del nombre aleatorio
> gracioso que os inventa Docker, y os ahorra copiar identificadores.
> **`--rm`** borra el contenedor automáticamente en cuanto termina, y es
> perfecto para pruebas de usar y tirar. Y **`-it`** os da una terminal
> interactiva dentro del contenedor.
>
> Un aviso sobre `-d` y `--rm`: son cómodos pero traicioneros juntos. Si
> lanzáis algo en segundo plano con `--rm` y falla, el contenedor se borra
> con sus logs y os quedáis sin poder investigar qué pasó.
>
> Y dos comandos para cuando algo va mal, que son los que de verdad os van a
> salvar. **`docker logs -f`** os enseña la salida del contenedor en tiempo
> real, según se va produciendo. Y **`docker exec -it <nombre> sh`** os abre
> una terminal **dentro** del contenedor, para mirar qué archivos hay,
> comprobar variables de entorno o lanzar comandos. Cuando en clase digáis
> "no funciona", lo primero que os voy a preguntar es qué dicen los logs.

**Puntos clave a remarcar en cámara:**
- El contenedor vive lo que viva su proceso principal. Si el proceso acaba, se para. Es normal.
- `exited` ≠ borrado. `docker ps -a` para verlos; ocupan disco.
- Flags imprescindibles: `-d`, `--name`, `--rm`, `-it`.
- `docker logs -f` y `docker exec -it ... sh` son las dos herramientas de diagnóstico.

**Demo en pantalla (recomendada):** lanzar un contenedor con un bucle que
imprima un contador cada 2 segundos y enseñar `docker logs -f` mostrando la
salida en vivo. Es exactamente el ejercicio 1 y engancha mucho más que un
`hello-world`.

---

## Vídeo 3 — Imágenes: registries, nombres, tags y capas (10 min)

**Teoría:** TEORIA.md §3
**Desbloquea:** ejercicio 5 bis (publicar en Docker Hub)

**Objetivo:** que sepan leer el nombre completo de una imagen y que entiendan
por qué `latest` es peligroso y por qué a veces el build tarda 3 segundos y
otras 5 minutos.

**Guion:**

> Cuando escribís `docker run postgres`, ahí hay más información oculta de la
> que parece. El nombre completo de una imagen tiene cuatro partes:
> **registry**, **namespace**, **repositorio** y **tag**. Cuando escribís
> solo `postgres`, Docker rellena el resto por vosotros: se convierte en
> `docker.io/library/postgres:latest`.
>
> El **registry** es el servidor. Por defecto Docker Hub, pero en una empresa
> será casi siempre uno privado: ECR en Amazon, Artifact Registry en Google,
> Harbor si es on-premise. El **namespace** es la cuenta o la organización;
> `library` es el namespace especial de las imágenes oficiales. Y el **tag**
> es la versión.
>
> Vamos con el tag, porque aquí hay una trampa que le explota a todo el mundo
> una vez en la vida. **`latest` no significa "la última versión".** Es
> simplemente el tag que se usa si no especificáis ninguno, y apunta a lo que
> el que publicó la imagen haya decidido. Puede cambiar de debajo de
> vuestros pies sin avisar.
>
> Traducido a vuestro trabajo: si vuestro pipeline de producción usa
> `python:latest`, un día cualquiera el mantenedor publica una versión nueva,
> vuestro build la coge, y un pipeline que llevaba meses funcionando se
> rompe sin que nadie haya tocado una línea de código. Y es un error
> desagradable de diagnosticar, porque en Git no hay ningún cambio.
>
> La regla es simple y no tiene excepciones: **en producción, tag explícito
> siempre**. `postgres:18-alpine`, no `postgres`. Reproducibilidad es
> exactamente esto.
>
> Por cierto, `alpine`: veréis muchas imágenes con ese sufijo. Alpine es una
> distribución de Linux minúscula, y esas variantes ocupan una fracción de
> lo que ocupa la normal. Menos tamaño es menos tiempo de descarga y menos
> superficie de ataque.
>
> Lo último y quizá lo más práctico: las imágenes están hechas de **capas**.
> Cada instrucción de un Dockerfile genera una capa, y las capas se apilan
> unas encima de otras, todas de solo lectura.
>
> Esto tiene dos consecuencias muy concretas. La primera es que **las capas
> se comparten**: si tenéis cinco imágenes construidas sobre
> `python:3.13-slim`, esa base está en disco **una sola vez**. Por eso
> `docker images` os puede sumar 15 GB cuando en disco real ocupáis 6.
>
> La segunda es la **caché**, y es la que explica por qué a veces un build
> tarda tres segundos y otras cinco minutos. Docker reutiliza las capas que
> no han cambiado, pero **en cuanto una capa cambia, todas las que vienen
> detrás se reconstruyen**. Por eso el orden de las instrucciones importa
> tanto, y lo veremos en el vídeo siguiente.

**Puntos clave a remarcar en cámara:**
- Nombre completo: `registry/namespace/repositorio:tag`. `postgres` → `docker.io/library/postgres:latest`.
- `latest` NO es "la última". Es el tag por defecto y es móvil. En producción, tag explícito.
- Las capas se comparten entre imágenes: el disco real es menor que la suma de `docker images`.
- Si cambia una capa, se invalidan todas las siguientes. De ahí la importancia del orden.

---

## Vídeo 4 — Dockerfile: construir tu propia imagen (10 min)

**Teoría:** TEORIA.md §3.2 y §4
**Desbloquea:** ejercicios 4 y 5

**Objetivo:** que sepan escribir un Dockerfile que extienda una imagen
oficial, que es el 90 % de lo que hará un Data Engineer.

**Guion:**

> Hasta ahora habéis usado imágenes que ha hecho otro. Ahora vais a hacer la
> vuestra. Y quiero deciros desde el principio cuál es el caso real: como
> Data Engineers **casi nunca vais a construir una imagen desde cero**. Lo
> que vais a hacer, una y otra vez, es **partir de una imagen oficial y
> añadirle cosas**.
>
> El caso típico y literal: tenéis Airflow corriendo, escribís un DAG que
> importa `duckdb`, y os peta con `ModuleNotFoundError`. Porque la imagen
> oficial de Airflow no trae duckdb, claro. La solución no es entrar en el
> contenedor e instalarlo a mano, porque eso se pierde en cuanto se recree
> el contenedor. La solución es construir vuestra propia imagen que sea "la
> de Airflow **más** duckdb".
>
> Un Dockerfile es un archivo de texto con instrucciones, y con cinco os
> sobra para empezar.
>
> **`FROM`** dice de qué imagen partís, y siempre es la primera línea.
> **`RUN`** ejecuta un comando **durante la construcción** de la imagen:
> aquí es donde va vuestro `pip install`. **`COPY`** copia archivos de
> vuestra máquina a dentro de la imagen. **`WORKDIR`** fija el directorio de
> trabajo. Y **`CMD`** define el comando que se ejecutará cuando alguien
> arranque un contenedor de esa imagen.
>
> Fijaos en la diferencia entre `RUN` y `CMD`, porque se confunden mucho:
> **`RUN` se ejecuta al construir, `CMD` al arrancar**. `RUN` deja su
> resultado grabado dentro de la imagen; `CMD` solo dice qué pasará después.
>
> Luego se construye con `docker build -t nombre:tag .`. Ese punto del final
> es el **contexto de build**: el directorio que se le manda al motor de
> Docker. No es decorativo; si lo lanzáis en una carpeta con 5 GB de datos
> dentro, Docker se los manda enteros y el build se arrastra. Para eso
> existe `.dockerignore`, que funciona igual que `.gitignore`.
>
> Y ahora el consejo que os va a ahorrar más tiempo de todo el módulo, que
> conecta con las capas del vídeo anterior: **poned primero lo que cambia
> poco y al final lo que cambia mucho**.
>
> Vuestras dependencias cambian una vez al mes. Vuestro código cambia veinte
> veces al día. Si ponéis el `COPY` del código **antes** del `pip install`,
> cada vez que toquéis una coma invalidáis la capa del código y Docker vuelve
> a instalar todas las dependencias desde cero: cinco minutos por cada
> cambio. Si lo ponéis **después**, la capa del `pip install` se mantiene en
> caché y el build tarda tres segundos.
>
> Es exactamente el mismo Dockerfile, las mismas instrucciones, solo
> cambiadas de orden. Y es la diferencia entre un ciclo de desarrollo ágil y
> uno insufrible.
>
> Un último apunte que os va a resolver una duda cuando veáis nuestro
> proyecto de Airflow: `CMD` **se puede sobrescribir** al arrancar el
> contenedor. Por eso los cinco servicios de Airflow que veremos usan
> exactamente **la misma imagen**, y lo único que los distingue es el
> comando: uno arranca el scheduler, otro el servidor web, otro el worker.
> Misma imagen, comportamientos distintos.

**Puntos clave a remarcar en cámara:**
- El caso real del DE: extender una imagen oficial, no construir desde cero.
- `RUN` = al construir. `CMD` = al arrancar. `CMD` es sobrescribible.
- El `.` del `docker build` es el contexto; cuidado con carpetas pesadas y usa `.dockerignore`.
- **Orden de las instrucciones**: lo estable arriba, lo volátil abajo. Dependencias antes que código.

**Demo en pantalla (muy recomendada):** construir dos veces la misma imagen
cambiando una línea del código, con el `COPY` mal colocado y bien colocado,
y enseñar los tiempos. Verlo con un cronómetro convence infinitamente más
que explicarlo.

---

## Vídeo 5 — Volúmenes y puertos (12 min)

**Teoría:** TEORIA.md §5 y §6
**Desbloquea:** ejercicio 3

**Objetivo:** que entiendan que un contenedor está aislado por diseño, y las
dos formas de romper ese aislamiento a propósito.

**Guion:**

> Un contenedor está **aislado**: su sistema de archivos desaparece cuando lo
> borráis, y su red es invisible desde fuera. Eso es justo lo que queremos
> casi siempre. Pero hay dos excepciones constantes: queremos que los datos
> **persistan**, y queremos poder **hablar** con el proceso de dentro. Para
> lo primero están los volúmenes, para lo segundo la publicación de puertos.
> Son mecanismos independientes.
>
> **Empecemos por los volúmenes.** Recordad las capas del vídeo 3: un
> contenedor tiene una capa de escritura encima de las capas de solo lectura
> de la imagen. Todo lo que escriba el proceso (una fila en la base de
> datos, un log, un archivo temporal) va a esa capa. Y esa capa **se borra
> con el contenedor**.
>
> Dejadme decirlo de forma más brutal: si tenéis PostgreSQL en un contenedor
> sin volumen, un `docker rm` borra **toda vuestra base de datos**. Y no solo
> eso: recrear el contenedor para actualizar la imagen también. Es un error
> que se comete una vez y no se olvida.
>
> Hay dos mecanismos, y la diferencia entre ellos es la pregunta de examen.
>
> El **bind mount** monta una carpeta **vuestra, del host**, dentro del
> contenedor. Vosotros elegís la ruta. Docker no gestiona nada, simplemente
> hace visible esa carpeta dentro. La carpeta `./dags` de vuestro proyecto y
> `/opt/airflow/dags` dentro del contenedor pasan a ser **literalmente el
> mismo directorio** visto desde dos sitios. Escribís un DAG en vuestro
> editor y el scheduler lo ve al instante, sin reconstruir ni reiniciar
> nada. Es la herramienta del desarrollo.
>
> El **volumen con nombre** es distinto: le dais un nombre, y **Docker
> decide dónde guardarlo**, en una zona suya que no os interesa. No lo
> editáis desde vuestro editor, pero sobrevive a `docker rm`, es portable
> entre máquinas y Docker sabe gestionarlo, copiarlo y respaldarlo. Es la
> herramienta de los datos de verdad: bases de datos.
>
> La regla para no equivocarse: **¿es código que escribes tú? Bind mount.
> ¿Son datos que genera la aplicación? Volumen con nombre.**
>
> **Vamos con los puertos.** Si arrancáis PostgreSQL en un contenedor y
> abrís vuestro cliente SQL en el puerto 5432 de localhost, no conecta. El
> proceso está escuchando, pero dentro de su propia red aislada. Vuestro
> `localhost` y el `localhost` del contenedor no son el mismo sitio.
>
> Para abrir una puerta se usa `-p`, y se lee **siempre** así: el número de
> la izquierda es **el puerto de vuestra máquina**, el de la derecha es **el
> puerto de dentro del contenedor**. Izquierda fuera, derecha dentro. Si os
> lo aprendéis en ese orden os ahorráis muchos disgustos.
>
> Y no tienen por qué coincidir. Si escribís `-p 9090:8080`, abrís vuestro
> navegador en el 9090 y por dentro llega al 8080. Esto es utilísimo cuando
> tenéis dos proyectos que quieren el mismo puerto: en clase usaremos el
> 8080 para el proyecto real y el 8088 para el sandbox, precisamente para
> que no choquen.
>
> Dos matices finales. El primero: veréis `EXPOSE` en algunos Dockerfiles.
> **`EXPOSE` no publica nada**, es solo documentación, un comentario formal
> que dice "esta imagen escucha aquí". El que abre la puerta de verdad es
> `-p`. Mucha gente pierde una tarde con esto.
>
> Y el segundo, que es importante para lo que viene: **para que dos
> contenedores hablen entre ellos NO hace falta `-p`**. Airflow se conecta a
> Postgres sin que Postgres publique ningún puerto al exterior. `-p` es solo
> para llegar **desde vuestra máquina**. Cómo se hablan entre ellos es el
> vídeo siguiente.
>
> Y ya que hablamos de arranque, un concepto que va a ser crítico: el
> **healthcheck**. Es un comando que Docker ejecuta cada cierto tiempo para
> saber si el contenedor está **listo**, no solo arrancado. Y la diferencia
> importa muchísimo en stacks de datos: "el proceso de Postgres existe" y
> "Postgres ya acepta conexiones" pueden llevarse veinte segundos. Sin
> healthcheck, Airflow intenta conectarse a una base de datos que aún está
> inicializándose y falla con un error incomprensible.

**Puntos clave a remarcar en cámara:**
- Sin volumen, `docker rm` borra los datos. Dicho así de crudo.
- Bind mount = tu carpeta, tú eliges la ruta, ideal para código. Volumen con nombre = lo gestiona Docker, ideal para datos.
- `-p izquierda:derecha` = `host:contenedor`. Izquierda fuera, derecha dentro.
- `EXPOSE` documenta, `-p` publica. No son lo mismo.
- Entre contenedores NO hace falta `-p`.
- Healthcheck = "listo", no "arrancado".

---

## Vídeo 6 — Docker Compose: varios servicios que se hablan (12 min)

**Teoría:** TEORIA.md §7, §8 y §9
**Desbloquea:** ejercicios 6 y 7

**Objetivo:** que sepan leer y escribir un `docker-compose.yml` y que
entiendan el DNS interno, que es lo que más "magia" parece.

**Guion:**

> Hasta ahora hemos lanzado contenedores sueltos. Pero una aplicación real de
> datos nunca es un contenedor: es Airflow **más** una base de datos, **más**
> un broker de mensajes, **más** un worker. Cinco o seis procesos que tienen
> que arrancar en orden, compartir red y conocerse entre sí.
>
> Podríais hacerlo con seis `docker run` escritos a mano, cada uno con sus
> quince flags. Y funcionaría... hasta que cerráis el portátil y al día
> siguiente no os acordáis de los flags. O hasta que se lo pasáis a un
> compañero.
>
> **Docker Compose** resuelve eso: describís todos los servicios en un único
> archivo YAML, y ese archivo se versiona en Git junto al código. Cada
> `service:` del YAML es, literalmente, la traducción de un `docker run` que
> antes escribiríais a mano. Lo que era `-p` ahora es `ports:`, lo que era
> `-v` ahora es `volumes:`, lo que era `-e` ahora es `environment:`. No hay
> conceptos nuevos, es la misma información mejor guardada.
>
> Los comandos son cuatro: `docker compose up -d` levanta todo en segundo
> plano, `docker compose ps` os dice cómo está cada servicio,
> `docker compose logs -f <servicio>` os da los logs de uno concreto, y
> `docker compose down` para y borra los contenedores.
>
> Ojo con una variante: **`docker compose down -v`** borra además los
> volúmenes con nombre. Es decir, **vuestros datos**. Es el comando que
> queréis cuando algo está corrupto y queréis empezar de cero, y el que no
> queréis ejecutar por inercia.
>
> Y ahora lo mejor de Compose, que es lo que más impresiona cuando se
> entiende. Al hacer `docker compose up`, Compose **crea automáticamente una
> red privada** para vuestro proyecto y conecta todos los servicios a ella.
> Dentro de esa red, **cada servicio es alcanzable por los demás usando su
> nombre de servicio como si fuera un nombre de dominio**.
>
> O sea: si vuestro servicio se llama `postgres` en el YAML, desde dentro del
> contenedor de Airflow la cadena de conexión es, literalmente,
> `postgresql://usuario:clave@postgres:5432/basededatos`. Ahí donde iría una
> IP, ponéis `postgres`. Compose levanta un DNS interno y lo resuelve solo.
>
> Esto es importante porque elimina el problema de las IPs. Los contenedores
> cambian de IP cada vez que se recrean; los nombres, no. Nunca escribáis una
> IP en una cadena de conexión.
>
> Y enlazando con el vídeo anterior: **por eso Postgres no necesita publicar
> el puerto 5432**. Airflow le habla por la red interna. En nuestro proyecto
> solo publicamos el 8080 del servidor web, porque es el único al que
> queremos llegar desde el navegador. Todo lo demás se queda dentro. Y eso,
> además de cómodo, es más seguro: lo que no está publicado no es atacable
> desde fuera.
>
> Una última pieza: **`depends_on`** controla el orden de arranque. Pero
> cuidado, porque por defecto solo espera a que el contenedor **exista**, no
> a que esté **listo**. Para eso hay que combinarlo con el healthcheck del
> vídeo anterior, usando `condition: service_healthy`. Sin eso, Airflow
> arranca antes de que Postgres acepte conexiones y todo revienta. Es
> literalmente el error más común al montar un stack de datos.

**Puntos clave a remarcar en cámara:**
- Compose = los mismos conceptos, en un archivo versionable. `-p`→`ports:`, `-v`→`volumes:`, `-e`→`environment:`.
- `down -v` borra los datos. Avisar dos veces.
- **DNS interno**: el nombre del servicio ES el hostname. Nunca uses IPs.
- Solo se publica al host lo que se necesita desde el navegador.
- `depends_on` sin `condition: service_healthy` no espera a que esté listo.

---

## Vídeo 7 — Desarrollo real y el stack de Airflow (8 min)

**Teoría:** TEORIA.md §10 y §11
**Desbloquea:** ejercicios 8, 9 y 10

**Objetivo:** cerrar el círculo enseñándoles que el proyecto real que van a
tocar en clase no tiene nada que no hayan visto ya.

**Guion:**

> Vamos a cerrar juntando todo, porque el objetivo del módulo no es que
> sepáis Docker en abstracto: es que podáis abrir el `docker-compose.yml` de
> un proyecto de datos real y entender qué está pasando.
>
> Primero, el flujo de trabajo del día a día. Cuando desarrolláis con
> contenedores, la pregunta constante es: **¿esto requiere reconstruir la
> imagen o no?** Y la respuesta define vuestra velocidad.
>
> Si habéis montado vuestro código con un **bind mount**, editáis el archivo
> y ya está: el contenedor lo ve al instante. Cero espera.
>
> Si lo que cambia son las **dependencias** —añadís una librería nueva—,
> entonces sí toca `docker compose build` y volver a levantar. Y ahí es donde
> el orden de las instrucciones del Dockerfile que vimos en el vídeo 4 os
> devuelve el tiempo invertido.
>
> La regla: **el código va por bind mount, las dependencias van en la
> imagen**. Con eso el 95 % de vuestros cambios son instantáneos.
>
> Y ahora abramos el proyecto real. Es un stack de Airflow 3 con PostgreSQL,
> y a primera vista intimida: son unas cien líneas de YAML y cinco servicios.
> Pero mirad lo que hay realmente dentro:
>
> Hay un servicio de **Postgres**, con un **volumen con nombre** para que los
> datos sobrevivan. Vídeo 5.
>
> Hay cinco servicios de Airflow que usan **exactamente la misma imagen** y
> se diferencian solo por el `command:`: uno es el scheduler, otro el
> servidor de API, otro el worker. Vídeo 4, cuando dijimos que `CMD` se
> sobrescribe.
>
> Se conectan a la base de datos con la cadena
> `postgresql://airflow:airflow@postgres:5432/airflow`, donde `postgres` es
> el nombre del servicio resuelto por el DNS interno. Vídeo 6.
>
> Hay **bind mounts** de `./dags` para poder escribir DAGs desde vuestro
> editor. Vídeo 5.
>
> Hay **healthchecks** con `pg_isready` y `depends_on` con
> `condition: service_healthy`, para que nada arranque antes de tiempo.
> Vídeos 5 y 6.
>
> Y hay un servicio `airflow-init` que se ejecuta una vez, crea las tablas y
> termina. Un contenedor que se para no está roto: ha terminado su trabajo.
> Vídeo 2.
>
> No hay nada ahí que no hayáis visto ya. Y ese es exactamente el punto:
> **un stack de datos de producción no es Docker avanzado, es Docker básico
> bien combinado**. La complejidad está en el dominio (Airflow, Postgres, la
> cola de tareas), no en la contenedorización.
>
> Nos vemos en clase. Venid con Docker instalado y las imágenes descargadas,
> que si no, la primera hora se nos va en barras de progreso.

**Puntos clave a remarcar en cámara:**
- Código por bind mount (instantáneo), dependencias en la imagen (requiere build).
- El proyecto real no usa ningún concepto nuevo: es la combinación de los 6 vídeos anteriores.
- Ir señalando en pantalla cada pieza del YAML y decir de qué vídeo sale. Es el momento "ah, vale".
- Cerrar recordando REQUISITOS.md y el `docker pull` previo.

**Demo en pantalla (imprescindible en este vídeo):** abrir el
`docker-compose.yml` real del repositorio e ir recorriéndolo de arriba abajo
señalando cada concepto. Es el vídeo que más cohesiona el módulo.

---

## Notas de producción

**Orden de grabación sugerido:** el 7 al final y de una sentada con el 6,
porque comparten el hilo del proyecto real.

**Qué mostrar en pantalla:** los vídeos 2, 4, 5 y 7 ganan muchísimo con
terminal en vivo. Los vídeos 1, 3 y 6 funcionan bien con diapositivas.

**Si un vídeo se alarga:** córtalo en dos antes que acelerar. Por encima de
15 minutos la tasa de abandono se dispara.

**Errores a propósito:** en los vídeos 4 y 5, provocar el fallo antes de
enseñar la solución (`ModuleNotFoundError` antes del Dockerfile; conexión
rechazada antes de `-p`). Se recuerda mucho mejor el concepto cuando se ha
visto primero el síntoma.

**Lo que NO debe entrar en los vídeos** (se dice explícitamente en TEORIA.md
que queda fuera): multi-stage builds, redes personalizadas, Docker Swarm,
registries privados, CI/CD y optimización de imágenes. Si se cuelan, el
módulo se desborda.
