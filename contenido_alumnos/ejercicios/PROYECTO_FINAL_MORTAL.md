# El Proyecto Final Mortal

> De `echo "hola mundo"` a un Pod que, por mucho que lo mates, siempre vuelve.

Bienvenido/a al examen final que nadie te ha pedido hacer en un examen. Esto
no es un ejercicio más: es **los tres módulos enteros, en orden, subiendo de
nivel como un videojuego malo de los 2000**, hasta que al final consigas
algo que se parece sospechosamente a un sistema en producción.

La buena noticia: cada nivel es pequeño. La mala noticia: hay dieciséis.

⚠️ Esto **no sustituye** a `EJERCICIOS.md`, `EJERCICIOS_KUBERNETES.md` ni a
las sesiones — es el "modo historia" que atas todo lo que ya sabes en un
único hilo, de principio a fin. Si un concepto no te suena, para y repasa
la teoría enlazada en cada nivel. Aquí no se re-explica nada desde cero,
solo se **usa**.

---

## Las reglas del juego

1. **Todo se hace en una carpeta nueva**, separada de todo lo demás:
   ```bash
   cd contenido_alumnos/ejercicios
   mkdir -p proyecto-final-mortal && cd proyecto-final-mortal
   ```
2. Cada nivel **depende del anterior**. No hay atajos: si te saltas el
   nivel 4, en el nivel 5 vas a sufrir, y va a ser culpa tuya, no nuestra.
3. Cada nivel tiene una sección **Teoría exprés** (el concepto que ataca),
   una **Misión** (qué hacer) y una **Solución** oculta (para cuando ya
   hayas sufrido lo suficiente, no antes).
4. Cuando un nivel diga **"Cómo sabes que has sobrevivido"**, es literal:
   si no ves eso en tu terminal, no pases al siguiente nivel.
5. Al final hay un **jefe final**. Ya sabes cómo funcionan los jefes
   finales: usan todo lo que has aprendido, y un poco más, y si te falta
   una réplica, hay uno que revive.

---

## El proyecto: CaféConDatos S.L.

Trabajas para una startup — inventada, pero créetelo — que ha llenado la
oficina de **cafeteras inteligentes**. Cada cafetera envía, cada vez que
sirve un café, una línea de datos: la hora, cuántos mililitros ha servido
y si alguien ha roto una taza en el proceso (pasa más de lo que crees).

Tu trabajo, en progresión creciente de dolor, es:

1. Leer esos datos.
2. Empaquetarlo para que corra en cualquier sitio.
3. Levantarlo junto a una base de datos real, con Docker Compose.
4. Llevarlo a Kubernetes y conseguir que **no se caiga nunca**, aunque tú
   mismo intentes matarlo.

El dataset es este `cafeteras.csv` (créalo tal cual, cópialo y pégalo):

```csv
hora,cafetera_id,ml_servidos,taza_rota
08:03,cafetera-1,180,false
08:15,cafetera-2,240,false
09:01,cafetera-1,180,true
09:45,cafetera-3,60,false
10:30,cafetera-2,240,false
11:02,cafetera-1,180,false
```

---

## Mapa de niveles

| Acto | Niveles | Ataca | Duración estimada |
|---|---|---|---|
| I — Docker fundamentos | 1 – 6 | contenedores, imágenes, volúmenes, Dockerfile, iteración y limpieza | ~65 min |
| II — Docker Compose | 7 – 10 | multi-servicio, red interna, persistencia, `.env`, `restart` | ~55 min |
| III — Kubernetes | 11 – 16 | Pods, Deployments, self-healing, probes, límites, depuración | ~90 min |

Total: **~3 h 30 min**, hecho con calma, en casa, sin nadie mirándote raro
si hablas solo con la terminal.

---

# ACTO I — Docker fundamentos

## Nivel 1 — El calentamiento: que algo, lo que sea, se ejecute (5 min) ⭐

**Teoría exprés**: un contenedor no es más que un proceso aislado que
arranca, hace su trabajo y (normalmente) muere. Esta es la versión más
tonta posible de eso.

**Misión**: ejecuta un contenedor que imprima un mensaje de bienvenida por
pantalla y luego desaparezca solo, sin dejar rastro en `docker ps -a`.

**Pistas**:
- La imagen más pequeña y rápida de descargar para esto es `alpine`, fijando
  siempre un tag concreto (`3.21`), nunca `latest`.
- El flag que borra el contenedor en cuanto termina empieza por `--r...`.
- Dentro del contenedor, el comando es tan simple como `echo "tu mensaje"`.

<details>
<summary>Solución</summary>

```bash
docker run --rm alpine:3.21 echo "CaféConDatos está en marcha (más o menos)"
```

Si esto no imprime el mensaje, algo va mal con tu instalación de Docker —
vuelve a `REQUISITOS.md` antes de seguir, no tiene sentido subir de nivel
con la base rota.

</details>

**Cómo sabes que has sobrevivido**: ves el mensaje en tu terminal y el
contenedor ya no existe (`docker ps -a` no lo lista: `--rm` lo borra solo).

---

## Nivel 2 — Meter tus datos dentro sin copiarlos (10 min) ⭐⭐

**Teoría exprés**: un bind mount conecta una carpeta de tu máquina con una
carpeta del contenedor. Sin esto, tendrías que reconstruir la imagen cada
vez que cambias una coma del CSV — y nadie tiene tiempo para eso.

**Misión**: sin escribir ni un Dockerfile todavía, cuenta cuántas líneas
tiene tu `cafeteras.csv` **desde dentro de un contenedor**, sin instalar
nada en tu máquina.

**Pistas**:
- Necesitas conectar tu carpeta actual con una carpeta del contenedor: el
  flag es `-v`, con sintaxis `origen:destino`, y **ambas rutas deben ser
  absolutas** (`$(pwd)` te da la tuya).
- El comando de Linux para contar líneas de un fichero es `wc -l`.
- Te sigue valiendo `alpine:3.21`, no necesitas nada más pesado todavía.

<details>
<summary>Solución</summary>

```bash
docker run --rm -v "$(pwd)":/datos alpine:3.21 wc -l /datos/cafeteras.csv
```

Si te devuelve `0` o un error de "No such file", revisa dos cosas: que
estás ejecutando el comando **desde la carpeta donde está el CSV**, y que
la ruta después de `-v` es absoluta (por eso `$(pwd)` y no `.`).

