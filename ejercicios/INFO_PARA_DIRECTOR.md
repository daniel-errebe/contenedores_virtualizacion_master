# Contenido y herramientas del Máster en Data Engineering

## Módulo: Contenedorización (Docker y Kubernetes)

Este documento recoge la información del módulo de contenedorización,
impartido en **tres sesiones consecutivas** sobre un mismo hilo conductor
de Data Engineering — un stack de **Apache Airflow 3 + PostgreSQL** — para
que el alumno vea una progresión única, de un contenedor suelto a un
sistema desplegado en un cluster:

| Sesión | Título | Duración |
|---|---|---|
| **1** | Docker general: imágenes y contenedores | 2 h 40 min |
| **2** | Docker Compose: orquestación de varios servicios | 2 h 20 min |
| **3** | Kubernetes: del contenedor al cluster | 2 h 30 min |

**Enfoque pedagógico**: el público es **Data Engineers, no perfiles
DevOps/plataforma**. No se busca dominio experto de las herramientas, sino
autonomía real para levantar, modificar, depurar y no perder datos en los
stacks con los que trabajarán a diario (Airflow, Spark, dbt, bases de
datos, notebooks). Los conceptos avanzados de infraestructura
(optimización de imágenes, redes personalizadas, Docker Swarm, seguridad y
escaneo de imágenes, CI/CD) se dejan fuera **a propósito**, remitiendo a
módulos posteriores de la formación.

Duración total del módulo: **7 h 30 min** (5 h de Docker repartidas en
las sesiones 1 y 2, + 2 h 30 min de Kubernetes en la sesión 3).

---

## 1. Descripción de los contenidos

### Sesión 1 — Docker general: imágenes y contenedores (2 h 40 min)

Fundamentos de contenedores e imágenes. Es la puerta de entrada al módulo:
no se asume ningún conocimiento previo de contenedorización.

| Unidad | Contenido teórico | Contenido práctico |
|---|---|---|
| **1. Contenedor vs. imagen** | Qué es una imagen (plantilla estática) y un contenedor (instancia en ejecución); diferencia con una máquina virtual (namespaces/cgroups vs. hardware virtualizado); qué es un registro (registry) | — |
| **2. Ejecutar y detener contenedores** | Ciclo de vida (`created` → `running` → `exited` → `removed`); flags clave de `docker run` (`-d`, `--name`, `--rm`, `-it`); inspección con `docker logs` y `docker exec` | **Ej. 1** — primer contenedor, ciclo de vida completo. **Ej. 2** — contenedores efímeros y `--rm` |
| **3. Imágenes en profundidad** | Imágenes oficiales vs. personalizadas; nomenclatura completa (`registry/namespace/repositorio:tag`); registries (Docker Hub, ECR, Artifact Registry...); importancia de los tags para reproducibilidad (`latest` es peligroso); capas y caché de build | **Ej. 5 bis** — crear cuenta en Docker Hub, publicar y descargar una imagen propia en grupo |
| **4. Construir imágenes con un Dockerfile** | Instrucciones básicas (`FROM`, `RUN`, `COPY`, `WORKDIR`, `CMD`); extender una imagen oficial (caso de uso real del Data Engineer); orden de capas para aprovechar la caché; `CMD` sobrescribible por `command:` | **Ej. 4** — primer Dockerfile. **Ej. 5** — añadir dependencias Python (`duckdb`) a la imagen de Airflow |
| **5. Condiciones de arranque** | Políticas de reinicio (`restart`); healthchecks (diferencia entre "arrancado" y "listo") | Se retoma en la sesión 2 (uso real en `depends_on`) |
| **6. Volúmenes y puertos** | Bind mounts vs. volúmenes con nombre (persistencia y diferencias); publicación de puertos (`-p host:contenedor`), `EXPOSE` vs. `-p` | **Ej. 3** — persistencia de datos con PostgreSQL y acceso por puerto |

**Ejercicios de ampliación** relacionados con esta sesión (opcionales):
espacio en disco y capas de imagen, `CMD` vs. `ENTRYPOINT`, políticas de
reinicio.

### Sesión 2 — Docker Compose: orquestación de varios servicios (2 h 20 min)

Continuación directa de la sesión 1. Da respuesta a la pregunta "¿cómo
levanto una aplicación de **varios** contenedores que colaboran?", y
culmina en el recorrido del proyecto real del repositorio.

