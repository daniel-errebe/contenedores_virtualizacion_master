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

## Módulo 0 — ¿Qué es Docker?

Máster en Data Engineering, MLOps & Arquitectura Cloud

---

# Antes de tocar un solo comando

## Media hora para entender qué problema resuelve Docker y por qué acabó en todas partes

<div class="pasos">
<div><b>01</b><span>El problema real que existía antes de que Docker apareciera</span></div>
<div><b>02</b><span>Cómo se intentaba resolver, y por qué no bastaba</span></div>
<div><b>03</b><span>De dónde sale Docker y qué inventó exactamente</span></div>
<div><b>04</b><span>Para qué se usa hoy en DevOps</span></div>
<div><b>05</b><span>Para qué lo vas a usar tú, en Data Engineering</span></div>
</div>

<div class="aviso">

Sin ejercicios. Este bloque es contexto: la sesión 1 empieza justo donde este termina.

</div>

---

<!-- _class: seccion -->

<div class="num">1</div>

# El problema

## Una frase que ha costado millones de euros en horas perdidas.

---

<!-- _class: lima -->

# "En mi máquina funciona"

## No es una excusa: casi siempre es literalmente cierto

<div class="cols">
<div>

### Tu portátil

- Python 3.11
- pandas 2.1
- Postgres 16
- macOS, Apple Silicon
- Una variable de entorno que pusiste hace tres meses y ya no recuerdas

</div>
<div>

### El servidor de producción

- Python 3.9
- pandas 1.5
- Postgres 13
- Ubuntu 20.04, x86
- Otra configuración distinta, puesta por otra persona

</div>
</div>

<div class="destacado">

El código es idéntico. El <b>entorno</b> no.<br>Y el software se ejecuta en un entorno, no en el vacío.

</div>

---

# El coste real de ese desajuste

## No es un problema estético: es la mayor fuente de fricción entre desarrollo y operaciones

<div class="pasos">
<div><b>01</b><span>Un pipeline que funciona en local y falla de madrugada en producción</span></div>
<div><b>02</b><span>Dos días de un ingeniero replicando un entorno a mano, con un documento de 40 pasos</span></div>
<div><b>03</b><span>Dos proyectos en el mismo servidor que necesitan versiones incompatibles de la misma librería</span></div>
<div><b>04</b><span>Un compañero nuevo que tarda una semana en poder ejecutar el proyecto</span></div>
<div><b>05</b><span>Nadie se atreve a actualizar nada, porque nadie sabe qué se rompería</span></div>
</div>

---

<!-- _class: seccion -->

<div class="num">2</div>

# El intento anterior:<br>máquinas virtuales

## La idea correcta, con el peso equivocado.

---

# La máquina virtual: llevarse el ordenador entero

## Si el problema es el entorno, empaquetamos el entorno completo

<pre class="diagrama">
┌──────────────────────────────────────────────────────┐
│   App A         App B         App C                  │
├──────────────┬──────────────┬────────────────────────┤
│ Librerías    │ Librerías    │ Librerías              │
├──────────────┼──────────────┼────────────────────────┤
│ SISTEMA      │ SISTEMA      │ SISTEMA                │
│ OPERATIVO    │ OPERATIVO    │ OPERATIVO              │
│ COMPLETO     │ COMPLETO     │ COMPLETO               │
│  (~2 GB)     │  (~2 GB)     │  (~2 GB)               │
├──────────────┴──────────────┴────────────────────────┤
│         HIPERVISOR (VMware, VirtualBox, KVM)         │
├──────────────────────────────────────────────────────┤
│            Sistema operativo anfitrión               │
├──────────────────────────────────────────────────────┤
│                      HARDWARE                        │
└──────────────────────────────────────────────────────┘
</pre>

<div class="aviso">

Cada máquina virtual lleva **un sistema operativo entero**, con su propio kernel.
Ahí está a la vez su gran virtud —el aislamiento es total— y su gran problema.

</div>

---

# Funciona, pero el precio es alto

## Tres o cuatro VMs y tu portátil se rinde

| Aspecto | Máquina virtual |
|---|---|
| **Tamaño** | Gigabytes: lleva un sistema operativo completo |
| **Arranque** | Minutos: arranca un SO de verdad, con su kernel |
| **Densidad** | Unas pocas por servidor |
| **Recursos** | RAM y CPU reservadas por adelantado, se usen o no |

<div class="aviso">

Para aislar una aplicación de 50 MB, arrancas un sistema operativo de 2 GB.
La idea es correcta; la unidad de empaquetado es demasiado gruesa.

</div>

---

<!-- _class: seccion -->

<div class="num">3</div>

# Cómo surge Docker

## 2013. Y lo que inventó no fue la tecnología.

---

<!-- _class: denso -->

# Las piezas ya existían, repartidas por el kernel de Linux

## Docker no inventó el aislamiento: llevaba décadas ahí

| Año | Pieza | Qué aportó |
|---|---|---|
| **1979** | `chroot` | Cambiar la raíz del sistema de archivos de un proceso |
| **2002** | *namespaces* | Que un proceso vea su propia red, sus propios procesos, su propio sistema de archivos |
| **2006** | *cgroups* (de Google) | Limitar cuánta CPU y memoria puede consumir un grupo de procesos |
| **2008** | LXC | Junta lo anterior en "contenedores de Linux"… pero es difícil de usar |

<div class="aviso">

Todo estaba disponible y era gratis. Y casi nadie lo usaba, porque montar un contenedor
a mano con esas herramientas requería ser experto en el kernel.

</div>

---

# 2013: dotCloud, una empresa a punto de cerrar

## Solomon Hykes presenta una herramienta interna en una charla de cinco minutos

<div class="cols-58">
<div>

**dotCloud** era una plataforma para desplegar aplicaciones. Para hacerlo, habían construido
una capa interna que empaquetaba el código de sus clientes en contenedores de Linux.

El negocio no despegaba. Liberaron esa capa interna como proyecto de código abierto en
**marzo de 2013**, en la PyCon de Santa Clara.

En meses, el proyecto valía más que la empresa. dotCloud se renombró **Docker, Inc.**

</div>
<div>

<div class="destacado">

Docker no inventó los contenedores.<br>Los hizo <b>usables</b>.

