<div class="cover">
<div class="cover-modulo">Módulo · Contenedores y Virtualización</div>
<h1 class="cover-title">Sesión 3<br>Kubernetes: del contenedor al cluster</h1>
<div class="cover-sub">Apuntes de apoyo · Máster en Data Engineering, MLOps &amp; Arquitectura Cloud</div>
<div class="cover-meta">
Contenido de referencia para repaso. Estos apuntes desarrollan por escrito lo que se ve
en las diapositivas y en los vídeos de teoría, y añaden el detalle que en clase se
menciona de pasada.
</div>
</div>

<div class="page-break"></div>

## Dónde estamos

Compose orquesta contenedores **en una máquina**. Hoy vemos qué pasa cuando hay muchas.

!!! aviso "Lo primero, para que nadie se agobie"
    **Kubernetes no sustituye a Docker ni a Compose.** Vas a seguir usando Compose todos
    los días en tu portátil. Kubernetes es lo que corre **debajo** cuando tu pipeline
    sale a producción. Son capas, no sustituciones.

**Objetivos de la sesión.** Al terminar deberías ser capaz de:

1. Leer y escribir cualquier manifiesto YAML de Kubernetes.
2. Desplegar una aplicación con un Deployment y exponerla con un Service.
3. Separar la configuración de la imagen con ConfigMaps y Secrets.
4. Montar almacenamiento que sobreviva a la muerte de un Pod.
5. Programar un proceso por lotes con un CronJob — tu pan de cada día.

**Una nota sobre el enfoque.** Estos apuntes están escritos para un perfil de **datos**,
no de administración de sistemas. Hay partes de Kubernetes (redes avanzadas, RBAC,
operadores, Helm) que quedan deliberadamente fuera. Lo que sí está aquí es todo lo que
necesitas para desplegar y depurar un pipeline.

---

## 1. Por qué Kubernetes

### 1.1 Cinco preguntas que Compose no sabe responder

Tu `docker-compose.yml` funciona. **En tu portátil.** Ahora imagina ese mismo stack en
producción:

1. El servidor se reinicia a las 3 de la mañana. **¿Quién arranca los contenedores?** ¿Y
   quién te avisa?
2. Airflow se queda colgado: vivo, pero sin responder. `docker ps` dice `Up` tan
   tranquilo. **¿Quién detecta que está roto?**
3. Necesitas 10 workers en lugar de 2 por un pico nocturno. **¿Y a las 6:00 los apagas a
   mano?**
4. Tienes 20 servidores. **¿Quién decide en cuál cabe cada contenedor?**
5. Quieres pasar de Airflow 3.3.1 a 3.3.2 **sin cortar el servicio**.

La segunda es la más traicionera: **un proceso vivo pero colgado es peor que uno
muerto**, porque el muerto al menos se nota.

Todo esto se puede resolver con scripts, `cron` y mucha paciencia. Pero es frágil y no
escala.

!!! definicion "Kubernetes (K8s)"
    Un **orquestador de contenedores** de código abierto: automatiza el despliegue, el
    escalado y la gestión de aplicaciones en contenedores sobre un conjunto de máquinas.
    Lo creó Google en 2014 a partir de su sistema interno **Borg**, y lo donó a la
    **CNCF** (Cloud Native Computing Foundation).

    Actúa como el director de orquesta de tu infraestructura, decidiendo en qué máquina
    física o virtual debe ejecutarse cada contenedor.

### 1.2 Compose y Kubernetes resuelven cosas distintas

<figure>
<img src="img/s124.png" alt="Comparativa Compose frente a Kubernetes">
<figcaption><strong>Figura 3.1.</strong> Ninguno sustituye al otro. Fíjate también en la
fila de complejidad: Kubernetes no es gratis.</figcaption>
</figure>

| Característica | Docker Compose | Kubernetes |
|---|---|---|
| **Alcance** | Una máquina | Un cluster de N máquinas |
| **Si un contenedor muere** | Se queda muerto (salvo `restart:`) | Se repone automáticamente |
| **Si la máquina muere** | Se cae todo | Los contenedores se recolocan en otro nodo |
| **Escalar** | `up --scale` (limitado) | `kubectl scale` o automático (HPA) |
| **Actualizar sin *downtime*** | No, hay corte | Sí, *rolling update* con *rollback* |
| **¿Detecta apps colgadas?** | Healthchecks básicos | *Probes*: liveness, readiness, startup |
| **Complejidad** | Baja, un archivo | **Alta, muchos objetos** |
| **Cuándo usarlo** | Desarrollo local, demos, CI | **Producción, cargas serias** |

!!! practica "Escalado en Data Engineering"
    El ejemplo típico de escalado automático es por CPU:
    `kubectl autoscale deployment mi-app --cpu-percent=60 --min=2 --max=10`.

    Pero **en ingeniería de datos rara vez escalarás por CPU**. Lo habitual es escalar
    por **longitud de cola**: *"levántame más Pods si hay más de 10.000 mensajes
    acumulados en Kafka"*. Es la misma idea, con otra métrica.

### 1.3 La idea central: de dar órdenes a describir un estado

Si te llevas **una sola cosa** de esta sesión, que sea esta.

<figure>
<img src="img/s125.png" alt="Imperativo frente a declarativo">
<figcaption><strong>Figura 3.2.</strong> Docker ejecuta una orden. Kubernetes mantiene
una promesa.</figcaption>
</figure>

!!! definicion "Imperativo frente a declarativo"
    **Docker es imperativo.** `docker run -d --name web nginx` significa *"arranca este
    contenedor **ahora**"*. Es una orden, se ejecuta una vez, y si alguien mata ese
    contenedor se queda muerto: Docker hizo lo que le pediste y su trabajo terminó ahí.

    **Kubernetes es declarativo.** `replicas: 3` no significa "arranca tres
    contenedores". Significa **"quiero que *siempre* haya tres copias"**. Y ese "siempre"
    es literal: no se ejecuta una vez, **se comprueba constantemente**.

Todo lo demás de esta sesión es consecuencia de esto.

### 1.4 El bucle de reconciliación

<figure>
<img src="img/s126.png" alt="El bucle de reconciliación">
<figcaption><strong>Figura 3.3.</strong> El corazón del sistema, y la razón de que los
Pods "resuciten" solos.</figcaption>
</figure>

!!! definicion "Bucle de reconciliación"
    Kubernetes compara continuamente, cada pocos segundos, el **estado deseado** (tu
    YAML) con el **estado real** (lo que hay en el cluster). Si no coinciden, actúa para
    corregirlo. Y vuelve a comparar. Para siempre.

