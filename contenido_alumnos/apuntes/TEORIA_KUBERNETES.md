# Kubernetes para Data Engineers — Teoría

> Material didáctico para la sesión de orquestación de contenedores del máster
> de Data Engineering. **Continuación directa de la sesión de Docker**: se da
> por sabido qué es una imagen, qué es un contenedor, qué hace un Dockerfile y
> cómo funciona `docker compose`.

Ejercicios: **[EJERCICIOS_KUBERNETES.md](./EJERCICIOS_KUBERNETES.md)**
Teoría de Docker (prerrequisito): **[TEORIA.md](./TEORIA.md)**

---

## Qué necesitas saber hoy y qué no

Kubernetes es enorme. La certificación oficial (CKA) son 2 meses de estudio.
En 2h30 no vamos a cubrirlo todo, ni falta que hace. Esto es lo que sí y lo
que no entra:

| Sí, hoy | No hoy (pero existe) |
|---|---|
| Pod, Deployment, Service | StatefulSet, DaemonSet, Operators |
| ConfigMap, Secret | Vault, Sealed Secrets, External Secrets |
| PersistentVolumeClaim | StorageClasses, CSI drivers, snapshots |
| Job y CronJob | Argo Workflows, KubeFlow |
| Probes, requests/limits | Affinity, taints/tolerations, PodDisruptionBudgets |
| `kubectl` a pelo | Helm, Kustomize, GitOps (Argo CD, Flux) |
| minikube en local | EKS, GKE, AKS, multi-tenant, RBAC avanzado |

El objetivo de hoy **no** es que salgas siendo administrador de Kubernetes. Es
que puedas leer los manifiestos de tu equipo, desplegar tu propia imagen, y
entender qué te está diciendo un `kubectl describe pod` cuando tu pipeline no
arranca. Eso es exactamente lo que necesita un Data Engineer.

---

## Índice

**Parte I — Conceptos**

