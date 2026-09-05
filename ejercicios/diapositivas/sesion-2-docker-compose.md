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

## Sesión 2 — Docker Compose

Máster en Data Engineering, MLOps & Arquitectura Cloud

---

# Dónde estamos

## Ya sabes levantar un contenedor. Ahora tienes que levantar cinco que se hablen entre sí

| Sesión | Contenido | Estado |
|---|---|---|
| 1 | Imágenes y contenedores | Hecha |
| **2. Hoy** | **Docker Compose: orquestación de varios servicios** | |
| 3 | Kubernetes: del contenedor al cluster | |

<div class="aviso">

Recordatorio de la sesión 1: **imagen es plantilla, contenedor es instancia**, `stop` no borra,
los datos van en volúmenes y `-p` es lo que abre el puente. Todo eso se usa hoy.

</div>

---

# El objetivo de hoy

## Al terminar podrás levantar un stack de datos completo y depurarlo

<div class="pasos">
<div><b>01</b><span>Traducir cualquier <code>docker run</code> a un servicio de Compose</span></div>
<div><b>02</b><span>Explicar por qué Airflow se conecta a <code>postgres</code> y no a <code>localhost</code></span></div>
<div><b>03</b><span>Montar tu código con bind mount y editarlo sin reconstruir nada</span></div>
<div><b>04</b><span>Separar Airflow en sus componentes reales y saber cuál mirar cuando falla</span></div>
<div><b>05</b><span>Hacer que el arranque sea fiable con healthchecks y <code>depends_on</code></span></div>
</div>

---

# Contenido de la sesión

## Cinco bloques, cinco ejercicios

<div class="cols">
<div>

**1.** De `docker run` a Compose
  → *Ejercicio 6*
**2.** Redes y DNS interno
  → *Ejercicio 7*
**3.** Volúmenes en Compose
  → *Ejercicio 8*

</div>
<div>

**4.** El stack real de Airflow 3
  → *Ejercicio 9*
**5.** Arranque robusto: healthchecks, `.env`, anclas
  → *Ejercicio 10*
**6.** Cierre: comparación con el proyecto real

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">1</div>
<div class="reloj">≈ 0:00</div>

# De `docker run`<br>a Docker Compose

## Nadie mantiene comandos de ocho líneas con flags. El YAML es el artefacto que se versiona en Git.

---

# El problema que resuelve Compose

## Airflow más Postgres son dos `docker run` que hay que recordar en orden

<div class="cols">
<div>

### Antes

```bash
docker network create red
docker run -d --name postgres \
  --network red \
  -e POSTGRES_PASSWORD=airflow \
  -v pgdata:/var/lib/postgresql \
  postgres:18-alpine
docker run -d --name airflow \
  --network red \
  -e AIRFLOW__DATABASE__... \
  -p 8088:8080 \
  apache/airflow:3.3.1-python3.14
```

</div>
<div>

### Después

```bash
docker compose up -d
```

Y el archivo está en Git, revisado en un *pull request*, idéntico para todo el equipo.

</div>
</div>

---

<!-- _class: lima -->

# Cada `service:` es un `docker run` traducido a YAML

## La correspondencia es casi literal

<div class="cols">
<div>

```bash
docker run \
  --name postgres \
  -e POSTGRES_PASSWORD=airflow \
  -v pgdata:/var/lib/postgresql \
  -p 5433:5432 \
  postgres:18-alpine
```

</div>
<div>

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_PASSWORD: airflow
    volumes:
      - pgdata:/var/lib/postgresql
    ports:
      - "5433:5432"

volumes:
  pgdata:
```

</div>
</div>

---

# Los seis comandos de Compose

## Con estos cubres todo lo que harás hoy

```bash
docker compose up -d          # crea y arranca todo, en segundo plano
docker compose ps             # estado de los servicios del proyecto
docker compose logs -f <servicio>   # sigue los logs de uno concreto

docker compose down           # para y borra contenedores (NO los volúmenes)
docker compose down -v        # además borra los volúmenes con nombre
docker compose config         # valida el YAML y lo muestra ya "resuelto"
```

<div class="aviso">

`docker compose config` es la herramienta más infravalorada: te enseña el YAML **final**,
con las variables sustituidas y las anclas expandidas. Úsala antes de depurar a ciegas.

</div>

---

<!-- _class: navy -->

# Ejercicio 6 — De `docker run` a Compose

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Traduce el Postgres del ejercicio 3

<div class="cols-58">
<div>

```yaml
# sandbox/docker-compose.yml
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

</div>
<div>

```bash
$ cd sandbox
$ docker compose up -d
$ docker compose ps
$ docker compose logs postgres
```