</details>

**Cómo sabes que has sobrevivido**: el número de líneas coincide con lo que
ves si haces `cat cafeteras.csv` tú mismo, fuera del contenedor.

---

## Nivel 3 — Tu primer script de verdad (10 min) ⭐⭐

**Teoría exprés**: de momento solo has usado imágenes de otros. Ahora vas
a escribir el script que hace el trabajo real, para meterlo en una imagen
en el próximo nivel.

**Misión**: escribe `procesar.py`, un script que lea `cafeteras.csv` y
cuente cuántas tazas se han roto en total. Ejecútalo dentro de un
contenedor, sin instalar Python en tu máquina.

**Pistas**:
- El módulo estándar `csv` trae `DictReader`, que te da cada fila como un
  diccionario con las cabeceras como claves.
- La columna `taza_rota` llega como texto, no como booleano: compárala
  contra la cadena `"true"`.
- Para ejecutarlo sin instalar Python en tu máquina, reutiliza el mismo
  bind mount del nivel 2, pero ahora sobre una imagen `python:3.14-alpine`,
  pasándole la ruta del script como argumento.

<details>
<summary>Solución</summary>

`procesar.py`:

```python
import csv

with open("/datos/cafeteras.csv") as f:
    lector = csv.DictReader(f)
    filas = list(lector)

total = len(filas)
rotas = sum(1 for fila in filas if fila["taza_rota"] == "true")

print(f"Cafés servidos: {total}")
print(f"Tazas rotas: {rotas}  (una tragedia cada {total // max(rotas, 1)} cafés)")
```

```bash
docker run --rm -v "$(pwd)":/datos python:3.14-alpine python /datos/procesar.py
```

Si te da `FileNotFoundError`, comprueba que `procesar.py` abre
`/datos/cafeteras.csv` (la ruta **dentro** del contenedor), no una ruta de
tu máquina.

</details>

**Cómo sabes que has sobrevivido**: ves "Cafés servidos: 6" y "Tazas
rotas: 1" en pantalla.

---

## Nivel 4 — Ya no dependes de que tu portátil tenga Python (15 min) ⭐⭐⭐

**Teoría exprés**: aquí está la diferencia real entre un script suelto y
un producto: **la imagen lleva dentro todo lo que necesita para correr**,
incluida la versión exacta de Python. Se acabó el "en mi máquina funciona".

**Misión**: empaqueta `procesar.py` en tu propia imagen, con un
`Dockerfile` y un `.dockerignore`. El CSV **no** va dentro de la imagen —
eso lo aprendiste hace tres sesiones, y sigue siendo verdad.

**Pistas**:
- Usa `python:3.14-alpine` como imagen base (`FROM`), copia solo
  `procesar.py` y define un `CMD` que lo ejecute al arrancar.
- Los nombres de imagen de Docker deben ir **en minúsculas** — nada de
  `CamelCase` en el tag.
- Construye siempre fijando `--platform linux/amd64` de forma explícita
  (sobre todo si estás en Mac con Apple Silicon) y con un tag concreto,
  nunca `latest`.
- Al ejecutar, sigues necesitando el bind mount del CSV: la imagen no lo
  lleva dentro.

<details>
<summary>Solución</summary>

`Dockerfile`:

```dockerfile
FROM python:3.14-alpine
WORKDIR /app
COPY procesar.py .
CMD ["python", "procesar.py"]
```

`.dockerignore`:

```
__pycache__/
*.pyc
.git
```

```bash
docker build --platform linux/amd64 -t cafecondatos:1.0 .
docker run --rm -v "$(pwd)":/datos --platform linux/amd64 cafecondatos:1.0
```

Si `docker build` te falla con "file not found", comprueba que
`procesar.py` está en la misma carpeta que el `Dockerfile`. Si `docker run`
imprime lo mismo que en el nivel 3, ya está: acabas de empaquetar tu
primera imagen, con Python y todo incluido.

</details>

**Cómo sabes que has sobrevivido**: `docker images` lista tu imagen, y
ejecutarla imprime el mismo resultado que en el nivel 3 — pero ahora sin
tener Python instalado en tu máquina.

---

## Nivel 5 — Iterar sin miedo: cambia, reconstruye, cotillea y limpia (15 min) ⭐⭐⭐

**Teoría exprés**: nadie escribe un Dockerfile perfecto a la primera y no
lo vuelve a tocar. El día a día real es: cambias una línea, reconstruyes,
te metes dentro del contenedor a ver qué ha pasado, miras los logs de algo
que ya terminó, y de vez en cuando limpias el desastre de imágenes
sueltas que has ido dejando por el camino.

**Misión**: en cuatro pasos, sin salir de tu imagen del nivel 4:

1. Cambia algo pequeño en el mensaje final que imprime `procesar.py`,
   reconstruye con el **mismo tag** y fíjate en qué capas del build se
   reutilizan de la cache y cuáles no.
2. Arranca un contenedor **en segundo plano** (no efímero esta vez) que
   se quede vivo un rato, y métete dentro de él con una shell interactiva
   para curiosear qué archivos tiene.
3. Sin mirar la terminal en directo, recupera después lo que ese
   contenedor ha ido imprimiendo por pantalla.
4. Comprueba cuántas imágenes y contenedores parados has ido acumulando
   en estos cuatro niveles, y límpialos.

**Pistas**:
- Docker reconstruye una imagen **capa a capa**: si no tocas nada por
  encima de la instrucción que cambiaste en el Dockerfile, todo lo
  anterior sale marcado como ya construido ("cache") en la salida de
  `docker build`.
- Para arrancar en segundo plano sin bloquear tu terminal, el flag es
  `-d`; esta vez no uses `--rm`, quieres que el contenedor siga ahí para
  poder inspeccionarlo.
- Puedes decirle a `docker run` qué comando ejecutar en vez del `CMD` de
  la imagen, poniéndolo al final: algo que lo mantenga vivo un rato (por
  ejemplo, `sleep` con un número de segundos).
- Para entrar a una shell dentro de un contenedor que ya está corriendo,
  el comando es `docker exec -it <contenedor> <shell>` — recuerda que
  Alpine no trae `bash`, pero sí trae algo más simple.
