# Guion — Vídeos de teoría (Kubernetes)

**Formato:** 6 vídeos cortos para grabar antes de la sesión en directo. Duración total aprox. **50–60 min**.
Cada bloque incluye: objetivo del vídeo, guion narrado (puedes leerlo casi literal o usarlo como apoyo), y qué diapositiva de `2-presentacion-kubernetes.pptx` corresponde.

Se asume que el alumno ya ha visto las 5 h de Docker: **no se reexplica qué es un contenedor ni una imagen**.

---

## Vídeo 1 — De Docker a Kubernetes (6-8 min)
*Diapositivas 1-4*

**Objetivo:** que entiendan el problema que resuelve Kubernetes antes de ver una sola línea de YAML.

**Guion:**

> Ya sabéis construir una imagen Docker y levantar un contenedor con `docker run`. Eso funciona muy bien... en un portátil, o en un único servidor. Pero pensad en una app real en producción: ¿qué pasa si ese servidor se cae? ¿Qué pasa si tenéis picos de tráfico y necesitáis 10 copias de vuestro contenedor en lugar de 1? ¿Quién decide en qué máquina va cada contenedor si tenéis 20 servidores? ¿Cómo actualizáis la versión de la app sin cortar el servicio?
>
> Todo esto lo podríais hacer a mano con scripts... pero no escala y es frágil. Kubernetes es un **orquestador de contenedores**: un sistema que gestiona automáticamente dónde se ejecutan vuestros contenedores, cuántas copias hay, qué hacer si uno falla, y cómo actualizarlos sin downtime.
>
> La idea central de Kubernetes es el **modelo declarativo**: vosotros no le decís "arranca este contenedor en este servidor" (eso es imperativo, como `docker run`). Le decís **"quiero que en todo momento haya 3 copias de esta app corriendo"**, y Kubernetes se encarga de que eso sea verdad siempre, aunque un servidor se caiga a media noche.

**Puntos clave a remarcar en cámara:**
- Docker = ejecutar un contenedor. Kubernetes = gestionar cientos de contenedores en un cluster de máquinas.
- Self-healing: si un contenedor muere, Kubernetes lo repone solo.
- Escalado: subir o bajar réplicas con un comando (o automáticamente).
- Actualizaciones sin downtime (rolling updates).
- Modelo declarativo: describes el "estado deseado", no los pasos.

---

## Vídeo 2 — Arquitectura de Kubernetes (10-12 min)
*Diapositivas 5-7*

**Objetivo:** que entiendan las piezas del cluster antes de tocar `kubectl`, porque si no, los comandos son magia.

**Guion:**

> Un cluster de Kubernetes tiene dos tipos de máquinas: el **control plane** (el "cerebro") y los **nodos worker** (donde realmente corren vuestros contenedores).
>
> **En el control plane** hay 4 piezas:
> 1. **API server**: es la puerta de entrada única al cluster. Cuando ejecutáis `kubectl apply`, en realidad estáis hablando con el API server por HTTP. Todo pasa por aquí.
> 2. **etcd**: es una base de datos clave-valor donde se guarda **todo** el estado del cluster: qué pods existen, qué configuración tienen, etc. Si etcd se pierde, el cluster pierde su memoria.
> 3. **Scheduler**: cuando se crea un pod nuevo, el scheduler decide en qué nodo va a correr, mirando recursos disponibles, restricciones, etc.
> 4. **Controller manager**: es el que hace real la promesa del modelo declarativo. Compara constantemente "lo que hay" contra "lo que debería haber" y corrige la diferencia. A esto se le llama **bucle de reconciliación**, y es el corazón de cómo funciona Kubernetes por dentro.
>
> **En cada nodo worker** hay 3 piezas:
> 1. **kubelet**: es el agente que habla con el API server y se asegura de que los contenedores que le han asignado a ese nodo estén realmente corriendo. Es el puente entre Kubernetes y el runtime de contenedores.
> 2. **Container runtime**: el mismo concepto que ya conocéis de Docker (hoy en día suele ser `containerd`), es quien realmente arranca y para los contenedores.
> 3. **kube-proxy**: gestiona las reglas de red para que el tráfico llegue a los pods correctos, incluso cuando estos se mueven de sitio.
>
> El flujo completo cuando hacéis `kubectl apply -f deployment.yaml`: kubectl envía el YAML al API server → el API server lo guarda en etcd → el scheduler decide en qué nodo(s) va → el kubelet de ese nodo se entera y le pide al container runtime que arranque el contenedor.