| Unidad | Contenido teórico | Contenido práctico |
|---|---|---|
| **7. De `docker run` a Compose** | Por qué hace falta un orquestador local cuando hay más de un servicio; traducción de flags de `docker run` a claves de `docker-compose.yml` | **Ej. 6** — primer `docker-compose.yml` |
| **8. Redes en Docker Compose** | Red privada automática por proyecto; DNS interno (los servicios se resuelven por nombre, no por IP) | **Ej. 7** — red entre servicios (Airflow ↔ Postgres) |
| **9. Volúmenes en acción** | Volúmenes con nombre y bind mounts ya combinados en Compose; declaración a nivel de archivo | Integrado en los ejercicios 6-9 |
| **10. Contenedores en desarrollo** | Flujo de trabajo: qué requiere reconstruir la imagen y qué no; bind mount para código, imagen para dependencias | **Ej. 8** — ciclo de desarrollo con DAGs |
| **11. Aplicación final** | Recorrido completo del `docker-compose.yml` real del proyecto (5 servicios de Airflow sobre la misma imagen, Postgres con volumen, healthchecks vistos en la sesión 1, `depends_on` con `condition: service_healthy`, red interna) | **Ej. 9** — arquitectura real. **Ej. 10** — arranque robusto guiado |

**Ejercicios de ampliación** relacionados con esta sesión (opcionales, para
quien va rápido o como trabajo posterior): Adminer como UI de base de
datos, un DAG que escribe en Postgres, un mini-pipeline CSV → pandas →
Postgres, pérdida de datos a propósito (`down` vs. `down -v`), depuración
de un stack roto a ciegas, configuración por variables de entorno.

### Sesión 3 — Kubernetes: del contenedor al cluster (2 h 30 min)

Continuación directa de las sesiones 1 y 2; no se reexplican conceptos ya
vistos (imagen, contenedor, Dockerfile, Compose). Estructurada en tres
partes: conceptos, aplicaciones reales, y práctica sobre minikube.

| Unidad | Contenido teórico | Contenido práctico |
|---|---|---|
| **1. ¿Por qué Kubernetes?** | El problema que resuelve un orquestador de cluster (varios servidores, tolerancia a fallos, escalado); modelo declarativo vs. imperativo; comparativa Compose vs. Kubernetes | — |
| **2. Arquitectura del cluster** | Control plane (API server, etcd, scheduler, controller manager) y nodos worker (kubelet, container runtime, kube-proxy); bucle de reconciliación | Bloque 0 — arrancar minikube e inspeccionar los componentes como Pods del sistema |
| **3. Manifiestos YAML** | Estructura `apiVersion` / `kind` / `metadata` / `spec`; labels y selectores; namespaces | Transversal a todos los ejercicios |
| **4. Pod, ReplicaSet, Deployment** | Jerarquía de objetos; self-healing; rolling update y rollback | **Ej. 1** — Pod aislado vs. Deployment con auto-reparación y escalado |
| **5. Services y red interna** | El problema de las IPs efímeras; tipos de Service (ClusterIP, NodePort, LoadBalancer); `port-forward` | **Ej. 2** — exponer la API propia con un Service, incluido un fallo deliberado de selector |
| **6. ConfigMaps y Secrets** | Separar configuración e imagen (equivalente a lo visto en la sesión 1 con variables de entorno); Secrets en base64 (no cifrado por defecto) | **Ej. 3** — inyectar configuración y credenciales, editar en caliente |
| **7. Almacenamiento** | `emptyDir`, `hostPath`, PersistentVolume/PersistentVolumeClaim; equivalencia directa con los volúmenes de Docker de la sesión 1 | **Ej. 4** — PostgreSQL con almacenamiento persistente |
| **8. Salud y recursos** | Probes (liveness, readiness, startup) — evolución de los healthchecks de la sesión 1; requests y limits; `OOMKilled` como error más común | Integrado en el ejercicio 4 (readinessProbe de Postgres) |
| **9. Job y CronJob** | Cargas por lotes frente a servicios de larga duración; comparación honesta con Airflow (cuándo usar cada uno) | **Ej. 5** — pipeline batch como Job y como CronJob alimentando la base de datos cada 2 minutos (ejercicio central de la sesión) |
| **10. minikube** | Cluster local de un solo nodo; el problema de que las imágenes locales no son visibles para el cluster, y sus tres soluciones | Preparación previa obligatoria + Bloque 0 |
| **11. Del Compose al manifiesto** | Tabla de traducción completa `docker-compose.yml` (sesión 2) → objetos de Kubernetes; qué no tiene equivalente directo (`depends_on`) | **Ej. 6** (opcional) — actualizar la imagen y comprobar despliegue sin caída de servicio |

**Diseño pedagógico clave**: los alumnos publican de antemano su propia
imagen (`mi-pipeline:1.0`) con tres puntos de entrada compartidos —un
generador de datos, una API HTTP y un proceso batch— de modo que la misma
imagen sirve tanto para el Deployment como para el Job/CronJob, solo
cambiando el comando. El ejercicio 5 culmina en un sistema **end to end**
funcionando: un CronJob que alimenta una base de datos con almacenamiento
persistente, expuesta a su vez por una API con réplicas — dando la
sensación de un proyecto real en producción.