- Para ver la salida acumulada de un contenedor sin estar mirando en
  directo, hay un subcomando de `docker` que se llama justo así, "logs".
- `docker images` te lista lo que tienes construido; el subcomando que
  limpia lo que ya no usas (contenedores parados, imágenes sin etiqueta,
  redes huérfanas) es `docker system ...`.

<details>
<summary>Solución</summary>

```bash
# 1. Cambia algo en procesar.py, por ejemplo:
#    print(f"Tazas rotas: {rotas}  (actualizado)")

docker build --platform linux/amd64 -t cafecondatos:1.0 .
```

En la salida verás algo como `CACHED` junto a `FROM` y `WORKDIR` — esas
capas no cambiaron y Docker no las repite. Solo el `COPY` (y lo que va
después) se reconstruye, porque `procesar.py` sí cambió.

```bash
# 2. Un contenedor vivo, para cotillear dentro
docker run -d --name cafeteras-vivo --platform linux/amd64 cafecondatos:1.0 sleep 300
docker exec -it cafeteras-vivo sh
# dentro de la shell:
#   ls /app
#   cat /app/procesar.py   (para confirmar que lleva tu cambio)
#   exit
```

```bash
# 3. Sus logs, sin haber estado mirando
docker logs cafeteras-vivo
```

```bash
# 4. Limpieza
docker images
docker stop cafeteras-vivo && docker rm cafeteras-vivo
docker system prune
```

Si `docker system prune` te pregunta "¿estás seguro?", contesta que sí sin
miedo: solo borra lo que ya está parado o sin usar, nunca algo en marcha.
Si quieres arrasar también las imágenes que no usa ningún contenedor,
añade `-a` — pero hazlo con cabeza, porque eso incluye imágenes base como
`alpine` o `python` que tendrás que volver a descargar.

</details>

**Cómo sabes que has sobrevivido**: en el build ves capas marcadas como ya
construidas y solo se repite la parte que cambiaste; entras con `exec` al
contenedor vivo y ves tu cambio reflejado dentro; y tras la limpieza,
`docker ps -a` y `docker images` muestran bastante menos basura que antes.

---

## Nivel 6 — Jefe de acto: la imagen que sobrevive a que borres tu carpeta de trabajo (10 min) ⭐⭐⭐⭐

**Teoría exprés**: recapitulación del Acto I entero: capas, contexto de
build, `.dockerignore`, `--platform`. Si este nivel te sale a la primera,
el Acto I está superado de verdad, no solo de nombre.

**Misión**: mueve `cafeteras.csv` a **otra carpeta cualquiera** de tu
sistema (por ejemplo `~/csv-secreto/`), y ejecuta tu imagen apuntando a esa
ruta, sin tocar el Dockerfile ni reconstruir nada.

**Pistas**:
- No necesitas reconstruir la imagen del nivel 4: el bind mount se decide
  al hacer `docker run`, no al hacer `docker build`.
- Solo cambia una cosa respecto al nivel 4: la ruta **de origen** del `-v`.

<details>
<summary>Solución</summary>

```bash
mkdir -p ~/csv-secreto
mv cafeteras.csv ~/csv-secreto/
docker run --rm -v ~/csv-secreto:/datos --platform linux/amd64 cafecondatos:1.0
```

Si esto te sorprende, el motivo es el más repetido de las tres sesiones:
**la imagen no contiene tus datos, solo el código**. El bind mount es lo
que decide, en tiempo de ejecución, de dónde vienen.

</details>

**Cómo sabes que has sobrevivido**: el resultado es idéntico, aunque el
CSV ya no esté donde empezó. Acto I superado. Guarda el CSV donde te
convenga para el resto del proyecto.

---

# ACTO II — Docker Compose

## Nivel 7 — Añade una base de datos de verdad (15 min) ⭐⭐⭐

**Teoría exprés**: hasta ahora `procesar.py` solo imprimía números en
pantalla y los olvidaba al instante, como un pez de tres segundos de
memoria. Toca guardarlos en Postgres.

**Misión**: crea un `docker-compose.yml` con un único servicio de
Postgres, con datos que sobrevivan a un reinicio y un `healthcheck` que
te diga cuándo está realmente lista para aceptar conexiones (no solo
arrancada).

**Pistas**:
- No hace falta publicar ningún puerto: nadie fuera de Compose necesita
  hablar con este Postgres todavía.
- Para que los datos sobrevivan, necesitas un **volumen con nombre**
  (declarado en la sección `volumes:` de nivel superior), no uno anónimo.
- Postgres 18 espera sus datos en `/var/lib/postgresql` (sin `/data` al
  final).
- El comando estándar para comprobar la salud de Postgres desde dentro es
  `pg_isready -U <usuario> -d <base_de_datos>`.

<details>
<summary>Solución</summary>

`docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: cafe
      POSTGRES_PASSWORD: cafe
      POSTGRES_DB: cafeconDatos
    volumes:
      - cafe_data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cafe -d cafeconDatos"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  cafe_data:
```

```bash
docker compose up -d
docker compose ps        # STATUS debe llegar a "healthy"
```

Si se queda en `starting` para siempre, mira los logs:
`docker compose logs postgres`. La causa más habitual: variables mal
escritas o un puerto ocupado por otro Postgres tuyo — el del
proyecto real de `contenido_alumnos/`, por ejemplo. Ese usa `5432` publicado por
Airflow; este de aquí **no publica ningún puerto**, así que no deberían
chocar.

</details>

**Cómo sabes que has sobrevivido**: `docker compose ps` muestra
`postgres` en estado `healthy`.

---

## Nivel 8 — Reescribe `procesar.py` para hablar con Postgres (20 min) ⭐⭐⭐

**Teoría exprés**: en Compose, un servicio se conecta a otro **por
nombre**, no por `localhost` ni por IP. Esto ya lo viste en la sesión 2 —
ahora lo escribes tú.

**Misión**: reescribe `procesar.py` para que guarde los resultados en
Postgres en vez de solo imprimirlos, empaquétalo con su nueva dependencia,
y añádelo como un segundo servicio a tu `docker-compose.yml`.

**Pistas**:
- Conéctate al host `postgres` (el nombre del servicio, no `localhost` ni
  una IP): en Compose, cada servicio resuelve a los demás por nombre.