</div>

</div>
</div>

---

<!-- _class: lima -->

# Lo que Docker inventó de verdad fueron tres cosas

## Ninguna es tecnología de kernel. Las tres son de experiencia de uso

<div class="pasos">
<div><b>01</b><span>Un <b>formato de imagen</b> por capas: empaquetar una aplicación y su entorno en un artefacto inmutable y reutilizable</span></div>
<div><b>02</b><span>El <b>Dockerfile</b>: una receta de texto, versionable en Git, que describe cómo se construye esa imagen</span></div>
<div><b>03</b><span>Un <b>registro público</b>, Docker Hub: un sitio del que descargar imágenes ya hechas y al que subir las tuyas</span></div>
</div>

<div class="destacado">

Estandarizar el <b>empaquetado</b> y el <b>reparto</b>.<br>Eso es lo que cambió la industria.

</div>

---

# La analogía que le da nombre

## Antes del contenedor de mercancías, cada carga se manipulaba a mano

<div class="cols">
<div>

### Transporte, antes de 1956

Sacos, cajas, barriles. Cada mercancía se cargaba de una forma distinta.
Descargar un barco: días.

Los barcos, las grúas y los camiones tenían que conocer la carga.

</div>
<div>

### Con el contenedor estándar

Una caja metálica de medidas fijas. Da igual lo que lleve dentro.

El barco, la grúa y el camión **solo conocen la caja**.

Descargar un barco: horas.

</div>
</div>

<div class="destacado">

Docker hace lo mismo con el software: da igual si dentro hay Python, Java o Go.<br>
La plataforma solo conoce el contenedor.

</div>

---

# Contenedor frente a máquina virtual

## Se comparte el kernel del anfitrión: ahí está toda la diferencia

<pre class="diagrama">
      MÁQUINAS VIRTUALES              CONTENEDORES
┌────────┬────────┬────────┐   ┌────────┬────────┬────────┐
│ App A  │ App B  │ App C  │   │ App A  │ App B  │ App C  │
├────────┼────────┼────────┤   ├────────┼────────┼────────┤
│ Libs   │ Libs   │ Libs   │   │ Libs   │ Libs   │ Libs   │
├────────┼────────┼────────┤   ├────────┴────────┴────────┤
│  S.O.  │  S.O.  │  S.O.  │   │      Docker Engine       │
│ (2 GB) │ (2 GB) │ (2 GB) │   │                          │
├────────┴────────┴────────┤   ├──────────────────────────┤
│       HIPERVISOR         │   │    Sistema operativo     │
├──────────────────────────┤   │   (kernel COMPARTIDO)    │
│   Sistema operativo      │   ├──────────────────────────┤
├──────────────────────────┤   │        HARDWARE          │
│        HARDWARE          │   └──────────────────────────┘
└──────────────────────────┘
</pre>

---

<!-- _class: denso -->

# La comparación en números

## No es "mejor" ni "peor": es una unidad de empaquetado más fina

| | Máquina virtual | Contenedor |
|---|---|---|
| **Qué aísla** | Hardware completo, con su propio kernel | Procesos, sobre el kernel del anfitrión |
| **Tamaño típico** | 1–20 GB | 50 MB – 1 GB |
| **Tiempo de arranque** | Minutos | **Menos de un segundo** |
| **Cuántos por servidor** | Unas decenas | **Cientos** |
| **Aislamiento** | Muy fuerte | Bueno, pero comparte kernel |
| **Cuándo usar cada uno** | Sistemas operativos distintos, aislamiento estricto | Empaquetar y desplegar aplicaciones |

<div class="aviso">

Conviven: en la nube, tus contenedores casi siempre corren **dentro** de máquinas virtuales.
Y en macOS y Windows, Docker Desktop arranca una VM de Linux, porque los contenedores
necesitan un kernel de Linux.

</div>

---

<!-- _class: seccion -->

<div class="num">4</div>

# Qué es Docker,<br>en concreto

## Tres piezas y un verbo. Todo lo demás es detalle.

---

<!-- _class: lima -->

# Las tres piezas del vocabulario

## Las vas a usar durante las tres sesiones. Y en el resto del máster

<div class="pasos">
<div><b>01</b><span><b>Imagen</b> — la plantilla inmutable: tu código, sus dependencias y el sistema base. Como una clase en programación, o un molde</span></div>
<div><b>02</b><span><b>Contenedor</b> — una imagen en ejecución. Como una instancia de esa clase. De una imagen salen mil contenedores idénticos</span></div>
<div><b>03</b><span><b>Registro</b> — el almacén de imágenes. Docker Hub es el público; toda empresa seria tiene el suyo privado</span></div>
</div>

<div class="destacado">

Imagen : contenedor  ::  clase : objeto  ::  receta : plato

</div>

---

# El ciclo completo, en un diagrama

## Es todo lo que hace Docker, y lo verás entero en la sesión 1

<pre class="diagrama">
   ┌────────────┐  docker build  ┌────────────┐  docker run  ┌──────────────┐
   │ Dockerfile │ ─────────────► │   IMAGEN   │ ───────────► │  CONTENEDOR  │
   │ (la receta,│                │(artefacto  │              │(en ejecución)│
   │  en Git)   │                │ inmutable) │              │              │
   └────────────┘                └─────┬──────┘              └──────────────┘
                                       │  ▲
                          docker push  │  │  docker pull
                                       ▼  │
                               ┌────────────────┐
                               │    REGISTRO    │
                               │  (Docker Hub)  │
                               └────────────────┘

   El MISMO artefacto corre en tu portátil, en el CI y en producción.
</pre>

---

# Qué NO es Docker

## Tres malentendidos que conviene desactivar hoy

<div class="pasos">
<div><b>01</b><span><b>No es una máquina virtual ligera.</b> No hay un sistema operativo dentro: son procesos aislados del anfitrión con funciones del kernel de Linux</span></div>
<div><b>02</b><span><b>No resuelve solo tus dependencias.</b> Te obliga a <i>declararlas</i> explícitamente, que es lo que las hace reproducibles. El trabajo lo sigues haciendo tú</span></div>
<div><b>03</b><span><b>No es seguro por defecto.</b> Un contenedor mal configurado puede acceder al anfitrión. Aísla, pero no es una barrera de seguridad completa</span></div>
</div>

