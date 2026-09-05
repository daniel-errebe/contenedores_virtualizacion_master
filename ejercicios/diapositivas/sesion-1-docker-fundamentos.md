---
marp: true
theme: pontia
paginate: true
footer: 'Máster en Data Engineering, MLOps & Arquitectura Cloud'
size: 16:9
---

<!-- _class: portada -->
<!-- _paginate: false -->

# Módulo:<br>Contenedores<br>y Kubernetes

## Sesión 1 — Imágenes y contenedores

Máster en Data Engineering, MLOps & Arquitectura Cloud

---

# El módulo son tres sesiones

## Cada una se apoya en la anterior; no hay atajos

| Sesión | Contenido | Duración |
|---|---|---|
| *0* | *¿Qué es Docker? Contexto e historia* | *30 min* |
| **1. Hoy** | Imágenes y contenedores: ejecutar, inspeccionar, persistir, construir | 2 h 40 |
| **2** | Docker Compose: varios servicios que se hablan entre sí | 2 h 20 |
| **3** | Kubernetes: del contenedor al cluster | 2 h 30 |

<div class="aviso">

Además hay **7 vídeos cortos de teoría** (unos 65 min en total) que debes ver antes.
La clase en vivo es para practicar, no para escuchar.

</div>

---

<!-- _class: lima -->

# Docker no es una herramienta más de la lista

## Es la capa por la que hoy pasa casi todo lo que despliegas

**Python** → **Git** → **Docker** → **Airflow** → **Spark** → **Kubernetes** → **Cloud**

<div class="destacado">

Si entiendes qué es una imagen, qué es un contenedor y dónde viven los datos,
las herramientas de arriba dejan de parecer cajas negras.

</div>

---

# El objetivo es defenderse, no memorizar comandos

## Al terminar la sesión de hoy podrás

<div class="pasos">
<div><b>01</b><span>Explicar la diferencia entre imagen y contenedor sin dudar</span></div>
<div><b>02</b><span>Arrancar, inspeccionar, parar y borrar contenedores con criterio</span></div>
<div><b>03</b><span>Hacer que los datos sobrevivan al borrado del contenedor</span></div>
<div><b>04</b><span>Publicar un puerto y saber por qué a veces no funciona</span></div>
<div><b>05</b><span>Escribir un Dockerfile que añada dependencias a una imagen oficial</span></div>
</div>

---

# Contenido de la sesión

## Seis bloques de teoría, cinco ejercicios intercalados

<div class="cols">
<div>

**0.** Comprobación del entorno
**1.** ¿Qué es un contenedor? ¿Y una imagen?
**2.** Ejecutar y detener contenedores
  → *Ejercicios 1 y 2*
**3.** Volúmenes y puertos
  → *Ejercicio 3*

</div>
<div>

**4.** Imágenes en profundidad
  → *Ejercicio 5 bis (en grupo)*
**5.** Construir imágenes con Dockerfile
  → *Ejercicios 4 y 5*
**6.** Condiciones de arranque
**7.** Cierre y puente a la sesión 2

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">0</div>
<div class="reloj">≈ 0:00</div>

# Comprobar el entorno

## Cinco minutos ahora evitan cuarenta minutos de incidencias repartidas por toda la sesión.

---

<!-- _class: navy -->

# Antes de seguir: valida tu instalación

## Si algo falla aquí, avísame ahora — no dentro de una hora

<div class="cols-58">
<div>

```bash
$ docker --version
Docker version 27.x.x

$ docker run --rm hello-world
Hello from Docker!

$ docker compose version
Docker Compose version v2.x.x

$ docker images | wc -l
```

</div>
<div>

### Si algo no responde

Revisa **REQUISITOS.md**, sección 8.

**macOS** — ¿arrancaste Colima o Docker Desktop?
**Windows** — ¿marcaste *WSL Integration*?
**Linux** — ¿hiciste `usermod -aG docker`?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">1</div>
<div class="reloj">≈ 0:15</div>

# ¿Qué es un contenedor?<br>¿Y una imagen?

## Toda la sesión se apoya en distinguir estas dos cosas. Si se mezclan, nada de lo demás encaja.

---

# Tres palabras que vas a usar todo el día

## Imagen, contenedor, registry