- Necesitas una librería de Python para hablar con Postgres — la variante
  `-binary` no pide compilador, así que es la que quieres en Alpine.
- Crea la tabla con `CREATE TABLE IF NOT EXISTS` para que el script se
  pueda ejecutar más de una vez sin romperse.
- En `docker-compose.yml`, tu nuevo servicio necesita: `build: .`, el bind
  mount del CSV, y un `depends_on` que espere a que Postgres esté sano de
  verdad (no solo arrancado) — repasa el nivel 7 para el nombre exacto de
  esa condición.

<details>
<summary>Solución</summary>

`procesar.py`:

```python
import csv
import psycopg2

conn = psycopg2.connect(
    host="postgres",
    dbname="cafeconDatos",
    user="cafe",
    password="cafe",
)
cur = conn.cursor()
cur.execute("""
    CREATE TABLE IF NOT EXISTS resumen (
        id SERIAL PRIMARY KEY,
        total_cafes INT,
        tazas_rotas INT
    )
""")

with open("/datos/cafeteras.csv") as f:
    filas = list(csv.DictReader(f))

total = len(filas)
rotas = sum(1 for fila in filas if fila["taza_rota"] == "true")

cur.execute(
    "INSERT INTO resumen (total_cafes, tazas_rotas) VALUES (%s, %s)",
    (total, rotas),
)
conn.commit()
print(f"Guardado en Postgres: {total} cafés, {rotas} tazas rotas")
```

`Dockerfile`:

```dockerfile
FROM python:3.14-alpine
WORKDIR /app
RUN pip install --no-cache-dir psycopg2-binary
COPY procesar.py .
CMD ["python", "procesar.py"]
```

`docker-compose.yml` (añade este servicio junto al `postgres` del nivel 7):

```yaml
  procesador:
    build: .
    volumes:
      - ./cafeteras.csv:/datos/cafeteras.csv
    depends_on:
      postgres:
        condition: service_healthy
```

```bash
docker compose up -d --build procesador
docker compose logs procesador
```

Errores típicos aquí:

- **`could not translate host name "postgres"`**: te falta estar en la
  misma red de Compose. Si ejecutas `procesar.py` con `docker run` suelto
  en vez de `docker compose up`, `postgres` no existe para ti — solo
  existe dentro de la red que Compose crea.
- **`depends_on` sin `condition`**: arranca el procesador antes de que
  Postgres acepte conexiones. Ya viste este aviso en la sesión 2, y aquí
  te vuelve a morder si lo olvidas.
- **`error while creating mount source path '...cafeteras.csv': chown ...:
  permission denied`**: significa que `cafeteras.csv` ya no es un fichero,
  sino un **directorio vacío** (compruébalo con `ls -la`: si ves
  `drwxr-xr-x` en vez de `-rw-r--r--`, ahí está el problema). Esto pasa
  cuando en un nivel anterior montaste esa ruta con `-v` **antes** de que
  el fichero existiera de verdad: Docker Desktop, al no encontrar el
  origen, lo auto-crea como carpeta. Solución: borra la carpeta vacía
  (`rmdir cafeteras.csv`) y vuelve a poner ahí el CSV real.

</details>

**Cómo sabes que has sobrevivido**: los logs de `procesador` dicen
"Guardado en Postgres: 6 cafés, 1 tazas rotas".

---

## Nivel 9 — Credenciales fuera del YAML y que sobreviva a un reinicio del demonio (15 min) ⭐⭐⭐

**Teoría exprés**: escribir usuario y contraseña directamente en
`docker-compose.yml` es exactamente lo que la teoría de la sesión 2 te
dijo que no hicieras: si ese archivo acaba en un repositorio, tus
credenciales van con él. Y un segundo problema, independiente: si
reinicias tu máquina (o Docker Desktop se cae y vuelve), tus servicios
**no** se levantan solos a menos que se lo digas explícitamente.

**Misión**: saca usuario, contraseña y nombre de base de datos de
`docker-compose.yml` a un fichero `.env`, y añade una política de reinicio
a ambos servicios para que sobrevivan a que Docker se reinicie sin que tu
ordenador se apague. De paso, practica el ciclo de iteración normal de
Compose: reiniciar un solo servicio, seguir sus logs en directo, y validar
que el YAML final es el que crees que es.

**Pistas**:
- Compose lee automáticamente un fichero llamado `.env` en la misma
  carpeta que el `docker-compose.yml`, sin que tengas que declarar nada
  extra — solo defines ahí las variables (`CLAVE=valor`, sin comillas) y
  las referencias en el YAML con `${CLAVE}`.
- El `.env` es precisamente el tipo de archivo que va en `.gitignore`, no
  en el repositorio.
- El campo que controla si un contenedor se reinicia solo se llama
  `restart`; el valor que quieres para servicios de larga duración (no
  para Jobs puntuales) es `unless-stopped`.
- Para reiniciar sin recrear ni tocar los demás servicios, hay un
  subcomando de `docker compose` que hace justo eso, con el nombre del
  servicio como argumento.
- Para seguir logs en directo (sin que el comando termine y te devuelva el
  prompt), `docker compose logs` acepta un flag de "seguir", igual que
  `tail -f`.
- Para comprobar que tus variables de `.env` se han sustituido bien en el
  YAML final, sin tener que arrancar nada, existe un subcomando que
  "resuelve" y muestra el resultado.

<details>
<summary>Solución</summary>

`.env`:

```env
POSTGRES_USER=cafe
POSTGRES_PASSWORD=cafe
POSTGRES_DB=cafeconDatos
```

`docker-compose.yml` (fragmento actualizado):

```yaml
services:
  postgres:
    image: postgres:18-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - cafe_data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 5

  procesador:
    build: .
    restart: unless-stopped
    volumes:
      - ./cafeteras.csv:/datos/cafeteras.csv
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  cafe_data:
```

```bash
# Comprueba que las variables se han sustituido de verdad
docker compose config

docker compose up -d
docker compose restart procesador
docker compose logs -f procesador   # Ctrl+C para salir del seguimiento
```

Si `docker compose config` no sustituye tus variables (las ves como texto
literal `${POSTGRES_USER}` en la salida), revisa que el `.env` esté **en
la misma carpeta** desde la que ejecutas `docker compose`, no en una
subcarpeta. Si `postgres` no arranca tras añadir `restart:`, no cambia
nada respecto a antes — ese campo solo afecta a qué pasa **después** de
que el contenedor muera, no a si arranca bien la primera vez.

