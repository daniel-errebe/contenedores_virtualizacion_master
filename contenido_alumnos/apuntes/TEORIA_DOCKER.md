# Teoría: de cero a Docker Compose

Este documento es la teoría de apoyo para [EJERCICIOS.md](./EJERCICIOS.md).
Está pensado para una clase de contenedores de un máster de **Data
Engineering** (5 horas), aplicada al proyecto real de Airflow + PostgreSQL
de este repositorio.

---

## Antes de empezar: qué necesitas saber hoy (y qué no)

Docker es una herramienta enorme. Como Data Engineer **no** necesitas
dominarla entera: necesitas la parte que te permite ejecutar, modificar y
depurar los stacks de datos con los que trabajarás (Airflow, Spark, dbt,
bases de datos, notebooks...).

**Lo que sí vas a usar cada semana:**

| Necesidad real | Concepto |
|---|---|
| "Levántame el entorno de Airflow" | `docker compose up` |
| "Mi DAG necesita `pandas`" | Extender una imagen con un Dockerfile |
| "No me guarda los datos al reiniciar" | Volúmenes |
| "No puedo conectar con la base de datos" | Red de Compose y nombres de servicio |
| "Quiero editar mis DAGs sin reconstruir nada" | Bind mounts |
| "No arranca, ¿qué hago?" | `docker compose logs`, `ps` |

**Lo que hoy NO vamos a ver** (y no pasa nada): optimización de imágenes,
*multi-stage builds*, redes personalizadas, Docker Swarm, Kubernetes,
registries privados, CI/CD. Son temas de perfil DevOps/plataforma; si algún
día los necesitas, la base de hoy te bastará para entenderlos.

> Regla práctica: si algo de Docker te parece "magia", casi siempre la
> respuesta está en una de estas cuatro cosas: **imagen**, **volumen**,
> **red** o **variable de entorno**.

---

## Índice