### Fíjate en lo que NO hay

Ni `--name`, ni `-d` por servicio, ni crear el volumen a mano. Compose lo deduce.

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">2</div>
<div class="reloj">≈ 0:20</div>

# Redes y DNS interno

## "No me conecta con la base de datos" es el problema número uno al montar un stack. La causa casi siempre está aquí.

---

# Compose crea una red privada y un DNS

## Cada servicio es alcanzable por su nombre de servicio

<pre class="diagrama">
      Red privada del proyecto Compose
┌──────────────────────────────────────────────────┐
│                                                  │
│   ┌────────────────┐        ┌────────────────┐   │
│   │  airflow       │───────▶│  postgres      │   │
│   │                │  DNS   │  escucha 5432  │   │
│   └────────────────┘interno └────────────────┘   │
│           │                                      │
└───────────┼──────────────────────────────────────┘
            │ ports: 8088:8080
            ▼
     tu navegador → localhost:8088
</pre>

---

<!-- _class: lima -->

# La línea que hay que entender

## El hostname es el nombre del servicio, no `localhost` ni una IP

```
postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
                                      └────────┘
                                      nombre del SERVICIO,
                                      resuelto por el DNS de Compose
```

<div class="aviso">

Dentro del contenedor de Airflow, **`localhost` es el propio Airflow**. Por eso
`@localhost:5432` da `connection refused`: no hay ninguna base de datos escuchando ahí dentro.

</div>

---

# Cuándo hace falta `ports:` y cuándo no

## Solo publicas lo que quieras alcanzar desde fuera del proyecto

| Comunicación | ¿Necesita `ports:`? | Por qué |
|---|---|---|
| Airflow → Postgres | **No** | Ambos están en la red de Compose; basta el nombre |
| Tu navegador → Airflow UI | **Sí** | Tu host está fuera de esa red |
| Tu DBeaver → Postgres | **Sí** | Igual: vienes de fuera |
| Scheduler → API server | **No** | Misma red interna |

<div class="aviso">

Publicar el 5432 "por si acaso" expone tu base de datos a toda la red wifi.
En el proyecto real publicamos solo el 8080, y además atado a `127.0.0.1`.

</div>

---

<!-- _class: navy -->

# Ejercicio 7 — Airflow y la red de Compose

## <span class="pill">25 min</span> <span class="pill">NÚCLEO CLAVE</span> Dos servicios que se hablan

<div class="cols-58">
<div>

```yaml
  airflow:
    image: apache/airflow:3.3.1-python3.14
    command: standalone
    depends_on: [postgres]
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN:
        postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
    ports:
      - "8088:8080"
```

</div>
<div>

### Antes de mirar la solución

¿Qué hostname pones en la cadena de conexión?

### Comprueba el DNS

```bash
$ docker compose exec airflow \
  python -c "import socket; \
  print(socket.gethostbyname('postgres'))"
```

Debe devolver una IP `172.x.x.x`.

</div>
</div>

---

<!-- _class: navy -->

# Experimento: rompe la conexión a propósito

## <span class="pill">2 min</span> Aprende a reconocer este error ahora, no en producción

```bash
# 1. Cambia @postgres:5432 por @localhost:5432 en el YAML
# 2. Recrea solo ese servicio
$ docker compose up -d --force-recreate airflow

# 3. Lee el error
$ docker compose logs airflow | tail -20
```

<div class="aviso">

Vas a ver `connection refused` o `could not translate host name`.
Es literalmente el error que más veces verás en tu carrera con stacks de datos.
Después, déjalo como estaba.

</div>

---

<!-- _class: seccion -->

<div class="num">3</div>
<div class="reloj">≈ 0:55</div>

# Volúmenes en Compose

## Los mismos dos mecanismos de la sesión 1, ahora declarados en el archivo.

---

# Los dos tipos, en sintaxis de Compose

## Volumen con nombre para los datos; bind mount para tu código

```yaml
services:
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql   # volumen con nombre

  airflow-scheduler:
    volumes:
      - ./dags:/opt/airflow/dags            # bind mount

volumes:
  postgres_data:      # los volúmenes con nombre se DECLARAN arriba del todo
```

<div class="aviso">

Se distinguen por la primera parte: si empieza por `.` o `/` es una ruta del host (bind mount);
si es un identificador suelto, es un volumen con nombre y hay que declararlo abajo.

</div>

---

<!-- _class: lima -->

# `down` y `down -v` no son lo mismo

## Una de las dos formas te borra los datos