---

<!-- _class: seccion -->

<div class="num">5</div>

# Para qué se usa

## Primero en DevOps, donde nació. Después, en todo lo demás.

---

# En DevOps: Docker es lo que hizo posible el CI/CD moderno

## El mismo artefacto atraviesa todas las etapas sin volver a construirse

<pre class="diagrama">
  git push
     │
     ▼
 ┌─────────┐   ┌──────────┐   ┌─────────┐   ┌────────────┐
 │  BUILD  │──►│  TESTS   │──►│ STAGING │──►│ PRODUCCIÓN │
 │ imagen  │   │ sobre la │   │ la MISMA│   │  la MISMA  │
 │ :a3f9c1 │   │  MISMA   │   │  imagen │   │   imagen   │
 └─────────┘   └──────────┘   └─────────┘   └────────────┘

  Lo que se prueba es exactamente lo que se despliega.
</pre>

<div class="aviso">

Sin contenedores, cada entorno se construye por separado y puede diferir.
Con contenedores, si pasa los tests, pasa en producción — o el fallo es de datos, no de entorno.

</div>

---

<!-- _class: denso -->

# Los cinco usos de Docker en DevOps

## Todos aparecen en el resto del máster

| Uso | Qué resuelve |
|---|---|
| **Entornos de desarrollo** | Un comando y tienes el stack entero. Alta de un compañero nuevo: minutos |
| **CI/CD** | Construir una vez, desplegar el mismo artefacto en todos los entornos |
| **Despliegue reproducible** | La imagen `:a3f9c1` de hoy es idéntica dentro de dos años |
| **Aislamiento de versiones** | Dos proyectos con Python 3.9 y 3.13 en el mismo servidor, sin conflicto |
| **Base de la nube** | ECS, Cloud Run, App Runner, Kubernetes: **todos** consumen imágenes de contenedor |

<div class="aviso">

Ese último punto es el importante: hoy, la unidad de despliegue estándar en cualquier nube
**es una imagen de contenedor**. No saber Docker cierra la puerta a todo lo demás.

</div>

---

<!-- _class: seccion -->

<div class="num">6</div>

# Y en Data Engineering

## Aquí es donde deja de ser cultura general y pasa a ser tu trabajo diario.

---

<!-- _class: lima -->

# El problema de dependencias en datos es peor que en cualquier otro sitio

## Y por eso los contenedores encajan tan bien

<div class="cols">
<div>

### Lo que arrastra un stack de datos

- Python con `pandas`, `numpy`, `pyarrow`
- Bibliotecas de sistema en C: `libpq`, `libgeos`, `libhdf5`
- La **JVM**, si hay Spark
- Drivers ODBC, clientes de base de datos
- Versiones de Airflow con dependencias fijadas al milímetro

</div>
<div>

### Por qué duele

Un `pip install` que falla al compilar en Linux pero funciona en macOS.

Un cluster de Spark donde cada nodo tiene una versión distinta de una librería.

Una imagen resuelve las dos cosas: se construye una vez y corre igual en todas partes.

</div>
</div>

---

<!-- _class: denso -->

# Dónde te vas a encontrar Docker, en concreto

## Seis casos, todos reales, casi todos en este máster

| Caso | Qué hace Docker |
|---|---|
| **Airflow** | El despliegue estándar es Compose o Kubernetes. La imagen oficial lleva scheduler, webserver y workers |
| **Bases de datos en local** | Postgres, MySQL, Redis, Kafka o MinIO en un comando, sin instalar nada y sin ensuciar tu equipo |
| **Spark** | Cada ejecutor arranca como un contenedor con exactamente las mismas dependencias |
| **dbt** | La imagen fija la versión de dbt y del adaptador. Sin sorpresas entre tu equipo y el CI |
| **Tareas de un DAG** | `DockerOperator` y `KubernetesPodOperator`: cada tarea corre en su propia imagen aislada |
| **Notebooks y ML** | La imagen fija versiones de CUDA, PyTorch y drivers. Reproducibilidad de experimentos |

---

# Un ejemplo que reconocerás de inmediato

## El mismo objetivo, con y sin contenedores

<div class="cols">
<div>

### Sin Docker

```bash
# Instala Postgres 16
# Configura el usuario
# Instala Python 3.11
# Crea el venv
# pip install -r requirements.txt
#   → falla al compilar psycopg2
# Instala libpq-dev
# Repite en el servidor
# Documenta 40 pasos en Confluence
# El documento queda obsoleto en 2 semanas
```

</div>
<div>

### Con Docker

```bash
docker compose up -d
```

<div class="destacado">

Y el <code>docker-compose.yml</code> está en Git,<br>versionado junto al código.

</div>

</div>
</div>

---

# El ecosistema hoy: Docker ya no está solo

## Y aun así, es por donde se empieza

<div class="pasos">
<div><b>01</b><span><b>OCI</b> (2015) — el formato de imagen se estandarizó. Ya no es "de Docker": es un estándar abierto de la industria</span></div>
<div><b>02</b><span><b>containerd</b> — el motor que ejecuta contenedores, extraído de Docker y donado a la CNCF. Es lo que usa Kubernetes por debajo</span></div>
<div><b>03</b><span><b>Podman, Buildah</b> — alternativas compatibles, sin demonio y sin necesidad de root</span></div>
<div><b>04</b><span><b>Kubernetes</b> — orquesta esos contenedores en cientos de máquinas. La sesión 3 de este módulo</span></div>
</div>

<div class="aviso">

Kubernetes dejó de usar Docker como motor en 2022. Pero sigue ejecutando **imágenes**
construidas con Docker: el formato es estándar. Por eso lo que aprendes hoy no caduca.

</div>

---

<!-- _class: lima -->

# Resumen del módulo 0

## Cinco frases

<div class="pasos">
<div><b>01</b><span>El problema no es el código: es el <b>entorno</b> en el que se ejecuta</span></div>
<div><b>02</b><span>Las máquinas virtuales lo resolvían, pero empaquetando un sistema operativo entero</span></div>
<div><b>03</b><span>Un contenedor comparte el kernel del anfitrión: pesa megas, arranca en un segundo</span></div>
<div><b>04</b><span>Docker no inventó los contenedores: inventó el <b>formato</b>, la <b>receta</b> y el <b>registro</b></span></div>
<div><b>05</b><span>Hoy es la unidad de despliegue estándar de la nube, y la base de Airflow, Spark y Kubernetes</span></div>
</div>

