<div class="cover">
<div class="cover-modulo">Módulo · Contenedores y Virtualización</div>
<h1 class="cover-title">Sesión 1<br>Docker: imágenes y contenedores</h1>
<div class="cover-sub">Apuntes de apoyo · Máster en Data Engineering, MLOps &amp; Arquitectura Cloud</div>
<div class="cover-meta">
Contenido de referencia para repaso. Estos apuntes desarrollan por escrito lo que se ve
en las diapositivas y en los vídeos de teoría, y añaden el detalle que en clase se
menciona de pasada.
</div>
</div>

<div class="page-break"></div>

## Cómo usar estos apuntes

Este documento **no sustituye a la sesión en directo ni a los ejercicios**: es el
soporte al que volver cuando algo no encaja, cuando hay que preparar la entrega, o
cuando dentro de seis meses te encuentres un `Dockerfile` en el trabajo y necesites
recordar por qué el orden de las líneas importaba.

Está organizado igual que la sesión, así que puedes ir directo al bloque que te
interese. Encontrarás cuatro tipos de caja destacada:

!!! definicion "Definición"
    El concepto formal, redactado para que puedas citarlo tal cual en una entrega.

!!! aviso "Ojo con esto"
    Trampas, errores frecuentes y detalles que cuestan horas si se pasan por alto.

!!! practica "En la práctica"
    Cómo se traduce el concepto al trabajo real de un ingeniero de datos.

!!! error "Error clásico"
    El fallo concreto que casi todo el mundo comete una vez. Mejor cometerlo aquí.

**Objetivos de la sesión.** Al terminar deberías ser capaz de:

1. Explicar la diferencia entre imagen y contenedor sin dudar.
2. Arrancar, inspeccionar, parar y borrar contenedores con criterio.
3. Hacer que los datos sobrevivan al borrado de un contenedor.
4. Publicar un puerto y saber diagnosticar por qué a veces no funciona.
5. Escribir un `Dockerfile` que añada dependencias a una imagen oficial.

---

## 1. El problema que resuelve Docker

### 1.1 "En mi máquina funciona"

La frase más cara de la industria del software no es una excusa: **casi siempre es
literalmente cierta**. El código es idéntico en los dos sitios; lo que cambia es el
entorno donde se ejecuta.

| Tu portátil | El servidor de producción |
|---|---|
| Python 3.11 | Python 3.9 |
| pandas 2.1 | pandas 1.5 |
| Postgres 16 | Postgres 13 |
| macOS, Apple Silicon (arm64) | Ubuntu 20.04, x86 (amd64) |
| Una variable de entorno que pusiste hace tres meses | Otra configuración distinta, puesta por otra persona |

El software no se ejecuta en el vacío: se ejecuta en un entorno. Y ese entorno, en un
equipo de datos, es especialmente frágil.

**El coste real del desajuste** no es estético. Es la mayor fuente de fricción entre
desarrollo y operaciones:

1. Un pipeline que funciona en local y falla de madrugada en producción.
2. Dos días de un ingeniero replicando un entorno a mano, siguiendo un documento de
   cuarenta pasos que además está desactualizado.
3. Dos proyectos en el mismo servidor que necesitan versiones incompatibles de la
   misma librería.
4. Un compañero nuevo que tarda una semana en poder ejecutar el proyecto.
5. **Nadie se atreve a actualizar nada, porque nadie sabe qué se rompería.**

El quinto punto es el más grave: es el momento en el que un equipo de datos deja de
avanzar.

### 1.2 El intento anterior: máquinas virtuales

La idea era correcta: *si el problema es el entorno, empaquetemos el entorno completo*.
Eso es una máquina virtual — la aplicación, sus librerías y **un sistema operativo
entero con su propio kernel**, todo corriendo sobre un hipervisor.

<figure>
<img src="img/s10.png" alt="Arquitectura de máquinas virtuales">
<figcaption><strong>Figura 1.1.</strong> Arquitectura de máquinas virtuales. Cada VM
arrastra un sistema operativo completo de unos 2 GB. Ahí está a la vez su gran virtud
—el aislamiento es total— y su gran problema.</figcaption>
</figure>

Funciona, pero el precio es alto:

| Aspecto | Máquina virtual |
|---|---|
| Tamaño | Gigabytes: lleva un sistema operativo completo |
| Arranque | Minutos: arranca un SO de verdad, con su kernel |
| Densidad | Unas pocas por servidor |
| Recursos | RAM y CPU reservadas por adelantado, se usen o no |

!!! aviso "La frase que resume el problema"
    Para aislar una aplicación de 50 MB, arrancas un sistema operativo de 2 GB. La idea
    es correcta; **la unidad de empaquetado es demasiado gruesa**.

### 1.3 De dónde sale Docker

Aquí conviene desmontar un mito: **Docker no inventó el aislamiento**. Las piezas ya
estaban en el kernel de Linux, repartidas, y llevaban décadas ahí.

| Año | Pieza | Qué aportó |
|---|---|---|
| 1979 | `chroot` | Cambiar la raíz del sistema de archivos de un proceso |
| 2002 | *namespaces* | Que un proceso vea su propia red, sus propios procesos, su propio sistema de archivos |
| 2006 | *cgroups* (de Google) | Limitar cuánta CPU y memoria puede consumir un grupo de procesos |
| 2008 | LXC | Junta lo anterior en "contenedores de Linux"… pero es difícil de usar |

Todo estaba disponible y era gratis. Y casi nadie lo usaba, porque montar un contenedor
a mano con esas herramientas requería ser experto en el kernel.

En **marzo de 2013**, una empresa llamada dotCloud —a punto de cerrar— liberó como
código abierto la capa interna que usaba para empaquetar el código de sus clientes en
contenedores de Linux. La presentaron en una charla de cinco minutos en la PyCon de
Santa Clara. En meses, el proyecto valía más que la empresa entera, y dotCloud se
renombró **Docker, Inc.**

> **Docker no inventó los contenedores. Los hizo usables.**

Lo que sí inventó fueron tres cosas, y ninguna es tecnología de kernel — las tres son
de experiencia de uso:

