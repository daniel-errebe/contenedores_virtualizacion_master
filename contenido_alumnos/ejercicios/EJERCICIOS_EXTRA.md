# Ejercicios extra — ampliación

Batería adicional para cuando sobra tiempo en clase, para trabajo en casa o
para una segunda sesión. **Ninguno es necesario** para seguir el hilo de
[EJERCICIOS.md](./EJERCICIOS.md).

Están ordenados por utilidad práctica para un Data Engineer, no por
dificultad. Elige a la carta.

| # | Ejercicio | Tiempo | Para qué sirve |
|---|---|---|---|
| A | Ver la base de datos con Adminer | 15 min | Añadir servicios auxiliares al stack |
| B | Un DAG que escribe en Postgres | 30 min | El caso de uso real de Airflow |
| C | Mini-pipeline CSV → pandas → Postgres | 40 min | Ingesta de datos de principio a fin |
| D | Perder datos a propósito: `down` vs `down -v` | 10 min | Evitar el desastre en producción |
| E | Depuración a ciegas | 25 min | Diagnosticar stacks rotos |
| F | Espacio en disco y capas de imagen | 15 min | Que no se te llene el portátil |
| G | Configuración por variables de entorno | 20 min | Un stack, varios entornos |
| H | `CMD` vs `ENTRYPOINT` | 15 min | Entender imágenes ajenas |
| I | Políticas de reinicio | 15 min | Resiliencia de servicios |

Todos parten del `sandbox/` que construiste en los ejercicios 6–10.

---

## A — Ver la base de datos con Adminer (15 min)

**Por qué te importa**: en cualquier stack de datos acabarás añadiendo
servicios auxiliares (una UI de base de datos, MinIO, un Jupyter, Redis).
El patrón es siempre el mismo.

### Tarea

Añade **Adminer** (cliente web de bases de datos, imagen ligerísima) al
`sandbox/docker-compose.yml` y úsalo para ver las tablas internas de
Airflow.

<details>
<summary>Ver solución</summary>

```yaml
  adminer:
    image: adminer:5
    ports:
      - "8090:8080"
    depends_on:
      postgres:
        condition: service_healthy
```

```bash
docker compose up -d adminer
```

Abre <http://localhost:8090> y entra con:

| Campo | Valor |
|---|---|
| Motor | PostgreSQL |
| Servidor | `postgres` ← **el nombre del servicio**, no localhost |
| Usuario | `airflow` |
| Contraseña | `airflow` |
| Base de datos | `airflow` |

</details>

### Validación

Ves las tablas de Airflow (`dag`, `dag_run`, `task_instance`...). Lanza un
DAG y consulta `SELECT * FROM dag_run ORDER BY id DESC LIMIT 5;`.

### Para pensar

- ¿Por qué en "Servidor" pones `postgres` y no `localhost`, si tú estás
  entrando desde tu navegador? (Pista: ¿quién hace la conexión a la base de
  datos, tu navegador o el contenedor de Adminer?)
- Adminer no lleva volumen. ¿Está bien? ¿Por qué?

---

## B — Un DAG que escribe en Postgres (30 min)

**Por qué te importa**: hasta ahora tus DAGs solo imprimían texto. Este es
el trabajo real: mover datos entre sistemas.

### Tarea

1. Añade el proveedor de Postgres a tu imagen de Airflow (recuerda el
   ejercicio 5).
2. Define una conexión de Airflow por variable de entorno.
3. Escribe un DAG que cree una tabla e inserte una fila con la fecha de
   ejecución.

<details>
<summary>Ver solución</summary>

`sandbox/Dockerfile`:

```dockerfile
FROM apache/airflow:3.3.1-python3.14
RUN pip install --no-cache-dir apache-airflow-providers-postgres
```

En el ancla común del `docker-compose.yml`, sustituye `image:` por `build:`
y añade la conexión:

```yaml
x-airflow-common: &airflow-common
  build: .                    # <- construye desde el Dockerfile local
  environment:
    # ... lo que ya tenías ...
    # Airflow lee conexiones desde variables AIRFLOW_CONN_<ID EN MAYÚSCULAS>
    AIRFLOW_CONN_MI_POSTGRES: postgresql://airflow:airflow@postgres:5432/airflow
```

