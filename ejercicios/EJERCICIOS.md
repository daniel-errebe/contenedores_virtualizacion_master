# Ejercicios de Docker para Data Engineers

> Material didáctico para la asignatura de contenedorización del máster de
> Data Engineering. Los conceptos están adaptados del curso
> [DevOps with Docker](https://courses.mooc.fi/org/uh-cs/courses/devops-with-docker-spring-2026)
> (Universidad de Helsinki, CC BY-NC-SA), reenfocados hacia el trabajo real
> con stacks de datos.

Teoría de apoyo: **[TEORIA.md](./TEORIA.md)**
Ejercicios de ampliación: **[EJERCICIOS_EXTRA.md](./EJERCICIOS_EXTRA.md)**
Si algo falla: **[TEORIA.md § Apéndice B](./TEORIA.md#apéndice-b--cuando-algo-falla)**

---

## Antes de la clase (obligatorio)

La imagen de Airflow pesa ~1,5 GB. Si la descargas en clase, pierdes media
sesión esperando. **Haz esto en casa, con buena conexión:**

```bash
# 1. Comprueba que Docker funciona
docker --version
docker compose version
docker run --rm hello-world

# 2. Descarga las imágenes que usaremos (tarda, pero es una sola vez)
docker pull postgres:18-alpine
docker pull apache/airflow:3.3.1-python3.14
docker pull alpine:3.21
```

**Requisitos**: Docker Desktop (o Docker Engine) y **al menos 4 GB de RAM
asignados a Docker** (Docker Desktop → Settings → Resources). Con menos, el
stack completo de Airflow irá muy lento.

---

## Cómo usar estos ejercicios

Cada ejercicio sigue el mismo formato:

- **Objetivo** — qué habilidad concreta practicas.
- **Por qué te importa** — para qué sirve esto en tu trabajo como Data Engineer.
- **Conceptos** — enlace a la teoría necesaria.
- **Tarea** — lo que tienes que hacer.
- **Solución** — despliégala solo si te atascas.
- **Validación** — cómo sabes que lo has hecho bien.

Los ejercicios marcados **⭐ NÚCLEO** son imprescindibles. Los marcados
*(opcional)* se pueden saltar sin perder el hilo — están ahí por si vas
rápido o quieres repasar en casa.

### Espacio de trabajo

Todo se hace en una carpeta **aparte** del proyecto real, para no romperlo:

```bash
cd mi_proyecto_airflow/ejercicios
mkdir -p sandbox && cd sandbox
```

Usaremos el **puerto 8088** en el sandbox (el proyecto final usa el 8080),
así que nunca chocarán aunque tengas los dos levantados.

> Compose nombra el proyecto según la carpeta donde está el YAML. Al
> trabajar en `sandbox/`, tus contenedores y volúmenes son independientes de
> los del proyecto real.

---

## Plan de la sesión

| Bloque | Contenido | Ejercicios | Práctica |
|---|---|---|---|
| 1 | Contenedores: ejecutar, inspeccionar, persistir | 1 – 3 | ~50 min |
| 2 | Imágenes propias con Dockerfile | 4 – 5 | ~40 min |
| 3 | Docker Compose: varios servicios que se hablan | 6 – 8 | ~55 min |
| 4 | El stack real de Airflow 3 | 9 – 10 | ~45 min |

Total de práctica: **~3 h 10 min**. El resto de las 5 horas se reparte entre
teoría, descansos y el cierre.

---

# Bloque 1 — Contenedores

## Ejercicio 1 ⭐ NÚCLEO — Tu primer contenedor (15 min)

**Objetivo**: ejecutar, listar, inspeccionar y eliminar un contenedor.

**Por qué te importa**: es el ciclo que repetirás mil veces. Sin esto no
puedes ni levantar ni depurar nada.

**Conceptos**: [§1](./TEORIA.md#1-qué-es-un-contenedor-qué-es-una-imagen),
[§2](./TEORIA.md#2-ejecutar-y-detener-contenedores)

### Tarea

1. Ejecuta un contenedor de `alpine:3.21` que imprima un mensaje y termine.
2. Ejecuta otro, esta vez **en segundo plano**, que se quede vivo 5 minutos.
3. Compruébalo con `docker ps`. Ahora prueba `docker ps -a`. ¿Qué cambia?
4. Mira sus logs, párale y bórralo.

### Solución

<details>
<summary>Ver solución</summary>

```bash
# 1. En primer plano: se ejecuta, imprime y el contenedor termina
docker run alpine:3.21 echo "Hola desde un contenedor"

# 2. En segundo plano (-d = detached), con un nombre para referirnos a él
docker run -d --name prueba alpine:3.21 sleep 300

# 3. Solo contenedores en ejecución / todos, incluidos los terminados
docker ps
docker ps -a

# 4. Logs, parada y borrado
docker logs prueba
docker stop prueba
docker rm prueba
```

`docker ps` muestra solo lo que está corriendo. `docker ps -a` muestra
también los `Exited` — ahí verás el del paso 1, que ya terminó pero **sigue
existiendo** ocupando espacio hasta que lo borres.

</details>

### Validación

`docker ps -a` no lista ningún contenedor llamado `prueba`.

> **Truco**: añade `--rm` (`docker run --rm alpine:3.21 echo hola`) y el
> contenedor se autoelimina al terminar. Úsalo siempre para pruebas rápidas.

---

## Ejercicio 2 ⭐ NÚCLEO — Los contenedores son efímeros (15 min)

**Objetivo**: entrar en un contenedor en marcha y comprobar de primera mano
que sus cambios no sobreviven.

**Por qué te importa**: esta es *la* lección que separa a quien entiende
Docker de quien no. Explica por qué se pierden tus datos, por qué desaparece
una librería que instalaste "a mano" y por qué existen los volúmenes.

**Conceptos**: [§2](./TEORIA.md#2-ejecutar-y-detener-contenedores)

### Tarea

1. Arranca un contenedor de `alpine:3.21` en segundo plano.
2. Ábrete una shell **dentro** de él y crea un archivo con contenido.
3. Sal, **para y borra** el contenedor.
4. Arranca otro contenedor de la misma imagen. ¿Está tu archivo?

### Solución

<details>
<summary>Ver solución</summary>

```bash
docker run -d --name efimero alpine:3.21 sleep 600

# Entramos: -i mantiene la entrada abierta, -t da una terminal
docker exec -it efimero sh
```

Dentro del contenedor:

```sh
echo "datos importantes" > /tmp/informe.txt
cat /tmp/informe.txt
exit
```

De vuelta en tu máquina:

```bash
docker stop efimero && docker rm efimero
docker run --rm alpine:3.21 cat /tmp/informe.txt
# -> cat: can't open '/tmp/informe.txt': No such file or directory
```

</details>

### Validación

El segundo contenedor no encuentra el archivo. **El contenedor era la
"instancia"; la imagen sigue intacta y no recuerda nada de lo que hiciste.**

### Para pensar

- Si instalas `pandas` con `docker exec ... pip install pandas`, ¿seguirá
  ahí mañana? ¿Y para tu compañero de equipo?
- ¿Dónde crees entonces que debería guardar sus archivos una base de datos?

---

## Ejercicio 3 ⭐ NÚCLEO — Volúmenes y puertos: que los datos sobrevivan (20 min)

**Objetivo**: levantar una base de datos real, persistir sus datos con un
volumen y acceder a ella desde tu máquina.

**Por qué te importa**: es exactamente lo que hace la base de datos de
metadatos de Airflow, y lo que harás con cualquier Postgres, MySQL o MinIO
de tus proyectos.

**Conceptos**: [§6](./TEORIA.md#6-interactuando-con-el-contenedor-volúmenes-y-puertos)

### Tarea

1. Levanta `postgres:18-alpine` con contraseña, **volumen con nombre** y el
   puerto publicado en `5433` de tu máquina.
2. Conéctate y crea una tabla con una fila.
3. **Borra el contenedor** y vuelve a crearlo con el mismo volumen.
4. Comprueba que tu fila sigue ahí.

> ⚠️ En PostgreSQL 18 la ruta de datos es `/var/lib/postgresql`
> (en versiones anteriores era `/var/lib/postgresql/data`). Si montas la
> ruta antigua, el volumen no persistirá nada.

### Solución

<details>
<summary>Ver solución</summary>

```bash
docker run -d --name pg-demo \
  -e POSTGRES_PASSWORD=secreto \
  -e POSTGRES_USER=demo \
  -e POSTGRES_DB=demo \
  -v pg_demo_data:/var/lib/postgresql \
  -p 5433:5432 \
  postgres:18-alpine
```

```bash
# Creamos datos (psql dentro del propio contenedor)
docker exec -it pg-demo psql -U demo -d demo -c \
  "CREATE TABLE ventas(id INT, importe NUMERIC); INSERT INTO ventas VALUES (1, 99.5);"

# Destruimos el contenedor por completo
docker stop pg-demo && docker rm pg-demo

# Lo recreamos apuntando al MISMO volumen
docker run -d --name pg-demo \
  -e POSTGRES_PASSWORD=secreto -e POSTGRES_USER=demo -e POSTGRES_DB=demo \
  -v pg_demo_data:/var/lib/postgresql \
  -p 5433:5432 postgres:18-alpine

docker exec -it pg-demo psql -U demo -d demo -c "SELECT * FROM ventas;"
```

</details>

### Validación

La consulta devuelve `1 | 99.5` aunque el contenedor sea nuevo. `docker
volume ls` muestra `pg_demo_data`.

### Limpieza

```bash
docker stop pg-demo && docker rm pg-demo
docker volume rm pg_demo_data
```

### Para pensar

- ¿Por qué publicamos en `5433` y no en `5432`?
- ¿Qué habría pasado en el paso 4 sin el flag `-v`?

---

# Bloque 2 — Imágenes propias

## Ejercicio 4 ⭐ NÚCLEO — Tu primer Dockerfile (15 min)

**Objetivo**: construir una imagen propia y ejecutarla.

**Por qué te importa**: es el paso previo (y sencillo) al ejercicio 5, que
es el que de verdad usarás.

**Conceptos**: [§4](./TEORIA.md#4-construyendo-imágenes-con-un-dockerfile)

### Tarea

Crea en `sandbox/hello/` un script `hello.sh` que imprima un saludo, y un
`Dockerfile` que lo copie a una imagen basada en `alpine:3.21` y lo ejecute
por defecto. Construye la imagen como `mi-saludo` y ejecútala.

### Solución

<details>
<summary>Ver solución</summary>

`sandbox/hello/hello.sh`:

```sh
#!/bin/sh
echo "Hola desde MI imagen"
```

`sandbox/hello/Dockerfile`:

```dockerfile
FROM alpine:3.21
WORKDIR /usr/src/app
COPY hello.sh .
RUN chmod +x hello.sh
CMD ["./hello.sh"]
```

```bash
cd sandbox/hello
docker build -t mi-saludo .
docker run --rm mi-saludo
```

</details>

### Validación

`docker run --rm mi-saludo` imprime tu saludo.

Ahora **cambia el texto del script y reconstruye**. Fíjate en la salida del
build: los pasos anteriores dicen `CACHED` y solo se rehace desde el `COPY`.
Esa es la caché de capas en acción.

---

## Ejercicio 5 ⭐⭐ NÚCLEO CLAVE — Añadir una librería Python a Airflow (25 min)

**Objetivo**: extender una imagen oficial con las dependencias que tu código
necesita.

**Por qué te importa**: **este es el ejercicio más útil de toda la clase.**
El día que tu DAG haga `import pandas` y falle con `ModuleNotFoundError`,
esto es exactamente lo que tendrás que hacer.

**Conceptos**: [§4.1](./TEORIA.md#41-el-caso-que-más-te-va-a-tocar-añadir-dependencias-a-una-imagen-existente)

### Tarea

1. Comprueba que la imagen oficial de Airflow **no** trae `duckdb`.
2. Escribe un `Dockerfile` en `sandbox/airflow-custom/` que parta de
   `apache/airflow:3.3.1-python3.14` e instale `duckdb`.
3. Construye la imagen como `mi-airflow:1.0`.
4. Verifica que ahora sí está.

### Solución

<details>
<summary>Ver solución</summary>

```bash
# 1. Confirmamos que falta
docker run --rm apache/airflow:3.3.1-python3.14 python -c "import duckdb"
# -> ModuleNotFoundError: No module named 'duckdb'
```

`sandbox/airflow-custom/Dockerfile`:

```dockerfile
FROM apache/airflow:3.3.1-python3.14

# La imagen oficial ya define USER airflow.
# pip DEBE ejecutarse como ese usuario, nunca como root.
RUN pip install --no-cache-dir duckdb==1.1.3
```

```bash
cd sandbox/airflow-custom
docker build -t mi-airflow:1.0 .

# 4. Verificamos
docker run --rm mi-airflow:1.0 python -c "import duckdb; print(duckdb.__version__)"
```

</details>

### Validación

El último comando imprime la versión de DuckDB en lugar de un error.

### Extensión: `requirements.txt`

Con una sola librería el `RUN pip install` directo vale. Con diez, se hace
inmanejable. Crea un `requirements.txt` y cámbialo:

```dockerfile
FROM apache/airflow:3.3.1-python3.14
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

```
# requirements.txt
duckdb==1.1.3
pandas==2.2.3
```

### Para pensar

- ¿Por qué fijamos la versión (`duckdb==1.1.3`) en vez de instalar la última?
- Si mañana añades `pandas` al `requirements.txt`, ¿qué capas se reconstruyen?
- ¿Qué diferencia hay entre hacer esto y ejecutar
  `docker compose exec airflow-scheduler pip install duckdb`?

---

# Bloque 3 — Docker Compose

## Ejercicio 6 ⭐ NÚCLEO — De `docker run` a Compose (15 min)

**Objetivo**: traducir un `docker run` largo a un archivo declarativo.

**Por qué te importa**: nadie mantiene comandos de 8 líneas con flags. El
`docker-compose.yml` es el artefacto que se versiona en Git y que compartes
con tu equipo.

**Conceptos**: [§7](./TEORIA.md#7-de-docker-run-a-docker-compose)

### Tarea

Convierte el `docker run` de Postgres del ejercicio 3 en un
`sandbox/docker-compose.yml`. Levántalo, mira su estado y sus logs.

### Solución

<details>
<summary>Ver solución</summary>

`sandbox/docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres_data:/var/lib/postgresql

volumes:
  postgres_data:
```

```bash
cd sandbox
docker compose up -d
docker compose ps
docker compose logs postgres
```

</details>

### Validación

`docker compose ps` muestra el servicio `postgres` en estado `running`.

Fíjate en lo que **no** hemos escrito: ni `--name`, ni `-d` por servicio, ni
crear el volumen a mano. Compose lo deduce del archivo. Tampoco hemos
publicado el puerto 5432 — lo haremos solo si necesitamos entrar desde
fuera.

---

## Ejercicio 7 ⭐⭐ NÚCLEO CLAVE — Airflow y la red de Compose (25 min)

**Objetivo**: añadir un segundo servicio y hacer que se comuniquen.

**Por qué te importa**: "no me conecta con la base de datos" es el problema
número 1 al montar cualquier stack de datos. La causa casi siempre es esta.

**Conceptos**: [§8](./TEORIA.md#8-redes-en-docker-compose)

### Tarea

1. Añade un servicio `airflow` que use `command: standalone` (arranca todos
   los componentes en un solo contenedor — versión simplificada para
   aprender) y publique el puerto **8088**.
2. Configúralo para que use el Postgres del ejercicio anterior.
3. **Antes de mirar la solución**: ¿qué hostname pones en la cadena de
   conexión?
4. Entra en el contenedor de Airflow y comprueba que resuelve el nombre.

### Solución

<details>
<summary>Ver solución</summary>

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres_data:/var/lib/postgresql

  airflow:
    image: apache/airflow:3.3.1-python3.14
    command: standalone
    depends_on:
      - postgres
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      # ↓ "postgres" es el NOMBRE DEL SERVICIO, no localhost ni una IP
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
      AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS: "true"
    ports:
      - "8088:8080"

volumes:
  postgres_data:
```

```bash
docker compose up -d
docker compose logs -f airflow    # Ctrl+C cuando veas que ha arrancado

# 4. Comprobamos el DNS interno de Compose
docker compose exec airflow python -c \
  "import socket; print(socket.gethostbyname('postgres'))"
```

Abre <http://localhost:8088> y entra con cualquier usuario/contraseña.

</details>

### Validación

La UI de Airflow carga en <http://localhost:8088> y el comando `socket`
devuelve una IP privada (algo como `172.x.x.x`).

### La lección

Compose crea una red privada y un **DNS interno** donde cada servicio es
alcanzable **por su nombre de servicio**. Dentro del contenedor de Airflow,
`localhost` es el propio Airflow — no Postgres.

### Experimento (2 min)

Cambia `@postgres:5432` por `@localhost:5432`, haz
`docker compose up -d --force-recreate airflow` y lee el error en los logs.
**Aprende a reconocer ese mensaje**: lo vas a ver muchas veces en tu carrera.

Luego déjalo como estaba.

---

## Ejercicio 8 ⭐ NÚCLEO — Monta tus DAGs y ejecuta el primero (20 min)

**Objetivo**: usar un bind mount para que tu código del host esté disponible
dentro del contenedor.

**Por qué te importa**: es lo que te permite editar un DAG en VS Code y
verlo en Airflow sin reconstruir ni reiniciar nada.

**Conceptos**: [§6](./TEORIA.md#6-interactuando-con-el-contenedor-volúmenes-y-puertos),
[§10](./TEORIA.md#10-contenedores-en-desarrollo)

### Tarea

1. Crea `sandbox/dags/` y monta esa carpeta en `/opt/airflow/dags`.
2. Escribe un DAG sencillo.
3. Sin reconstruir la imagen, comprueba que aparece en la UI y ejecútalo.
4. **Sin parar nada**, edita el mensaje del DAG y observa el cambio.

### Solución

<details>
<summary>Ver solución</summary>

En el servicio `airflow` del `docker-compose.yml`:

```yaml
    volumes:
      - ./dags:/opt/airflow/dags
```

`sandbox/dags/mi_primer_dag.py`:

```python
from datetime import datetime

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

with DAG(
    dag_id="mi_primer_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["clase"],
) as dag:
    BashOperator(
        task_id="saludar",
        bash_command='echo "Mi DAG vive en el host y se ejecuta en el contenedor"',
    )
```

```bash
docker compose up -d
```

En la UI (<http://localhost:8088>): busca `mi_primer_dag`, actívalo y
lánzalo con *Trigger*. Mira la salida en *Logs* de la tarea.

</details>

### Validación

El DAG aparece en la UI sin haber reconstruido ninguna imagen, y su tarea
termina en verde.

> ⚠️ **Sintaxis de Airflow 3**: se importa `DAG` desde `airflow.sdk` y los
> operadores básicos desde `airflow.providers.standard.operators.*`. El
> parámetro es `schedule=`, no `schedule_interval=` (eso era Airflow 2).

### Para pensar

- El código está en **tu disco** pero se ejecuta **dentro del contenedor**.
  ¿Qué pasaría si tu DAG importa una librería que tú tienes instalada en tu
  máquina pero no está en la imagen? (Ver ejercicio 5.)

---

# Bloque 4 — El stack real

## Ejercicio 9 ⭐ NÚCLEO — De `standalone` a la arquitectura real (25 min)

**Objetivo**: separar Airflow en sus componentes reales, como en producción.

**Por qué te importa**: `standalone` es un atajo de desarrollo. Cualquier
Airflow real tiene los componentes separados, y necesitas saber **cuál mirar
cuando algo falla**.

**Conceptos**: [§7](./TEORIA.md#7-de-docker-run-a-docker-compose),
[§4.2](./TEORIA.md#42-cmd-y-command)

### Contexto

En **Airflow 3** el stack mínimo son cuatro procesos, todos con **la misma
imagen** y distinto `command:`:

| Componente | `command:` | Qué hace | ¿Dónde miro si...? |
|---|---|---|---|
| API Server | `api-server` | Web UI + API REST | ...no carga la web |
| Scheduler | `scheduler` | Decide qué tarea toca y la ejecuta (LocalExecutor) | ...la tarea no arranca |
| DAG Processor | `dag-processor` | Parsea los archivos `.py` de `dags/` | ...mi DAG no aparece |
| Triggerer | `triggerer` | Ejecuta tareas diferibles (`deferrable`) | ...uso sensores async |

> El **DAG Processor separado es obligatorio desde Airflow 3**. En Airflow 2
> iba dentro del scheduler. Si lo olvidas, tus DAGs nunca aparecen.

Además necesitamos un contenedor **de un solo uso** que cree las tablas de
la base de datos antes de que arranque nada: `airflow-init`.

### Tarea

Sustituye el servicio único `airflow` por los cinco servicios. Para no
perder tiempo copiando YAML, **te damos tres**; escribe tú los dos que
faltan (`airflow-dag-processor` y `airflow-triggerer`).

Los cinco llevan **el mismo bloque `environment:` y `volumes:`** que tenía
el servicio `airflow` (la conexión a Postgres y `./dags`). De momento
cópialo tal cual en cada uno — sí, es repetitivo y frágil; eso es
justamente el problema que resolveremos en el ejercicio 10.

```yaml
  airflow-init:
    image: apache/airflow:3.3.1-python3.14
    depends_on: [postgres]
    # environment: (el mismo de siempre)
    entrypoint: ["/bin/bash", "-c"]
    command: ["airflow db migrate"]
    restart: "no"                  # es de un solo uso: no debe reiniciarse

  airflow-api-server:
    image: apache/airflow:3.3.1-python3.14
    command: api-server
    ports:
      - "8088:8080"

  airflow-scheduler:
    image: apache/airflow:3.3.1-python3.14
    command: scheduler
```

### Solución

<details>
<summary>Ver solución</summary>

Los dos que faltan son idénticos salvo el `command:`:

```yaml
  airflow-dag-processor:
    image: apache/airflow:3.3.1-python3.14
    command: dag-processor

  airflow-triggerer:
    image: apache/airflow:3.3.1-python3.14
    command: triggerer
```

Los cinco necesitan las mismas `environment:` y `volumes:` (conexión a la
base de datos y `./dags`). Repetirlo en cada uno es tedioso y frágil — lo
arreglamos en el ejercicio 10.

```bash
docker compose up -d
docker compose ps
```

</details>

### Validación

`docker compose ps` muestra los cinco servicios: `airflow-init` en `exited
(0)` y los otros cuatro corriendo. Tu DAG sigue apareciendo en la UI.

### Experimento (3 min)

```bash
docker compose stop airflow-dag-processor
```

Añade un DAG nuevo en `sandbox/dags/` y espera un minuto. **No aparece.**
Vuelve a arrancarlo y aparecerá. Acabas de aprender a diagnosticar el
problema más frecuente de Airflow 3.

---

## Ejercicio 10 ⭐ NÚCLEO — Arranque robusto y configuración limpia (20 min)

**Objetivo**: aplicar healthchecks, orden de arranque, `.env` y anclas YAML.

**Por qué te importa**: sin healthchecks, tu stack falla aleatoriamente al
arrancar según qué contenedor gane la carrera. Con ellos, arranca siempre
bien.

**Conceptos**: [§5](./TEORIA.md#5-condiciones-de-arranque-del-contenedor),
[§9](./TEORIA.md#9-volúmenes-en-acción),
[§10](./TEORIA.md#10-contenedores-en-desarrollo)

### Parte A — El problema (5 min)

```bash
docker compose down -v
docker compose up -d
docker compose logs airflow-init | head -40
```

Con `depends_on: [postgres]` a secas, Compose solo espera a que el
**contenedor exista**, no a que Postgres **acepte conexiones**. Es una
carrera: a veces funciona, a veces ves `connection refused`.

### Parte B — La solución (15 min)

Aplica los tres arreglos:

<details>
<summary>Ver solución</summary>

**1. Healthcheck en Postgres + espera real:**

```yaml
services:
  postgres:
    image: postgres:18-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U airflow -d airflow"]
      interval: 10s
      timeout: 5s
      retries: 5
```

**2. Cadena de dependencias con condiciones:**

```yaml
  airflow-init:
    depends_on:
      postgres:
        condition: service_healthy          # espera a que ACEPTE conexiones

  airflow-scheduler:
    depends_on:
      airflow-init:
        condition: service_completed_successfully   # espera a que TERMINE bien
```

**3. Configuración fuera del YAML** — un archivo `sandbox/.env`:

```env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
AIRFLOW_PORT=8088
POSTGRES_PASSWORD=airflow
```

```yaml
    image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
    ports:
      - "${AIRFLOW_PORT:-8088}:8080"
```

**4. Anclas YAML** para no repetir el bloque común cinco veces:

```yaml
x-airflow-common: &airflow-common          # define la plantilla
  image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
  environment:
    AIRFLOW__CORE__EXECUTOR: LocalExecutor
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
    AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS: "true"
  volumes:
    - ./dags:/opt/airflow/dags

services:
  airflow-scheduler:
    <<: *airflow-common                    # "pega aquí todo lo de la plantilla"
    command: scheduler

  airflow-dag-processor:
    <<: *airflow-common
    command: dag-processor
```

```bash
docker compose config      # valida el YAML y muestra cómo queda "resuelto"
docker compose down -v && docker compose up -d
docker compose ps
```

</details>

### Validación

- `docker compose config` no da errores y muestra la configuración expandida.
- `docker compose up -d` arranca correctamente **varias veces seguidas**
  tras `down -v` (ya no hay carrera).
- `docker compose ps` muestra `(healthy)` en Postgres.

### Para pensar

- ¿Por qué `airflow-init` lleva `restart: "no"` y los demás no?
- Las anclas son YAML puro, no Compose. ¿Qué ventaja tiene sobre copiar y
  pegar?
- El `.env` **no** se sube a Git. ¿Qué problema resuelve eso?

---

# Cierre (15 min)

Compara tu `sandbox/docker-compose.yml` con el
[`docker-compose.yml`](../docker-compose.yml) del proyecto real. Has llegado
prácticamente al mismo sitio; las diferencias son detalles de robustez
(healthchecks en todos los servicios de Airflow, `restart: unless-stopped`,
publicar en `127.0.0.1`).

```bash
# Levanta el proyecto real y compruébalo
cd ../..            # a mi_proyecto_airflow/
docker compose up -d
docker compose ps
# UI en http://localhost:8080
```

### Preguntas de repaso

1. Tu compañero clona el repo y hace `docker compose up -d`. ¿Qué
   necesita tener instalado? ¿Y si su máquina es Windows y la tuya Mac?
2. Un DAG falla con `ModuleNotFoundError: No module named 'requests'`.
   ¿Cuál es el arreglo correcto y cuál es el atajo que no debes usar?
3. Haces `docker compose down -v` en producción por error. ¿Qué has perdido?
   ¿Y con `docker compose down` a secas?
4. ¿Por qué Airflow se conecta a `postgres` y tú, desde tu navegador, a
   `localhost:8080`?
5. Tu DAG nuevo no aparece en la UI. Enumera tres cosas que comprobarías,
   en orden.

### Limpieza

```bash
cd ejercicios/sandbox && docker compose down -v
docker system prune          # libera espacio de imágenes y contenedores sueltos
```

---

## ¿Te ha sabido a poco?

Sigue con **[EJERCICIOS_EXTRA.md](./EJERCICIOS_EXTRA.md)**: DAGs que
escriben en Postgres, inspeccionar la base de datos con Adminer,
mini-pipelines con `pandas` y varios ejercicios de depuración.
