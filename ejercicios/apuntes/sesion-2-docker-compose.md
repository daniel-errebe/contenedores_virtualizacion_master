<div class="cover">
<div class="cover-modulo">Módulo · Contenedores y Virtualización</div>
<h1 class="cover-title">Sesión 2<br>Docker Compose: varios servicios que se hablan</h1>
<div class="cover-sub">Apuntes de apoyo · Máster en Data Engineering, MLOps &amp; Arquitectura Cloud</div>
<div class="cover-meta">
Contenido de referencia para repaso. Estos apuntes desarrollan por escrito lo que se ve
en las diapositivas y en los vídeos de teoría, y añaden el detalle que en clase se
menciona de pasada.
</div>
</div>

<div class="page-break"></div>

## Dónde estamos

En la sesión 1 aprendiste a levantar **un** contenedor: a construir su imagen, a
persistir sus datos y a publicar su puerto. Hoy tienes que levantar **cinco que se
hablen entre sí**, que es lo que realmente es una aplicación de datos.

**Se da por sabido de la sesión anterior:** imagen es plantilla y contenedor es
instancia; `stop` no borra; los datos van en volúmenes; `-p` es lo que abre el puente.
Todo eso se usa hoy.

**Objetivos de la sesión.** Al terminar deberías ser capaz de:

1. Traducir cualquier `docker run` a un servicio de Compose.
2. Explicar por qué Airflow se conecta a `postgres` y no a `localhost`.
3. Montar tu código con *bind mount* y editarlo sin reconstruir nada.
4. Separar Airflow en sus componentes reales y saber cuál mirar cuando falla.
5. Hacer que el arranque sea fiable con `healthcheck` y `depends_on`.

---

## 1. De `docker run` a Docker Compose

### 1.1 El problema que resuelve

Una aplicación real de datos nunca es un contenedor: es Airflow **más** una base de
datos, **más** un procesador de DAGs, **más** un servidor de API. Cinco o seis procesos
que tienen que arrancar en orden, compartir red y conocerse entre sí.

Podrías hacerlo con seis `docker run` escritos a mano, cada uno con sus quince flags. Y
funcionaría… hasta que cierras el portátil y al día siguiente no te acuerdas de los
flags. O hasta que se lo pasas a un compañero y descubres que los flags que a ti te
funcionaban no eran exactamente los que le diste.

<figure>
<img src="img/s84.png" alt="Antes y después de Docker Compose">
<figcaption><strong>Figura 2.1.</strong> A la izquierda, dos <code>docker run</code> que
hay que recordar en orden y con todos sus flags. A la derecha, lo mismo — y el archivo
está en Git, revisado en un <em>pull request</em>, idéntico para todo el
equipo.</figcaption>
</figure>

!!! definicion "Docker Compose"
    Una herramienta que describe **todos los servicios de una aplicación en un único
    archivo declarativo**, `docker-compose.yml`, y los gestiona como un conjunto. Ese
    archivo se versiona en Git junto al código.

### 1.2 Cada `service:` es un `docker run` traducido

Esto es lo que desactiva la sensación de "empezamos de cero otra vez": **no hay ni un
concepto nuevo**. Es la misma información, mejor guardada.

<figure>
<img src="img/s85.png" alt="Correspondencia entre docker run y un servicio de Compose">
<figcaption><strong>Figura 2.2.</strong> La correspondencia es casi literal:
<code>-p</code> pasa a <code>ports:</code>, <code>-v</code> a <code>volumes:</code>,
<code>-e</code> a <code>environment:</code> y <code>--name</code> al nombre del
servicio.</figcaption>
</figure>

| En `docker run` | En `docker-compose.yml` |
|---|---|
| `imagen:tag` | `image:` |
| `--name postgres` | El nombre del servicio (`postgres:`) |
| `-e VAR=valor` | `environment:` |
| `-v origen:destino` | `volumes:` |
| `-p host:cont` | `ports:` |
| `--restart unless-stopped` | `restart: unless-stopped` |
| `--network red` | *(automático: Compose crea la red)* |
| El comando final | `command:` |