**Puntos clave a remarcar en cámara:**
- El API server es el único punto de entrada; nada habla directamente con etcd.
- El bucle de reconciliación (controller manager) es LA idea central de Kubernetes.
- kubelet = "el Docker de cada nodo, pero obedeciendo al control plane".

---

## Vídeo 3 — Objetos fundamentales: Pod, ReplicaSet, Deployment (10 min)
*Diapositivas 8-10*

**Objetivo:** que sepan leer y escribir un YAML básico de Deployment antes de la práctica.

**Guion:**

> La unidad mínima que se ejecuta en Kubernetes no es un contenedor suelto, es un **Pod**. Un Pod es un envoltorio que contiene uno o más contenedores que comparten red y almacenamiento. En la mayoría de los casos vais a tener un contenedor por Pod (el vuestro, el que construisteis con Docker).
>
> **Nunca vais a crear Pods sueltos en producción**, porque si el Pod muere, nadie lo repone. Para eso existe el **ReplicaSet**, que garantiza que siempre haya N copias de un Pod corriendo. Y por encima del ReplicaSet está el **Deployment**, que es lo que realmente vais a usar casi siempre: gestiona ReplicaSets por vosotros y además permite hacer **rolling updates** (actualizar la versión de la imagen sin downtime, sustituyendo pods poco a poco) y **rollback** (volver atrás si algo sale mal).
>
> Todo esto se define en YAML de forma declarativa. Fijaos en la estructura: `apiVersion`, `kind` (el tipo de objeto), `metadata` (nombre, etiquetas) y `spec` (lo que queréis que exista). Las **labels** son clave: son pares clave-valor que ponéis en los Pods, y luego otros objetos (como los Services que veremos después) los usan para "encontrar" esos Pods.

**Puntos clave a remarcar en cámara:**
- Jerarquía: Deployment → ReplicaSet → Pod → Contenedor(es).
- En la práctica casi siempre se trabaja con Deployments, no con Pods ni ReplicaSets directamente.
- Las labels son el mecanismo de "pegamento" entre objetos en todo Kubernetes.

---

## Vídeo 4 — Services, networking e Ingress (8-10 min)
*Diapositivas 11-12*

**Objetivo:** entender por qué hace falta un Service y qué tipo usar en cada caso.

**Guion:**

> Los Pods son efímeros: mueren y se recrean con una IP nueva cada vez. Si vuestro frontend tuviera que acordarse de la IP de un Pod concreto del backend, se rompería constantemente. Para eso existe el **Service**: una IP estable y un nombre DNS fijo que apunta, mediante labels, a un grupo de Pods, y reparte el tráfico entre ellos.
>
> Hay tres tipos que vais a usar sobre todo:
> - **ClusterIP** (el tipo por defecto): solo accesible dentro del cluster. Es lo normal para que el frontend hable con el backend, o el backend con la base de datos.
> - **NodePort**: abre un puerto fijo en todos los nodos del cluster para poder acceder desde fuera. Es sencillo pero poco usado en producción real.
> - **LoadBalancer**: pide un balanceador de carga al proveedor cloud (AWS, GCP, Azure). Es lo típico para exponer un servicio a internet.
>
> Cuando tenéis varias apps web y queréis exponerlas todas por el puerto 443 con distintos dominios o rutas, usáis un **Ingress**: es una capa de enrutamiento HTTP/HTTPS que decide, según el host o el path de la petición, a qué Service mandarla. Es la puerta de entrada única para el tráfico web del cluster.

**Puntos clave a remarcar en cámara:**
- Service = IP estable + selector por labels + balanceo de tráfico entre Pods.
- ClusterIP para comunicación interna, LoadBalancer para exponer a internet, NodePort sobre todo para pruebas.
- Ingress no sustituye al Service, trabaja encima de él.

---

## Vídeo 5 — Configuración y almacenamiento: ConfigMaps, Secrets, Volúmenes (8 min)
*Diapositivas 13-14*

**Objetivo:** que entiendan por qué NO se debe meter configuración ni contraseñas dentro de la imagen Docker.