<div class="pasos">
<div><b>01</b><span><b>Imagen</b> — plantilla de solo lectura con un sistema de archivos y metadatos. Como una <i>clase</i> en programación, o una <i>receta</i> de cocina.</span></div>
<div><b>02</b><span><b>Contenedor</b> — instancia en ejecución de una imagen, con su propia capa de escritura encima. Como un <i>objeto</i>, o el <i>plato ya cocinado</i>.</span></div>
<div><b>03</b><span><b>Registry</b> — servidor donde viven las imágenes. Se descargan con <code>pull</code> y se suben con <code>push</code>. El público por defecto es <b>Docker Hub</b>.</span></div>
</div>

<div class="aviso">

De una misma imagen puedes arrancar **cien contenedores independientes**. La imagen no cambia nunca.

</div>

---

# Un contenedor no es una máquina virtual

## Comparte el kernel del host; no arranca un sistema operativo propio

| Aspecto | Máquina virtual | Contenedor |
|---|---|---|
| **Arranque** | Kernel + SO completo (2–5 min) | Directamente el proceso (~100 ms) |
| **Tamaño en disco** | 5–30 GB | 100 MB – 2 GB |
| **RAM mínima** | 512 MB – 2 GB | 10–100 MB |
| **Aislamiento** | Hardware virtualizado | Namespaces y cgroups del SO |
| **Cuántos caben** | 5–10 en tu portátil | Cientos |

---

<!-- _class: lima -->

# Por qué esto resuelve "en mi máquina funciona"

## La imagen empaqueta las dependencias exactas, no solo tu código

<div class="destacado">

Tu portátil, el servidor de integración y producción ejecutan
<b>los mismos bytes</b>. Si falla, falla en los tres sitios igual.

</div>

<div class="aviso">

Eso también significa que **si tu imagen está mal construida, está mal construida en todas partes**.
Docker no arregla el problema: lo hace reproducible.

</div>

---

<!-- _class: seccion -->

<div class="num">2</div>
<div class="reloj">≈ 0:25</div>

# Ejecutar y detener contenedores

## El ciclo de vida es el concepto que más errores causa en las primeras semanas.

---

# Un contenedor está en uno de tres estados

## Y solo uno de ellos significa que ha desaparecido

<pre class="diagrama">
                    docker run
                        │
                        ▼
    ┌──────────────────────────────────────┐
    │              RUNNING                 │
    │      proceso principal vivo          │
    └──────────────────────────────────────┘
       ▲                              │
       │ docker start                 │ docker stop
       │ (resucita)                   │ o el proceso termina
       │                              ▼
    ┌──────────────────────────────────────┐
    │              EXITED                  │
    │   parado, pero EXISTE en el sistema  │
    └──────────────────────────────────────┘
                    │
                    │ docker rm
                    ▼
             BORRADO (desaparece)
</pre>

---

# Tres ideas que hay que fijar aquí

## Casi todas las confusiones del primer día salen de estas tres

<div class="pasos">
<div><b>01</b><span>Un contenedor <code>EXITED</code> <b>no está borrado</b>. Ocupa disco y sale en <code>docker ps -a</code>.</span></div>
<div><b>02</b><span>Solo <code>docker rm</code> lo borra de verdad. <code>docker stop</code> no borra nada.</span></div>
<div><b>03</b><span><code>docker run --rm</code> se autoelimina al terminar. Úsalo para pruebas de un solo uso.</span></div>
</div>

<div class="aviso">

Si `docker ps` no muestra tu contenedor, prueba `docker ps -a` **antes** de volver a lanzarlo.
Muy probablemente sigue ahí, parado, y el error está en sus logs.

</div>

---

<!-- _class: denso -->

# `docker run` — los flags que usarás de verdad

## Hay decenas; con estos ocho cubres el 95 % de los casos

| Flag | Qué hace | Ejemplo |
|---|---|---|
| `-d` | Segundo plano (*detached*) | `docker run -d nginx` |
| `-it` | Shell interactiva | `docker run -it alpine sh` |
| `-e VAR=valor` | Variable de entorno | `-e POSTGRES_PASSWORD=secreto` |
| `-p host:cont` | Publica un puerto | `-p 8080:80` |
| `-v origen:destino` | Monta datos | `-v datos:/var/lib/postgresql` |
| `--name nombre` | Nombre fijo (si no, aleatorio) | `--name mi-db` |
| `--rm` | Se autoelimina al terminar | `docker run --rm alpine echo hola` |
| `--restart` | Política de reinicio | `--restart unless-stopped` |