| Comando | Borra contenedores | Borra volúmenes | Cuándo usarlo |
|---|---|---|---|
| `docker compose stop` | No | No | Pausa temporal |
| `docker compose down` | Sí | **No** | Uso normal a diario |
| `docker compose down -v` | Sí | **Sí** | Empezar de cero a propósito |

<div class="aviso">

`down -v` en el proyecto real de la sesión 1 fue **necesario**: un volumen creado con Postgres 15
no arranca con la imagen `postgres:18-alpine`. Pero en producción, ese mismo comando es un incidente.

</div>

---

<!-- _class: navy -->

# Ejercicio 8 — Monta tus DAGs

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> Editar código sin reconstruir nada

<div class="cols-58">
<div>

```yaml
    volumes:
      - ./dags:/opt/airflow/dags
```

```python
# sandbox/dags/mi_primer_dag.py
from datetime import datetime
from airflow.sdk import DAG
from airflow.providers.standard.operators.bash \
    import BashOperator

with DAG(
    dag_id="mi_primer_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:
    BashOperator(task_id="saludar",
        bash_command='echo "Hola"')
```

</div>
<div>

### Tarea

1. Monta `./dags`
2. Escribe el DAG
3. Compruébalo en la UI **sin reconstruir**
4. Edita el mensaje y observa el cambio

### Sintaxis de Airflow 3

`DAG` viene de `airflow.sdk`.
El parámetro es `schedule=`, no `schedule_interval=`.

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">4</div>
<div class="reloj">≈ 1:30</div>

# El stack real de Airflow 3

## `standalone` es un atajo de desarrollo. Cualquier Airflow real tiene los componentes separados.

---

<!-- _class: denso -->

# Cuatro procesos, la misma imagen, distinto `command:`

## La tabla que hay que saberse: dónde mirar cuando algo falla

| Componente | `command:` | Qué hace | ¿Dónde miro si…? |
|---|---|---|---|
| **API Server** | `api-server` | Web UI y API REST | …no carga la web |
| **Scheduler** | `scheduler` | Decide qué tarea toca y la ejecuta | …la tarea no arranca |
| **DAG Processor** | `dag-processor` | Parsea los `.py` de `dags/` | …**mi DAG no aparece** |
| **Triggerer** | `triggerer` | Tareas diferibles (`deferrable`) | …uso sensores async |

<div class="aviso">

El **DAG Processor separado es obligatorio desde Airflow 3**. En Airflow 2 iba dentro del scheduler.
Si lo olvidas, tus DAGs no aparecen nunca y no hay ningún error que te lo diga.

</div>

---

# Y un quinto contenedor, de un solo uso

## `airflow-init` crea las tablas antes de que arranque nada más

```yaml
  airflow-init:
    image: apache/airflow:3.3.1-python3.14
    entrypoint: ["/bin/bash", "-c"]
    command: ["airflow db migrate"]
    restart: "no"          # es de un solo uso: NO debe reiniciarse
```

<div class="aviso">

`restart: "no"` no es un descuido. Si le pusieras `unless-stopped`, Docker relanzaría la migración
en bucle cada vez que termina correctamente. Los contenedores de tarea única llevan `no`.

</div>

---

<!-- _class: navy -->

# Ejercicio 9 — De `standalone` a la arquitectura real

## <span class="pill">25 min</span> <span class="pill">NÚCLEO</span> Te doy tres servicios; escribe los dos que faltan

<div class="cols">
<div>

### Te damos

```yaml
  airflow-init:
    command: ["airflow db migrate"]
  airflow-api-server:
    command: api-server
  airflow-scheduler:
    command: scheduler
```

</div>
<div>

### Escribe tú

```yaml
  airflow-dag-processor:
    command: ?
  airflow-triggerer:
    command: ?
```

Los cinco llevan el mismo `environment:` y `volumes:`. Cópialo tal cual, aunque sea repetitivo.

</div>
</div>

<div class="aviso">

Sí, es tedioso y frágil. **Ese es justamente el problema que resolvemos en el ejercicio 10.**

</div>

---

<!-- _class: navy -->

# Experimento: mata el DAG Processor

## <span class="pill">3 min</span> El diagnóstico más frecuente de Airflow 3

```bash
$ docker compose stop airflow-dag-processor

# Añade un DAG nuevo en sandbox/dags/ y espera un minuto
# → NO aparece en la UI. Y no hay ningún error visible.

$ docker compose start airflow-dag-processor
# → ahora sí aparece
```

<div class="aviso">

Acabas de aprender a diagnosticar "mi DAG no aparece" sin buscar en Stack Overflow.
Los cuatro procesos fallan **en silencio y por separado**: por eso importa saber cuál hace qué.