!!! practica "Lo que ya no tienes que hacer"
    Fíjate en lo que **desaparece**: ni `--name` por contenedor, ni `-d` por servicio,
    ni `docker network create`, ni crear el volumen a mano. Compose lo deduce todo.

### 1.3 Un `docker-compose.yml` mínimo, comentado

```yaml
services:                                  # cada bloque aquí es un contenedor
  postgres:
    image: postgres:18-alpine              # tag fijado, nunca latest
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - pgdata:/var/lib/postgresql         # volumen con nombre: datos

  airflow:
    image: apache/airflow:3.3.1-python3.14
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
    command: standalone                    # sobrescribe el CMD de la imagen
    ports:
      - "8088:8080"                        # solo publicamos lo que se ve desde fuera
    depends_on:
      - postgres

volumes:
  pgdata:                                  # declaración obligatoria del volumen
```

!!! aviso "Los dos puntos no son decorativos"
    `pgdata` sin `:` al final no es una declaración de volumen válida — YAML no sabe qué
    hacer con una palabra suelta y falla el parseo. La indentación y los `:` **son** la
    estructura del archivo, no adorno.

!!! aviso "`standalone` es solo para pruebas"
    `command: standalone` arranca **todos los componentes de Airflow a la vez dentro del
    mismo contenedor** y crea un usuario admin con contraseña aleatoria. Es cómodo para
    probar en cinco minutos, pero **no es la arquitectura real** — eso se ve en el
    apartado 4. Si mañana ves `standalone` en un proyecto de verdad, es una señal de
    alarma.

### 1.4 Los seis comandos de Compose

```bash
docker compose up -d               # crea y arranca todo, en segundo plano
docker compose ps                  # estado de los servicios del proyecto
docker compose logs -f <servicio>  # sigue los logs de uno concreto
docker compose down                # para y borra contenedores (NO los volúmenes)
docker compose down -v             # además borra los volúmenes con nombre
docker compose config              # valida el YAML y lo muestra ya "resuelto"
```

Y otros que usarás a diario:

```bash
docker compose up -d --build              # reconstruyendo tus imágenes propias
docker compose up -d --force-recreate X   # recrear un servicio concreto
docker compose restart <servicio>         # reiniciar solo uno
docker compose exec <servicio> bash       # shell dentro de un servicio
docker compose stop                       # pausa temporal, sin borrar nada
```

!!! practica "`docker compose config` es la herramienta más infravalorada"
    Te enseña el YAML **final**, con las variables sustituidas y las anclas expandidas,
    **sin arrancar nada**. Si tienes un error de indentación o una variable que no se
    resuelve, sale aquí. Úsalo **antes** de depurar a ciegas.

> Nota: las versiones modernas de Compose ya no requieren (ni recomiendan) la clave
> `version:` al principio del archivo.

---

## 2. Redes y DNS interno

*"No me conecta con la base de datos"* es el problema número uno al montar un stack. La
causa casi siempre está aquí.

### 2.1 Compose crea una red privada y un DNS

<figure>
<img src="img/s89.png" alt="Red privada y DNS interno de Compose">
<figcaption><strong>Figura 2.3.</strong> Al hacer <code>up</code>, Compose crea una red
privada para el proyecto y registra cada servicio en un DNS interno. Solo el puerto
publicado sale al exterior.</figcaption>
</figure>

!!! definicion "El DNS interno de Compose"
    Al ejecutar `docker compose up`, Compose crea automáticamente una **red privada**
    para tu proyecto y conecta todos los servicios a ella. Dentro de esa red, **cada
    servicio es alcanzable por los demás usando su nombre de servicio como si fuera un
    nombre de dominio**.

No hay que configurar nada: ni `networks:`, ni IPs, ni ficheros `hosts`.

### 2.2 La línea que hay que entender

<figure>
<img src="img/s90.png" alt="La cadena de conexión con el nombre del servicio">
<figcaption><strong>Figura 2.4.</strong> Donde iría una IP, va el nombre del servicio.
Y dentro del contenedor de Airflow, <code>localhost</code> es el propio
Airflow.</figcaption>
</figure>