1. **Un formato de imagen por capas**: empaquetar una aplicación y su entorno en un
   artefacto inmutable y reutilizable.
2. **El Dockerfile**: una receta de texto, versionable en Git, que describe paso a paso
   cómo se construye esa imagen.
3. **Un registro público** (Docker Hub): un sitio centralizado del que descargar
   imágenes ya creadas y al que subir las tuyas.

Estandarizar el empaquetado y el reparto. Eso es lo que cambió la industria.

!!! practica "La analogía que le da nombre"
    Antes de 1956, transportar mercancías era un caos: sacos, cajas y barriles, cada
    cosa manipulada de una forma distinta. Descargar un barco eran días, porque el
    barco, la grúa y el camión tenían que **conocer la carga**. Con el contenedor de
    mercancías estándar —una caja metálica de medidas fijas— descargar pasó a ser horas,
    porque el barco, la grúa y el camión solo conocen **la caja**. Docker hace lo mismo
    con el software: da igual si dentro hay Python, Java o Go; la plataforma solo conoce
    el contenedor.

### 1.4 Contenedor frente a máquina virtual

La diferencia técnica es una sola, y de ella se derivan todas las demás: **el
contenedor comparte el kernel del anfitrión**.

<figure>
<img src="img/s17.png" alt="Comparativa de arquitectura: VM frente a contenedores">
<figcaption><strong>Figura 1.2.</strong> A la izquierda, cada aplicación arrastra su
propio sistema operativo. A la derecha, todas comparten el kernel del anfitrión y solo
se aíslan mediante <em>namespaces</em> y <em>cgroups</em>.</figcaption>
</figure>

| | Máquina virtual | Contenedor |
|---|---|---|
| **Qué aísla** | Hardware completo, con su propio kernel | Procesos, sobre el kernel del anfitrión |
| **Tamaño típico** | 1–20 GB | 50 MB – 1 GB |
| **Arranque** | Minutos | Menos de un segundo (~100 ms) |
| **RAM mínima** | 512 MB – 2 GB | 10–100 MB |
| **Cuántos caben** | Unas decenas por servidor | Cientos |
| **Aislamiento** | Muy fuerte | Bueno, pero comparte kernel |
| **Cuándo usar cada uno** | Sistemas operativos distintos, aislamiento estricto | Empaquetar y desplegar aplicaciones |

Dos matices que conviene tener claros:

- **No compiten, conviven.** En la nube, tus contenedores casi siempre corren *dentro*
  de máquinas virtuales.
- **En macOS y Windows, Docker Desktop arranca una VM de Linux** por debajo, porque los
  contenedores necesitan un kernel de Linux. Si tienes Mac, cuando ejecutas un
  contenedor hay una máquina virtual de por medio: es un detalle que explica algún
  comportamiento raro de rendimiento con volúmenes.

### 1.5 Qué NO es Docker

Tres malentendidos que conviene desactivar desde el principio:

| Malentendido | Realidad |
|---|---|
| **No es una máquina virtual ligera** | No hay un sistema operativo dentro: son procesos aislados del anfitrión mediante funciones del kernel de Linux |
| **No resuelve solo tus dependencias** | Te obliga a *declararlas* explícitamente, que es lo que las hace reproducibles. El trabajo lo sigues haciendo tú |
| **No es seguro por defecto** | Un contenedor mal configurado puede acceder al anfitrión. Aísla, pero no es una barrera de seguridad completa |

### 1.6 Por qué esto importa especialmente en Data Engineering

El problema de dependencias en datos es **peor** que en cualquier otro sitio. Mira lo
que arrastra un stack de datos típico:

- Python con `pandas`, `numpy`, `pyarrow`.
- Bibliotecas de sistema en C: `libpq`, `libgeos`, `libhdf5`.
- La JVM entera, si hay Spark.
- Drivers ODBC y clientes de bases de datos.
- Versiones de Airflow con dependencias fijadas al milímetro.

¿Por qué duele? Porque un `pip install` falla al compilar en Linux y funciona en macOS.
O porque tienes un cluster de Spark donde cada nodo arrastra una versión distinta de
una librería, y las cosas fallan **solo a veces** — que es la peor forma de fallar.

!!! practica "Dónde te vas a encontrar Docker en este máster"
    **Airflow** (su despliegue estándar es Compose o Kubernetes) · **bases de datos en
    local** (Postgres, Kafka, MinIO en un comando y sin ensuciar tu equipo) · **Spark**
    (cada ejecutor arranca como un contenedor con las mismas dependencias) · **dbt** (la
    imagen fija la versión de dbt y del adaptador) · **tareas de un DAG**
    (`DockerOperator` y `KubernetesPodOperator`) · **notebooks y ML** (la imagen fija
    versiones de CUDA, PyTorch y drivers).

### 1.7 El ecosistema hoy

Docker ya no está solo, y conviene no quedarse con una foto desactualizada:

- **OCI** (2015): el formato de imagen se estandarizó. Ya no es "de Docker", es un
  estándar abierto de la industria.
- **containerd**: el motor que ejecuta contenedores, extraído de Docker y donado a la
  CNCF. Es lo que usa Kubernetes por debajo.
- **Podman, Buildah**: alternativas compatibles, sin demonio de fondo y sin necesidad de
  permisos de *root*.
- **Kubernetes**: orquesta esos contenedores en cientos de máquinas (sesión 3).

!!! dato "Un dato que sorprende"
    **Kubernetes dejó de usar Docker como motor en 2022.** Y aun así sigue ejecutando
    imágenes construidas con Docker, porque el formato es estándar. Por eso lo que
    aprendes aquí no caduca.

---

## 2. Los tres conceptos fundamentales

Toda la sesión se apoya en distinguir tres palabras. Si se mezclan, nada de lo demás
encaja.