---

<!-- _class: verde -->

# Y ahora, a la práctica

## La sesión 1 empieza donde termina esta explicación

<div class="cols">
<div>

### Lo que acabas de ver

El **porqué**: qué problema resuelve Docker,
de dónde viene y en qué encaja.

</div>
<div>

### Lo que viene ahora

El **cómo**: tu primer contenedor, dónde viven
los datos, cómo se publica un puerto
y cómo se construye una imagen propia.

</div>
</div>

<div class="destacado">

Sesión 1 — Imágenes y contenedores

</div>

---


<!-- _class: portada -->
<!-- _paginate: false -->

# Módulo:<br>Contenedores<br>y Kubernetes

## Sesión 1 — Imágenes y contenedores

Máster en Data Engineering, MLOps & Arquitectura Cloud

---

# El módulo son tres sesiones

## Cada una se apoya en la anterior; no hay atajos

| Sesión | Contenido | Duración |
|---|---|---|
| *0* | *¿Qué es Docker? Contexto e historia* | *30 min* |
| **1. Hoy** | Imágenes y contenedores: ejecutar, inspeccionar, persistir, construir | 2 h 40 |
| **2** | Docker Compose: varios servicios que se hablan entre sí | 2 h 20 |
| **3** | Kubernetes: del contenedor al cluster | 2 h 30 |

<div class="aviso">

Además hay **7 vídeos cortos de teoría** (unos 65 min en total) que debes ver antes.
La clase en vivo es para practicar, no para escuchar.

</div>

---

<!-- _class: lima -->

# Docker no es una herramienta más de la lista

## Es la capa por la que hoy pasa casi todo lo que despliegas

**Python** → **Git** → **Docker** → **Airflow** → **Spark** → **Kubernetes** → **Cloud**

<div class="destacado">

Si entiendes qué es una imagen, qué es un contenedor y dónde viven los datos,
las herramientas de arriba dejan de parecer cajas negras.

</div>

---

# El objetivo es defenderse, no memorizar comandos

## Al terminar la sesión de hoy podrás

<div class="pasos">
<div><b>01</b><span>Explicar la diferencia entre imagen y contenedor sin dudar</span></div>
<div><b>02</b><span>Arrancar, inspeccionar, parar y borrar contenedores con criterio</span></div>
<div><b>03</b><span>Hacer que los datos sobrevivan al borrado del contenedor</span></div>
<div><b>04</b><span>Publicar un puerto y saber por qué a veces no funciona</span></div>
<div><b>05</b><span>Escribir un Dockerfile que añada dependencias a una imagen oficial</span></div>
</div>

---

# Contenido de la sesión

## Seis bloques de teoría, cinco ejercicios intercalados

<div class="cols">
<div>

**0.** Comprobación del entorno
**1.** ¿Qué es un contenedor? ¿Y una imagen?
**2.** Ejecutar y detener contenedores
  → *Ejercicios 1 y 2*
**3.** Volúmenes y puertos
  → *Ejercicio 3*

</div>
<div>

**4.** Imágenes en profundidad
  → *Ejercicio 5 bis (en grupo)*
**5.** Construir imágenes con Dockerfile
  → *Ejercicios 4 y 5*
**6.** Condiciones de arranque
**7.** Cierre y puente a la sesión 2

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">0</div>
<div class="reloj">≈ 0:00</div>

# Comprobar el entorno

## Cinco minutos ahora evitan cuarenta minutos de incidencias repartidas por toda la sesión.

---

<!-- _class: navy -->

# Antes de seguir: valida tu instalación

## Si algo falla aquí, avísame ahora — no dentro de una hora

<div class="cols-58">
<div>

```bash
$ docker --version
Docker version 27.x.x

$ docker run --rm hello-world
Hello from Docker!

$ docker compose version
Docker Compose version v2.x.x

$ docker images | wc -l
```

</div>
<div>

### Si algo no responde

Revisa **REQUISITOS.md**, sección 8.

**macOS** — ¿arrancaste Colima o Docker Desktop?
**Windows** — ¿marcaste *WSL Integration*?
**Linux** — ¿hiciste `usermod -aG docker`?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">1</div>
<div class="reloj">≈ 0:15</div>

# ¿Qué es un contenedor?<br>¿Y una imagen?

## Toda la sesión se apoya en distinguir estas dos cosas. Si se mezclan, nada de lo demás encaja.

---

# Tres palabras que vas a usar todo el día

## Imagen, contenedor, registry

<div class="pasos">
<div><b>01</b><span><b>Imagen</b> — plantilla de solo lectura con un sistema de archivos y metadatos. Como una <i>clase</i> en programación, o una <i>receta</i> de cocina.</span></div>
<div><b>02</b><span><b>Contenedor</b> — instancia en ejecución de una imagen, con su propia capa de escritura encima. Como un <i>objeto</i>, o el <i>plato ya cocinado</i>.</span></div>
<div><b>03</b><span><b>Registry</b> — servidor donde viven las imágenes. Se descargan con <code>pull</code> y se suben con <code>push</code>. El público por defecto es <b>Docker Hub</b>.</span></div>
</div>

<div class="aviso">

De una misma imagen puedes arrancar **cien contenedores independientes**. La imagen no cambia nunca.

</div>

---

# Un contenedor no es una máquina virtual

## Comparte el kernel del host; no arranca un sistema operativo propio

| Aspecto | Máquina virtual | Contenedor |
|---|---|---|
| **Arranque** | Kernel + SO completo (2–5 min) | Directamente el proceso (~100 ms) |
| **Tamaño en disco** | 5–30 GB | 100 MB – 2 GB |
| **RAM mínima** | 512 MB – 2 GB | 10–100 MB |
| **Aislamiento** | Hardware virtualizado | Namespaces y cgroups del SO |
| **Cuántos caben** | 5–10 en tu portátil | Cientos |

---

<!-- _class: lima -->

# Por qué esto resuelve "en mi máquina funciona"