```
postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
                                      └── nombre del SERVICIO,
                                          resuelto por el DNS interno
```

Esto es exactamente lo que hace la variable `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` de
nuestro proyecto.

!!! error "Por qué `@localhost:5432` da «connection refused»"
    Dentro del contenedor de Airflow, **`localhost` es el propio Airflow**. No hay
    ninguna base de datos escuchando ahí dentro. Cada contenedor tiene su propio
    `localhost`, y no es el tuyo ni el de su vecino.

!!! practica "La regla que vale para toda tu carrera"
    **Nunca escribas una IP en una cadena de conexión.** Los contenedores cambian de IP
    cada vez que se recrean; los nombres, no. Esta misma regla reaparece literalmente en
    la sesión 3 con los *Services* de Kubernetes.

**Cómo comprobarlo tú mismo:**

```bash
docker compose exec airflow \
  python -c "import socket; print(socket.gethostbyname('postgres'))"
# Debe devolver una IP 172.x.x.x
```

### 2.3 Cuándo hace falta `ports:` y cuándo no

Solo publicas lo que quieras alcanzar **desde fuera del proyecto Compose**.

| Comunicación | ¿Necesita `ports:`? | Por qué |
|---|---|---|
| Airflow → Postgres | **No** | Ambos están en la red de Compose; basta el nombre |
| Tu navegador → UI de Airflow | **Sí** | Tu host está fuera de esa red |
| Tu DBeaver → Postgres | **Sí** | Igual: vienes de fuera |
| Scheduler → API server | **No** | Misma red interna |

!!! aviso "Publicar «por si acaso» es un problema de seguridad"
    Publicar el 5432 sin necesitarlo expone tu base de datos a toda la red wifi. En el
    proyecto real publicamos **solo** el 8080, y además atado a `127.0.0.1`. Cuando en
    una revisión de código veas un `ports:` en una base de datos, pregunta por qué está
    ahí: nueve de cada diez veces es un resto de cuando alguien depuraba.

!!! error "El puerto derecho no te lo inventas"
    En `ports: "8088:8000"`, el `8000` tiene que ser el puerto donde **realmente**
    escucha el proceso dentro del contenedor. Si la imagen escucha en el 8080, no
    responderá nada. Compruébalo con:

    ```bash
    docker compose ps                                        # columna PORTS
    docker inspect --format='{{.Config.ExposedPorts}}' <cont>
    ```

### 2.4 Experimento recomendado: rompe la conexión a propósito

Cambia `@postgres:5432` por `@localhost:5432` en el YAML, recrea solo ese servicio y lee
el error:

```bash
docker compose up -d --force-recreate airflow
docker compose logs airflow | tail -20
```

Verás `connection refused` o `could not translate host name`. Es literalmente el error
que más veces verás en tu carrera con stacks de datos: **conviene aprender a
reconocerlo ahora, no en producción**. Después, déjalo como estaba.

---

## 3. Volúmenes en Compose

Son los mismos dos mecanismos de la sesión 1, ahora declarados en el archivo.

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

!!! practica "Cómo distinguirlos de un vistazo"
    Mira la **primera parte** del valor: si empieza por `.` o por `/`, es una ruta del
    host y por tanto un **bind mount**. Si es un identificador suelto, es un **volumen
    con nombre** y hay que declararlo abajo, en la sección `volumes:` de nivel superior.

### 3.1 `down` y `down -v` no son lo mismo

Esta es la trampa favorita de cualquier examen de Docker.

| Comando | Borra contenedores | Borra volúmenes | Cuándo usarlo |
|---|---|---|---|
| `docker compose stop` | No | No | Pausa temporal |
| `docker compose down` | Sí | **No** | Uso normal a diario |
| `docker compose down -v` | Sí | **Sí** | Empezar de cero **a propósito** |

Es la diferencia entre reiniciar el servidor y prenderle fuego.

!!! aviso "El caso real de este proyecto"
    `down -v` fue **necesario** cuando un volumen creado con Postgres 15 no arrancaba
    con la imagen `postgres:18-alpine`. Pero ese mismo comando, en producción, es un
    incidente. Nunca lo ejecutes por inercia un viernes por la tarde.