**La analogía del termostato**, que es la que vas a usar para explicárselo a otros:

- **Estado deseado:** lo configuras a 22 °C.
- **Estado real:** la habitación está a 19 °C.
- **Reconciliación:** el termostato detecta la diferencia y enciende la calefacción. Al
  llegar a 22 °C se apaga, pero **no deja de vigilar**. Si abres una ventana, vuelve a
  encenderse.

**Aplicado a Kubernetes:**

1. Pides tres réplicas. Se crean tres. El estado deseado (3) coincide con el real (3);
   el bucle solo vigila.
2. Un servidor físico se apaga de golpe y uno de tus Pods muere. El estado real baja a 2.
3. **En milisegundos**, el bucle detecta la diferencia y ordena crear un Pod nuevo en
   otro nodo sano.

Nadie te ha llamado por teléfono a las 3 de la mañana. Ese es el valor.

---

## 2. Arquitectura de un cluster

!!! aviso "No hay que memorizar esto"
    Lo que sí hay que saber es **a quién culpar cuando algo se atasca**. Léelo una vez,
    quédate con el diagnóstico del final, y vuelve aquí cuando lo necesites.

<figure>
<img src="img/s129.png" alt="Arquitectura de un cluster de Kubernetes">
<figcaption><strong>Figura 3.4.</strong> Control plane (el cerebro, que decide) y nodos
worker (los músculos, donde corren tus contenedores).</figcaption>
</figure>

### 2.1 El control plane — el cerebro

| Componente | Qué hace |
|---|---|
| **API server** | La **única** puerta de entrada. `kubectl` habla con él por HTTPS. Nadie accede a etcd directamente |
| **etcd** | Base de datos clave-valor con **todo** el estado del cluster. Si se pierde etcd, el cluster pierde la memoria |
| **Scheduler** | Cuando hay un Pod nuevo sin nodo, decide en cuál cabe según CPU y memoria libres |
| **Controller manager** | Ejecuta los bucles de reconciliación. Es quien hace real la promesa del modelo declarativo |

### 2.2 Los nodos worker — los músculos

| Componente | Qué hace |
|---|---|
| **kubelet** | El agente del nodo. Pregunta al API server "¿qué me toca correr?" y se asegura de que esos contenedores estén vivos |
| **Container runtime** | Quien realmente arranca contenedores. Hoy suele ser **containerd** (el mismo motor que hay debajo de Docker) |
| **kube-proxy** | Programa las reglas de red del nodo para que el tráfico llegue al Pod correcto |

### 2.3 Qué pasa de verdad cuando haces `kubectl apply`

<figure>
<img src="img/s130.png" alt="Detalle de los componentes y el ciclo de kubectl apply">
<figcaption><strong>Figura 3.5.</strong> Los seis pasos que separan tu YAML de un
contenedor corriendo.</figcaption>
</figure>

1. `kubectl` envía el YAML al **API server**.
2. El API server valida y lo guarda en **etcd** → *estado deseado registrado*.
3. El **controller manager** detecta que faltan Pods y crea los objetos Pod.
4. El **scheduler** asigna cada Pod a un nodo con recursos libres.
5. El **kubelet** de ese nodo se entera y llama a containerd.
6. **containerd** descarga la imagen y arranca el contenedor.

!!! practica "El único diagnóstico que hay que retener de este apartado"
    **Un Pod atascado en `Pending` para siempre = el scheduler no encuentra sitio.**
    Falta CPU o memoria. Ya sabes a quién culpar sin mirar nada más.

### 2.4 Nodos y namespaces

Se confunden constantemente, y no tienen nada que ver.

<figure>
<img src="img/s141.png" alt="Namespaces como particiones lógicas">
<figcaption><strong>Figura 3.6.</strong> Los namespaces son particiones lógicas: los
mismos nodos físicos alojan Pods de <code>desarrollo</code> y de
<code>produccion</code> a la vez.</figcaption>
</figure>

!!! definicion "Nodo frente a namespace"
    **Nodo** = división **física**. Una máquina de verdad, con su CPU y su RAM. **Tú no
    eliges** en cuál cae tu Pod: lo decide el scheduler según lo que pidas en
    `resources`. En minikube hay uno; en producción, decenas.

    **Namespace** = división **lógica**. Una carpeta, no una máquina. `dev` y `prod`
    conviven en los mismos nodos físicos sin colisionar. Dos Services llamados
    `postgres` pueden existir a la vez si están en namespaces distintos.

```bash
kubectl get nodes
kubectl get pods -o wide          # la columna NODE dice dónde cayó cada Pod
kubectl get namespaces
kubectl get pods -n produccion    # Pods de un namespace concreto
kubectl get pods -A               # de todos los namespaces
```

!!! aviso "El namespace va dentro del DNS"
    Dentro de tu namespace, `postgres` funciona a secas. **Desde otro** tendrías que
    escribir `postgres.produccion.svc.cluster.local`. La primera vez que alguien mueve
    un pipeline de `dev` a `prod` y no le funciona, suele ser por esto.

!!! practica "El impacto real para un ingeniero de datos"
    Si despliegas un pipeline masivo de Spark en un namespace, **tus procesos se
    distribuyen en paralelo entre múltiples nodos físicos** sin que tú decidas nada. La
    lógica de software gobierna la infraestructura física de forma transparente. Eso es,
    en el fondo, lo que te están vendiendo cuando dicen *cloud native*.

    Y la tolerancia a fallos va en el mismo paquete: si un nodo físico se queda sin red
    o sin luz, el cluster detecta que no responde y **reprograma automáticamente todos
    sus Pods** en los nodos restantes con capacidad libre.

---

## 3. Anatomía de un manifiesto YAML

Buena noticia: **todo en Kubernetes se describe con la misma estructura de cuatro
campos**. Da igual que sea un Pod, un Service o un CronJob. Apréndela una vez.

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

Es de las pocas cosas que conviene tener a mano en una nota.

### 3.1 El YAML muerde

!!! aviso "Vas a perder más tiempo con espacios que con Kubernetes"
    **1. Espacios, nunca tabuladores.** Un tab es un error de sintaxis, sin más.

    **2. La indentación *es* la estructura.** Dos espacios de más y el campo cuelga de
    otro sitio.

    **3. El guion `-` abre un elemento de lista.** `containers:` lleva lista;
    `metadata:` no.

Dos comandos que te van a salvar:

```bash
kubectl apply -f pod.yaml --dry-run=client   # ¿es válido, sin aplicarlo?
kubectl get pod mi-app -o yaml               # ¿cómo lo ha entendido el cluster?
```