</details>

**Cómo sabes que has sobrevivido**: `docker compose config` muestra los
valores reales (no `${...}` sin resolver), y si haces
`docker restart $(docker inspect --format '{{.Id}}' <container_id_de_docker>)`
o simplemente reinicias Docker Desktop, tus servicios vuelven a estar
`healthy` sin que tú ejecutes `docker compose up` a mano.

---

## Nivel 10 — Jefe de acto: que sobreviva a un `docker compose down` (10 min) ⭐⭐⭐⭐

**Teoría exprés**: la trampa favorita del examen final de cualquier
profesor de Docker: `down` sin `-v` **no borra los volúmenes con nombre**.
`down -v` sí. Es la diferencia entre reiniciar el servidor y prenderle
fuego.

**Misión**: para el stack, vuelve a levantarlo, y comprueba que la fila
que insertaste en el nivel 9 **sigue ahí**. Luego haz lo mismo, pero esta
vez con el flag que sí borra los volúmenes, y comprueba que la fila **ha
desaparecido**.

**Pistas**:
- El comando para parar y levantar de nuevo sin borrar nada es el mismo
  `docker compose` de siempre, solo con dos subcomandos distintos.
- Para consultar dentro del contenedor de Postgres sin salir de tu
  terminal, usa `docker compose exec postgres psql -U ... -d ... -c "..."`.
- El flag que sí destruye los volúmenes nombrados va pegado a `down`.

<details>
<summary>Solución</summary>

```bash
docker compose down          # para los contenedores
docker compose up -d         # los vuelve a levantar
docker compose exec postgres psql -U cafe -d cafeconDatos -c "SELECT * FROM resumen;"

# Ahora, el experimento de verdad
docker compose down -v
docker compose up -d
docker compose exec postgres psql -U cafe -d cafeconDatos -c "SELECT * FROM resumen;"
```

Con `down` a secas la fila sigue ahí; con `down -v` la tabla ni siquiera
existe (hay que esperar a que `procesador` vuelva a arrancar y la recree,
y aun así estará vacía). Si con `down` normal ya habías perdido los
datos, revisa que en el nivel 7 usaste un volumen **con nombre**
(`cafe_data:`) y no uno anónimo.

</details>

**Cómo sabes que has sobrevivido**: entiendes, sin tener que preguntarlo
en clase, por qué `down` a secas conserva los datos y `down -v` no. Acto
II superado.

---

# ACTO III — Kubernetes

## Nivel 11 — El cluster se enciende (5 min) ⭐

**Teoría exprés**: nada nuevo que aprender aquí, solo el ritual de
invocación.

**Misión**: enciende tu cluster local y comprueba que el nodo está listo
para recibir trabajo.

**Pistas**:
- El comando que arranca el cluster y el que lista sus nodos son los dos
  primeros que aprendiste en la sesión 3.

<details>
<summary>Solución</summary>

```bash
minikube start
kubectl get nodes
```

Si `minikube start` se cuelga más de 3 minutos, es tu señal para el plan B:
borra y reintenta (`minikube delete && minikube start`),
o baja los recursos con `--memory=2560`.

</details>

**Cómo sabes que has sobrevivido**: `kubectl get nodes` muestra un nodo en
estado `Ready`.

---

## Nivel 12 — Traduce tu procesador a un Pod suelto (15 min) ⭐⭐⭐

**Teoría exprés**: un Pod es el equivalente en Kubernetes a
`docker run`. Y, como en la sesión 3 no te cansaste de oír, **un Pod
suelto no se recupera solo si muere**. Este nivel existe precisamente
para que lo compruebes con tus propias manos.

**Misión**: escribe `01-pod.yaml`, un Pod suelto que ejecute tu imagen del
procesador. Aplícalo, compruébalo y luego bórralo a propósito para ver si
vuelve.

**Pistas**:
- minikube no ve las imágenes de tu Docker local automáticamente: tienes
  que cargarlas explícitamente con un subcomando de `minikube image ...`.
- Como la imagen no viene de ningún registro remoto, dile a Kubernetes que
  **no** intente descargarla: hay un campo `imagePullPolicy` para eso.
- El resto del Pod es igual que el ejemplo de la sesión 3: `apiVersion`,
  `kind`, `metadata` con una `label`, y `spec.containers` con `name` e
  `image`.

<details>
<summary>Solución</summary>

```bash
docker build --platform linux/amd64 -t cafecondatos:1.0 .
minikube image load cafecondatos:1.0
```

`01-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: procesador-pod
  labels:
    app: procesador
spec:
  containers:
    - name: procesador
      image: cafecondatos:1.0
      imagePullPolicy: Never
```

```bash
kubectl apply -f 01-pod.yaml
kubectl get pods
kubectl delete pod procesador-pod
kubectl get pods
```

Si ves `ImagePullBackOff`, seguramente olvidaste el `minikube image load`
o el `imagePullPolicy: Never` (sin él, Kubernetes intenta descargar de
Docker Hub una imagen que solo existe en tu máquina).

</details>

**Cómo sabes que has sobrevivido**: tras borrar el Pod, `kubectl get pods`
no muestra nada. Nadie lo repone. Exactamente como en la sesión 3, y
exactamente por lo que viene el siguiente nivel.

---

## Nivel 13 — El Pod que sí vuelve (15 min) ⭐⭐⭐⭐

**Teoría exprés**: un Deployment no es "un Pod mejorado", es **un vigilante
que se asegura de que siempre haya el número de Pods que le pediste**. Es
la pieza que convierte "se ha caído" en "ya está arriba otra vez, ni te
enteraste".

**Misión**: escribe `02-deployment.yaml`, con el mismo contenedor que en
el nivel 12 pero gestionado por un Deployment con **2 réplicas**. Borra
uno de sus Pods a propósito y comprueba qué pasa esta vez.

**Pistas**:
- Un Deployment necesita un `selector` que coincida exactamente con las
  `labels` de la plantilla (`template.metadata.labels`) — si no coinciden,
  no crea ningún Pod.