!!! definicion "Imagen, contenedor, registro"
    **Imagen**: plantilla de **solo lectura** que contiene un sistema de archivos
    mínimo (librerías, binarios, tu aplicación) y metadatos (qué comando ejecutar, qué
    puertos documenta, con qué usuario correr). Es estática y no se ejecuta.

    **Contenedor**: **instancia en ejecución** de una imagen, con su propia capa de
    escritura temporal encima. Es un proceso vivo.

    **Registro (*registry*)**: servidor donde viven las imágenes. Se descargan con
    `docker pull` y se suben con `docker push`. El público por defecto es **Docker Hub**.

La analogía canónica, la que hay que memorizar:

> **imagen : contenedor :: clase : objeto :: receta : plato**

De una misma imagen puedes arrancar **cien contenedores independientes**, igual que de
una clase instancias cien objetos o de una receta salen cien platos. Y la imagen **no
cambia nunca**.

<figure>
<img src="img/s21.png" alt="Ciclo completo de Docker">
<figcaption><strong>Figura 1.3.</strong> El ciclo completo de Docker. Es, literalmente,
todo lo que hace la herramienta: un Dockerfile versionado en Git se convierte en imagen
con <code>build</code>, la imagen se convierte en contenedor con <code>run</code>, y
viaja al registro con <code>push</code>/<code>pull</code>.</figcaption>
</figure>

La consecuencia práctica de ese diagrama es la frase que justifica todo el módulo:
**el mismo artefacto corre en tu portátil, en el sistema de integración continua y en
producción**.

!!! aviso "El matiz incómodo"
    Que tu portátil, el sistema de integración y producción ejecuten *los mismos bytes*
    significa también que **si tu imagen está mal construida, está mal construida en
    todas partes**. Docker no arregla el problema: lo hace **reproducible**. Que es
    muchísimo —un error reproducible se puede arreglar; uno que aparece solo a veces,
    no— pero no es magia.

---

## 3. Ciclo de vida de un contenedor

Este es el concepto que más errores causa en las primeras semanas.

### 3.1 Los tres estados

!!! definicion "La regla fundamental"
    Un contenedor **vive exactamente lo que viva su proceso principal**. No es una
    máquina virtual que arrancas y se queda encendida esperando.

Si ejecutas un contenedor cuyo comando es `echo hola`, imprime "hola", el proceso
termina, y el contenedor **se para inmediatamente**. No está roto: ha hecho su trabajo.

<figure>
<img src="img/s45.png" alt="Los tres estados de un contenedor">
<figcaption><strong>Figura 1.4.</strong> Los tres estados de un contenedor. Fíjate en
que solo uno de ellos significa que ha desaparecido de verdad.</figcaption>
</figure>

**RUNNING** — el proceso principal está vivo. Puedes ver su salida con `docker logs -f`,
entrar con `docker exec -it`, y pararlo con `docker stop`.

**EXITED** — el proceso terminó, por sí solo o porque lo paraste. El contenedor **sigue
existiendo**: ocupa espacio en disco, aparece en `docker ps -a`, y puedes resucitarlo
con `docker start`.

**BORRADO** — desapareció del sistema. Solo ocurre con `docker rm`.

Tres ideas que hay que fijar, porque casi todas las confusiones del primer día salen de
aquí:

1. Un contenedor `EXITED` **no está borrado**. Sigue ocupando espacio y aparece
   únicamente con `docker ps -a`.
2. Solo `docker rm` lo borra de verdad. `docker stop` detiene la ejecución pero no
   borra nada.
3. `docker run --rm` se autoelimina al terminar su proceso. Úsalo para pruebas rápidas
   de un solo uso.

!!! practica "Consejo de diagnóstico rápido"
    Si `docker ps` no muestra tu contenedor, prueba **siempre** con `docker ps -a`
    antes de intentar lanzarlo otra vez. Lo más probable es que siga ahí, parado, y la
    explicación del fallo esté en sus logs. La alternativa —volver a lanzarlo— es cómo
    la gente acaba con veinte contenedores muertos y el disco lleno.

### 3.2 `docker run` y sus flags

Hay decenas de flags. Con estos ocho cubres el 95 % de los casos:

| Flag | Qué hace | Ejemplo |
|---|---|---|
| `-d` | Segundo plano (*detached*): devuelve el control a tu terminal | `docker run -d nginx` |
| `-it` | Shell interactiva (`-i` mantiene stdin, `-t` asigna terminal) | `docker run -it alpine sh` |
| `-e VAR=valor` | Define una variable de entorno | `-e POSTGRES_PASSWORD=secreto` |
| `-p host:cont` | Publica un puerto | `-p 8080:80` |
| `-v origen:destino` | Monta datos (volumen o bind mount) | `-v datos:/var/lib/postgresql` |
| `--name nombre` | Nombre fijo; si no, Docker inventa uno aleatorio | `--name mi-db` |
| `--rm` | Se autoelimina al terminar | `docker run --rm alpine echo hola` |
| `--restart política` | Política de reinicio | `--restart unless-stopped` |

!!! aviso "`-d` y `--rm` juntos son traicioneros"
    Si lanzas algo en segundo plano con `--rm` y falla, el contenedor se borra **con sus
    logs dentro** y te quedas sin poder investigar qué pasó. Cómodo, pero peligroso
    mientras depuras.

**Ejemplos prácticos:**

```bash
# 1. Postgres en segundo plano, configurado y con volumen
docker run -d --name mi-db \
  -e POSTGRES_PASSWORD=secreto \
  -v mi_datos:/var/lib/postgresql \
  postgres:18-alpine

# 2. Un script de Python que imprime y termina, sin instalar Python
docker run --rm -v "$(pwd)":/app python:3.14 python /app/script.py

# 3. Shell interactiva en Ubuntu para explorar
docker run -it ubuntu bash

# 4. Nginx publicado en el 8080 de tu máquina
docker run -d --name web -p 8080:80 nginx
```

### 3.3 Inspeccionar: lo que harás cuando algo falle

```bash
docker ps                        # contenedores en ejecución
docker ps -a                     # todos, incluidos los parados
docker logs <contenedor>         # salida completa (stdout + stderr)
docker logs -f <contenedor>      # sigue en tiempo real, como tail -f
docker logs --tail 50 <cont>     # solo las últimas 50 líneas
docker exec -it <cont> sh        # abre una shell DENTRO del contenedor
docker inspect <cont>            # JSON completo: IP, volúmenes, variables
docker top <cont>                # procesos dentro del contenedor
docker stats <cont>              # CPU, memoria e I/O en vivo
```