**Parte I — Fundamentos de Docker**
1. [¿Qué es un contenedor? ¿Qué es una imagen?](#1-qué-es-un-contenedor-qué-es-una-imagen)
2. [Ejecutar y detener contenedores](#2-ejecutar-y-detener-contenedores)
3. [Imágenes en profundidad](#3-imágenes-en-profundidad)
4. [Construyendo imágenes con un Dockerfile](#4-construyendo-imágenes-con-un-dockerfile)
   — incluye [4.1 Añadir dependencias a una imagen existente](#41-el-caso-que-más-te-va-a-tocar-añadir-dependencias-a-una-imagen-existente)
5. [Condiciones de arranque del contenedor](#5-condiciones-de-arranque-del-contenedor)
6. [Interactuando con el contenedor: volúmenes y puertos](#6-interactuando-con-el-contenedor-volúmenes-y-puertos)

**Parte II — Orquestación con Docker Compose**

7. [De `docker run` a Docker Compose](#7-de-docker-run-a-docker-compose)
8. [Redes en Docker Compose](#8-redes-en-docker-compose)
9. [Volúmenes en acción](#9-volúmenes-en-acción)
10. [Contenedores en desarrollo](#10-contenedores-en-desarrollo)
11. [Aplicación final: nuestro stack Airflow + PostgreSQL](#11-aplicación-final-nuestro-stack-airflow--postgresql)

**Apéndices (para consultar durante los ejercicios)**

- [A — Chuleta de comandos](#apéndice-a--chuleta-de-comandos)
- [B — Cuando algo falla](#apéndice-b--cuando-algo-falla)

---

## Parte I — Fundamentos de Docker

### 1. ¿Qué es un contenedor? ¿Qué es una imagen?

- **Imagen**: una plantilla de solo lectura que contiene un sistema de
  archivos mínimo (librerías, binarios, tu aplicación) y metadatos (qué
  comando ejecutar, qué puertos documenta, etc.). Es análoga a una **clase**
  en programación, o a una **receta** de cocina.
- **Contenedor**: una instancia en ejecución de una imagen, con su propio
  sistema de archivos "de escritura" temporal encima. Es análoga a un
  **objeto** instanciado de esa clase, o al **plato ya cocinado** a partir de
  la receta.
- **Registro (registry)**: un servidor que almacena imágenes para poder
  descargarlas (`docker pull`) o subirlas (`docker push`). El registro
  público por defecto es **Docker Hub**.

A diferencia de una máquina virtual, un contenedor **no** virtualiza
hardware ni arranca un kernel propio: comparte el kernel del host y usa
mecanismos del sistema operativo (namespaces y cgroups en Linux) para
aislar procesos, red y sistema de archivos. Por eso los contenedores son
mucho más ligeros y rápidos de arrancar que una VM.

**¿Por qué importa esto?** Resuelve el clásico "en mi máquina funciona":
la imagen empaqueta exactamente las dependencias que la aplicación necesita,
así que se comporta igual en tu portátil, en el servidor del profesor o en
producción.

### 2. Ejecutar y detener contenedores

#### 2.0 ¿Qué es un contenedor realmente?

Un **contenedor** es una **instancia en ejecución** de una imagen. Es lo que ocurre cuando dices
`docker run <imagen>`.

La diferencia con una máquina virtual:

| Aspecto | Máquina Virtual | Contenedor |
|---|---|---|
| **Arranca** | Kernel propio + SO completo (2-5 min) | Directamente el proceso, reutiliza kernel del host (100 ms) |
| **Tamaño en disco** | 5-30 GB | 100 MB - 2 GB (típicamente) |
| **RAM mínima** | 512 MB - 2 GB | 10-100 MB |
| **Aislamiento** | Hardware virtualizado (completo) | Namespaces y cgroups del SO (parcial) |
| **Portabilidad** | "Funciona en KVM, VirtualBox, Hyper-V" | "Funciona en cualquier máquina con Docker" |

**¿Por qué importa?** Los contenedores son lo suficientemente ligeros como para tener **cientos**
en una máquina. Una VM tienes **máximo 5-10**.

#### 2.1 Dentro de un contenedor — qué ve?

Cuando entras en un contenedor con `docker exec -it <contenedor> sh`, ves:

```
root@a1b2c3d4e5f6:/# ls /
bin    boot   dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
```

Es un **sistema de archivos completo** — pequeño (Alpine 7 MB, Ubuntu 77 MB) pero funcional. Tiene
`cat`, `grep`, Python, Node, lo que la imagen incluya.

Pero **no es una máquina virtual completa**:
- No hay BIOS
- No hay kernel separado
- Los procesos que ves desde dentro tienen números de PID diferentes que desde el host
  (el kernel enmascara el número — es lo que hace un *namespace de PID*)
- Si haces `docker ps` desde tu máquina host, ves todos los contenedores en ejecución

#### 2.2 El ciclo de vida — estados

Un contenedor puede estar en uno de estos estados:

**RUNNING** — el proceso principal está en ejecución. Puedes:
- Ver su salida con `docker logs -f`
- Entrar en él con `docker exec -it <contenedor> sh`
- Paarlo con `docker stop`

```bash
docker run -d nginx
docker ps        # lo ves aquí
```

**EXITED** — el proceso terminó (ya sea porque finalizó naturalmente o porque lo paraste).
El contenedor **sigue existiendo** — ocupa espacio en `/var/lib/docker` y aparece en `docker ps -a`.
Lo importante: **puedes resucitarlo** con `docker start`.

```bash
docker stop nginx           # pasa a EXITED
docker ps -a               # lo ves aquí
docker start nginx          # vuelve a RUNNING
```

**BORRADO** — desapareció completamente. Solo ocurre con `docker rm`.

```
                    docker run
                        │
                        ▼
    ┌──────────────────────────────────────┐
    │         RUNNING                      │
    │  (proceso principal vivo, activo)    │
    └──────────────────────────────────────┘
       ▲                              │
       │                              │ docker stop
       │                              │ o el proceso termina
       │ docker start                 │
       │  (resucita)                  ▼
    ┌──────────────────────────────────────┐
    │         EXITED                       │
    │  (parado pero EXISTE en el sistema)  │
    └──────────────────────────────────────┘
                    │
                    │ docker rm
                    ▼
                 BORRADO (desaparece)
```

**Tres conceptos clave aquí:**

1. Un contenedor `EXITED` **no está borrado** — el contenedor existe, ocupa espacio en disco y
   aparece en `docker ps -a`. Puedes resucitarlo en cualquier momento con `docker start`.
2. Solo `docker rm` lo **borra de verdad** — es la única forma de que desaparezca del
   sistema completamente.
3. Si quieres evitar tener contenedores fantasma, usa `docker run --rm` — se
   autoelimina cuando termina.

#### 2.3 `docker run` — los flags más importantes

`docker run` toma una imagen y arranca un contenedor. Algunos flags útiles:

| Flag | Qué hace | Ejemplo |
|---|---|---|
| `-d` | **Detached** — en segundo plano | `docker run -d nginx` → arranca y devuelve el control al terminal |
| `-i` | **Interactive** — mantén stdin abierto incluso si no hay entrada | usado con `-t` |
| `-t` | **Terminal** — asigna una pseudoterminal | `docker run -it alpine sh` → entra en una shell interactiva |
| `-e VAR=valor` | Define una variable de entorno | `docker run -e POSTGRES_PASSWORD=secret postgres:18` |
| `-p puerto_host:puerto_contenedor` | Publica un puerto | `docker run -p 8080:80 nginx` → accedes por localhost:8080 |
| `-v ruta_host:ruta_contenedor` | **Bind mount** — monta una carpeta del host | `docker run -v /tmp/data:/data postgres:18` |
| `--name nombre` | Le da un nombre al contenedor | `docker run --name mi-nginx nginx` (si no usas `--name`, Docker genera uno aleatorio) |
| `--rm` | Autoelimina el contenedor al terminar | `docker run --rm ubuntu echo hola` |
| `--restart policy` | Política de reinicio si el proceso falla | `docker run -d --restart unless-stopped nginx` |

**Ejemplos prácticos:**

```bash
# 1. Arranca Postgres en segundo plano, la configura y monta un volumen
docker run -d --name mi-db \
  -e POSTGRES_PASSWORD=secreto \
  -v mi_datos:/var/lib/postgresql \
  postgres:18-alpine

# 2. Lanza un script Python que imprime y termina
docker run --rm \
  -v $(pwd):/app \
  python:3.14 \
  python /app/script.py

# 3. Abre una shell interactiva en Ubuntu para explorar
docker run -it ubuntu bash

# 4. Levanta Nginx publicado en el puerto 8080
docker run -d --name web -p 8080:80 nginx
# Accedes con: http://localhost:8080
```

#### 2.4 Inspeccionar un contenedor en ejecución

```bash
docker ps                          # lista contenedores activos
docker ps -a                       # lista todos (incluidos los parados)
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"  # formato personalizado

docker logs <contenedor>           # ve la salida completa (stdout + stderr)
docker logs -f <contenedor>        # sigue la salida en tiempo real (tipo `tail -f`)
docker logs --tail 50 <contenedor> # últimas 50 líneas

docker inspect <contenedor>        # información JSON completa (IP, variables, volúmenes, etc.)
docker top <contenedor>            # procesos en ejecución dentro del contenedor
docker stats <contenedor>          # CPU, memoria y I/O en tiempo real
```

#### 2.5 Ciclo de vida operativo — paso a paso

Veamos un ejemplo completo. Levantamos Postgres:

```bash
# 1. Crear y arrancar
docker run -d --name mi-postgres \
  -e POSTGRES_PASSWORD=secreto \
  -v datos:/var/lib/postgresql \
  postgres:18-alpine

# 2. Ver que está corriendo
docker ps
# CONTAINER ID  IMAGE                STATUS         NAMES
# abc123...     postgres:18-alpine   Up 5 seconds   mi-postgres

# 3. Ver sus logs
docker logs mi-postgres
# ...
# PostgreSQL init process complete; ready for start up.
# database system is ready to accept connections

# 4. Entrar en el contenedor
docker exec -it mi-postgres psql -U postgres -c "SELECT version();"
# PostgreSQL 18.3 on aarch64-unknown-linux-musl, ...

# 5. Pararlo
docker stop mi-postgres

# 6. Ver que está parado (pero existe)
docker ps -a
# abc123...     postgres:18-alpine   Exited (0)     mi-postgres

# 7. Resucitarlo
docker start mi-postgres

# 8. Ver que está corriendo de nuevo
docker ps
# abc123...     postgres:18-alpine   Up 2 seconds   mi-postgres

# 9. Borrarlo definitivamente
docker rm mi-postgres
# Ahora desaparece

docker ps -a
# (no aparece)
```

Comandos esenciales (resumen):

```bash
docker run <imagen>               # arranca un contenedor
docker run -d <imagen>            # en segundo plano
docker run -it <imagen> sh        # interactivo
docker run --rm <imagen>          # autoelimina al terminar

docker ps                         # contenedores en ejecución
docker ps -a                      # todos los contenedores
docker logs -f <contenedor>       # sigue la salida
docker exec -it <contenedor> sh   # abre una shell dentro

docker stop <contenedor>          # para el contenedor
docker start <contenedor>         # lo resucita
docker rm <contenedor>            # lo borra
```

### 3. Imágenes en profundidad

#### 3.0 ¿Qué es una imagen?

Una **imagen** es un **snapshot** estático de un sistema de archivos completo — básicamente, es como hacer una "foto" del
contenedor ya construido. Contiene:

- **Capas de archivos**: un sistema operativo mínimo (Alpine es 7 MB, Ubuntu es 77 MB), librerías
  compartidas, binarios, tu aplicación y sus dependencias.
- **Metadatos**: qué comando ejecutar por defecto, qué variables de entorno predefino, qué puertos
  documento, con qué usuario ejecutar, etc.

Cuando haces `docker run <imagen>`, Docker:

1. Descarga la imagen (si no la tiene localmente).
2. Crea un contenedor nuevo a partir de ella.
3. Añade una capa **de escritura** temporal encima (solo en el contenedor, la imagen sigue intacta).
4. Arranca el proceso principal del contenedor.

La imagen **nunca cambia** — es de solo lectura. Es como una **plantilla** que puedes usar 100 veces,
y cada `docker run` crea una **instancia nueva e independiente** con su propia capa de escritura.

#### 3.1 Imágenes oficiales vs imágenes personalizadas

Existen dos tipos de imágenes:

**Imágenes oficiales** — curadas y mantenidas por Docker Inc. o por el proyecto de software:

| Imagen | Quién la mantiene | Uso |
|---|---|---|
| `postgres:18-alpine` | PostgreSQL project | Base de datos lista para usar, minimizada |
| `python:3.14` | Python project | Python + pip, nada más |
| `nginx:1.27` | NGINX project | Servidor web HTTP preconfigurado |
| `node:22-alpine` | Node.js project | Node.js + npm, para apps JavaScript |
| `ubuntu:24.04` | Canonical / Docker | Sistema base completo (600 MB+) |

Las oficiales no llevan prefijo de organización en su nombre. Aparecen directamente en Docker Hub
bajo `library/` y se refieren como `nombre:tag`.

**Imágenes personalizadas** — construidas por empresas, comunidades u individuos para casos específicos:

| Imagen | Quién la mantiene | Uso |
|---|---|---|
| `apache/airflow:3.3.1-python3.14` | Apache Software Foundation | Airflow con dependencias ya instaladas |
| `bitnami/postgresql:18` | Bitnami | PostgreSQL pero con configuraciones sensibles por defecto |
| `google/cloud-sdk:latest` | Google | Google Cloud SDK preinstalado |
| `my-company/data-pipeline:v2.1` | Tu empresa | Tu propia imagen para ejecutar un pipeline |

Las personalizadas llevan un **prefijo de organización** (`apache/`, `bitnami/`, etc.). Es lo que indica
que no es una imagen oficial.

#### 3.2 De la teoría a la práctica: crear tu propia imagen a partir de una oficial

Ahora viene un concepto que confunde a casi todos: **¿cuál es la diferencia entre usar una imagen oficial
directamente y crear tu propia imagen basándose en una oficial?**

Veamos un ejemplo concreto con Postgres:

**Opción A — Usar la imagen oficial directamente:**

```bash
docker run -d --name mi-db \
  -e POSTGRES_PASSWORD=secreto \
  -v mi_datos:/var/lib/postgresql \
  postgres:18-alpine
```

**Opción B — Crear tu propia imagen personalizada:**

```dockerfile
# Dockerfile
FROM postgres:18-alpine

ENV POSTGRES_DB=mi_base_de_datos \
    POSTGRES_USER=usuario_admin \
    POSTGRES_PASSWORD=contrasena_segura

COPY ./init.sql /docker-entrypoint-initdb.d/
EXPOSE 5432
```

Luego:

```bash
docker build -t mi-postgres:18 .
docker run -d --name mi-db \
  -v postgres_data:/var/lib/postgresql/data \
  mi-postgres:18
```

**¿Son ambas imágenes?** Sí, son dos imágenes distintas. Pero veamos las diferencias:

| Aspecto | Opción A (oficial) | Opción B (personalizada) |
|---|---|---|
| **¿De dónde viene?** | Descargada de Docker Hub (no construida por ti) | Construida por ti con `docker build`, basada en la oficial |
| **¿Qué contiene?** | PostgreSQL 18 + nada más | PostgreSQL 18 + tus variables preestablecidas + tus scripts de inicialización |
| **¿Qué configuración pasas?** | En cada `docker run` con flags: `-e POSTGRES_PASSWORD=...` | Ya está dentro de la imagen (baked in) |
| **¿Cómo arrancas un contenedor?** | Con muchos parámetros en la CLI | Parámetros mínimos, la imagen ya trae todo preconfigurado |
| **¿Reproducibilidad?** | Si olvidas un `-e` o metes la contraseña mal, falla | Imposible equivocarse — la imagen es idéntica cada vez |
| **¿Compartir con el equipo?** | "Oye, ejecuta esto con estos flags..." (propenso a errores) | "Usa `mi-postgres:18` — punto" |

**Relación entre ambas:**

```
docker.io/library/postgres:18-alpine  (imagen oficial de Docker Hub)
            ↓ (descargada, sirve como BASE)
            ↓ docker build -t mi-postgres:18 .
        tu Dockerfile
            ↓ (tus personalizaciones se apilan encima)
        mi-postgres:18  (tu imagen personalizada)
```

Tu imagen `mi-postgres:18` **contiene** toda la imagen oficial, más tus capas encima.

**¿Cuándo usar cada una?**

**Usa la imagen oficial directamente si:**
- Solo necesitas la imagen tal cual
- Planeas usar parámetros distintos cada vez (`docker run` con diferentes `-e`)
- Es un prototipo rápido o una prueba puntual

Ejemplo:
```bash
# Quiero experimentar con diferentes versiones de Postgres
docker run -e POSTGRES_PASSWORD=secreto postgres:18-alpine
docker run -e POSTGRES_PASSWORD=otracontra postgres:16-alpine
```

**Crea tu propia imagen si:**
- Necesitas **predefinir configuración** que siempre es igual
- Tienes **scripts de inicialización** (migraciones, datos de prueba)
- Necesitas **instalar dependencias adicionales** (librerías, herramientas)
- Quieres garantizar que el equipo usa **exactamente la misma configuración**
- Tienes un **proceso reproducible** que reutilizarás muchas veces

Ejemplo:
```dockerfile
FROM postgres:18-alpine

# Siempre con estas credenciales
ENV POSTGRES_DB=datos \
    POSTGRES_USER=admin \
    POSTGRES_PASSWORD=segura_y_conocida

# Siempre con esta estructura de tablas
COPY ./schema.sql /docker-entrypoint-initdb.d/

# Siempre con este usuario
USER postgres
```

**El caso real de nuestro proyecto:**

Nuestro Airflow **no** usa una imagen personalizada de Postgres — usa la oficial directamente.
Pero sí usa una imagen personalizada de **Airflow**, aunque la construimos por `docker-compose.yml`
(veremos esto en la sección de Compose). ¿Por qué?

Porque Airflow necesita **dependencias específicas** (librerías Python) que varían según el proyecto.
La imagen oficial `apache/airflow:3.3.1-python3.14` viene con lo mínimo. En un proyecto real,
escribirías un Dockerfile que añada `pandas`, `duckdb`, etc., y usarías esa en `docker-compose.yml`.

**Resumen en tres puntos:**

1. **Ambas son imágenes**, pero una es oficial (lista para descargar) y la otra es personalizada (la construyes).
2. La personalizada **no reemplaza a la oficial** — la incluye y le añade capas encima.
3. Crea imágenes personalizadas cuando quieras **reproducibilidad y configuración predeterminada**. Usa las oficiales
   cuando solo necesites la herramienta tal cual.

#### 3.3 Registries — dónde viven las imágenes

Una **imagen necesita vivir en algún sitio**. Los registries (repositorios de imágenes) son servidores
que almacenan, versionan y distribuyen imágenes. El más conocido es **Docker Hub**, pero hay muchos más:

| Registry | Proveedor | Punto de acceso | Cómo usarlo |
|---|---|---|---|
| **Docker Hub** | Docker Inc. | `docker.io` (implícito) | `docker pull postgres:18` |
| **ECR** | Amazon AWS | `123456789.dkr.ecr.us-east-1.amazonaws.com` | `aws ecr get-login-password \| docker login --username AWS --password-stdin <account-id>.dkr.ecr...` |
| **Artifact Registry** | Google Cloud Platform | `us-central1-docker.pkg.dev` | `gcloud auth configure-docker` |
| **Harbor** | Cloud Native Computing Foundation | Autohosteo | Docker API compatible |
| **Quay.io** | Red Hat | `quay.io` | `docker pull quay.io/prometheus/prometheus:latest` |
| **GitHub Container Registry (GHCR)** | GitHub | `ghcr.io` | `docker pull ghcr.io/owner/repo:tag` |

**Ejemplo: los tres usos más comunes:**

```bash
# 1. Descargar desde Docker Hub (por defecto)
docker pull postgres:18
# equivalente a: docker pull docker.io/library/postgres:18

# 2. Descargar desde Artifact Registry de Google Cloud
docker pull us-central1-docker.pkg.dev/mi-proyecto/mi-repo/mi-imagen:v1.0

# 3. Descargar desde ECR de AWS
docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/mi-imagen:v1.0
```

Para **subir** tu imagen a un registry (por ejemplo, a Docker Hub):

```bash
docker build -t mi-usuario/mi-imagen:v1.0 .
docker login                    # auténticate en Docker Hub
docker push mi-usuario/mi-imagen:v1.0
```

#### 3.4 Nombrado de imágenes — la sintaxis completa

El nombre **completo** de una imagen sigue este patrón:

```
[REGISTRY]/[ORGANIZACIÓN]/IMAGEN:TAG
```

Ejemplos reales:

```
docker.io/library/postgres:18-alpine
│         │       │       │        └─ tag (versión)
│         │       │       └──────────── nombre de imagen
│         │       └───────────────────── organización (library = oficial)
│         └────────────────────────────── registry (Docker Hub)

apache/airflow:3.3.1-python3.14
└─ si omites registry, Docker asume docker.io

mi-usuario/mi-imagen:latest
└─ si omites organización, Docker asume es un usuario personal

gcr.io/mi-proyecto/mi-imagen:v1.0
└─ registry privado de Google Cloud
```

**Si omites partes**, Docker asume valores por defecto:

- Sin registry → `docker.io`
- Sin organización → `library` (imágenes oficiales)
- Sin tag → `latest`

Así que `postgres` es en realidad `docker.io/library/postgres:latest`.

#### 3.5 Tags — importancia para reproducibilidad

Un **tag** es una etiqueta que le das a una imagen. No es una rama de Git — varias tags pueden
apuntar a la misma imagen, y una misma imagen puede tener muchos tags.

**Problema de usar `latest`:**

```bash
docker pull postgres        # tira de postgres:latest
# Hoy: PostgreSQL 18.3
# En 3 meses: PostgreSQL 19.0 (incompatible con tu código)
```

Tu compañero de equipo tira del mismo comando y acaba con una versión distinta. Caos.

**Solución — fijar la versión:**

```bash
docker pull postgres:18.3-alpine   # siempre la misma versión
```

Nuestro proyecto hace esto en el `.env`:

```env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
```

No es `apache/airflow:latest` — es una versión **concreta y reproducible**.

#### 3.6 Capas y caché — por qué las imágenes se construyen rápido (o lentamente)

Las imágenes se componen de **capas apiladas**. Cada instrucción `RUN`, `COPY` o `ADD` en un Dockerfile
crea una nueva capa. Docker **cachea** estas capas:

```dockerfile
FROM ubuntu:24.04                    # capa 1 (descargada de registry)
RUN apt-get update                   # capa 2
RUN apt-get install -y python3       # capa 3
COPY app.py .                        # capa 4
RUN python3 app.py                   # capa 5
```

Si reconstruyes sin cambios, Docker reutiliza todas las capas — casi instantáneo.

Si cambias solo `app.py` y reconstruyes:
- Capas 1-3 → `CACHED` (velocidad máxima)
- Capa 4 → se rehace (porque el contenido cambió)
- Capa 5 → se rehace (depende de la 4)

Si cambias una línea al principio (por ejemplo, la base de Ubuntu):
- Capas 1 → se rehace
- Capas 2-5 → se rehacen todas (porque dependen de la anterior)

**Consejo práctico**: ordena las instrucciones de forma que lo que **cambia frecuentemente** esté
al final — tu código. Lo que **cambia rara vez** va al principio — las dependencias del SO.

**Espacio en disco:**

Las imágenes pueden ser grandes:

```bash
docker system df                 # resumen de lo que ocupa Docker
docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
```

Ejemplos reales:
- `alpine:3.21` → 7 MB
- `python:3.14` → 950 MB
- `apache/airflow:3.3.1-python3.14` → 1,5 GB
- `ubuntu:24.04` → 77 MB

Por eso en nuestro proyecto usamos `postgres:18-alpine` (286 MB) en lugar de `postgres:18` (479 MB).
Es la misma funcionalidad, pero Alpine ocupa 193 MB menos.

### 4. Construyendo imágenes con un Dockerfile

Un **Dockerfile** es un archivo de texto con instrucciones para construir
una imagen de forma reproducible y versionable.

Instrucciones más comunes:

| Instrucción | Qué hace |
|---|---|
| `FROM <imagen>:<tag>` | Imagen base de la que partimos. Siempre la primera instrucción. |
| `WORKDIR /ruta` | Cambia (y crea si no existe) el directorio de trabajo para las siguientes instrucciones. |
| `COPY origen destino` | Copia archivos desde tu máquina (contexto de build) a la imagen. |
| `RUN comando` | Ejecuta un comando **durante el build** y guarda el resultado como una nueva capa. |
| `ENV CLAVE=valor` | Define una variable de entorno disponible en build y en runtime. |
| `USER usuario` | Cambia el usuario con el que se ejecutan las siguientes instrucciones y el contenedor final. |
| `CMD [...]` | Comando por defecto **al arrancar el contenedor** (`docker run`). Se puede sobrescribir. |

Ejemplo mínimo:

```dockerfile
# Imagen base pequeña
FROM alpine:3.21

# Directorio de trabajo dentro de la imagen
WORKDIR /usr/src/app

# Copiamos nuestro script al contenedor
COPY hello.sh .

# Comando que se ejecuta al hacer `docker run`
CMD ["./hello.sh"]
```

```bash
docker build -t hello-docker .     # construye la imagen a partir del Dockerfile del directorio actual
docker run hello-docker            # ejecuta CMD dentro de un contenedor nuevo
```

#### 4.1 El caso que más te va a tocar: añadir dependencias a una imagen existente

Como Data Engineer, **rara vez escribirás una imagen desde cero**. Lo que sí
harás constantemente es partir de una imagen oficial y añadirle las
librerías que tu código necesita. El caso típico: tu DAG importa `pandas`,
pero la imagen oficial de Airflow no lo trae.

El patrón es siempre el mismo — `FROM` la imagen oficial, `RUN pip install`
lo que falte:

```dockerfile
FROM apache/airflow:3.3.1-python3.14

# La imagen de Airflow define USER airflow; pip debe ejecutarse como ese usuario
RUN pip install --no-cache-dir pandas==2.2.3
```

Y en Compose, en vez de `image:`, se indica `build:` para que Compose
construya esa imagen a partir de tu Dockerfile:

```yaml
services:
  airflow-scheduler:
    build: .          # busca un Dockerfile en este directorio
    # image: apache/airflow:3.3.1-python3.14   <- ya no usamos la imagen tal cual
```

Para una lista larga de dependencias se usa un `requirements.txt`:

```dockerfile
FROM apache/airflow:3.3.1-python3.14
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

> **Error clásico**: instalar la librería "a mano" con `docker exec ...  pip
> install pandas`. Funciona *hasta que* borras el contenedor, y entonces
> desaparece. Lo que va en el Dockerfile es permanente y reproducible; lo
> que haces con `exec` es temporal.

#### 4.2 `CMD` y `command:`

`CMD` define el comando por defecto de la imagen, y **se puede
sobrescribir**. Esto explica un detalle de nuestro proyecto que si no
resulta desconcertante: los cinco servicios de Airflow usan **la misma
imagen**, y lo único que los diferencia es el comando:

```yaml
  airflow-scheduler:
    command: scheduler       # sobrescribe el CMD por defecto de la imagen
  airflow-api-server:
    command: api-server
```

(Existe también `ENTRYPOINT`, que es un comando fijo al que se le añaden
argumentos. Las imágenes de `postgres` y `apache/airflow` lo usan
internamente para preparar el entorno antes de ejecutar tu comando. Para
nuestro propósito basta con saber que existe y que por eso `command:`
funciona pasándole solo el subcomando.)

### 5. Condiciones de arranque del contenedor

- **Políticas de reinicio** (`restart`): qué hace Docker si el proceso
  principal del contenedor termina. En la práctica usarás dos:
  `unless-stopped` (reinicia siempre salvo que lo pares tú a propósito —
  el que usamos en el proyecto) y `no` (por defecto; el adecuado para
  contenedores de un solo uso, como nuestro `airflow-init`).

- **Healthcheck**: un comando que Docker ejecuta periódicamente para decidir
  si el contenedor está realmente **listo**, no solo "arrancado". Es la
  diferencia entre "el proceso de Postgres existe" y "Postgres ya acepta
  conexiones".

  Esto importa muchísimo en stacks de datos: sin healthcheck, Airflow
  intentará conectarse a una base de datos que todavía está inicializándose
  y fallará con un error confuso. Con healthcheck, Compose sabe esperar.

  En nuestro proyecto: Postgres se comprueba con `pg_isready`, y los
  componentes de Airflow con `airflow jobs check` o con el endpoint HTTP
  `/api/v2/monitor/health`.

### 6. Interactuando con el contenedor: volúmenes y puertos

Un contenedor, por diseño, está **aislado**: su sistema de archivos desaparece
cuando lo borras y su red es invisible desde fuera. Eso es justo lo que
queremos casi siempre... excepto cuando necesitamos que **persistan datos**
entre reinicios o que **algo externo pueda hablar** con el proceso de dentro.
Para lo primero existen los **volúmenes**; para lo segundo, la **publicación
de puertos**. Son mecanismos independientes, así que los vemos por separado.

#### 6.1 Volúmenes — persistencia y datos compartidos

Recuerda el ciclo de vida de la sección 2: un contenedor tiene una **capa
de escritura** encima de las capas de solo lectura de la imagen. Todo lo que
el proceso escribe (una fila nueva en la base de datos, un log, un fichero
temporal) va a parar a esa capa de escritura. El problema es que **esa capa
desaparece con el contenedor** (`docker rm`):

```
┌─────────────────────────────┐
│   Capa de escritura (RW)     │  ← se borra con `docker rm`
├─────────────────────────────┤
│   Capas de la imagen (RO)    │  ← vienen de la imagen, no cambian
└─────────────────────────────┘
```

Si tu base de datos vive solo en esa capa de escritura, un simple
`docker rm postgres` (o recrear el contenedor al actualizar la imagen) borra
**todos tus datos**. Los volúmenes existen para sacar esos datos fuera del
ciclo de vida del contenedor. Docker ofrece dos mecanismos, con propósitos
distintos:

**Bind mount** — montas una ruta **que tú eliges, del host**, dentro del
contenedor. Docker no gestiona nada; simplemente hace visible esa carpeta
del host dentro del contenedor. Es ideal para desarrollo: editas código en
tu editor y lo ves reflejado al instante dentro del contenedor, sin
reconstruir la imagen.

```bash
docker run -v $(pwd)/dags:/opt/airflow/dags apache/airflow:3.3.1-python3.14
#           │                │
#           │                └── ruta DENTRO del contenedor
#           └── ruta EN TU MÁQUINA (la eliges tú, ya debe existir)
```

Aquí, `./dags` en tu proyecto y `/opt/airflow/dags` dentro del contenedor son
**literalmente el mismo directorio** visto desde dos sitios distintos. Si
añades un DAG nuevo en tu editor, el scheduler de Airflow lo ve al instante,
sin reiniciar nada.

**Volumen con nombre (named volume)** — le pides a Docker que te gestione un
espacio de almacenamiento; tú no eliges ni conoces la ruta exacta en el host
(vive bajo `/var/lib/docker/volumes/<nombre>/_data`, gestionado por Docker).
Es ideal para datos persistentes que no necesitas tocar manualmente, como los
ficheros internos de una base de datos.

```bash
docker run -v postgres_data:/var/lib/postgresql postgres:18-alpine
#           │                │
#           │                └── ruta DENTRO del contenedor
#           └── nombre del volumen (Docker decide dónde vive en el host)
```

Si no existe un volumen llamado `postgres_data`, Docker lo crea la primera
vez. Ese volumen **sobrevive** a `docker rm postgres` y puede reutilizarse
por un contenedor distinto más adelante (por ejemplo, tras una actualización
de imagen) — es exactamente lo que vimos que falló en nuestro proyecto real,
cuando un volumen `postgres_data` creado con Postgres 15 no era compatible
con la imagen `postgres:18-alpine` y tuvimos que borrarlo con
`docker compose down -v`.

**Diferencias clave:**

| Aspecto | Bind mount | Volumen con nombre |
|---|---|---|
| **¿Quién elige la ruta?** | Tú, una ruta concreta del host | Docker, tú solo pones un nombre |
| **¿Dónde vive en el host?** | Donde tú digas (`$(pwd)/dags`, `/home/user/...`) | Gestionado por Docker (`/var/lib/docker/volumes/...`) |
| **¿Lo ves y editas fácilmente desde el host?** | Sí, es una carpeta normal | No directamente; solo a través de Docker |
| **¿Sobrevive a `docker rm`?** | Sí (es tu carpeta, ajena a Docker) | Sí (a menos que uses `docker rm -v` o `down -v`) |
| **¿Se puede mover entre máquinas/nubes fácilmente?** | Depende de la ruta del host | Sí, con `docker volume` los puedes respaldar/migrar |
| **Caso de uso típico** | Código fuente, DAGs, configuración que editas | Datos de bases de datos, colas, estado interno |

```bash
docker volume ls                    # lista los volúmenes con nombre
docker volume inspect postgres_data # dónde vive y quién lo usa
docker volume rm postgres_data      # lo borra (¡pierdes los datos!)
```

**¿Cuál uso para qué?** Regla rápida para proyectos de datos:

| Qué guardas | Qué usar |
|---|---|
| Datos de una base de datos | Volumen con nombre |
| Tu código (DAGs, scripts, notebooks) | Bind mount |
| Logs que quieres leer desde tu editor | Bind mount |
| Datos temporales de una tarea | Nada (que se pierdan) |

#### 6.2 Puertos — exponer un servicio al exterior

Cada contenedor arranca con **su propia red aislada**: aunque el proceso de
dentro escuche en el puerto 8080, ese puerto **no es alcanzable** ni desde tu
máquina (el host) ni desde el resto de la red, hasta que lo publicas
explícitamente.

```
┌───────────────────────────┐        ┌───────────────────────────┐
│   Tu máquina (host)        │        │   Contenedor                │
│                             │        │   proceso escuchando :8080  │
│   localhost:8080  ────X────┼────────┤   (aislado, no alcanzable)  │
└───────────────────────────┘        └───────────────────────────┘
```

La bandera `-p` (o `--publish`) crea un puente entre un puerto de tu máquina
y un puerto dentro del contenedor:

```bash
docker run -p 8080:8080 apache/airflow:3.3.1-python3.14 api-server
#           │    │
#           │    └── puerto DENTRO del contenedor (donde escucha el proceso)
#           └── puerto EN TU MÁQUINA (el que tú abres en el navegador)
```

Los dos números **no tienen por qué coincidir**. Por ejemplo, si ya tienes
algo ocupando el 8080 en tu máquina, puedes mapear a otro puerto local sin
tocar la aplicación de dentro:

```bash
docker run -p 9090:8080 apache/airflow:3.3.1-python3.14 api-server
# accedes con http://localhost:9090, el contenedor sigue escuchando en 8080
```

**Variantes útiles de `-p`:**

| Sintaxis | Efecto |
|---|---|
| `-p 8080:8080` | Publica en todas las interfaces de red del host (accesible desde tu red local) |
| `-p 127.0.0.1:8080:8080` | Publica solo en `localhost` — nadie más en tu red puede acceder |
| `-p 9090:8080` | Puerto distinto en el host (9090) que dentro del contenedor (8080) |
| `-p 8080-8090:8080-8090` | Publica un rango de puertos |
| `-P` (mayúscula) | Publica automáticamente todos los puertos que la imagen declara con `EXPOSE`, en puertos aleatorios del host |

En nuestro `docker-compose.yml` usamos `127.0.0.1:8080:8080` para el
`api-server` de Airflow: así solo tú, desde tu propia máquina, puedes acceder
a la interfaz web — nadie más en la misma red Wi-Fi podría entrar escaneando
tu IP. El detalle fino de qué interfaz publicar por seguridad se estudia con
más profundidad en el módulo de *Security and Optimization*, pero conviene
tenerlo presente desde ya como buena práctica por defecto.

**`EXPOSE` en un Dockerfile vs `-p` en `docker run`** — es una confusión muy
habitual:

- `EXPOSE 8080` en un Dockerfile es solo **documentación/metadato**: le dice
  a quien use la imagen "este proceso escucha en el 8080", pero **no publica
  nada por sí solo**.
- `-p` (o `ports:` en Compose) es lo que **realmente** abre el puente hacia
  tu máquina. Sin `-p`, aunque la imagen tenga `EXPOSE`, el puerto sigue
  siendo inalcanzable desde fuera del contenedor.

**Comprobar qué hay publicado:**

```bash
docker port <contenedor>        # qué puertos tiene publicados y hacia dónde
docker ps                       # columna PORTS también lo muestra
```

**Nota sobre contenedores hablando entre sí:** todo lo anterior es para
publicar un puerto **hacia tu host**. Si dos contenedores necesitan hablar
entre ellos (por ejemplo, Airflow con Postgres), **no hace falta `-p`** —
les basta con estar en la misma red de Docker y usar el nombre del servicio
como si fuera un hostname. Eso lo vemos en detalle en la sección 8 (Redes en
Docker Compose).

---

## Parte II — Orquestación con Docker Compose

### 7. De `docker run` a Docker Compose

Cuando una aplicación necesita **varios contenedores que colaboran** (por
ejemplo, Airflow + PostgreSQL), escribir y recordar múltiples comandos
`docker run` con las mismas redes, variables y volúmenes se vuelve
inmanejable. **Docker Compose** resuelve esto describiendo todos los
servicios en un único archivo declarativo, `docker-compose.yml`.

Cada `service:` del archivo es, conceptualmente, la traducción a YAML de un
`docker run` que antes escribirías a mano:

```yaml
services:
  postgres:
    image: postgres:18-alpine   # equivalente a: docker run postgres:18-alpine
    environment:
      POSTGRES_PASSWORD: airflow
```

Comandos básicos:

```bash
docker compose up -d      # crea y arranca todos los servicios (en segundo plano)
docker compose ps         # estado de los servicios del proyecto
docker compose logs -f <servicio>
docker compose down       # para y elimina los contenedores (no los volúmenes)
docker compose down -v    # además elimina los volúmenes con nombre
docker compose config     # valida el archivo y muestra el YAML final "resuelto"
```

> Nota: las versiones modernas de Compose ya no requieren (ni recomiendan)
> la clave `version:` al principio del archivo.

### 8. Redes en Docker Compose

Al ejecutar `docker compose up`, Compose crea automáticamente una **red
privada** para tu proyecto y conecta todos los servicios a ella. Dentro de
esa red, **cada servicio es alcanzable por los demás usando su nombre de
servicio como hostname** (Compose configura un DNS interno automáticamente).

Por ejemplo, si tenemos:

```yaml
services:
  postgres:
    image: postgres:18-alpine
  airflow-scheduler:
    image: apache/airflow:3.3.1-python3.14
```

entonces, **desde dentro** del contenedor `airflow-scheduler`, la base de
datos es alcanzable simplemente como `postgres` (no como `localhost` ni
como una IP fija):

```
postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
                                       └── nombre del servicio, resuelto por el DNS de Compose
```

Esto es exactamente lo que hace nuestra variable
`AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` en el proyecto. **No** necesitas
publicar el puerto `5432` de Postgres al host (`-p`/`ports:`) para que
Airflow pueda conectarse — solo hace falta publicar los puertos que quieras
alcanzar **desde fuera** del proyecto Compose (en nuestro caso, el `8080`
del `airflow-api-server`, para poder abrir la UI desde tu navegador).

### 9. Volúmenes en acción

Igual que con `docker run`, en Compose distinguimos:

- **Volúmenes con nombre**, declarados en la sección `volumes:` de nivel
  superior del archivo, para datos persistentes gestionados por Docker
  (la base de datos de Postgres).
- **Bind mounts**, como `./dags:/opt/airflow/dags`, para nuestro propio
  código, que queremos editar desde el host y ver reflejado sin reconstruir
  ninguna imagen.

```yaml
services:
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql   # volumen con nombre

  airflow-scheduler:
    volumes:
      - ./dags:/opt/airflow/dags            # bind mount

volumes:
  postgres_data:   # declaración del volumen con nombre (nivel superior)
```

Compose también gestiona el **orden de arranque** entre servicios con
`depends_on`. Por defecto solo espera a que el contenedor exista, no a que
esté realmente listo; combinándolo con `healthcheck` y
`condition: service_healthy` / `condition: service_completed_successfully`
conseguimos una orquestación fiable (por ejemplo: que el `airflow-scheduler`
no arranque hasta que `postgres` esté realmente aceptando conexiones, y que
ningún componente de Airflow arranque hasta que `airflow-init` haya
terminado con éxito la migración de la base de datos).

### 10. Contenedores en desarrollo

Para iterar rápido durante el desarrollo (sin reconstruir la imagen en cada
cambio), se monta el propio código fuente como bind mount, tal como hacemos
con `./dags`, `./logs` y `./plugins`. Esto permite editar un DAG en tu
editor y verlo aparecer en la UI de Airflow sin volver a construir ninguna
imagen ni reiniciar contenedores.

Otras prácticas típicas del flujo de desarrollo con Compose:

- Externalizar configuración cambiante (credenciales, puertos, versión de
  imagen) en un archivo **`.env`**, que Compose lee automáticamente y que
  permite tener valores distintos por persona/entorno sin tocar el YAML:

  ```env
  AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
  POSTGRES_PASSWORD=airflow
  ```

  ```yaml
  image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
  ```

- Evitar repetir la misma configuración en cada servicio usando **anclas
  YAML** (`&ancla` / `<<: *ancla`), una característica del propio formato
  YAML (no específica de Compose) que actúa como una plantilla reutilizable:

  ```yaml
  x-airflow-common: &airflow-common
    image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor

  services:
    airflow-scheduler:
      <<: *airflow-common
      command: scheduler
  ```

### 11. Aplicación final: nuestro stack Airflow + PostgreSQL

Todo lo anterior se combina en el [`docker-compose.yml`](../docker-compose.yml)
final de este proyecto:

| Concepto del curso | Dónde aparece en nuestro proyecto |
|---|---|
| Imagen con versión fijada | `postgres:18-alpine`, `apache/airflow:3.3.1-python3.14` |
| Dockerfile / `CMD` sobrescrito | `command: scheduler`, `command: api-server`, ... sobre la misma imagen base |
| Healthcheck + restart policy | `healthcheck:` en cada servicio, `restart: unless-stopped` |
| Bind mount para desarrollo | `./dags`, `./logs`, `./plugins` |
| Volumen con nombre | `postgres_data` |
| Red y DNS de Compose | Airflow se conecta a `postgres` (no a `localhost`) |
| `depends_on` + `condition` | `airflow-init` debe completarse antes de que arranque el resto |
| `.env` | Versiones, puertos y credenciales externalizadas |
| Anclas YAML | `x-airflow-common: &airflow-common` |
| Publicación de puertos | `127.0.0.1:${AIRFLOW_PORT:-8080}:8080` en `airflow-api-server` |

En [EJERCICIOS.md](./EJERCICIOS.md) reconstruimos este archivo paso a paso,
exercise a exercise, hasta llegar exactamente a esta versión final.

---

## Qué queda fuera (a propósito)

Siguiendo el alcance pedido, **no** se cubre aquí el módulo *Security and
Optimization* del curso original, que incluye (y se recomienda ver en otra
sesión):

- Reducción de tamaño de imágenes y *multi-stage builds*.
- Ejecutar contenedores como usuario no-root en profundidad, *capabilities*,
  *read-only filesystems*.
- Escaneo de vulnerabilidades en imágenes.
- Límites de Docker Compose en producción y alternativas de orquestación
  (Kubernetes, Swarm).

Algunos de estos aspectos ya están presentes de forma básica en nuestro
`docker-compose.yml` (por ejemplo, `AIRFLOW_UID` o publicar en
`127.0.0.1`), pero se dejan configurados sin profundizar en el porqué
detallado — eso pertenece al siguiente módulo.

---

## Apéndice A — Chuleta de comandos

Los comandos que realmente vas a usar. Si te aprendes esta tabla, vas
sobrado para el 90 % del trabajo diario.

```bash
# --- Contenedores sueltos ---
docker run -d --name X imagen        # arrancar en segundo plano
docker ps            / docker ps -a  # ver contenedores (activos / todos)
docker logs -f X                     # ver la salida del contenedor
docker exec -it X bash               # abrir una shell dentro
docker stop X        / docker rm X   # parar / borrar

# --- Imágenes ---
docker build -t mi-imagen .          # construir desde el Dockerfile actual
docker image ls                      # imágenes locales
docker pull imagen:tag               # descargar sin ejecutar

# --- Compose (tu día a día) ---
docker compose up -d                 # levantar el stack
docker compose up -d --build         # ídem, reconstruyendo imágenes propias
docker compose ps                    # estado y salud de los servicios
docker compose logs -f servicio      # logs de un servicio
docker compose exec servicio bash    # shell dentro de un servicio
docker compose restart servicio      # reiniciar solo uno
docker compose down                  # parar y borrar contenedores (datos OK)
docker compose down -v               # ⚠️ además borra los volúmenes (pierdes datos)
docker compose config                # validar el YAML y ver el resultado final

# --- Espacio en disco ---
docker system df                     # cuánto ocupa Docker
docker system prune                  # limpiar lo que no se usa
```

---

## Apéndice B — Cuando algo falla

Casi todos los problemas de clase caen en una de estas categorías. El
**orden** de diagnóstico importa: mira siempre primero `ps`, luego `logs`.

| Síntoma | Causa habitual | Qué hacer |
|---|---|---|
| `docker compose ps` muestra `Exited (1)` | El proceso murió al arrancar | `docker compose logs <servicio>` y lee las **últimas** líneas |
| Un servicio se queda en `starting` para siempre | El healthcheck nunca pasa | Ejecuta el comando del healthcheck a mano con `docker compose exec` |
| `port is already allocated` | Otro proceso ocupa el puerto | Cambia el puerto del host (`8081:8080`) o para lo que lo ocupe |
| `could not translate host name "postgres"` | Estás usando `localhost` en vez del nombre del servicio, o el servicio no está en el mismo Compose | Usa el nombre del servicio (§8) |
| `connection refused` a la base de datos | Arrancó antes de que Postgres estuviera listo | `depends_on` + `condition: service_healthy` (§9) |
| Los datos desaparecen al reiniciar | No hay volumen, o hiciste `down -v` | Declara un volumen con nombre (§6) |
| `ModuleNotFoundError` en un DAG | La librería no está en la imagen | Añádela con un Dockerfile (§4.1), no con `pip install` en caliente |
| El DAG nuevo no aparece en la UI | El bind mount no apunta donde crees, o hay un error de sintaxis | `docker compose exec airflow-dag-processor ls /opt/airflow/dags` y mira los logs de ese servicio |
| Todo va lentísimo / se congela | Docker no tiene RAM suficiente | Sube la memoria en Docker Desktop → Settings → Resources |
| "No entiendo qué pasa" | — | `docker compose down -v && docker compose up -d` y empieza limpio |

> **El comando que resuelve más dudas**: `docker compose logs -f`. Antes de
> preguntar, léelo. La respuesta suele estar literalmente escrita ahí.