---

# Inspeccionar: lo que harás cuando algo falle

## Antes de reinstalar nada, mira los logs

```bash
docker ps                       # contenedores en ejecución
docker ps -a                    # todos, incluidos los parados

docker logs <contenedor>        # salida completa (stdout + stderr)
docker logs -f <contenedor>     # sigue en tiempo real, como tail -f
docker logs --tail 50 <cont>    # solo las últimas 50 líneas

docker exec -it <cont> sh       # abre una shell DENTRO del contenedor
docker inspect <cont>           # JSON completo: IP, volúmenes, variables
docker stats <cont>             # CPU, memoria e I/O en vivo
```

<div class="aviso">

`docker logs` es la primera herramienta de diagnóstico, no la última.

</div>

---

<!-- _class: navy -->

# Ejercicio 1 — Tu primer contenedor

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Arrancar, listar, inspeccionar y parar

<div class="cols-58">
<div>

```bash
$ docker run hello-world

$ docker run -d --name web \
    -p 8088:80 nginx:alpine

$ docker ps

$ docker logs web

$ docker stop web
```

</div>
<div>

### Tarea

Arranca un contenedor, compruébalo desde el navegador y páralo.

### Responde antes de continuar

¿Qué diferencia hay entre `docker ps` y `docker ps -a` **después** de parar `web`?

</div>
</div>

---

<!-- _class: navy -->

# Ejercicio 2 — Los contenedores son efímeros

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Escribe un fichero, borra el contenedor, búscalo

<div class="cols-58">
<div>

```bash
$ docker run -it --name prueba \
    alpine:3.21 sh

/ # echo "dato importante" > /datos.txt
/ # cat /datos.txt
/ # exit

$ docker start -ai prueba
/ # cat /datos.txt      # ¿sigue?

$ docker rm prueba
$ docker run -it alpine:3.21 sh
/ # cat /datos.txt      # ¿y ahora?
```

</div>
<div>

### Lo que vas a comprobar

Los datos **sobreviven** a `stop`/`start`.

Los datos **mueren** con `rm`.

### Para pensar

Si esto fuera tu base de datos de producción, ¿qué acabas de perder?

</div>
</div>

---

<!-- _class: lima -->

# Ese ejercicio es el motivo de la siguiente sección

## Un contenedor tiene una capa de escritura que muere con él

<pre class="diagrama">
┌───────────────────────────────────┐
│   Capa de escritura (RW)          │  ← se borra con docker rm
├───────────────────────────────────┤
│   Capas de la imagen (RO)         │  ← vienen de la imagen, no cambian
└───────────────────────────────────┘
</pre>

<div class="destacado">

Los volúmenes existen para sacar los datos<br>fuera del ciclo de vida del contenedor.

</div>

---

<!-- _class: seccion -->

<div class="num">3</div>
<div class="reloj">≈ 1:10</div>

# Volúmenes y puertos

## Dos mecanismos independientes: uno para que los datos duren, otro para que alguien pueda hablar con el proceso.

---

# Hay dos formas de montar datos, y no son intercambiables

## Bind mount para tu código; volumen con nombre para tus datos

<div class="cols">
<div>

### Bind mount

Tú eliges una ruta **de tu máquina**.

```bash
docker run \
  -v $(pwd)/dags:/opt/airflow/dags \
  apache/airflow:3.3.1-python3.14
```

Editas en tu editor, se ve dentro al instante.

</div>
<div>

### Volumen con nombre

Docker gestiona el almacenamiento; tú solo pones un nombre.

```bash
docker run \
  -v postgres_data:/var/lib/postgresql \
  postgres:18-alpine
```

Sobrevive a `docker rm`.

</div>
</div>

---

<!-- _class: denso -->

# Cuál usar para qué

## Regla rápida para proyectos de datos

| Qué guardas | Qué usar | Por qué |
|---|---|---|
| Datos de una base de datos | **Volumen con nombre** | No necesitas tocarlos a mano; Docker los gestiona y los puedes migrar |
| Tu código: DAGs, scripts, notebooks | **Bind mount** | Quieres editarlos en tu editor y verlos al instante |
| Logs que quieres leer desde tu editor | **Bind mount** | Acceso directo desde el host |
| Datos temporales de una tarea | **Nada** | Que se pierdan es lo correcto |

<div class="aviso">