`sandbox/dags/escribe_en_postgres.py`:

```python
from datetime import datetime

from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.sdk import DAG

with DAG(
    dag_id="escribe_en_postgres",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["extra"],
) as dag:
    crear = PostgresOperator(
        task_id="crear_tabla",
        postgres_conn_id="mi_postgres",
        sql="""
            CREATE TABLE IF NOT EXISTS ejecuciones (
                id SERIAL PRIMARY KEY,
                dag_id TEXT,
                momento TIMESTAMP
            );
        """,
    )

    insertar = PostgresOperator(
        task_id="insertar_fila",
        postgres_conn_id="mi_postgres",
        sql="INSERT INTO ejecuciones (dag_id, momento) VALUES ('{{ dag.dag_id }}', NOW());",
    )

    crear >> insertar
```

```bash
docker compose up -d --build     # --build porque ahora construimos imagen propia
```

</details>

### Validación

Lanza el DAG y comprueba la tabla desde Adminer (ejercicio A) o con:

```bash
docker compose exec postgres psql -U airflow -d airflow -c "SELECT * FROM ejecuciones;"
```

### Para pensar

- Sin `--build`, Compose reutiliza la imagen anterior. ¿Qué pasaría?
- Estamos usando la **misma base de datos** que los metadatos de Airflow.
  ¿Es buena idea en un proyecto real? ¿Qué harías en su lugar?

---

## C — Mini-pipeline: CSV → pandas → Postgres (40 min)

**Por qué te importa**: es el "hola mundo" de la ingeniería de datos, y
junta todo lo de la clase: imagen propia, bind mount, red y persistencia.

### Tarea

1. Deja un CSV en `sandbox/data/ventas.csv` y monta esa carpeta.
2. Añade `pandas` y `sqlalchemy` a tu imagen.
3. Escribe un DAG con `@task` que lea el CSV, calcule un agregado y lo
   escriba en Postgres.

<details>
<summary>Ver solución</summary>

`sandbox/data/ventas.csv`:

```csv
fecha,producto,importe
2024-01-01,A,100
2024-01-01,B,250
2024-01-02,A,175
```

`sandbox/requirements.txt`:

```
apache-airflow-providers-postgres
pandas==2.2.3
```

`sandbox/Dockerfile`:

```dockerfile
FROM apache/airflow:3.3.1-python3.14
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

Monta la carpeta de datos en el ancla común:

```yaml
  volumes:
    - ./dags:/opt/airflow/dags
    - ./data:/opt/airflow/data
```

`sandbox/dags/pipeline_ventas.py`:

```python
from datetime import datetime

from airflow.sdk import DAG, task

with DAG(
    dag_id="pipeline_ventas",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["extra"],
) as dag:

    @task
    def cargar_ventas():
        import pandas as pd
        from sqlalchemy import create_engine

        df = pd.read_csv("/opt/airflow/data/ventas.csv")
        resumen = df.groupby("producto", as_index=False)["importe"].sum()

        engine = create_engine(
            "postgresql+psycopg2://airflow:airflow@postgres:5432/airflow"
        )
        resumen.to_sql("resumen_ventas", engine, if_exists="replace", index=False)
        return len(resumen)

    cargar_ventas()
```

```bash
docker compose up -d --build
```

</details>

### Validación

```bash
docker compose exec postgres psql -U airflow -d airflow -c "SELECT * FROM resumen_ventas;"
```

### Extensión

Edita el CSV **desde tu editor** (sin tocar Docker) y vuelve a lanzar el
DAG. Los resultados cambian: eso es el bind mount trabajando para ti.

---

## D — Perder datos a propósito (10 min)

**Por qué te importa**: es el error que más caro sale. Mejor cometerlo hoy,
en clase.

### Tarea

1. Crea datos en Postgres (una tabla con filas).
2. Ejecuta `docker compose down` y vuelve a levantar. ¿Siguen los datos?
3. Ejecuta `docker compose down -v` y vuelve a levantar. ¿Y ahora?
4. Explica la diferencia con tus palabras.

<details>
<summary>Ver solución</summary>

```bash
docker compose exec postgres psql -U airflow -d airflow \
  -c "CREATE TABLE prueba(x INT); INSERT INTO prueba VALUES (42);"

