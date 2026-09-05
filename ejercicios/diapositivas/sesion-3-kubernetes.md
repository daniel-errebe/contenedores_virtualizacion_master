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

## Sesión 3 — Del contenedor al cluster

Máster en Data Engineering, MLOps & Arquitectura Cloud

---

# Dónde estamos

## Compose orquesta contenedores en una máquina. Hoy vemos qué pasa cuando hay muchas

| Sesión | Contenido | Estado |
|---|---|---|
| 1 | Imágenes y contenedores | Hecha |
| 2 | Docker Compose | Hecha |
| **3. Hoy** | **Kubernetes: del contenedor al cluster** | |

<div class="aviso">

Kubernetes **no sustituye** a Docker ni a Compose. Seguirás usando Compose todos los días
en tu portátil. Kubernetes es lo que corre debajo cuando tu pipeline sale a producción.

</div>

---

# El objetivo de hoy

## En 2 h 30 vas a desplegar un pipeline completo sobre un cluster

<div class="pasos">
<div><b>01</b><span>Leer y escribir cualquier manifiesto YAML de Kubernetes</span></div>
<div><b>02</b><span>Desplegar una app con Deployment y exponerla con un Service</span></div>
<div><b>03</b><span>Separar la configuración de la imagen con ConfigMaps y Secrets</span></div>
<div><b>04</b><span>Montar almacenamiento que sobreviva a la muerte de un Pod</span></div>
<div><b>05</b><span>Programar un proceso por lotes con CronJob — tu pan de cada día</span></div>
</div>

---

# Contenido de la sesión

## Cuatro bloques, seis ejercicios

<div class="cols">
<div>

**0.** Arrancar el cluster y orientarse
**1.** Pods, Deployments y el *self-healing*
  → *Ejercicio 1*
**2.** Services y red interna
  → *Ejercicio 2*
**3.** Configuración: ConfigMap y Secret
  → *Ejercicio 3*

</div>
<div>

**4.** Persistencia: PV y PVC
  → *Ejercicio 4*
**5.** Job y CronJob: el pipeline completo
  → *Ejercicio 5*
**6.** Rolling update y rollback
  → *Ejercicio 6 (opcional)*

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">1</div>
<div class="reloj">≈ 0:00</div>

# ¿Por qué Kubernetes?

## Todo esto se puede resolver con scripts, cron y mucha paciencia. Pero es frágil y no escala.

---

# Tu `docker-compose.yml` funciona. En tu portátil.

## Cinco preguntas que no tienen respuesta con Compose

<div class="pasos">
<div><b>01</b><span>El servidor se reinicia a las 3 de la mañana. ¿Quién arranca los contenedores? ¿Y quién te avisa?</span></div>
<div><b>02</b><span>Airflow se queda colgado: vivo, pero sin responder. <code>docker ps</code> dice <code>Up</code>. ¿Quién detecta que está roto?</span></div>
<div><b>03</b><span>Necesitas 10 workers en lugar de 2 por un pico nocturno. ¿Y a las 6:00 los apagas a mano?</span></div>
<div><b>04</b><span>Tienes 20 servidores. ¿Quién decide en cuál cabe cada contenedor?</span></div>
<div><b>05</b><span>Quieres pasar de Airflow 3.3.1 a 3.3.2 <b>sin cortar el servicio</b>.</span></div>
</div>

---

<!-- _class: denso -->

# Compose y Kubernetes resuelven cosas distintas

## Ninguno sustituye al otro

| | Docker Compose | Kubernetes |
|---|---|---|
| **Alcance** | Una máquina | Un cluster de N máquinas |
| **Si un contenedor muere** | Se queda muerto (salvo `restart:`) | Se repone automáticamente |
| **Si la máquina muere** | Se cae todo | Los Pods se recolocan en otro nodo |
| **Escalar** | Limitado | `kubectl scale` o automático (HPA) |
| **Actualizar sin corte** | No | Sí: rolling update con rollback |
| **¿Detecta apps colgadas?** | Healthchecks básicos | Probes: liveness, readiness, startup |
| **Complejidad** | Baja, un archivo | Alta, muchos objetos |
| **Cuándo** | Desarrollo local, demos, CI | Producción |

---

<!-- _class: lima -->

# La idea central: pasas de dar órdenes a describir un estado

## Si te llevas solo una cosa de hoy, que sea esta

<div class="cols">
<div>

### Docker: imperativo

```bash
docker run -d --name web nginx
```

*"Arranca este contenedor ahora."*

Si alguien lo mata, se queda muerto. Docker hizo lo que le pediste y ya está.

</div>
<div>

### Kubernetes: declarativo

```yaml
replicas: 3
```

*"Quiero que siempre haya 3 copias."*

No se ejecuta una vez: se comprueba **constantemente**.

</div>
</div>

---

# El bucle de reconciliación

## El corazón del sistema, y la razón de que los Pods "resuciten" solos

<pre class="diagrama">
      ┌───────────────────────────────────────────┐
      │                                           │
      ▼                                           │