## La imagen empaqueta las dependencias exactas, no solo tu código

<div class="destacado">

Tu portátil, el servidor de integración y producción ejecutan
<b>los mismos bytes</b>. Si falla, falla en los tres sitios igual.

</div>

<div class="aviso">

Eso también significa que **si tu imagen está mal construida, está mal construida en todas partes**.
Docker no arregla el problema: lo hace reproducible.

</div>

---

<!-- _class: seccion -->

<div class="num">2</div>
<div class="reloj">≈ 0:25</div>

# Ejecutar y detener contenedores

## El ciclo de vida es el concepto que más errores causa en las primeras semanas.

---

# Un contenedor está en uno de tres estados

## Y solo uno de ellos significa que ha desaparecido

<pre class="diagrama">
                    docker run
                        │
                        ▼
    ┌──────────────────────────────────────┐
    │              RUNNING                 │
    │      proceso principal vivo          │
    └──────────────────────────────────────┘
       ▲                              │
       │ docker start                 │ docker stop
       │ (resucita)                   │ o el proceso termina
       │                              ▼
    ┌──────────────────────────────────────┐
    │              EXITED                  │
    │   parado, pero EXISTE en el sistema  │
    └──────────────────────────────────────┘
                    │
                    │ docker rm
                    ▼
             BORRADO (desaparece)
</pre>

---

# Tres ideas que hay que fijar aquí

## Casi todas las confusiones del primer día salen de estas tres

<div class="pasos">
<div><b>01</b><span>Un contenedor <code>EXITED</code> <b>no está borrado</b>. Ocupa disco y sale en <code>docker ps -a</code>.</span></div>
<div><b>02</b><span>Solo <code>docker rm</code> lo borra de verdad. <code>docker stop</code> no borra nada.</span></div>
<div><b>03</b><span><code>docker run --rm</code> se autoelimina al terminar. Úsalo para pruebas de un solo uso.</span></div>
</div>

<div class="aviso">

Si `docker ps` no muestra tu contenedor, prueba `docker ps -a` **antes** de volver a lanzarlo.
Muy probablemente sigue ahí, parado, y el error está en sus logs.

</div>

---

<!-- _class: denso -->

# `docker run` — los flags que usarás de verdad

## Hay decenas; con estos ocho cubres el 95 % de los casos

| Flag | Qué hace | Ejemplo |
|---|---|---|
| `-d` | Segundo plano (*detached*) | `docker run -d nginx` |
| `-it` | Shell interactiva | `docker run -it alpine sh` |
| `-e VAR=valor` | Variable de entorno | `-e POSTGRES_PASSWORD=secreto` |
| `-p host:cont` | Publica un puerto | `-p 8080:80` |
| `-v origen:destino` | Monta datos | `-v datos:/var/lib/postgresql` |
| `--name nombre` | Nombre fijo (si no, aleatorio) | `--name mi-db` |
| `--rm` | Se autoelimina al terminar | `docker run --rm alpine echo hola` |
| `--restart` | Política de reinicio | `--restart unless-stopped` |

---

# Inspeccionar: lo que harás cuando algo falle

## Antes de reinstalar nada, mira los logs

```bash
docker ps                       # contenedores en ejecución
docker ps -a                    # todos, incluidos los parados

docker logs <contenedor>        # salida completa (stdout + stderr)
docker logs -f <contenedor>     # sigue en tiempo real, como tail -f
docker logs --tail 50 <cont>    # solo las últimas 50 líneas

docker exec -it <cont> sh       # abre una shell DENTRO del contenedor
docker inspect <cont>           # JSON completo: IP, volúmenes, variables
docker stats <cont>             # CPU, memoria e I/O en vivo
```

<div class="aviso">

`docker logs` es la primera herramienta de diagnóstico, no la última.

</div>

---

<!-- _class: navy -->

# Ejercicio 1 — Tu primer contenedor

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Arrancar, listar, inspeccionar y parar

<div class="cols-58">
<div>

```bash
$ docker run hello-world

$ docker run -d --name web \
    -p 8088:80 nginx:alpine

$ docker ps

$ docker logs web

$ docker stop web
```

</div>
<div>

### Tarea

Arranca un contenedor, compruébalo desde el navegador y páralo.

### Responde antes de continuar

¿Qué diferencia hay entre `docker ps` y `docker ps -a` **después** de parar `web`?

</div>
</div>

---

<!-- _class: navy -->

# Ejercicio 2 — Los contenedores son efímeros

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> Escribe un fichero, borra el contenedor, búscalo

<div class="cols-58">
<div>

```bash
$ docker run -it --name prueba \
    alpine:3.21 sh

/ # echo "dato importante" > /datos.txt
/ # cat /datos.txt
/ # exit

$ docker start -ai prueba
/ # cat /datos.txt      # ¿sigue?

$ docker rm prueba
$ docker run -it alpine:3.21 sh
/ # cat /datos.txt      # ¿y ahora?
```

</div>
<div>

### Lo que vas a comprobar

Los datos **sobreviven** a `stop`/`start`.

Los datos **mueren** con `rm`.

### Para pensar

Si esto fuera tu base de datos de producción, ¿qué acabas de perder?

</div>
</div>

---

<!-- _class: lima -->

# Ese ejercicio es el motivo de la siguiente sección

## Un contenedor tiene una capa de escritura que muere con él

<pre class="diagrama">
┌───────────────────────────────────┐
│   Capa de escritura (RW)          │  ← se borra con docker rm
├───────────────────────────────────┤
│   Capas de la imagen (RO)         │  ← vienen de la imagen, no cambian
└───────────────────────────────────┘
</pre>

<div class="destacado">

Los volúmenes existen para sacar los datos<br>fuera del ciclo de vida del contenedor.

</div>

---

<!-- _class: seccion -->

<div class="num">3</div>
<div class="reloj">≈ 1:10</div>

# Volúmenes y puertos

## Dos mecanismos independientes: uno para que los datos duren, otro para que alguien pueda hablar con el proceso.

---

# Hay dos formas de montar datos, y no son intercambiables

## Bind mount para tu código; volumen con nombre para tus datos

<div class="cols">
<div>

### Bind mount

Tú eliges una ruta **de tu máquina**.