!!! error "«error validating data: unknown field …»"
    Casi nunca significa que el campo no exista. Significa que **está colgando del sitio
    equivocado**. Busca la indentación, no el nombre.

Y configura tu editor: dos espacios por tabulador, y que muestre los espacios en blanco.
Cinco minutos de configuración, horas de sufrimiento ahorradas.

### 3.2 Labels y selectors: el pegamento de Kubernetes

Este es el mecanismo más importante y más silencioso del sistema.

<figure>
<img src="img/s136.png" alt="Labels y selectors">
<figcaption><strong>Figura 3.7.</strong> Los objetos no se referencian por nombre, sino
por etiqueta.</figcaption>
</figure>

!!! definicion "Labels y selectors"
    En Kubernetes los objetos **no se referencian por nombre**, sino por **etiquetas**.
    Un Service no dice "manda tráfico a los Pods `mi-app-7d4b-x9`, `mi-app-7d4b-k2`…"
    (que además cambian de nombre constantemente). Dice: **"manda tráfico a todo lo que
    tenga la etiqueta `app: mi-app`"**.

Es un sistema de acoplamiento débil: los Pods pueden ir y venir, cambiar de IP y de
nombre, y todo lo demás sigue encontrándolos porque la etiqueta no cambia.

!!! error "Causa nº 1 de «mi Service no funciona»"
    El `selector` del Service no coincide con las `labels` de los Pods. **Una letra de
    más y el Service se queda sin endpoints… en silencio.** Sin error, sin aviso, sin
    nada. Simplemente deja de funcionar.

    Se diagnostica con:

    ```bash
    kubectl get pods --show-labels
    kubectl describe svc <nombre>      # busca "Endpoints:"
    kubectl get endpoints <nombre>     # si pone <none>, es el selector
    ```

---

## 4. Pod, ReplicaSet y Deployment

### 4.1 El Pod — la unidad mínima

<figure>
<img src="img/s142.png" alt="Anatomía de un Pod">
<figcaption><strong>Figura 3.8.</strong> El Pod es un envoltorio: los contenedores que
contiene comparten IP y almacenamiento, y se ven entre sí por
<code>localhost</code>.</figcaption>
</figure>

!!! definicion "Pod"
    En Docker, la unidad que ejecutas es el **contenedor**. En Kubernetes es el **Pod**:
    un envoltorio que contiene **uno o más contenedores** que comparten **red** (la
    misma IP, se ven por `localhost`) y **almacenamiento**.

**En el 95 % de los casos tendrás un solo contenedor por Pod.** El patrón
multi-contenedor (*sidecar*) se usa para procesos de soporte —un recolector de logs, un
proxy— pero no es tu caso de uso habitual. Guárdalo como cultura general.

!!! aviso "Nunca crees Pods sueltos"
    Si el Pod muere, **nadie lo repone**. Se comporta exactamente igual que un
    `docker run` sin `--restart`. Lo comprobarás tú mismo en el ejercicio 1.

### 4.2 ReplicaSet y Deployment

<figure>
<img src="img/s143.png" alt="Deployment, ReplicaSet y Pods">
<figcaption><strong>Figura 3.9.</strong> El Deployment gestiona un ReplicaSet, y el
ReplicaSet mantiene los Pods. Tú solo escribes el Deployment.</figcaption>
</figure>

!!! definicion "ReplicaSet"
    Garantiza que en todo momento existan **N Pods** con unas etiquetas dadas. Si uno
    muere, crea otro. Es, literalmente, **el bucle de reconciliación aplicado al
    recuento de Pods**.

!!! definicion "Deployment"
    Está por encima del ReplicaSet y añade lo que hace falta para operar de verdad:
    ***rolling updates*** y ***rollback***. Al actualizar, crea un ReplicaSet **nuevo**
    y vacía el viejo poco a poco, sin cortar el servicio.

**Tranquilidad con el ReplicaSet: no lo vas a escribir nunca a mano.** Lo gestiona el
Deployment de forma transparente. Solo tienes que saber que existe para cuando aparezca
en un `kubectl get all` y no te asustes.

**Un Deployment mínimo:**

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

!!! aviso "La estructura de muñeca rusa"
    El `spec` del Deployment contiene un `template`, que es **a su vez la definición de
    un Pod**, con su propio `metadata` y su propio `spec`. Es decir: hay un `spec`
    dentro de otro `spec`. No está mal escrito; es así.

    Y la línea del comentario en mayúsculas es la que rompe despliegues: las `labels`
    del template **deben coincidir** con `selector.matchLabels`. Si no coinciden, el
    Deployment crea Pods que luego no reconoce como suyos.

**Rolling update y rollback:**

```bash
kubectl set image deployment/mi-app app=mi-usuario/mi-imagen:2.0
kubectl rollout status deployment/mi-app     # sigue el progreso
kubectl rollout history deployment/mi-app    # historial de versiones
kubectl rollout undo deployment/mi-app       # vuelve a la anterior
```

Durante el *rolling update*, Kubernetes levanta un Pod nuevo, espera a que esté **listo**
(readiness probe) y solo entonces mata uno viejo. **El número de Pods disponibles nunca
llega a cero.**

!!! practica "Prueba a romperlo a propósito"
    Despliega una imagen que no exista (`:no-existe`). Verás que el Pod nuevo se queda
    en `ImagePullBackOff`… **pero los Pods viejos siguen sirviendo tráfico**. Cero
    *downtime* incluso con un despliegue roto. Esa es la respuesta definitiva a la
    pregunta 5 del apartado 1.1.

### 4.3 El punto ciego de Data Engineering: servicios frente a tareas

<figure>
<img src="img/s144.png" alt="Deployment, Job y CronJob">
<figcaption><strong>Figura 3.10.</strong> No todo corre para siempre. Los procesos de
datos nacen, ejecutan una acción pesada y mueren con éxito.</figcaption>
</figure>

Conviene sembrar esto ya, aunque se desarrolle en el apartado 8:

| | **Deployment** | **Job** | **CronJob** |
|---|---|---|---|
| Para qué sirve | Algo que atiende peticiones | Algo que se ejecuta una vez | Algo que se ejecuta a una hora |
| Cuándo termina | Nunca: ese es el objetivo | Cuando el proceso sale con 0 | Cada ejecución, por separado |
| Si el proceso acaba | **Lo reinicia** | Lo da por completado | Lo da por completado |
| Ejemplo tuyo | Una API, la UI de Airflow | Una carga inicial, una migración | El ETL de las 2:00 |