**Guion:**

> Una buena práctica que ya deberíais conocer de Docker es no meter configuración "quemada" dentro de la imagen. En Kubernetes esto se resuelve con dos objetos:
>
> **ConfigMap**: guarda configuración no sensible (URLs, nombres de entorno, flags) fuera de la imagen, y se inyecta en el Pod como variables de entorno o como archivos montados. Así la misma imagen sirve para desarrollo, preproducción y producción, solo cambiando el ConfigMap.
>
> **Secret**: es prácticamente igual, pero pensado para datos sensibles (contraseñas, tokens, claves API). Ojo importante para el máster: por defecto, un Secret **no está cifrado**, solo está codificado en base64, que es trivial de decodificar. Para seguridad real hace falta cifrado en etcd o un gestor externo (Vault, cloud KMS). Es un matiz que mucha gente pasa por alto y vale la pena remarcarlo.
>
> Sobre el almacenamiento: el sistema de archivos de un contenedor es efímero, igual que en Docker. Si el Pod muere, esos datos se pierden. Para persistir datos entre reinicios de un Pod, o compartir almacenamiento, Kubernetes usa **Volúmenes**, y para almacenamiento persistente "de verdad" (que sobrevive aunque se borre el Pod), el par **PersistentVolume (PV)** / **PersistentVolumeClaim (PVC)**: el PV es el almacenamiento físico disponible, y el PVC es la "solicitud" que hace un Pod para usar ese almacenamiento.

**Puntos clave a remarcar en cámara:**
- ConfigMap = configuración no sensible; Secret = sensible (pero base64 ≠ cifrado).
- Los contenedores son efímeros: sin volumen, los datos se pierden al reiniciar el Pod.
- PVC es la petición, PV es el recurso real de almacenamiento.

---

## Vídeo 6 — Salud, recursos y escalado (8 min)
*Diapositivas 15-17*

**Objetivo:** cerrar la teoría con lo que hace que un despliegue sea "de producción" de verdad.

**Guion:**

> Tres conceptos finales que marcan la diferencia entre un despliegue de juguete y uno listo para producción.
>
> **Probes (sondas de salud)**: Kubernetes necesita saber si vuestra app está realmente sana, no le basta con que el proceso esté corriendo. Hay tres tipos: **liveness probe** (¿sigue viva la app? si falla, Kubernetes reinicia el contenedor), **readiness probe** (¿está lista para recibir tráfico? si falla, el Service deja de mandarle peticiones, pero no la reinicia) y **startup probe** (para apps que tardan en arrancar, evita que la liveness probe la mate antes de tiempo).
>
> **Resource requests y limits**: le decís a Kubernetes cuánta CPU y memoria necesita como mínimo vuestro contenedor (`requests`, lo usa el scheduler para decidir en qué nodo cabe) y cuánto puede usar como máximo (`limits`, evita que un contenedor se coma todos los recursos del nodo y afecte a los demás).
>
> **HPA (Horizontal Pod Autoscaler)**: con requests bien definidos, Kubernetes puede escalar automáticamente el número de réplicas según el uso de CPU (o memoria, o métricas personalizadas). Así, en un pico de tráfico, el cluster añade Pods solo, y los quita cuando baja la carga.

**Puntos clave a remarcar en cámara:**
- Liveness = "reinícialo si está muerto". Readiness = "no le mandes tráfico si no está listo".
- Sin `requests`/`limits` el HPA no tiene datos fiables para decidir.
- Esta es la última pieza teórica antes de la sesión 100% práctica.

---

## Notas de producción para grabar

- Ritmo objetivo: **habla despacio**, deja 1-2 segundos de silencio tras cada idea clave — facilita que se pueda ver a 1.25x sin perder comprensión.
- Graba cada vídeo por separado (mejor 6 archivos cortos que uno largo): así los alumnos pueden repetir solo el bloque que no entendieron.
- Al final de cada vídeo, añade una pantalla con 1-2 preguntas de repaso (puedes sacarlas del bloque "Recap relámpago" de `3-ejercicios-practicos.md`) — sirven de gancho para la sesión en directo.
- Sube los vídeos con al menos 48h de antelación y pide confirmación de visionado (aunque sea informal) para poder ajustar el tiempo de repaso en directo según cuánta gente los ha visto.
