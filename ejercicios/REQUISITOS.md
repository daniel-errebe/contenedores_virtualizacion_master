# Requisitos e instalación — Léeme ANTES de la primera clase

> **Este documento no es opcional y no se puede hacer el día de la clase.**
>
> Las sesiones de Docker (5 h) y Kubernetes (2 h 30) son prácticas de
> principio a fin. Si llegas sin el entorno montado perderás la primera hora
> instalando, no darás alcance al grupo y el resto de la clase se para por ti.
>
> Reserva **45 minutos en casa, con buena conexión a internet** y sigue este
> documento hasta el final, incluida la **[verificación final](#8-verificación-final--el-momento-de-la-verdad)**.

Si algo no funciona, escribe al profesor **con varios días de antelación**,
no la noche anterior. Incluye: tu sistema operativo, el comando exacto que
ejecutaste y el mensaje de error completo (captura de pantalla).

---

## Índice

1. [Resumen: qué tienes que instalar](#1-resumen-qué-tienes-que-instalar)
2. [Requisitos de hardware](#2-requisitos-de-hardware)
3. [Cuentas que necesitas crear](#3-cuentas-que-necesitas-crear)
4. [Instalación en macOS](#4-instalación-en-macos)
5. [Instalación en Windows](#5-instalación-en-windows)
6. [Instalación en Linux](#6-instalación-en-linux)
7. [Descarga previa de las imágenes](#7-descarga-previa-de-las-imágenes)
8. [Verificación final — el momento de la verdad](#8-verificación-final--el-momento-de-la-verdad)
9. [Problemas frecuentes](#9-problemas-frecuentes)
10. [Plan B: si tu ordenador no puede](#10-plan-b-si-tu-ordenador-no-puede)
11. [Apéndice A — Tabla de alternativas por sistema](#apéndice-a--tabla-de-alternativas-por-sistema)
12. [Apéndice B — Notas para el profesor](#apéndice-b--notas-para-el-profesor)

---

## 1. Resumen: qué tienes que instalar

| # | Herramienta | ¿Para qué sesión? | ¿Obligatorio? | Tiempo aprox. |
|---|---|---|---|---|
| 1 | **Docker** (motor + CLI + Compose) | Docker y Kubernetes | ✅ Sí | 15 min |
| 2 | **Cuenta de Docker Hub** | Docker y Kubernetes | ✅ Sí | 3 min |
| 3 | **Git** | Ambas (clonar el repo) | ✅ Sí | 5 min |
| 4 | **Un editor de código** (VS Code) | Ambas | ✅ Sí | 5 min |
| 5 | **Imágenes descargadas** | Docker | ✅ Sí | 15 min |
| 6 | **minikube + kubectl** | Kubernetes | ✅ Sí (2.ª sesión) | 10 min |
| 7 | Terminal decente (WSL en Windows) | Ambas | ✅ Sí en Windows | 15 min |

**Docker Compose no se instala aparte.** Desde la versión 2 es un plugin que
viene incluido con Docker. El comando es `docker compose` (con espacio), no
`docker-compose` (con guion). Si tu sistema solo entiende el del guion,
tienes una instalación antigua: sigue este documento para actualizarla.

---

## 2. Requisitos de hardware

| Recurso | Mínimo | Recomendado | Por qué |
|---|---|---|---|
| **RAM total** | 8 GB | 16 GB | El stack de Airflow levanta 5 servicios a la vez |
| **RAM para Docker** | 4 GB | 6–8 GB | Configurable, ver más abajo |
| **Disco libre** | 20 GB | 30 GB | Imágenes (~6 GB) + cluster de minikube (~3 GB) + capas intermedias |
| **CPU** | 2 núcleos | 4 núcleos | minikube pide 2 solo para él |
| **Virtualización** | Habilitada en BIOS/UEFI | — | Sin ella Docker no arranca en Windows/Linux |

### Comprobar el espacio en disco

```bash
# macOS / Linux
df -h /

# Windows (PowerShell)
Get-PSDrive C
```

### Si tienes 8 GB de RAM justos

Es viable, pero tendrás que ser disciplinado: **cierra Chrome, Slack, Teams y
Spotify** antes de la clase. Y sobre todo, no tengas el stack de Airflow y el
cluster de minikube levantados a la vez. Se apaga uno antes de encender el
otro:

```bash
docker compose down     # apaga el stack de Docker
minikube stop           # apaga el cluster de Kubernetes
```

### Virtualización deshabilitada

Es el fallo nº 1 en portátiles de empresa y en algunos equipos de sobremesa.
Síntoma: Docker Desktop se queda en «Starting...» eternamente, o WSL da
`Error 0x80370102`.

Comprobación rápida:

- **Windows**: Administrador de tareas → pestaña *Rendimiento* → *CPU* →
  busca «Virtualización: Habilitada».
- **Linux**: `grep -Eoc '(vmx|svm)' /proc/cpuinfo` — si devuelve `0`, está
  deshabilitada.
- **macOS**: siempre está habilitada, no te preocupes.

Solución: reiniciar, entrar en la BIOS/UEFI (normalmente F2, F10, Supr o Esc
durante el arranque) y activar **Intel VT-x** o **AMD-V / SVM Mode**.

> ⚠️ Si tu portátil es de empresa y la BIOS está bloqueada por el
> departamento de IT, **avisa al profesor con una semana de antelación**.
> Hay plan B (ver [sección 10](#10-plan-b-si-tu-ordenador-no-puede)), pero
> hay que prepararlo.

---

## 3. Cuentas que necesitas crear

### 3.1 Docker Hub (obligatorio)

Regístrate en **<https://hub.docker.com/signup>**. Es gratis.

**Elige bien el nombre de usuario**: se convertirá en el prefijo público de
todas tus imágenes (`tu_usuario/mi-pipeline:1.0`) y no es fácil de cambiar
después. Algo profesional, que puedas enseñar en una entrevista.

Una vez creada la cuenta, autentícate desde tu terminal:

```bash
docker login
# Username: tu_usuario
# Password: ...
```

#### Por qué esto importa más de lo que parece

Docker Hub limita cuántas imágenes puedes descargar:

| Situación | Límite aproximado de descargas |
|---|---|
| Sin autenticar (anónimo) | ~10 por hora **y por IP pública** |
| Cuenta gratuita autenticada | ~100 por hora **por cuenta** |
| Cuenta de pago | Sin límite práctico |

Fíjate en el detalle: **sin autenticar el límite es por IP**. En un aula,
treinta personas comparten la misma IP pública. Si nadie hace `docker login`,
entre todos agotamos el cupo en los primeros minutos y empiezan a aparecer
errores `toomanyrequests: You have reached your pull rate limit`.

**Haz `docker login` en casa y no lo desactives.** La sesión queda guardada.

> Los límites exactos han cambiado varias veces; los números de la tabla son
> orientativos. Lo que no cambia es la conclusión: autentícate.

#### Un apunte de seguridad

En `docker login` puedes usar tu contraseña, pero se guarda en texto claro en
`~/.docker/config.json`. Lo correcto es usar un **Access Token**:

1. Docker Hub → tu avatar → *Account Settings* → *Security* → *Personal access tokens*
2. *Generate new token*, permisos *Read & Write*
3. Cópialo (solo se muestra una vez) y úsalo como contraseña en `docker login`

Si el token se filtra, lo revocas sin tocar tu contraseña real.

### 3.2 GitHub (recomendado, no obligatorio)

Para clonar el repositorio de la asignatura y para tener tu propio trabajo
versionado. Cuenta gratuita en <https://github.com/signup>.

---

## 4. Instalación en macOS

Antes de nada, averigua qué chip tienes: menú  → *Acerca de este Mac*.

- **Apple Silicon** (M1, M2, M3, M4...) → arquitectura `arm64`
- **Intel** → arquitectura `amd64` / `x86_64`

Ambas funcionan, pero lee la [nota sobre arquitecturas](#46-nota-importante-para-apple-silicon)
al final de esta sección.

### 4.1 Homebrew (te va a simplificar todo)

Si no lo tienes:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Al terminar, el instalador te dirá que ejecutes un par de comandos para
añadir `brew` al PATH. **Hazle caso**, o `brew` no se encontrará.

### 4.2 Git

macOS trae Git, pero suele estar desactualizado:

```bash
git --version          # si responde algo, ya lo tienes
brew install git       # para actualizarlo (opcional)
```

Si es la primera vez que usas Git, configúralo:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### 4.3 Docker — Opción A: Docker Desktop (la más sencilla)

Descarga desde <https://www.docker.com/products/docker-desktop/> eligiendo
**Apple Silicon** o **Intel Chip** según tu Mac. Es un `.dmg` normal.

Después de instalarlo:

1. Ábrelo (la primera vez pedirá permisos de administrador).
2. Espera a que la ballena de la barra de menús deje de animarse.
3. Ve a **Settings → Resources** y asigna:
   - **Memory: 6 GB** (mínimo 4)
   - **CPUs: 4** (mínimo 2)
   - **Disk image size: al menos 40 GB**
4. *Apply & Restart*.

> 💡 Docker Desktop es gratis para uso personal, educación y empresas
> pequeñas, pero **requiere licencia de pago en empresas grandes**
> (>250 empleados o >10 M$ de facturación). Si estás usando un portátil
> corporativo, usa la Opción B para evitar problemas legales.

### 4.4 Docker — Opción B: Colima (ligera, sin licencia, sin interfaz)

Colima levanta una máquina virtual mínima con Docker dentro. Consume menos
RAM que Docker Desktop y no tiene restricciones de licencia.

```bash
brew install colima docker docker-compose
colima start --cpu 4 --memory 8 --disk 60
```

- `colima` → la VM
- `docker` → solo el cliente de línea de comandos
- `docker-compose` → el plugin de Compose v2

Comprueba que funciona:

```bash
docker ps
```

Comandos que necesitarás recordar:

```bash
colima status     # ¿está encendida?
colima start      # encender (al reiniciar el Mac no arranca sola)
colima stop       # apagar y liberar la RAM
```

> ⚠️ **Colima no arranca sola al encender el Mac.** Si un día `docker ps` te
> dice `Cannot connect to the Docker daemon`, casi seguro es que se te ha
> olvidado `colima start`.
>
> ⚠️ Si Colima lleva días encendida, a veces la resolución DNS deja de
> funcionar dentro de los contenedores (síntoma: los `pip install` de un
> `docker build` fallan por *temporary failure in name resolution*). Se
> arregla con `colima stop && colima start`.

### 4.5 minikube y kubectl (para la segunda sesión)

```bash
brew install minikube kubectl
```

Arranca el cluster **una vez ahora** para verificar que va, y apágalo:

```bash
minikube start --driver=docker --memory=4096 --cpus=2
kubectl get nodes
# -> debe aparecer 1 nodo en estado Ready

minikube stop
```

> ⚠️ **Si usas Colima**: aquí hay VM dentro de VM. Colima levanta una máquina
> virtual, y minikube crea un contenedor dentro de ella que hace de nodo. La
> memoria se suma. Da a Colima **al menos 8 GB** (`colima start --memory 8`)
> o minikube fallará por falta de recursos.

### 4.6 Nota importante para Apple Silicon

Tu Mac es `arm64`. La mayoría de imágenes modernas publican versiones para
ambas arquitecturas y Docker elige la tuya automáticamente. Todas las que
usamos en clase (`postgres:18-alpine`, `apache/airflow`, `python:3.13-slim`,
`alpine:3.21`) tienen build nativo `arm64`, así que no tendrás problemas.

Pero te encontrarás con imágenes antiguas que solo existen para `amd64`.
Síntoma: `no matching manifest for linux/arm64`. Solución:

```bash
docker run --platform linux/amd64 imagen_que_sea
```

Funciona por emulación, pero es **lento** (de 3 a 10 veces más). Tenlo en
cuenta cuando en el trabajo alguien diga «pues a mí me va rápido».

---

## 5. Instalación en Windows

Windows necesita un paso previo que macOS y Linux no: **WSL2**. Docker no
corre de forma nativa en Windows; por debajo siempre usa una máquina virtual
Linux. WSL2 es esa máquina virtual, bien integrada con el sistema.

### 5.1 Requisitos previos

- Windows 11, o Windows 10 versión 2004 (build 19041) o superior.
  Compruébalo con `winver` en el menú de inicio.
- Virtualización habilitada en la BIOS (ver [sección 2](#2-requisitos-de-hardware)).

### 5.2 Paso obligatorio: instalar WSL2

Abre **PowerShell como administrador** (clic derecho en el menú de inicio →
*Terminal (Administrador)*) y ejecuta:

```powershell
wsl --install
```

Esto instala WSL2 y una distribución de Ubuntu. **Reinicia el ordenador**
cuando termine.

Al reiniciar se abrirá una ventana de Ubuntu que te pedirá crear un usuario y
contraseña de Linux. **Anótalos**: los necesitarás para los comandos `sudo`.
Ojo, al escribir la contraseña no se ve nada en pantalla; es normal.

Verifica que ha quedado en versión 2:

```powershell
wsl --list --verbose
```

Debe mostrar `VERSION 2`. Si pone `1`:

```powershell
wsl --set-default-version 2
wsl --set-version Ubuntu 2
```

#### Limitar la RAM que consume WSL (muy recomendable)

Por defecto WSL puede llegar a comerse hasta el 50–80 % de tu RAM y no
devolverla. Crea el archivo `C:\Users\TU_USUARIO\.wslconfig` con este
contenido:

```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Ajusta los números a tu equipo (con 8 GB totales, pon `memory=4GB`). Aplica
los cambios con:

```powershell
wsl --shutdown
```

### 5.3 Docker — Opción A: Docker Desktop + WSL2 (recomendada)

1. Descarga desde <https://www.docker.com/products/docker-desktop/>
2. Durante la instalación, **deja marcada** la casilla
   *Use WSL 2 instead of Hyper-V*.
3. Al terminar, abre Docker Desktop y ve a
   **Settings → Resources → WSL Integration**.
4. Activa *Enable integration with my default WSL distro* y también el
   interruptor de **Ubuntu**.
5. *Apply & Restart*.

Ese paso 4 es el que la gente se salta y luego, dentro de Ubuntu, `docker`
no existe.

### 5.4 Docker — Opción B: Docker Engine dentro de WSL (sin Docker Desktop)

Si tu empresa no permite instalar Docker Desktop por la licencia, puedes
instalar Docker Engine directamente dentro de Ubuntu (WSL). Abre la terminal
de **Ubuntu** (no PowerShell) y sigue las instrucciones de la
[sección 6](#6-instalación-en-linux), que aplican tal cual.

Después, para que el servicio arranque:

```bash
sudo service docker start
```

> ⚠️ En WSL no hay `systemd` por defecto en versiones antiguas, así que
> Docker **no arranca solo**. Tendrás que ejecutar ese `sudo service docker
> start` cada vez que abras Ubuntu. Para automatizarlo, añade al final de tu
> `~/.bashrc`:
>
> ```bash
> if ! service docker status > /dev/null 2>&1; then
>     sudo service docker start > /dev/null 2>&1
> fi
> ```

### 5.5 Dónde ejecutar los comandos (esto importa)

**Trabaja siempre dentro de la terminal de Ubuntu (WSL), no en PowerShell ni
en CMD.** Todos los comandos del material están escritos para bash, y en
PowerShell fallarán cosas como `$(pwd)`, las comillas simples o `sh -c`.

Y un aviso de rendimiento que la gente descubre tarde y a base de sufrir:

| Dónde guardas el proyecto | Rendimiento | Ruta |
|---|---|---|
| Dentro del sistema de archivos de Linux | ✅ Rápido | `/home/tu_usuario/proyectos/` |
| En el disco de Windows visto desde WSL | ❌ Hasta 10× más lento | `/mnt/c/Users/...` |

**Clona el repositorio en `/home/tu_usuario/`, no en `/mnt/c/`.** La
diferencia en los `docker build` es brutal.

Para abrir esa carpeta en VS Code desde Ubuntu:

```bash
cd ~/proyectos/mi_proyecto_airflow
code .
```

### 5.6 Git

Ya viene instalado dentro de Ubuntu (WSL). Solo configúralo:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

> No instales Git para Windows *además*, salvo que sepas lo que haces:
> acabarás con dos instalaciones distintas y credenciales duplicadas.

### 5.7 minikube y kubectl (para la segunda sesión)

Aquí hay que ser coherente con la opción de Docker que hayas elegido:

**Si usas Docker Desktop** → instala minikube en Windows y ejecútalo desde
PowerShell:

```powershell
winget install Kubernetes.minikube
winget install Kubernetes.kubectl
```

**Si usas Docker Engine dentro de WSL** → instala minikube dentro de Ubuntu,
siguiendo los comandos de Linux de la [sección 6.4](#64-minikube-y-kubectl).

> ⚠️ **No mezcles.** Si instalas minikube en Windows pero el Docker está solo
> dentro de WSL (o al revés), minikube no encontrará el driver y verás
> `Exiting due to DRV_NOT_DETECTED`.

Prueba el cluster una vez y apágalo:

```bash
minikube start --driver=docker --memory=4096 --cpus=2
kubectl get nodes
minikube stop
```

### 5.8 Alternativa completa: Rancher Desktop

Si Docker Desktop te da problemas de licencia y no quieres pelearte con WSL a
mano, **Rancher Desktop** (<https://rancherdesktop.io/>) es libre, incluye
Docker (moby) y trae Kubernetes integrado. Sirve para las dos sesiones.

Configúralo en *Preferences → Container Engine* → selecciona **dockerd
(moby)**, no containerd. Con containerd el comando `docker` no existe y todo
el material dejaría de funcionar.

---

## 6. Instalación en Linux

Linux es el entorno nativo de Docker: no hay máquina virtual de por medio,
así que va más rápido y consume menos que en macOS o Windows.

### 6.1 Git y utilidades

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y git curl

# Fedora / RHEL / CentOS
sudo dnf install -y git curl
```

### 6.2 Docker Engine

La forma más rápida y soportada oficialmente para un entorno de desarrollo:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Esto instala el motor, el CLI y el plugin de Compose v2.

> ❌ **No instales Docker desde `snap` ni desde el paquete `docker.io` de
> Ubuntu.** Son versiones antiguas o con confinamiento que rompen el acceso a
> los volúmenes. Si ya los tienes, desinstálalos antes:
>
> ```bash
> sudo snap remove docker
> sudo apt remove -y docker docker-engine docker.io containerd runc
> ```

### 6.3 Paso post-instalación imprescindible

Sin esto tendrás que escribir `sudo` delante de cada comando de Docker, y a
mitad de clase acabarás con archivos propiedad de `root` que no puedes
borrar.

```bash
sudo groupadd docker           # puede decir que ya existe, no pasa nada
sudo usermod -aG docker $USER
newgrp docker                  # aplica el grupo en esta terminal
```

**Cierra la sesión y vuelve a entrar** (o reinicia) para que el cambio sea
permanente. Verifica:

```bash
docker run --rm hello-world    # SIN sudo
```

Y que Docker arranque con el sistema:

```bash
sudo systemctl enable --now docker
```

### 6.4 minikube y kubectl

```bash
# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

> Si tu máquina es ARM (Raspberry Pi, portátil ARM), sustituye `amd64` por
> `arm64` en las dos URLs.

Prueba y apaga:

```bash
minikube start --driver=docker --memory=4096 --cpus=2
kubectl get nodes
minikube stop
```

> ❌ **Nunca uses `--driver=none`.** Instala Kubernetes directamente sobre tu
> sistema, sin aislamiento, y deja porquería difícil de limpiar.

---

## 7. Descarga previa de las imágenes

Estas descargas suman unos **6 GB**. Hacerlas en clase, treinta personas a la
vez sobre el wifi del centro, significa perder media sesión mirando barras de
progreso.

**Hazlo en casa.** Solo hay que hacerlo una vez: quedan en caché para siempre.

```bash
docker login          # primero autentícate (ver sección 3.1)

# Sesión de Docker
docker pull alpine:3.21
docker pull postgres:18-alpine
docker pull python:3.13-slim
docker pull apache/airflow:3.3.1-python3.14

# Sesión de Kubernetes
docker pull curlimages/curl:latest
```

Comprueba que están:

```bash
docker images
```

| Imagen | Tamaño aprox. | Se usa en |
|---|---|---|
| `alpine:3.21` | 8 MB | Ejercicios 1 y 2 de Docker |
| `postgres:18-alpine` | 280 MB | Ejercicio 3 de Docker, ejercicio 4 de K8s |
| `python:3.13-slim` | 130 MB | Ejercicio 5 bis, imagen del pipeline |
| `apache/airflow:3.3.1-python3.14` | ~1,5 GB | Ejercicios 5 y 9 de Docker |
| `curlimages/curl` | 10 MB | Ejercicio 2 de K8s |

> El tamaño que muestra `docker images` es el descomprimido, siempre mayor
> que lo que has descargado por red. Además, las imágenes comparten capas
> entre sí, así que la suma real en disco es menor que la de la columna.

### 7.1 Solo para la sesión de Kubernetes

Además de lo anterior, la segunda sesión requiere que **hayas construido y
publicado tu propia imagen** `tu_usuario/mi-pipeline:1.0` en Docker Hub. Eso
se explica paso a paso en
**[EJERCICIOS_KUBERNETES.md § Antes de la clase](./EJERCICIOS_KUBERNETES.md#antes-de-la-clase-obligatorio)**
y usa lo que habrás aprendido en la primera sesión, así que **no lo hagas
hasta después de la clase de Docker**.

---

## 8. Verificación final — el momento de la verdad

Copia y pega este bloque entero en tu terminal. Si algo falla, lo verás.

```bash
echo "--- 1. Docker instalado ---"
docker --version

echo "--- 2. Compose v2 (con espacio) ---"
docker compose version

echo "--- 3. El demonio responde ---"
docker run --rm hello-world

echo "--- 4. Autenticado en Docker Hub ---"
docker info | grep -i username

echo "--- 5. Git ---"
git --version

echo "--- 6. Imágenes descargadas ---"
docker images | grep -E "alpine|postgres|python|airflow"

echo "--- 7. Kubernetes (solo 2.ª sesión) ---"
minikube version
kubectl version --client
```

### Qué deberías ver

| Comprobación | Salida esperada | Si falla, ve a |
|---|---|---|
| 1 | `Docker version 27.x` o superior | Secciones 4, 5 o 6 |
| 2 | `Docker Compose version v2.x` | Tienes Compose v1, reinstala Docker |
| 3 | `Hello from Docker!` | [Sección 9](#9-problemas-frecuentes) |
| 4 | `Username: tu_usuario` | Ejecuta `docker login` |
| 5 | `git version 2.x` | Sección 4.2 / 5.6 / 6.1 |
| 6 | 4 líneas de imágenes | [Sección 7](#7-descarga-previa-de-las-imágenes) |
| 7 | `minikube version: v1.3x` | Sección 4.5 / 5.7 / 6.4 |

### Prueba de fuego (opcional pero recomendable)

Si esto funciona, estás 100 % listo:

```bash
docker run -d --name prueba-pg \
  -e POSTGRES_PASSWORD=prueba \
  -p 5439:5432 \
  postgres:18-alpine

sleep 10
docker exec -it prueba-pg psql -U postgres -c "SELECT version();"

# limpieza
docker rm -f prueba-pg
```

Debe imprimir la versión de PostgreSQL. Usamos el puerto `5439` a propósito
para no chocar con nada que puedas tener instalado.

### Checklist antes de venir a clase

- [ ] `docker run --rm hello-world` funciona sin `sudo`
- [ ] `docker compose version` dice `v2.x`
- [ ] `docker info | grep -i username` muestra mi usuario de Docker Hub
- [ ] `docker images` lista las 4 imágenes de la tabla
- [ ] Docker tiene asignados al menos 4 GB de RAM
- [ ] Tengo 20 GB libres en disco
- [ ] *(2.ª sesión)* `minikube start` ha funcionado al menos una vez
- [ ] *(2.ª sesión)* Mi imagen está publicada en Docker Hub

---

## 9. Problemas frecuentes

### 9.1 «Cannot connect to the Docker daemon»

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

El cliente está instalado pero el motor no está arrancado. Es, con
diferencia, el error más común.

| Sistema | Solución |
|---|---|
| macOS + Docker Desktop | Abre la aplicación Docker Desktop y espera a la ballena |
| macOS + Colima | `colima start` |
| Windows + Docker Desktop | Ábrelo; revisa Settings → Resources → WSL Integration |
| Windows + Engine en WSL | `sudo service docker start` |
| Linux | `sudo systemctl start docker` |

### 9.2 «permission denied while trying to connect to the Docker daemon socket»

Solo en Linux/WSL. Te falta el paso post-instalación:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Y cierra la sesión y vuelve a entrar. **La solución no es poner `sudo`
delante de todo**: acabarás creando archivos de `root` en tus carpetas.

### 9.3 «toomanyrequests: You have reached your pull rate limit»

Has agotado el cupo de Docker Hub. Ejecuta `docker login` (ver
[sección 3.1](#31-docker-hub-obligatorio)). Si ya estabas autenticado, espera
una hora o pide al profesor la copia local de las imágenes.

### 9.4 `docker-compose: command not found`

El comando correcto es `docker compose`, **con espacio**. Si tu material
antiguo usa el guion, es de Compose v1, que está retirado desde 2023.

### 9.5 «port is already allocated»

```
Error: Bind for 0.0.0.0:8080 failed: port is already allocated
```

Algo más está usando ese puerto. Averigua qué:

```bash
# macOS / Linux
lsof -i :8080

# Windows (PowerShell)
netstat -ano | findstr :8080
```

Suele ser otro contenedor tuyo. Lista los que están corriendo con
`docker ps` y párralos con `docker stop nombre`.

> En el material usamos puertos separados a propósito: **8080** para el
> proyecto real de Airflow, **8088** para el sandbox de Docker y **8090**
> para Kubernetes. No los cambies y no chocarán entre sí.

### 9.6 El `docker build` falla al descargar paquetes de Python

```
Temporary failure in name resolution
```

El contenedor no resuelve DNS. Causas habituales:

| Causa | Solución |
|---|---|
| VPN corporativa activa | Desconéctala y reintenta |
| Colima lleva días encendida | `colima stop && colima start` |
| Docker Desktop atascado | Reinícialo por completo |
| Proxy de empresa | Configúralo en Docker Desktop → Settings → Resources → Proxies |

### 9.7 Todo va lentísimo

| Comprobación | Cómo se arregla |
|---|---|
| ¿Docker tiene ≥4 GB de RAM? | Settings → Resources, o `colima start --memory 8` |
| *(Windows)* ¿El proyecto está en `/mnt/c/`? | Muévelo a `/home/tu_usuario/` |
| ¿Tienes Airflow y minikube a la vez? | Apaga uno: `docker compose down` o `minikube stop` |
| ¿Chrome con 40 pestañas? | En serio, ciérralas |

### 9.8 «no matching manifest for linux/arm64»

Mac con Apple Silicon intentando usar una imagen que solo existe para Intel.
Añade `--platform linux/amd64` al `docker run` o al `docker build`. Irá
lento, pero funcionará.

### 9.9 Me he quedado sin espacio en disco

Docker acumula imágenes, contenedores parados, volúmenes huérfanos y caché de
build. Mira cuánto ocupa:

```bash
docker system df
```

Limpieza segura (borra solo lo que no está en uso):

```bash
docker system prune
```

Limpieza agresiva:

```bash
docker system prune -a --volumes
```

> ⚠️ El segundo comando **borra también los volúmenes**, es decir, los datos
> de tus bases de datos. Y te obligará a volver a descargar las imágenes.
> Antes de un día de clase, no lo hagas.

### 9.10 minikube no arranca

| Error | Causa y solución |
|---|---|
| `DRV_NOT_DETECTED` | Docker no está corriendo, o has instalado minikube en Windows y Docker en WSL |
| `Insufficient memory` | Baja a `--memory=3072`, o sube la RAM de Docker Desktop / Colima |
| Se queda colgado en «Creating docker container» | `minikube delete && minikube start --driver=docker` |
| `ImagePullBackOff` al desplegar | Tu imagen local no existe dentro del cluster — está explicado en [TEORIA_KUBERNETES.md § 10.1](./TEORIA_KUBERNETES.md) |

Para empezar de cero sin miedo:

```bash
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

---

## 10. Plan B: si tu ordenador no puede

Si tu portátil es de empresa con la BIOS bloqueada, tienes 4 GB de RAM o
Windows en una versión demasiado antigua, **avisa al profesor con antelación**.
Existen alternativas, pero requieren preparación previa:

| Opción | Qué es | Limitaciones |
|---|---|---|
| **GitHub Codespaces** | VS Code en el navegador con Docker incluido | 60 h gratis/mes; requiere cuenta de GitHub |
| **Play with Docker** | <https://labs.play-with-docker.com> | Sesiones de 4 h, se borra todo al terminar |
| **Killercoda** | <https://killercoda.com> | Escenarios de K8s en el navegador, sesiones cortas |
| **Trabajar en pareja** | Compartir portátil con un compañero | Menos práctica personal, pero funciona |

> Estas opciones sirven para seguir la clase, pero **no sustituyen tener
> Docker en tu máquina**. Como Data Engineer vas a usar Docker todos los
> días: merece la pena resolver el problema de raíz.

---

## Apéndice A — Tabla de alternativas por sistema

| Sistema | Opción recomendada | Alternativa libre | Evitar |
|---|---|---|---|
| **macOS Apple Silicon** | Docker Desktop | Colima + docker CLI | Docker Toolbox (obsoleto) |
| **macOS Intel** | Docker Desktop | Colima, Rancher Desktop | Docker Toolbox |
| **Windows 11** | Docker Desktop + WSL2 | Rancher Desktop, Engine en WSL | Docker en CMD/PowerShell puro |
| **Windows 10 (2004+)** | Docker Desktop + WSL2 | Engine dentro de WSL2 | WSL versión 1 |
| **Windows 10 antiguo** | ⚠️ Actualizar Windows | GitHub Codespaces | Hyper-V manual |
| **Ubuntu / Debian** | Docker Engine (get.docker.com) | — | `snap`, paquete `docker.io` |
| **Fedora / RHEL** | Docker Engine | Podman + alias (con matices) | — |
| **Linux ARM** | Docker Engine (binarios arm64) | — | Binarios amd64 |

### Sobre Podman

Podman es un sustituto de Docker sin demonio, muy usado en entornos RHEL. La
mayoría de comandos son idénticos (`alias docker=podman`), pero
**`podman compose` no se comporta igual** que `docker compose` y en clase
darás con diferencias justo en los ejercicios del bloque 3. Si es tu única
opción, avisa al profesor antes.

---

## Apéndice B — Notas para el profesor

### Distribución de imágenes sin depender del wifi

Si el aula tiene mala conexión o alguien llega sin las imágenes, se pueden
llevar en un USB y cargarlas en segundos:

```bash
# En la máquina que sí las tiene (genera ~2 GB)
docker save -o imagenes-clase.tar \
  alpine:3.21 \
  postgres:18-alpine \
  python:3.13-slim \
  apache/airflow:3.3.1-python3.14

# En la máquina del alumno
docker load -i imagenes-clase.tar
```

Merece la pena comprimirlo (`gzip imagenes-clase.tar`) para que quepa mejor.

### Comprobación rápida al inicio de la sesión

Un solo comando que el alumno ejecuta y enseña en pantalla:

```bash
docker compose version && docker images | wc -l && docker info | grep -i username
```

En 10 segundos por persona se detecta quién no ha hecho los deberes, y se le
puede emparejar con un compañero antes de empezar en vez de a mitad del
ejercicio 3.

### Puertos reservados en el material

| Puerto | Uso | Documento |
|---|---|---|
| 8080 | Airflow del proyecto real | `docker-compose.yml` raíz |
| 8088 | Airflow del sandbox | EJERCICIOS.md, bloques 3–4 |
| 8090 | `port-forward` de Kubernetes | EJERCICIOS_KUBERNETES.md |
| 5433 | PostgreSQL del ejercicio 3 | EJERCICIOS.md |
| 5439 | PostgreSQL de la prueba de este documento | REQUISITOS.md § 8 |