</div>

---

<!-- _class: seccion -->

<div class="num">5</div>
<div class="reloj">≈ 1:50</div>

# Arranque robusto

## Sin healthchecks, tu stack arranca bien o mal según qué contenedor gane la carrera. Eso no es aceptable.

---

# `depends_on` a secas no espera lo que crees

## Espera a que el contenedor **exista**, no a que esté **listo**

<div class="cols">
<div>

### El problema

```yaml
  airflow-init:
    depends_on: [postgres]
```

Compose arranca `airflow-init` en cuanto el contenedor de Postgres existe.

Pero Postgres tarda unos segundos en aceptar conexiones.

</div>
<div>

### El síntoma

A veces funciona. A veces:

```
connection refused
```

Es una **carrera**. Y las carreras se ganan casi siempre… hasta el día de la demo.

</div>
</div>

---

<!-- _class: lima -->

# La solución son dos piezas que encajan

## Un healthcheck que define "listo", y una condición que lo espera

<div class="cols">
<div>

### 1. Definir qué es "listo"

```yaml
  postgres:
    healthcheck:
      test: ["CMD-SHELL",
        "pg_isready -U airflow -d airflow"]
      interval: 10s
      timeout: 5s
      retries: 5
```

</div>
<div>

### 2. Esperar a esa condición

```yaml
  airflow-init:
    depends_on:
      postgres:
        condition: service_healthy

  airflow-scheduler:
    depends_on:
      airflow-init:
        condition:
          service_completed_successfully
```

</div>
</div>

---

# Las tres condiciones de `depends_on`

## Cada una espera algo distinto

| Condición | Espera a que… | Uso típico |
|---|---|---|
| `service_started` | El contenedor exista (por defecto) | Casi nunca es lo que quieres |
| `service_healthy` | El healthcheck pase | Bases de datos, colas, APIs |
| `service_completed_successfully` | El contenedor termine con código 0 | Migraciones, `airflow-init` |

<div class="aviso">

**Recuérdalo para la sesión 3**: en Kubernetes esto mismo se llama *readiness probe*.
El concepto es idéntico; cambia el nombre y el sitio donde se declara.

</div>

---

# Configuración fuera del YAML: el `.env`

## Lo que cambia por persona o por entorno no va en el archivo versionado

<div class="cols">
<div>

```env
# sandbox/.env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
AIRFLOW_PORT=8088
POSTGRES_PASSWORD=airflow
```

</div>
<div>

```yaml
    image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
    ports:
      - "${AIRFLOW_PORT:-8088}:8080"
```

La sintaxis `${VAR:-valor}` significa *"usa `VAR`, y si no existe, este valor por defecto"*.

</div>
</div>

<div class="aviso">

El `.env` **no se sube a Git**. Por eso el YAML sí puede subirse sin exponer credenciales.

</div>

---

# Anclas YAML: dejar de copiar y pegar cinco veces

## No es de Compose, es del propio formato YAML

```yaml
x-airflow-common: &airflow-common        # define la plantilla
  image: ${AIRFLOW_IMAGE_NAME}
  environment:
    AIRFLOW__CORE__EXECUTOR: LocalExecutor
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
  volumes:
    - ./dags:/opt/airflow/dags

services:
  airflow-scheduler:
    <<: *airflow-common                  # "pega aquí todo lo de la plantilla"
    command: scheduler

  airflow-dag-processor:
    <<: *airflow-common
    command: dag-processor
```

---

<!-- _class: navy -->

# Ejercicio 10 — Arranque robusto y configuración limpia

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> Primero provoca el fallo, luego arréglalo

<div class="cols">
<div>

### Parte A — el problema

```bash
$ docker compose down -v
$ docker compose up -d
$ docker compose logs airflow-init | head -40
```

Repite dos o tres veces. Verás que no siempre pasa lo mismo.

</div>
<div>

### Parte B — los cuatro arreglos

1. `healthcheck` en Postgres
2. `depends_on` con `condition:`
3. `.env` con lo que cambia
4. Anclas YAML

```bash
$ docker compose config
$ docker compose down -v && \
  docker compose up -d
```

</div>
</div>

---

<!-- _class: navy -->

# Ejercicio 10 — Para pensar

## Tres preguntas que conviene responder en voz alta

<div class="pasos">
<div><b>01</b><span>¿Por qué <code>airflow-init</code> lleva <code>restart: "no"</code> y los demás no?</span></div>
<div><b>02</b><span>Las anclas son YAML puro, no Compose. ¿Qué ventaja real tienen sobre copiar y pegar?</span></div>
<div><b>03</b><span>El <code>.env</code> no se sube a Git. ¿Qué problema resuelve eso exactamente?</span></div>
</div>