!!! error "El error clásico: meter una ETL en un Deployment"
    Tu script termina **correctamente**, con éxito, código cero, todo bien. Y
    Kubernetes, que está programado para pensar que un Deployment no debe terminar
    nunca, interpreta que se ha parado de forma no planificada. Y lo reinicia.
    Inmediatamente. **Tu carga de datos se ejecuta en bucle toda la noche.**

    Y lo verdaderamente perverso: **en el panel de control todo parece correcto**, porque
    el Pod aparece como `Running`. Ninguna alarma salta. Te enteras por la factura de la
    nube, o porque alguien de negocio pregunta por qué el informe dice que habéis
    vendido cuarenta veces el mismo pedido.

---

## 5. Services y red interna

### 5.1 El problema

Los Pods son **efímeros y con IP cambiante**. Cada vez que uno se recrea —porque se
cayó, porque escalaste, porque hiciste un *rolling update*— tiene una IP nueva.

<figure>
<img src="img/s148.png" alt="El pipeline de datos estable con Services">
<figcaption><strong>Figura 3.11.</strong> El código del pipeline apunta al Service
estable. Si un Pod de base de datos muere, el flujo ni se entera.</figcaption>
</figure>

**El dolor del ingeniero de datos sin Services**, en cuatro pasos:

1. Conectas tu pipeline directamente a la IP del Pod, `10.244.1.5`.
2. El Pod muere de madrugada por un pico de carga.
3. Kubernetes lo levanta otra vez, pero en otra IP, `10.244.2.18`.
4. Por la mañana tu pipeline lleva horas fallando contra una IP que ya no existe.

### 5.2 La solución: el Service

!!! definicion "Service"
    Una **IP estable y un nombre DNS fijo** que apunta, mediante *labels*, a un grupo de
    Pods, y reparte el tráfico entre ellos.

Y aquí está la continuidad deliberada con la sesión 2:

```
# En Docker Compose:  postgresql://usuario@postgres:5432/db
# En Kubernetes:      postgresql://usuario@postgres:5432/db
#                                            └── nombre del Service
```

La cadena de conexión **no cambia ni un carácter**. Dentro del cluster, el nombre del
Service funciona como *hostname*, exactamente igual que el nombre del servicio en
Compose.

> **Si entendiste la red de Compose, ya entiendes los Services.** Y la regla de "nunca
> escribas una IP en una cadena de conexión" sigue vigente.

### 5.3 Los tres tipos de Service

<figure>
<img src="img/s150.png" alt="Los tres tipos de Service">
<figcaption><strong>Figura 3.12.</strong> ClusterIP cubre el 90 % de los casos.
</figcaption>
</figure>

| Tipo | Alcance | Cuándo | Ejemplo en datos |
|---|---|---|---|
| **ClusterIP** (por defecto) | Solo dentro del cluster | Tu app ↔ tu base de datos. **El 90 % de los casos** | Airflow → Postgres, API interna |
| **NodePort** | Puerto fijo (30000–32767) en todos los nodos | Pruebas y clusters locales | Ver la UI de Spark o el dashboard de Ray temporalmente |
| **LoadBalancer** | Pide un balanceador al proveedor cloud | Exponer a internet en AWS/GCP/Azure | Recibir un flujo masivo de eventos de un Kafka externo (AWS MSK) |

Y una cuarta pieza que no es un Service pero que te va a sonar: el **Ingress**, que
enruta tráfico HTTP según el dominio o la ruta. **No sustituye al Service, trabaja
encima de él.** Es la forma habitual de exponer Superset, JupyterHub o la UI de Airflow.

### 5.4 `port-forward`: tu mejor amigo en local

```bash
kubectl port-forward svc/mi-app 8090:80
#                              │    │
#                              │    └── puerto del Service (dentro del cluster)
#                              └── puerto en TU máquina
```

Se lee **igual que el `-p` de Docker**: izquierda tu máquina, derecha el destino. Abre un
túnel temporal, funciona con cualquier tipo de Service, no requiere tocar ningún
manifiesto, y se cierra con `Ctrl+C`.

!!! practica "Para qué lo vas a usar de verdad"
    **Consultas rápidas**: conectar DBeaver o DataGrip a la base de datos interna del
    cluster. **Interfaces web**: acceder a la UI de Airflow sin montar un Ingress.

!!! aviso "No es para tráfico pesado"
    Es **temporal** y no está diseñado para carga sostenida. Evita extraer gigas de
    datos a tu portátil por un `port-forward`: funciona, pero mal y lento, y alguien lo
    verá en las métricas.

---

## 6. Configuración: ConfigMap y Secret

En Docker ya viste que la configuración **no va dentro de la imagen**. Kubernetes
formaliza esa idea en dos objetos que son, estructuralmente, **casi idénticos**.

### 6.1 ConfigMap — lo no sensible

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

### 6.2 Secret — lo sensible

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:                 # stringData = texto plano; K8s lo codifica solo
  POSTGRES_PASSWORD: "contrasena_segura"
```

!!! practica "Usa `stringData`, no `data`"
    Con `stringData` lo escribes en texto plano y Kubernetes lo codifica por ti. Nada de
    hacer `base64` a mano — que es como la gente acaba con un salto de línea dentro de
    la contraseña y dos horas perdidas.

### 6.3 Cómo se inyectan

**Todas las claves de golpe**, como variables de entorno (el equivalente exacto del
`env_file` de Compose):

```yaml
      containers:
        - name: app
          envFrom:
            - configMapRef: { name: app-config }
            - secretRef:    { name: db-secret }
```

**Una clave concreta**, cuando el nombre de la variable no coincide con el de la clave:

```yaml
          env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: DB_USER
```

**Como archivo montado**, útil para ficheros de configuración enteros:

```yaml
          volumeMounts:
            - name: config
              mountPath: /etc/config
      volumes:
        - name: config
          configMap:
            name: app-config