Caso real de este proyecto: un volumen `postgres_data` creado con Postgres 15 **no arranca**
con la imagen `postgres:18-alpine`. Hubo que borrarlo con `docker compose down -v`.

</div>

---

<!-- _class: lima -->

# El bind mount tiene una trampa: los permisos

## Los archivos que crea el contenedor no son tuyos

<div class="cols">
<div>

### Qué pasa

El proceso de dentro corre como `root` o como otro usuario del sistema. Lo que escriba en el bind mount lleva **ese** propietario, no el tuyo.

```bash
$ ls -l logs/
-rw-r--r--  1 root  root  dag.log

$ rm logs/dag.log
rm: Permission denied
```

</div>
<div>

### Cómo se arregla

```bash
# Ejecutar con TU identidad
$ docker run -u $(id -u):$(id -g) ...
```

En el stack de Airflow hay una variable dedicada:

```bash
$ echo "AIRFLOW_UID=$(id -u)" >> .env
```

</div>
</div>

<div class="aviso">

Pasa en **Linux**. En Mac y Windows, Docker Desktop traduce los identificadores por ti y no lo verás
nunca... hasta que despliegues en el servidor de la empresa, que es Linux.

</div>

---

# Un puerto dentro del contenedor no es alcanzable

## Hasta que lo publicas explícitamente

<pre class="diagrama">
┌────────────────────────────┐        ┌────────────────────────────┐
│   Tu máquina (host)        │        │   Contenedor               │
│                            │        │   proceso escuchando :8080 │
│   localhost:8080  ───X─────┼────────┤   (aislado)                │
└────────────────────────────┘        └────────────────────────────┘
</pre>

```bash
docker run -p 8080:8080 apache/airflow:3.3.1-python3.14 api-server
#           │    │
#           │    └── puerto DENTRO del contenedor
#           └── puerto EN TU MÁQUINA (el que abres en el navegador)
```

---

<!-- _class: denso -->

# Variantes de `-p` y una confusión clásica

## `EXPOSE` documenta; `-p` es lo que realmente abre el puente

| Sintaxis | Efecto |
|---|---|
| `-p 8080:8080` | Publica en todas las interfaces: accesible desde tu red local |
| `-p 127.0.0.1:8080:8080` | Solo `localhost`: nadie más en tu wifi puede entrar |
| `-p 9090:8080` | Puertos distintos a ambos lados — perfectamente válido |
| `-P` | Publica todos los `EXPOSE` en puertos aleatorios |

<div class="aviso">

`EXPOSE 8080` en un Dockerfile es **solo un metadato**. Sin `-p`, el puerto sigue sin ser alcanzable.
En nuestro `docker-compose.yml` usamos `127.0.0.1:8080:8080` a propósito.

</div>

---

<!-- _class: navy -->

# Ejercicio 3 — Que los datos sobrevivan

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> Postgres con volumen y puerto publicado

<div class="cols-58">
<div>

```bash
$ docker run -d --name db \
    -e POSTGRES_PASSWORD=secreto \
    -v pgdata:/var/lib/postgresql \
    -p 5433:5432 \
    postgres:18-alpine

$ docker exec -it db psql -U postgres \
    -c "CREATE TABLE t(id int);"

$ docker rm -f db

# vuelve a arrancarlo con el MISMO volumen
# ¿sigue existiendo la tabla?
```

</div>
<div>

### Lo que demuestras

El contenedor se ha borrado. Los datos, no.

### Ojo con el puerto

`5433` en el host, `5432` dentro. Así no chocas con un Postgres local.

### Para pensar

¿Qué pasa si cambias `pgdata` por otro nombre?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">4</div>
<div class="reloj">≈ 1:40</div>

# Imágenes en profundidad

## De dónde vienen, cómo se llaman y por qué el tag importa más de lo que parece.

---

# Una imagen es un snapshot de un sistema de archivos

## Capas de solo lectura, más metadatos

<div class="cols">
<div>

### Contiene

- Un SO mínimo (Alpine 7 MB, Ubuntu 77 MB)
- Librerías y binarios
- Tu aplicación y sus dependencias
- **Metadatos**: comando por defecto, variables, puertos, usuario

</div>
<div>

### `docker run` hace cuatro cosas

1. Descarga la imagen si no la tiene
2. Crea un contenedor nuevo
3. Añade una capa de escritura encima
4. Arranca el proceso principal

</div>
</div>

<div class="aviso">