> **`docker logs` es la primera herramienta de diagnóstico, no la última.** Antes de
> reinstalar nada, antes de recrear el contenedor y antes de preguntar: lee los logs.
> La respuesta suele estar literalmente escrita ahí.

### 3.4 Ciclo de vida operativo, paso a paso

```bash
# 1. Crear y arrancar
docker run -d --name mi-postgres \
  -e POSTGRES_PASSWORD=secreto \
  -v datos:/var/lib/postgresql \
  postgres:18-alpine

# 2. Comprobar que corre
docker ps
#  CONTAINER ID  IMAGE                STATUS         NAMES
#  abc123...     postgres:18-alpine   Up 5 seconds   mi-postgres

# 3. Leer sus logs
docker logs mi-postgres
#  database system is ready to accept connections

# 4. Entrar y consultar
docker exec -it mi-postgres psql -U postgres -c "SELECT version();"

# 5. Pararlo
docker stop mi-postgres

# 6. Sigue existiendo
docker ps -a
#  abc123...     postgres:18-alpine   Exited (0)     mi-postgres

# 7. Resucitarlo
docker start mi-postgres

# 8. Borrarlo definitivamente
docker rm mi-postgres
```

### 3.5 Por qué esto lleva directo a los volúmenes

<figure>
<img src="img/s51.png" alt="Capa de escritura y capas de imagen">
<figcaption><strong>Figura 1.5.</strong> Las capas de la imagen son de solo lectura e
inmutables. La capa de escritura se crea al iniciar el contenedor y
<strong>se borra permanentemente con <code>docker rm</code></strong>.</figcaption>
</figure>

Todo lo que escriba tu proceso —una fila en una tabla, un log, un `parquet`— va a la
capa de escritura. Y esa capa es mortal.

!!! error "El error que se comete una vez en la vida"
    Si tienes PostgreSQL en un contenedor **sin volumen**, un `docker rm` borra **toda
    tu base de datos**. Y recrear el contenedor para actualizar la imagen, también.

Los volúmenes existen exactamente para sacar los datos fuera del ciclo de vida del
contenedor.

---

## 4. Volúmenes y puertos

Dos mecanismos **independientes**: uno para que los datos duren, otro para que alguien
pueda hablar con el proceso. Confundirlos es clásico: publicar un puerto no persiste
nada, y montar un volumen no abre ninguna red.

### 4.1 Volúmenes: las dos formas de montar datos

<figure>
<img src="img/s53.png" alt="Bind mount frente a volumen con nombre">
<figcaption><strong>Figura 1.6.</strong> Bind mount para tu código; volumen con nombre
para tus datos. No son intercambiables.</figcaption>
</figure>

!!! definicion "Bind mount"
    Montas una ruta **que tú eliges, de tu máquina**, dentro del contenedor. Docker no
    gestiona nada: simplemente hace visible esa carpeta dentro.

    ```bash
    docker run -v "$(pwd)/dags":/opt/airflow/dags apache/airflow:3.3.1-python3.14
    #           │                 │
    #           │                 └── ruta DENTRO del contenedor
    #           └── ruta EN TU MÁQUINA (la eliges tú; debe existir)
    ```

    `./dags` en tu proyecto y `/opt/airflow/dags` dentro del contenedor pasan a ser
    **literalmente el mismo directorio** visto desde dos sitios. Escribes un DAG en tu
    editor y Airflow lo ve al instante, sin reconstruir ni reiniciar nada.

!!! definicion "Volumen con nombre (*named volume*)"
    Le pides a Docker que gestione un espacio de almacenamiento; tú solo pones un
    nombre y **no eliges dónde vive** (bajo `/var/lib/docker/volumes/<nombre>/_data`).

    ```bash
    docker run -v postgres_data:/var/lib/postgresql postgres:18-alpine
    ```

    Si no existe, Docker lo crea la primera vez. **Sobrevive a `docker rm`**, es
    portable entre máquinas y Docker sabe respaldarlo y migrarlo.

**Diferencias clave:**

| Aspecto | Bind mount | Volumen con nombre |
|---|---|---|
| ¿Quién elige la ruta? | Tú, una ruta concreta | Docker; tú solo das un nombre |
| ¿Dónde vive? | Donde tú digas | Zona gestionada por Docker |
| ¿Lo editas desde tu editor? | Sí, es una carpeta normal | No directamente |
| ¿Sobrevive a `docker rm`? | Sí (es tu carpeta) | Sí (salvo `docker rm -v` / `down -v`) |
| ¿Migrable entre máquinas? | Depende de la ruta | Sí, con `docker volume` |
| Caso de uso típico | Código, DAGs, configuración | Bases de datos, estado interno |

**La regla rápida para proyectos de datos:**

| Qué guardas | Qué usar | Por qué |
|---|---|---|
| Datos de una base de datos | **Volumen con nombre** | No necesitas tocarlos a mano; Docker los gestiona y migra |
| Tu código: DAGs, scripts, notebooks | **Bind mount** | Quieres editarlos y verlos al instante |
| Logs que lees desde tu editor | **Bind mount** | Acceso directo desde el host |
| Datos temporales de una tarea | **Nada** | Que se pierdan es lo correcto |

```bash
docker volume ls                     # lista los volúmenes con nombre
docker volume inspect postgres_data  # dónde vive y quién lo usa
docker volume rm postgres_data       # lo borra (¡pierdes los datos!)
```

!!! aviso "Caso real de este proyecto"
    Un volumen `postgres_data` creado con **Postgres 15 no arranca** con la imagen
    `postgres:18-alpine`: el formato de datos en disco cambia entre versiones mayores.
    Hubo que borrarlo con `docker compose down -v`. Es decir: el volumen te salva de
    perder datos por accidente, pero **también te ata a la versión que los creó**. El
    día que actualices una base de datos en producción, esto deja de ser una anécdota.