```

### 6.4 Un Secret NO está cifrado

!!! aviso "Esto hay que decirlo en voz alta"
    Por defecto, un Secret **solo está codificado en base64**, que es trivial de
    revertir:

    ```bash
    kubectl get secret db-secret \
      -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
    # → contrasena_segura
    ```

    Un Secret protege frente a *"que aparezca por accidente en un log o en un
    `kubectl get -o yaml`"*, **no frente a un atacante**. Para seguridad real hace falta
    cifrado en reposo en etcd, RBAC bien configurado, o un gestor externo (HashiCorp
    Vault, AWS Secrets Manager, GCP Secret Manager).

    **Y nunca, jamás, subas a Git un Secret con datos reales.** Un base64 en un
    repositorio no es una contraseña protegida: es una contraseña con un sombrero puesto.

### 6.5 Equivalencias con lo que ya sabes

| Docker / Compose | Kubernetes |
|---|---|
| `-e VAR=valor` | ConfigMap + `envFrom` |
| Archivo `.env` | ConfigMap |
| Contraseñas en `.env` (mala práctica) | Secret (algo mejor) / Vault (bien) |
| `-v ./config.yml:/app/config.yml` | ConfigMap montado como volumen |

!!! practica "Especial para ingenieros de datos: archivos de configuración pesados"
    Montar un ConfigMap **como volumen** es el estándar de la industria para inyectar
    archivos grandes o complejos como un `spark-defaults.conf` o un `airflow.cfg`.

    Funciona en tres pasos: creas el ConfigMap con el contenido completo del archivo, lo
    declaras como volumen en el Pod, y Kubernetes crea el archivo dentro del contenedor
    al arrancar. Y un extra: **cambiar el ConfigMap puede actualizar el archivo montado
    sin reiniciar la aplicación**.

---

## 7. Almacenamiento persistente

En Docker los datos morían con el contenedor. **En Kubernetes es peor**: el Pod no solo
se para, se **recrea en otro nodo**, así que ni siquiera puedes contar con el disco
local.

### 7.1 Los tres niveles

| Tipo | Vive mientras… | Equivalente en Docker |
|---|---|---|
| **emptyDir** | …viva el Pod | Capa de escritura del contenedor |
| **hostPath** | …viva el nodo (**¡y solo ese nodo!**) | Bind mount |
| **PersistentVolume (PV)** | …tú no lo borres | Volumen con nombre |

!!! aviso "Evita `hostPath`"
    Parece la traducción natural del bind mount, pero **ata el Pod a un nodo concreto**.
    Si el Pod se recoloca, los datos se quedan en la otra máquina. Funciona
    perfectamente en minikube —donde solo hay un nodo— y explota el día que lo llevas a
    producción. Que es la peor clase de error: el que solo aparece cuando ya importa.

### 7.2 PV y PVC: la petición y el recurso

<figure>
<img src="img/s161.png" alt="PV y PVC, la analogía de la reserva de mesa">
<figcaption><strong>Figura 3.13.</strong> El PVC es la reserva; el PV es la mesa física.
Tú solo escribes la reserva.</figcaption>
</figure>

!!! definicion "PVC y PV"
    **PersistentVolumeClaim (PVC)** = la *solicitud*: "necesito 5 GB de disco". Lo
    escribes tú, en tu YAML. **Es lo único que escribes normalmente.**

    **PersistentVolume (PV)** = el almacenamiento *real*. Lo crea automáticamente el
    proveedor cloud mediante una **StorageClass** (un disco EBS en AWS, un Persistent
    Disk en GCP) o, en minikube, el propio cluster de forma dinámica.

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

Y se usa en el Pod exactamente como un volumen de Docker, solo que con más ceremonia:

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

### 7.3 Modos de acceso

Este detalle sí lo preguntan en entrevistas.

| Modo | Significado | Típico | Uso en datos |
|---|---|---|---|
| **ReadWriteOnce** (RWO) | Un solo nodo lo monta en escritura | Disco de bloque (AWS EBS) | Bases de datos relacionales |
| **ReadOnlyMany** (ROX) | Muchos nodos, solo lectura | — | Datasets de referencia |
| **ReadWriteMany** (RWX) | Muchos nodos leen y escriben a la vez | Sistema de archivos en red (EFS, NFS) | **Compartir datasets entre workers de Spark**, logs centralizados de Airflow |

> Si te quedas con una: **RWO para bases de datos, RWX para datasets compartidos entre
> workers**. RWX es el salvavidas el día que tengas varios workers de Spark leyendo el
> mismo dataset físico a la vez.

---

## 8. Salud y recursos

Esto es lo que separa un despliegue de juguete de uno de producción.

<figure>
<img src="img/s165.png" alt="Las tres probes">
<figcaption><strong>Figura 3.14.</strong> Tres sondas, tres preguntas distintas — y tres
consecuencias muy distintas si fallan.</figcaption>
</figure>

!!! practica "Por qué esto es especialmente tuyo"
    Mientras un desarrollador web se preocupa de latencias de milisegundos, **el
    ingeniero de datos lidia con pipelines en Python, Spark o pandas que devoran memoria
    como si no hubiera un mañana**. Este apartado es el más rentable de toda la sesión
    para tu perfil.

### 8.1 Probes: ¿está sana tu app?

Punto de partida: **que el proceso corra no significa que funcione**. Una aplicación
puede estar viva y colgada, y `Running` te mentirá alegremente.

| Probe | Pregunta | Si falla… |
|---|---|---|
| **liveness** | ¿Sigue viva? | **Reinicia el contenedor** |
| **readiness** | ¿Está lista para recibir tráfico? | **La saca del Service** (no la reinicia) |
| **startup** | ¿Ha terminado de arrancar? | Reinicia, pero da tiempo extra al arranque |

La distinción liveness/readiness es la más útil y la más preguntada:

- **Readiness fallando** = *"estoy cargando, no me mandes peticiones ahora"*. Kubernetes
  la deja tranquila.
- **Liveness fallando** = *"estoy rota sin remedio"*. Kubernetes la reinicia.

Confundirlas hace que una aplicación que solo estaba ocupada acabe reiniciándose en
bucle.

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

También pueden ser `exec` (ejecutar un comando dentro del contenedor) o `tcpSocket` —
útil para bases de datos que no tienen endpoint HTTP:

```yaml
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "airflow", "-d", "airflow"]
```

Fíjate en que es **exactamente el mismo comando** que usabas como `healthcheck` en
Compose. Cambia el nombre y el sitio donde se declara; el concepto es idéntico.

!!! practica "La startup probe existe por Airflow y compañía"
    Aplicaciones que tardan 60–90 segundos en arrancar. Sin ella, la liveness probe las
    mataría a los 15 segundos, entrando en un bucle infinito de reinicios. Si algún día
    despliegas Airflow en Kubernetes y no arranca nunca, mira esto primero.

### 8.2 `requests` y `limits`

<figure>
<img src="img/s166.png" alt="Requests y limits">
<figcaption><strong>Figura 3.15.</strong> <code>requests</code> es lo que se te
garantiza; <code>limits</code> es el techo. Y las consecuencias de pasarse son
asimétricas.</figcaption>
</figure>

```yaml
          resources:
            requests:        # lo que GARANTIZA tener (el scheduler lo reserva)
              cpu: "100m"    # 100 milicores = 0,1 CPU
              memory: "128Mi"
            limits:          # el máximo que PUEDE usar
              cpu: "500m"
              memory: "512Mi"