┌──────────────┐    ¿coinciden?    ┌──────────────┐
│   ESTADO     │ ───────X────────► │   ESTADO     │
│   DESEADO    │                   │   REAL       │
│  (tu YAML)   │ ◄──── actúa ───── │ (el cluster) │
└──────────────┘   para corregir   └──────────────┘
      │                                           │
      └──────────── cada pocos segundos ──────────┘
</pre>

<div class="aviso">

Si borras un Pod, en segundos aparece otro. No porque alguien lo mande,
sino porque el estado real dejó de coincidir con el deseado.

</div>

---

<!-- _class: seccion -->

<div class="num">0</div>
<div class="reloj">≈ 0:00</div>

# Arrancar el cluster

## Veinte minutos para orientarse. Si algo falla, se resuelve aquí y no a mitad del ejercicio 1.

---

<!-- _class: navy -->

# Bloque 0 — Arranca y orientate

## <span class="pill">20 min</span> Comprueba el cluster antes de tocar nada

<div class="cols-58">
<div>

```bash
$ minikube start --driver=docker \
    --memory=4096 --cpus=2
$ minikube status

$ kubectl get nodes -o wide
$ kubectl get namespaces
$ kubectl get pods -n kube-system
```

</div>
<div>

### Fíjate en `kube-system`

Ahí corren, **como Pods**, `etcd`, `kube-apiserver`, `kube-scheduler`, `coredns`…

Kubernetes se ejecuta a sí mismo sobre Kubernetes.

### Checkpoint

`kubectl get nodes` muestra un nodo `Ready`.

</div>
</div>

---

# Qué hay dentro de un cluster

## No hace falta memorizarlo. Sí saber a quién culpar cuando algo se atasca

<pre class="diagrama">
┌─────────────── CONTROL PLANE (el cerebro) ────────────────┐
│  ┌────────────┐  ┌────────┐  ┌───────────┐  ┌──────────┐  │
│  │ API server │  │  etcd  │  │ Scheduler │  │Controller│  │
│  │ (la puerta)│  │(memoria)│ │  (coloca) │  │ manager  │  │
│  └─────┬──────┘  └────────┘  └───────────┘  └──────────┘  │
└────────┼───────────────────────────────────────────────────┘
  kubectl│apply
    ┌────┴──────────────┬────────────────────┐
    ▼                   ▼                    ▼
┌─────────┐        ┌─────────┐         ┌─────────┐
│ NODO 1  │        │ NODO 2  │         │ NODO 3  │
│ kubelet │        │ kubelet │         │ kubelet │
│[Pod][Pod]        │ [Pod]   │         │[Pod][Pod]
└─────────┘        └─────────┘         └─────────┘
</pre>

<div class="aviso">

Un Pod atascado en `Pending` para siempre = el **scheduler** no encuentra sitio. Falta CPU o memoria.

</div>

---

# Nodos y namespaces: dónde acaba tu Pod

## Los nodos son máquinas de verdad. Los namespaces, solo una forma de no pisarse los nombres.

<div class="cols">
<div>

### Nodo — división física

Una máquina, con su CPU y su RAM. Tú **no eliges** en cuál cae tu Pod: lo decide el scheduler según lo que pidas en `resources`.

```bash
$ kubectl get nodes
$ kubectl get pods -o wide   # columna NODE
```

En minikube hay uno. En producción, decenas.

</div>
<div>

### Namespace — división lógica

Una carpeta, no una máquina. `dev` y `prod` conviven en los **mismos** nodos sin colisionar.

```bash
$ kubectl get pods -n produccion
$ kubectl get pods -A       # todos
```

Dos Services llamados `postgres` pueden existir a la vez si están en namespaces distintos.

</div>
</div>

<div class="aviso">

El namespace va dentro del DNS: `postgres` funciona **dentro** del tuyo. Desde otro tendrías
que escribir `postgres.produccion.svc.cluster.local`.

</div>

---

<!-- _class: seccion -->

<div class="num">2</div>
<div class="reloj">≈ 0:20</div>

# Manifiestos YAML

## Todo en Kubernetes se describe con la misma estructura de cuatro campos. Apréndela una vez.

---

<!-- _class: lima -->

# Los cuatro campos de cualquier manifiesto

## Da igual que sea un Pod, un Service o un CronJob

```yaml
apiVersion: apps/v1     # 1. Versión de la API que define este tipo de objeto
kind: Deployment        # 2. QUÉ tipo de objeto es
metadata:               # 3. Cómo se llama y cómo se etiqueta
  name: mi-app
  labels:
    app: mi-app
spec:                   # 4. QUÉ quieres que exista (el estado deseado)
  replicas: 3
```

| `apiVersion` | Para qué objetos |
|---|---|
| `v1` | Pod, Service, ConfigMap, Secret, PersistentVolumeClaim |
| `apps/v1` | Deployment, ReplicaSet, StatefulSet |
| `batch/v1` | Job, CronJob |

---

<!-- _class: navy -->

# Antes de escribir el primero: el YAML muerde

## Hoy vas a perder más tiempo con espacios que con Kubernetes