- El campo que fija el número de réplicas va directamente bajo `spec`.
- Para borrar un Pod concreto necesitas su nombre exacto, que ahora es
  autogenerado: consíguelo con `kubectl get pods -l app=procesador`.

<details>
<summary>Solución</summary>

`02-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: procesador
spec:
  replicas: 2
  selector:
    matchLabels:
      app: procesador
  template:
    metadata:
      labels:
        app: procesador
    spec:
      containers:
        - name: procesador
          image: cafecondatos:1.0
          imagePullPolicy: Never
```

```bash
kubectl apply -f 02-deployment.yaml
kubectl get pods -l app=procesador
kubectl delete pod <uno-de-los-dos-nombres>
kubectl get pods -l app=procesador
```

Si tu Pod imprime su resultado y termina (estado `Completed` en vez de
`Running`), el Deployment lo va a **reiniciar en bucle**, porque de su
punto de vista un contenedor que ha terminado es un contenedor que se ha
"caído". Esto no es un bug del ejercicio: es exactamente el aviso de
"Servicios frente a tareas" de la sesión 3. Para este nivel, está bien
así — en el nivel 16 lo vas a arreglar de verdad.

</details>

**Cómo sabes que has sobrevivido**: borras un Pod y, en segundos, aparece
uno nuevo con un nombre distinto. El número total de Pods con
`app=procesador` nunca baja de 2.

---

## Nivel 14 — Le das tu configuración sin escribirla en el YAML, y Postgres entra en el cluster (20 min) ⭐⭐⭐⭐

**Teoría exprés**: `postgres`, `cafe`, `cafeconDatos` llevan diez niveles
escritos a fuego en tu código. Un ConfigMap (y, para la contraseña, un
Secret) separa eso del contenedor — el mismo motivo por el que en Compose
usabas variables de entorno y no valores fijos. Pero un ConfigMap con
`DB_HOST: postgres` solo describe **dónde debería estar** Postgres, no lo
crea. Hasta ahora tu procesador en Kubernetes ha vivido solo: en este
nivel Postgres entra por fin en el cluster, con su propio Deployment y
Service, para que ese nombre resuelva a algo de verdad.

**Misión**: actualiza `procesar.py` para que lea la conexión de variables
de entorno en vez de tenerla escrita a fuego, mueve esa configuración a
un ConfigMap (los datos no secretos) y un Secret (la contraseña), y
despliega Postgres en el propio cluster reutilizando ese mismo
ConfigMap/Secret como sus credenciales de arranque.

**Pistas**:
- En Python, se leen variables de entorno con `os.environ["NOMBRE"]`.
- Un ConfigMap y un Secret se parecen tanto que puedes escribirlos en el
  mismo archivo YAML separados por `---`.
- Para inyectar **todas** las claves de un ConfigMap o Secret como
  variables de entorno de golpe (sin listarlas una a una), el campo del
  contenedor se llama `envFrom`, con `configMapRef` y `secretRef` dentro.
- La imagen oficial de Postgres arranca leyendo `POSTGRES_USER`,
  `POSTGRES_PASSWORD` y `POSTGRES_DB` — nombres que no coinciden con las
  claves de tu ConfigMap/Secret (`DB_USER`, `DB_NAME`...). En vez de
  duplicar las credenciales con nombres distintos, un contenedor puede
  definir una variable de entorno **individual** cuyo valor viene de una
  clave concreta: el campo es `env` (no `envFrom`), con
  `valueFrom.configMapKeyRef` o `valueFrom.secretKeyRef`.
- El Service de Postgres necesita un `selector` que coincida con las
  `labels` de su Deployment, y expone el puerto `5432` — no publiques
  ningún `NodePort` todavía, nadie fuera del cluster necesita hablar con
  él en este nivel.
- No olvides reconstruir la imagen del procesador y recargarla en
  minikube tras cambiar el script, y esperar a que Postgres esté listo
  antes de aplicar el Deployment del procesador (`kubectl wait
  --for=condition=ready`).

<details>
<summary>Solución</summary>

`procesar.py` (fragmento de la conexión):

```python
import os
conn = psycopg2.connect(
    host=os.environ["DB_HOST"],
    dbname=os.environ["DB_NAME"],
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASSWORD"],
)
```

```bash
docker build --platform linux/amd64 -t cafecondatos:1.0 .
minikube image load cafecondatos:1.0
```

`03-configmap-secret.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: procesador-config
data:
  DB_HOST: postgres
  DB_NAME: cafeconDatos
  DB_USER: cafe
---
apiVersion: v1
kind: Secret
metadata:
  name: procesador-secret
type: Opaque
stringData:
  DB_PASSWORD: cafe
```

`04-postgres.yaml` (Postgres entra en el cluster — sin almacenamiento
persistente todavía, eso llega en el jefe final):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:18-alpine
          env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: procesador-config
                  key: DB_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: procesador-secret
                  key: DB_PASSWORD
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: procesador-config
                  key: DB_NAME
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

`02-deployment.yaml` (añade `envFrom` al contenedor del procesador):

```yaml
      containers:
        - name: procesador
          image: cafecondatos:1.0
          imagePullPolicy: Never
          envFrom:
            - configMapRef:
                name: procesador-config
            - secretRef:
                name: procesador-secret
```

```bash
kubectl apply -f 03-configmap-secret.yaml
kubectl apply -f 04-postgres.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
kubectl apply -f 02-deployment.yaml
```

Si el Pod de Postgres entra en `CrashLoopBackOff`, mira primero sus logs
(`kubectl logs -l app=postgres`) — el motivo más típico es una clave mal
escrita en `configMapKeyRef`/`secretKeyRef` (revisa que `DB_USER`,
`DB_NAME` y `DB_PASSWORD` coincidan letra a letra con las claves del
ConfigMap/Secret).

Si el Pod del procesador entra en `CrashLoopBackOff`, mira sus logs con
`--previous` (el aviso más repetido de toda la sesión 3, y con razón):

```bash
kubectl logs <pod> --previous
```

Lo más probable es un `KeyError` porque falta alguna variable — revisa que
el `envFrom` esté dentro de `spec.containers[0]`, no en cualquier otro
sitio (el YAML muerde, ¿recuerdas?). Si en cambio el error es de conexión
(`could not connect to server`), significa que aplicaste el Deployment
del procesador **antes** de que Postgres estuviera listo — de ahí el
`kubectl wait` del paso anterior.