docker compose down && docker compose up -d
docker compose exec postgres psql -U airflow -d airflow -c "SELECT * FROM prueba;"
# -> 42  (los contenedores se borran, el VOLUMEN no)

docker compose down -v && docker compose up -d
docker compose exec postgres psql -U airflow -d airflow -c "SELECT * FROM prueba;"
# -> ERROR: relation "prueba" does not exist
```

- `down` borra **contenedores y red**. Los volúmenes con nombre sobreviven.
- `down -v` borra **también los volúmenes**. Los datos desaparecen para
  siempre.

</details>

### Para pensar

- Los bind mounts (`./dags`) **nunca** se borran con `-v`. ¿Por qué?
- ¿Cómo harías una copia de seguridad del volumen antes de un `down -v`?

---

## E — Depuración a ciegas (25 min)

**Por qué te importa**: en la vida real nadie te da el error explicado. Te
dan un stack que no arranca.

### Tarea

Crea un `docker-compose.yml` en `sandbox/roto/` con estos **cuatro fallos
introducidos a propósito**, arráncalo y arréglalos uno a uno usando solo
`docker compose ps` y `docker compose logs`.

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: airflow
      POSTGRES_DB: airflow
    volumes:
      - pg:/var/lib/postgresql/data

  airflow:
    image: apache/airflow:3.3.1-python3.14
    command: standalone
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@localhost:5432/airflow
    ports:
      - "8080:8080"

volumes:
  pg:
```

<details>
<summary>Ver los cuatro fallos</summary>

1. **Falta `POSTGRES_PASSWORD`** → Postgres se niega a arrancar.
   *Síntoma*: el contenedor sale con error nada más empezar.
   *Cómo lo ves*: `docker compose logs postgres`.

2. **`@localhost:5432`** debería ser `@postgres:5432` → Airflow no encuentra
   la base de datos.
   *Síntoma*: `connection refused` en bucle.

3. **Ruta de volumen `/var/lib/postgresql/data`** → en PostgreSQL 18 la ruta
   correcta es `/var/lib/postgresql`. No falla, pero **no persiste**.
   *Cómo lo ves*: creas datos, haces `down` + `up` y no están.

4. **Puerto `8080:8080`** → choca con el proyecto real si lo tienes
   levantado.
   *Síntoma*: `Bind for 0.0.0.0:8080 failed: port is already allocated`.
   *Arreglo*: usa `8088:8080`.

</details>

### Validación

El stack arranca, la UI carga y los datos sobreviven a un
`docker compose down && docker compose up -d`.

---

## F — Espacio en disco y capas de imagen (15 min)

**Por qué te importa**: las imágenes de datos son enormes. En tres meses
tendrás 40 GB de Docker sin saber por qué.

### Tarea

```bash
docker system df                 # resumen de lo que ocupa Docker
docker image ls                  # ordena mentalmente por tamaño
docker history apache/airflow:3.3.1-python3.14 | head -20
```

1. ¿Cuánto ocupan tus imágenes? ¿Y los volúmenes?
2. En `docker history`, ¿qué capa es la más grande?
3. Compara `postgres:18` con `postgres:18-alpine`:

```bash
docker pull postgres:18
docker image ls postgres
```

4. Libera espacio:

```bash
docker system df                  # antes
docker system prune               # borra contenedores parados, redes e imágenes sueltas
docker system df                  # después
```

> ⚠️ `docker system prune -a --volumes` borra **todo** lo que no esté en
> uso, volúmenes incluidos. Úsalo solo sabiendo lo que haces.

### Para pensar

- Las variantes `-alpine` pesan mucho menos. ¿Por qué no se usan siempre?
  (Pista: `alpine` usa `musl` en vez de `glibc`, y algunas librerías de
  Python con extensiones compiladas dan problemas.)

---

## G — Configuración por variables de entorno (20 min)

**Por qué te importa**: el mismo `docker-compose.yml` debe servir para tu
portátil, para el entorno de pruebas y para producción. Lo único que cambia
son las variables.

### Tarea

1. Mueve **toda** la configuración variable del `sandbox/` a un `.env`:
   versión de imagen, puerto, usuario, contraseña y nombre de base de datos.