---

## 4. El stack real de Airflow 3

`standalone` es un atajo de desarrollo. **Cualquier Airflow real tiene los componentes
separados**, cada uno en su propio contenedor.

### 4.1 Cuatro procesos, la misma imagen, distinto `command:`

<figure>
<img src="img/s99.png" alt="Los cuatro componentes de Airflow 3">
<figcaption><strong>Figura 2.5.</strong> La tabla que hay que saberse: qué hace cada
componente y, sobre todo, dónde mirar cuando algo falla.</figcaption>
</figure>

| Componente | `command:` | Qué hace | ¿Dónde miro si…? |
|---|---|---|---|
| **API Server** | `api-server` | Web UI y API REST | …no carga la web |
| **Scheduler** | `scheduler` | Decide qué tarea toca y la ejecuta | …la tarea no arranca |
| **DAG Processor** | `dag-processor` | Parsea los `.py` de `dags/` | **…mi DAG no aparece** |
| **Triggerer** | `triggerer` | Tareas diferibles (*deferrable*) | …uso sensores asíncronos |

Los cuatro usan **exactamente la misma imagen**. Lo único que los distingue es el
`command:`, que sobrescribe el `CMD` — justo el concepto del apartado 6.4 de la sesión 1.

!!! aviso "El DAG Processor separado es obligatorio desde Airflow 3"
    En Airflow 2 iba dentro del scheduler. Si lo olvidas, **tus DAGs no aparecen nunca y
    no hay ningún error que te lo diga**. Los cuatro procesos fallan en silencio y por
    separado: por eso importa saber cuál hace qué.

**Experimento muy recomendable:** para el DAG Processor, añade un DAG nuevo, espera un
minuto y comprueba que no aparece en la UI — sin ningún error visible. Luego arráncalo
otra vez y observa cómo aparece.

```bash
docker compose stop airflow-dag-processor
# ... añade un DAG y espera. No aparece, y no hay error.
docker compose start airflow-dag-processor
# ... ahora sí
```

Acabas de aprender a diagnosticar *"mi DAG no aparece"* sin buscar en Stack Overflow.

### 4.2 Y un quinto contenedor, de un solo uso

```yaml
  airflow-init:
    image: apache/airflow:3.3.1-python3.14
    entrypoint: ["/bin/bash", "-c"]
    command: ["airflow db migrate"]
    restart: "no"        # es de un solo uso: NO debe reiniciarse
```

`airflow-init` crea las tablas de la base de datos y **termina**. Y no está roto:
acuérdate de la sesión 1, un contenedor que termina ha hecho su trabajo.

!!! error "El `restart: no` entrecomillado no es un descuido"
    Si le pusieras `unless-stopped`, Docker relanzaría la migración **en bucle** cada
    vez que termina correctamente. Los contenedores de tarea única llevan `no`.

    Guarda esta idea: en Kubernetes tiene nombre propio y se llama **Job**.

---

## 5. Arranque robusto

Sin healthchecks, tu stack arranca bien o mal según qué contenedor gane la carrera. Eso
no es aceptable.

### 5.1 `depends_on` a secas no espera lo que crees

<figure>
<img src="img/s104.png" alt="El problema de depends_on sin condición">
<figcaption><strong>Figura 2.6.</strong> <code>depends_on</code> por defecto espera a
que el contenedor <em>exista</em>, no a que esté <em>listo</em>. Es una carrera. Y las
carreras se ganan casi siempre… hasta el día de la demo.</figcaption>
</figure>

Compose arranca `airflow-init` en cuanto el contenedor de Postgres **existe**. Pero
Postgres tarda unos segundos en aceptar conexiones. Resultado:

```
CRITICAL: [postgres] connection refused
airflow-init exited with code 1
```

Y lo peor es que **a veces funciona**. Es un fallo intermitente, que es la peor clase de
fallo: el que no puedes reproducir cuando quieres.

### 5.2 La solución son dos piezas que encajan