</details>

**Cómo sabes que has sobrevivido**: `kubectl exec` en el Pod del
procesador y `echo $DB_HOST` te devuelve `postgres`, sin que esa palabra
aparezca en tu imagen ni en tu código — y, la prueba de verdad, una
consulta directa a Postgres confirma que la fila se ha insertado:

```bash
kubectl exec deploy/postgres -- psql -U cafe -d cafeconDatos -c "SELECT * FROM resumen;"
```

(Si el Deployment del procesador lleva un rato vivo, verás **varias**
filas, una por cada reinicio — exactamente el defecto del nivel 13 que
todavía no has arreglado. Eso llega en el nivel 16.)

---

## Nivel 15 — Ojos que vigilan, frenos que paran (15 min) ⭐⭐⭐⭐

**Teoría exprés**: que un contenedor esté `Running` no significa que
funcione — puede estar vivo pero colgado. Una **readiness probe**
comprueba eso de verdad, y si falla, Kubernetes no le manda tráfico (pero
no lo reinicia). Por separado: sin decirle a Kubernetes cuánta memoria
necesita tu contenedor, no hay límite — y sin límite, un `pandas` que se
desmadra se come el nodo entero. Con límite, Kubernetes lo mata primero,
de forma controlada: es el famoso `OOMKilled`, probablemente el error que
más vas a ver en producción el día de mañana.

**Misión**: en cuatro pasos, sobre el Postgres y el Deployment de los
niveles anteriores:

1. Añade una `readinessProbe` al contenedor de Postgres que reutilice el
   mismo comando que ya usaste como `healthcheck` en Compose (nivel 7),
   ahora traducido al mundo Kubernetes.
2. Añade `resources.limits.memory` al contenedor del procesador, con un
   valor deliberadamente bajo, y observa cómo muere.
3. Diagnóstica ese fallo sin adivinar: usa el kit de depuración real de
   `kubectl`, no solo `get pods`.
4. Sube el límite a un valor razonable, comprueba que sobrevive, y de
   paso, habla con tu Postgres **desde fuera del cluster**, sin exponer
   ningún puerto en el YAML.

**Pistas**:
- Una probe basada en ejecutar un comando dentro del propio contenedor usa
  el campo `exec.command`, con la lista de argumentos tal cual los
  pasarías en la terminal (nada de comillas de más). Si ese comando
  necesita leer variables de entorno del propio contenedor (para no
  repetir las credenciales que ya definiste en el nivel 14),
  `exec.command` no las expande solo — necesitas pasar por una shell
  explícita, del estilo `["sh", "-c", "tu comando $VARIABLE"]`.
- `resources` va al mismo nivel que `image` dentro de un contenedor, con
  dos secciones: `requests` (lo que se le garantiza) y `limits` (el techo).
  Para provocar el fallo a propósito, un `limits.memory` de `20Mi` debería
  bastar para una imagen tan ligera como la tuya.
- Tras el fallo, `kubectl describe pod <pod>` tiene una sección con el
  motivo del último reinicio: busca una palabra que empieza por "OOM".
- `kubectl get events --sort-by=.lastTimestamp` te da, en orden
  cronológico, avisos que `kubectl get pods` a secas no muestra.
- Para hablar con el Service de Postgres desde tu máquina sin tocar
  ningún YAML, existe `kubectl port-forward svc/<nombre>
  <puerto_local>:<puerto_del_service>`; se corta con `Ctrl+C`.