<div class="cols">
<div>

### Las tres reglas

**1.** Espacios, **nunca tabuladores**. Un tab es un error de sintaxis, sin más.

**2.** La indentación *es* la estructura. Dos espacios de más y el campo cuelga de otro sitio.

**3.** El guion `-` abre un elemento de lista. `containers:` lleva lista; `metadata:` no.

</div>
<div>

### Cuando no cuadre

```bash
# ¿Es válido, sin aplicarlo?
$ kubectl apply -f pod.yaml \
    --dry-run=client

# ¿Cómo lo ha entendido el cluster?
$ kubectl get pod mi-app -o yaml
```

Configura tu editor: dos espacios por tabulador y mostrar espacios en blanco.

</div>
</div>

<div class="aviso">

`error validating data: unknown field "..."` casi nunca significa que el campo no exista.
Significa que **está colgando del sitio equivocado**.

</div>

---

# Labels y selectors: el pegamento de Kubernetes

## Los objetos no se referencian por nombre, sino por etiqueta

<pre class="diagrama">
    Deployment                          Service
    selector:                           selector:
      app: mi-app                         app: mi-app
         │                                    │
         │  crea Pods con                     │  busca Pods con
         │  labels: app=mi-app                │  labels: app=mi-app
         ▼                                    ▼
    ┌─────────────────────────────────────────────────┐
    │  [Pod]        [Pod]        [Pod]                │
    │  app=mi-app   app=mi-app   app=mi-app           │
    └─────────────────────────────────────────────────┘
</pre>

<div class="aviso">

**Causa nº 1 de "mi Service no funciona"**: el `selector` no coincide con las `labels`.
Un typo y el Service se queda sin endpoints, en silencio.

</div>

---

<!-- _class: seccion -->

<div class="num">3</div>
<div class="reloj">≈ 0:25</div>

# Pod, ReplicaSet<br>y Deployment

## Tres objetos, pero en la práctica solo escribirás uno.

---

# El Pod es la unidad mínima, no el contenedor

## Uno o más contenedores que comparten IP y almacenamiento

<pre class="diagrama">
┌──────── Pod (IP: 10.244.1.7) ────────┐
│  ┌───────────────┐  ┌──────────────┐ │
│  │  contenedor   │  │  contenedor  │ │
│  │  principal    │  │  sidecar     │ │
│  │  (tu app)     │  │  (opcional)  │ │
│  └───────────────┘  └──────────────┘ │
│         ↕ se ven por localhost        │
│  ┌─────────────────────────────────┐ │
│  │  volúmenes compartidos          │ │
│  └─────────────────────────────────┘ │
└───────────────────────────────────────┘
</pre>

<div class="aviso">

En el **95 % de los casos** tendrás un solo contenedor por Pod.
Y **nunca crees Pods sueltos**: si mueren, nadie los repone. Igual que `docker run` sin `--restart`.

</div>

---

# Deployment: lo que usarás siempre

## Por encima del ReplicaSet, y añade lo que hace falta para operar de verdad

<pre class="diagrama">
   Deployment  "quiero 3 réplicas de mi-app:2.0"
        │
        ├── crea y gestiona ──► ReplicaSet (v2.0, 3 réplicas)
        │                            ├──► Pod
        │                            ├──► Pod
        │                            └──► Pod
        │
        └── al actualizar, crea un ReplicaSet nuevo y vacía
            el viejo poco a poco, sin cortar el servicio
</pre>

<div class="aviso">

El ReplicaSet existe, pero **no lo escribirás nunca a mano**. Lo gestiona el Deployment.

</div>

---

<!-- _class: denso -->

# Un Deployment mínimo

## Fíjate en la estructura de muñeca rusa

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 3
  selector:
    matchLabels:              # a qué Pods gestiona
      app: mi-app
  template:                   # la "plantilla" de Pod que va a crear
    metadata:
      labels:
        app: mi-app           # DEBE coincidir con el selector de arriba
    spec:
      containers:
        - name: app
          image: mi-usuario/mi-imagen:1.0
          ports:
            - containerPort: 8000