2. Crea un `.env.example` con valores de ejemplo (ese sí se sube a Git).
3. Comprueba con `docker compose config` que se resuelve bien.
4. Cambia `AIRFLOW_PORT` en el `.env` y verifica que la UI cambia de puerto
   sin tocar el YAML.

<details>
<summary>Ver solución</summary>

`sandbox/.env`:

```env
AIRFLOW_IMAGE_NAME=apache/airflow:3.3.1-python3.14
AIRFLOW_PORT=8088
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
```

```yaml
  postgres:
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-airflow}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-airflow}
      POSTGRES_DB: ${POSTGRES_DB:-airflow}
```

```bash
docker compose config | grep -A3 environment   # ver los valores ya resueltos
```

La sintaxis `${VAR:-valor}` significa "usa `VAR`, y si no existe, usa
`valor`". Así el archivo funciona aunque falte el `.env`.

</details>

### Para pensar

- El `.env` está en `.gitignore` y el `.env.example` no. ¿Qué problema
  resuelve esa pareja de archivos?
- Para credenciales reales de producción, ¿bastaría con un `.env`? ¿Qué
  usarías en su lugar?

---

## H — `CMD` vs `ENTRYPOINT` (15 min)

**Por qué te importa**: no vas a escribir muchos `ENTRYPOINT`, pero sí vas a
**leer** imágenes ajenas y necesitas saber por qué a veces tu `command:` se
ignora.

### Tarea

Construye dos imágenes idénticas salvo por la instrucción final:

```dockerfile
# Dockerfile.cmd
FROM alpine:3.21
CMD ["echo", "soy CMD"]
```

```dockerfile
# Dockerfile.entrypoint
FROM alpine:3.21
ENTRYPOINT ["echo", "soy ENTRYPOINT"]
```

```bash
docker build -f Dockerfile.cmd -t demo-cmd .
docker build -f Dockerfile.entrypoint -t demo-entry .

docker run --rm demo-cmd
docker run --rm demo-cmd   echo "adiós"     # ¿qué imprime?
docker run --rm demo-entry
docker run --rm demo-entry "adiós"          # ¿y ahora?
```

<details>
<summary>Ver explicación</summary>

- `CMD` se **sustituye** por lo que pases en `docker run` → imprime `adiós`.
- `ENTRYPOINT` se **mantiene** y lo que pasas se le **añade como argumento**
  → imprime `soy ENTRYPOINT adiós`.

Por eso en nuestro proyecto `command: scheduler` funciona: la imagen de
Airflow tiene un `ENTRYPOINT` que prepara el entorno y ejecuta `airflow` con
el subcomando que le pases.

Y por eso `airflow-init` necesita
`entrypoint: ["/bin/bash", "-c"]` — para saltarse ese entrypoint y ejecutar
un comando de shell arbitrario.

</details>

---

## I — Políticas de reinicio (15 min)

**Por qué te importa**: decide si tu servicio se recupera solo tras un fallo
o se queda caído hasta que alguien lo mire.

### Tarea

1. Arranca un contenedor con `--restart unless-stopped` cuyo proceso muera a
   los pocos segundos.
2. Observa con `docker ps` cómo se reinicia solo (fíjate en la columna
   `STATUS`: verás el contador de *uptime* volver a empezar).
3. Párale tú con `docker stop`. ¿Se reinicia? ¿Por qué no?

<details>
<summary>Ver solución</summary>

```bash
docker run -d --name reinicia --restart unless-stopped alpine:3.21 sh -c "sleep 5; exit 1"

docker ps          # ejecútalo varias veces: el uptime se reinicia una y otra vez
docker inspect -f '{{.RestartCount}}' reinicia   # cuenta de reinicios

docker stop reinicia   # parada explícita
docker ps -a           # se queda Exited; "unless-stopped" respeta tu decisión

docker rm reinicia
```

</details>

### Para pensar

- En nuestro proyecto, `airflow-init` usa `restart: "no"` mientras que los
  demás usan `unless-stopped`. ¿Qué pasaría si `airflow-init` llevara
  `unless-stopped`?
- Un servicio que reinicia en bucle, ¿qué mensaje te está dando realmente?