<figure>
<img src="img/s105.png" alt="Healthcheck más condición de depends_on">
<figcaption><strong>Figura 2.7.</strong> Un healthcheck define qué significa "listo";
una condición en <code>depends_on</code> lo espera. Una sin la otra no sirve de
nada.</figcaption>
</figure>

**Pieza 1 — definir qué es "listo"** (en el servicio del que dependes):

```yaml
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U airflow -d airflow"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
```

**Pieza 2 — esperar a esa condición** (en el servicio que depende):

```yaml
  airflow-init:
    depends_on:
      postgres:
        condition: service_healthy

  airflow-scheduler:
    depends_on:
      airflow-init:
        condition: service_completed_successfully
```

!!! aviso "Una sin la otra no funciona"
    Si pones la condición pero el servicio no tiene `healthcheck`, Compose no tiene nada
    que consultar. Van siempre en pareja.

### 5.3 Las tres condiciones de `depends_on`

| Condición | Espera a que… | Uso típico |
|---|---|---|
| `service_started` | El contenedor exista (**por defecto**) | Casi nunca es lo que quieres |
| `service_healthy` | El healthcheck pase | Bases de datos, colas, APIs |
| `service_completed_successfully` | El contenedor termine con código 0 | Migraciones, `airflow-init` |

!!! practica "Recuérdalo para la sesión 3"
    En Kubernetes, `service_healthy` se llama **readiness probe**. El concepto es
    idéntico; cambian el nombre y el sitio donde se declara. Lo que **no** existe en
    Kubernetes es `depends_on` — y es a propósito.

---

## 6. Configuración limpia: `.env` y anclas YAML

Dos mejoras de higiene que separan un YAML de juguete de uno profesional.

### 6.1 El archivo `.env`

Todo lo que cambia **por persona o por entorno** no va en el archivo versionado.

```env
# sandbox/.env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
AIRFLOW_PORT=8088
POSTGRES_PASSWORD=airflow
```

```yaml
image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:3.3.1-python3.14}
ports:
  - "${AIRFLOW_PORT:-8088}:8080"
```

!!! definicion "La sintaxis `${VAR:-valor}`"
    Significa *"usa `VAR`, y si no existe, este valor por defecto"*. Así el proyecto
    funciona aunque alguien no tenga `.env`, pero cada persona puede cambiar su puerto
    sin tocar el YAML compartido.

Compose lee el `.env` de la misma carpeta **automáticamente**, sin declarar nada.

!!! aviso "El `.env` no se sube a Git"
    Por eso el YAML **sí** puede subirse sin exponer credenciales. Ponlo en el
    `.gitignore` el mismo día que creas el proyecto — y también en el `.dockerignore`,
    por el motivo que vimos en la sesión 1.

### 6.2 Anclas YAML

<figure>
<img src="img/s108.png" alt="Anclas YAML">
<figcaption><strong>Figura 2.8.</strong> Se define una plantilla con
<code>&amp;nombre</code> y se "pega" en cada servicio con
<code>&lt;&lt;: *nombre</code>.</figcaption>
</figure>

!!! definicion "Anclas y merge keys"
    **No son de Compose: son del propio formato YAML.** Defines un bloque reutilizable
    con `&ancla` y lo insertas donde quieras con `<<: *ancla`. El prefijo `x-` en la
    clave le dice a Compose "esto es una plantilla, ignórame como servicio".

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

Así los cuatro servicios de Airflow comparten imagen, variables y volúmenes sin
repetirlos cuatro veces. Y cuando haya que cambiar la cadena de conexión, se cambia en
**un** sitio — exactamente el mismo motivo por el que no copias y pegas código.

---

## 7. El `docker-compose.yml` real, comentado

Este es el momento en el que todo encaja. El archivo del proyecto intimida a primera
vista —unas cien líneas y cinco servicios— pero **no hay ni una línea que no hayas
visto ya**.

<figure>
<img src="img/s112.png" alt="Mapa de conceptos en el docker-compose.yml real">
<figcaption><strong>Figura 2.9.</strong> Cada concepto de las dos sesiones tiene una
línea concreta donde vive.</figcaption>
</figure>