```

| | `requests` | `limits` |
|---|---|---|
| **Para qué sirve** | El scheduler lo usa para decidir en qué nodo cabe | Frena a un contenedor que se desmadra |
| **Si te pasas de CPU** | — | *Throttling*: va más lento, pero **sigue vivo** |
| **Si te pasas de memoria** | — | **El contenedor muere: `OOMKilled`** |

!!! error "`OOMKilled`: el error que más veces verás en producción"
    Un `pandas.read_csv()` de un fichero más grande de lo esperado, un `groupby` que
    explota en memoria… **y Kubernetes mata el Pod sin avisar**. Sin traza, sin excepción
    de Python, sin nada: el proceso desaparece y los logs se cortan a mitad.

    Cuando veas un Pod reiniciándose sin logs de error claros:

    ```bash
    kubectl describe pod <pod>     # busca OOMKilled en "Last State"
    ```

!!! definicion "Nota de unidades"
    **`1000m` es un núcleo entero de CPU** (1 vCPU). Así que `500m` es media CPU. La `m`
    es de *milicores*, no de "mega".

### 8.3 Los cuatro estados en los que se te va a quedar un Pod

<figure>
<img src="img/s167.png" alt="Los cuatro estados de fallo de un Pod">
<figcaption><strong>Figura 3.16.</strong> "Running" no sale en esta tabla, y justo por
eso la vas a necesitar. Merece la pena fotografiarla.</figcaption>
</figure>

| Estado | Qué significa | Dónde está la causa |
|---|---|---|
| **Pending** | El scheduler no encuentra un nodo con sitio | `kubectl describe pod` → *Events* |
| **ImagePullBackOff** | No consigue descargar la imagen | Nombre, tag o credenciales del registry |
| **CrashLoopBackOff** | Arranca, se muere, y K8s reintenta cada vez más despacio | `kubectl logs --previous` |
| **OOMKilled** | Se pasó de `limits.memory` | `kubectl describe pod` → *Last State* |

!!! aviso "`CrashLoopBackOff` es el más frecuente y el peor entendido"
    **No es un fallo de Kubernetes: es tu proceso saliendo con código distinto de cero.**
    Kubernetes está haciendo exactamente lo que le pediste.

    Y la clave para diagnosticarlo es el flag **`--previous`**. Sin él lees los logs del
    contenedor que **acaba de arrancar** —que normalmente no ha dicho nada todavía— y no
    los del que **se murió**, que es donde está la explicación:

    ```bash
    kubectl logs <pod> --previous
    ```

    Es el flag que más veces vas a escribir en tus primeros meses.

---

## 9. Job y CronJob

Con diferencia, **los objetos más relevantes para tu perfil**. Si de toda la sesión solo
te llevas un bloque, que sea este.

<figure>
<img src="img/s169.png" alt="Servicios frente a tareas">
<figcaption><strong>Figura 3.17.</strong> Casi todo lo visto hasta ahora corre para
siempre. Casi todo lo que tú haces, no.</figcaption>
</figure>

### 9.1 Job — una vez, hasta completar

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: carga-inicial
spec:
  backoffLimit: 3              # reintentos si falla
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: carga
          image: tu-usuario/pipeline:1.0
          command: ["python", "carga.py"]
```

!!! definicion "La diferencia con un Deployment, en una frase"
    **Un Job no repone el Pod cuando termina bien.** Su objetivo es que el proceso *se
    complete*, no que siga vivo. Si falla, reintenta hasta `backoffLimit` veces.

El contraste es el mismo hecho interpretado de dos formas opuestas: si un Pod de un
**Deployment** termina, Kubernetes piensa *"¡oh no, se ha caído!"* y lo reinicia. Si un
Pod de un **Job** termina con código 0, lo deja en `Completed` y piensa *"buen chico"*.

!!! practica "Dos superpoderes del Job para datos"
    **Paralelismo.** Un Job puede levantar diez Pods a la vez con `parallelism: 10` para
    procesar una cola de Kafka de forma concurrente hasta completar cien tareas
    (`completions: 100`). Es paralelismo gratis: no tienes que escribir ningún
    orquestador.

    **Tolerancia a fallos.** Si tu script falla porque una API externa dio *timeout* —que
    pasa siempre—, el Job lo reintenta automáticamente con `backoffLimit`, sin que tú
    escribas un solo `try/except` de reintentos.

### 9.2 CronJob — un Job nuevo cada vez que toca

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pipeline-diario
spec:
  schedule: "0 2 * * *"           # todos los días a las 02:00
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pipeline
              image: tu-usuario/pipeline:1.0
```

Sintaxis del `schedule` — cron de toda la vida:

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

**Casos de uso reales**, que son literalmente tu futuro trabajo: lanzar la ingesta diaria
del ERP a la base de datos analítica; ejecutar un script de limpieza de tablas huérfanas
los domingos; generar y enviar un informe cada mañana.

!!! practica "Truco para no esperar al horario"
    Puedes disparar una ejecución manual de un CronJob sin esperar a que toque:

    ```bash
    kubectl create job --from=cronjob/pipeline prueba-manual
    ```

    Te va a ahorrar muchas esperas tontas depurando.

!!! aviso "No adivines las expresiones cron"
    Se equivoca todo el mundo, sobre todo con el día de la semana. Y una expresión mal
    puesta **no falla**: simplemente se ejecuta cuando no toca, que es mucho peor.

### 9.3 Entonces, ¿para qué sirve Airflow?

Pregunta completamente legítima. La respuesta es honesta en las dos direcciones:

| | CronJob de Kubernetes | Airflow |
|---|---|---|
| Programar una tarea | Sí | Sí |
| **Dependencias entre tareas** (B después de A) | **No** | **Sí — el DAG** |
| Reintentos con *backoff* por tarea | Básico | Configurable por tarea |
| Interfaz para ver el histórico | `kubectl get jobs` | UI completa |
| **Backfill de fechas pasadas** | **No** | **Sí** |
| Paso de datos entre tareas | No | Sí (XComs, *datasets*) |

Resumiendo: **un CronJob programa *una* cosa. Airflow orquesta *un grafo de cosas* con
dependencias, histórico y backfill.** No compiten.

!!! practica "Y de hecho se combinan"
    El **`KubernetesPodOperator`** de Airflow lanza cada tarea del DAG como un Pod.
    Airflow pone la orquestación, Kubernetes pone la ejecución aislada y el escalado. Es
    la arquitectura estándar en cualquier empresa que corra Airflow sobre K8s — que hoy
    son prácticamente todas las que tienen algo de volumen.

---

## 10. minikube: tu cluster local

**minikube** levanta un cluster de un solo nodo dentro de un contenedor Docker o una VM
en tu máquina. Es el estándar para aprender y para probar manifiestos antes de mandarlos
a un cluster real.

```bash
minikube start --driver=docker --memory=4096 --cpus=2
minikube status
kubectl get nodes                  # deberías ver 1 nodo Ready
kubectl get pods -n kube-system    # los componentes internos, como Pods