1. [¿Por qué Kubernetes? De un contenedor a un cluster](#1-por-qué-kubernetes-de-un-contenedor-a-un-cluster)
2. [Arquitectura de un cluster](#2-arquitectura-de-un-cluster)
3. [Anatomía de un manifiesto YAML](#3-anatomía-de-un-manifiesto-yaml)
4. [Pod, ReplicaSet y Deployment](#4-pod-replicaset-y-deployment)
5. [Services y red interna](#5-services-y-red-interna)

**Parte II — Aplicaciones reales**

6. [Configuración: ConfigMaps y Secrets](#6-configuración-configmaps-y-secrets)
7. [Almacenamiento: volúmenes, PV y PVC](#7-almacenamiento-volúmenes-pv-y-pvc)
8. [Salud y recursos: probes, requests y limits](#8-salud-y-recursos-probes-requests-y-limits)
9. [Cargas por lotes: Job y CronJob](#9-cargas-por-lotes-job-y-cronjob)

**Parte III — Práctica**

10. [minikube: tu cluster local](#10-minikube-tu-cluster-local)
11. [Del `docker-compose.yml` al manifiesto de Kubernetes](#11-del-docker-composeyml-al-manifiesto-de-kubernetes)

**Apéndices**

- [A — Chuleta de `kubectl`](#apéndice-a--chuleta-de-kubectl)
- [B — Cuando algo falla](#apéndice-b--cuando-algo-falla)

---

## Leyendas de esta guía

Cada sección está marcada para indicar en qué contexto la necesitas:

- **🟢 Leer antes de clase** — es preparación previa obligatoria para no llegar perdido. Base para los ejercicios.
- **🔵 Se explica en directo** — durante la sesión se desarrolla en tiempo real. Viene bien haber visto antes el resumen, pero se redunda en clase.
- **⚪ Referencia** — está aquí por si lo necesitas después, cuando trabajas con Kubernetes. Valioso pero no crítico para las 2 h 30 de la sesión.

### Mínimo viable de lectura

**Si vas justo de tiempo**, aquí está el camino mínimo (aprox. 45 min) para entender los ejercicios:

1. **Sección 3** (§3 — Anatomía de YAML): 15 min. Sin esto no sabes leer ni escribir un manifiesto.
2. **Sección 4** (§4 — Pod/Deployment): 10 min. Qué es cada cosa y por qué Deployment en lugar de Pod solo.
3. **Sección 5** (§5 — Services): 10 min. Cómo expones tu aplicación.
4. **Sección 9** (§9 — Job/CronJob): 10 min. El ejercicio 5 es el corazón de la sesión.

Con eso tienes espina dorsal del módulo. El resto enriquece, pero los 4 de arriba son el mínimo.

---

## Parte I — Conceptos

### 1. 🔵 ¿Por qué Kubernetes? De un contenedor a un cluster

En la sesión de Docker terminaste con un `docker-compose.yml` que levanta
Airflow y Postgres. Funciona perfectamente... **en tu portátil**. Ahora
imagina ese mismo stack en producción:

- El servidor donde corre se reinicia a las 3 de la mañana. ¿Quién arranca
  los contenedores? ¿Y quién te avisa?
- El proceso de Airflow se queda colgado (vivo, pero sin responder).
  `docker ps` dice que está `Up`. ¿Quién detecta que en realidad está roto?
- Necesitas 10 workers en lugar de 2 porque hay un pico de carga nocturna.
  ¿Los arrancas a mano? ¿Y a las 6:00 los apagas también a mano?
- Tienes 20 servidores. ¿Quién decide en cuál cabe cada contenedor?
- Quieres actualizar de Airflow 3.3.1 a 3.3.2 **sin cortar el servicio**.

Todo esto se puede resolver con scripts, `cron` y mucha paciencia. Pero es
frágil y no escala. **Kubernetes es un orquestador de contenedores**: un
sistema que resuelve exactamente estos problemas de forma automática.

#### 1.1 Compose vs Kubernetes

| | Docker Compose | Kubernetes |
|---|---|---|
| **Alcance** | Una máquina | Un cluster de N máquinas |
| **Si un contenedor muere** | Se queda muerto (salvo `restart:`) | Se repone automáticamente |
| **Si la máquina muere** | Se cae todo | Los contenedores se recolocan en otro nodo |
| **Escalar** | `docker compose up --scale` (limitado) | `kubectl scale` o automático (HPA) |
| **Actualizar sin downtime** | No, hay corte | Sí, rolling update con rollback |
| **¿Detecta apps colgadas?** | Healthchecks básicos | Probes: liveness, readiness, startup |
| **Complejidad** | Baja, un archivo | Alta, muchos objetos |
| **Cuándo usarlo** | Desarrollo local, demos, CI | Producción, cargas serias |

Compose no está "superado" por Kubernetes: **resuelven cosas distintas**.
Seguirás usando Compose todos los días en tu portátil. Kubernetes es lo que
corre debajo cuando tu pipeline sale a producción.

#### 1.2 La idea central: el modelo declarativo

Esta es *la* diferencia mental respecto a Docker, y si te la llevas hoy, el
resto encaja solo.

Con Docker das **órdenes** (modelo imperativo):

```bash
docker run -d --name web nginx    # "arranca ESTE contenedor AHORA"
```

Si alguien lo mata, se queda muerto. Docker hizo lo que le pediste y ya está.

Con Kubernetes describes un **estado deseado** (modelo declarativo):

```yaml
replicas: 3    # "quiero que SIEMPRE haya 3 copias corriendo"
```

Kubernetes no ejecuta esto una vez: lo comprueba **constantemente**. A esto se
le llama **bucle de reconciliación** y es el corazón del sistema:

```
      ┌─────────────────────────────────────────┐
      │                                           │
      ▼                                           │
┌──────────────┐    ¿coinciden?    ┌──────────────┐
│   ESTADO      │ ───────X───────► │   ESTADO      │
│   DESEADO     │                   │   REAL        │
│  (tu YAML)    │ ◄──── actúa ───── │ (el cluster)  │
└──────────────┘   para corregir    └──────────────┘
      │                                           │
      └───────────── cada pocos segundos ─────────┘
```

Si borras un Pod, en segundos aparece otro. No porque alguien lo mande, sino
porque el estado real dejó de coincidir con el deseado y el bucle lo corrigió.

---

### 2. ⚪ Arquitectura de un cluster

Un cluster tiene dos tipos de máquinas (nodos): el **control plane** (el
cerebro, que decide) y los **workers** (los músculos, donde corren tus
contenedores).

```
┌──────────────────── CONTROL PLANE (el cerebro) ────────────────────┐
│                                                                      │
│   ┌────────────┐   ┌────────┐   ┌───────────┐   ┌────────────────┐ │
│   │ API server │   │  etcd  │   │ Scheduler │   │  Controller     │ │
│   │ (la puerta)│   │(memoria)│  │ (coloca)  │   │  manager        │ │
│   └─────┬──────┘   └────────┘   └───────────┘   │ (reconcilia)    │ │
│         │                                        └────────────────┘ │
└─────────┼────────────────────────────────────────────────────────────┘
          │
   kubectl│apply
          │
     ┌────┴─────────────────────┬──────────────────────────┐
     ▼                           ▼                          ▼
┌──────────────┐         ┌──────────────┐          ┌──────────────┐
│  NODO 1       │         │  NODO 2       │          │  NODO 3       │
│  ┌─────────┐  │         │  ┌─────────┐  │          │  ┌─────────┐  │
│  │ kubelet │  │         │  │ kubelet │  │          │  │ kubelet │  │
│  ├─────────┤  │         │  ├─────────┤  │          │  ├─────────┤  │
│  │containerd│ │         │  │containerd│ │          │  │containerd│ │
│  ├─────────┤  │         │  ├─────────┤  │          │  ├─────────┤  │
│  │kube-proxy│ │         │  │kube-proxy│ │          │  │kube-proxy│ │
│  └─────────┘  │         │  └─────────┘  │          │  └─────────┘  │
│   [Pod][Pod]  │         │   [Pod]       │          │   [Pod][Pod]  │
└──────────────┘         └──────────────┘          └──────────────┘
```

**En el control plane:**

| Componente | Qué hace |
|---|---|
| **API server** | La única puerta de entrada. `kubectl` habla con él por HTTPS. Nada accede a etcd directamente |
| **etcd** | Base de datos clave-valor con **todo** el estado del cluster. Si se pierde etcd, el cluster pierde la memoria |
| **Scheduler** | Cuando hay un Pod nuevo sin nodo asignado, decide en cuál cabe (según CPU/memoria libres y restricciones) |
| **Controller manager** | Ejecuta los bucles de reconciliación. Es quien hace real la promesa del modelo declarativo |

**En cada nodo worker:**

| Componente | Qué hace |
|---|---|
| **kubelet** | El agente del nodo. Pregunta al API server "¿qué me toca correr?" y se asegura de que esos contenedores estén vivos |
| **Container runtime** | Quien realmente arranca contenedores. Hoy suele ser `containerd` (el mismo motor que hay debajo de Docker) |
| **kube-proxy** | Programa las reglas de red del nodo para que el tráfico llegue al Pod correcto |

**El flujo completo de un `kubectl apply -f deployment.yaml`:**

```
1. kubectl envía el YAML al API server
2. API server valida y lo guarda en etcd            → "estado deseado registrado"
3. Controller manager ve que faltan Pods            → crea los objetos Pod
4. Scheduler asigna cada Pod a un nodo concreto
5. kubelet de ese nodo se entera y llama a containerd
6. containerd descarga la imagen y arranca el contenedor
```

> **Lo importante para ti**: no necesitas memorizar estos componentes para
> trabajar. Pero cuando un Pod se queda en `Pending` para siempre, saber que
> es el **scheduler** el que no encuentra sitio te lleva directo a la causa
> (no hay recursos), en vez de dar palos de ciego.

---

### 3. 🟢 Anatomía de un manifiesto YAML

Todo en Kubernetes se describe con la misma estructura de 4 campos. Aprende
esto una vez y sabrás leer cualquier manifiesto:

```yaml
apiVersion: apps/v1          # 1. Versión de la API que define este tipo de objeto
kind: Deployment             # 2. QUÉ tipo de objeto es
metadata:                    # 3. Cómo se llama y cómo se etiqueta
  name: mi-app
  labels:
    app: mi-app
spec:                        # 4. QUÉ quieres que exista (el estado deseado)
  replicas: 3
  ...
```

| Campo | Para qué sirve |
|---|---|
| `apiVersion` | `v1` para objetos básicos (Pod, Service, ConfigMap, Secret). `apps/v1` para Deployment. `batch/v1` para Job/CronJob |
| `kind` | El tipo: `Pod`, `Deployment`, `Service`, `ConfigMap`, `Secret`, `Job`, `CronJob`, `PersistentVolumeClaim`... |
| `metadata` | `name` (identificador único dentro del namespace) y `labels` (etiquetas de las que hablamos abajo) |
| `spec` | Todo lo específico de ese tipo de objeto. Es donde vive el "estado deseado" |

#### 3.1 Labels y selectors — el pegamento de Kubernetes

Este es el concepto que más confunde al principio y el que más se repite.

En Kubernetes, los objetos **no se referencian por nombre**, sino por
**etiquetas** (labels). Un Service no dice "manda tráfico a los pods
`mi-app-7d4b-x9`, `mi-app-7d4b-k2`..." (que además cambian de nombre
constantemente). Dice: **"manda tráfico a todo lo que tenga la etiqueta
`app: mi-app`"**.

```
    Deployment                          Service
    selector:                           selector:
      app: mi-app                         app: mi-app
         │                                    │
         │  crea Pods con                     │  busca Pods con
         │  labels: app=mi-app                │  labels: app=mi-app
         ▼                                    ▼
    ┌─────────────────────────────────────────────────┐
    │  [Pod]        [Pod]        [Pod]                 │
    │  app=mi-app   app=mi-app   app=mi-app            │
    └─────────────────────────────────────────────────┘
```

Es un sistema de acoplamiento débil: los Pods pueden ir y venir, cambiar de
IP y de nombre, y todo lo demás sigue encontrándolos porque la etiqueta no
cambia.

> **Causa nº1 de "mi Service no funciona"**: el `selector` del Service no
> coincide con las `labels` de los Pods. Un typo y el Service se queda sin
> endpoints, silenciosamente. Se diagnostica con
> `kubectl get pods --show-labels` y `kubectl describe svc <nombre>`.

#### 3.2 Namespaces

Un namespace es una **carpeta lógica** dentro del cluster. Sirve para separar
entornos o equipos dentro del mismo cluster sin que se pisen los nombres.

```bash
kubectl get namespaces
kubectl get pods -n kube-system      # los pods internos de Kubernetes
kubectl apply -f app.yaml -n datos   # desplegar en el namespace "datos"
```

Si no especificas ninguno, todo va al namespace `default`. En producción,
tu equipo de datos probablemente tendrá el suyo propio.

---

### 4. 🟢 Pod, ReplicaSet y Deployment

#### 4.1 El Pod — la unidad mínima

En Docker, la unidad que ejecutas es el **contenedor**. En Kubernetes es el
**Pod**: un envoltorio que contiene **uno o más contenedores** que comparten
red (la misma IP, se ven entre sí por `localhost`) y almacenamiento.

```
┌──────── Pod (IP: 10.244.1.7) ────────┐
│                                        │
│  ┌───────────────┐  ┌───────────────┐ │
│  │  contenedor    │  │  contenedor    │ │
│  │  principal     │  │  sidecar       │ │
│  │  (tu app)      │  │  (opcional)    │ │
│  └───────────────┘  └───────────────┘ │
│         ↕ se ven por localhost         │
│  ┌──────────────────────────────────┐ │
│  │  volúmenes compartidos            │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**En el 95% de los casos tendrás un solo contenedor por Pod** — el tuyo. El
patrón multi-contenedor (*sidecar*) se usa para cosas como un recolector de
logs o un proxy que acompaña a la app.

**Nunca crees Pods sueltos en producción.** Si el Pod muere, nadie lo repone:
se comporta exactamente igual que un `docker run` sin `--restart`.

#### 4.2 ReplicaSet — N copias siempre vivas

Un ReplicaSet garantiza que en todo momento existan **N Pods** con unas
etiquetas dadas. Si uno muere, crea otro. Es el bucle de reconciliación
aplicado al recuento de Pods.

En la práctica **no crearás ReplicaSets a mano**: los gestiona el Deployment
por ti.

#### 4.3 Deployment — lo que usarás siempre

El Deployment está por encima del ReplicaSet y añade lo que hace falta para
operar de verdad: **rolling updates** y **rollback**.

```
   Deployment  "quiero 3 réplicas de mi-app:2.0"
        │
        ├── crea y gestiona ──► ReplicaSet (v2.0, 3 réplicas)
        │                            │
        │                            ├──► Pod
        │                            ├──► Pod
        │                            └──► Pod
        │
        └── al actualizar, crea un ReplicaSet nuevo y vacía el viejo
            poco a poco, sin cortar el servicio
```

Un Deployment mínimo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 3
  selector:
    matchLabels:            # a qué Pods gestiona
      app: mi-app
  template:                 # la "plantilla" de Pod que va a crear
    metadata:
      labels:
        app: mi-app         # DEBE coincidir con el selector de arriba
    spec:
      containers:
        - name: app
          image: mi-usuario/mi-imagen:1.0
          ports:
            - containerPort: 8000
```

Fíjate en la estructura de muñeca rusa: el `spec` del Deployment contiene un
`template`, que es a su vez la definición de un Pod (con su propio `metadata`
y su propio `spec`). Ese anidamiento confunde al principio, pero una vez lo
ves, todos los manifiestos se leen igual.

**Rolling update y rollback:**

```bash
kubectl set image deployment/mi-app app=mi-usuario/mi-imagen:2.0
kubectl rollout status deployment/mi-app     # sigue el progreso
kubectl rollout history deployment/mi-app    # historial de versiones
kubectl rollout undo deployment/mi-app       # vuelve a la anterior
```

Durante el rolling update, Kubernetes va sustituyendo Pods poco a poco:
levanta uno nuevo, espera a que esté *listo* (readiness probe), y solo
entonces mata uno viejo. El número de Pods disponibles **nunca llega a cero**.

---

### 5. 🟢 Services y red interna

#### 5.1 El problema

Los Pods son **efímeros y con IP cambiante**. Cada vez que uno se recrea
—porque se cayó, porque escalaste, porque hiciste un rolling update— tiene una
IP nueva. Si tu pipeline se conectara a la IP de un Pod concreto de Postgres,
se rompería constantemente.

#### 5.2 La solución: el Service

Un Service es una **IP estable y un nombre DNS fijo** que apunta, mediante
labels, a un grupo de Pods, y reparte el tráfico entre ellos.

```
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
```

Lo importante: **dentro del cluster, el nombre del Service funciona como
hostname**. Exactamente igual que en Docker Compose, donde un servicio llama
a otro por el nombre del servicio:

```python
# En Docker Compose:  postgresql://usuario@postgres:5432/db
# En Kubernetes:      postgresql://usuario@postgres:5432/db
#                                            └── nombre del Service
```

Es la misma idea que ya conoces, y esa continuidad es intencionada.

#### 5.3 Tipos de Service

| Tipo | Alcance | Cuándo se usa |
|---|---|---|
| **ClusterIP** (por defecto) | Solo dentro del cluster | Comunicación interna: tu app ↔ tu base de datos. **El 90% de los casos** |
| **NodePort** | Abre un puerto fijo (30000-32767) en todos los nodos | Pruebas y clusters locales. Poco usado en producción |
| **LoadBalancer** | Pide un balanceador al proveedor cloud | Exponer un servicio a internet en AWS/GCP/Azure |

Y para tráfico web con varios dominios o rutas, existe el **Ingress**: una
capa de enrutamiento HTTP/HTTPS que decide, según el `Host` o el `path`, a qué
Service mandar cada petición. No sustituye al Service, trabaja encima de él.

#### 5.4 `port-forward` — tu mejor amigo en local

En un cluster local (minikube), la forma más fiable de acceder a un servicio
desde tu navegador **no es NodePort, es `port-forward`**:

```bash
kubectl port-forward svc/mi-app 8090:80
#                              │    │
#                              │    └── puerto del Service (dentro del cluster)
#                              └── puerto en TU máquina
```

Abre un túnel temporal desde tu máquina al cluster. Funciona siempre, con
cualquier tipo de Service, sin tocar los manifiestos. Se corta con `Ctrl+C`.

Es idéntico en concepto al `-p` de `docker run`, pero como comando aparte y
temporal.

---

## Parte II — Aplicaciones reales

### 6. 🔵 Configuración: ConfigMaps y Secrets

En la sesión de Docker viste que **no se mete la configuración dentro de la
imagen**: se pasa con `-e` o con un archivo `.env`. La misma imagen sirve para
desarrollo y producción, solo cambian las variables.

Kubernetes formaliza esa idea en dos objetos.

#### 6.1 ConfigMap — configuración no sensible

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

Se inyecta en el Pod de dos formas. Como **variables de entorno**:

```yaml
      containers:
        - name: app
          image: mi-usuario/mi-imagen:1.0
          envFrom:
            - configMapRef:
                name: app-config      # inyecta TODAS las claves como variables
```

O como **archivos montados** (útil para ficheros de configuración enteros):

```yaml
          volumeMounts:
            - name: config
              mountPath: /etc/config
      volumes:
        - name: config
          configMap:
            name: app-config
```

#### 6.2 Secret — datos sensibles

Idéntico en estructura, pero pensado para contraseñas, tokens y claves:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:                    # stringData = texto plano, K8s lo codifica solo
  POSTGRES_PASSWORD: "contrasena_segura"
```

> ⚠️ **Aviso importante que mucha gente pasa por alto**: por defecto, un Secret
> **no está cifrado**. Solo está codificado en **base64**, que es trivial de
> revertir:
>
> ```bash
> kubectl get secret db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
> # → contrasena_segura
> ```
>
> Un Secret protege frente a "que aparezca por accidente en un log o en un
> `kubectl get -o yaml` rápido", no frente a un atacante. Para seguridad real
> hace falta cifrado en reposo en etcd, RBAC bien configurado, o un gestor
> externo (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager).
> **Y nunca, jamás, commitees un Secret con datos reales a Git.**

#### 6.3 Equivalencias con lo que ya sabes

| Docker / Compose | Kubernetes |
|---|---|
| `-e VAR=valor` | ConfigMap + `envFrom` |
| Archivo `.env` | ConfigMap |
| Contraseñas en `.env` (mala práctica) | Secret (algo mejor) / Vault (bien) |
| `-v ./config.yml:/app/config.yml` | ConfigMap montado como volumen |

---

### 7. 🔵 Almacenamiento: volúmenes, PV y PVC

El sistema de archivos de un contenedor es efímero — esto ya lo sufriste en el
Ejercicio 2 de Docker. En Kubernetes es peor: los Pods no solo se paran, se
**recrean en otro nodo**, así que ni siquiera puedes contar con el disco local.

#### 7.1 Los tres niveles

| Tipo | Vive mientras... | Equivalente en Docker |
|---|---|---|
| **emptyDir** | ...viva el Pod | Capa de escritura del contenedor |
| **hostPath** | ...viva el nodo (¡y solo en ese nodo!) | Bind mount |
| **PersistentVolume (PV)** | ...tú no lo borres | Named volume |

Para datos de verdad —una base de datos, un dataset— siempre **PV/PVC**.

#### 7.2 PV y PVC — la petición y el recurso

Este par confunde porque son dos objetos para una sola cosa. La analogía:

```
  PersistentVolumeClaim (PVC)          PersistentVolume (PV)
  "Necesito 5 GB de disco"      ───►   El disco real de 5 GB
  (lo escribes tú, en tu YAML)         (lo crea el cluster/cloud)

  Es como reservar mesa:               Es la mesa física
  tú pides, el restaurante asigna
```

- **PVC** = la *solicitud*. Es lo único que escribes normalmente.
- **PV** = el almacenamiento *real*. En un cloud lo crea automáticamente el
  proveedor (un disco EBS en AWS, un Persistent Disk en GCP) mediante una
  **StorageClass**. En minikube lo crea el propio cluster en el disco de la VM.

Un PVC típico:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce          # lo monta un solo nodo a la vez
  resources:
    requests:
      storage: 1Gi
```

Y se usa en el Pod exactamente como un volumen de Docker:

```yaml
      containers:
        - name: postgres
          image: postgres:18-alpine
          volumeMounts:
            - name: datos
              mountPath: /var/lib/postgresql
      volumes:
        - name: datos
          persistentVolumeClaim:
            claimName: postgres-pvc
```

**Modos de acceso:**

| Modo | Significado |
|---|---|
| `ReadWriteOnce` (RWO) | Un solo nodo puede montarlo en escritura. Lo normal para bases de datos |
| `ReadOnlyMany` (ROX) | Muchos nodos, solo lectura |
| `ReadWriteMany` (RWX) | Muchos nodos en escritura. Requiere almacenamiento en red (NFS, EFS); no todos lo soportan |

---

### 8. 🔵 Salud y recursos: probes, requests y limits

Esto es lo que separa un despliegue de juguete de uno de producción.

#### 8.1 Probes — ¿está sana tu app?

Que el proceso esté corriendo **no significa que funcione**. Una app puede
estar viva pero colgada esperando una conexión que nunca llega. Kubernetes
comprueba la salud real con tres tipos de sondas:

| Probe | Pregunta | Si falla... |
|---|---|---|
| **liveness** | ¿Sigue viva? | **Reinicia el contenedor** |
| **readiness** | ¿Está lista para recibir tráfico? | **La saca del Service** (no la reinicia) |
| **startup** | ¿Ha terminado de arrancar? | Reinicia, pero da tiempo extra al arranque |

La distinción liveness/readiness es la que más se pregunta y la más útil:

- **Readiness fallando** = "estoy ocupada / cargando / mi dependencia está
  caída, no me mandes peticiones ahora". Kubernetes la deja tranquila.
- **Liveness fallando** = "estoy rota sin remedio". Kubernetes la reinicia.

```yaml
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8000
            initialDelaySeconds: 5
            periodSeconds: 5
```

También pueden ser `exec` (ejecutar un comando dentro del contenedor) o
`tcpSocket` (comprobar que un puerto acepta conexiones) — útil para bases de
datos que no tienen endpoint HTTP:

```yaml
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "usuario"]
```

> **La startup probe existe por Airflow y compañía**: apps que tardan 60-90
> segundos en arrancar. Sin ella, la liveness probe las mataría a los 15
> segundos, entrando en un bucle infinito de reinicios.

#### 8.2 Requests y limits

Le dices a Kubernetes cuántos recursos necesita tu contenedor:

```yaml
          resources:
            requests:          # lo que GARANTIZA tener (el scheduler lo reserva)
              cpu: "100m"      # 100 milicores = 0,1 CPU
              memory: "128Mi"
            limits:            # el máximo que PUEDE usar
              cpu: "500m"
              memory: "512Mi"
```

| | `requests` | `limits` |
|---|---|---|
| **Para qué sirve** | El scheduler lo usa para decidir en qué nodo cabe | Frena a un contenedor que se desmadra |
| **Si te pasas de CPU** | — | Se te *estrangula* (throttling), va más lento |
| **Si te pasas de memoria** | — | **El contenedor muere con OOMKilled** |

> **Muy relevante para Data Engineers**: `OOMKilled` es probablemente el error
> que más veces verás en producción. Un `pandas.read_csv()` de un fichero más
> grande de lo esperado, un `groupby` que explota en memoria... y Kubernetes
> mata el Pod sin contemplaciones al superar el `limits.memory`. Cuando veas
> un Pod reiniciándose sin logs de error claros,
> `kubectl describe pod` → busca `OOMKilled` en el motivo del último estado.

#### 8.3 Escalado automático (HPA)

Con los `requests` bien definidos, Kubernetes puede añadir y quitar réplicas
solo, según el uso de CPU o memoria:

```bash
kubectl autoscale deployment mi-app --cpu-percent=70 --min=2 --max=10
```

Lo mencionamos para que sepas que existe. En un cluster local necesita el
addon `metrics-server` y tarda minutos en reaccionar, así que no lo veremos
en la práctica de hoy.

---

### 9. 🟢 Cargas por lotes: Job y CronJob

Hasta ahora todo eran servicios que corren **para siempre** (un servidor web,
una base de datos). Pero gran parte del trabajo de un Data Engineer son
procesos que **arrancan, hacen algo y terminan**: una carga nocturna, un
proceso de limpieza, un backfill.

Para eso están el Job y el CronJob — y son, con diferencia, **los objetos más
relevantes para tu perfil**.

#### 9.1 Job — ejecuta una vez hasta completar

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: carga-inicial
spec:
  backoffLimit: 3            # reintentos si falla
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: carga
          image: mi-usuario/mi-pipeline:1.0
          command: ["python", "carga.py"]
```

A diferencia de un Deployment, un Job **no repone el Pod cuando termina bien**:
su objetivo es que el proceso se complete, no que siga vivo. Si falla,
reintenta hasta `backoffLimit` veces.

#### 9.2 CronJob — ejecuta según un horario

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pipeline-diario
spec:
  schedule: "0 2 * * *"           # todos los días a las 02:00 (sintaxis cron)
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pipeline
              image: mi-usuario/mi-pipeline:1.0
```

Un CronJob crea un Job nuevo cada vez que toca. Sintaxis del `schedule`:

```
 ┌───────── minuto (0-59)
 │ ┌─────── hora (0-23)
 │ │ ┌───── día del mes (1-31)
 │ │ │ ┌─── mes (1-12)
 │ │ │ │ ┌─ día de la semana (0-6, domingo=0)
 │ │ │ │ │
 * * * * *

 "*/5 * * * *"   cada 5 minutos
 "0 2 * * *"     todos los días a las 02:00
 "0 6 * * 1"     los lunes a las 06:00
```

#### 9.3 ¿Y entonces para qué sirve Airflow?

Pregunta legítima: si Kubernetes ya sabe ejecutar tareas programadas, ¿por qué
existe Airflow?

| | CronJob de Kubernetes | Airflow |
|---|---|---|
| **Programar una tarea** | ✅ | ✅ |
| **Dependencias entre tareas** (B después de A) | ❌ | ✅ (el DAG) |
| **Reintentos con backoff por tarea** | Básico | ✅ Configurable por tarea |
| **Interfaz para ver el histórico** | `kubectl get jobs` | ✅ UI completa |
| **Backfill de fechas pasadas** | ❌ | ✅ |
| **Paso de datos entre tareas** | ❌ | ✅ (XComs, datasets) |

Un CronJob es perfecto para **una** tarea aislada y periódica. Airflow es
para **pipelines con dependencias**. Y de hecho se combinan: el
`KubernetesPodOperator` de Airflow lanza cada tarea del DAG como un Pod en
Kubernetes — lo mejor de los dos mundos, y la arquitectura estándar en
empresas que corren Airflow sobre K8s.

---

## Parte III — Práctica

### 10. 🟢 minikube: tu cluster local

**minikube** levanta un cluster de Kubernetes de un solo nodo dentro de una VM
o de un contenedor Docker en tu máquina. Es el estándar para aprender y para
probar manifiestos antes de mandarlos a un cluster real.

```bash
minikube start --driver=docker --memory=4096 --cpus=2
minikube status
kubectl get nodes                  # deberías ver 1 nodo Ready

minikube dashboard                 # UI web (opcional, muy útil visualmente)
minikube stop                      # apaga el cluster (conserva el estado)
minikube delete                    # lo borra entero
```

#### 10.1 El problema nº1 de minikube: tus imágenes locales no existen

Esto tumba a la mitad de la clase el primer día, así que léelo dos veces.

**minikube tiene su propio almacén de imágenes, separado del de tu Docker.**
Aunque `docker image ls` en tu máquina muestre `mi-imagen:1.0`, el cluster de
minikube **no la ve**. Al desplegar, intentará descargarla de Docker Hub, no
la encontrará, y el Pod se quedará en `ImagePullBackOff`.

```
┌──────────── Tu máquina ────────────┐   ┌───── minikube (otro Docker) ─────┐
│  docker image ls                    │   │  almacén de imágenes propio       │
│    mi-imagen:1.0    ✅ está aquí    │   │    (vacío)          ❌ no la ve   │
└─────────────────────────────────────┘   └───────────────────────────────────┘
```

Tienes tres soluciones:

| Opción | Comando | Cuándo usarla |
|---|---|---|
| **A. Publicar en Docker Hub** | `docker push usuario/imagen:1.0` | **La mejor**. Es lo que harías en producción y ya sabes hacerlo |
| **B. Cargarla en minikube** | `minikube image load mi-imagen:1.0` | Sin cuenta de Docker Hub, o para iterar rápido |
| **C. Construir dentro de minikube** | `eval $(minikube docker-env)` y luego `docker build` | Desarrollo intensivo; ojo, cambia tu `docker` de sitio |

> ⚠️ **Gotcha adicional con las opciones B y C**: si tu imagen tiene el tag
> `latest`, Kubernetes usa por defecto `imagePullPolicy: Always` e intentará
> descargarla igualmente de Docker Hub, ignorando la copia local. Con las
> opciones B y C, **usa siempre un tag concreto** (`:1.0`) o añade
> explícitamente `imagePullPolicy: IfNotPresent` al contenedor.

#### 10.2 Acceder a tus servicios en minikube

```bash
kubectl port-forward svc/mi-servicio 8090:80   # lo más fiable, funciona siempre
minikube service mi-servicio                    # abre el navegador (para NodePort)
minikube ip                                     # la IP del nodo
```

---

### 11. ⚪ Del `docker-compose.yml` al manifiesto de Kubernetes

Aquí es donde todo lo de la sesión anterior encaja. Este es el mismo servicio
en los dos mundos:

**Docker Compose:**

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_PASSWORD: airflow
    volumes:
      - postgres_data:/var/lib/postgresql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "airflow"]
    deploy:
      resources:
        limits: { memory: 512M }
```

**Kubernetes** (el mismo servicio, repartido en 4 objetos):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
stringData:
  POSTGRES_PASSWORD: airflow
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteOnce]
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
    matchLabels: { app: postgres }
  template:
    metadata:
      labels: { app: postgres }
    spec:
      containers:
        - name: postgres
          image: postgres:18-alpine
          envFrom:
            - secretRef: { name: postgres-secret }
          volumeMounts:
            - name: datos
              mountPath: /var/lib/postgresql
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "airflow"]
          resources:
            limits: { memory: 512Mi }
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
  selector: { app: postgres }
  ports:
    - port: 5432
```

**Tabla de traducción:**

| Docker Compose | Kubernetes |
|---|---|
| `services:` (cada servicio) | Un `Deployment` + un `Service` |
| `image:` | `spec.template.spec.containers[].image` |
| `environment:` | `ConfigMap` (o `Secret`) + `envFrom` |
| `env_file: .env` | `ConfigMap` |
| `volumes:` (named volume) | `PersistentVolumeClaim` + `volumeMounts` |
| `volumes:` (bind mount) | `ConfigMap` montado, o `hostPath` (evítalo) |
| `ports: "8080:80"` | `Service` (+ `port-forward` o Ingress) |
| `depends_on:` | No existe: se resuelve con readiness probes y reintentos |
| `healthcheck:` | `livenessProbe` / `readinessProbe` |
| `deploy.replicas:` | `spec.replicas` |
| `deploy.resources.limits:` | `resources.limits` |
| `restart: always` | Es el comportamiento por defecto |
| `networks:` | Automático: todos los Pods se ven; se restringe con `NetworkPolicy` |
| `docker compose up -d` | `kubectl apply -f .` |
| `docker compose down` | `kubectl delete -f .` |
| `docker compose ps` | `kubectl get pods` |
| `docker compose logs -f x` | `kubectl logs -f deploy/x` |
| `docker compose exec x sh` | `kubectl exec -it deploy/x -- sh` |

Un detalle importante: **`depends_on` no tiene equivalente**. Kubernetes no
garantiza orden de arranque. La filosofía es que **tu app debe tolerar que su
dependencia todavía no esté lista** y reintentar. Si tu Pod no encuentra
Postgres, se reinicia; en el siguiente intento Postgres ya estará y funcionará.
Para casos que sí necesitan orden estricto, existen los **initContainers**
(contenedores que se ejecutan hasta completarse antes del contenedor
principal).

---

## Apéndice A — ⚪ Chuleta de `kubectl`

```bash
# ── Ver qué hay ────────────────────────────────────────────────
kubectl get pods                       # pods del namespace actual
kubectl get pods -o wide               # + IP y nodo
kubectl get pods --show-labels         # + etiquetas (¡para depurar selectors!)
kubectl get all                        # todo lo del namespace
kubectl get deploy,svc,pvc             # varios tipos a la vez
kubectl get pods -w                    # se queda mirando los cambios en vivo

# ── Detalles y diagnóstico ─────────────────────────────────────
kubectl describe pod <nombre>          # EL comando de depuración. Mira "Events"
kubectl logs <pod>                     # logs
kubectl logs -f deploy/<nombre>        # logs en vivo del deployment
kubectl logs <pod> --previous          # logs del contenedor ANTERIOR (tras crash)
kubectl exec -it <pod> -- sh           # shell dentro del contenedor
kubectl get events --sort-by=.lastTimestamp   # qué ha pasado en el cluster

# ── Aplicar y borrar ───────────────────────────────────────────
kubectl apply -f manifiesto.yaml       # crea o actualiza
kubectl apply -f .                     # todos los YAML de la carpeta
kubectl delete -f manifiesto.yaml
kubectl delete pod <nombre>

# ── Operar ─────────────────────────────────────────────────────
kubectl scale deployment <n> --replicas=5
kubectl set image deployment/<n> <contenedor>=<imagen>:<tag>
kubectl rollout status deployment/<n>
kubectl rollout undo deployment/<n>
kubectl port-forward svc/<nombre> 8090:80

# ── Jobs ───────────────────────────────────────────────────────
kubectl get jobs
kubectl get cronjobs
kubectl create job --from=cronjob/<nombre> prueba-manual   # lanzarlo ya

# ── Namespaces ─────────────────────────────────────────────────
kubectl get ns
kubectl get pods -n kube-system
kubectl config set-context --current --namespace=datos     # cambiar el actual
```

---

## Apéndice B — ⚪ Cuando algo falla

**El comando universal**: `kubectl describe pod <nombre>` y lee la sección
**Events** del final. Ahí está la causa el 80% de las veces.

| Estado / síntoma | Causa habitual | Qué hacer |
|---|---|---|
| `Pending` | El scheduler no encuentra nodo con recursos libres | `describe pod` → Events. Baja los `requests` o da más recursos a minikube |
| `ImagePullBackOff` / `ErrImagePull` | La imagen no existe, el nombre está mal, o **es local y minikube no la ve** | Revisa el nombre. Usa `minikube image load` o publica en Docker Hub (ver §10.1) |
| `CrashLoopBackOff` | El contenedor arranca y se muere en bucle | `kubectl logs <pod> --previous` para ver por qué murió |
| `OOMKilled` (en describe) | Superó `limits.memory` | Sube el límite o reduce el uso de memoria del proceso |
| `Completed` pero esperabas que siguiera | El proceso terminó. Un Deployment espera procesos que no acaban | ¿Debería ser un Job en vez de un Deployment? |
| Service sin `Endpoints` | El `selector` no coincide con las `labels` de los Pods | `kubectl get pods --show-labels` y compara con `describe svc` |
| `port-forward` da error de conexión | El Pod aún no está `Ready` | `kubectl get pods` y espera a `1/1 Running` |
| PVC en `Pending` | No hay StorageClass o no hay espacio | `kubectl get sc` — en minikube debe existir `standard` |
| Todo lento o Pods en `Pending` | minikube sin recursos | `minikube stop && minikube start --memory=6144 --cpus=4` |

**Rutina de diagnóstico en 4 pasos:**

```bash
kubectl get pods                     # 1. ¿Cuál está mal y en qué estado?
kubectl describe pod <nombre>        # 2. ¿Qué dice la sección Events?
kubectl logs <nombre>                # 3. ¿Qué dice la aplicación?
kubectl logs <nombre> --previous     # 4. Si crashea: ¿qué dijo antes de morir?
```