| Concepto | Dónde aparece en el proyecto | Visto en |
|---|---|---|
| Imagen con versión fijada | `postgres:18-alpine`, `apache/airflow:3.3.1-python3.14` | S1 §5.4 |
| `CMD` sobrescrito | `command: scheduler`, `command: api-server`, … | S1 §6.4 |
| Healthcheck y política de reinicio | `healthcheck:` por servicio, `restart: unless-stopped` | S1 §7 |
| Bind mount para desarrollo | `./dags`, `./logs`, `./plugins` | S1 §4.1 |
| Volumen con nombre | `postgres_data` | S1 §4.1 |
| Red y DNS de Compose | Airflow se conecta a `postgres` | S2 §2 |
| `depends_on` con condiciones | `airflow-init` antes que el resto | S2 §5 |
| `.env` y anclas YAML | `x-airflow-common: &airflow-common` | S2 §6 |
| Publicación de puertos | `127.0.0.1:${AIRFLOW_PORT:-8080}:8080` | S1 §4.2 |

### 7.1 Recorrido por bloques

**La plantilla (`x-airflow-common`).** No es un servicio: es un ancla YAML con lo que
comparten los cinco componentes de Airflow — imagen, variables de entorno, bind mounts y
el `depends_on` de Postgres.

**`environment`.** La cadena de conexión usa `postgres` como *hostname* y
`${VAR:-defecto}` para las credenciales. Dos conceptos distintos chocando en la misma
línea.

**`user: "${AIRFLOW_UID:-50000}:0"`.** Un ajuste de permisos de Linux para que los
ficheros que Airflow escribe en `./logs` no acaben siendo propiedad de `root` en tu
host. Está fuera del alcance de esta sesión; el detalle está en `REQUISITOS.md`.

**`postgres`.** Tag fijado, credenciales por variable, volumen con nombre en
`/var/lib/postgresql` (**sin `/data` al final**, que en Postgres 18 cambió), healthcheck
con `pg_isready` y `restart: unless-stopped`.

**`airflow-init`.** El contenedor de un solo uso, con `restart: "no"`.

**`airflow-api-server`.** El único que publica puerto, y atado a `127.0.0.1`. Su
healthcheck ya no es `pg_isready`: es un `curl` contra su propio endpoint de salud,
porque cada tipo de servicio se comprueba a su manera. Y su `depends_on` **mezcla** la
plantilla común con una condición extra propia
(`airflow-init: service_completed_successfully`).

**`scheduler`, `dag-processor`, `triggerer`.** La misma receta, cambiando el `command:`
y el healthcheck a su tipo de *job*. Ninguno publica puertos: no necesitan que nadie
desde fuera hable con ellos.

**No hay sección `networks:`** en todo el archivo, y no hace falta: Compose la crea sola.

### 7.2 Nada de esto era de Airflow

Hoy has usado Airflow como excusa. El patrón es **idéntico** en cualquier stack de datos:

| Stack | Servicios que levantas | La pieza que te va a doler |
|---|---|---|
| **Airflow** | api-server, scheduler, dag-processor, Postgres | El DNS interno y el orden de arranque |
| **Kafka** | broker, controlador (KRaft), una UI | Los *listeners*: dentro y fuera de la red |
| **Spark** | master y uno o varios workers | Los puertos del driver y la memoria |
| **dbt** | dbt más el warehouse de destino | El `profiles.yml`, montado como bind mount |

Cambian los nombres de los servicios y las variables de entorno. **No cambia nada más**:
sigue siendo un `services:`, una red implícita, unos volúmenes y un `depends_on` con
condiciones.

---

## 8. Resumen de la sesión

1. **Compose son los mismos conceptos, en un archivo versionable.** `-p` → `ports:`,
   `-v` → `volumes:`, `-e` → `environment:`.
2. **El nombre del servicio ES el hostname.** Nunca uses IPs en una cadena de conexión.
3. **Solo se publica al host lo que necesitas alcanzar desde fuera.** Lo no publicado no
   es atacable.