minikube dashboard                 # UI web (opcional, muy útil visualmente)
minikube stop                      # apaga el cluster, conserva el estado
minikube delete                    # lo borra entero
```

!!! dato "Un detalle simpático"
    En `kube-system` verás corriendo `etcd`, `kube-apiserver`, `kube-scheduler`,
    `coredns`… **como Pods**. Es decir: **Kubernetes se ejecuta a sí mismo sobre
    Kubernetes.** Elegante y ligeramente recursivo, pero funciona.

### 10.1 El error que tumba a media clase

<figure>
<img src="img/s175.png" alt="minikube tiene su propio almacén de imágenes">
<figcaption><strong>Figura 3.18.</strong> Aunque <code>docker image ls</code> la muestre,
el cluster de minikube no la ve.</figcaption>
</figure>

!!! error "Tus imágenes locales no existen dentro del cluster"
    **minikube tiene su propio almacén de imágenes, separado del de tu Docker.** Es,
    literalmente, otro Docker. Puedes hacer `docker image ls` y ver ahí tu
    `mi-imagen:1.0` tan tranquila… y el cluster no la ve. Al desplegar, intentará
    descargarla de Docker Hub, no la encontrará, y el Pod se quedará en
    **`ImagePullBackOff`** para siempre, mientras tú juras que la imagen existe. Y tienes
    razón: existe. Solo que no ahí.

Tres soluciones:

| Opción | Comando | Cuándo usarla |
|---|---|---|
| **A. Publicar en Docker Hub** | `docker push usuario/imagen:1.0` | **La mejor.** Es lo que harías en producción |
| **B. Cargarla en minikube** | `minikube image load mi-imagen:1.0` | Iterar rápido; la que usamos en clase |
| **C. Construir dentro** | `eval $(minikube docker-env)` y luego `docker build` | Desarrollo intensivo (ojo: cambia tu `docker` de sitio) |

!!! aviso "El *gotcha* dentro del *gotcha*"
    Con las opciones B y C, si tu imagen tiene el tag `latest`, Kubernetes usa por
    defecto `imagePullPolicy: Always` e **intentará descargarla de Docker Hub ignorando
    la copia local que acabas de cargar**. Haces todo bien y sigue fallando.

    Solución: usa **siempre un tag concreto** (`:1.0`) o añade explícitamente
    `imagePullPolicy: IfNotPresent`.

    Es la **tercera vez** en el módulo que `latest` causa un problema. No es casualidad.

### 10.2 Acceder a tus servicios

```bash
kubectl port-forward svc/mi-servicio 8090:80   # lo más fiable, funciona siempre
minikube service mi-servicio                    # abre el navegador (para NodePort)
minikube ip                                     # la IP del nodo
```

---

## 11. Del `docker-compose.yml` al manifiesto

Aquí es donde todo lo de las sesiones anteriores encaja. Este es el mismo servicio en
los dos mundos.

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

**Kubernetes** — el mismo servicio, repartido en **cuatro objetos**:

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

### 11.1 Tabla de traducción

<figure>
<img src="img/s179.png" alt="Tabla de traducción de Docker a Kubernetes">
<figcaption><strong>Figura 3.19.</strong> Cada fila es algo que ya sabías, con otro
nombre.</figcaption>
</figure>

| Lo que conocías (Docker / Compose) | En Kubernetes es… | Para qué lo usas en datos |
|---|---|---|
| `docker run` / contenedor | **Pod** | La unidad mínima donde corre tu script de Python, Spark o tu base de datos |
| Servidor / tu portátil | **Nodo (worker)** | La máquina que aporta la CPU y RAM reales |
| Separar proyectos en carpetas | **Namespace** | Tu "aula virtual" para no mezclar dev con producción |
| `docker compose up` (servicios) | **Deployment** | Mantiene viva tu app o API continua |
| Script de ejecución única | **Job / CronJob** | **Tu pan de cada día**: pipelines ETL programados |
| `localhost` / IPs de contenedores | **Service (ClusterIP)** | La IP/DNS estable para conectar tus pipelines a la base de datos |
| `docker run -p 8080:80` | **`port-forward`** | Tu túnel temporal para DBeaver o la UI de Airflow |
| Variables en `.env` | **ConfigMap** | Inyectar URLs, niveles de log, `airflow.cfg` |
| Contraseñas en `.env` | **Secret** | Claves de AWS, tokens, contraseñas |
| `-v /ruta:/datos` | **PVC / PV** | Almacenamiento persistente para tus bases de datos |
| `-m 4g` (límite de memoria) | **requests / limits** | Evitar que un `read_csv()` mate el nodo (`OOMKilled`) |
| `environment:` | ConfigMap o Secret + `envFrom` | |
| `healthcheck:` | `livenessProbe` / `readinessProbe` | |
| `deploy.replicas:` | `spec.replicas` | |
| `restart: always` | Es el comportamiento por defecto | |
| `networks:` | Automático; se restringe con `NetworkPolicy` | |

**No hay ni una sola idea nueva en esa tabla.** Solo nombres nuevos y más ceremonia. Que
es, sinceramente, el 80 % de lo que es aprender Kubernetes.

### 11.2 La única traducción que no existe

!!! aviso "`depends_on` no tiene equivalente, y es a propósito"
    **Kubernetes no garantiza orden de arranque.** Su filosofía es que tu aplicación
    debe **tolerar** que su dependencia no esté lista. Si tu Pod no encuentra Postgres,
    se reinicia, y en el siguiente intento ya estará.

    Al principio suena a dejadez, pero es lo correcto: en un sistema distribuido las
    dependencias **se caen en cualquier momento**, no solo al arrancar. Una aplicación
    que solo tolera fallos durante el arranque es una aplicación frágil.

    Para los casos que sí necesitan orden estricto —una migración de base de datos antes
    de arrancar, por ejemplo— existen los **initContainers**: contenedores que se
    ejecutan hasta completarse **antes** del contenedor principal.

### 11.3 Comandos: la tabla de equivalencias

| Docker Compose | Kubernetes |
|---|---|
| `docker compose up -d` | `kubectl apply -f .` |
| `docker compose down` | `kubectl delete -f .` |
| `docker compose ps` | `kubectl get pods` |
| `docker compose logs -f x` | `kubectl logs -f deploy/x` |
| `docker compose exec x sh` | `kubectl exec -it deploy/x -- sh` |
| *(no hay equivalente)* | **`kubectl describe pod x`** ← lo primero al depurar |

!!! practica "`kubectl describe` no tiene equivalente en Compose"
    Y es la herramienta de diagnóstico **más importante** de Kubernetes. Al final de su
    salida están los **eventos**: ahí está siempre la causa. Siempre.

---

## 12. Resumen y diagnóstico

### 12.1 Las ideas que hay que llevarse

1. **Kubernetes no sustituye a Compose.** Resuelven cosas distintas.
2. **Imperativo → declarativo.** `docker run` es una orden; `replicas: 3` es una
   promesa que se vigila constantemente.
3. **El bucle de reconciliación** es la razón de que los Pods resuciten solos.
4. **Nunca Pods sueltos.** Usa Deployment (servicios) o Job/CronJob (tareas).
5. **Una ETL en un Deployment se ejecuta en bucle toda la noche**, y el panel dice
   `Running`.
6. **Los Services son el DNS de Compose**, con otro nombre.
7. **Un Secret no está cifrado.**
8. **`OOMKilled`** es el error que más veces verás. Mira `describe`, no `logs`.
9. **`describe` antes que `logs`.** Siempre.

### 12.2 La batería de diagnóstico

<figure>
<img src="img/s182.png" alt="Cuatro síntomas, cuatro comandos">
<figcaption><strong>Figura 3.20.</strong> Si te llevas una sola chuleta de la sesión, que
sea esta.</figcaption>
</figure>

| Síntoma | Primer comando | Qué estás buscando |
|---|---|---|
| **No arranca**: `Pending`, `ImagePullBackOff` | `kubectl describe pod <pod>` | Los *eventos* del final, que explican el fallo de *scheduling* o la descarga fallida |
| **Error en ejecución / bucles**: `CrashLoopBackOff` | `kubectl logs <pod> --previous` | La traza del contenedor **que murió** |
| **El Service no responde** (`Running` pero inaccesible) | `kubectl get endpoints <svc>` | Si pone `<none>`, es el selector |
| **El CronJob no se ejecuta** | `kubectl describe cronjob <cj>` | Si hubo ejecuciones y con qué resultado |

!!! aviso "El orden importa"
    **Siempre `describe` antes que `logs`.** Si el contenedor no ha llegado ni a
    arrancar, no hay logs que leer, y la causa está en los eventos. Ver a alguien
    releyendo logs vacíos durante veinte minutos es un clásico.

### 12.3 Chuleta de `kubectl`

```bash
# ── Ver qué hay ────────────────────────────────────────────────
kubectl get pods                      # pods del namespace actual
kubectl get pods -o wide              # + IP y nodo
kubectl get pods --show-labels        # + etiquetas
kubectl get all                       # todos los objetos comunes
kubectl get pods -A                   # de todos los namespaces