La imagen **nunca cambia**. Cien `docker run` generan cien contenedores independientes.

</div>

---

# Oficiales frente a personalizadas

## El prefijo de organización te dice cuál es cuál

<div class="cols">
<div>

### Oficiales

Sin prefijo de organización.

`postgres:18-alpine`
`python:3.13-slim`
`nginx:1.27`
`alpine:3.21`

Mantenidas por el propio proyecto.

</div>
<div>

### Personalizadas

Con prefijo `organización/`.

`apache/airflow:3.3.1-python3.14`
`bitnami/postgresql:18`
`tu-usuario/mi-pipeline:1.0`

Publicadas por empresas, comunidades o por ti.

</div>
</div>

---

<!-- _class: lima -->

# El nombre completo de una imagen

## Si omites partes, Docker rellena por ti — y ahí empiezan los sustos

```
docker.io / library / postgres : 18-alpine
    │          │          │          │
    │          │          │          └── tag (versión)
    │          │          └───────────── nombre
    │          └──────────────────────── organización (library = oficial)
    └─────────────────────────────────── registry
```

| Si omites… | Docker asume… |
|---|---|
| El registry | `docker.io` |
| La organización | `library` (imágenes oficiales) |
| El tag | `latest` |

Así que `postgres` es en realidad `docker.io/library/postgres:latest`.

---

# `latest` es una promesa que nadie te ha hecho

## Es el origen de la mitad de los "a mí me funcionaba ayer"

<div class="cols">
<div>

### El problema

```bash
docker pull postgres
# Hoy:      PostgreSQL 18.3
# En 3 meses: PostgreSQL 19.0
```

Tu compañero ejecuta el mismo comando y obtiene otra versión.

</div>
<div>

### La solución

```bash
docker pull postgres:18.3-alpine
```

En nuestro proyecto, el `.env`:

```env
AIRFLOW_IMAGE_NAME=\
  apache/airflow:3.3.1-python3.14
```

</div>
</div>

<div class="aviso">

Regla: **en un proyecto real, nunca `latest`**. Ni en el Dockerfile, ni en el Compose.

</div>

---

<!-- _class: lima -->

# Una imagen no vale para cualquier procesador

## Mac con Apple Silicon es `arm64`. El servidor de tu empresa, casi seguro `amd64`.

<div class="cols">
<div>

### El síntoma

```bash
$ docker run mi-imagen:1.0
exec format error
```

O peor: arranca, pero va diez veces más lento porque está emulando.

</div>
<div>

### La solución

```bash
# Al construir
$ docker build --platform linux/amd64 \
    -t mi-app:1.0 .

# Y al ejecutar
$ docker run --platform linux/amd64 ...
```

</div>
</div>

<div class="aviso">

Las imágenes oficiales (`postgres`, `python`, `airflow`) son **multiarquitectura**: Docker elige
la tuya solo. El problema aparece con **la tuya**: construida en tu Mac, desplegada en un Linux `amd64`.

</div>

---

# Registries: dónde viven las imágenes

## Docker Hub es el de por defecto, no el único

| Registry | Proveedor | Punto de acceso |
|---|---|---|
| **Docker Hub** | Docker Inc. | `docker.io` (implícito) |
| **ECR** | Amazon AWS | `<cuenta>.dkr.ecr.<región>.amazonaws.com` |
| **Artifact Registry** | Google Cloud | `<región>-docker.pkg.dev` |
| **GHCR** | GitHub | `ghcr.io` |
| **Quay.io** | Red Hat | `quay.io` |

<div class="aviso">

En cualquier empresa con nube, tus imágenes acabarán en ECR o Artifact Registry, no en Docker Hub.
La mecánica es idéntica: `login`, `build`, `push`, `pull`.

</div>

---

<!-- _class: navy -->

# Ejercicio 5 bis — Publica y comparte una imagen

## <span class="pill">15 min</span> <span class="pill">EN GRUPO</span> Una persona publica; el resto descarga

<div class="cols">
<div>

### Parte A — la persona voluntaria

```bash
$ docker login
$ docker build \
    -t TU_USUARIO/mi-pipeline:1.0 .
$ docker push TU_USUARIO/mi-pipeline:1.0
```

Comparte el nombre exacto con la clase.

</div>
<div>

### Parte B — el resto

```bash
$ docker run --rm \
    TU_USUARIO/mi-pipeline:1.0
```