### 4.2 Puertos: exponer un servicio al exterior

Cada contenedor arranca con **su propia red aislada**. Aunque el proceso escuche en el
8080, ese puerto **no es alcanzable** desde tu máquina hasta que lo publicas.

<figure>
<img src="img/s55.png" alt="Un puerto dentro del contenedor no es alcanzable">
<figcaption><strong>Figura 1.7.</strong> Tu <code>localhost</code> y el
<code>localhost</code> del contenedor no son el mismo sitio. Ese aspa es,
literalmente, tu primer día con Docker.</figcaption>
</figure>

La bandera `-p` crea el puente, y **se lee siempre igual**:

```bash
docker run -p 8080:8080 apache/airflow:3.3.1-python3.14 api-server
#           │    │
#           │    └── puerto DENTRO del contenedor (donde escucha el proceso)
#           └── puerto EN TU MÁQUINA (el que abres en el navegador)
```

> **Izquierda fuera, derecha dentro.** Si te lo aprendes en ese orden, te ahorras
> muchos disgustos.

Los dos números **no tienen por qué coincidir**. `-p 9090:8080` es perfectamente
válido: abres el navegador en el 9090 y por dentro llega al 8080. Es utilísimo cuando
dos proyectos quieren el mismo puerto.

**Variantes de `-p`:**

| Sintaxis | Efecto |
|---|---|
| `-p 8080:8080` | Publica en **todas** las interfaces: accesible desde tu red local |
| `-p 127.0.0.1:8080:8080` | Solo `localhost`: nadie más en tu wifi puede entrar |
| `-p 9090:8080` | Puertos distintos a ambos lados — perfectamente válido |
| `-p 8080-8090:8080-8090` | Publica un rango |
| `-P` (mayúscula) | Publica todos los `EXPOSE` en puertos aleatorios |

!!! aviso "Seguridad: la forma corta te expone a toda la wifi"
    `-p 8088:8080` publica en `0.0.0.0`, es decir, en todas las interfaces de la
    máquina. Cualquiera en la misma red que conozca tu IP puede entrar. Por eso en
    nuestro `docker-compose.yml` real usamos `127.0.0.1:8080:8080` **a propósito**. El
    detalle fino se estudia en el módulo de *Security and Optimization*, pero conviene
    tenerlo como buena práctica por defecto desde ya.

!!! error "`EXPOSE` no publica nada"
    `EXPOSE 8080` en un Dockerfile es **solo un metadato**: le dice a quien use la
    imagen "este proceso escucha aquí", pero no abre nada. El que abre la puerta de
    verdad es `-p` (o `ports:` en Compose). Mucha gente pierde una tarde con esto.

    Corolario práctico: el número de la derecha de `-p` **no te lo inventas**. Tiene
    que coincidir con el puerto real donde escucha la aplicación. Compruébalo con:

    ```bash
    docker inspect --format='{{.Config.ExposedPorts}}' <contenedor>
    docker port <contenedor>
    ```

!!! practica "Entre contenedores NO hace falta `-p`"
    Si dos contenedores necesitan hablar entre ellos (Airflow con Postgres, por
    ejemplo), les basta con estar en la misma red de Docker y usar el nombre del
    servicio como *hostname*. `-p` sirve **solo** para llegar desde tu máquina. Esto se
    desarrolla en la sesión 2.

---

## 5. Imágenes en profundidad

### 5.1 Qué contiene una imagen

<figure>
<img src="img/s59.png" alt="Una imagen es un snapshot de un sistema de archivos">
<figcaption><strong>Figura 1.8.</strong> Contenido de una imagen y las cuatro cosas que
hace <code>docker run</code>.</figcaption>
</figure>

Una imagen es un **snapshot** de un sistema de archivos: capas de solo lectura más
metadatos. Dentro lleva un sistema operativo mínimo (Alpine son 7 MB, Ubuntu 77 MB),
librerías y binarios, tu aplicación con sus dependencias, y metadatos (comando por
defecto, variables, puertos, usuario).

Y `docker run` hace exactamente cuatro cosas:

1. Descarga la imagen si no la tiene localmente.
2. Crea un contenedor nuevo.
3. **Le añade una capa de escritura encima.**
4. Arranca el proceso principal.

### 5.2 Oficiales frente a personalizadas

Se distinguen por una tontería que conviene saber leer: **si no hay prefijo de
organización, es oficial**.

| Oficiales (sin prefijo) | Personalizadas (con `organización/`) |
|---|---|
| `postgres:18-alpine` | `apache/airflow:3.3.1-python3.14` |
| `python:3.13-slim` | `bitnami/postgresql:18` |
| `nginx:1.27` | `tu-usuario/mi-pipeline:1.0` |
| `alpine:3.21` | |
| *Mantenidas por el propio proyecto* | *Publicadas por empresas, comunidades o por ti* |

**¿Usar la oficial directamente o construir la mía?**

| Aspecto | Usar la oficial | Construir la tuya |
|---|---|---|
| ¿De dónde viene? | Descargada del registro | Construida por ti con `docker build`, basada en la oficial |
| ¿Qué contiene? | La herramienta y nada más | La oficial **más** tus dependencias y configuración |
| ¿Dónde pasas la config? | En cada `docker run`, con flags | Ya está dentro de la imagen |
| ¿Reproducibilidad? | Si olvidas un `-e`, falla | Imposible equivocarse: la imagen es idéntica cada vez |
| Compartir con el equipo | "Ejecuta esto con estos flags…" | "Usa `mi-imagen:1.0`. Punto." |

Tu imagen personalizada **no reemplaza a la oficial: la contiene** y le apila capas
encima.

```
docker.io/library/postgres:18-alpine   (imagen oficial)
            ↓  sirve de BASE
        tu Dockerfile  →  docker build -t mi-postgres:18 .
            ↓  tus capas encima
        mi-postgres:18   (tu imagen personalizada)
```

### 5.3 El nombre completo de una imagen

<figure>
<img src="img/s61.png" alt="El nombre completo de una imagen">
<figcaption><strong>Figura 1.9.</strong> Las cuatro partes del nombre de una imagen y
lo que Docker rellena por ti cuando omites alguna.</figcaption>
</figure>