# ── Detalles y diagnóstico ─────────────────────────────────────
kubectl describe pod <pod>            # eventos al final ← lo primero
kubectl logs <pod>                    # logs del contenedor
kubectl logs <pod> --previous         # logs del que MURIÓ ← clave
kubectl logs -f deploy/<nombre>       # seguir en tiempo real
kubectl get events --sort-by=.lastTimestamp
kubectl get endpoints <svc>           # ¿el Service encuentra Pods?

# ── Aplicar y borrar ───────────────────────────────────────────
kubectl apply -f archivo.yaml
kubectl apply -f .                    # todos los YAML de la carpeta
kubectl apply -f x.yaml --dry-run=client   # validar sin aplicar
kubectl delete -f .

# ── Operar ─────────────────────────────────────────────────────
kubectl exec -it deploy/<nombre> -- sh
kubectl port-forward svc/<nombre> 8090:80
kubectl scale deployment/<nombre> --replicas=5
kubectl rollout restart deploy/<nombre>
kubectl rollout undo deployment/<nombre>

# ── Jobs ───────────────────────────────────────────────────────
kubectl get jobs / kubectl get cronjobs
kubectl create job --from=cronjob/<cj> prueba-manual

# ── Limpieza ───────────────────────────────────────────────────
kubectl delete -f .
kubectl get pvc                       # los PVC no siempre se borran con lo anterior
minikube stop                         # apagar (conserva el estado)
minikube delete                       # borrarlo entero
```

!!! aviso "Limpia al terminar"
    minikube ocupa **4 GB de RAM** mientras esté arrancado. Y comprueba los PVC a mano:
    no siempre se borran con `kubectl delete -f .`.

### 12.4 Autoevaluación

1. Explica el bucle de reconciliación usando el termostato, en tres frases.
2. ¿Qué diferencia hay entre `liveness` y `readiness`? ¿Qué pasa si las confundes?
3. Tu Pod está en `CrashLoopBackOff`. ¿Cuál es el **primer** comando que ejecutas, y por
   qué lleva `--previous`?
4. ¿Por qué no debes desplegar un pipeline ETL como Deployment? ¿Qué síntoma verías en el
   panel?
5. Tu Service está creado, los Pods están `Running`, y aun así nadie responde. ¿Qué
   compruebas primero?
6. ¿Qué es un `OOMKilled` y por qué es especialmente frecuente en ingeniería de datos?
7. Cargaste tu imagen con `minikube image load` y el Pod sigue en `ImagePullBackOff`.
   ¿Qué es lo más probable?
8. ¿Por qué `depends_on` no existe en Kubernetes, y qué usarías si necesitas orden
   estricto?
9. Tienes tres workers de Spark que deben leer el mismo dataset a la vez. ¿Qué
   `accessMode` necesitas?

---

## 13. Fin del módulo

Tres sesiones, un mismo hilo: **qué se ejecuta, dónde viven los datos y quién lo
mantiene vivo.**

**Lo que te llevas:**

- Construir y publicar imágenes reproducibles.
- Levantar un stack de datos completo con Compose.
- Desplegar y depurar un pipeline sobre Kubernetes.
- Y, sobre todo, **saber dónde mirar cuando falla** (`kubectl describe` y sus eventos).

**Siguientes pasos naturales:**

- `KubernetesPodOperator` en Airflow.
- **Helm**: plantillas de manifiestos.
- Un cluster gestionado: EKS, GKE, AKS.
- El módulo de *Security and Optimization*.

> No has aprendido Kubernetes para convertirte en administrador de sistemas. Lo has
> aprendido para que cuando mañana escribas un DAG en Airflow usando el
> `KubernetesPodOperator`, sepas exactamente qué CPU estás pidiendo, dónde viven tus
> datos y por qué tu tarea no se va a caer a las tres de la mañana.