---

## 2. Competencias y objetivos

### Al finalizar la sesión 1 (Docker general), el alumno será capaz de:

- Explicar la diferencia entre imagen y contenedor, y por qué los
  contenedores son más ligeros que una máquina virtual.
- Ejecutar, inspeccionar, depurar y eliminar contenedores desde la línea de
  comandos, interpretando su ciclo de vida.
- Elegir el tag correcto de una imagen y entender por qué `latest` no es
  apto para producción.
- Escribir un Dockerfile que extienda una imagen oficial añadiendo
  dependencias propias, ordenando las instrucciones para aprovechar la
  caché de capas.
- Decidir cuándo usar un bind mount y cuándo un volumen con nombre, y
  explicar las consecuencias de no usar ninguno (pérdida de datos).
- Publicar y consumir puertos correctamente, distinguiendo `EXPOSE` de
  `-p`.
- Publicar una imagen propia en Docker Hub y descargarla en otra máquina.

### Al finalizar la sesión 2 (Docker Compose), el alumno será capaz de:

- Traducir una combinación de comandos `docker run` a un único
  `docker-compose.yml` declarativo.
- Levantar una aplicación multi-servicio con Docker Compose, entendiendo la
  red privada y el DNS interno (resolución por nombre de servicio, sin usar
  IPs).
- Diagnosticar por qué un servicio no arranca en el orden esperado,
  combinando `depends_on` con los healthchecks vistos en la sesión 1.
- Distinguir en su flujo de trabajo qué cambios requieren reconstruir la
  imagen y cuáles se reflejan al instante mediante un bind mount.
- Leer y modificar con soltura el `docker-compose.yml` de un stack de datos
  real (Airflow + PostgreSQL) sin sentirlo como una caja negra.

### Al finalizar la sesión 3 (Kubernetes), el alumno será capaz de:

- Explicar qué problema resuelve un orquestador de contenedores frente a
  Docker Compose, y cuándo está justificado dar el salto.
- Interpretar la arquitectura de un cluster (control plane / nodos) y el
  papel de cada componente principal.
- Escribir y aplicar manifiestos YAML para Pods, Deployments y Services,
  comprendiendo el uso de labels y selectores.
- Explicar por qué un Pod suelto no es apto para producción y cómo un
  Deployment proporciona auto-reparación y escalado.
- Exponer una aplicación dentro y fuera del cluster con los distintos tipos
  de Service, y usar `port-forward` para acceso local.
- Separar configuración y credenciales del código mediante ConfigMaps y
  Secrets, y explicar por qué un Secret no es, por sí solo, seguro.
- Desplegar una base de datos con almacenamiento persistente
  (PersistentVolumeClaim) que sobreviva a la eliminación de sus Pods.
- Diferenciar cuándo usar un Job/CronJob frente a un Deployment, y
  argumentar cuándo conviene Airflow en lugar de un CronJob de Kubernetes.
- Levantar un cluster local con minikube y resolver el problema más
  frecuente de ese entorno (imágenes locales no visibles para el cluster).
- Traducir mentalmente un `docker-compose.yml` a los objetos de Kubernetes
  equivalentes.
- Desplegar y operar, de principio a fin, un sistema con varios
  componentes que colaboran (API, base de datos persistente, proceso
  programado), reproduciendo la sensación de un despliegue real.

---

## 3. Herramientas y recursos

### Software y cuentas (instalación previa obligatoria)

| Herramienta | Uso | Alternativas por sistema operativo |
|---|---|---|
| **Docker** (motor + CLI + Compose v2) | Sesiones 1 y 2 | macOS: Docker Desktop o Colima · Windows: Docker Desktop + WSL2, Docker Engine en WSL, o Rancher Desktop · Linux: Docker Engine nativo |
| **Cuenta de Docker Hub** | Sesiones 1 a 3 (publicar y descargar imágenes; evita límites de descarga por IP compartida en el aula) | — |
| **Git** | Clonar el repositorio de la asignatura | Incluido en macOS/Linux/WSL; instalación aparte en Windows nativo (no recomendado) |
| **Editor de código (VS Code recomendado)** | Las tres sesiones | Cualquier editor equivalente |
| **minikube + kubectl** | Sesión 3 (Kubernetes) | Homebrew (macOS), winget (Windows), binarios oficiales (Linux) |
| **WSL2** | Solo Windows | Paso obligatorio antes de instalar Docker |