El patrón completo es:

```
[REGISTRY]/[ORGANIZACIÓN]/IMAGEN:TAG
```

Y si omites partes, Docker asume valores por defecto:

| Si omites... | Docker asume |
|---|---|
| El registry | `docker.io` |
| La organización | `library` (imágenes oficiales) |
| El tag | `latest` |

> Así que ese `postgres` inocente que has escrito es en realidad
> **`docker.io/library/postgres:latest`**. Y ahí empiezan los sustos.

### 5.4 `latest` es una promesa que nadie te ha hecho

!!! error "El origen de la mitad de los «a mí me funcionaba ayer»"
    `latest` **no significa "la última versión estable"**. Es simplemente el tag que se
    usa si no especificas ninguno, y apunta a lo que el que publicó la imagen haya
    decidido. Puede cambiar debajo de tus pies sin avisar.

    ```bash
    docker pull postgres
    # Hoy:        PostgreSQL 18.3
    # En 3 meses: PostgreSQL 19.0 (posiblemente incompatible con tu código)
    ```

    Tu compañero ejecuta el mismo comando y obtiene otra versión. Y es especialmente
    desagradable de diagnosticar, porque **en Git no hay ningún cambio que mirar**.

**La regla, sin excepciones: en un proyecto real, nunca `latest`.** Ni en el
Dockerfile, ni en el Compose. En nuestro proyecto está fijado en el `.env`:

```env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
```

Y ya que sale: el sufijo **`alpine`** que ves por todas partes es una distribución de
Linux minúscula. Esas variantes ocupan una fracción de la normal (`postgres:18-alpine`
son 286 MB frente a 479 MB de `postgres:18`), y menos tamaño es menos tiempo de
descarga y menos superficie de ataque.

### 5.5 Una imagen no vale para cualquier procesador

Un Mac con Apple Silicon es `arm64`. El servidor de tu empresa es, casi seguro, `amd64`.

**El síntoma** es este mensaje maravillosamente críptico:

```
$ docker run mi-imagen:1.0
exec format error
```

Y hay una variante peor, porque al menos el error se ve: que **arranque pero vaya diez
veces más lento**, porque está emulando la arquitectura. Ese lo descubres tres semanas
después preguntándote por qué tu pipeline tarda una eternidad.

**La solución** es declarar la plataforma explícitamente, al construir y al ejecutar:

```bash
docker build --platform linux/amd64 -t mi-app:1.0 .
docker run   --platform linux/amd64 mi-app:1.0
```

!!! practica "Matiz importante"
    Las imágenes **oficiales** (postgres, python, airflow) son multiarquitectura y
    Docker elige la tuya solo — por eso te funcionan sin pensar. El problema aparece con
    **la tuya**: construida en tu Mac, desplegada en un Linux amd64.

### 5.6 Registries

| Registry | Proveedor | Punto de acceso |
|---|---|---|
| **Docker Hub** | Docker Inc. | `docker.io` (implícito) |
| **ECR** | Amazon AWS | `<cuenta>.dkr.ecr.<región>.amazonaws.com` |
| **Artifact Registry** | Google Cloud | `<región>-docker.pkg.dev` |
| **GHCR** | GitHub | `ghcr.io` |
| **Quay.io** | Red Hat | `quay.io` |
| **Harbor** | CNCF (autohospedado) | El tuyo |

En cualquier empresa con nube, tus imágenes acabarán en **ECR o Artifact Registry**, no
en Docker Hub. La buena noticia: la mecánica es **idéntica** en todos —
`login → build → push → pull`. Aprendes uno y los sabes todos; solo cambian la URL y la
forma de autenticarse.

```bash
docker build -t mi-usuario/mi-imagen:1.0 .
docker login
docker push mi-usuario/mi-imagen:1.0
```

### 5.7 Capas y caché

<figure>
<img src="img/s70.png" alt="Capas y caché en la construcción de imágenes">
<figcaption><strong>Figura 1.10.</strong> Cada <code>RUN</code>, <code>COPY</code> y
<code>ADD</code> crea una capa que Docker cachea. Si cambias una, se rehacen todas las
que vienen detrás.</figcaption>
</figure>

Las imágenes se componen de **capas apiladas**, todas de solo lectura. Esto tiene dos
consecuencias muy concretas:

**Primera: las capas se comparten.** Si tienes cinco imágenes construidas sobre
`python:3.13-slim`, esa base está en disco **una sola vez**. Por eso `docker images`
puede sumarte 15 GB cuando en disco real ocupas 6.

**Segunda: la caché**, que explica por qué a veces un build tarda dos segundos y otras
cuatro minutos. Docker reutiliza las capas que no han cambiado, pero **en cuanto una
capa cambia, todas las que vienen detrás se reconstruyen**.

> **Regla de oro: lo que cambia poco (dependencias) va arriba. Lo que cambia siempre
> (tu código) va abajo.**

Traducido: tus dependencias cambian una vez al mes; tu código, veinte veces al día. Si
pones el `COPY` del código **antes** del `pip install`, cada coma que toques invalida
esa capa y Docker reinstala **todas** las dependencias desde cero. Si lo pones
**después**, la capa del `pip install` se mantiene cacheada. Es el mismo Dockerfile,
las mismas instrucciones, solo cambiadas de orden — y es la diferencia entre cinco
minutos y tres segundos por cada cambio.

**Espacio en disco.** Órdenes de magnitud reales:

| Imagen | Tamaño |
|---|---|
| `alpine:3.21` | 7 MB |
| `ubuntu:24.04` | 77 MB |
| `postgres:18-alpine` | 286 MB |
| `python:3.14` | ~950 MB |
| `apache/airflow:3.3.1-python3.14` | ~1,5 GB |

```bash
docker system df                    # cuánto ocupa Docker en total
docker image ls
docker history <imagen>             # las capas de una imagen, con su tamaño
```

---

## 6. Construir imágenes con un Dockerfile

Como ingeniero de datos, **rara vez escribirás una imagen desde cero**. Lo que harás
cada semana es **añadirle dependencias a una oficial**.