```

---

<!-- _class: navy -->

# Ejercicio 1 — Tu primer Pod y por qué nunca se usan solos

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> Escribe los dos manifiestos y mata un Pod dos veces

<div class="cols">
<div>

### Escribe `01-pod.yaml`

Un Pod suelto con tu imagen.

```bash
$ kubectl apply -f 01-pod.yaml
$ kubectl delete pod api-pod
$ kubectl get pods
# → no hay nada. Nadie lo repone.
```

</div>
<div>

### Escribe `02-deployment.yaml`

El mismo contenedor, con 3 réplicas.

```bash
$ kubectl apply -f 02-deployment.yaml
$ kubectl delete pod api-7d4b-x9
$ kubectl get pods
# → en segundos aparece uno nuevo
```

</div>
</div>

<div class="aviso">

Los manifiestos **los tecleas tú**, en `k8s-sandbox/`. Están resueltos en el enunciado, pero
escribirlos es lo que hace que se queden. Acabas de ver el bucle de reconciliación en acción.

</div>

---

<!-- _class: seccion -->

<div class="num">4</div>
<div class="reloj">≈ 0:40</div>

# Services y red interna

## Los Pods son efímeros y cambian de IP. Necesitas algo estable a lo que apuntar.

---

# El problema y la solución, en un diagrama

## Una IP estable y un nombre DNS fijo por delante de un grupo de Pods

<pre class="diagrama">
                     Service "postgres"
                  (IP fija + DNS: postgres)
                            │
              balancea entre los Pods que
              tengan la label app=postgres
                            │
           ┌────────────────┼────────────────┐
           ▼                ▼                ▼
        [Pod]            [Pod]            [Pod]
      10.244.1.7       10.244.2.3       10.244.1.9
       (cambia)         (cambia)         (cambia)
</pre>

---

<!-- _class: lima -->

# Y aquí está la continuidad con la sesión 2

## Es exactamente la misma idea que el DNS de Compose

```python
# En Docker Compose:  postgresql://usuario@postgres:5432/db
# En Kubernetes:      postgresql://usuario@postgres:5432/db
#                                          └── nombre del Service
```

<div class="destacado">

Dentro del cluster, el nombre del Service<br>funciona como hostname.

</div>

<div class="aviso">

Esa continuidad es intencionada. Si entendiste la red de Compose, ya entiendes los Services.

</div>

---

# Los tres tipos de Service

## Y cuál usarás de verdad

| Tipo | Alcance | Cuándo |
|---|---|---|
| **ClusterIP** *(por defecto)* | Solo dentro del cluster | Tu app ↔ tu base de datos. **El 90 % de los casos** |
| **NodePort** | Puerto fijo (30000–32767) en todos los nodos | Pruebas y clusters locales |
| **LoadBalancer** | Pide un balanceador al cloud | Exponer a internet en AWS/GCP/Azure |

<div class="aviso">

Para tráfico web con varios dominios o rutas existe el **Ingress**: enruta HTTP según el `Host`
o el `path`. No sustituye al Service, trabaja encima de él.

</div>

---

# `port-forward`: tu mejor amigo en local

## En minikube, más fiable que NodePort

```bash
kubectl port-forward svc/mi-app 8090:80
#                              │    │
#                              │    └── puerto del Service (dentro del cluster)
#                              └── puerto en TU máquina
```

<div class="aviso">

Abre un túnel temporal desde tu máquina al cluster. Funciona siempre, con cualquier tipo
de Service, sin tocar los manifiestos. Se corta con `Ctrl+C`.

Es el concepto del `-p` de `docker run`, pero como comando aparte y temporal.

</div>

---

<!-- _class: navy -->

# Ejercicio 2 — Services: acceder a tu aplicación

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> IPs efímeras, DNS estable

<div class="cols-58">
<div>

```bash
# 1. Comprueba que las IPs cambian
$ kubectl get pods -o wide
$ kubectl delete pod <uno>
$ kubectl get pods -o wide

# 2. ¿Ha encontrado el Service los Pods?
$ kubectl describe svc mi-app

# 3. Desde DENTRO, por nombre DNS
$ kubectl exec -it deploy/mi-app -- \
    curl http://mi-app

# 4. Desde TU máquina
$ kubectl port-forward svc/mi-app 8090:80
```

</div>
<div>

### Rompe el selector

<span class="pill">2 min</span>

Cambia una letra del `selector` del Service y vuelve a aplicar.

```bash
$ kubectl describe svc mi-app
# Endpoints: <none>
```

Ningún error. Solo deja de funcionar.

</div>
</div>

---

<!-- _class: navy -->

# Reto — diagnóstico a ciegas

## <span class="pill">5 min</span> <span class="pill">POR PAREJAS</span> Ahora rompe el manifiesto de tu compañero

<div class="cols-58">
<div>

```bash
# 1. Cada uno mete UN fallo en el YAML
#    del otro y lo aplica. Sin decir cuál.

# 2. El otro tiene dos minutos:
$ kubectl get pods
$ kubectl describe pod <nombre>
$ kubectl get endpoints <servicio>
$ kubectl logs <nombre>
```

</div>
<div>

### Fallos válidos

- Un typo en el `selector`
- Un `image:` que no existe
- Un `containerPort` que no coincide
- Un `replicas: 0`

### La regla

Se diagnostica **leyendo la salida**, no releyendo el YAML.

</div>
</div>

<div class="aviso">

Romper algo tú y arreglarlo no es depurar: ya sabes la respuesta. Esto se parece bastante más
a un martes por la mañana con un pipeline caído y sin ningún contexto.

</div>

---

<!-- _class: seccion -->

<div class="num">5</div>
<div class="reloj">≈ 1:10</div>

# Configuración:<br>ConfigMap y Secret

## En Docker viste que la configuración no va dentro de la imagen. Kubernetes formaliza esa idea.

---

# ConfigMap y Secret son el mismo objeto con distinta intención

## Uno para lo público, otro para lo sensible

<div class="cols">
<div>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "produccion"
  BATCH_SIZE: "1000"
  DB_HOST: "postgres"
```