Requisitos de máquina: mínimo 8 GB de RAM (16 GB recomendado), 20-30 GB de
disco libre, virtualización habilitada en la BIOS/UEFI. Documentados con
detalle, verificación paso a paso y solución de problemas por sistema
operativo en el documento de requisitos (ver más abajo).

### Materiales digitales elaborados para el módulo

| Documento | Contenido |
|---|---|
| `REQUISITOS.md` | Guía de instalación exhaustiva por sistema operativo (macOS, Windows/WSL, Linux), cuentas necesarias, verificación final y solución de problemas frecuentes |
| `TEORIA.md` | Teoría completa de Docker, organizada en las 11 unidades descritas en la sección 1 |
| `EJERCICIOS.md` | 10 ejercicios núcleo + 1 ejercicio de grupo (publicación en Docker Hub), con objetivo, solución oculta y validación |
| `EJERCICIOS_EXTRA.md` | 9 ejercicios de ampliación para quien va rápido o como trabajo posterior |
| `GUION_VIDEOS_TEORIA.md` | Guion narrado para 7 vídeos cortos de apoyo (teoría de Docker en formato asíncrono) |
| `TEORIA_KUBERNETES.md` | Teoría completa de Kubernetes, organizada en 11 unidades y 2 apéndices |
| `EJERCICIOS_KUBERNETES.md` | 6 ejercicios prácticos sobre minikube, con preparación previa obligatoria (construir y publicar la imagen propia) |
| `GUIA_PROFESOR.md` | Documento operativo interno: cronograma minuto a minuto, checklist previo, problemas frecuentes en el aula, ideas de evaluación |

### Recursos de referencia externos

- Imágenes oficiales de Docker Hub: `postgres:18-alpine`,
  `apache/airflow:3.3.1-python3.14`, `python:3.13-slim`, `alpine:3.21`.
- Curso [DevOps with Docker](https://courses.mooc.fi/org/uh-cs/courses/devops-with-docker-spring-2026)
  (Universidad de Helsinki, licencia CC BY-NC-SA), origen de varios
  conceptos adaptados al material.
- Proyecto real del repositorio (`docker-compose.yml` con Airflow 3 +
  PostgreSQL), usado como hilo conductor y caso final de las tres
  sesiones.

---

## 4. Evaluación

El módulo se evalúa **por proyecto práctico, no por test**. La razón
pedagógica: los comandos y flags concretos se consultan en segundos en la
documentación oficial; lo que interesa medir es la comprensión real de los
conceptos (por qué falla algo, qué se pierde si no hay volumen, por qué un
servicio no conecta con otro) y la capacidad de aplicarlos a un stack de
datos.

### Opciones de proyecto (sesiones 1 y 2, Docker)

Se evalúan conjuntamente porque el proyecto natural requiere tanto
imágenes propias (sesión 1) como Compose (sesión 2):

1. **Entrega de depuración (recomendada)**: se entrega a cada alumno un
   `docker-compose.yml` con 4-5 fallos deliberados (puertos mal
   publicados, variables de entorno incorrectas, `depends_on` sin
   condición de salud, volumen mal montado...). El alumno debe identificar
   y corregir cada fallo, y **explicar por qué** ocurría. Evalúa
   comprensión real por encima de memorización.
2. **Extensión del proyecto**: añadir un servicio nuevo al stack existente
   (por ejemplo, Adminer, MinIO o un Jupyter) y un DAG de Airflow que lo
   utilice.
3. **Pipeline propio**: construir un mini-pipeline de ingesta (CSV →
   transformación con pandas → PostgreSQL) empaquetado en su propia imagen,
   sobre un dataset elegido por el alumno.

### Proyecto de la sesión 3 (Kubernetes)

Continuación natural del ejercicio central de la sesión (ejercicio 5): se
pide al alumno desplegar, sobre su cluster de minikube, un sistema completo
compuesto por al menos:

- Una base de datos con almacenamiento persistente (PVC).
- Un componente que escribe datos de forma periódica (CronJob).
- Un componente que expone esos datos (Deployment + Service).
- Configuración y credenciales separadas del código (ConfigMap + Secret).

Como entrega, el alumno documenta los manifiestos usados y demuestra que
los datos persisten tras eliminar y recrear los Pods correspondientes —el
mismo criterio de éxito que se practica en clase.

### Criterios comunes

- Se valora la **explicación razonada** de cada decisión (por qué un bind
  mount y no un volumen con nombre, por qué un Job y no un Deployment) por
  encima del resultado final funcionando "por probar cosas".
- No se evalúan preguntas tipo test sobre sintaxis de la CLI: se considera
  que no mide comprensión y es fácilmente resoluble por consulta directa a
  la documentación.