4. **`down` conserva los volúmenes; `down -v` los borra.**
5. **`depends_on` sin `condition:` no espera a que esté listo.** Healthcheck +
   condición, siempre en pareja.
6. **Un stack de producción no es Docker avanzado**: es Docker básico bien combinado.

### 8.1 Chuleta de Compose

```bash
docker compose up -d                      # levantar el stack
docker compose up -d --build              # ídem, reconstruyendo imágenes propias
docker compose up -d --force-recreate X   # recrear un servicio concreto
docker compose ps                         # estado y salud de los servicios
docker compose logs -f <servicio>         # logs de uno concreto
docker compose exec <servicio> bash       # shell dentro de un servicio
docker compose restart <servicio>         # reiniciar solo uno
docker compose stop                       # pausa (no borra)
docker compose down                       # parar y borrar contenedores (datos OK)
docker compose down -v                    # ⚠️ además borra los volúmenes
docker compose config                     # validar y ver el YAML final resuelto
```

### 8.2 Cuando algo falla

| Síntoma | Causa habitual | Qué hacer |
|---|---|---|
| `Exited (1)` en `compose ps` | El proceso murió al arrancar | `docker compose logs <servicio>`, lee las **últimas** líneas |
| Se queda en `starting` para siempre | El healthcheck nunca pasa | Ejecuta el comando del healthcheck a mano con `compose exec` |
| `could not translate host name "postgres"` | Usas `localhost` o el servicio no está en el mismo Compose | Usa el nombre del servicio (§2) |
| `connection refused` a la base de datos | Arrancó antes de que Postgres estuviera listo | `depends_on` + `condition: service_healthy` (§5) |
| `port is already allocated` | Otro proceso ocupa el puerto | Cambia el puerto del host o para lo que lo ocupe |
| No responde en el navegador | El puerto derecho de `ports:` no coincide con el real | `docker compose ps`, columna PORTS |
| Los datos desaparecen al reiniciar | No hay volumen, o hiciste `down -v` | Declara un volumen con nombre (§3) |
| El DAG nuevo no aparece | DAG Processor parado, o bind mount mal apuntado | `compose logs airflow-dag-processor` (§4.1) |
| Variables sin sustituir en `config` | El `.env` no está en la carpeta desde la que ejecutas | Muévelo junto al `docker-compose.yml` |
| "No entiendo qué pasa" | — | `docker compose down -v && docker compose up -d` |

> **El comando que resuelve más dudas**: `docker compose logs -f`. Antes de preguntar,
> léelo. La respuesta suele estar literalmente escrita ahí.

### 8.3 Autoevaluación

1. Tu compañero clona el repositorio y hace `docker compose up -d`. ¿Qué necesita tener
   instalado? ¿Cambia algo si él usa Windows y tú Mac?
2. Un DAG falla con `ModuleNotFoundError: No module named 'requests'`. ¿Cuál es el
   arreglo correcto y cuál es el atajo que no debes usar?
3. Haces `down -v` en producción por error. ¿Qué has perdido? ¿Y con `down` a secas?
4. ¿Por qué Airflow se conecta a `postgres` y tú, desde el navegador, a
   `localhost:8080`?
5. Tu DAG nuevo no aparece. Enumera **tres** cosas que comprobarías, en orden.
6. ¿Por qué `airflow-init` lleva `restart: "no"` y los demás no?
7. Las anclas son YAML puro, no Compose. ¿Qué ventaja real tienen sobre copiar y pegar?

---

## 9. Qué viene en la sesión 3

Compose orquesta contenedores **en una máquina**. Kubernetes lo hace en muchas — y
cambia las reglas:

- Por qué Compose no basta en producción.
- Pod, Deployment y Service.
- ConfigMaps, Secrets y volúmenes persistentes.
- Job y CronJob: el equivalente a un DAG programado.

**Antes de la sesión 3**, limpia el entorno. Minikube va a pedir 4 GB de RAM, y si dejas
cinco contenedores de Airflow corriendo, tu portátil se va a quejar:

```bash
cd ejercicios/sandbox
docker compose down -v
docker system df
docker system prune
```
