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