### 6.1 Las siete instrucciones que necesitas

| Instrucción | Qué hace |
|---|---|
| `FROM imagen:tag` | Imagen base. **Siempre la primera línea.** |
| `WORKDIR /ruta` | Directorio de trabajo (lo crea si no existe) |
| `COPY origen destino` | Copia archivos de tu máquina a la imagen |
| `RUN comando` | Ejecuta algo **durante el build** y guarda el resultado como capa |
| `ENV CLAVE=valor` | Variable de entorno, disponible en build y en *runtime* |
| `USER usuario` | Usuario con el que se ejecuta lo siguiente y el contenedor final |
| `CMD ["..."]` | Comando por defecto al arrancar. **Se puede sobrescribir.** |

!!! aviso "`RUN` frente a `CMD`: la confusión más habitual"
    **`RUN` se ejecuta al construir; `CMD`, al arrancar.** `RUN` deja su resultado
    grabado dentro de la imagen. `CMD` solo dice qué pasará después.

**El Dockerfile mínimo** son cuatro líneas y dos comandos:

```dockerfile
FROM alpine:3.21
WORKDIR /usr/src/app
COPY hello.sh .
CMD ["./hello.sh"]
```

```bash
docker build -t hello-docker .
docker run hello-docker
```

### 6.2 El caso que más te va a tocar

Tienes Airflow corriendo, escribes un DAG que hace `import pandas`, y te peta con
`ModuleNotFoundError`. Porque la imagen oficial de Airflow no trae pandas.

```dockerfile
FROM apache/airflow:3.3.1-python3.14

# La imagen de Airflow define USER airflow;
# pip debe ejecutarse como ese usuario
RUN pip install --no-cache-dir pandas==2.2.3
```

Tres líneas. Acabas de crear "la imagen de Airflow **más** pandas".

Para una lista larga de dependencias se usa un `requirements.txt`:

```dockerfile
FROM apache/airflow:3.3.1-python3.14
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

!!! aviso "Dos detalles que fallan siempre"
    **1. El usuario.** La imagen de Airflow define `USER airflow`, y `pip` se tiene que
    ejecutar como ese usuario. Si metes un `USER root` ahí, Airflow luego no encontrará
    los paquetes.

    **2. `--no-cache-dir`.** Evita que pip guarde su caché de descarga dentro de la
    capa. Esa caché no te sirve de nada dentro de una imagen inmutable y puede añadir
    cientos de megas al tamaño final.

!!! error "Instalarlo a mano con `docker exec`"
    `docker exec ... pip install pandas` funciona… **hasta que borras el contenedor**.
    Y entonces vuelve el `ModuleNotFoundError` y ya no te acuerdas de qué instalaste. Lo
    del Dockerfile es permanente y reproducible; lo del `exec` es una nota mental que se
    pierde.

Y en Compose, en vez de `image:`, se indica `build:` para que Compose construya tu
imagen:

```yaml
services:
  airflow-scheduler:
    build: .        # busca un Dockerfile en este directorio
```

### 6.3 El contexto de build y `.dockerignore`

<figure>
<img src="img/s71.png" alt="El contexto de build">
<figcaption><strong>Figura 1.11.</strong> El punto final de <code>docker build .</code>
empaqueta y envía la carpeta entera al motor de Docker — aunque el Dockerfile no copie
nada de ella.</figcaption>
</figure>

Ese punto del final **no es decorativo**: es el **contexto de build**, la carpeta que
Docker empaqueta y envía al motor. Si lanzas el build en una carpeta con 5 GB de datos,
Docker se los manda enteros y el build se arrastra.

La solución es un `.dockerignore`, que funciona igual que un `.gitignore`:

```
.git
__pycache__/
venv/
data/
*.csv
*.parquet
.env
```

Hay **dos motivos** para usarlo, y el segundo es el que de verdad importa:

1. **Velocidad**: el mismo build pasa de enviar 2,4 GB a enviar 480 kB.
2. **Seguridad**: que tu `.env` no acabe dentro de la imagen el día que alguien añada un
   `COPY . .` al Dockerfile. Ese día tus credenciales viajan dentro de la imagen, y esa
   imagen se sube a un registro donde puede descargarla cualquiera con acceso.

> Pon `.env` en el `.dockerignore` el mismo día que creas el proyecto, no después.

### 6.4 `CMD`, `ENTRYPOINT` y `command:`

`CMD` define el comando por defecto de la imagen y **se puede sobrescribir**. Esto
explica un detalle de nuestro proyecto que si no resulta desconcertante: los servicios
de Airflow del `docker-compose.yml` usan **exactamente la misma imagen**, y lo único que
los distingue es el `command:`.

```yaml
services:
  airflow-scheduler:
    image: apache/airflow:3.3.1-python3.14
    command: scheduler         # sobrescribe el CMD de la imagen

  airflow-api-server:
    image: apache/airflow:3.3.1-python3.14
    command: api-server