### Validación

`docker compose up -d` arranca bien **varias veces seguidas** tras `down -v`.
Ya no hay carrera.

---

<!-- _class: seccion -->

<div class="num">6</div>
<div class="reloj">≈ 2:05</div>

# Cierre

## Has reconstruido, paso a paso, casi el mismo archivo que usa el proyecto real.

---

<!-- _class: denso -->

# Todo lo de hoy, en el `docker-compose.yml` real

## Cada concepto tiene una línea concreta donde vive

| Concepto | Dónde aparece en el proyecto |
|---|---|
| Imagen con versión fijada | `postgres:18-alpine`, `apache/airflow:3.3.1-python3.14` |
| `CMD` sobrescrito | `command: scheduler`, `command: api-server`… |
| Healthcheck y política de reinicio | `healthcheck:` por servicio, `restart: unless-stopped` |
| Bind mount para desarrollo | `./dags`, `./logs`, `./plugins` |
| Volumen con nombre | `postgres_data` |
| Red y DNS de Compose | Airflow se conecta a `postgres` |
| `depends_on` con condiciones | `airflow-init` antes que el resto |
| `.env` y anclas YAML | `x-airflow-common: &airflow-common` |
| Publicación de puertos | `127.0.0.1:${AIRFLOW_PORT:-8080}:8080` |

---

<!-- _class: lima -->

# Nada de esto era de Airflow

## Hoy has usado Airflow como excusa. El patrón es idéntico en cualquier stack de datos.

| Stack | Servicios que levantas | La pieza que te va a doler |
|---|---|---|
| **Airflow** | api-server, scheduler, dag-processor, Postgres | El DNS interno y el orden de arranque |
| **Kafka** | broker, controlador (KRaft), una UI | Los `listeners`: dentro y fuera de la red |
| **Spark** | master y uno o varios workers | Los puertos del *driver* y la memoria |
| **dbt** | dbt más el *warehouse* de destino | El `profiles.yml`, montado como bind mount |

<div class="aviso">

Cambian los nombres de los servicios y las variables de entorno. **No cambia nada más**: sigue
siendo un `services:`, una red implícita, unos volúmenes y un `depends_on` con condiciones.

</div>

---

<!-- _class: navy -->

# Preguntas de repaso

## Si puedes responderlas, la sesión ha cumplido

<div class="pasos">
<div><b>01</b><span>Tu compañero clona el repo y hace <code>docker compose up -d</code>. ¿Qué necesita tener instalado? ¿Cambia algo si él usa Windows y tú Mac?</span></div>
<div><b>02</b><span>Un DAG falla con <code>ModuleNotFoundError: No module named 'requests'</code>. ¿Cuál es el arreglo correcto y cuál es el atajo que no debes usar?</span></div>
<div><b>03</b><span>Haces <code>down -v</code> en producción por error. ¿Qué has perdido? ¿Y con <code>down</code> a secas?</span></div>
<div><b>04</b><span>¿Por qué Airflow se conecta a <code>postgres</code> y tú, desde el navegador, a <code>localhost:8080</code>?</span></div>
<div><b>05</b><span>Tu DAG nuevo no aparece. Enumera tres cosas que comprobarías, en orden.</span></div>
</div>

---

<!-- _class: lima -->

# Limpieza antes de irte

## Compose deja volúmenes e imágenes que ocupan disco de verdad

```bash
$ cd ejercicios/sandbox
$ docker compose down -v

$ docker system df        # mira cuánto ocupa Docker
$ docker system prune     # libera lo que ya no se usa
```

<div class="aviso">

En la sesión 3 vas a levantar un cluster de minikube que pide 4 GB de RAM.
Si dejas cinco contenedores de Airflow corriendo, tu portátil se va a quejar.

</div>

---

<!-- _class: verde -->

# En la sesión 3

## Compose orquesta contenedores en una máquina. Kubernetes lo hace en muchas — y cambia las reglas.

<div class="cols">
<div>

### Lo que viene

- Por qué Compose no basta en producción
- Pod, Deployment, Service
- ConfigMaps, Secrets y volúmenes persistentes
- Job y CronJob: el equivalente a un DAG programado

</div>
<div>

### Antes de la sesión 3

Ve los **vídeos de Kubernetes**.

Lee el **mínimo viable** de `TEORIA_KUBERNETES.md`: secciones 3, 4, 5 y 9. Son 45 minutos.

Comprueba que `minikube` arranca.

</div>
</div>