Nadie ha compartido código, ni instalado nada, ni configurado un entorno.

</div>
</div>

<div class="aviso">

Esto es exactamente lo que hace un pipeline de CI cuando despliega. Sin magia.

</div>

---

<!-- _class: seccion -->

<div class="num">5</div>
<div class="reloj">≈ 1:55</div>

# Construir imágenes<br>con un Dockerfile

## Como Data Engineer rara vez escribirás una imagen desde cero. Lo que harás cada semana es añadirle dependencias a una oficial.

---

<!-- _class: denso -->

# Las siete instrucciones que necesitas

## Hay muchas más; con estas construyes casi todo lo que te van a pedir

| Instrucción | Qué hace |
|---|---|
| `FROM imagen:tag` | Imagen base. Siempre la primera línea. |
| `WORKDIR /ruta` | Directorio de trabajo (lo crea si no existe) |
| `COPY origen destino` | Copia archivos de tu máquina a la imagen |
| `RUN comando` | Ejecuta algo **durante el build** y guarda el resultado como capa |
| `ENV CLAVE=valor` | Variable de entorno, disponible en build y en runtime |
| `USER usuario` | Usuario con el que se ejecuta lo siguiente y el contenedor final |
| `CMD ["..."]` | Comando por defecto al arrancar. **Se puede sobrescribir.** |

---

# El Dockerfile mínimo

## Cuatro líneas y dos comandos

<div class="cols">
<div>

```dockerfile
FROM alpine:3.21

WORKDIR /usr/src/app

COPY hello.sh .

CMD ["./hello.sh"]
```

</div>
<div>

```bash
$ docker build -t hello-docker .

$ docker run hello-docker
```

El `.` final es el **contexto de build**: la carpeta que Docker envía al daemon.

</div>
</div>

---

<!-- _class: lima -->

# El caso que más te va a tocar

## Tu DAG importa `pandas`; la imagen oficial de Airflow no lo trae

```dockerfile
FROM apache/airflow:3.3.1-python3.14

# La imagen de Airflow define USER airflow;
# pip debe ejecutarse como ese usuario
RUN pip install --no-cache-dir pandas==2.2.3
```

<div class="aviso">

**Error clásico**: instalarlo a mano con `docker exec ... pip install pandas`.
Funciona *hasta que* borras el contenedor. Lo del Dockerfile es permanente y reproducible.

</div>

---

# Capas y caché: por qué a veces tarda 2 s y otras 4 min

## Cada `RUN`, `COPY` y `ADD` crea una capa que Docker cachea

<div class="cols">
<div>

```dockerfile
FROM ubuntu:24.04       # capa 1
RUN apt-get update      # capa 2
RUN apt-get install -y python3   # capa 3
COPY app.py .           # capa 4
RUN python3 app.py      # capa 5
```

</div>
<div>

### Si cambias `app.py`

Capas 1–3 → `CACHED`
Capas 4–5 → se rehacen

### Si cambias la línea `FROM`

**Todas** se rehacen.

</div>
</div>

<div class="aviso">

Regla de oro: lo que **cambia poco** (dependencias) va arriba. Lo que **cambia siempre** (tu código) va abajo.

</div>

---

# El contexto de build: lo que de verdad estás enviando

## El punto final de `docker build .` empaqueta la carpeta entera

<div class="cols">
<div>

### Sin `.dockerignore`

```bash
$ docker build -t mi-app:1.0 .
Sending build context ...  2.4GB
```

Ahí van tu `.git`, tu `venv/`, tus CSV de pruebas y el `data/` entero. Aunque el Dockerfile no los copie.

</div>
<div>

### Con `.dockerignore`

```
.git
__pycache__/
venv/
data/
*.csv
*.parquet
.env
```

```bash
Sending build context ...  480kB
```

</div>
</div>

<div class="aviso">

Dos motivos, y el segundo es el que importa: **builds mucho más rápidos** y **no meter tu `.env`
dentro de la imagen** el día que alguien añada un `COPY . .` al Dockerfile.

</div>

---

<!-- _class: navy -->

# Ejercicio 4 — Tu primer Dockerfile

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> De un script suelto a una imagen

<div class="cols-58">
<div>