```

Misma imagen, comportamientos distintos.

!!! definicion "¿Y `ENTRYPOINT`?"
    `ENTRYPOINT` define un comando **fijo** al que se le añaden argumentos
    automáticamente al arrancar. Tanto la imagen de `postgres` como la de
    `apache/airflow` lo configuran internamente para preparar el entorno antes de
    ejecutar tu comando. Por eso tú solo escribes el subcomando final (`scheduler`) y no
    el comando entero (`airflow scheduler`).

---

## 7. Condiciones de arranque: `restart` y `healthcheck`

Dos ajustes pequeños con consecuencias grandes. "Arrancado" y "listo" **no son lo
mismo**, y distinguirlo evita el error más confuso de la sesión 2.

### 7.1 Política de reinicio (`restart`)

Decide qué hace Docker si el proceso principal termina:

| Valor | Comportamiento | Cuándo usarlo |
|---|---|---|
| `no` | No reinicia (por defecto) | **Tareas de un solo uso**, como `airflow-init` |
| `unless-stopped` | Reinicia siempre salvo que lo pares tú | Servicios de larga duración. El que usamos |
| `always` | Reinicia siempre, incluso si lo paraste | Rara vez lo que quieres |
| `on-failure[:N]` | Solo si sale con código ≠ 0 | Procesos que pueden fallar de forma transitoria |

!!! error "Poner `unless-stopped` a un contenedor de un solo uso"
    Si `airflow-init` (que ejecuta la migración de la base de datos y termina) llevara
    `unless-stopped`, Docker relanzaría la migración **en bucle** cada vez que termina
    correctamente. Los contenedores de tarea única llevan `restart: "no"`.

### 7.2 Healthcheck

!!! definicion "Healthcheck"
    Un comando que Docker ejecuta periódicamente para decidir si el contenedor está
    realmente **listo**, no solo "arrancado". Es la diferencia entre *"el proceso de
    Postgres existe"* y *"Postgres ya acepta conexiones"*.

```yaml
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U airflow -d airflow"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
```

Esta distinción, que suena a sutileza, es la que evita el error más frecuente al montar
un stack de datos: **sin healthcheck, Airflow intenta conectarse a una base de datos que
todavía se está inicializando y falla con un mensaje incomprensible**. Entre "el proceso
existe" y "acepta conexiones" pueden pasar veinte segundos.

En nuestro proyecto: Postgres se comprueba con `pg_isready`, y los componentes de
Airflow con `airflow jobs check` o con el endpoint HTTP `/api/v2/monitor/health`. En la
sesión 2 lo combinamos con `depends_on` para conseguir un arranque fiable.

---

## 8. Resumen de la sesión

Cinco cosas que ya no deberían darte problemas:

1. **Imagen es plantilla; contenedor es instancia.** Nunca más los mezclas.
2. **`stop` no borra. Solo `rm` borra.** Y `ps -a` lo demuestra.
3. **Los datos van en volúmenes**: con nombre para bases de datos, bind mount para tu
   código.
4. **`-p` abre el puente; `EXPOSE` solo documenta.**
5. **`FROM` oficial + `RUN pip install`** es el 90 % de los Dockerfiles que escribirás.

### 8.1 Chuleta de comandos

```bash
# --- Contenedores ---
docker run -d --name X imagen        # arrancar en segundo plano
docker run -it imagen sh             # shell interactiva
docker run --rm imagen               # autoeliminar al terminar
docker ps          /  docker ps -a   # ver activos / todos
docker logs -f X                     # seguir la salida
docker exec -it X sh                 # abrir una shell dentro
docker inspect X                     # JSON completo
docker stats X                       # CPU y memoria en vivo
docker stop X      /  docker rm X    # parar / borrar

# --- Imágenes ---
docker build -t mi-imagen:1.0 .              # construir
docker build --platform linux/amd64 -t X .   # fijando arquitectura
docker image ls                              # imágenes locales
docker history mi-imagen:1.0                 # sus capas
docker pull imagen:tag                       # descargar
docker login / docker push usuario/img:1.0   # publicar

# --- Volúmenes ---
docker volume ls
docker volume inspect <nombre>
docker volume rm <nombre>

# --- Espacio en disco ---
docker system df                     # cuánto ocupa Docker
docker system prune                  # limpiar lo no usado
docker system prune -a               # además, imágenes sin usar
```

### 8.2 Cuando algo falla

El **orden** de diagnóstico importa: mira siempre primero `ps`, luego `logs`.

| Síntoma | Causa habitual | Qué hacer |
|---|---|---|
| El contenedor no aparece en `docker ps` | Terminó su proceso | `docker ps -a` y luego `docker logs` |
| `Exited (1)` nada más arrancar | El proceso murió al iniciar | `docker logs <cont>` y lee las **últimas** líneas |
| `port is already allocated` | Otro proceso ocupa el puerto | Cambia el puerto del host (`8081:8080`) |
| No responde en el navegador | El puerto derecho de `-p` no coincide con el real | `docker inspect --format='{{.Config.ExposedPorts}}' X` |
| `exec format error` | Arquitectura equivocada (arm64 vs amd64) | Reconstruye con `--platform linux/amd64` |
| Los datos desaparecen al recrear | No hay volumen declarado | Usa un volumen con nombre |
| `ModuleNotFoundError` en un DAG | La librería no está en la imagen | Añádela con un Dockerfile, no con `exec` |
| El build tarda siglos | Contexto enorme o mal orden de capas | `.dockerignore` y dependencias antes que código |
| Todo va lentísimo | Docker sin RAM suficiente | Docker Desktop → Settings → Resources |

### 8.3 Autoevaluación

Si puedes responder a estas seis, la sesión ha cumplido:

1. Tu compañero clona el repositorio y ejecuta la imagen. ¿Qué necesita tener
   instalado? ¿Cambia algo si él usa Windows y tú Mac?
2. Explica en dos frases la diferencia entre imagen y contenedor, sin usar la palabra
   "Docker".
3. Has hecho `docker stop` a un contenedor y ya no aparece en `docker ps`. ¿Ha
   desaparecido? ¿Cómo lo compruebas? ¿Cómo lo recuperas?
4. ¿Por qué `docker run -p 8080:5432 postgres` no te deja conectar por el 8080 aunque
   el contenedor esté `Up`?
5. Tienes un `Dockerfile` con `COPY app.py .` antes de `RUN pip install -r
   requirements.txt`. ¿Qué problema tiene y cómo lo arreglas?
6. ¿Qué diferencia hay entre montar `-v ./dags:/opt/airflow/dags` y
   `-v pgdata:/var/lib/postgresql`? ¿Cuál usarías para cada caso?

---

## 9. Qué viene en la sesión 2

Ya sabes levantar **un** contenedor. En la siguiente sesión tendrás que levantar
**cinco que se hablen entre sí**:

- De `docker run` a `docker compose`.
- Redes: por qué `postgres` funciona como *hostname* sin que configures ninguna IP.
- `depends_on` y healthchecks encadenados.
- El stack real de Airflow, servicio a servicio.

**Antes de la sesión 2**, deja tu entorno limpio:

```bash
docker ps -a
docker system df
docker system prune
```