```bash
docker run \
  -v $(pwd)/dags:/opt/airflow/dags \
  apache/airflow:3.3.1-python3.14
```

Editas en tu editor, se ve dentro al instante.

</div>
<div>

### Volumen con nombre

Docker gestiona el almacenamiento; tú solo pones un nombre.

```bash
docker run \
  -v postgres_data:/var/lib/postgresql \
  postgres:18-alpine
```

Sobrevive a `docker rm`.

</div>
</div>

---

<!-- _class: denso -->

# Cuál usar para qué

## Regla rápida para proyectos de datos

| Qué guardas | Qué usar | Por qué |
|---|---|---|
| Datos de una base de datos | **Volumen con nombre** | No necesitas tocarlos a mano; Docker los gestiona y los puedes migrar |
| Tu código: DAGs, scripts, notebooks | **Bind mount** | Quieres editarlos en tu editor y verlos al instante |
| Logs que quieres leer desde tu editor | **Bind mount** | Acceso directo desde el host |
| Datos temporales de una tarea | **Nada** | Que se pierdan es lo correcto |

<div class="aviso">

Caso real de este proyecto: un volumen `postgres_data` creado con Postgres 15 **no arranca**
con la imagen `postgres:18-alpine`. Hubo que borrarlo con `docker compose down -v`.

</div>

---

<!-- _class: lima -->

# El bind mount tiene una trampa: los permisos

## Los archivos que crea el contenedor no son tuyos

<div class="cols">
<div>

### Qué pasa

El proceso de dentro corre como `root` o como otro usuario del sistema. Lo que escriba en el bind mount lleva **ese** propietario, no el tuyo.

```bash
$ ls -l logs/
-rw-r--r--  1 root  root  dag.log

$ rm logs/dag.log
rm: Permission denied
```

</div>
<div>

### Cómo se arregla

```bash
# Ejecutar con TU identidad
$ docker run -u $(id -u):$(id -g) ...
```

En el stack de Airflow hay una variable dedicada:

```bash
$ echo "AIRFLOW_UID=$(id -u)" >> .env
```

</div>
</div>

<div class="aviso">

Pasa en **Linux**. En Mac y Windows, Docker Desktop traduce los identificadores por ti y no lo verás
nunca... hasta que despliegues en el servidor de la empresa, que es Linux.

</div>

---

# Un puerto dentro del contenedor no es alcanzable

## Hasta que lo publicas explícitamente

<pre class="diagrama">
┌────────────────────────────┐        ┌────────────────────────────┐
│   Tu máquina (host)        │        │   Contenedor               │
│                            │        │   proceso escuchando :8080 │
│   localhost:8080  ───X─────┼────────┤   (aislado)                │
└────────────────────────────┘        └────────────────────────────┘
</pre>

```bash
docker run -p 8080:8080 apache/airflow:3.3.1-python3.14 api-server
#           │    │
#           │    └── puerto DENTRO del contenedor
#           └── puerto EN TU MÁQUINA (el que abres en el navegador)
```

---

<!-- _class: denso -->

# Variantes de `-p` y una confusión clásica

## `EXPOSE` documenta; `-p` es lo que realmente abre el puente

| Sintaxis | Efecto |
|---|---|
| `-p 8080:8080` | Publica en todas las interfaces: accesible desde tu red local |
| `-p 127.0.0.1:8080:8080` | Solo `localhost`: nadie más en tu wifi puede entrar |
| `-p 9090:8080` | Puertos distintos a ambos lados — perfectamente válido |
| `-P` | Publica todos los `EXPOSE` en puertos aleatorios |

<div class="aviso">

`EXPOSE 8080` en un Dockerfile es **solo un metadato**. Sin `-p`, el puerto sigue sin ser alcanzable.
En nuestro `docker-compose.yml` usamos `127.0.0.1:8080:8080` a propósito.

</div>

---

<!-- _class: navy -->

# Ejercicio 3 — Que los datos sobrevivan

## <span class="pill">20 min</span> <span class="pill">NÚCLEO</span> Postgres con volumen y puerto publicado

<div class="cols-58">
<div>

```bash
$ docker run -d --name db \
    -e POSTGRES_PASSWORD=secreto \
    -v pgdata:/var/lib/postgresql \
    -p 5433:5432 \
    postgres:18-alpine

$ docker exec -it db psql -U postgres \
    -c "CREATE TABLE t(id int);"

$ docker rm -f db

# vuelve a arrancarlo con el MISMO volumen
# ¿sigue existiendo la tabla?
```

</div>
<div>

### Lo que demuestras

El contenedor se ha borrado. Los datos, no.

### Ojo con el puerto

`5433` en el host, `5432` dentro. Así no chocas con un Postgres local.

### Para pensar

¿Qué pasa si cambias `pgdata` por otro nombre?

</div>
</div>

---

<!-- _class: seccion -->

<div class="num">4</div>
<div class="reloj">≈ 1:40</div>

# Imágenes en profundidad

## De dónde vienen, cómo se llaman y por qué el tag importa más de lo que parece.

---

# Una imagen es un snapshot de un sistema de archivos

## Capas de solo lectura, más metadatos

<div class="cols">
<div>

### Contiene

- Un SO mínimo (Alpine 7 MB, Ubuntu 77 MB)
- Librerías y binarios
- Tu aplicación y sus dependencias
- **Metadatos**: comando por defecto, variables, puertos, usuario

</div>
<div>

### `docker run` hace cuatro cosas

1. Descarga la imagen si no la tiene
2. Crea un contenedor nuevo
3. Añade una capa de escritura encima
4. Arranca el proceso principal

</div>
</div>

<div class="aviso">

La imagen **nunca cambia**. Cien `docker run` generan cien contenedores independientes.

</div>

---

# Oficiales frente a personalizadas

## El prefijo de organización te dice cuál es cuál

<div class="cols">
<div>

### Oficiales

Sin prefijo de organización.

`postgres:18-alpine`
`python:3.13-slim`
`nginx:1.27`
`alpine:3.21`

Mantenidas por el propio proyecto.

</div>
<div>

### Personalizadas

Con prefijo `organización/`.

`apache/airflow:3.3.1-python3.14`
`bitnami/postgresql:18`
`tu-usuario/mi-pipeline:1.0`

Publicadas por empresas, comunidades o por ti.