</div>
<div>

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  POSTGRES_PASSWORD: "contrasena_segura"
```

`stringData` = texto plano; Kubernetes lo codifica solo.

</div>
</div>

```yaml
          envFrom:
            - configMapRef: { name: app-config }   # inyecta TODAS las claves
            - secretRef:    { name: db-secret }
```

---

<!-- _class: lima -->

# Un Secret no está cifrado

## Está codificado en base64, que es trivial de revertir

```bash
kubectl get secret db-secret \
  -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
# → contrasena_segura
```

<div class="aviso">

Un Secret protege frente a *"que aparezca por accidente en un log o en un `kubectl get -o yaml`"*,
**no frente a un atacante**. Para seguridad real: cifrado en reposo en etcd, RBAC, o un gestor
externo (Vault, AWS Secrets Manager, GCP Secret Manager).

**Y nunca, jamás, commitees un Secret con datos reales a Git.**

</div>

---

# Equivalencias con lo que ya sabes

## Nada de esto es nuevo, solo cambia el nombre

| Docker / Compose | Kubernetes |
|---|---|
| `-e VAR=valor` | ConfigMap + `envFrom` |
| Archivo `.env` | ConfigMap |
| Contraseñas en `.env` *(mala práctica)* | Secret *(algo mejor)* / Vault *(bien)* |
| `-v ./config.yml:/app/config.yml` | ConfigMap montado como volumen |

---

<!-- _class: navy -->

# Ejercicio 3 — ConfigMap y Secret

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Cambiar la configuración sin tocar la imagen

<div class="cols-58">
<div>

```bash
$ kubectl apply -f configmap.yaml
$ kubectl apply -f secret.yaml
$ kubectl rollout restart deploy/api

# ¿Llegaron las variables?
$ kubectl exec deploy/api -- env | grep BATCH

# Cambia BATCH_SIZE a 20 y reaplica
$ kubectl apply -f configmap.yaml
$ kubectl rollout restart deploy/api
# → ahora el JSON trae 20 lecturas
```

</div>
<div>

### Y comprueba esto

```bash
$ kubectl get secret db-secret \
  -o jsonpath='{.data.POSTGRES_PASSWORD}' \
  | base64 -d
```

### Para pensar

Has cambiado el comportamiento de la app **sin reconstruir la imagen**.
¿Por qué importa eso en un pipeline de CI?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">6</div>
<div class="reloj">≈ 1:25</div>

# Almacenamiento persistente

## En Docker los datos morían con el contenedor. En Kubernetes es peor: el Pod se recrea en otro nodo.

---

# Tres niveles de almacenamiento

## Para datos de verdad, siempre PV/PVC

| Tipo | Vive mientras… | Equivalente en Docker |
|---|---|---|
| **emptyDir** | …viva el Pod | Capa de escritura del contenedor |
| **hostPath** | …viva el nodo *(¡y solo ese nodo!)* | Bind mount |
| **PersistentVolume (PV)** | …tú no lo borres | Volumen con nombre |

<div class="aviso">

`hostPath` parece la traducción natural del bind mount, pero **evítalo**: ata el Pod
a un nodo concreto. Si el Pod se recoloca, los datos se quedan en la otra máquina.

</div>

---

<!-- _class: lima -->

# PV y PVC: dos objetos para una sola cosa

## La analogía de la reserva de mesa

<pre class="diagrama">
  PersistentVolumeClaim (PVC)          PersistentVolume (PV)
  "Necesito 5 GB de disco"      ───►   El disco real de 5 GB
  (lo escribes tú, en tu YAML)         (lo crea el cluster/cloud)

  Es como reservar mesa:               Es la mesa física
  tú pides, el restaurante asigna
</pre>

<div class="aviso">

**PVC** es lo único que escribes normalmente. El **PV** lo crea el proveedor: un disco EBS
en AWS, un Persistent Disk en GCP. En minikube, el propio cluster.

</div>

---

# Un PVC y su uso en el Pod

## Idéntico a un volumen de Docker, con más ceremonia

<div class="cols">
<div>

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
```

</div>
<div>

```yaml
      containers:
        - name: postgres
          volumeMounts:
            - name: datos
              mountPath: /var/lib/postgresql
      volumes:
        - name: datos
          persistentVolumeClaim:
            claimName: postgres-pvc
```

</div>
</div>

`ReadWriteOnce` = un solo nodo lo monta en escritura. Lo normal para bases de datos.

---

<!-- _class: navy -->

# Ejercicio 4 — Postgres con almacenamiento persistente

## <span class="pill">20 min</span> <span class="pill">NÚCLEO CLAVE</span> Destruye el Pod y comprueba que los datos siguen

<div class="cols-58">
<div>

```bash
$ kubectl apply -f postgres-pvc.yaml
$ kubectl apply -f postgres.yaml

# 1. Crear datos
$ kubectl exec -it deploy/postgres -- \
    psql -U datos -c \
    "CREATE TABLE t(v text); \
     INSERT INTO t VALUES ('sobrevive?');"

# 2. Destruir el Pod
$ kubectl delete pod -l app=postgres

# 3. Esperar y comprobar
$ kubectl exec -it deploy/postgres -- \
    psql -U datos -c "SELECT * FROM t;"
# → sobrevive?
```

