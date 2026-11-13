# Ejercicios de Kubernetes para Data Engineers

> Sesión práctica de 2h30, continuación directa del bloque de Docker.
> Al terminar tendrás, corriendo sobre un cluster de Kubernetes, un pipeline
> completo: una base de datos con almacenamiento persistente, una API que
> expone datos, y un proceso programado que alimenta la base de datos cada
> pocos minutos. Un proyecto **end to end**.

⚠️ Instalación previa: **[REQUISITOS.md](./REQUISITOS.md)** ← minikube y kubectl
Teoría de apoyo: **[TEORIA_KUBERNETES.md](./TEORIA_KUBERNETES.md)**
Prerrequisito: **[EJERCICIOS.md](./EJERCICIOS.md)** (bloque de Docker completo)
Si algo falla: **[TEORIA_KUBERNETES.md § Apéndice B](./TEORIA_KUBERNETES.md#apéndice-b--cuando-algo-falla)**

---

## Antes de la clase (OBLIGATORIO)

⚠️ **Esto no es opcional.** Si llegas sin hacerlo, perderás la primera hora
instalando cosas y no darás alcance al resto del grupo. Son 20 minutos en
casa con buena conexión.

### 1. Instalar minikube y kubectl

```bash
# macOS (con Homebrew)
brew install minikube kubectl

# Windows (con winget)
winget install Kubernetes.minikube
winget install Kubernetes.kubectl

# Linux — ver https://minikube.sigs.k8s.io/docs/start/
```

> Instrucciones detalladas por sistema operativo (incluido qué hacer si usas
> WSL, Colima o Rancher Desktop) en **[REQUISITOS.md § 4–6](./REQUISITOS.md)**.

### 2. Arrancar el cluster una vez y comprobar que va

```bash
minikube start --driver=docker --memory=4096 --cpus=2
kubectl get nodes
# -> debe aparecer 1 nodo en estado Ready

minikube stop      # apágalo hasta el día de la clase
```

> Si `minikube start` falla por memoria, prueba con `--memory=3072`. Si tienes
> Docker Desktop, sube su límite de RAM a 6 GB en Settings → Resources.

### 3. Construir y publicar tu imagen del pipeline

Esta es **la imagen que desplegarás en Kubernetes durante toda la sesión**.
Usa exactamente lo que aprendiste en el bloque de Docker.

Crea la carpeta `ejercicios/k8s-sandbox/app/` con estos cuatro archivos:

**`generador.py`** — la lógica de generación de datos (reutilizada por los
otros dos):

```python
import numpy as np
import pandas as pd
from datetime import datetime, timedelta


def generar(n=10):
    """Genera un DataFrame de lecturas de sensores con timestamps."""
    ahora = datetime.now()
    return pd.DataFrame({
        "timestamp": [ahora - timedelta(minutes=i * 5) for i in range(n)],
        "sensor": np.random.choice(["norte", "sur", "este", "oeste"], n),
        "temperatura": np.round(np.random.uniform(15, 30, n), 2),
        "humedad": np.round(np.random.uniform(30, 90, n), 2),
    })
```

**`api.py`** — un servidor HTTP mínimo que expone los datos en JSON
(sin dependencias extra, solo la librería estándar):

```python
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from generador import generar


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return

        n = int(os.getenv("BATCH_SIZE", "5"))
        cuerpo = generar(n).to_json(orient="records", date_format="iso").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(cuerpo)

    def log_message(self, *args):
        pass  # silencia el log por petición


print("API escuchando en el puerto 8000", flush=True)
HTTPServer(("", 8000), Handler).serve_forever()
```

**`pipeline.py`** — el proceso por lotes que escribe en PostgreSQL:

```python
import os
from sqlalchemy import create_engine
from generador import generar

n = int(os.getenv("BATCH_SIZE", "10"))
host = os.getenv("DB_HOST", "postgres")
usuario = os.getenv("POSTGRES_USER", "datos")
password = os.getenv("POSTGRES_PASSWORD", "cambiame")
base = os.getenv("POSTGRES_DB", "datos")

df = generar(n)
engine = create_engine(f"postgresql+psycopg2://{usuario}:{password}@{host}:5432/{base}")
df.to_sql("lecturas", engine, if_exists="append", index=False)

print(f"OK: {len(df)} filas insertadas en la tabla 'lecturas'", flush=True)
```

**`Dockerfile`**:

```dockerfile
FROM python:3.13-slim
WORKDIR /app
RUN pip install --no-cache-dir \
    pandas==2.2.3 numpy==2.1.3 sqlalchemy==2.0.36 psycopg2-binary==2.9.10
COPY generador.py api.py pipeline.py ./
EXPOSE 8000
CMD ["python", "api.py"]
```

Constrúyela y **publícala en Docker Hub** (misma cuenta del Ejercicio 5 bis
de Docker):

```bash
cd ejercicios/k8s-sandbox/app

docker build -t TU_USUARIO/mi-pipeline:1.0 .
docker run --rm -p 8000:8000 TU_USUARIO/mi-pipeline:1.0   # pruébala: http://localhost:8000
docker login
docker push TU_USUARIO/mi-pipeline:1.0
```

> **¿No tienes cuenta de Docker Hub?** Puedes cargar la imagen directamente en
> minikube con `minikube image load mi-pipeline:1.0` (constrúyela sin
> prefijo de usuario) y añadir `imagePullPolicy: IfNotPresent` a los
> contenedores. Ver [§10.1 de la teoría](./TEORIA_KUBERNETES.md#101-el-problema-nº1-de-minikube-tus-imágenes-locales-no-existen).

### Checklist antes de venir a clase

- [ ] `kubectl get nodes` muestra un nodo `Ready`
- [ ] `TU_USUARIO/mi-pipeline:1.0` aparece en tu perfil de Docker Hub
- [ ] `docker run --rm -p 8000:8000 TU_USUARIO/mi-pipeline:1.0` devuelve JSON en el navegador

---

## Cómo usar estos ejercicios

Mismo formato que el bloque de Docker: **Objetivo**, **Por qué te importa**,
**Conceptos**, **Tarea**, **Solución** (desplegable), **Validación** y
**Para pensar**.

En estos ejercicios **escribirás los manifiestos YAML tú**, en la carpeta
`ejercicios/k8s-sandbox/`. Están todos en las soluciones, pero teclearlos es
justo lo que hace que se te queden.

```bash
cd ejercicios
mkdir -p k8s-sandbox && cd k8s-sandbox
```

Usaremos el **puerto 8090** para acceder desde el navegador (el proyecto de
Airflow usa el 8080 y el sandbox de Docker el 8088, así nada choca).

En todos los manifiestos, sustituye `TU_USUARIO` por tu usuario de Docker Hub.

---

## Plan de la sesión (150 min)

| Tiempo | Bloque | Ejercicios |
|---|---|---|
| 0–20 min | Arrancar el cluster y orientarse | Bloque 0 |
| 20–40 min | Pods y Deployments: el self-healing | 1 |
| 40–60 min | Services: acceder a tu aplicación | 2 |
| 60–70 min | **Descanso** | |
| 70–85 min | Configuración sin reconstruir la imagen | 3 |
| 85–105 min | Persistencia real: Postgres con PVC | 4 |
| 105–135 min | El pipeline completo: CronJob → Postgres | 5 |
| 135–150 min | Extras, cierre y limpieza | 6 (opcional) |

---

# Bloque 0 — Arrancar el cluster (20 min)

```bash
minikube start --driver=docker --memory=4096 --cpus=2
minikube status
```

Orientarte en el cluster antes de tocar nada:

```bash
kubectl get nodes -o wide          # el (único) nodo de tu cluster
kubectl get namespaces             # las "carpetas" del cluster
kubectl get pods -n kube-system    # los Pods internos de Kubernetes
```

Fíjate en `kube-system`: ahí están corriendo, **como Pods**, los componentes
del control plane que viste en la teoría (`etcd`, `kube-apiserver`,
`kube-scheduler`, `kube-controller-manager`, `coredns`). Kubernetes se ejecuta
a sí mismo sobre Kubernetes.

**Checkpoint**: `kubectl get nodes` muestra un nodo `Ready`. Si no, resuélvelo
**ahora**, no a mitad del Ejercicio 1.

> **Opcional pero muy visual**: `minikube dashboard` abre una interfaz web
> donde ves todos los objetos del cluster. Va bien para seguir la sesión en
> paralelo a la terminal.

---

# Bloque 1 — Pods, Deployments y Services

## Ejercicio 1 ⭐ NÚCLEO — Tu primer Pod y por qué nunca se usan solos (20 min)

**Objetivo**: desplegar tu propia imagen en Kubernetes y ver el self-healing
en directo.

**Por qué te importa**: es el equivalente al `docker run` de Kubernetes, pero
con la diferencia fundamental que justifica todo el sistema: aquí, lo que
declaras **se mantiene solo**.

**Conceptos**: [§4](./TEORIA_KUBERNETES.md#4-pod-replicaset-y-deployment),
[§3](./TEORIA_KUBERNETES.md#3-anatomía-de-un-manifiesto-yaml)

### Tarea

1. Escribe `01-pod.yaml`: un Pod suelto con tu imagen `TU_USUARIO/mi-pipeline:1.0`.
   Aplícalo y compruébalo.
2. **Bórralo a propósito.** ¿Vuelve?
3. Escribe `02-deployment.yaml`: el mismo contenedor, pero gestionado por un
   Deployment con **3 réplicas**.
4. **Borra uno de los Pods del Deployment.** ¿Y ahora?
5. Escala a 5 réplicas sin editar el archivo.

### Pista

Un manifiesto siempre tiene los mismos cuatro bloques: `apiVersion`, `kind`,
`metadata` (con al menos un `name`) y `spec`. Para un Pod, lo único que
necesita el `spec` es una lista `containers` con `name`, `image` y
`ports.containerPort` (el puerto que tu `Dockerfile` expone con `EXPOSE`). El
Deployment **no es un objeto nuevo que aprender**: es un `spec.template` que
contiene exactamente ese mismo Pod, más `replicas` y un `selector` que debe
usar la misma label que pongas en `template.metadata.labels`.

### Guía paso a paso

1. Copia este esqueleto como `01-pod.yaml` y rellena los `<...>`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: <nombre-libre-para-el-pod>
     labels:
       app: <etiqueta-para-agrupar-luego>
   spec:
     containers:
       - name: <nombre-libre-para-el-contenedor>
         image: <TU_USUARIO/mi-pipeline:1.0>
         ports:
           - containerPort: <puerto-que-expone-tu-imagen>
   ```

2. `kubectl apply -f 01-pod.yaml` y `kubectl get pods`. Si se queda en
   `ImagePullBackOff`, revisa el nombre de la imagen antes de seguir.

   > **¿No publicaste la imagen en Docker Hub?** Kubernetes solo sabe tirar
   > de registries, nunca mira tu Docker local. Si construiste la imagen sin
   > `docker push` (por ejemplo `docker build -t mi-pipeline:1.0 .`, sin
   > prefijo de usuario), tienes que meterla tú mismo dentro de minikube con
   > `minikube image load mi-pipeline:1.0`, y añadir
   > `imagePullPolicy: IfNotPresent` al contenedor para que no intente
   > descargarla de internet.

3. `kubectl delete pod <nombre>` y comprueba con `kubectl get pods` que no
   vuelve solo.
4. Para `02-deployment.yaml`, reutiliza el mismo bloque `containers` de arriba
   dentro de esta estructura (no lo escribas desde cero):

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: <nombre-libre-para-el-deployment>
   spec:
     replicas: <numero-de-copias>
     selector:
       matchLabels:
         app: <misma-etiqueta-que-abajo>
     template:
       metadata:
         labels:
           app: <misma-etiqueta-que-arriba>
       spec:
         containers:
           - name: <...>
             image: <...>
             ports:
               - containerPort: <...>
   ```

   La clave que rompe el 90% de los Deployments mal escritos:
   `spec.selector.matchLabels.app` y `spec.template.metadata.labels.app`
   **tienen que ser idénticos, letra por letra**. Si no coinciden, el
   Deployment se crea sin error visible pero no gestiona ningún Pod.
5. Borra un Pod del Deployment (no el Deployment entero) y observa que
   aparece uno nuevo. Luego `kubectl scale deployment <nombre> --replicas=5`.

### Solución

<details>
<summary>Ver solución</summary>

`01-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  labels:
    app: api
spec:
  containers:
    - name: api
      image: TU_USUARIO/mi-pipeline:1.0
      ports:
        - containerPort: 8000
```

```bash
kubectl apply -f 01-pod.yaml
kubectl get pods                       # espera a 1/1 Running
kubectl describe pod api-pod           # mira la sección Events del final
kubectl logs api-pod                   # -> "API escuchando en el puerto 8000"

# El experimento
kubectl delete pod api-pod
kubectl get pods
# -> no hay nada. Nadie lo repone. Igual que un `docker run` sin --restart.
```

`02-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: TU_USUARIO/mi-pipeline:1.0
          ports:
            - containerPort: 8000
```

```bash
kubectl apply -f 02-deployment.yaml
kubectl get pods -l app=api            # 3 Pods, con nombres autogenerados
kubectl get deploy,rs,pods             # ¡mira la jerarquía Deployment → ReplicaSet → Pods!

# El mismo experimento
kubectl delete pod <nombre-de-un-pod>
kubectl get pods -l app=api
# -> en segundos aparece uno nuevo. El bucle de reconciliación en acción.

# Escalar sin tocar el YAML
kubectl scale deployment api --replicas=5
kubectl get pods -l app=api -w         # Ctrl+C para salir
```

</details>

### Validación

`kubectl get pods -l app=api` muestra 5 Pods `Running`, y borrar cualquiera de
ellos hace que aparezca otro automáticamente.

### Para pensar

- Ejecuta `kubectl get rs`. ¿De dónde ha salido ese ReplicaSet si tú no lo
  creaste?
- Los nombres de los Pods son del tipo `api-7d4b9c8f5-x9k2p`. ¿Por qué crees
  que Kubernetes les pone un sufijo aleatorio en vez de `api-1`, `api-2`?
- Si `kubectl scale` funciona, ¿para qué sirve entonces el `replicas: 3` del
  archivo? ¿Qué pasa si vuelves a hacer `kubectl apply -f 02-deployment.yaml`?

---

## Ejercicio 2 ⭐ NÚCLEO — Services: acceder a tu aplicación (20 min)

**Objetivo**: dar una dirección estable a tus Pods y acceder desde tu
navegador.

**Por qué te importa**: los Pods cambian de IP constantemente. Sin Service, en
Kubernetes no se puede conectar nada con nada.

**Conceptos**: [§5](./TEORIA_KUBERNETES.md#5-services-y-red-interna),
[§3.1](./TEORIA_KUBERNETES.md#31-labels-y-selectors--el-pegamento-de-kubernetes)

### Tarea

1. Comprueba que las IPs de tus Pods son distintas y cambian al recrearlos.
2. Escribe `03-service.yaml`: un Service `ClusterIP` que apunte a tus Pods.
3. Verifica que el Service ha encontrado los Pods (**endpoints**).
4. Accede a la API **desde dentro** del cluster, usando el nombre DNS.
5. Accede **desde tu navegador** con `port-forward` en el puerto 8090.

### Pista

Un Service no "contiene" Pods ni los referencia por nombre: los encuentra
**en tiempo real** buscando cuáles tienen las labels indicadas en
`spec.selector`. Por eso el campo más importante de todo el YAML es que ese
`selector` coincida con las `labels` del Deployment del Ejercicio 1. El
Service también tiene dos puertos distintos y es fácil confundirlos: `port`
(por donde se llama al Service) y `targetPort` (el puerto real del
contenedor, el mismo `containerPort` de antes).

### Guía paso a paso

1. Antes de escribir YAML, comprueba el problema que vas a resolver:
   `kubectl get pods -l app=api -o wide` dos veces, borrando un Pod entre
   medias, para ver que la IP cambia.
2. Escribe `03-service.yaml` con este esqueleto:

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: <nombre-del-service>
   spec:
     type: ClusterIP
     selector:
       app: <la-misma-label-que-usaste-en-el-deployment-del-ej-1>
     ports:
       - port: <puerto-para-llamar-al-service>
         targetPort: <containerPort-de-tu-contenedor>
   ```

3. Aplica y comprueba que **encontró** los Pods antes de probar nada más:
   `kubectl describe svc <nombre>` → mira la línea `Endpoints`. Si pone
   `<none>`, el `selector` no coincide con ninguna label: no sigas hasta
   arreglarlo.
4. Desde dentro del cluster, el nombre del Service **es** su DNS:
   `kubectl run curl-test --image=curlimages/curl -it --rm --restart=Never --
   curl -s http://<nombre-del-service>`.
5. Desde tu máquina: `kubectl port-forward svc/<nombre-del-service>
   8090:<port-del-service>`.

### Solución

<details>
<summary>Ver solución</summary>

```bash
# 1. IPs efímeras
kubectl get pods -l app=api -o wide     # apunta una IP
kubectl delete pod <ese-pod>
kubectl get pods -l app=api -o wide     # el nuevo tiene otra IP
```

`03-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: ClusterIP
  selector:
    app: api            # ¡DEBE coincidir con las labels de los Pods!
  ports:
    - port: 80          # puerto del Service
      targetPort: 8000  # puerto del contenedor
```

```bash
kubectl apply -f 03-service.yaml

# 3. ¿Ha encontrado los Pods?
kubectl get svc api
kubectl describe svc api        # mira "Endpoints": deben ser las IPs de tus Pods
kubectl get endpoints api

# 4. Desde DENTRO del cluster, por nombre DNS
kubectl run curl-test --image=curlimages/curl -it --rm --restart=Never -- curl -s http://api
# -> el JSON con las lecturas

# 5. Desde TU máquina
kubectl port-forward svc/api 8090:80
# Abre http://localhost:8090 en el navegador. Ctrl+C para cerrar el túnel.
```

</details>

### Validación

`http://localhost:8090` devuelve un JSON con lecturas de sensores. Recárgalo
varias veces: los datos cambian (son aleatorios) y las peticiones se reparten
entre los Pods.

### Rompe el selector (2 min, muy instructivo)

Cambia en `03-service.yaml` el selector a `app: apii` (con typo), aplica, y
ejecuta `kubectl get endpoints api`. Verás `<none>`: el Service existe, no da
ningún error, pero no apunta a nada. **Esta es la causa número uno de "mi
Service no funciona"**. Deshaz el cambio y vuelve a aplicar.

### Para pensar

- ¿Por qué el Service sigue funcionando aunque borres Pods y aparezcan otros
  con IPs nuevas?
- ¿Qué relación tiene el nombre del Service (`api`) con la forma en que los
  servicios se llaman entre sí en un `docker-compose.yml`?
- ¿Por qué `port-forward` funciona con un `ClusterIP`, que en teoría solo es
  accesible desde dentro del cluster?

---

# Descanso (10 min)

---

# Bloque 2 — Configuración y persistencia

## Ejercicio 3 ⭐ NÚCLEO — ConfigMap y Secret (15 min)

**Objetivo**: cambiar el comportamiento de tu aplicación **sin reconstruir ni
volver a publicar la imagen**.

**Por qué te importa**: la misma imagen tiene que servir para desarrollo,
preproducción y producción. Lo único que cambia es la configuración inyectada.

**Conceptos**: [§6](./TEORIA_KUBERNETES.md#6-configuración-configmaps-y-secrets)

### Tarea

1. Escribe `04-config.yaml` con un **ConfigMap** (`BATCH_SIZE`, `DB_HOST`,
   `POSTGRES_USER`, `POSTGRES_DB`) y un **Secret** (`POSTGRES_PASSWORD`).
   Los usaremos también en los ejercicios 4 y 5.
2. Modifica el Deployment para inyectarlos con `envFrom`.
3. Comprueba que las variables llegaron dentro del contenedor.
4. Cambia `BATCH_SIZE` a 20, aplica, y comprueba el efecto en la API.
5. Demuestra que un Secret **no está cifrado**.

### Pista

Un ConfigMap es literalmente un diccionario `clave: "valor"` bajo `data`. Un
Secret es igual, solo que su bloque se llama `stringData` (para que puedas
escribir el valor en texto plano y que Kubernetes lo pase a base64 por ti).
Ninguno de los dos "hace" nada por sí solo: hay que decirle al contenedor que
los lea, con `envFrom` dentro del mismo `containers[].` donde ya tienes
`image` y `ports` en `02-deployment.yaml`. Y como los procesos leen sus
variables de entorno **una sola vez, al arrancar**, cambiar el ConfigMap no
basta: hay que forzar a los Pods a reiniciarse.

### Guía paso a paso

1. Escribe `04-config.yaml` con dos documentos separados por `---`:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: <nombre-libre>
   data:
     BATCH_SIZE: "<numero-entre-comillas>"
     DB_HOST: "<nombre-del-service-de-postgres-que-usarás-en-el-ej-4>"
     POSTGRES_USER: "<usuario>"
     POSTGRES_DB: "<nombre-bd>"
   ---
   apiVersion: v1
   kind: Secret
   metadata:
     name: <nombre-libre>
   type: Opaque
   stringData:
     POSTGRES_PASSWORD: "<contraseña-en-texto-plano>"
   ```

2. Edita `02-deployment.yaml` del Ejercicio 1: dentro del contenedor `api`,
   al mismo nivel que `image` y `ports`, añade:

   ```yaml
           envFrom:
             - configMapRef:
                 name: <el-name-del-configmap-de-arriba>
             - secretRef:
                 name: <el-name-del-secret-de-arriba>
   ```

3. `kubectl apply -f 04-config.yaml && kubectl apply -f 02-deployment.yaml`,
   luego `kubectl exec deploy/<nombre> -- env | grep -E "BATCH_|POSTGRES_|DB_"`
   para confirmar que llegaron.
4. `kubectl edit configmap <nombre>` para subir `BATCH_SIZE`, y
   `kubectl rollout restart deployment <nombre>` — este comando es el que
   fuerza a los Pods a releer la configuración.
5. `kubectl get secret <nombre> -o jsonpath='{.data.POSTGRES_PASSWORD}' |
   base64 -d` para ver la contraseña en claro.

### Solución

<details>
<summary>Ver solución</summary>

`04-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  BATCH_SIZE: "5"
  DB_HOST: "postgres"
  POSTGRES_USER: "datos"
  POSTGRES_DB: "datos"
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  POSTGRES_PASSWORD: "contrasena_de_clase"
```

En `02-deployment.yaml`, añade `envFrom` al contenedor:

```yaml
        - name: api
          image: TU_USUARIO/mi-pipeline:1.0
          ports:
            - containerPort: 8000
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: db-secret
```

```bash
kubectl apply -f 04-config.yaml
kubectl apply -f 02-deployment.yaml

# 3. ¿Llegaron las variables?
kubectl exec deploy/api -- env | grep -E "BATCH_|POSTGRES_|DB_"

# 4. Cambiar la configuración sin tocar la imagen
kubectl edit configmap app-config       # cambia BATCH_SIZE a "20"
kubectl rollout restart deployment api  # los Pods releen la config al reiniciar
kubectl port-forward svc/api 8090:80
# -> ahora el JSON trae 20 lecturas en vez de 5

# 5. Un Secret NO está cifrado
kubectl get secret db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
# -> contrasena_de_clase, en texto plano
```

</details>

### Validación

La API devuelve 20 registros en vez de 5, sin haber reconstruido ni
republicado la imagen.

### Para pensar

- ¿Por qué hace falta `kubectl rollout restart` después de cambiar el
  ConfigMap? (Pista: ¿cuándo lee un proceso sus variables de entorno?)
- Si un Secret solo está en base64, ¿qué aporta realmente frente a un
  ConfigMap? ¿Dónde meterías una contraseña de producción de verdad?
- ¿A qué se parece esto de la sesión de Docker: al `-e`, al `.env`, o a los
  dos?

---

## Ejercicio 4 ⭐⭐ NÚCLEO CLAVE — Postgres con almacenamiento persistente (20 min)

**Objetivo**: desplegar una base de datos real cuyos datos **sobreviven** a la
destrucción del Pod.

**Por qué te importa**: es el Ejercicio 3 del bloque de Docker (volúmenes con
nombre), pero en Kubernetes. Y es la pieza sobre la que se apoya el pipeline
del ejercicio siguiente.

**Conceptos**: [§7](./TEORIA_KUBERNETES.md#7-almacenamiento-volúmenes-pv-y-pvc),
[§8.1](./TEORIA_KUBERNETES.md#81-probes--está-sana-tu-app)

### Tarea

1. Escribe `05-postgres.yaml` con tres objetos: un **PersistentVolumeClaim**
   de 1 Gi, un **Deployment** de `postgres:18-alpine` que use el PVC y las
   credenciales del ConfigMap/Secret, y un **Service** llamado `postgres`.
2. Añade una **readiness probe** con `pg_isready`.
3. Crea una tabla con datos.
4. **Borra el Pod de Postgres.** Cuando Kubernetes lo reponga, comprueba que
   tus datos siguen ahí.

> ⚠️ Igual que en Docker: en PostgreSQL 18 la ruta de datos es
> `/var/lib/postgresql`, no `/var/lib/postgresql/data`.

### Pista

Este ejercicio junta tres objetos en un solo archivo, pero cada uno ya lo has
visto: el PVC es solo una "solicitud de disco" (`accessModes` +
`resources.requests.storage`); el Deployment es el mismo patrón del
Ejercicio 1 pero con un `volumeMounts` dentro del contenedor y un `volumes` al
nivel de `spec.template.spec` que los conecta por `name`; y el Service es
idéntico al del Ejercicio 2, apuntando ahora al puerto 5432. El PVC no se
"inyecta" solo: el nombre en `volumes[].persistentVolumeClaim.claimName` debe
ser exactamente el `metadata.name` del PVC.

### Guía paso a paso

1. El PVC, la pieza más pequeña:

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: <nombre-libre>
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: <cantidad, ej. 1Gi>
   ```

2. El Deployment de Postgres. Fíjate en las **dos** referencias cruzadas:
   `volumeMounts[].name` debe coincidir con `volumes[].name` (no con el PVC),
   y `volumes[].persistentVolumeClaim.claimName` debe coincidir con el
   `metadata.name` del PVC del paso 1.

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: <nombre-libre>
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: <etiqueta>
     template:
       metadata:
         labels:
           app: <misma-etiqueta>
       spec:
         containers:
           - name: <...>
             image: postgres:18-alpine
             ports:
               - containerPort: 5432
             envFrom:
               - configMapRef:
                   name: <el-configmap-del-ej-3>
               - secretRef:
                   name: <el-secret-del-ej-3>
             volumeMounts:
               - name: <nombre-de-enlace-con-volumes>
                 mountPath: /var/lib/postgresql
             readinessProbe:
               exec:
                 command: ["pg_isready", "-U", "<mismo-POSTGRES_USER-del-configmap>"]
               initialDelaySeconds: 5
               periodSeconds: 5
         volumes:
           - name: <mismo-nombre-de-enlace-de-arriba>
             persistentVolumeClaim:
               claimName: <name-del-pvc-del-paso-1>
   ```

3. El Service, calcado del Ejercicio 2 pero sin `port-forward` (no lo
   necesitas: solo lo usarán otros Pods del cluster):

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: <debe-coincidir-con-el-DB_HOST-que-pusiste-en-el-configmap>
   spec:
     selector:
       app: <misma-etiqueta-del-deployment-de-postgres>
     ports:
       - port: 5432
         targetPort: 5432
   ```

4. Aplica y espera: `kubectl get pvc` (de `Pending` a `Bound`) y
   `kubectl get pods -l app=<etiqueta>` (a `1/1 Running`). Si el PVC se queda
   en `Pending`, revisa el Apéndice de errores al final del documento.
5. Crea una fila con `kubectl exec -it deploy/<nombre> -- psql -U <usuario>
   -d <bd> -c "CREATE TABLE prueba(id INT, nota TEXT); INSERT INTO prueba
   VALUES (1, 'sobrevive?');"`, borra el Pod (`kubectl delete pod -l
   app=<etiqueta>`) y repite el `SELECT` cuando el nuevo esté listo.

### Solución

<details>
<summary>Ver solución</summary>

`05-postgres.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
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
          ports:
            - containerPort: 5432
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: db-secret
          volumeMounts:
            - name: datos
              mountPath: /var/lib/postgresql
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "datos"]
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              memory: "512Mi"
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
      targetPort: 5432
```

```bash
kubectl apply -f 05-postgres.yaml
kubectl get pvc                   # debe pasar de Pending a Bound
kubectl get pods -l app=postgres  # espera a 1/1 Running

# 3. Crear datos
kubectl exec -it deploy/postgres -- psql -U datos -d datos -c \
  "CREATE TABLE prueba(id INT, nota TEXT); INSERT INTO prueba VALUES (1, 'sobrevive?');"

# 4. Destruir el Pod
kubectl delete pod -l app=postgres
kubectl get pods -l app=postgres -w     # espera a que el nuevo esté 1/1 Running

kubectl exec -it deploy/postgres -- psql -U datos -d datos -c "SELECT * FROM prueba;"
# -> 1 | sobrevive?
```

</details>

### Validación

Tras borrar el Pod, el nuevo Pod devuelve la fila `1 | sobrevive?`.
`kubectl get pvc` muestra `postgres-pvc` en estado `Bound`.

### Para pensar

- El Pod es nuevo, con otra IP y otro nombre. ¿Dónde estaban físicamente los
  datos mientras no existía ningún Pod?
- ¿Por qué `replicas: 1` y no 3, como en la API? ¿Qué pasaría con 3 réplicas
  de Postgres apuntando al mismo PVC?
- La readiness probe usa `pg_isready` en vez de una petición HTTP. ¿Por qué?
- ¿Qué relación tiene el PVC con el *named volume* del Ejercicio 3 de Docker?

---

# Bloque 3 — El pipeline completo

## Ejercicio 5 ⭐⭐⭐ EL EJERCICIO DE LA SESIÓN — Tu pipeline en producción (30 min)

**Objetivo**: poner en marcha un proceso **programado** que genera datos y los
carga en la base de datos, automáticamente, cada pocos minutos.

**Por qué te importa**: esto es, en miniatura, exactamente lo que hace un
pipeline de datos en producción. Al terminar este ejercicio tendrás corriendo
sobre Kubernetes: almacenamiento persistente, configuración externalizada,
secretos, una API que sirve datos y un proceso batch programado. **Un sistema
completo, no un ejemplo de juguete.**

**Conceptos**: [§9](./TEORIA_KUBERNETES.md#9-cargas-por-lotes-job-y-cronjob)

### Tarea

1. Escribe `06-job.yaml`: un **Job** que ejecute `pipeline.py` una sola vez
   contra Postgres. Compruébalo.
2. Verifica que las filas llegaron a la tabla `lecturas`.
3. Escribe `07-cronjob.yaml`: un **CronJob** que haga lo mismo **cada 2
   minutos**.
4. Observa cómo van apareciendo Jobs nuevos y cómo crece la tabla.
5. Lanza una ejecución manual del CronJob sin esperar al horario.

### Pista

Un Job es casi un Deployment sin `replicas` ni self-healing continuo: en vez
de "mantener siempre N Pods vivos", su contrato es "ejecuta esto hasta que
termine con éxito". Por eso lleva `restartPolicy: OnFailure` en vez de nada
(el valor por defecto, `Always`, no tendría sentido para algo que debe
acabar). El `command` es lo único realmente nuevo: sobrescribe el `CMD` de tu
imagen para que, en vez de arrancar `api.py`, ejecute `pipeline.py`. El
CronJob no es un objeto distinto: es un Job envuelto en un `jobTemplate` con
un `schedule` delante.

### Guía paso a paso

1. `06-job.yaml` — parte del contenedor que ya conoces del Ejercicio 3/4 y
   cambia solo tres cosas: quita `ports`, añade `command`, y envuélvelo en
   `spec.template.spec` con `restartPolicy: OnFailure`:

   ```yaml
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: <nombre-libre>
   spec:
     backoffLimit: <cuantos-reintentos-si-falla>
     template:
       spec:
         restartPolicy: OnFailure
         containers:
           - name: <...>
             image: <TU_USUARIO/mi-pipeline:1.0>
             command: ["python", "pipeline.py"]
             envFrom:
               - configMapRef:
                   name: <el-configmap-del-ej-3>
               - secretRef:
                   name: <el-secret-del-ej-3>
   ```

2. Aplica, y sigue la pista de siempre: `kubectl logs job/<nombre>` antes de
   ir a mirar la base de datos. Si falla, casi siempre es `DB_HOST` mal o
   Postgres no listo todavía (revisa el Apéndice de errores).
3. `07-cronjob.yaml` — coge el `spec` entero del Job del paso 1 y méetelo tal
   cual dentro de `jobTemplate.spec`, añadiendo `schedule` al nivel de arriba:

   ```yaml
   apiVersion: batch/v1
   kind: CronJob
   metadata:
     name: <nombre-libre>
   spec:
     schedule: "<expresión cron, ej. */2 * * * * = cada 2 min>"
     successfulJobsHistoryLimit: <cuantos Jobs completados conservar>
     failedJobsHistoryLimit: <cuantos Jobs fallidos conservar>
     jobTemplate:
       spec:
         backoffLimit: <...>
         template:
           spec:
             restartPolicy: OnFailure
             containers:
               - name: <...>
                 image: <...>
                 command: ["python", "pipeline.py"]
                 envFrom:
                   - configMapRef:
                       name: <...>
                   - secretRef:
                       name: <...>
   ```

4. `kubectl get jobs -w` y espera sin tocar nada: cada 2 minutos debe
   aparecer un Job nuevo solo.
5. Para no esperar: `kubectl create job --from=cronjob/<nombre-del-cronjob>
   <nombre-libre-para-esta-ejecución>`.

### Solución

<details>
<summary>Ver solución</summary>

`06-job.yaml` — nota el `command`, que sobrescribe el `CMD` de la imagen (la
misma imagen, otro punto de entrada):

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: carga-inicial
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: pipeline
          image: TU_USUARIO/mi-pipeline:1.0
          command: ["python", "pipeline.py"]
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: db-secret
```

```bash
kubectl apply -f 06-job.yaml
kubectl get jobs
kubectl get pods -l job-name=carga-inicial
kubectl logs job/carga-inicial
# -> OK: 20 filas insertadas en la tabla 'lecturas'

# 2. Comprobar en la base de datos
kubectl exec -it deploy/postgres -- psql -U datos -d datos -c \
  "SELECT count(*) FROM lecturas;"
kubectl exec -it deploy/postgres -- psql -U datos -d datos -c \
  "SELECT * FROM lecturas ORDER BY timestamp DESC LIMIT 5;"
```

`07-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pipeline-datos
spec:
  schedule: "*/2 * * * *"          # cada 2 minutos
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pipeline
              image: TU_USUARIO/mi-pipeline:1.0
              command: ["python", "pipeline.py"]
              envFrom:
                - configMapRef:
                    name: app-config
                - secretRef:
                    name: db-secret
              resources:
                requests:
                  cpu: "100m"
                  memory: "128Mi"
                limits:
                  memory: "512Mi"
```

```bash
kubectl apply -f 07-cronjob.yaml
kubectl get cronjobs
kubectl get jobs -w                 # espera: cada 2 min aparece uno nuevo

# 5. Sin esperar: lanzar una ejecución manual
kubectl create job --from=cronjob/pipeline-datos ejecucion-manual

# 4. Ver crecer la tabla
kubectl exec -it deploy/postgres -- psql -U datos -d datos -c \
  "SELECT count(*) AS filas, max(timestamp) AS ultima FROM lecturas;"
```

</details>

### Validación

Ejecuta el `count(*)` dos veces separadas por unos minutos: el número de filas
**ha crecido solo**, sin que tú hayas hecho nada. Tienes un proceso
programado corriendo en un cluster de Kubernetes.

### Lo que acabas de construir

```
    ┌──────────────────── Cluster de Kubernetes ────────────────────┐
    │                                                                 │
    │   CronJob "pipeline-datos"                                      │
    │   (cada 2 min)                                                  │
    │        │ crea                                                   │
    │        ▼                                                        │
    │   ┌─────────┐   escribe    ┌──────────────┐    ┌────────────┐  │
    │   │   Job    │ ──────────► │  Service      │───►│ Deployment  │ │
    │   │ pipeline │             │  "postgres"   │    │  postgres   │ │
    │   └─────────┘             └──────────────┘    └──────┬─────┘  │
    │        ▲                                              │        │
    │        │ config                                       ▼        │
    │   ┌────┴──────────────┐                        ┌────────────┐  │
    │   │ ConfigMap + Secret│                        │    PVC      │ │
    │   └───────────────────┘                        │ (persiste)  │ │
    │        │                                       └────────────┘  │
    │        ▼                                                        │
    │   ┌──────────┐      ┌──────────────┐                           │
    │   │Deployment│ ◄─── │   Service     │ ◄─── kubectl port-forward │
    │   │   api    │      │    "api"      │           :8090           │
    │   │ (3 pods) │      └──────────────┘                           │
    │   └──────────┘                                                  │
    └─────────────────────────────────────────────────────────────────┘
```

Compáralo con el `docker-compose.yml` del proyecto de Airflow: son las mismas
piezas conceptuales (base de datos + almacenamiento + configuración + servicio
web + tareas programadas), pero ahora con self-healing, escalado y
programación gestionados por el cluster.

### Para pensar

- Un Job usa `restartPolicy: OnFailure` y un Deployment nunca lleva esa clave.
  ¿Por qué? ¿Qué pasaría si desplegaras `pipeline.py` como un Deployment?
- Los Jobs terminados se quedan en `Completed` en vez de borrarse. ¿Por qué
  crees que Kubernetes los conserva? ¿Qué hace `successfulJobsHistoryLimit`?
- **La pregunta importante**: si Kubernetes ya sabe programar tareas con
  CronJob, ¿para qué sirve entonces Airflow? (Ver
  [§9.3](./TEORIA_KUBERNETES.md#93-y-entonces-para-qué-sirve-airflow))
- ¿Qué pasaría si Postgres estuviera caído cuando el CronJob se dispara?
  ¿Quién lo reintenta?

---

## Ejercicio 6 (opcional) — Rolling update y rollback (10 min)

**Objetivo**: actualizar la versión de tu aplicación sin cortar el servicio, y
volver atrás si algo sale mal.

**Conceptos**: [§4.3](./TEORIA_KUBERNETES.md#43-deployment--lo-que-usarás-siempre)

### Tarea

1. Publica una versión `1.1` de tu imagen (cambia algo visible en
   `generador.py`, por ejemplo añade una columna).
2. Actualiza el Deployment de la API a esa versión y observa el rollout.
3. Comprueba el historial y haz **rollback**.
4. Provoca un fallo: despliega una imagen que no existe. Observa qué pasa.

### Pista

Aquí no escribes YAML nuevo: reutilizas el Deployment `api` del Ejercicio 1 y
lo modificas con comandos. La clave es `kubectl set image
deployment/<nombre> <nombre-del-contenedor>=<nueva-imagen>` — el
`<nombre-del-contenedor>` es el que pusiste en `containers[].name`, no el
nombre del Deployment. Kubernetes sustituye los Pods **de uno en uno**
(rolling update) para no dejar nunca el servicio a cero.

### Guía paso a paso

1. Cambia algo pequeño y visible en `generador.py` (por ejemplo, añade una
   columna nueva al DataFrame) y publica `TU_USUARIO/mi-pipeline:1.1`.

   > **Sin Docker Hub**: construye `mi-pipeline:1.1` sin prefijo de usuario y
   > cárgala directamente con `minikube image load mi-pipeline:1.1` — no
   > hace falta `docker push` para que el cluster la vea.

2. `kubectl set image deployment/<nombre-deployment>
   <nombre-contenedor>=TU_USUARIO/mi-pipeline:1.1` y sigue el proceso con
   `kubectl rollout status deployment/<nombre>` y `kubectl get pods -l
   app=api -w` en paralelo.
3. `kubectl rollout history deployment/<nombre>` para ver las revisiones, y
   `kubectl rollout undo deployment/<nombre>` para volver a la anterior.
4. Repite el paso 2 pero con una imagen que no exista
   (`TU_USUARIO/mi-pipeline:99.99`) y compara `kubectl get pods` con lo que
   sirve `http://localhost:8090` mientras tanto. Deshaz con `rollout undo`.

### Solución

<details>
<summary>Ver solución</summary>

```bash
# 1. Nueva versión
cd app && docker build -t TU_USUARIO/mi-pipeline:1.1 . && docker push TU_USUARIO/mi-pipeline:1.1

# 2. Rolling update
kubectl set image deployment/api api=TU_USUARIO/mi-pipeline:1.1
kubectl rollout status deployment/api
kubectl get pods -l app=api -w    # los Pods se sustituyen de uno en uno

# 3. Historial y vuelta atrás
kubectl rollout history deployment/api
kubectl rollout undo deployment/api
kubectl rollout status deployment/api

# 4. Un despliegue roto
kubectl set image deployment/api api=TU_USUARIO/mi-pipeline:99.99
kubectl get pods -l app=api
# -> el Pod nuevo se queda en ImagePullBackOff...
# -> ...pero los Pods VIEJOS siguen sirviendo tráfico. Cero downtime.
kubectl rollout undo deployment/api
```

</details>

### Validación

Durante el `rollout status`, el número de Pods disponibles nunca llega a 0. Y
con la imagen inexistente, la API sigue respondiendo en `localhost:8090`.

### Para pensar

- ¿Por qué el despliegue roto no tumbó el servicio? ¿Qué mecanismo lo impidió?
- ¿Qué papel jugaría aquí una **readiness probe** bien configurada en la API?

---

# Cierre y limpieza (15 min)

### Repaso: de Docker a Kubernetes

| Lo que hiciste en Docker | Lo que has hecho hoy |
|---|---|
| `docker run` de tu imagen | Deployment con 3 réplicas y self-healing |
| `-p 8080:8080` | Service + `port-forward` |
| `-e VAR=valor` / `.env` | ConfigMap + Secret |
| Volumen con nombre para Postgres | PersistentVolumeClaim |
| `healthcheck:` en Compose | readiness probe con `pg_isready` |
| Publicar la imagen en Docker Hub | La misma imagen, desplegada en un cluster |
| Ejecutar el script a mano | CronJob que lo ejecuta solo cada 2 minutos |

### Siguientes pasos naturales

- **Helm** — empaquetar todos estos YAML como una plantilla reutilizable y
  parametrizable. Es como pasar de scripts sueltos a un paquete instalable.
- **GitOps (Argo CD, Flux)** — que el cluster se sincronice automáticamente
  con lo que haya en un repositorio de Git. El `kubectl apply` desaparece.
- **Airflow sobre Kubernetes** — con el `KubernetesPodOperator`, cada tarea de
  un DAG se ejecuta como un Pod. Es la arquitectura estándar en producción y
  la unión directa de las dos sesiones que has hecho.
- **Clusters gestionados** — EKS (AWS), GKE (Google), AKS (Azure). Lo que has
  hecho hoy en minikube funciona igual allí; cambia el `kubeconfig`, no los
  manifiestos.

### Limpieza

```bash
# Borrar todo lo que has creado
kubectl delete -f .

# El PVC no se borra con lo anterior si lo creaste aparte: compruébalo
kubectl get pvc
kubectl delete pvc postgres-pvc

# Apagar el cluster (conserva el estado para otro día)
minikube stop

# O borrarlo entero
minikube delete
```

---

## Apéndice — Errores más frecuentes en esta sesión

| Síntoma | Causa | Solución |
|---|---|---|
| `ImagePullBackOff` en el Ejercicio 1 | No sustituiste `TU_USUARIO`, o la imagen no está publicada | Revisa el nombre; `docker push` de nuevo; o `minikube image load` |
| Los Pods de Postgres no pasan de `0/1` | La readiness probe falla porque el usuario no coincide | El `-U` de `pg_isready` debe ser el mismo `POSTGRES_USER` del ConfigMap |
| PVC en `Pending` para siempre | minikube sin StorageClass | `kubectl get sc` → debe existir `standard`. Reinicia minikube si no |
| El Job falla con error de conexión | Postgres aún no estaba listo, o `DB_HOST` mal | Es normal en el primer intento: el `backoffLimit` reintenta. Revisa `kubectl logs job/<nombre>` |
| `kubectl exec` a Postgres da error de autenticación | El Secret y el ConfigMap no coinciden con lo que espera el pipeline | Compara `kubectl get cm app-config -o yaml` con lo que lee `pipeline.py` |
| `port-forward` se cae solo | Es normal si el Pod se recrea | Vuelve a lanzarlo; usa `svc/api` en vez de un Pod concreto |
| Todo va lentísimo | minikube sin recursos | `minikube stop && minikube start --memory=6144 --cpus=4` |