```bash
$ cat > hello.sh <<'EOF'
#!/bin/sh
echo "Hola desde dentro"
EOF
$ chmod +x hello.sh

$ cat > Dockerfile <<'EOF'
FROM alpine:3.21
WORKDIR /app
COPY hello.sh .
CMD ["./hello.sh"]
EOF

$ docker build -t hola:1.0 .
$ docker run --rm hola:1.0
```

</div>
<div>

### Después, comprueba

```bash
$ docker images hola
$ docker history hola:1.0
```

### Para pensar

Cambia el `echo` y reconstruye. ¿Qué capas dice `CACHED`?

</div>
</div>

---

<!-- _class: navy -->

# Ejercicio 5 — Añadir una librería a Airflow

## <span class="pill">25 min</span> <span class="pill">NÚCLEO CLAVE</span> El ejercicio más parecido a tu trabajo real

<div class="cols-58">
<div>

```dockerfile
FROM apache/airflow:3.3.1-python3.14

RUN pip install --no-cache-dir \
    pandas==2.2.3
```

```bash
$ docker build -t mi-airflow:1.0 .

$ docker run --rm mi-airflow:1.0 \
    python -c "import pandas; \
    print(pandas.__version__)"
```

</div>
<div>

### Extensión

Pásalo a `requirements.txt`:

```dockerfile
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir \
    -r /tmp/requirements.txt
```

### Para pensar

¿Por qué `--no-cache-dir`?

</div>
</div>

---

# `CMD` explica un detalle raro de nuestro proyecto

## Cinco servicios, la misma imagen, distinto comando

```yaml
services:
  airflow-scheduler:
    image: apache/airflow:3.3.1-python3.14
    command: scheduler        # sobrescribe el CMD de la imagen

  airflow-api-server:
    image: apache/airflow:3.3.1-python3.14
    command: api-server
```

<div class="aviso">

Existe también `ENTRYPOINT`: un comando fijo al que se le añaden argumentos.
`postgres` y `apache/airflow` lo usan por dentro — por eso `command:` funciona pasando solo el subcomando.

</div>

---

<!-- _class: seccion -->

<div class="num">6</div>
<div class="reloj">≈ 2:40</div>

# Condiciones de arranque

## "Arrancado" y "listo" no son lo mismo. Distinguirlo evita el error más confuso de la sesión 2.

---

# Reinicio y salud

## Dos ajustes pequeños con consecuencias grandes

<div class="cols">
<div>

### `restart`

Qué hace Docker si el proceso principal termina.

**`unless-stopped`** — reinicia siempre salvo que lo pares tú. El que usamos.

**`no`** — por defecto. Correcto para tareas de un solo uso, como `airflow-init`.

</div>
<div>

### `healthcheck`

Un comando periódico que decide si el contenedor está **listo**, no solo *arrancado*.

La diferencia entre "el proceso de Postgres existe" y "Postgres acepta conexiones".

</div>
</div>

<div class="aviso">

Sin healthcheck, Airflow intenta conectarse a una base de datos que aún se está inicializando
y falla con un error incomprensible. **Volveremos a esto en la sesión 2 con `depends_on`.**

</div>

---

<!-- _class: lima -->

# Qué te llevas de hoy

## Cinco cosas que ya no deberían darte problemas

<div class="pasos">
<div><b>01</b><span>Imagen es plantilla; contenedor es instancia. Nunca más los mezclas.</span></div>
<div><b>02</b><span><code>stop</code> no borra. Solo <code>rm</code> borra. Y <code>ps -a</code> lo demuestra.</span></div>
<div><b>03</b><span>Los datos van en volúmenes: con nombre para bases de datos, bind mount para tu código.</span></div>
<div><b>04</b><span><code>-p</code> abre el puente; <code>EXPOSE</code> solo documenta.</span></div>
<div><b>05</b><span><code>FROM</code> oficial + <code>RUN pip install</code> es el 90 % de los Dockerfiles que escribirás.</span></div>
</div>

---

<!-- _class: verde -->

# En la sesión 2

## Ya sabes levantar un contenedor. Ahora tienes que levantar cinco que se hablen entre sí.

<div class="cols">
<div>

### Lo que viene

- De `docker run` a `docker compose`
- Redes: por qué `postgres` funciona como hostname
- `depends_on` y healthchecks encadenados
- El stack real de Airflow, servicio a servicio

</div>
<div>

### Antes de la sesión 2

Mira los **vídeos 6 y 7**.

Deja tu entorno limpio:

```bash
docker ps -a
docker system df
```

</div>
</div>