</div>
<div>

### Lo que demuestras

El Pod se ha recreado desde cero. El PVC no.

### Para pensar

¿Qué pasaría con `emptyDir` en vez de PVC?

¿Y si el cluster tuviera 3 nodos y el Pod se recolocara?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">7</div>
<div class="reloj">≈ 1:45</div>

# Salud y recursos

## Lo que separa un despliegue de juguete de uno de producción.

---

# Que el proceso corra no significa que funcione

## Tres sondas, tres preguntas distintas

| Probe | Pregunta | Si falla… |
|---|---|---|
| **liveness** | ¿Sigue viva? | **Reinicia el contenedor** |
| **readiness** | ¿Está lista para recibir tráfico? | **La saca del Service** (no la reinicia) |
| **startup** | ¿Ha terminado de arrancar? | Reinicia, pero da tiempo extra al arranque |

<div class="aviso">

**Readiness fallando** = *"estoy cargando, no me mandes peticiones ahora"*. K8s la deja tranquila.
**Liveness fallando** = *"estoy rota sin remedio"*. K8s la reinicia.

La **startup probe** existe por Airflow y compañía: apps que tardan 90 s en arrancar
y que la liveness mataría a los 15 s, en bucle infinito.

</div>

---

<!-- _class: lima -->

# `requests` y `limits`, y por qué te van a doler

## `OOMKilled` es el error que más veces verás en producción

<div class="cols">
<div>

```yaml
resources:
  requests:      # lo que GARANTIZA tener
    cpu: "100m"
    memory: "128Mi"
  limits:        # el máximo que PUEDE usar
    cpu: "500m"
    memory: "512Mi"
```

</div>
<div>

| Si te pasas de… | Consecuencia |
|---|---|
| **CPU** | Throttling: va más lento |
| **Memoria** | **El contenedor muere: `OOMKilled`** |

</div>
</div>

<div class="aviso">

Un `pandas.read_csv()` más grande de lo esperado y Kubernetes mata el Pod sin avisar.
Pod reiniciándose sin logs claros → `kubectl describe pod` → busca `OOMKilled`.

</div>

---

<!-- _class: denso -->

# Los cuatro estados en los que se te va a quedar un Pod

## `Running` no sale en esta tabla, y justo por eso la vas a necesitar

| Estado | Qué significa | Dónde está la causa |
|---|---|---|
| `Pending` | El scheduler no encuentra un nodo con sitio | `kubectl describe pod` → Events |
| `ImagePullBackOff` | No consigue descargar la imagen | Nombre, tag o credenciales del registry |
| **`CrashLoopBackOff`** | **Arranca, se muere, y K8s reintenta cada vez más despacio** | **`kubectl logs <pod> --previous`** |
| `OOMKilled` | Se pasó de `limits.memory` | `kubectl describe pod` → Last State |

<div class="aviso">

`CrashLoopBackOff` es el más frecuente y el peor entendido: **no es un fallo de Kubernetes**, es
tu proceso saliendo con código distinto de cero. La clave está en `--previous`: sin ese flag lees
los logs del contenedor que **acaba de arrancar**, no los del que se murió.

</div>

---

<!-- _class: seccion -->

<div class="num">8</div>
<div class="reloj">≈ 1:50</div>

# Job y CronJob

## Con diferencia, los objetos más relevantes para tu perfil.

---

<!-- _class: lima -->

# El punto ciego: servicios frente a tareas

## Casi todo lo que has visto hoy corre para siempre. Casi todo lo que tú haces, no.

| | Deployment | Job | CronJob |
|---|---|---|---|
| **Para qué sirve** | Algo que atiende peticiones | Algo que se ejecuta una vez | Algo que se ejecuta a una hora |
| **Cuándo termina** | Nunca: ese es el objetivo | Cuando el proceso sale con 0 | Cada ejecución, por separado |
| **Si el proceso acaba** | Lo reinicia | Lo da por completado | Lo da por completado |
| **Ejemplo tuyo** | Una API, la UI de Airflow | Una carga inicial, una migración | El ETL de las 2:00 |

<div class="aviso">

**El error clásico**: meter una ETL en un `Deployment`. Termina, Kubernetes ve un contenedor parado,
lo reinicia, y tu carga se ejecuta en bucle toda la noche. Y en el panel todo parece correcto:
el Pod aparece `Running`.

</div>

---

# Hasta ahora todo eran servicios que corren para siempre

## Pero gran parte de tu trabajo son procesos que arrancan, hacen algo y terminan

<div class="cols">
<div>

### Job — una vez, hasta completar

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: carga-inicial
spec:
  backoffLimit: 3      # reintentos
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: carga
          image: tu-usuario/pipeline:1.0
          command: ["python", "carga.py"]