</div>
</div>

---

<!-- _class: lima -->

# El nombre completo de una imagen

## Si omites partes, Docker rellena por ti — y ahí empiezan los sustos

```
docker.io / library / postgres : 18-alpine
    │          │          │          │
    │          │          │          └── tag (versión)
    │          │          └───────────── nombre
    │          └──────────────────────── organización (library = oficial)
    └─────────────────────────────────── registry
```

| Si omites… | Docker asume… |
|---|---|
| El registry | `docker.io` |
| La organización | `library` (imágenes oficiales) |
| El tag | `latest` |

Así que `postgres` es en realidad `docker.io/library/postgres:latest`.

---

# `latest` es una promesa que nadie te ha hecho

## Es el origen de la mitad de los "a mí me funcionaba ayer"

<div class="cols">
<div>

### El problema

```bash
docker pull postgres
# Hoy:      PostgreSQL 18.3
# En 3 meses: PostgreSQL 19.0
```

Tu compañero ejecuta el mismo comando y obtiene otra versión.

</div>
<div>

### La solución

```bash
docker pull postgres:18.3-alpine
```

En nuestro proyecto, el `.env`:

```env
AIRFLOW_IMAGE_NAME=\
  apache/airflow:3.3.1-python3.14
```

</div>
</div>

<div class="aviso">

Regla: **en un proyecto real, nunca `latest`**. Ni en el Dockerfile, ni en el Compose.

</div>

---

<!-- _class: lima -->

# Una imagen no vale para cualquier procesador

## Mac con Apple Silicon es `arm64`. El servidor de tu empresa, casi seguro `amd64`.

<div class="cols">
<div>

### El síntoma

```bash
$ docker run mi-imagen:1.0
exec format error
```

O peor: arranca, pero va diez veces más lento porque está emulando.

</div>
<div>

### La solución

```bash
# Al construir
$ docker build --platform linux/amd64 \
    -t mi-app:1.0 .

# Y al ejecutar
$ docker run --platform linux/amd64 ...
```

</div>
</div>

<div class="aviso">

Las imágenes oficiales (`postgres`, `python`, `airflow`) son **multiarquitectura**: Docker elige
la tuya solo. El problema aparece con **la tuya**: construida en tu Mac, desplegada en un Linux `amd64`.

</div>

---

# Registries: dónde viven las imágenes

## Docker Hub es el de por defecto, no el único

| Registry | Proveedor | Punto de acceso |
|---|---|---|
| **Docker Hub** | Docker Inc. | `docker.io` (implícito) |
| **ECR** | Amazon AWS | `<cuenta>.dkr.ecr.<región>.amazonaws.com` |
| **Artifact Registry** | Google Cloud | `<región>-docker.pkg.dev` |
| **GHCR** | GitHub | `ghcr.io` |
| **Quay.io** | Red Hat | `quay.io` |

<div class="aviso">

En cualquier empresa con nube, tus imágenes acabarán en ECR o Artifact Registry, no en Docker Hub.
La mecánica es idéntica: `login`, `build`, `push`, `pull`.

</div>

---

<!-- _class: navy -->

# Ejercicio 5 bis — Publica y comparte una imagen

## <span class="pill">15 min</span> <span class="pill">EN GRUPO</span> Una persona publica; el resto descarga

<div class="cols">
<div>

### Parte A — la persona voluntaria

```bash
$ docker login
$ docker build \
    -t TU_USUARIO/mi-pipeline:1.0 .
$ docker push TU_USUARIO/mi-pipeline:1.0
```

Comparte el nombre exacto con la clase.

</div>
<div>

### Parte B — el resto

```bash
$ docker run --rm \
    TU_USUARIO/mi-pipeline:1.0
```

Nadie ha compartido código, ni instalado nada, ni configurado un entorno.

</div>
</div>

<div class="aviso">

Esto es exactamente lo que hace un pipeline de CI cuando despliega. Sin magia.

</div>

---

<!-- _class: seccion -->

<div class="num">5</div>
<div class="reloj">≈ 1:55</div>

# Construir imágenes<br>con un Dockerfile

## Como Data Engineer rara vez escribirás una imagen desde cero. Lo que harás cada semana es añadirle dependencias a una oficial.

---

<!-- _class: denso -->

# Las siete instrucciones que necesitas

## Hay muchas más; con estas construyes casi todo lo que te van a pedir

| Instrucción | Qué hace |
|---|---|
| `FROM imagen:tag` | Imagen base. Siempre la primera línea. |
| `WORKDIR /ruta` | Directorio de trabajo (lo crea si no existe) |
| `COPY origen destino` | Copia archivos de tu máquina a la imagen |
| `RUN comando` | Ejecuta algo **durante el build** y guarda el resultado como capa |
| `ENV CLAVE=valor` | Variable de entorno, disponible en build y en runtime |
| `USER usuario` | Usuario con el que se ejecuta lo siguiente y el contenedor final |
| `CMD ["..."]` | Comando por defecto al arrancar. **Se puede sobrescribir.** |

---

# El Dockerfile mínimo

## Cuatro líneas y dos comandos

<div class="cols">
<div>

```dockerfile
FROM alpine:3.21

WORKDIR /usr/src/app

COPY hello.sh .

CMD ["./hello.sh"]
```

</div>
<div>

```bash
$ docker build -t hello-docker .

$ docker run hello-docker
```

El `.` final es el **contexto de build**: la carpeta que Docker envía al daemon.

</div>
</div>

---

<!-- _class: lima -->

# El caso que más te va a tocar

## Tu DAG importa `pandas`; la imagen oficial de Airflow no lo trae

```dockerfile
FROM apache/airflow:3.3.1-python3.14

# La imagen de Airflow define USER airflow;
# pip debe ejecutarse como ese usuario
RUN pip install --no-cache-dir pandas==2.2.3
```

<div class="aviso">

**Error clásico**: instalarlo a mano con `docker exec ... pip install pandas`.
Funciona *hasta que* borras el contenedor. Lo del Dockerfile es permanente y reproducible.

</div>

---

# Capas y caché: por qué a veces tarda 2 s y otras 4 min

## Cada `RUN`, `COPY` y `ADD` crea una capa que Docker cachea

<div class="cols">
<div>