- Para no instalar el cliente `psql` en tu máquina, lanza un contenedor
  efímero de `postgres:18-alpine` (el mismo patrón "nada instalado en tu
  máquina" del nivel 1) apuntando a `host.docker.internal`, que es cómo
  Docker Desktop te deja llegar desde un contenedor a un puerto abierto en
  tu propio host.

<details>
<summary>Solución</summary>

`04-postgres.yaml` (añade `readinessProbe` al contenedor `postgres` que
ya desplegaste en el nivel 14 — reutiliza las variables que ese
contenedor ya tiene en su entorno, en vez de repetir las credenciales por
tercera vez):

```yaml
          readinessProbe:
            exec:
              command: ["sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
            initialDelaySeconds: 5
            periodSeconds: 5
```

`02-deployment.yaml` (añade `resources` al contenedor `procesador`,
primero con un límite imposible):

```yaml
          resources:
            requests:
              memory: "16Mi"
            limits:
              memory: "20Mi"
```

```bash
kubectl apply -f 04-postgres.yaml
kubectl apply -f 02-deployment.yaml
kubectl get pods -l app=procesador

# El diagnóstico de verdad
kubectl describe pod <un-pod-de-procesador> | grep -A3 "Last State"
kubectl get events --sort-by=.lastTimestamp | tail -10
```

Deberías ver `Reason: OOMKilled` en el estado anterior del contenedor.
Ahora sube el límite a algo razonable:

```yaml
          resources:
            requests:
              memory: "32Mi"
            limits:
              memory: "64Mi"
```

```bash
kubectl apply -f 02-deployment.yaml
kubectl get pods -l app=procesador   # ya no debería reiniciarse
```

Y el `port-forward`, para hablar con Postgres sin exponer nada nuevo:

```bash
kubectl port-forward svc/postgres 5433:5432 &
docker run --rm postgres:18-alpine \
  psql -h host.docker.internal -p 5433 -U cafe -d cafeconDatos -c "SELECT 1;"
```

Si el `port-forward` se queda colgado sin conectar, comprueba que el
Service `postgres` existe y tiene al menos un Pod detrás con
`kubectl get endpoints postgres`. Si `docker run` no encuentra
`host.docker.internal`, asegúrate de estar en Docker Desktop (Mac o
Windows) — en Linux nativo el equivalente es `--add-host=host.docker.internal:host-gateway`.
Cuando termines, mata el `port-forward` en segundo plano con `kill %1` o
`Ctrl+C` si lo lanzaste en primer plano.

</details>

**Cómo sabes que has sobrevivido**: con el límite bajo, ves `OOMKilled` en
`kubectl describe pod`; con el límite razonable, el Pod se queda
`Running` sin reiniciarse; y el `psql` efímero a través del
`port-forward` te devuelve una fila con un `1`, sin haber expuesto ningún
puerto nuevo en tus manifiestos.

---

## Nivel 16 — JEFE FINAL: el Pod inmortal (20 min) ⭐⭐⭐⭐⭐

**Teoría exprés**: junta todo lo que has aprendido en los tres actos y
arréglale el defecto que arrastrabas desde el nivel 13: tu procesador
**termina**, y un Deployment está pensado para procesos que **no
terminan**. La pieza correcta para "algo que se ejecuta una vez y se da
por bueno" es un **Job**, no un Deployment — el punto ciego exacto de la
sesión 3. Y tu Postgres, desde el nivel 14, tampoco tiene almacenamiento
persistente todavía: si su Pod muere, sus datos mueren con él. Ese es el
segundo defecto que este nivel arregla.

**Misión**: añade una `PersistentVolumeClaim` a tu Postgres del nivel 14
(actualiza `04-postgres.yaml`, no lo reescribas desde cero — el
Deployment y el Service ya existen), convierte el Deployment del
procesador del nivel 13 en un **Job** en `05-job.yaml`, y demuestra que
los datos sobreviven aunque **mates el Pod de Postgres a propósito**.

**Pistas**:
- Un PVC pide almacenamiento con `accessModes` y
  `resources.requests.storage`; luego se referencia desde el Pod con
  `volumes` + `persistentVolumeClaim`, y se monta dentro del contenedor
  con `volumeMounts` en la misma ruta que usa la imagen oficial de
  Postgres (`/var/lib/postgresql`).
- Añadir un `volumeMount` a un Deployment que ya existe dispara un
  rollout: el Pod de Postgres se recreará una vez al aplicar el cambio —
  eso es normal, no es el fallo que estás buscando arreglar.
- Un Job, a diferencia de un Deployment, **no repone el Pod cuando
  termina bien** — solo reintenta si falla, hasta un límite
  (`backoffLimit`). Esa es la pieza que arregla el defecto del nivel 13.
- Las credenciales y la `readinessProbe` de Postgres no cambian respecto
  a los niveles 14 y 15 — solo añades almacenamiento, no reinventas la
  configuración.
- Para esperar a que algo esté listo antes de seguir con el siguiente
  paso, existe `kubectl wait --for=condition=...`.

<details>
<summary>Solución (léela solo si el jefe final te ha matado a ti primero)</summary>

`04-postgres.yaml` (la misma base de los niveles 14 y 15 — lo único
nuevo es el bloque `PersistentVolumeClaim` y las líneas
`volumeMounts`/`volumes`):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 256Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:18-alpine
          env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: procesador-config
                  key: DB_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: procesador-secret
                  key: DB_PASSWORD
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: procesador-config
                  key: DB_NAME
          readinessProbe:
            exec:
              command: ["sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: datos
              mountPath: /var/lib/postgresql
      volumes:
        - name: datos
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

`05-job.yaml` (el mismo contenedor del Deployment de los niveles 13–15,
límites de memoria incluidos, ahora gestionado por un Job):

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: procesador
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: procesador
          image: cafecondatos:1.0
          imagePullPolicy: Never
          envFrom:
            - configMapRef:
                name: procesador-config
            - secretRef:
                name: procesador-secret
          resources:
            requests:
              memory: "32Mi"
            limits:
              memory: "64Mi"
```

```bash
kubectl apply -f 04-postgres.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
kubectl apply -f 05-job.yaml
kubectl wait --for=condition=complete job/procesador --timeout=60s

# El golpe de gracia
kubectl delete pod -l app=postgres
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s

# ¿Sobrevivió?
POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -- psql -U cafe -d cafeconDatos -c "SELECT * FROM resumen;"
```

Errores más probables, de más a menos frecuente:

- **El Job se queda en bucle reintentando**: revisa `procesar.py` —
  cualquier excepción sin capturar hace que el proceso salga con código
  distinto de cero, y el Job lo cuenta como fallo. Añade manejo de errores
  si te falta.
- **El PVC no se crea**: en minikube, comprueba que hay una `StorageClass`
  por defecto con `kubectl get storageclass`. Casi siempre la hay (`standard`),
  pero si no, es la única pieza que necesitarías crear a mano.
- **Tras matar el Pod, la tabla `resumen` ha desaparecido**: significa que
  el `volumeMounts` no apunta a la misma ruta que declara la imagen oficial
  de Postgres (`/var/lib/postgresql`, sin `/data` al final, en Postgres 18).
  Es el mismo detalle que ya viste con el volumen con nombre en Compose,
  solo que aquí se llama PVC.

Si después de todo esto la fila sigue ahí tras matar el Pod: felicidades,
la mataste, y volvió, con la memoria intacta. Es lo más parecido a una
resurrección que vas a conseguir programando.

</details>

**Cómo sabes que has sobrevivido**: la consulta final devuelve la fila que
insertó el Job, **después** de haber borrado y recreado el Pod de
Postgres. Si esto te ha salido, no hay ya ningún concepto de los tres
módulos que no hayas tocado con tus manos.

---

## Certificado de supervivencia (no oficial, no vale para nada, pero te lo has ganado)

Si has llegado hasta aquí, sin trampas, esto es lo que acabas de demostrar
que sabes hacer sin que nadie te lo explique paso a paso:

| Concepto | Nivel donde lo sufriste |
|---|---|
| Contenedores, bind mounts | 1 – 2 |
| Dockerfile, `.dockerignore`, `--platform` | 3 – 4 |
| Iteración, depuración y limpieza de imágenes | 5 |
| La imagen no lleva tus datos (jefe de acto) | 6 |
| Compose multi-servicio, DNS interno, `depends_on` sano | 7 – 8 |
| `.env`, `restart` policy y ciclo de iteración en Compose | 9 |
| Volúmenes con nombre y qué borra `down -v` (jefe de acto) | 10 |
| Pods sueltos y por qué no se usan solos | 12 |
| Deployments y self-healing | 13 |
| ConfigMap, Secret y Postgres desplegado en el cluster | 14 |
| Probes, `resources`/`limits`, `OOMKilled`, `port-forward` | 15 |
| Job frente a Deployment, PersistentVolumeClaim | 16 |

Lo único que **no** hay aquí es un CronJob (el ETL de las 2:00 de la
madrugada) — si te ha sabido a poco, ya sabes cuál es el siguiente jefe
final que te falta por matar.