```

</div>
<div>

### La diferencia con Deployment

Un Job **no repone el Pod cuando termina bien**.

Su objetivo es que el proceso **se complete**, no que siga vivo.

Si falla, reintenta hasta `backoffLimit`.

</div>
</div>

---

# CronJob: un Job nuevo cada vez que toca

## La sintaxis de `schedule` es cron de toda la vida

<div class="cols">
<div>

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pipeline-diario
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pipeline
              image: tu-usuario/pipeline:1.0
```

</div>
<div>

```
 ┌───── minuto (0-59)
 │ ┌─── hora (0-23)
 │ │ ┌─ día del mes
 │ │ │ ┌─ mes
 │ │ │ │ ┌─ día semana (0=dom)
 * * * * *

 "*/5 * * * *"  cada 5 minutos
 "0 2 * * *"    a las 02:00
 "0 6 * * 1"    lunes a las 06:00
```

</div>
</div>

---

<!-- _class: lima -->

# Entonces, ¿para qué sirve Airflow?

## Pregunta legítima. La respuesta está en la columna de la derecha

| | CronJob de Kubernetes | Airflow |
|---|---|---|
| Programar una tarea | Sí | Sí |
| **Dependencias entre tareas** (B después de A) | No | **Sí — el DAG** |
| Reintentos con backoff por tarea | Básico | Configurable por tarea |
| Interfaz para ver el histórico | `kubectl get jobs` | UI completa |
| **Backfill de fechas pasadas** | No | **Sí** |
| Paso de datos entre tareas | No | Sí (XComs, datasets) |

<div class="aviso">

Y se combinan: el **`KubernetesPodOperator`** de Airflow lanza cada tarea del DAG como un Pod.
Es la arquitectura estándar en empresas que corren Airflow sobre K8s.

</div>

---

<!-- _class: navy -->

# Ejercicio 5 — Tu pipeline en producción

## <span class="pill">30 min</span> <span class="pill">EL EJERCICIO DE LA SESIÓN</span> CronJob → Postgres, end to end

<div class="cols-58">
<div>

```bash
# 1. Lanzar el pipeline como Job
$ kubectl apply -f job-pipeline.yaml
$ kubectl logs job/pipeline
# → OK: 20 filas insertadas en 'lecturas'

# 2. Comprobarlo en la base de datos
$ kubectl exec -it deploy/postgres -- \
    psql -U datos -c \
    "SELECT count(*) FROM lecturas;"

# 3. Programarlo cada 5 minutos
$ kubectl apply -f cronjob.yaml
$ kubectl get cronjob

# 4. Sin esperar: ejecución manual
$ kubectl create job --from=cronjob/pipeline \
    prueba-manual
```

</div>
<div>

### Lo que acabas de construir

Un **pipeline de datos completo** sobre Kubernetes:

- Base de datos con almacenamiento que sobrevive
- Una API que expone datos
- Un proceso programado que la alimenta

Con configuración externa, secretos y reintentos.

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">9</div>
<div class="reloj">≈ 2:15</div>

# minikube y el error<br>que tumba a media clase

## Tus imágenes locales no existen dentro del cluster.

---

<!-- _class: lima -->

# minikube tiene su propio almacén de imágenes

## Aunque `docker image ls` la muestre, el cluster no la ve

<pre class="diagrama">
┌────────── Tu máquina ──────────┐  ┌─── minikube (otro Docker) ───┐
│  docker image ls                │  │  almacén de imágenes propio  │
│    mi-imagen:1.0   ✅ está aquí │  │    (vacío)      ❌ no la ve  │
└─────────────────────────────────┘  └───────────────────────────────┘
</pre>

Resultado: el Pod se queda en **`ImagePullBackOff`** para siempre.

| Opción | Comando | Cuándo |
|---|---|---|
| **A. Publicar en Docker Hub** | `docker push usuario/imagen:1.0` | **La mejor.** Es lo de producción |
| **B. Cargarla en minikube** | `minikube image load mi-imagen:1.0` | Iterar rápido |
| **C. Construir dentro** | `eval $(minikube docker-env)` | Desarrollo intensivo |

---

# El gotcha dentro del gotcha

## Con las opciones B y C, `latest` te vuelve a romper el despliegue

<div class="aviso">

Si tu imagen tiene el tag `latest`, Kubernetes usa por defecto `imagePullPolicy: Always`
e intentará descargarla de Docker Hub **ignorando la copia local que acabas de cargar**.

Con las opciones B y C: usa **siempre un tag concreto** (`:1.0`), o añade explícitamente
`imagePullPolicy: IfNotPresent`.

</div>

<div class="destacado">

Es la tercera vez en el módulo que <code>latest</code><br>causa un problema. No es casualidad.

</div>

---

<!-- _class: navy -->

# Ejercicio 6 (opcional) — Rolling update y rollback

## <span class="pill">10 min</span> Actualizar sin cortar el servicio, y volver atrás

<div class="cols-58">
<div>