```dockerfile
FROM ubuntu:24.04       # capa 1
RUN apt-get update      # capa 2
RUN apt-get install -y python3   # capa 3
COPY app.py .           # capa 4
RUN python3 app.py      # capa 5
```

</div>
<div>

### Si cambias `app.py`

Capas 1–3 → `CACHED`
Capas 4–5 → se rehacen

### Si cambias la línea `FROM`

**Todas** se rehacen.

</div>
</div>

<div class="aviso">

Regla de oro: lo que **cambia poco** (dependencias) va arriba. Lo que **cambia siempre** (tu código) va abajo.

</div>

---

# El contexto de build: lo que de verdad estás enviando

## El punto final de `docker build .` empaqueta la carpeta entera

<div class="cols">
<div>

### Sin `.dockerignore`

```bash
$ docker build -t mi-app:1.0 .
Sending build context ...  2.4GB
```

Ahí van tu `.git`, tu `venv/`, tus CSV de pruebas y el `data/` entero. Aunque el Dockerfile no los copie.

</div>
<div>

### Con `.dockerignore`

```
.git
__pycache__/
venv/
data/
*.csv
*.parquet
.env
```

```bash
Sending build context ...  480kB
```

</div>
</div>

<div class="aviso">

Dos motivos, y el segundo es el que importa: **builds mucho más rápidos** y **no meter tu `.env`
dentro de la imagen** el día que alguien añada un `COPY . .` al Dockerfile.

</div>

---

<!-- _class: navy -->

# Ejercicio 4 — Tu primer Dockerfile

## <span class="pill">15 min</span> <span class="pill">NÚCLEO</span> De un script suelto a una imagen

<div class="cols-58">
<div>

```bash
$ cat > hello.sh <<'EOF'
#!/bin/sh
echo "Hola desde dentro"
EOF
$ chmod +x hello.sh

$ cat > Dockerfile <<'EOF'
FROM alpine:3.21
WORKDIR /app
COPY hello.sh .
CMD ["./hello.sh"]
EOF

$ docker build -t hola:1.0 .
$ docker run --rm hola:1.0
```

</div>
<div>

### Después, comprueba

```bash
$ docker images hola
$ docker history hola:1.0
```

### Para pensar

Cambia el `echo` y reconstruye. ¿Qué capas dice `CACHED`?

</div>
</div>

---

<!-- _class: navy -->

# Ejercicio 5 — Añadir una librería a Airflow

## <span class="pill">25 min</span> <span class="pill">NÚCLEO CLAVE</span> El ejercicio más parecido a tu trabajo real

<div class="cols-58">
<div>

```dockerfile
FROM apache/airflow:3.3.1-python3.14

RUN pip install --no-cache-dir \
    pandas==2.2.3
```

```bash
$ docker build -t mi-airflow:1.0 .

$ docker run --rm mi-airflow:1.0 \
    python -c "import pandas; \
    print(pandas.__version__)"
```

</div>
<div>

### Extensión

Pásalo a `requirements.txt`:

```dockerfile
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir \
    -r /tmp/requirements.txt
```

### Para pensar

¿Por qué `--no-cache-dir`?

</div>
</div>

---

# `CMD` explica un detalle raro de nuestro proyecto

## Cinco servicios, la misma imagen, distinto comando

```yaml
services:
  airflow-scheduler:
    image: apache/airflow:3.3.1-python3.14
    command: scheduler        # sobrescribe el CMD de la imagen

  airflow-api-server:
    image: apache/airflow:3.3.1-python3.14
    command: api-server
```

<div class="aviso">

Existe también `ENTRYPOINT`: un comando fijo al que se le añaden argumentos.
`postgres` y `apache/airflow` lo usan por dentro — por eso `command:` funciona pasando solo el subcomando.

</div>

---

<!-- _class: seccion -->

<div class="num">6</div>
<div class="reloj">≈ 2:40</div>

# Condiciones de arranque

## "Arrancado" y "listo" no son lo mismo. Distinguirlo evita el error más confuso de la sesión 2.

---

# Reinicio y salud

## Dos ajustes pequeños con consecuencias grandes

<div class="cols">
<div>

### `restart`

Qué hace Docker si el proceso principal termina.

**`unless-stopped`** — reinicia siempre salvo que lo pares tú. El que usamos.

**`no`** — por defecto. Correcto para tareas de un solo uso, como `airflow-init`.

</div>
<div>

### `healthcheck`

Un comando periódico que decide si el contenedor está **listo**, no solo *arrancado*.

La diferencia entre "el proceso de Postgres existe" y "Postgres acepta conexiones".

</div>
</div>

<div class="aviso">

Sin healthcheck, Airflow intenta conectarse a una base de datos que aún se está inicializando
y falla con un error incomprensible. **Volveremos a esto en la sesión 2 con `depends_on`.**

</div>

---

<!-- _class: lima -->

# Qué te llevas de hoy

## Cinco cosas que ya no deberían darte problemas

<div class="pasos">
<div><b>01</b><span>Imagen es plantilla; contenedor es instancia. Nunca más los mezclas.</span></div>
<div><b>02</b><span><code>stop</code> no borra. Solo <code>rm</code> borra. Y <code>ps -a</code> lo demuestra.</span></div>
<div><b>03</b><span>Los datos van en volúmenes: con nombre para bases de datos, bind mount para tu código.</span></div>
<div><b>04</b><span><code>-p</code> abre el puente; <code>EXPOSE</code> solo documenta.</span></div>
<div><b>05</b><span><code>FROM</code> oficial + <code>RUN pip install</code> es el 90 % de los Dockerfiles que escribirás.</span></div>
</div>

---

<!-- _class: verde -->

# En la sesión 2

## Ya sabes levantar un contenedor. Ahora tienes que levantar cinco que se hablen entre sí.

<div class="cols">
<div>

### Lo que viene

- De `docker run` a `docker compose`
- Redes: por qué `postgres` funciona como hostname
- `depends_on` y healthchecks encadenados
- El stack real de Airflow, servicio a servicio

</div>
<div>

### Antes de la sesión 2

Mira los **vídeos 6 y 7**.

Deja tu entorno limpio:

```bash
docker ps -a
docker system df
```

</div>
</div>

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