```bash
# 1. Nueva versión
$ kubectl set image deployment/api \
    app=tu-usuario/pipeline:2.0
$ kubectl rollout status deployment/api

# 2. Historial y vuelta atrás
$ kubectl rollout history deployment/api
$ kubectl rollout undo deployment/api

# 3. Un despliegue roto a propósito
$ kubectl set image deployment/api \
    app=tu-usuario/pipeline:no-existe
```

</div>
<div>

### Lo que vas a ver

El Pod nuevo se queda en `ImagePullBackOff`…

…pero **los Pods viejos siguen sirviendo tráfico**.

**Cero downtime**, incluso con un despliegue roto.

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">10</div>
<div class="reloj">≈ 2:20</div>

# Cierre

## Todo el módulo, en una tabla de traducción.

---

<!-- _class: denso -->

# De Docker Compose a Kubernetes

## Cada cosa que aprendiste en las sesiones 1 y 2 tiene aquí su equivalente

| Docker Compose | Kubernetes | Para qué lo usas en datos |
|---|---|---|
| `services:` (cada servicio) | `Deployment` + `Service` | Tu API, la UI de Airflow |
| `image:` | `containers[].image` | Tu pipeline ya empaquetado |
| `environment:` | `ConfigMap` o `Secret` + `envFrom` | Credenciales del *warehouse* |
| `volumes:` (con nombre) | `PersistentVolumeClaim` | Los datos de tu Postgres |
| `ports: "8080:80"` | `Service` + `port-forward` | Abrir una UI en tu portátil |
| `healthcheck:` | `livenessProbe` / `readinessProbe` | Detectar un worker colgado |
| `deploy.replicas:` | `spec.replicas` | Escalar workers en un pico |
| **`depends_on:`** | **No existe** | Reintentos, en tu propio código |

---

<!-- _class: lima -->

# La única traducción que no existe

## `depends_on` no tiene equivalente, y es a propósito

<div class="destacado">

Kubernetes no garantiza orden de arranque.<br>Tu app debe tolerar que su dependencia no esté lista.

</div>

<div class="aviso">

Si tu Pod no encuentra Postgres, se reinicia; en el siguiente intento ya estará.
Para casos que sí necesitan orden estricto existen los **initContainers**: contenedores
que se ejecutan hasta completarse antes del contenedor principal.

</div>

---

<!-- _class: denso -->

# Comandos: la tabla de equivalencias

## Si sabías Compose, ya sabes moverte por un cluster

| Docker Compose | Kubernetes |
|---|---|
| `docker compose up -d` | `kubectl apply -f .` |
| `docker compose down` | `kubectl delete -f .` |
| `docker compose ps` | `kubectl get pods` |
| `docker compose logs -f x` | `kubectl logs -f deploy/x` |
| `docker compose exec x sh` | `kubectl exec -it deploy/x -- sh` |
| *(no hay equivalente)* | `kubectl describe pod x` ← **lo primero al depurar** |

<div class="aviso">

`kubectl describe` no tiene equivalente en Compose y es la herramienta de diagnóstico
más importante de Kubernetes. Al final muestra los **eventos**: ahí está siempre la causa.

</div>

---

<!-- _class: denso -->

# La batería de diagnóstico: cuatro síntomas, cuatro comandos

## Si te llevas una sola chuleta de hoy, que sea esta

| Síntoma | Primer comando | Qué estás buscando |
|---|---|---|
| No arranca: `Pending`, `ImagePullBackOff` | `kubectl describe pod <pod>` | La sección **Events**, al final |
| Arranca y se cae: `CrashLoopBackOff` | `kubectl logs <pod> --previous` | La traza del contenedor que murió |
| El Service no responde | `kubectl get endpoints <svc>` | Si pone `<none>`, es el `selector` |
| El CronJob no se ejecuta | `kubectl describe cronjob <cj>` | Si hubo ejecuciones y con qué resultado |

<div class="aviso">

El orden importa: **siempre `describe` antes que `logs`**. Si el contenedor no ha llegado ni a
arrancar no hay logs que leer, y la causa está en los eventos.

</div>

---

<!-- _class: navy -->

# Limpieza

## minikube ocupa 4 GB de RAM mientras esté arrancado

```bash
# Borrar todo lo que has creado
$ kubectl delete -f .

# Los PVC no siempre se borran con lo anterior: compruébalo
$ kubectl get pvc

# Apagar el cluster (conserva el estado para otro día)
$ minikube stop

# O borrarlo entero
$ minikube delete
```

---

<!-- _class: verde -->

# Fin del módulo

## Tres sesiones, un mismo hilo: qué se ejecuta, dónde viven los datos y quién lo mantiene vivo

<div class="cols">
<div>

### Lo que te llevas

- Construir y publicar imágenes reproducibles
- Levantar un stack de datos completo con Compose
- Desplegar y depurar un pipeline sobre Kubernetes
- Y, sobre todo, **saber dónde mirar cuando falla**

</div>
<div>

### Siguientes pasos naturales

- `KubernetesPodOperator` en Airflow
- Helm: plantillas de manifiestos
- Un cluster gestionado: EKS, GKE, AKS
- El módulo de *Security and Optimization*

</div>
</div>
