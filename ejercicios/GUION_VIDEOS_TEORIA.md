# Guion — Vídeos de teoría (Docker y Kubernetes)

**Formato:** 15 vídeos cortos para grabar antes de las sesiones en directo.
Duración total aprox. **2 h 40 min** (unos 77 min de Docker y 85 de
Kubernetes).

Cada bloque incluye: objetivo del vídeo, el guion narrado (puedes leerlo
casi literal), los puntos que remarcar en cámara y qué ejercicio desbloquea.

## Cómo usar este guion mientras grabas

Las diapositivas de referencia son **las definitivas aprobadas por
dirección**:
`diapositivas/diapositivas_finales/contenedores_virtualizacion_pontia_2026_ADAPTADO.pdf`
(184 páginas).

Dentro del guion verás marcas como **▶ 17** o **▶ 17–18**. Son el **número
de página del PDF** que debe estar en pantalla en ese momento. Están puestas
justo en el punto del texto donde toca pasar de diapositiva, así que puedes
leer de corrido y avanzar cuando las veas.

> ⚠️ **El público son futuros ingenieros de datos, no futuros SRE.** Siempre
> que dudes entre profundizar en un detalle de infraestructura o enseñar
> cómo eso se traduce a un pipeline, elige lo segundo. Hay varias
> diapositivas (Spark, Kafka, `read_csv` que revienta el nodo, Airflow)
> puestas justo para eso: apóyate en ellas.

**Qué se asume:** soltura con la terminal, Python y SQL. **No** se asume
absolutamente nada de contenedores: el vídeo 1 empieza desde cero.

> Antes de publicar los vídeos, comprueba que los alumnos han recibido
> **[REQUISITOS.md](./REQUISITOS.md)**. Menciónalo en el vídeo 1: si llegan
> sin Docker instalado, los vídeos no sirven de nada.

---

## Mapa de los vídeos

### Bloque A — Docker (sesiones 1 y 2)

| # | Vídeo | Duración | Diapositivas | Teoría | Desbloquea |
|---|---|---|---|---|---|
| 1 | Por qué existe Docker (Módulo 0) | 11 min | 4–32 | — | — |
| 2 | Imagen, contenedor y ciclo de vida | 11 min | 38–51 | §1, §2 | Ej. 1, 2 |
| 3 | Volúmenes y puertos | 11 min | 52–57 | §5, §6 | Ej. 3 |
| 4 | Imágenes: nombre, tag, plataforma y registries | 10 min | 58–65 | §3 | Ej. 5 bis |
| 5 | Dockerfile: capas, caché y contexto | 12 min | 66–78 | §3.2, §4 | Ej. 4, 5 |
| 6 | Compose: varios servicios que se hablan | 12 min | 79–102 | §7, §8, §9 | Ej. 6, 7, 8, 9 |
| 7 | Arranque robusto y el stack real de Airflow | 10 min | 103–116 | §10, §11 | Ej. 10 |

### Bloque B — Kubernetes (sesión 3)

| # | Vídeo | Duración | Diapositivas | Teoría (K8s) | Desbloquea |
|---|---|---|---|---|---|
| 8 | Por qué Kubernetes: de dar órdenes a describir un estado | 10 min | 117–126 | §1 | — |
| 9 | Anatomía del cluster y del YAML | 11 min | 127–141 | §2, §3 | Bloque 0 |
| 10 | Pod, Deployment y self-healing | 10 min | 142–146 | §4 | Ej. 1 |
| 11 | Services: la IP estable que tu pipeline necesita | 10 min | 147–153 | §5 | Ej. 2 |
| 12 | ConfigMap, Secret y almacenamiento persistente | 12 min | 154–163 | §6, §7 | Ej. 3, 4 |
| 13 | Salud y recursos: probes, limits y `OOMKilled` | 10 min | 164–167 | §8 | — |
| 14 | Job y CronJob: tu pan de cada día | 12 min | 168–173 | §9 | Ej. 5 |
| 15 | minikube, tabla de traducción y diagnóstico | 10 min | 174–184 | §10, §11 | Ej. 6 |

**Si tienes que recortar:** los vídeos **4** y **9** son los más
prescindibles (el 4 se puede leer; del 9 basta con la primera mitad). El
vídeo **14** es innegociable: es el que separa a un data engineer que sabe
Kubernetes de uno que solo lo ha visto.

---

# BLOQUE A — DOCKER

## Vídeo 1 — Por qué existe Docker (11 min)

**Diapositivas:** 4 a 32 (Módulo 0 completo)
**Objetivo:** que entiendan el problema **antes** que la herramienta, y que
salgan sabiendo que Docker no inventó los contenedores: los hizo usables.
Este vídeo no tiene ejercicios; es el contexto sobre el que se apoya todo lo
demás.

**Guion:**

> ▶ **4–5** Bienvenidos al módulo de contenedores. Antes de tocar un solo
> comando quiero que entendáis **qué problema resuelve Docker**, porque si
> empezamos por los comandos os vais a aprender una lista de flags sin saber
> para qué sirven, y eso se olvida en dos semanas. El problema, en cambio,
> no se olvida: lo vais a sufrir.
>
> ▶ **7** Empecemos por la frase más cara de la industria del software: "en
> mi máquina funciona". Y quiero que os quedéis con un matiz importante:
> **no es una excusa, casi siempre es literalmente cierto**. En vuestro
> portátil tenéis Python 3.11, pandas 2.1, Postgres 16, macOS con chip de
> Apple. En el servidor de producción hay Python 3.9, pandas 1.5, Postgres
> 13 y un Ubuntu 20.04 sobre x86. Y por ahí en medio, una variable de
> entorno que pusisteis hace tres meses y de la que ya no os acordáis.
>
> El código es idéntico. El entorno no. Y el software se ejecuta en un
> entorno, no en el vacío.
>
> ▶ **8** ¿Cuánto cuesta eso de verdad? Un pipeline que va perfecto en local
> y revienta de madrugada en producción. Dos días de un ingeniero replicando
> un entorno a mano siguiendo un documento de cuarenta pasos que además
> está desactualizado. Dos proyectos en el mismo servidor que necesitan
> versiones incompatibles de la misma librería. Un compañero nuevo que tarda
> una semana en poder ejecutar el proyecto. Y el peor de todos, el quinto:
> **nadie se atreve a actualizar nada, porque nadie sabe qué se rompería**.
> Ese es el momento en que un equipo de datos deja de avanzar.
>
> ▶ **9–10** Esto ya se intentó resolver antes, y con una idea correcta: si
> el problema es el entorno, empaquetemos el entorno entero. Eso son las
> **máquinas virtuales**. Coges tu aplicación, y debajo le metes un sistema
> operativo completo, con su propio kernel, y eso corre sobre un hipervisor.
> Funciona. El aislamiento es total.
>
> ▶ **11** Pero el precio es alto. Una máquina virtual ocupa gigabytes,
> tarda minutos en arrancar porque está arrancando un sistema operativo de
> verdad, y reserva RAM y CPU por adelantado las use o no. Fijaos en la
> frase de abajo, que es la que resume todo el problema: **para aislar una
> aplicación de 50 megas, arrancas un sistema operativo de 2 gigas**. La
> idea es correcta; la unidad de empaquetado es demasiado gruesa. Por eso
> con tres o cuatro máquinas virtuales vuestro portátil se rinde.
>
> ▶ **12–13** Y llegamos a 2013. Aquí hay algo que me gusta contar porque
> desmonta un mito: **Docker no inventó el aislamiento**. Las piezas ya
> estaban en el kernel de Linux, y llevaban ahí décadas. `chroot` es de
> 1979. Los *namespaces*, que son los que hacen que un proceso vea su propia
> red y su propio sistema de archivos, son de 2002. Los *cgroups*, que
> limitan cuánta CPU y memoria puede consumir un grupo de procesos, los donó
> Google en 2006. Y en 2008 LXC ya juntaba todo eso en algo llamado
> "contenedores de Linux".
>
> O sea: todo estaba disponible, y era gratis. Y casi nadie lo usaba. ¿Por
> qué? Porque montar un contenedor a mano con esas herramientas requería ser
> experto en el kernel. Estaba ahí, pero no era usable.
>
> ▶ **14** Y entonces aparece dotCloud, una empresa que estaba a punto de
> cerrar. Tenían una plataforma para desplegar aplicaciones y, para hacerla
> funcionar, habían construido una capa interna que empaquetaba el código de
> sus clientes en contenedores de Linux. El negocio no despegaba, así que en
> marzo de 2013 liberaron esa capa interna como proyecto de código abierto,
> en una charla de cinco minutos en la PyCon. En cuestión de meses el
> proyecto valía más que la empresa entera, y dotCloud se renombró Docker.
>
> La frase de la derecha es la que quiero que os llevéis: **Docker no
> inventó los contenedores. Los hizo usables.** Que, por cierto, es una
> lección que se repite bastante en tecnología.
>
> ▶ **15** Lo que Docker sí inventó fueron tres cosas, y ninguna es
> tecnología de kernel: las tres son de experiencia de uso. Un **formato de
> imagen** por capas, que empaqueta la aplicación y su entorno en un
> artefacto inmutable. El **Dockerfile**, que es una receta de texto,
> versionable en Git, que describe cómo se construye esa imagen. Y un
> **registro público**, Docker Hub, de donde descargarse imágenes ya hechas
> y al que subir las tuyas.
>
> Estandarizar el empaquetado y el reparto. Eso es lo que cambió la
> industria.
>
> ▶ **16** Y de ahí viene el nombre, que es una analogía muy buena. Antes de
> 1956, transportar mercancías era un caos: sacos, cajas, barriles, cada
> cosa se cargaba de una forma. Descargar un barco eran días de trabajo,
> porque el barco, la grúa y el camión tenían que conocer la carga. Llega el
> contenedor de mercancías estándar: una caja metálica de medidas fijas, y
> da exactamente igual lo que lleve dentro. Descargar el barco pasa a ser
> horas. Docker hace lo mismo con el software: da igual si dentro hay
> Python, Java o Go. La plataforma solo conoce la caja.
>
> ▶ **17** Y aquí está la diferencia técnica clave frente a la máquina
> virtual. Mirad los dos dibujos. En las máquinas virtuales, cada aplicación
> arrastra su sistema operativo de dos gigas. En los contenedores, **el
> kernel se comparte**: solo hay uno, el del anfitrión, y encima corren los
> procesos aislados. Ahí está toda la diferencia.
>
> ▶ **18** Traducido a números: una VM ocupa entre 1 y 20 gigas y tarda
> minutos en arrancar; un contenedor ocupa entre 50 megas y 1 giga y arranca
> en menos de un segundo. De VMs os caben unas decenas por servidor; de
> contenedores, cientos.
>
> Y dos matices honestos, porque no quiero venderos humo. El primero: **no
> es que uno sea mejor que otro**, es que el contenedor es una unidad de
> empaquetado más fina. De hecho conviven: en la nube, vuestros contenedores
> casi siempre están corriendo dentro de máquinas virtuales. El segundo, que
> explica una cosa que os va a pasar: en macOS y en Windows, Docker Desktop
> arranca **una máquina virtual de Linux por debajo**, porque los
> contenedores necesitan un kernel de Linux. Así que si tenéis Mac, cuando
> ejecutáis un contenedor hay una VM de por medio. Es un detalle que
> explicará algún comportamiento raro más adelante.
>
> ▶ **19–20** Vamos al vocabulario, que son tres palabras y las vais a usar
> durante todo el máster. La **imagen** es la plantilla inmutable: vuestro
> código, sus dependencias y el sistema base. El **contenedor** es una
> imagen en ejecución. Y el **registro** es el almacén de imágenes.
>
> La analogía de abajo es la que os va a salvar: **imagen es a contenedor lo
> que clase es a objeto**. O, si preferís algo más de andar por casa, lo que
> receta es a plato. De una receta salen mil platos idénticos, y la receta no
> cambia.
>
> ▶ **21** Y este diagrama es, literalmente, todo lo que hace Docker.
> Escribís un **Dockerfile**, que vive en Git. Con `docker build` eso se
> convierte en una **imagen**, que es un artefacto inmutable. Con
> `docker run` la imagen se convierte en un **contenedor** en ejecución. Y
> con `push` y `pull` esa imagen viaja a un **registro** y vuelve. Ya está.
> Todo lo demás son detalles.
>
> La frase de abajo es la importante: **el mismo artefacto corre en vuestro
> portátil, en el sistema de integración continua y en producción**.
>
> ▶ **22** Tres malentendidos que quiero desactivar hoy mismo. Uno: **no es
> una máquina virtual ligera**; no hay un sistema operativo dentro, son
> procesos aislados. Dos: **no resuelve solas vuestras dependencias**; os
> obliga a declararlas explícitamente, que es lo que las hace
> reproducibles, pero el trabajo lo seguís haciendo vosotros. Y tres, que
> conviene decirlo pronto: **no es seguro por defecto**. Un contenedor mal
> configurado puede acceder al anfitrión. Aísla, pero no es una barrera de
> seguridad completa.
>
> ▶ **23–24** ¿Para qué se usa? Nació en DevOps, y ahí lo que hizo posible
> fue el CI/CD moderno. Mirad la cadena: hacéis push a Git, se construye una
> imagen —la `a3f9c1`—, se pasan los tests **sobre esa misma imagen**, se
> despliega **esa misma imagen** a staging, y se despliega **esa misma
> imagen** a producción. Lo que se prueba es exactamente lo que se despliega.
> Sin contenedores, cada entorno se construye por separado y puede diferir,
> con lo cual pasar los tests no te garantiza nada.
>
> ▶ **25** Los cinco usos clásicos los tenéis en la tabla, pero quedaos con
> el último: **hoy la unidad de despliegue estándar en cualquier nube es una
> imagen de contenedor**. ECS, Cloud Run, App Runner, Kubernetes: todos
> consumen imágenes. No saber Docker os cierra la puerta a todo lo demás.
>
> ▶ **26–27** Y ahora la parte que os toca a vosotros, donde esto deja de
> ser cultura general. El problema de dependencias en datos es **peor** que
> en cualquier otro sitio, y no lo digo por dramatizar. Mirad lo que arrastra
> un stack de datos típico: Python con pandas, numpy y pyarrow. Bibliotecas
> de sistema en C: `libpq`, `libgeos`, `libhdf5`. La JVM entera si hay
> Spark. Drivers ODBC. Y versiones de Airflow con dependencias fijadas al
> milímetro.
>
> ¿Por qué duele? Porque un `pip install` os falla al compilar en Linux y
> funciona en macOS. O porque tenéis un cluster de Spark donde cada nodo
> arrastra una versión distinta de una librería, y las cosas fallan solo a
> veces, que es la peor forma de fallar.
>
> ▶ **28** Seis sitios concretos donde os vais a encontrar Docker en este
> máster: **Airflow**, cuyo despliegue estándar es Compose o Kubernetes.
> **Bases de datos en local** —Postgres, Kafka, MinIO— en un comando y sin
> ensuciar vuestro equipo. **Spark**, donde cada ejecutor arranca como un
> contenedor con exactamente las mismas dependencias. **dbt**, donde la
> imagen fija la versión de dbt y del adaptador. Las **tareas de un DAG**,
> con `DockerOperator` y `KubernetesPodOperator`, donde cada tarea corre
> aislada en su propia imagen. Y **notebooks y machine learning**, donde la
> imagen fija versiones de CUDA, PyTorch y drivers.
>
> ▶ **29** Este ejemplo os va a sonar. A la izquierda, el mismo objetivo sin
> Docker: instala Postgres, configura el usuario, instala Python, crea el
> venv, `pip install`... y falla compilando `psycopg2`. Instala `libpq-dev`.
> Repite todo en el servidor. Documenta cuarenta pasos en Confluence. Y el
> documento queda obsoleto en dos semanas. A la derecha: `docker compose up
> -d`. Y ese `docker-compose.yml` está en Git, versionado junto al código.
>
> ▶ **30** Última pieza de contexto, para que no os quedéis con una foto
> desactualizada: hoy Docker ya no está solo. En 2015 el formato de imagen
> se estandarizó bajo la **OCI**, así que ya no es "de Docker", es un
> estándar abierto. **containerd**, el motor que ejecuta contenedores, se
> extrajo de Docker y es lo que usa Kubernetes por debajo. Existen
> alternativas compatibles como **Podman**. Y **Kubernetes** orquesta todo
> eso en cientos de máquinas, que es la sesión 3 de este mismo módulo.
>
> De hecho, un dato que sorprende: **Kubernetes dejó de usar Docker como
> motor en 2022**. Y aun así sigue ejecutando imágenes construidas con
> Docker, porque el formato es estándar. Por eso todo lo que aprendéis hoy
> no caduca.
>
> ▶ **31–32** Y cierro con las cinco frases del resumen, que si os las
> lleváis ya habéis aprovechado el vídeo. El problema no es el código, es el
> entorno. Las máquinas virtuales lo resolvían empaquetando un sistema
> operativo entero. Un contenedor comparte el kernel: pesa megas y arranca
> en un segundo. Docker no inventó los contenedores: inventó el formato, la
> receta y el registro. Y hoy es la unidad de despliegue estándar de la nube
> y la base de Airflow, Spark y Kubernetes.
>
> A partir del siguiente vídeo ya no hablamos: empezamos a ejecutar cosas.
> Aseguraos de tener Docker instalado siguiendo `REQUISITOS.md`, porque si
> llegáis a la sesión sin él, la primera hora se nos va en barras de
> progreso.

**Puntos clave a remarcar en cámara:**
- El problema es el **entorno**, no el código. Y "en mi máquina funciona" suele ser cierto.
- La VM tenía la idea correcta con la unidad equivocada: 2 GB de SO para aislar 50 MB de app.
- Docker **no inventó** los contenedores (chroot, namespaces, cgroups, LXC). Inventó imagen + Dockerfile + registro.
- Contenedor comparte kernel → megas y milisegundos. En Mac/Windows hay una VM de Linux por debajo.
- Imagen : contenedor :: clase : objeto :: receta : plato.
- No es seguro por defecto. Decirlo pronto y sin dramatismo.
- En datos duele más por las dependencias nativas (C, JVM, drivers).

---

## Vídeo 2 — Imagen, contenedor y ciclo de vida (11 min)

**Diapositivas:** 38 a 51
**Teoría:** TEORIA.md §1 y §2
**Desbloquea:** ejercicios 1 y 2

**Objetivo:** que sepan arrancar, listar, inspeccionar y borrar
contenedores, y sobre todo que entiendan **por qué un contenedor "se muere
solo"**, que es la fuente del 80 % de la confusión de la primera semana.

**Guion:**

> ▶ **38–39** Antes de nada, cinco minutos de comprobación que os van a
> ahorrar cuarenta de incidencias. Abrid una terminal y lanzad estos cuatro
> comandos: `docker --version`, `docker run --rm hello-world`,
> `docker compose version` y `docker images`. Si los cuatro responden, estáis
> listos.
>
> Si alguno falla, la sección 8 de `REQUISITOS.md` lo cubre. Los tres fallos
> típicos: en macOS, no haber arrancado Colima o Docker Desktop; en Windows,
> no haber marcado la integración con WSL; en Linux, no haber hecho el
> `usermod -aG docker`. Resolvedlo **ahora**, no dentro de una hora.
>
> ▶ **40–41** Tres palabras que vais a usar todo el día. La **imagen** es
> una plantilla de solo lectura, con un sistema de archivos y metadatos: la
> clase, la receta. El **contenedor** es una instancia en ejecución de esa
> imagen, **con su propia capa de escritura encima**: el objeto, el plato ya
> cocinado. Y el **registry** es el servidor donde viven las imágenes; se
> descargan con `pull` y se suben con `push`.
>
> Fijaos en la frase de abajo, que es la que más veces voy a repetir: de una
> misma imagen podéis arrancar cien contenedores independientes, y **la
> imagen no cambia nunca**.
>
> ▶ **42** Ya lo vimos en el módulo 0, pero lo dejo en pantalla porque es la
> tabla a la que volveréis: arranque, tamaño, RAM, aislamiento y densidad. Un
> contenedor arranca en unos 100 milisegundos, no en dos minutos.
>
> ▶ **43** Y aquí una diapositiva que tiene una frase incómoda y que quiero
> que os llevéis tal cual. Sí, la imagen empaqueta las dependencias exactas,
> y por eso vuestro portátil, el sistema de integración y producción ejecutan
> los mismos bytes. **Pero eso también significa que si vuestra imagen está
> mal construida, está mal construida en todas partes.**
>
> Docker no arregla el problema: **lo hace reproducible**. Que es
> muchísimo, ojo, porque un error reproducible se puede arreglar; uno que
> aparece solo a veces, no. Pero no es magia.
>
> ▶ **44–45** Vamos con el concepto que más errores causa en las primeras
> semanas: el ciclo de vida. Un contenedor **vive exactamente lo que viva su
> proceso principal**. No es una máquina virtual que arrancas y se queda
> encendida esperando. Si lanzáis un contenedor cuyo comando es `echo hola`,
> imprime "hola", el proceso termina, y el contenedor **se para
> inmediatamente**. No está roto: ha hecho su trabajo y se ha ido, como un
> buen profesional.
>
> Mirad el diagrama: `docker run` lo pone en **RUNNING**. Cuando hacéis
> `docker stop`, o cuando el proceso termina solo, pasa a **EXITED**. Y
> fijaos en lo que dice justo debajo de EXITED: *parado, pero existe en el
> sistema*. Solo `docker rm` lo borra de verdad. Y desde EXITED podéis
> resucitarlo con `docker start`.
>
> ▶ **46** Tres ideas que hay que fijar, porque casi todas las confusiones
> del primer día salen de aquí. Uno: un contenedor **EXITED no está
> borrado**; sigue ocupando espacio en disco y solo aparece con
> `docker ps -a`. Dos: **el borrado real solo lo hace `docker rm`**;
> `docker stop` detiene, no borra. Y tres: `docker run --rm` se autoelimina
> al terminar, y es perfecto para pruebas de un solo uso.
>
> El consejo de diagnóstico de abajo os lo vais a agradecer: **si
> `docker ps` no muestra vuestro contenedor, probad `docker ps -a` antes de
> intentar lanzarlo otra vez.** Lo más probable es que siga ahí, parado, y la
> explicación del fallo esté en sus logs. La alternativa —volver a lanzarlo—
> es cómo la gente acaba con veinte contenedores muertos y el disco lleno.
>
> ▶ **47** Los flags de `docker run`. Hay decenas; con estos ocho cubrís el
> 95 % de los casos, y de estos ocho hoy nos importan cuatro.
>
> **`-d`** lo lanza en segundo plano y os devuelve la terminal; sin él os
> quedáis enganchados a su salida. **`-it`** os da una shell interactiva
> dentro. **`--name`** le pone un nombre fijo en vez del nombre aleatorio
> gracioso que se inventa Docker —que están muy logrados, pero copiarlos a
> mano cansa—. Y **`--rm`** lo autoelimina al terminar.
>
> Los otros cuatro —`-e`, `-p`, `-v` y `--restart`— salen en los dos vídeos
> siguientes, así que de momento solo quedaos con que existen.
>
> Un aviso sobre `-d` y `--rm` juntos: son cómodos pero traicioneros. Si
> lanzáis algo en segundo plano con `--rm` y falla, el contenedor se borra
> **con sus logs dentro**, y os quedáis sin poder investigar qué pasó.
>
> ▶ **48** Y estos son los comandos de cuando algo va mal, que son los que
> de verdad os van a salvar. `docker ps` y `docker ps -a` para ver qué hay.
> **`docker logs`** para la salida completa, y **`docker logs -f`** para
> seguirla en tiempo real, igual que un `tail -f`. **`docker exec -it <cont>
> sh`** para abrir una shell **dentro** del contenedor y mirar qué archivos
> hay o qué variables de entorno tiene. `docker inspect` para el JSON
> completo con IP, volúmenes y variables. Y `docker stats` para ver CPU y
> memoria en vivo.
>
> La frase del pie es una norma de la asignatura: **`docker logs` es la
> primera herramienta de diagnóstico, no la última.** Cuando en clase digáis
> "no funciona", lo primero que os voy a preguntar es qué dicen los logs.
>
> ▶ **49–50** Con esto ya podéis hacer los ejercicios 1 y 2. En el primero
> arrancáis un nginx en el puerto 8088, lo comprobáis desde el navegador y lo
> paráis; la pregunta a responder es qué diferencia hay entre `docker ps` y
> `docker ps -a` después de pararlo.
>
> El ejercicio 2 es el importante. Entráis en un Alpine, escribís un fichero,
> salís, lo arrancáis otra vez y el fichero **sigue ahí**. Luego hacéis
> `docker rm`, arrancáis un contenedor nuevo de la misma imagen, y el fichero
> **ha desaparecido**. Los datos sobreviven a `stop` y `start`; mueren con
> `rm`. Y la pregunta para pensar es deliberadamente incómoda: si eso hubiera
> sido vuestra base de datos de producción, ¿qué acabáis de perder?
>
> ▶ **51** Porque ese ejercicio es, literalmente, el motivo de la siguiente
> sección. Mirad el dibujo: debajo están las **capas de la imagen**, en solo
> lectura, inmutables y compartidas entre contenedores. Y encima, la **capa
> de escritura**, que se crea al arrancar el contenedor y **se borra cuando
> hacéis `docker rm`**.
>
> Todo lo que escriba vuestro proceso —una fila en una tabla, un log, un
> parquet— va a esa capa. Y esa capa es mortal. Los volúmenes existen
> exactamente para sacar los datos fuera del ciclo de vida del contenedor. Y
> de eso va el vídeo siguiente.

**Puntos clave a remarcar en cámara:**
- El contenedor vive lo que viva su proceso principal. Si el proceso acaba, se para. **Es normal, no está roto.**
- `exited` ≠ borrado. `docker ps -a` para verlos; ocupan disco. Solo `rm` borra.
- Flags de hoy: `-d`, `-it`, `--name`, `--rm`. Cuidado con `-d --rm` juntos: pierdes los logs.
- `docker logs` y `docker exec -it ... sh` son las dos herramientas de diagnóstico.
- Docker no arregla el problema: lo hace **reproducible**.
- Cerrar con la capa de escritura: es el gancho hacia volúmenes.

**Demo en pantalla (recomendada):** lanzar un contenedor con un bucle que
imprima un contador cada 2 segundos y enseñar `docker logs -f` con la salida
en vivo, y luego `docker exec -it` entrando en él. Engancha mucho más que un
`hello-world`.

---

## Vídeo 3 — Volúmenes y puertos (11 min)

**Diapositivas:** 52 a 57
**Teoría:** TEORIA.md §5 y §6
**Desbloquea:** ejercicio 3

**Objetivo:** que entiendan que un contenedor está aislado por diseño, y las
dos formas de romper ese aislamiento a propósito. Son dos mecanismos
**independientes**, y confundirlos es clásico.

**Guion:**

> ▶ **52** Venimos del vídeo anterior con una idea incómoda: la capa de
> escritura de un contenedor muere con él. Y un contenedor, además, tiene la
> red invisible desde fuera. Las dos cosas son aislamiento, y el aislamiento
> es justo lo que queremos... casi siempre.
>
> Pero hay dos excepciones constantes: queremos que los datos **persistan**,
> y queremos poder **hablar** con el proceso de dentro. Para lo primero
> están los volúmenes; para lo segundo, la publicación de puertos. Insisto
> en algo que en el examen falla mucha gente: **son mecanismos
> independientes**. Publicar un puerto no persiste nada, y montar un volumen
> no abre ninguna red.
>
> ▶ **53** Empecemos por los volúmenes, que tienen dos formas y **no son
> intercambiables**.
>
> El **bind mount** monta una carpeta **vuestra, de vuestra máquina**, dentro
> del contenedor. Vosotros elegís la ruta: eso es lo que significa esa
> sintaxis `-v ruta_del_host:ruta_del_contenedor`. Docker no gestiona nada,
> simplemente hace visible esa carpeta dentro. Mirad el ejemplo: `./dags` de
> vuestro proyecto y `/opt/airflow/dags` dentro del contenedor pasan a ser
> **literalmente el mismo directorio** visto desde dos sitios. Escribís un
> DAG en vuestro editor y Airflow lo ve al instante, sin reconstruir ni
> reiniciar nada.
>
> El **volumen con nombre** es distinto: le dais un nombre y **Docker decide
> dónde guardarlo**, en una zona suya que sinceramente no os interesa. No lo
> editáis desde vuestro editor, pero **sobrevive a `docker rm`**, es portable
> y Docker sabe gestionarlo y respaldarlo.
>
> ▶ **54** La regla para no equivocarse nunca está en esta tabla. Datos de
> una base de datos: **volumen con nombre**, porque no necesitáis tocarlos a
> mano. Vuestro código —DAGs, scripts, notebooks—: **bind mount**, porque
> queréis editarlo y verlo al instante. Logs que queréis abrir desde vuestro
> editor: bind mount. Y datos temporales de una tarea: **nada**, que se
> pierdan es exactamente lo correcto.
>
> Y quiero que os fijéis en el caso real del pie, porque nos pasó de verdad
> en este proyecto: un volumen `postgres_data` creado con Postgres 15 **no
> arranca** con la imagen `postgres:18-alpine`. El formato de datos en disco
> cambia entre versiones mayores. Hubo que borrarlo con
> `docker compose down -v`. Es decir: el volumen os salva de perder datos por
> accidente, pero también os ata a la versión que los creó. Anotadlo, porque
> el día que actualicéis una base de datos en producción esto deja de ser una
> anécdota de clase.
>
> Y dejadme decirlo de la forma más cruda posible antes de pasar de tema: si
> tenéis PostgreSQL en un contenedor **sin volumen**, un `docker rm` borra
> **toda vuestra base de datos**. Y recrear el contenedor para actualizar la
> imagen, también. Es un error que se comete una vez en la vida y no se
> olvida.
>
> ▶ **55** Vamos con los puertos. Arrancáis Postgres en un contenedor, abrís
> vuestro cliente SQL contra el 5432 de localhost, y no conecta. El proceso
> está escuchando perfectamente, pero **dentro de su propia red aislada**.
> Vuestro `localhost` y el `localhost` del contenedor no son el mismo sitio.
> Ese aspa roja del dibujo es exactamente vuestro primer día con Docker.
>
> Para abrir una puerta se usa `-p`, y se lee **siempre** igual: el número de
> la **izquierda** es el puerto **en vuestra máquina**, el de la **derecha**
> es el puerto **dentro del contenedor**. Izquierda fuera, derecha dentro. Si
> os lo aprendéis en ese orden, os ahorráis muchísimos disgustos.
>
> ▶ **56** Y aquí las variantes, con dos cosas importantes.
>
> La primera: `-p 9090:8080` es perfectamente válido; los puertos **no tienen
> por qué coincidir**. Es utilísimo cuando dos proyectos quieren el mismo
> puerto: en clase usaremos el 8080 para el proyecto real y el 8088 para el
> sandbox, precisamente para que no choquen.
>
> La segunda, y fijaos porque en nuestro `docker-compose.yml` está hecho a
> propósito: `-p 127.0.0.1:8080:8080` publica **solo en localhost**. Con la
> forma corta, `-p 8080:8080`, estáis publicando en **todas** las interfaces,
> y cualquiera en la misma wifi puede entrar a vuestro Airflow. En una
> cafetería eso es, digamos, generoso por vuestra parte.
>
> Y el clásico del pie: **`EXPOSE` no publica nada**. Es solo un metadato en
> el Dockerfile, un comentario formal que dice "esta imagen escucha aquí". El
> que abre la puerta de verdad es `-p`. Aquí es donde mucha gente pierde una
> tarde entera.
>
> Antes de pasar al ejercicio, un aviso que enlaza con el vídeo 6 y que es
> importante: **para que dos contenedores hablen entre ellos NO hace falta
> `-p`**. Airflow se conecta a Postgres sin que Postgres publique ningún
> puerto al exterior. `-p` sirve solo para llegar **desde vuestra máquina**.
> Cómo se hablan entre ellos lo vemos en Compose.
>
> ▶ **57** Y con esto ya podéis hacer el ejercicio 3, que es donde se junta
> todo: arrancáis Postgres con un volumen con nombre y el puerto publicado en
> el 5433 —en el 5433 y no en el 5432, precisamente para no chocar con un
> Postgres que tengáis instalado—, creáis una tabla, **borráis el
> contenedor** con `docker rm -f`, y lo volvéis a arrancar con el mismo
> volumen. La tabla sigue ahí.
>
> El contenedor se ha borrado. Los datos, no. Ese es todo el concepto.

**Puntos clave a remarcar en cámara:**
- Volúmenes y puertos son mecanismos **independientes**. No mezclarlos.
- Sin volumen, `docker rm` borra los datos. Dicho así de crudo.
- Bind mount = tu carpeta, tú eliges la ruta, para **código**. Volumen con nombre = lo gestiona Docker, para **datos**.
- El caso real: volumen de Postgres 15 que no arranca con Postgres 18. El volumen te ata a la versión.
- `-p izquierda:derecha` = `host:contenedor`. Izquierda fuera, derecha dentro.
- `127.0.0.1:8080:8080` vs `8080:8080`: lo segundo te expone a toda la wifi.
- `EXPOSE` documenta, `-p` publica.
- Entre contenedores NO hace falta `-p`. (Gancho al vídeo 6.)

**Demo en pantalla (recomendada):** provocar el fallo antes de la solución.
Arrancar Postgres **sin** `-p`, intentar conectar y que falle; luego
añadirlo. El síntoma primero, el concepto después.

---

## Vídeo 4 — Imágenes: nombre, tag, plataforma y registries (10 min)

**Diapositivas:** 58 a 65
**Teoría:** TEORIA.md §3
**Desbloquea:** ejercicio 5 bis (publicar en Docker Hub)

**Objetivo:** que sepan leer el nombre completo de una imagen, que entiendan
por qué `latest` es peligroso, y que sepan diagnosticar el `exec format
error` que le aparece a media clase con Mac.

**Guion:**

> ▶ **58–59** Llevamos tres vídeos usando imágenes que ha hecho otro. Vamos a
> mirarlas por dentro antes de construir la nuestra.
>
> Una imagen es un **snapshot de un sistema de archivos**: capas de solo
> lectura más metadatos. Dentro lleva un sistema operativo mínimo —Alpine son
> 7 megas, Ubuntu 77—, librerías y binarios, vuestra aplicación con sus
> dependencias, y unos metadatos que dicen cuál es el comando por defecto,
> qué variables tiene y con qué usuario corre.
>
> Y fijaos en lo que hace `docker run` realmente, que son cuatro pasos:
> descarga la imagen si no la tiene, crea un contenedor nuevo, **le añade una
> capa de escritura encima** —esa capa que ya conocemos— y arranca el proceso
> principal. Cien llamadas a `docker run` generan cien contenedores
> independientes, y la imagen no cambia.
>
> ▶ **60** Oficiales frente a personalizadas, y se distinguen por una tontería
> que conviene saber leer: **si no hay prefijo de organización, es oficial**.
> `postgres:18-alpine`, `python:3.13-slim`, `alpine:3.21` son oficiales,
> mantenidas por el propio proyecto. En cuanto veis una barra —
> `apache/airflow`, `bitnami/postgresql`, `vuestro-usuario/mi-pipeline`— hay
> una organización detrás.
>
> ▶ **61** Y esto explica por qué. El nombre completo de una imagen tiene
> cuatro partes: **registry**, **organización**, **repositorio** y **tag**.
> Cuando escribís solo `postgres`, Docker rellena el resto por vosotros: el
> registry pasa a ser `docker.io`, la organización `library` —que es el
> namespace especial de las oficiales— y el tag... **`latest`**.
>
> O sea que ese `postgres` inocente que habéis escrito es en realidad
> `docker.io/library/postgres:latest`. Y ahí empiezan los sustos.
>
> ▶ **62** Porque **`latest` es una promesa que nadie os ha hecho**. No
> significa "la última versión estable"; es simplemente el tag que se usa si
> no especificáis ninguno, y apunta a lo que el que publicó la imagen haya
> decidido. Puede cambiar debajo de vuestros pies sin avisar.
>
> Mirad el ejemplo: hacéis `docker pull postgres` hoy y os bajáis PostgreSQL
> 18.3. Dentro de tres meses, el mismo comando os baja PostgreSQL 19. Y
> vuestro compañero, ejecutando literalmente el mismo comando que vosotros,
> se baja otra versión distinta.
>
> Traducido a vuestro trabajo: si vuestro pipeline usa `python:latest`, un día
> cualquiera el mantenedor publica una versión nueva, vuestro build la coge, y
> un pipeline que llevaba seis meses funcionando se rompe **sin que nadie haya
> tocado una línea de código**. Y es especialmente desagradable de
> diagnosticar, porque en Git no hay ningún cambio que mirar.
>
> La regla no tiene excepciones: **en un proyecto real, nunca `latest`**. Ni
> en el Dockerfile, ni en el Compose. En nuestro proyecto está fijado en el
> `.env`: `apache/airflow:3.3.1-python3.14`.
>
> Y ya que sale: ese sufijo `alpine` que veis por todas partes es una
> distribución de Linux minúscula. Esas variantes ocupan una fracción de la
> normal, y menos tamaño es menos descarga y menos superficie de ataque.
>
> ▶ **63** Y ahora una diapositiva que va dedicada a los que tenéis Mac con
> chip de Apple, que sois muchos. **Una imagen no vale para cualquier
> procesador.** Vuestro Mac es `arm64`. El servidor de vuestra empresa es,
> casi seguro, `amd64`.
>
> El síntoma es este mensaje maravillosamente críptico: `exec format error`. Y
> hay una variante peor, porque al menos el error se ve: que **arranque pero
> vaya diez veces más lento**, porque está emulando la arquitectura. Ese lo
> descubrís tres semanas después preguntándoos por qué vuestro pipeline tarda
> una eternidad.
>
> La solución es declarar la plataforma explícitamente, tanto al construir
> como al ejecutar: `--platform linux/amd64`.
>
> Y quedaos con el matiz del pie, que es el que evita confusión: las imágenes
> **oficiales** son multiarquitectura, y Docker elige la vuestra solo. Por eso
> `postgres` o `python` os funcionan sin pensar. El problema aparece con **la
> vuestra**: construida en vuestro Mac, desplegada en un Linux amd64. Ese es
> el día en que este error os muerde.
>
> ▶ **64** Los registries. Docker Hub es el de por defecto, no el único. En
> AWS tenéis **ECR**, en Google **Artifact Registry**, en GitHub **GHCR**, en
> Red Hat **Quay**. Y la realidad laboral es la del pie: en cualquier empresa
> con nube, vuestras imágenes acabarán en ECR o en Artifact Registry, no en
> Docker Hub.
>
> La buena noticia es que la mecánica es **idéntica** en todos: `login`,
> `build`, `push`, `pull`. Aprendéis uno y los sabéis todos; lo único que
> cambia es la URL y cómo os autenticáis.
>
> ▶ **65** Y con eso ya podéis hacer el ejercicio 5 bis, que se hace en grupo
> y es de mis favoritos porque el "clic" es inmediato. Una persona hace
> `login`, `build` y `push` de una imagen, y comparte el nombre exacto con la
> clase. El resto hacéis `docker run` de ese nombre y **funciona**.
>
> Y quiero que os fijéis en lo que **no** ha pasado: nadie ha compartido
> código, nadie ha instalado nada, nadie ha configurado un entorno. Solo se ha
> movido un artefacto. Eso es exactamente lo que hace un pipeline de
> integración continua cuando despliega. Sin magia.

**Puntos clave a remarcar en cámara:**
- `docker run` hace 4 cosas: pull si falta, crea contenedor, añade capa RW, arranca proceso.
- Sin prefijo de organización = imagen oficial.
- Nombre completo: `registry/organización/repositorio:tag`. `postgres` → `docker.io/library/postgres:latest`.
- `latest` **NO** es "la última". Es móvil. Nunca en un proyecto real.
- `exec format error` = arquitectura. Mac = arm64, servidor = amd64. Solución: `--platform linux/amd64`.
- Las oficiales son multiarquitectura; el problema aparece con **tu** imagen.
- En empresa las imágenes viven en ECR / Artifact Registry, no en Docker Hub. Misma mecánica.

---

## Vídeo 5 — Dockerfile: capas, caché y contexto (12 min)

**Diapositivas:** 66 a 78
**Teoría:** TEORIA.md §3.2 y §4
**Desbloquea:** ejercicios 4 y 5

**Objetivo:** que sepan escribir un Dockerfile que extienda una imagen
oficial —que es el 90 % de lo que hará un data engineer— y que entiendan el
orden de las instrucciones, que es lo que separa un ciclo de desarrollo ágil
de uno insufrible.

**Guion:**

> ▶ **66** Hasta ahora habéis usado imágenes que ha hecho otro. Ahora vais a
> hacer la vuestra. Y quiero deciros desde el principio cuál es el caso real,
> que además lo pone la propia diapositiva: como data engineers **rara vez
> vais a escribir una imagen desde cero**. Lo que vais a hacer cada semana es
> **añadirle dependencias a una oficial**.
>
> ▶ **67** Un Dockerfile es un archivo de texto con instrucciones. Hay
> muchísimas; con estas siete construís casi todo lo que os van a pedir.
>
> **`FROM`** dice de qué imagen partís, y siempre es la primera línea.
> **`WORKDIR`** fija el directorio de trabajo, y lo crea si no existe.
> **`COPY`** copia archivos de vuestra máquina a la imagen. **`RUN`** ejecuta
> algo **durante el build** y guarda el resultado como capa: aquí es donde va
> vuestro `pip install`. **`ENV`** define una variable de entorno. **`USER`**
> cambia el usuario con el que se ejecuta lo siguiente, y guardad esa porque
> vuelve enseguida. Y **`CMD`** define el comando por defecto al arrancar,
> que **se puede sobrescribir**.
>
> Fijaos en la diferencia entre `RUN` y `CMD`, porque se confunden mucho:
> **`RUN` se ejecuta al construir; `CMD`, al arrancar**. `RUN` deja su
> resultado grabado dentro de la imagen. `CMD` solo dice qué pasará después.
>
> ▶ **68** El Dockerfile mínimo son cuatro líneas: partes de Alpine, fijas el
> directorio, copias un script y dices qué ejecutar. Y luego dos comandos:
> `docker build -t hello-docker .` y `docker run hello-docker`.
>
> Ese **punto final** no es decorativo, y hay una diapositiva entera dentro de
> un momento para él. De momento quedaos con que es "la carpeta que Docker
> envía al motor para construir".
>
> ▶ **69** Y este es el caso que más os va a tocar en la vida real. Tenéis
> Airflow corriendo, escribís un DAG que hace `import pandas`, y os peta con
> `ModuleNotFoundError`. Porque la imagen oficial de Airflow no trae pandas.
>
> Mirad la solución: tres líneas. `FROM apache/airflow`, un comentario, y un
> `RUN pip install`. Ya está: acabáis de crear "la imagen de Airflow **más**
> pandas".
>
> Dos detalles importantes. El primero, ese comentario del medio no está de
> adorno: la imagen de Airflow define `USER airflow`, y **`pip` se tiene que
> ejecutar como ese usuario**. Si os ponéis creativos y metéis un `USER root`
> ahí, Airflow luego no encontrará los paquetes. Es el fallo número uno de
> este ejercicio.
>
> Y el segundo, el error clásico del pie: instalarlo a mano con
> `docker exec ... pip install pandas`. Funciona... hasta que borráis el
> contenedor. Y entonces vuelve el `ModuleNotFoundError` y ya no os acordáis
> de qué instalasteis. Lo del Dockerfile es permanente y reproducible; lo
> otro es una nota mental que se pierde.
>
> ▶ **70** Y ahora la diapositiva que explica por qué a veces un build tarda
> dos segundos y otras cuatro minutos: **las capas y la caché**.
>
> Cada `RUN`, `COPY` y `ADD` crea una capa, y Docker cachea cada una. Mirad el
> ejemplo: cinco instrucciones, cinco capas. Si cambiáis `app.py`, las capas 1
> a 3 salen marcadas como `CACHED` y solo se rehacen la 4 y la 5. Si cambiáis
> la línea del `FROM`, **se rehacen todas**, porque todo lo demás cuelga de
> ella.
>
> De ahí la regla de oro, que es probablemente el consejo que más tiempo os va
> a ahorrar de todo el módulo: **lo que cambia poco va arriba; lo que cambia
> siempre, abajo.**
>
> Traducido: vuestras dependencias cambian una vez al mes; vuestro código
> cambia veinte veces al día. Si ponéis el `COPY` del código **antes** del
> `pip install`, cada vez que toquéis una coma invalidáis esa capa y Docker
> reinstala **todas** las dependencias desde cero. Cinco minutos por cada
> cambio. Si lo ponéis **después**, la capa del `pip install` se mantiene
> cacheada y el build tarda tres segundos.
>
> Es exactamente el mismo Dockerfile, las mismas instrucciones, solo cambiadas
> de orden.
>
> ▶ **71** Y volvemos al punto del `docker build .`, que merece su propia
> diapositiva porque muerde de dos formas.
>
> Mirad la izquierda: `Sending build context to Docker daemon 2.4GB`. Ese
> mensaje significa que Docker acaba de empaquetar y enviar **vuestra carpeta
> entera**: el `.git`, el `venv/`, los CSV de pruebas, el `data/` completo. Y
> lo hace **aunque el Dockerfile no copie nada de eso**. En un proyecto de
> datos, donde tenéis parquets de prueba por todas partes, esto es la
> diferencia entre un build de 3 segundos y uno de 4 minutos.
>
> La solución es un `.dockerignore`, que funciona exactamente igual que un
> `.gitignore`. Y con él, el mismo build pasa a enviar 480 kilobytes.
>
> Pero fijaos en el aviso del pie, porque **el segundo motivo es el que de
> verdad importa**: no meter vuestro `.env` dentro de la imagen el día que
> alguien añada un `COPY . .` al Dockerfile. Ese día, vuestras credenciales de
> base de datos viajan dentro de la imagen, y esa imagen se sube a un registry
> donde la puede descargar cualquiera que tenga acceso. Poned `.env` en el
> `.dockerignore` desde el minuto cero.
>
> ▶ **72–73** Con esto tenéis los ejercicios 4 y 5. El 4 es el "hola mundo":
> de un script suelto a una imagen. Y prestad atención a la pregunta para
> pensar: cambiad el `echo`, reconstruid, y mirad **qué capas dicen `CACHED`**.
> Ahí veis la teoría de la diapositiva 70 con vuestros propios ojos.
>
> El 5 es, con diferencia, el más parecido a vuestro trabajo real: añadir
> pandas a Airflow, y luego pasarlo a un `requirements.txt`. Y la pregunta
> para pensar es buena: **¿por qué `--no-cache-dir`?** Os la dejo ahí. Pista:
> tiene que ver con el tamaño final de la imagen y con que la caché de pip no
> os sirve absolutamente de nada dentro de una capa inmutable.
>
> ▶ **74** Un apunte que os va a resolver una duda en cuanto abráis nuestro
> proyecto: `CMD` **se puede sobrescribir** al arrancar. Por eso los servicios
> de Airflow del `docker-compose.yml` usan **exactamente la misma imagen** y
> lo único que los distingue es el `command:`: uno dice `scheduler`, otro
> `api-server`, otro `dag-processor`. Misma imagen, comportamientos distintos.
>
> Y de la columna derecha, un concepto que confunde: existe también
> `ENTRYPOINT`, que define un comando **fijo** al que se le añaden argumentos
> automáticamente. Tanto la imagen de Postgres como la de Airflow lo
> configuran por dentro, y por eso vosotros solo escribís el subcomando final
> —`scheduler`— y no el comando entero. Si alguna vez os preguntáis por qué
> ahí no pone `airflow scheduler`, es por esto.
>
> ▶ **75–76** Y cerramos con dos ajustes pequeños de consecuencias grandes.
>
> **`restart`** decide qué hace Docker si el proceso principal termina. El
> valor que usamos es `unless-stopped`: reinicia siempre salvo que lo paréis
> vosotros. Y `no`, el valor por defecto, es el correcto para tareas de un
> solo uso como `airflow-init`, que hace su trabajo y se muere a propósito.
>
> **`healthcheck`** es un comando periódico que decide si el contenedor está
> **listo**, no solo arrancado. Y esa distinción, que suena a sutileza, es la
> que os va a evitar el error más confuso de la sesión 2: sin healthcheck,
> Airflow intenta conectarse a una base de datos que **todavía se está
> inicializando** y falla con un mensaje incomprensible. "El proceso de
> Postgres existe" y "Postgres acepta conexiones" pueden llevarse veinte
> segundos de diferencia.
>
> ▶ **77–78** Y esto es lo que os lleváis de la sesión 1, cinco frases:
> imagen es plantilla y contenedor es instancia; `stop` no borra, solo `rm`
> borra; los datos van en volúmenes —con nombre para bases de datos, bind
> mount para vuestro código—; `-p` abre el puente y `EXPOSE` solo documenta; y
> `FROM` oficial más `RUN pip install` es el 90 % de los Dockerfiles que
> escribiréis.
>
> En la sesión 2 pasamos de levantar **un** contenedor a levantar **cinco que
> se hablan entre sí**. Antes de venir, mirad los vídeos 6 y 7, y dejad el
> entorno limpio: `docker ps -a` para ver qué tenéis abandonado por ahí y
> `docker system df` para ver cuánto disco os está costando.

**Puntos clave a remarcar en cámara:**
- El caso real del DE: **extender** una imagen oficial, no construir desde cero.
- `RUN` = al construir. `CMD` = al arrancar, y es sobrescribible (de ahí los 5 servicios de Airflow).
- En Airflow, `pip` debe correr como `USER airflow`. Fallo nº 1 del ejercicio 5.
- Capas y caché: lo estable arriba, lo volátil abajo. Dependencias antes que código.
- El `.` es el contexto de build. `.dockerignore` por velocidad **y por seguridad** (`.env`).
- `restart: unless-stopped` para servicios; `no` para tareas de un solo uso.
- Healthcheck = "listo", no "arrancado". Gancho directo al vídeo 7.

**Demo en pantalla (muy recomendada):** construir dos veces la misma imagen
cambiando una línea de código, con el `COPY` mal colocado y bien colocado, y
enseñar los tiempos con un cronómetro. Convence infinitamente más que
explicarlo.

---

## Vídeo 6 — Compose: varios servicios que se hablan (12 min)

**Diapositivas:** 79 a 102
**Teoría:** TEORIA.md §7, §8 y §9
**Desbloquea:** ejercicios 6, 7, 8 y 9

**Objetivo:** que sepan leer y escribir un `docker-compose.yml` y que
entiendan el DNS interno, que es lo que más "magia" parece y lo que menos
magia tiene.

**Guion:**

> ▶ **79–81** Bienvenidos a la sesión 2. Ya sabéis levantar **un** contenedor.
> Hoy tenéis que levantar **cinco que se hablen entre sí**, que es lo que
> realmente es una aplicación de datos.
>
> ▶ **83–84** Porque una aplicación real nunca es un contenedor: es Airflow
> **más** una base de datos, **más** un procesador de DAGs, **más** un
> servidor de API. Cinco o seis procesos que tienen que arrancar en orden,
> compartir red y conocerse entre sí.
>
> Podríais hacerlo con seis `docker run` escritos a mano, cada uno con sus
> quince flags. Y funcionaría... hasta que cerráis el portátil y al día
> siguiente no os acordáis de los flags. O hasta que se lo pasáis a un
> compañero y descubrís que los flags que os funcionaban a vosotros no eran
> exactamente los que le disteis.
>
> ▶ **85** Compose resuelve eso, y quiero que veáis esta diapositiva con
> calma porque desactiva la sensación de "empezamos de cero otra vez": **cada
> `service:` del YAML es, literalmente, un `docker run` traducido**. Lo que
> era `-p` ahora es `ports:`. Lo que era `-v` ahora es `volumes:`. Lo que era
> `-e` ahora es `environment:`. Lo que era `--name` es el nombre del servicio.
>
> No hay ni un concepto nuevo. Es la misma información, mejor guardada: en un
> archivo que se versiona en Git junto al código.
>
> ▶ **86** Los comandos son seis y los vais a usar todos los días.
> `docker compose up -d` levanta todo en segundo plano. `ps` os dice cómo está
> cada servicio. `logs -f <servicio>` os da los logs de uno concreto. `exec`
> os mete dentro. `build` reconstruye. Y `down` para y borra los contenedores.
>
> Ojo con una variante que sale más adelante y que quiero adelantar ya:
> **`docker compose down -v`** borra además los volúmenes con nombre. Es
> decir, **vuestros datos**. Es el comando que queréis cuando algo está
> corrupto y queréis empezar de cero, y el que **no** queréis ejecutar por
> inercia un viernes por la tarde.
>
> ▶ **87** El ejercicio 6 es exactamente esa traducción: coger un
> `docker run` que ya habéis escrito y pasarlo a Compose.
>
> ▶ **88–89** Y ahora lo mejor de Compose, que es lo que más impresiona
> cuando se entiende. Al hacer `docker compose up`, Compose **crea
> automáticamente una red privada** para vuestro proyecto y conecta todos los
> servicios a ella. Dentro de esa red, **cada servicio es alcanzable por los
> demás usando su nombre de servicio como si fuera un nombre de dominio**.
>
> ▶ **90** Y esta es la línea que hay que entender. Si vuestro servicio se
> llama `postgres` en el YAML, desde el contenedor de Airflow la cadena de
> conexión es, literalmente,
> `postgresql://usuario:clave@postgres:5432/basededatos`. Ahí donde iría una
> IP, ponéis `postgres`. Compose levanta un DNS interno y lo resuelve solo.
>
> Y esto no es una comodidad estética: **elimina el problema de las IPs**. Los
> contenedores cambian de IP cada vez que se recrean; los nombres, no. Regla
> para toda vuestra carrera: **nunca escribáis una IP en una cadena de
> conexión.** Guardadla, porque en la sesión 3 os la voy a repetir tal cual
> cuando hablemos de Services.
>
> ▶ **91** Y enlazando con el vídeo 3: **por eso Postgres no necesita publicar
> el puerto 5432**. Airflow le habla por la red interna. En nuestro proyecto
> solo publicamos el 8080 del servidor web, que es el único al que queremos
> llegar desde el navegador. Todo lo demás se queda dentro.
>
> Y eso, además de cómodo, es más seguro: **lo que no está publicado no es
> atacable desde fuera**. Cuando en una revisión de código veáis un
> `ports:` en la base de datos, preguntad por qué está ahí. Nueve de cada diez
> veces es un resto de cuando alguien depuraba.
>
> ▶ **92–93** El ejercicio 7 va de eso, y el experimento que viene después es
> mi favorito: **romper la conexión a propósito**. Cambiáis el hostname
> `postgres` por otra cosa y veis exactamente qué error da. Porque el día que
> os salga ese error en el trabajo —y os va a salir— lo vais a reconocer en
> tres segundos en vez de en tres horas.
>
> ▶ **94–95** Los volúmenes en Compose son los mismos dos tipos del vídeo 3,
> solo que en sintaxis YAML: los **bind mount** con una ruta relativa
> (`./dags:/opt/airflow/dags`) y los **volúmenes con nombre**, que además hay
> que declarar en la sección `volumes:` de nivel superior. Si os olvidáis de
> declararlos ahí abajo, Compose se queja; es un error de los buenos, porque
> te lo dice.
>
> ▶ **96** Y aquí la trampa favorita de cualquier examen de Docker:
> **`down` y `down -v` no son lo mismo**. `down` para y borra los
> contenedores, pero **respeta los volúmenes con nombre**. `down -v` los
> borra. Es la diferencia entre reiniciar el servidor y prenderle fuego.
>
> ▶ **97** El ejercicio 8 es montar vuestros DAGs por bind mount y comprobar
> que aparecen en Airflow sin reconstruir nada.
>
> ▶ **98–99** Y ahora abrimos el stack real. Fijaos en algo que ya os
> adelanté en el vídeo 5: aquí hay **cuatro procesos usando exactamente la
> misma imagen**, y lo único que los diferencia es el `command:`. Uno es el
> `api-server`, otro el `scheduler`, otro el `dag-processor`. Misma imagen,
> comportamientos distintos.
>
> ▶ **100** Y hay un quinto contenedor especial, `airflow-init`, que es **de
> un solo uso**: arranca, crea las tablas de la base de datos, y **termina**.
> Y no está roto. Acordaos del vídeo 2: un contenedor que termina ha hecho su
> trabajo. Guardad también esta idea, porque en Kubernetes tiene nombre
> propio y se llama Job.
>
> ▶ **101–102** El ejercicio 9 es pasar de un Airflow `standalone` a esta
> arquitectura real. Y el experimento de después es matar el DAG Processor a
> mano y ver qué pasa. Sin `restart:`, se queda muerto. Y eso —quién repone
> lo que se ha caído— es justo la pregunta con la que abriremos la sesión 3.

**Puntos clave a remarcar en cámara:**
- Compose = los mismos conceptos, en un archivo versionable. `-p`→`ports:`, `-v`→`volumes:`, `-e`→`environment:`.
- **DNS interno**: el nombre del servicio ES el hostname. **Nunca uses IPs.** (Se repite en la sesión 3.)
- Solo se publica al host lo que se necesita desde el navegador. Lo no publicado no es atacable.
- `down` conserva los volúmenes; `down -v` los borra. Avisar dos veces.
- 4 servicios, 1 imagen, distinto `command:` → el `CMD` sobrescribible del vídeo 5.
- `airflow-init` termina **a propósito**. Gancho hacia Job en Kubernetes.

---

## Vídeo 7 — Arranque robusto y el stack real de Airflow (10 min)

**Diapositivas:** 103 a 116
**Teoría:** TEORIA.md §10 y §11
**Desbloquea:** ejercicio 10

**Objetivo:** cerrar el bloque de Docker enseñándoles que el proyecto real
que van a tocar en clase no tiene **nada** que no hayan visto ya.

**Guion:**

> ▶ **103–104** Nos queda la pieza que más errores causa en un stack de
> datos, y es esta: **`depends_on` a secas no espera lo que creéis**.
>
> Por defecto, `depends_on` solo espera a que el contenedor **exista y haya
> arrancado**. No espera a que el proceso de dentro esté **listo**. Y para una
> base de datos esa diferencia son veinte segundos largos: Postgres arranca,
> empieza a inicializar su directorio de datos, y durante ese rato **no acepta
> conexiones**. Mientras tanto, Airflow ya se ha lanzado, ha intentado
> conectar, ha fallado y se ha muerto.
>
> El resultado es un error incomprensible en un servicio que no tiene la
> culpa. Es, literalmente, el fallo número uno al montar un stack de datos con
> Compose.
>
> ▶ **105** Y la solución son **dos piezas que encajan**, no una: el
> **healthcheck** del servicio del que dependes —que vimos en el vídeo 5— más
> el `depends_on` **con condición**. Una sin la otra no sirve de nada: si
> ponéis la condición pero el servicio no tiene healthcheck, Compose no tiene
> nada que consultar.
>
> ▶ **106** Las tres condiciones posibles: `service_started` es el
> comportamiento por defecto, el que no espera nada útil.
> **`service_healthy`** es el que queréis el 90 % de las veces: espera a que
> el healthcheck pase. Y `service_completed_successfully` espera a que un
> contenedor **termine bien**, que es justo lo que necesitáis para
> `airflow-init`: primero se crean las tablas, y solo cuando eso ha terminado
> con éxito arranca el resto.
>
> ▶ **107** Dos mejoras de higiene que separan un YAML de juguete de uno
> profesional. La primera: el **`.env`**.
>
> Todo lo que cambia por persona o por entorno **no va en el archivo
> versionado**. Va en un `.env` que Compose lee automáticamente. Y fijaos en
> la sintaxis, que es muy útil: `${VARIABLE:-valor_por_defecto}` significa
> "usa la variable, y si no existe, este valor". Así el proyecto funciona
> aunque alguien no tenga `.env`, pero cada uno puede cambiar su puerto sin
> tocar el YAML compartido.
>
> Y la frase del pie es la importante: **el `.env` no se sube a Git**. Por eso
> el YAML sí se puede subir sin exponer credenciales. Ponedlo en el
> `.gitignore` el mismo día que creáis el proyecto, no después.
>
> ▶ **108** La segunda: las **anclas YAML**. Y quiero aclarar algo que
> confunde: esto **no es de Compose**, es del propio formato YAML.
>
> Definís una plantilla con `&nombre` —aquí `x-airflow-common`— y luego la
> "pegáis" en cada servicio con `<<: *nombre`. Así los cuatro servicios de
> Airflow comparten imagen, variables de entorno y volúmenes sin repetirlos
> cuatro veces. Y cuando haya que cambiar la cadena de conexión, se cambia en
> **un** sitio, no en cuatro. Que es exactamente el mismo motivo por el que no
> copiáis y pegáis código.
>
> ▶ **109–110** El ejercicio 10 junta las dos cosas: arranque robusto y
> configuración limpia.
>
> ▶ **111–112** Y ahora el momento que cierra la sesión. Abrimos el
> `docker-compose.yml` **real** del proyecto, ese que a primera vista intimida
> porque son cien líneas de YAML, y mirad lo que hay dentro:
>
> Imágenes **con versión fijada** — vídeo 4. El **`CMD` sobrescrito** con
> `command: scheduler` — vídeo 5. **Healthcheck y `restart`** — vídeo 5.
> **Bind mounts** de `./dags`, `./logs` y `./plugins` — vídeo 3. Un **volumen
> con nombre**, `postgres_data` — vídeo 3. La **red y el DNS de Compose**, con
> Airflow conectándose a `postgres` por nombre — vídeo 6. **`depends_on` con
> condiciones** — hace dos minutos. El **`.env` y las anclas YAML** — hace un
> minuto. Y la **publicación de puertos** en `127.0.0.1:8080` — vídeo 3.
>
> No hay ni una sola línea ahí que no hayáis visto ya. Y ese es exactamente el
> punto: **un stack de datos de producción no es Docker avanzado, es Docker
> básico bien combinado.** La complejidad está en el dominio —Airflow,
> Postgres, la cola de tareas—, no en la contenedorización.
>
> ▶ **113** Y para que no os quedéis con la idea de que esto va de Airflow:
> hoy hemos usado Airflow como excusa. Mirad la tabla. Si mañana levantáis
> **Kafka**, son un broker, un controlador y una UI, y la pieza que os va a
> doler son los *listeners*. Si levantáis **Spark**, un master y varios
> workers, y lo que duele son los puertos del driver y la memoria. Si
> levantáis **dbt**, dbt más el warehouse, y lo que duele es el
> `profiles.yml` montado como bind mount.
>
> Cambian los nombres de los servicios y las variables de entorno. **No cambia
> nada más**: sigue siendo un `services:`, una red implícita, unos volúmenes y
> un `depends_on` con condiciones.
>
> ▶ **114–115** Repasad las preguntas de la 114 antes de la clase; si las
> cuatro os salen sin dudar, vais sobrados. Y por favor, haced la limpieza de
> la 115: `docker compose down`, mirad qué tenéis con `docker ps -a` y
> comprobad el disco con `docker system df`. Minikube va a necesitar 4 gigas
> de RAM en la sesión 3, y vuestro portátil os lo va a agradecer.
>
> ▶ **116** Y en la sesión 3 respondemos a la pregunta que dejamos abierta:
> vale, ya sé levantar cinco contenedores que se hablan **en mi portátil**.
> ¿Y quién los levanta cuando el servidor se reinicia a las tres de la
> mañana? Ahí empieza Kubernetes.

**Puntos clave a remarcar en cámara:**
- `depends_on` a secas **no** espera a que esté listo. Son **dos piezas**: healthcheck + `condition:`.
- `service_completed_successfully` es la condición para `airflow-init`.
- `.env` fuera de Git, con `${VAR:-defecto}`. Las anclas YAML son de YAML, no de Compose.
- El recorrido del `docker-compose.yml` real es **el momento "ah, vale"** del bloque: ir señalando cada línea y decir de qué vídeo sale.
- Un stack de producción no es Docker avanzado: es Docker básico bien combinado.
- El patrón es idéntico en Kafka, Spark o dbt. Cambian los nombres, no los conceptos.

**Demo en pantalla (imprescindible en este vídeo):** abrir el
`docker-compose.yml` real del repositorio y recorrerlo de arriba abajo
señalando cada concepto con el cursor. Es el vídeo que más cohesiona el
bloque de Docker.

---

# BLOQUE B — KUBERNETES

> **Nota de grabación:** este bloque es más denso y los alumnos llegan con
> menos contexto previo. Dos decisiones que ayudan mucho: (1) apoyarte
> **siempre** en la equivalencia con Compose, que es el andamio que ya tienen
> montado; y (2) no vender Kubernetes como "lo siguiente que sustituye a
> Docker". Se dice explícitamente en varias diapositivas y conviene repetirlo:
> seguirán usando Compose todos los días.

## Vídeo 8 — Por qué Kubernetes: de dar órdenes a describir un estado (10 min)

**Diapositivas:** 117 a 126
**Teoría:** TEORIA_KUBERNETES.md §1

**Objetivo:** que entiendan el salto conceptual **imperativo → declarativo**
antes de ver un solo comando. Si se llevan una sola idea del vídeo, que sea
el bucle de reconciliación.

**Guion:**

> ▶ **117–118** Sesión 3. Ya sabéis levantar contenedores sueltos y ya sabéis
> orquestar varios con Compose **en una máquina**. Hoy vemos qué pasa cuando
> hay muchas máquinas.
>
> Y antes de empezar, un aviso para que nadie se agobie: **Kubernetes no
> sustituye a Docker ni a Compose**. Vais a seguir usando Compose todos los
> días en vuestro portátil. Kubernetes es lo que corre **debajo** cuando
> vuestro pipeline sale a producción. Son capas, no sustituciones.
>
> ▶ **119–120** El objetivo de hoy es concreto: en dos horas y media vais a
> desplegar un pipeline completo sobre un cluster. Leer y escribir
> manifiestos, desplegar una app con un Deployment, exponerla con un Service,
> separar la configuración con ConfigMaps y Secrets, montar almacenamiento que
> sobreviva a la muerte de un Pod, y —el que de verdad os importa— programar
> un proceso por lotes con un CronJob.
>
> ▶ **121–122** ¿Qué es Kubernetes? Formalmente: un orquestador de código
> abierto para automatizar el despliegue, escalado y gestión de aplicaciones
> en contenedores. Lo creó Google en 2014 a partir de su sistema interno
> **Borg**, y lo donó a la CNCF.
>
> El ejemplo de la derecha es de manual: una tienda que recibe un pico de
> visitas a las ocho de la tarde. Sin Kubernetes, alguien levanta servidores a
> mano. Con Kubernetes, declaráis una política y ya está:
> `kubectl autoscale --cpu-percent=60 --min=2 --max=10`.
>
> Pero fijaos en el matiz del pie, que es el que os toca a vosotros: **en
> ingeniería de datos rara vez escalaréis por CPU**. Lo habitual es escalar
> por **longitud de cola**: "levántame más Pods si hay más de diez mil
> mensajes acumulados en Kafka". Es la misma idea, con otra métrica.
>
> ▶ **123** Y aquí están las cinco preguntas que vuestro `docker-compose.yml`
> **no** sabe responder. Leedlas conmigo, porque cada una es un objeto de
> Kubernetes que veremos hoy.
>
> Uno: el servidor se reinicia a las tres de la mañana. ¿Quién arranca los
> contenedores? Dos: Airflow se queda colgado —vivo pero sin responder—, y
> `docker ps` dice `Up` tan tranquilo. ¿Quién detecta que está roto? Tres:
> necesitáis diez workers en vez de dos por un pico nocturno... ¿y a las seis
> los apagáis a mano? Cuatro: tenéis veinte servidores, ¿quién decide en cuál
> cabe cada contenedor? Y cinco: queréis pasar de Airflow 3.3.1 a 3.3.2 **sin
> cortar el servicio**.
>
> La número dos es la que más me gusta, porque es la más traicionera: un
> proceso vivo pero colgado es peor que un proceso muerto. El muerto al menos
> se nota.
>
> ▶ **124** Esta tabla resume la respuesta a las cinco. Si un contenedor
> muere, Compose lo deja muerto —salvo `restart:`— y Kubernetes **lo repone**.
> Si la máquina entera muere, con Compose se cae todo y con Kubernetes los
> contenedores **se recolocan en otro nodo**. Escalar, actualizar sin
> downtime, detectar apps colgadas: todo eso está en la columna de la derecha.
>
> Y también está el precio, que es honesto: complejidad **baja** en Compose,
> **alta** en Kubernetes. Un archivo frente a muchos objetos. Por eso la
> última fila es la importante: Compose para desarrollo local, demos y CI;
> Kubernetes para producción y cargas serias.
>
> ▶ **125** Y ahora, si os lleváis **una sola cosa** de la sesión de hoy, que
> sea esta diapositiva.
>
> Docker es **imperativo**: `docker run -d --name web nginx` significa
> "arranca este contenedor **ahora**". Es una orden. Se ejecuta una vez. Y si
> alguien mata ese contenedor, se queda muerto: Docker hizo lo que le
> pedisteis y su trabajo terminó ahí.
>
> Kubernetes es **declarativo**: `replicas: 3` no significa "arranca tres
> contenedores". Significa **"quiero que siempre haya tres copias"**. Y ese
> "siempre" es literal: no se ejecuta una vez, **se comprueba constantemente**.
>
> Pasáis de dar órdenes a describir un estado. Todo lo demás del día de hoy es
> consecuencia de esto.
>
> ▶ **126** Y el mecanismo que hace real esa promesa es el **bucle de
> reconciliación**, que es el corazón del sistema y la razón de que los Pods
> "resuciten" solos.
>
> Kubernetes compara continuamente, cada pocos segundos, el **estado deseado**
> —vuestro YAML— con el **estado real** —lo que hay en el cluster—. Si no
> coinciden, actúa para corregirlo. Y vuelve a comparar. Para siempre.
>
> La analogía del termostato es perfecta y la vais a usar para explicárselo a
> otros: configuráis 22 grados —estado deseado—, la habitación está a 19
> —estado real—, el termostato detecta la diferencia y enciende la calefacción
> —reconcilia—. Al llegar a 22 se apaga, pero **no deja de vigilar**. Si
> abrís una ventana, vuelve a encenderse.
>
> Aplicado a Kubernetes: pedís tres réplicas, se crean tres. Un servidor se
> apaga de golpe y os quedáis con dos. En **milisegundos**, el bucle detecta
> la diferencia y ordena crear un Pod nuevo en otro nodo sano. Nadie os ha
> llamado por teléfono a las tres de la mañana.
>
> Eso es todo el concepto. El resto de la sesión son los objetos concretos que
> se apoyan en él.

**Puntos clave a remarcar en cámara:**
- Kubernetes **no sustituye** a Compose. Compose se sigue usando a diario. Repetirlo.
- Las cinco preguntas de la 123 son el guion completo de la sesión: cada una es un objeto.
- En datos se escala por **longitud de cola**, no por CPU. Es el matiz que los distingue de un perfil web.
- **Imperativo vs declarativo** es LA idea del día. `docker run` = orden. `replicas: 3` = promesa.
- Bucle de reconciliación = termostato. Vigila **siempre**, no una vez.
- Reconocer el coste: Kubernetes es más complejo. No venderlo como gratis.

---

## Vídeo 9 — Anatomía del cluster y del YAML (11 min)

**Diapositivas:** 127 a 141
**Teoría:** TEORIA_KUBERNETES.md §2 y §3
**Desbloquea:** bloque 0 (arrancar minikube)

**Objetivo:** que sepan **a quién culpar** cuando algo se atasca, y que
escriban su primer YAML sin morir en el intento. No hay que memorizar la
arquitectura; hay que saber leerla cuando falla.

**Guion:**

> ▶ **127–128** Antes de nada, arrancad el cluster, porque si algo va a
> fallar prefiero que falle ahora y no a mitad del ejercicio 1.
> `minikube start` con cuatro gigas y dos CPUs, `minikube status`, y
> `kubectl get nodes`.
>
> Y fijaos en el detalle simpático de la derecha: lanzad
> `kubectl get pods -n kube-system`. Ahí veréis corriendo `etcd`,
> `kube-apiserver`, `kube-scheduler`, `coredns`... **como Pods**. Es decir:
> **Kubernetes se ejecuta a sí mismo sobre Kubernetes**. Que es elegante y
> ligeramente recursivo, pero funciona.
>
> El checkpoint es simple: `kubectl get nodes` os muestra un nodo en `Ready`.
> Si no, paramos ahí.
>
> ▶ **129–131** Y esta es la arquitectura. Os aviso de entrada: **no hay que
> memorizarla**. Lo que sí hay que saber es a quién culpar cuando algo se
> atasca.
>
> El **control plane** es el cerebro y tiene cuatro piezas. El **API server**
> es la única puerta de entrada: `kubectl` habla con él por HTTPS, y nadie
> accede a nada más directamente. **etcd** es una base de datos clave-valor
> con todo el estado del cluster; si se pierde etcd, el cluster pierde la
> memoria. El **scheduler** decide en qué nodo cabe cada Pod nuevo según CPU y
> memoria. Y el **controller manager** es el que ejecuta esos bucles de
> reconciliación del vídeo anterior: es quien hace real la promesa.
>
> Los **nodos worker** son el músculo. En cada uno hay un **kubelet**, que es
> el agente que pregunta al API server qué le toca correr; un **container
> runtime**, que hoy suele ser **containerd** —acordaos del módulo 0:
> Kubernetes dejó de usar Docker como motor en 2022—; y **kube-proxy**, que
> programa las reglas de red.
>
> Y el ciclo de la derecha es lo que pasa **de verdad** cuando hacéis
> `kubectl apply`. Seis pasos: kubectl envía el YAML al API server; el API
> server lo valida y lo guarda en etcd; el controller manager detecta que
> faltan Pods y los crea; el scheduler asigna cada Pod a un nodo con hueco; el
> kubelet de ese nodo se entera y llama a containerd; y containerd descarga la
> imagen y arranca el contenedor.
>
> ¿Para qué sirve saber esto? Para el tip de diagnóstico del pie, que es lo
> único que os pido que retengáis: **un Pod atascado en `Pending` para siempre
> significa que el scheduler no encuentra sitio**. Falta CPU o memoria. Ya
> sabéis a quién culpar sin mirar nada más.
>
> ▶ **132** Nodos y namespaces, que se confunden y no tienen nada que ver.
>
> Un **nodo** es una división **física**: una máquina de verdad, con su CPU y
> su RAM. Y vosotros **no elegís** en cuál cae vuestro Pod: lo decide el
> scheduler según lo que pidáis en `resources`. En minikube hay uno; en
> producción, decenas.
>
> Un **namespace** es una división **lógica**: una carpeta, no una máquina.
> `dev` y `prod` conviven en los mismos nodos físicos sin colisionar. Dos
> Services llamados `postgres` pueden existir a la vez si están en namespaces
> distintos.
>
> Y guardad el aviso del pie, que es el que muerde: **el namespace va dentro
> del DNS**. Dentro de vuestro namespace, `postgres` funciona a secas. Desde
> otro, tendríais que escribir `postgres.produccion.svc.cluster.local`. La
> primera vez que alguien mueve un pipeline de `dev` a `prod` y no le
> funciona, suele ser por esto.
>
> ▶ **133–134** Vamos al YAML. Y aquí hay una buena noticia: **todo en
> Kubernetes se describe con la misma estructura de cuatro campos**. Da igual
> que sea un Pod, un Service o un CronJob. Aprendedla una vez y ya está.
>
> `apiVersion` dice qué versión de la API define este tipo de objeto. `kind`
> dice **qué** es. `metadata` dice cómo se llama y cómo se etiqueta. Y `spec`
> dice **qué queréis que exista**: el estado deseado.
>
> La tablita de abajo os ahorra búsquedas: `v1` para Pod, Service, ConfigMap,
> Secret y PVC. `apps/v1` para Deployment. `batch/v1` para Job y CronJob. Es
> de las pocas cosas que conviene tener a mano en una nota.
>
> ▶ **135** Y ahora una advertencia sincera: **hoy vais a perder más tiempo
> con espacios que con Kubernetes**.
>
> Tres reglas. Espacios, **nunca** tabuladores; un tab es un error de sintaxis
> y punto. La indentación **es** la estructura: dos espacios de más y el campo
> cuelga de otro sitio. Y el guion abre un elemento de lista: `containers:`
> lleva lista, `metadata:` no.
>
> Dos comandos que os van a salvar. `kubectl apply --dry-run=client` os dice
> si es válido **sin aplicarlo**. Y `kubectl get pod mi-app -o yaml` os enseña
> **cómo lo ha entendido el cluster**, que a veces no es lo que vosotros
> creíais escribir.
>
> Y el aviso del pie, que es de los que se agradecen: cuando veáis
> `error validating data: unknown field ...`, casi nunca significa que el
> campo no exista. Significa que **está colgando del sitio equivocado**.
> Buscad la indentación, no el nombre.
>
> Ah, y configurad vuestro editor: dos espacios por tabulador, y que muestre
> los espacios en blanco. Cinco minutos de configuración, horas de sufrimiento
> ahorradas.
>
> ▶ **136** Y esta diapositiva explica el mecanismo más importante y más
> silencioso de Kubernetes: **labels y selectors**. Los objetos **no se
> referencian por nombre**, se referencian por **etiqueta**.
>
> El Deployment dice "yo gestiono los Pods con la etiqueta `app=mi-app`". El
> Service dice "yo mando tráfico a los Pods con la etiqueta `app=mi-app`". Y
> los Pods, por su parte, llevan esa etiqueta puesta. Nadie se conoce por
> nombre; se conocen por etiqueta.
>
> Y de ahí sale la **causa número uno** de "mi Service no funciona": el
> selector no coincide con las labels. Una letra de más y el Service se queda
> sin endpoints... **en silencio**. Sin error, sin aviso, sin nada. Simplemente
> deja de funcionar. Anotadlo, porque en el ejercicio 2 lo vais a provocar a
> propósito.
>
> ▶ **137–141** Y cierro con las cuatro diapositivas de jerarquía, que os
> recomiendo leer con calma porque ordenan todo el vocabulario.
>
> La idea es que hay **dos planos**. El **físico**: el cluster es el colegio
> entero, y los nodos son las aulas de verdad, con sus paredes, su CPU y su
> RAM. Y el **lógico**, que flota por encima: namespaces, deployments, pods,
> contenedores.
>
> Y lo importante es que **el namespace es transversal**: no pertenece a un
> nodo. Fijaos en la diapositiva 141: el namespace `desarrollo` y el namespace
> `produccion` tienen Pods repartidos por los mismos nodos físicos.
>
> El impacto para vosotros está escrito en la 138 y es muy concreto: si
> desplegáis un pipeline de Spark en un namespace, **vuestros procesos se
> distribuyen en paralelo entre múltiples nodos físicos** sin que vosotros
> decidáis nada. La lógica de software gobierna la infraestructura física de
> forma transparente. Que es, en el fondo, todo lo que os están vendiendo
> cuando os dicen "cloud native".
>
> Y de la 140, quedaos con la tolerancia a fallos: si un nodo físico se queda
> sin red o sin luz, el cluster detecta que no responde y **reprograma
> automáticamente todos sus Pods** en los nodos restantes que tengan
> capacidad. Otra vez el bucle de reconciliación, ahora a escala de máquina.

**Puntos clave a remarcar en cámara:**
- **No hay que memorizar** la arquitectura. Hay que saber a quién culpar.
- `kube-system`: Kubernetes corre sobre sí mismo. Buen momento para un gag corto.
- `Pending` para siempre = el scheduler no encuentra sitio (CPU/memoria).
- Nodo = físico (no eliges). Namespace = lógico (una carpeta). El namespace va **dentro del DNS**.
- Cuatro campos: `apiVersion`, `kind`, `metadata`, `spec`. Siempre los mismos.
- `unknown field` = **indentación**, no nombre. Y `--dry-run=client` antes de aplicar.
- Labels y selectors: se referencian por **etiqueta**, no por nombre. Un typo rompe el Service **en silencio**.

---

## Vídeo 10 — Pod, Deployment y self-healing (10 min)

**Diapositivas:** 142 a 146
**Teoría:** TEORIA_KUBERNETES.md §4
**Desbloquea:** ejercicio 1

**Objetivo:** que entiendan que la unidad es el **Pod**, no el contenedor,
que **nunca** se usan Pods sueltos, y que se lleven ya el aviso de
"servicios frente a tareas" que se desarrolla en el vídeo 14.

**Guion:**

> ▶ **142** Primera sorpresa del día: en Docker la unidad que ejecutáis es el
> **contenedor**. En Kubernetes es el **Pod**.
>
> ¿Y qué es un Pod? Un envoltorio que contiene **uno o más contenedores** que
> comparten dos cosas: la **red** —tienen la misma IP y se ven entre sí por
> `localhost`— y el **almacenamiento**.
>
> Antes de que os agobiéis con el patrón sidecar: **en el 95 % de los casos
> tendréis un solo contenedor por Pod**. El sidecar existe para procesos de
> soporte —un recolector de logs, un proxy—, pero no es vuestro caso de uso
> habitual. Guardadlo como cultura general.
>
> Y ahora la frase importante del pie, que es la que quiero que os llevéis:
> **nunca creéis Pods sueltos**. Si mueren, nadie los repone. Es el
> equivalente exacto a hacer `docker run` sin `--restart`. Y lo vais a
> comprobar vosotros mismos en el ejercicio 1.
>
> ▶ **143** Entonces, ¿qué usáis? Un **Deployment**. Y mirad la cadena, porque
> son tres objetos en fila: el **Deployment** crea y gestiona un
> **ReplicaSet**, y el ReplicaSet mantiene los **Pods**.
>
> El ReplicaSet es quien garantiza que en todo momento existan N Pods con unas
> etiquetas dadas. Si uno muere, crea otro. Es, literalmente, **el bucle de
> reconciliación aplicado al recuento de Pods**.
>
> ¿Y para qué está el Deployment por encima, si el ReplicaSet ya hace eso?
> Para las **actualizaciones**. Cuando cambiáis la versión de la imagen, el
> Deployment crea un ReplicaSet **nuevo** y vacía el viejo poco a poco, sin
> cortar el servicio. Eso es el *rolling update*, y es la respuesta a la
> pregunta 5 de la diapositiva 123.
>
> Tranquilidad con el ReplicaSet: **no lo vais a escribir nunca a mano**. Lo
> gestiona el Deployment de forma transparente. Solo tenéis que saber que
> existe para cuando aparezca en un `kubectl get all` y no os asustéis.
>
> ▶ **144** Y ahora una diapositiva que va dedicada específicamente a
> vosotros, porque es **el punto ciego de nuestro perfil**: servicios frente a
> tareas.
>
> No todo corre para siempre. Los procesos de datos, de hecho, casi nunca
> corren para siempre: nacen, ejecutan una acción pesada, y **mueren con
> éxito**. Eso es un ETL.
>
> Tres objetos, tres propósitos. **Deployment** para cosas que no deben morir
> nunca: una API, un dashboard, la UI de Airflow. **Job** para ejecutar un
> script finito. Y **CronJob** para ejecuciones recurrentes: `0 3 * * *` para
> la extracción de cada madrugada.
>
> Y aquí el error clásico, que quiero que se os quede grabado desde ya aunque
> lo desarrollemos en el vídeo 14: **si metéis una ETL en un Deployment, el
> proceso termina correctamente, Kubernetes interpreta que se ha caído, y lo
> reinicia. Y otra vez. Y otra vez.** Vuestra carga de datos se ejecuta en
> bucle toda la noche.
>
> Y lo verdaderamente perverso está en la última línea: **en el panel de
> control todo parece correcto**, porque el Pod aparece en estado `Running`.
> Nadie salta. Vosotros os enteráis al día siguiente, cuando veis que la tabla
> tiene doscientas mil filas duplicadas... o cuando llega la factura de la
> nube.
>
> ▶ **145** Este es un Deployment mínimo, y quiero que os fijéis en lo que la
> diapositiva llama **la estructura de muñeca rusa**, porque es lo que más
> cuesta al principio.
>
> El `spec` del Deployment tiene un `template`, que es **una plantilla de
> Pod**. Y esa plantilla tiene **su propio** `metadata` y **su propio** `spec`.
> Es decir: hay un `spec` dentro de otro `spec`. No está mal escrito; es así.
>
> Y la línea con el comentario en mayúsculas es la que os va a romper el
> despliegue: las `labels` del template **deben coincidir** con el
> `selector.matchLabels` de arriba. Si no coinciden, el Deployment crea Pods
> que luego no reconoce como suyos, y se queda en un bucle bastante triste.
> Es la aplicación directa de la diapositiva 136.
>
> ▶ **146** Y con esto, el ejercicio 1, que es el que hace clic. Escribís dos
> manifiestos. En el primero, un **Pod suelto**: lo aplicáis, lo borráis, y
> `kubectl get pods` no muestra nada. Nadie lo repone. En el segundo, un
> **Deployment con tres réplicas**: borráis un Pod y **en segundos aparece uno
> nuevo**, con otro nombre.
>
> Acabáis de ver el bucle de reconciliación con vuestros propios ojos.
>
> Y haced caso al aviso del pie: **los manifiestos los tecleáis vosotros**.
> Están resueltos en el enunciado, sí, pero copiar y pegar no fija nada.
> Escribirlos —y pelearos con la indentación— es lo que hace que se queden.

**Puntos clave a remarcar en cámara:**
- La unidad es el **Pod**, no el contenedor. Comparten IP y almacenamiento.
- 95 % de los casos: **un contenedor por Pod**. El sidecar es cultura general.
- **Nunca Pods sueltos.** = `docker run` sin `--restart`.
- Deployment → ReplicaSet → Pods. El ReplicaSet no se escribe a mano.
- El Deployment aporta el **rolling update**.
- **Servicios vs tareas**: una ETL en un Deployment = bucle infinito, y el panel dice `Running`. Sembrar aquí, cosechar en el vídeo 14.
- Muñeca rusa: `spec` dentro de `spec`. Y las labels del template **deben** coincidir con el selector.

---

## Vídeo 11 — Services: la IP estable que tu pipeline necesita (10 min)

**Diapositivas:** 147 a 153
**Teoría:** TEORIA_KUBERNETES.md §5
**Desbloquea:** ejercicio 2

**Objetivo:** que vean que un Service es exactamente el DNS de Compose que ya
conocen, y que sepan diagnosticar el fallo silencioso del selector.

**Guion:**

> ▶ **147–148** Los Pods son efímeros y cambian de IP. Necesitáis algo estable
> a lo que apuntar, y eso es un **Service**.
>
> Mirad la columna de la derecha, porque es literalmente una historia de
> terror para nuestro perfil, en cuatro pasos. Uno: conectáis vuestro pipeline
> directamente a la IP del Pod, `10.244.1.5`. Dos: el Pod muere de madrugada
> por un pico de carga. Tres: Kubernetes lo levanta otra vez, pero en otra IP,
> `10.244.2.18`. Y cuatro: por la mañana vuestro pipeline lleva horas fallando
> contra una IP que ya no existe.
>
> Con un Service, no. El Service tiene una **IP estática** y un **nombre DNS
> estable**, y balancea el tráfico hacia todos los Pods que lleven la etiqueta
> correcta. Vuestro pipeline apunta al Service, y si un Pod de base de datos
> muere, vuestro flujo **ni se entera**.
>
> ▶ **149** Y aquí está la continuidad con la sesión 2, que quiero que veáis
> porque es deliberada. Mirad las dos líneas: en Docker Compose escribíais
> `postgresql://usuario@postgres:5432/db`. En Kubernetes escribís...
> exactamente lo mismo. La única diferencia es que ahí `postgres` ya no es el
> nombre de un servicio de Compose, sino el nombre de un **Service** de
> Kubernetes.
>
> Dentro del cluster, el nombre del Service funciona como hostname. **Si
> entendisteis la red de Compose, ya entendéis los Services.** Y os prometí en
> el vídeo 6 que os repetiría lo de no escribir IPs: pues ya está repetido.
>
> ▶ **150** Tres tipos de Service, y os digo desde ya cuál vais a usar.
>
> **ClusterIP**, que es el de por defecto: solo accesible dentro del cluster.
> Vuestra app hablando con vuestra base de datos. **El 90 % de los casos.**
>
> **NodePort** abre un puerto fijo en el rango 30000–32767 en todos los nodos.
> Sirve para pruebas y clusters locales: ver temporalmente la UI de Spark o el
> dashboard de Ray.
>
> **LoadBalancer** le pide un balanceador de verdad al proveedor cloud. En
> datos lo veréis en puntos de entrada masiva: recibir un flujo de eventos
> desde un Kafka externo, por ejemplo.
>
> Y una cuarta pieza que no es un Service pero que os va a sonar: el
> **Ingress**, que enruta tráfico HTTP según el dominio o la ruta. No
> sustituye al Service, **trabaja encima de él**. Es la forma habitual de
> exponer Superset, JupyterHub o la UI de Airflow.
>
> ▶ **151** Y ahora vuestro mejor amigo en local: **`port-forward`**.
>
> `kubectl port-forward svc/mi-app 8090:80`. Y se lee **igual que el `-p` de
> Docker**: el de la izquierda es el puerto en **vuestra** máquina, el de la
> derecha el del Service. Abre un túnel temporal, funciona con cualquier tipo
> de Service, no requiere tocar ningún manifiesto, y se cierra con `Ctrl+C`.
>
> Para vosotros esto es oro puro por dos motivos muy concretos: conectar
> **DBeaver o DataGrip** a la base de datos interna del cluster para lanzar
> cuatro consultas, y **abrir la UI de Airflow** sin montar un Ingress.
>
> Pero atención al aviso, que es serio: es **temporal** y no está pensado para
> tráfico pesado. No lo uséis para extraer gigas de datos a vuestro portátil.
> Funciona, sí, pero mal y lento, y alguien lo verá en las métricas.
>
> ▶ **152** El ejercicio 2 tiene cuatro pasos, y el tercero es el que hace
> clic: comprobáis que las IPs cambian al borrar un Pod, comprobáis que el
> Service **sí** encuentra a los Pods, y luego entráis **dentro** del cluster
> y hacéis `curl http://mi-app` **por nombre DNS**. Y funciona. Y desde
> fuera, `port-forward`.
>
> Pero el paso estrella es el de la derecha: **romped el selector a
> propósito**. Cambiad una letra, volved a aplicar, y haced
> `kubectl describe svc`. Veréis `Endpoints: <none>`.
>
> Y quiero que os fijéis en lo que **no** ha pasado: **ningún error**. Nadie
> os avisa. El Service simplemente deja de funcionar en silencio. Por eso
> `kubectl get endpoints` es de los comandos que más vais a usar.
>
> ▶ **153** Y luego, el reto por parejas, que es mi parte favorita de la
> sesión: cada uno mete **un** fallo en el YAML del otro, sin decir cuál, y el
> otro tiene dos minutos para encontrarlo con `get`, `describe`, `endpoints` y
> `logs`.
>
> La regla es la que importa: **se diagnostica leyendo la salida, no
> releyendo el YAML**. Y el motivo está en el pie: romper algo tú y luego
> arreglarlo no es depurar, porque ya sabes la respuesta. Esto se parece
> bastante más a un martes por la mañana con un pipeline caído y sin ningún
> contexto. Que es, con perdón, vuestro futuro.

**Puntos clave a remarcar en cámara:**
- El dolor concreto: pipeline atado a la IP de un Pod → falla de madrugada.
- **Es el mismo DNS de Compose.** La cadena de conexión no cambia ni un carácter.
- ClusterIP = 90 % de los casos. NodePort para local. LoadBalancer para entrada masiva. Ingress va **encima**.
- `port-forward` se lee como `-p`. Para DBeaver y la UI de Airflow. **No** para mover gigas.
- Selector roto = `Endpoints: <none>` y **cero errores**. `kubectl get endpoints` es el comando clave.
- Diagnosticar = leer la salida, no releer el YAML.

---

## Vídeo 12 — ConfigMap, Secret y almacenamiento persistente (12 min)

**Diapositivas:** 154 a 163
**Teoría:** TEORIA_KUBERNETES.md §6 y §7
**Desbloquea:** ejercicios 3 y 4

**Objetivo:** que separen configuración de imagen sin pensarlo, que sepan
que un Secret **no está cifrado**, y que entiendan por qué en un cluster la
persistencia es un problema más grave que en Docker.

**Guion:**

> ▶ **154–155** En Docker ya visteis que la configuración no va dentro de la
> imagen. Kubernetes formaliza esa idea con dos objetos que, mirad las dos
> columnas, son **prácticamente idénticos**: un ConfigMap y un Secret son el
> mismo objeto con distinta intención. Uno para lo público, otro para lo
> sensible.
>
> El ConfigMap lleva un `data:` con pares clave-valor: el entorno, el tamaño
> del lote, el host de la base de datos. El Secret lleva un `stringData:` con
> la contraseña. Y ese `stringData` es una comodidad importante: **lo
> escribís en texto plano y Kubernetes lo codifica solo**. Nada de andar
> haciendo `base64` a mano, que es como la gente acaba con un salto de línea
> dentro de la contraseña y dos horas perdidas.
>
> Y abajo, la forma de inyectarlos: **`envFrom`**, que mete **todas** las
> claves de golpe como variables de entorno. Es el equivalente exacto del
> `env_file` de Compose.
>
> ▶ **156** Y ahora una diapositiva que hay que decir en voz alta y sin
> rodeos: **un Secret no está cifrado**. Está codificado en **base64**, que es
> trivial de revertir. Mirad el comando: un `jsonpath` y un `base64 -d`, y ahí
> tenéis la contraseña en pantalla.
>
> ¿Entonces para qué sirve? Para lo que dice el pie: protege frente a que la
> contraseña **aparezca por accidente** en un log o en un `kubectl get -o
> yaml`. No protege frente a un atacante. Para seguridad real necesitáis
> cifrado en reposo en etcd, RBAC bien configurado, o un gestor externo tipo
> Vault, AWS Secrets Manager o el de Google.
>
> Y la última línea, que va en serio: **nunca, jamás, subáis a Git un Secret
> con datos reales**. Un base64 en un repositorio no es una contraseña
> protegida, es una contraseña con un sombrero puesto.
>
> ▶ **157** Las equivalencias, que es donde se ve que nada de esto es nuevo:
> `-e VAR=valor` pasa a ser ConfigMap más `envFrom`. El archivo `.env` pasa a
> ser un ConfigMap. Las contraseñas en `.env` —que ya dijimos que era mala
> práctica— pasan a Secret, o mejor a Vault. Y un
> `-v ./config.yml:/app/config.yml` pasa a ser un **ConfigMap montado como
> volumen**.
>
> Y esa última fila tiene una sección entera dedicada a vosotros, porque es
> el estándar de la industria en datos: **inyectar archivos de configuración
> pesados**. Un `spark-defaults.conf`, un `airflow.cfg`. Creáis el ConfigMap
> con el contenido completo del archivo, lo declaráis como volumen, y
> Kubernetes crea el archivo dentro del contenedor al arrancar.
>
> ¿Por qué os importa? Porque a los data engineers nos gusta tener la
> configuración en archivos organizados, no en cuarenta variables de entorno
> sueltas desperdigadas por el manifiesto. Y porque —fijaos en la última
> línea— cambiar el ConfigMap puede actualizar el archivo montado **sin
> reiniciar la aplicación**.
>
> ▶ **158** El ejercicio 3 va de eso, y la pregunta para pensar es la buena:
> habéis cambiado el comportamiento de la aplicación **sin reconstruir la
> imagen**. ¿Por qué importa eso en un pipeline de integración continua?
> Pensadlo: significa que promocionar de `dev` a `prod` no requiere construir
> nada nuevo. Es el mismo artefacto con otra configuración. Vuelve el módulo 0.
>
> ▶ **159–160** Cambiamos de tema: almacenamiento. Y os aviso de que aquí la
> situación es **peor** que en Docker.
>
> En Docker, en local, si el contenedor muere no pasa nada grave: los datos
> siguen en el disco duro de vuestro portátil gracias al clásico `-v`. Pero en
> un cluster hay un problema nuevo: **si el nodo A se apaga y el Pod resucita
> en el nodo B, el disco duro físico es otro.** Vuestros datos se han quedado
> en una máquina a la que el Pod ya no tiene acceso.
>
> Tres niveles. **`emptyDir`** vive mientras viva el Pod: es el equivalente a
> la capa de escritura del contenedor. **`hostPath`** vive mientras viva el
> nodo, **y solo ese nodo**: es el equivalente al bind mount. Y el
> **PersistentVolume** vive hasta que vosotros lo borréis: es el equivalente
> al volumen con nombre.
>
> Y atención al aviso del pie, porque es una trampa muy tentadora:
> **`hostPath` parece la traducción natural del bind mount, pero evitadlo**.
> Ata el Pod a un nodo concreto, y si el Pod se recoloca, los datos se quedan
> en la otra máquina. Funciona perfectamente en minikube —donde solo hay un
> nodo— y explota el día que lo lleváis a producción. Que es la peor clase de
> error: el que solo aparece cuando ya importa.
>
> ▶ **161** PV y PVC: dos objetos para una sola cosa, y la analogía de la
> reserva de mesa lo deja claro.
>
> El **PVC** es la reserva: "necesito cinco gigas de disco". Lo escribís
> vosotros, en vuestro YAML. El **PV** es la mesa física: el disco real. Y lo
> crea el cluster o el proveedor cloud.
>
> Lo importante en la práctica: **el PVC es lo único que escribís
> normalmente**. El PV lo crea automáticamente el proveedor —un disco EBS en
> AWS, un Persistent Disk en Google— o, en minikube, el propio cluster de
> forma dinámica. Así que no os agobiéis con el PV: pedís y aparece.
>
> ▶ **162** El manifiesto es esto: un PVC con `accessModes` y el tamaño que
> pedís, y luego en el Pod un `volumeMounts` que dice dónde montarlo y un
> `volumes` que lo conecta con el PVC por nombre. Es idéntico a un volumen de
> Docker, solo que con más ceremonia. Bienvenidos a Kubernetes.
>
> Y prestad atención a los **modos de acceso**, porque este es de los detalles
> que os van a preguntar en una entrevista.
>
> **ReadWriteOnce** significa que **un solo nodo** lo monta en escritura. Es
> lo normal para bases de datos relacionales, y por debajo suele ser un disco
> de bloque tipo EBS.
>
> **ReadWriteMany** significa que **múltiples nodos** leen y escriben a la
> vez. Por debajo es un sistema de archivos en red, tipo EFS o NFS. Y es
> **vuestro salvavidas** el día que tengáis varios workers de Spark que
> necesitan leer el mismo dataset físico a la vez, o que queráis centralizar
> los logs de Airflow.
>
> Si os quedáis con una: RWO para bases de datos, RWX para datasets
> compartidos entre workers.
>
> ▶ **163** Y el ejercicio 4 es la demostración: creáis Postgres con su PVC,
> insertáis una fila, **destruís el Pod** con `kubectl delete pod`, esperáis a
> que se recree, y consultáis. La fila sigue ahí.
>
> El Pod se ha recreado desde cero. El PVC, no.
>
> Y las dos preguntas para pensar son buenas: ¿qué habría pasado con
> `emptyDir` en vez de PVC? Y la segunda, que es la que de verdad importa: ¿y
> si el cluster tuviera tres nodos y el Pod se recolocara en otro? Volved a la
> 160 y a la nota sobre `hostPath`.

**Puntos clave a remarcar en cámara:**
- ConfigMap y Secret son el mismo objeto con distinta intención. `envFrom` inyecta todo de golpe.
- **Un Secret NO está cifrado.** base64 se revierte en un comando. Decirlo en voz alta.
- ConfigMap montado como **volumen** = el patrón estándar para `spark-defaults.conf` / `airflow.cfg`.
- En un cluster el Pod puede resucitar **en otro nodo**: ahí muere el disco local.
- **Evitar `hostPath`.** Funciona en minikube y explota en producción.
- PVC = la reserva (lo escribes tú). PV = la mesa (lo crea el cluster).
- **RWO** para bases de datos, **RWX** para datasets compartidos entre workers de Spark.

---

## Vídeo 13 — Salud y recursos: probes, limits y `OOMKilled` (10 min)

**Diapositivas:** 164 a 167
**Teoría:** TEORIA_KUBERNETES.md §8

**Objetivo:** que sepan que "Running" no significa "funcionando", y que
salgan reconociendo `OOMKilled` y `CrashLoopBackOff` de un vistazo. Este es
el vídeo más "de producción" del bloque.

**Guion:**

> ▶ **164–165** Esto es lo que separa un despliegue de juguete de uno de
> producción, y la diapositiva empieza con una frase dedicada a nosotros que
> me parece muy acertada: mientras un desarrollador web se preocupa de
> latencias de milisegundos, **el data engineer lidia con pipelines en Python,
> Spark o pandas que devoran memoria como si no hubiera un mañana**.
>
> Punto de partida: **que el proceso corra no significa que funcione**. Un
> contenedor puede estar vivo y colgado, y `Running` os mentirá alegremente.
>
> Para eso hay tres sondas, y cada una responde a una pregunta distinta.
>
> **liveness**: ¿sigue viva? Si falla, **reinicia** el contenedor.
> **readiness**: ¿está lista para recibir tráfico? Si falla, **la saca del
> Service** pero **no la reinicia**. Y **startup**: ¿ha terminado de arrancar?
>
> La diferencia entre las dos primeras es la que hay que entender, y las dos
> frases del medio lo resumen perfectamente. Readiness fallando dice "estoy
> cargando, no me mandes peticiones ahora", y Kubernetes la deja tranquila.
> Liveness fallando dice "estoy rota sin remedio", y Kubernetes la reinicia.
> Confundirlas es lo que hace que una aplicación que solo estaba ocupada
> acabe reiniciándose en bucle.
>
> Y la startup probe... la startup probe existe **por Airflow y compañía**.
> Aplicaciones que tardan noventa segundos en arrancar y que la liveness
> mataría a los quince, en bucle infinito, para siempre. Si alguna vez
> desplegáis Airflow en Kubernetes y no arranca nunca, mirad esto primero.
>
> ▶ **166** `requests` y `limits`, y el título ya avisa: **por qué os van a
> doler**.
>
> `requests` es lo que Kubernetes os **garantiza**: con eso decide el
> scheduler en qué nodo cabéis. `limits` es el **máximo** que podéis usar.
>
> Y las consecuencias de pasarse son **asimétricas**, que es lo que hay que
> saber. Si os pasáis de **CPU**, hay *throttling*: vais más lento, pero
> seguís vivos. Si os pasáis de **memoria**, el contenedor **muere**:
> `OOMKilled`.
>
> Ahí está la frase que resume vuestra vida profesional: **un
> `pandas.read_csv()` más grande de lo esperado y Kubernetes mata el Pod sin
> avisar**. Sin traza, sin excepción de Python, sin nada. El proceso
> desaparece. Y vosotros mirando los logs sin entender por qué se cortan a
> mitad.
>
> Por eso: Pod reiniciándose sin logs claros → `kubectl describe pod` → buscad
> `OOMKilled`.
>
> Y una nota de unidades, porque confunde a todo el mundo la primera vez:
> **`1000m` es un núcleo entero de CPU**. Así que `500m` es media CPU. La `m`
> es de *milicores*, no de "mega".
>
> ▶ **167** Y esta es la diapositiva que quiero que fotografiéis, porque es la
> chuleta de vuestro primer mes: **los cuatro estados en los que se os va a
> quedar un Pod**. Y fijaos en el subtítulo, que es muy fino: "Running" no
> sale en la tabla, **y justo por eso la vais a necesitar**.
>
> **`Pending`**: el scheduler no encuentra un nodo con sitio. Ya lo vimos:
> faltan recursos. Se mira con `describe`, en los eventos.
>
> **`ImagePullBackOff`**: no consigue descargar la imagen. Nombre, tag o
> credenciales del registry. Spoiler: en el vídeo 15 vais a provocarlo sin
> querer.
>
> **`CrashLoopBackOff`**: arranca, se muere, y Kubernetes reintenta cada vez
> más despacio. Se mira con `logs`.
>
> **`OOMKilled`**: se pasó del límite de memoria. Se mira con `describe`, en
> `Last State`.
>
> Y quedaos con el pie, que es la parte de verdad útil: **`CrashLoopBackOff`
> es el más frecuente y el peor entendido**. No es un fallo de Kubernetes, es
> **vuestro proceso saliendo con código distinto de cero**. Kubernetes está
> haciendo exactamente lo que le pedisteis.
>
> Y la clave para diagnosticarlo es el flag **`--previous`**. Sin él, leéis
> los logs del contenedor que **acaba de arrancar** —que normalmente no ha
> dicho nada todavía—, y no los del que **se murió**, que es donde está la
> explicación. Es el flag que más veces vais a escribir en vuestros primeros
> meses. Apuntadlo.

**Puntos clave a remarcar en cámara:**
- "Running" ≠ "funcionando". Un proceso vivo y colgado es peor que uno muerto.
- **readiness** te saca del Service (no reinicia). **liveness** reinicia. Confundirlas = bucle.
- **startup probe existe por Airflow**: apps que tardan 90 s en arrancar.
- CPU → throttling (lento). Memoria → **muerte** (`OOMKilled`). Asimétrico.
- `read_csv()` que revienta el límite = Pod muerto **sin traza**. El caso más nuestro de todos.
- `1000m` = 1 núcleo.
- `CrashLoopBackOff` = **tu** proceso saliendo con código ≠ 0. Y `--previous` es el flag clave.

---

## Vídeo 14 — Job y CronJob: tu pan de cada día (12 min)

**Diapositivas:** 168 a 173
**Teoría:** TEORIA_KUBERNETES.md §9
**Desbloquea:** ejercicio 5 (el ejercicio central de la sesión)

**Objetivo:** el vídeo **más importante** del bloque para este perfil. Que
salgan sabiendo que un ETL **nunca** va en un Deployment, y que sepan
responder a "¿entonces para qué sirve Airflow?".

**Guion:**

> ▶ **168** Llegamos a los objetos que, con diferencia, son **los más
> relevantes para vuestro perfil**. Si de toda la sesión de hoy solo os
> lleváis un bloque, que sea este.
>
> ▶ **169** Y empezamos reconociendo el problema: **casi todo lo que hemos
> visto hoy corre para siempre. Casi todo lo que vosotros hacéis, no.**
>
> La tabla es de las que hay que leer entera. **Deployment**: algo que atiende
> peticiones, no termina nunca —ese es el objetivo—, y si el proceso acaba, lo
> reinicia. Ejemplo vuestro: una API, la UI de Airflow.
>
> **Job**: algo que se ejecuta una vez, termina cuando el proceso sale con
> código cero, y entonces se da por **completado**. Ejemplo vuestro: una carga
> inicial, una migración.
>
> **CronJob**: algo que se ejecuta a una hora. Cada ejecución es independiente.
> Ejemplo vuestro: el ETL de las dos de la mañana.
>
> Y ahora el aviso, que ya sembré en el vídeo 10 y que aquí toca desarrollar
> del todo. **El error clásico es meter una ETL en un Deployment.** ¿Qué pasa?
> Vuestro script termina **correctamente**, con éxito, código cero, todo bien.
> Y Kubernetes, que está programado para pensar que un Deployment no debe
> terminar nunca, interpreta que se ha parado de forma no planificada. Y lo
> reinicia. Inmediatamente.
>
> Vuestra carga de datos se ejecuta **en bucle, una y otra vez, durante toda
> la noche**.
>
> Y lo peor —última línea— es que **en el panel todo parece correcto**, porque
> el Pod aparece como `Running`. Nadie os avisa. Ninguna alarma salta. Os
> enteráis por la factura de la nube, o porque alguien de negocio pregunta por
> qué el informe dice que habéis vendido cuarenta veces el mismo pedido.
>
> ▶ **170** Así que vamos con el **Job**, que es la herramienta correcta.
>
> Mirad el manifiesto: `apiVersion: batch/v1`, `kind: Job`, un `backoffLimit`
> que son los reintentos, y dentro una plantilla de Pod con
> `restartPolicy: OnFailure` y vuestro contenedor ejecutando
> `python carga.py`.
>
> La diferencia con un Deployment está en la columna derecha, y el contraste
> me encanta cómo está redactado: si un Pod de un **Deployment** termina,
> Kubernetes piensa "¡oh no, se ha caído!" y lo reinicia. Si un Pod de un
> **Job** termina con código cero, Kubernetes lo deja en `Completed` y piensa
> "buen chico". Es el mismo hecho interpretado de dos formas opuestas, y por
> eso elegir el objeto correcto importa tanto.
>
> Y hay dos superpoderes ahí abajo que quiero que conozcáis porque son
> específicamente para nosotros.
>
> El primero, **paralelismo**: un Job puede levantar diez Pods a la vez con
> `parallelism: 10` para procesar una cola de Kafka de forma concurrente hasta
> completar cien tareas con `completions: 100`. Eso es oro puro para
> distribución, y es gratis: no tenéis que escribir ningún orquestador.
>
> El segundo, **tolerancia a fallos**: si vuestro script de pandas falla
> porque una API externa dio timeout —que pasa siempre—, el Job usa
> `backoffLimit` para reintentarlo automáticamente antes de rendirse. Sin que
> vosotros escribáis un solo `try/except` de reintentos.
>
> ▶ **171** Y el **CronJob** es simplemente un Job nuevo cada vez que toca. La
> sintaxis de `schedule` es cron de toda la vida: minuto, hora, día del mes,
> mes, día de la semana.
>
> `"0 2 * * *"` son las dos de la mañana. `"*/5 * * * *"` es cada cinco
> minutos. `"0 6 * * 1"` es los lunes a las seis.
>
> Y los casos de uso son literalmente vuestro futuro trabajo: lanzar la
> ingesta diaria del ERP a la base de datos analítica, limpiar tablas
> huérfanas los domingos, generar un informe cada mañana.
>
> Un consejo práctico que no está en la diapositiva: cuando dudéis de una
> expresión cron, no la adivinéis. Se equivoca todo el mundo, sobre todo con
> el día de la semana. Y una expresión cron mal puesta no falla: simplemente
> se ejecuta cuando no toca, que es mucho peor.
>
> ▶ **172** Y ahora **la pregunta que siempre sale en clase**, y que es
> completamente legítima: si Kubernetes ya programa tareas... **¿entonces para
> qué sirve Airflow?**
>
> La respuesta está en la tabla, y es honesta en las dos direcciones.
> Programar una tarea: los dos. Pero **dependencias entre tareas** —que B se
> ejecute después de A—: el CronJob **no**, Airflow **sí**, y eso es
> exactamente lo que es un DAG. **Reintentos configurables por tarea**:
> básicos en CronJob, finos en Airflow. **Interfaz para ver el histórico**:
> `kubectl get jobs` frente a una UI completa. **Backfill de fechas
> pasadas**: el CronJob no sabe hacerlo, Airflow sí. Y **paso de datos entre
> tareas**: XComs y datasets.
>
> Resumiendo: un CronJob programa **una** cosa. Airflow orquesta **un grafo de
> cosas con dependencias, histórico y backfill**. No compiten.
>
> Y fijaos en el pie, porque describe la arquitectura estándar de la
> industria: **se combinan**. El `KubernetesPodOperator` de Airflow lanza cada
> tarea del DAG como un Pod. Airflow pone la orquestación, Kubernetes pone la
> ejecución aislada y el escalado. Eso es lo que os vais a encontrar en
> cualquier empresa que corra Airflow sobre Kubernetes, que hoy son
> prácticamente todas las que tienen algo de volumen.
>
> ▶ **173** Y con esto tenéis el ejercicio central de la sesión, treinta
> minutos: lanzáis vuestro pipeline como **Job**, comprobáis en la base de
> datos que ha insertado las filas, lo programáis cada cinco minutos como
> **CronJob**, y —truco muy útil— lo ejecutáis manualmente sin esperar con
> `kubectl create job --from=cronjob/pipeline`. Ese comando os va a salvar
> muchas esperas tontas depurando.
>
> Y mirad lo que habréis construido al terminar: una base de datos con
> almacenamiento que sobrevive, una API que expone datos, y un proceso
> programado que la alimenta. Con configuración externa, secretos y
> reintentos. Eso es un pipeline de datos en producción. En dos horas y media.

**Puntos clave a remarcar en cámara:**
- **El vídeo más importante del bloque.** Si algo se graba con energía, este.
- ETL en un Deployment = **bucle infinito toda la noche**, y el panel dice `Running`.
- Deployment: "¡se ha caído!" → reinicia. Job: "buen chico" → `Completed`. Mismo hecho, interpretación opuesta.
- `parallelism` + `completions` = paralelismo gratis para colas. `backoffLimit` = reintentos gratis.
- **"¿Y entonces para qué sirve Airflow?"** → dependencias, histórico, backfill, XComs. No compiten: se combinan con `KubernetesPodOperator`.
- `kubectl create job --from=cronjob/...` para no esperar al schedule.

---

## Vídeo 15 — minikube, tabla de traducción y diagnóstico (10 min)

**Diapositivas:** 174 a 184
**Teoría:** TEORIA_KUBERNETES.md §10 y §11
**Desbloquea:** ejercicio 6 (opcional)

**Objetivo:** desactivar el error que tumba a media clase, y cerrar el módulo
entero con la tabla de traducción y la batería de diagnóstico.

**Guion:**

> ▶ **174–175** Vamos con el error que tumba a media clase, y lo digo sin
> exagerar: **vuestras imágenes locales no existen dentro del cluster**.
>
> minikube tiene **su propio almacén de imágenes**. Es, literalmente, otro
> Docker. Así que podéis hacer `docker image ls` y ver ahí vuestra
> `mi-imagen:1.0` tan tranquila... y el cluster no la ve. Resultado: el Pod se
> queda en `ImagePullBackOff` para siempre, mientras vosotros juráis que la
> imagen existe. Y tenéis razón: existe. Solo que no ahí.
>
> Tres soluciones. La **A**, publicar en Docker Hub con `docker push`: es la
> mejor, porque es lo que se hace en producción. La **B**,
> `minikube image load mi-imagen:1.0`: es la de iterar rápido, y la que
> usaremos hoy. Y la **C**, `eval $(minikube docker-env)`, que redirige
> vuestro cliente de Docker al demonio de minikube: para desarrollo intensivo.
>
> ▶ **176** Y ahora **el gotcha dentro del gotcha**, que es maravilloso.
>
> Con las opciones B y C, si vuestra imagen tiene el tag `latest`, Kubernetes
> usa por defecto `imagePullPolicy: Always`. Es decir: **intenta descargarla
> de Docker Hub e ignora la copia local que acabáis de cargar**. Hacéis todo
> bien y sigue fallando.
>
> La solución: usad siempre un tag concreto —`:1.0`— o añadid explícitamente
> `imagePullPolicy: IfNotPresent`.
>
> Y fijaos en la frase del pie, que es mi favorita de todo el módulo: **es la
> tercera vez que `latest` causa un problema. No es casualidad.** Primera vez,
> vídeo 4: versiones que cambian debajo. Segunda, en el Compose. Tercera,
> aquí. A estas alturas espero que `latest` os produzca un pequeño escalofrío.
>
> ▶ **177** El ejercicio 6 es opcional pero muy vistoso: hacéis un
> `kubectl set image` a una versión nueva, y luego a una versión **que no
> existe**. Y lo que veis es que el Pod nuevo se queda en `ImagePullBackOff`,
> **pero los Pods viejos siguen sirviendo tráfico**. Cero downtime **incluso
> con un despliegue roto**. Y luego `kubectl rollout undo` para volver atrás.
>
> Esa es la respuesta definitiva a la pregunta 5 de la diapositiva 123.
>
> ▶ **178–179** Y cerramos con la tabla que resume el módulo entero. No os la
> voy a leer entera, pero quiero que veáis el patrón: **cada fila es algo que
> ya sabíais, con otro nombre**.
>
> `docker run` es un **Pod**. Vuestro portátil es un **Nodo**. Separar
> proyectos en carpetas es un **Namespace**. `docker compose up` de servicios
> es un **Deployment**. Un script de ejecución única es un **Job o CronJob** —y
> ahí pone, con razón, "tu pan de cada día"—. El `localhost` entre
> contenedores es un **Service**. El `-p 8080:80` es **port-forward**. Las
> variables del `.env` son un **ConfigMap**. Las contraseñas, un **Secret**.
> El `-v /ruta:/datos` es un **PVC**. Y el límite de memoria son **requests y
> limits**.
>
> No hay ni una sola idea nueva en esa tabla. Solo nombres nuevos y más
> ceremonia. Que es, sinceramente, el 80 % de lo que es aprender Kubernetes.
>
> ▶ **180** Con **una** excepción, y es importante: **`depends_on` no tiene
> equivalente. Y es a propósito.**
>
> Kubernetes **no garantiza orden de arranque**. Su filosofía es que vuestra
> aplicación debe **tolerar** que su dependencia no esté lista. Si vuestro Pod
> no encuentra Postgres, se reinicia, y en el siguiente intento ya estará.
>
> Al principio esto suena a dejadez, pero es lo correcto: en un sistema
> distribuido las dependencias **se caen en cualquier momento**, no solo al
> arrancar. Una aplicación que solo tolera fallos durante el arranque es una
> aplicación frágil.
>
> Y para los casos que sí necesitan orden estricto —una migración de base de
> datos antes de arrancar, por ejemplo— existen los **initContainers**:
> contenedores que se ejecutan hasta completarse **antes** del contenedor
> principal.
>
> ▶ **181** La tabla de comandos, que os va a servir la primera semana:
> `compose up` es `kubectl apply -f .`, `compose down` es `kubectl delete -f
> .`, `compose ps` es `kubectl get pods`, `compose logs -f` es
> `kubectl logs -f deploy/x`, `compose exec` es `kubectl exec -it deploy/x --
> sh`.
>
> Y fijaos en la última fila: **`kubectl describe pod` no tiene equivalente en
> Compose**, y es la herramienta de diagnóstico más importante de Kubernetes.
> Al final de su salida están los **eventos**, y ahí está siempre la causa.
> Siempre.
>
> ▶ **182** Y si de toda la sesión os lleváis **una sola chuleta**, que sea
> esta. Cuatro síntomas, cuatro comandos.
>
> ¿No arranca —`Pending`, `ImagePullBackOff`—? **`kubectl describe pod`**, y
> mirad los eventos del final.
>
> ¿Error en ejecución o bucles —`CrashLoopBackOff`—? **`kubectl logs <pod>
> --previous`**, para leer la traza del contenedor **que murió**.
>
> ¿El Service no responde, o el Pod está `Running` pero es inaccesible?
> **`kubectl get endpoints <svc>`**. Si pone `<none>`, es el selector.
>
> ¿El CronJob no se ejecuta? **`kubectl describe cronjob`**, para ver si hubo
> ejecuciones y con qué resultado.
>
> Y el aviso del pie es la regla de oro: **siempre `describe` antes que
> `logs`**. Si el contenedor no ha llegado ni a arrancar, no hay logs que
> leer, y la causa está en los eventos. Ver a alguien releyendo logs vacíos
> durante veinte minutos es un clásico, y ahora ya no os va a pasar.
>
> ▶ **183–184** Última cosa, y va en serio: **limpiad**. minikube ocupa cuatro
> gigas de RAM mientras esté arrancado. `kubectl delete -f .`, comprobad los
> PVC con `kubectl get pvc` —porque **no siempre se borran** con lo anterior—,
> y luego `minikube stop` para apagar el cluster conservando el estado.
>
> Y con esto cerramos el módulo. Habéis pasado de no saber qué era un
> contenedor a desplegar un pipeline completo, con persistencia, configuración
> externa, secretos y ejecución programada, sobre un cluster. Si dentro de
> unos meses abrís el repositorio de una empresa y os encontráis una carpeta
> llena de YAML, ya sabéis leerla. Que era exactamente el objetivo.

**Puntos clave a remarcar en cámara:**
- **Las imágenes locales no existen en minikube.** Es el error que tumba a media clase.
- Opción B (`minikube image load`) para clase; opción A (`push`) es la de producción.
- El gotcha del gotcha: `latest` → `imagePullPolicy: Always` → ignora la copia local. **Tercera vez que `latest` muerde.**
- Rolling update: despliegue roto y **cero downtime**. Cierra la pregunta 5 de la 123.
- La tabla de traducción: **ninguna idea nueva**, solo nombres nuevos.
- `depends_on` no existe **a propósito**. La app debe tolerar el fallo. Para orden estricto: `initContainers`.
- **`describe` antes que `logs`.** Siempre.
- Recordar la limpieza: minikube se come 4 GB.

---

## Notas de producción

**Orden de grabación sugerido:** el bloque de Docker en dos sesiones (1–5 y
6–7) y el de Kubernetes en dos más (8–11 y 12–15). Los vídeos 6 y 7
comparten el hilo del proyecto real, así que ganan mucho grabados seguidos.
Lo mismo con el 13 y el 14: el `OOMKilled` del 13 encadena directo con el
"tu ETL en bucle toda la noche" del 14.

**Qué mostrar en pantalla:**
- Diapositivas puras: 1, 4, 8, 9.
- Diapositivas + terminal en vivo: 2, 3, 5, 7, 10, 11, 14, 15.
- El vídeo 7 y el 15 son los dos "momentos ah, vale" del módulo: en el 7 se
  recorre el `docker-compose.yml` real; en el 15, la tabla de traducción. En
  ambos conviene ir señalando con el cursor mientras hablas.

**Si un vídeo se alarga:** córtalo en dos antes que acelerar. Por encima de
15 minutos la tasa de abandono se dispara. Los candidatos naturales a
partirse son el 9 (arquitectura / YAML) y el 12 (configuración /
almacenamiento), que ya son dos temas pegados.

**Errores a propósito:** el patrón "síntoma primero, concepto después"
funciona muy bien y está pensado en varios puntos del guion. Provoca el
fallo antes de enseñar la solución:
- Vídeo 3: conexión rechazada antes de explicar `-p`.
- Vídeo 5: `ModuleNotFoundError` antes del Dockerfile.
- Vídeo 11: romper el selector y enseñar `Endpoints: <none>` **sin ningún
  error en pantalla**.
- Vídeo 15: `ImagePullBackOff` con la imagen "que sí existe" en `docker
  image ls`.

**El hilo de `latest`:** aparece tres veces a propósito — vídeo 4
(diapositiva 62, versiones que cambian debajo), vídeo 7 (el `.env` del
proyecto fija `apache/airflow:3.3.1-python3.14`) y vídeo 15 (diapositiva
176, `imagePullPolicy: Always`). La propia diapositiva 176 lo señala. Merece
la pena remarcarlo cada vez y hacer la broma en la tercera: es el gag que
mejor fija el concepto de todo el módulo.

**Tono:** el público son futuros ingenieros de datos. Cada vez que aparezca
una diapositiva con un ejemplo de Spark, Kafka, pandas o Airflow, **párate
en ella**: son las que justifican por qué están viendo esto. Las
diapositivas 27, 28, 144, 157, 162, 165, 166, 170 y 172 son exactamente eso.

**Lo que NO debe entrar en los vídeos** (queda fuera a propósito y así se
dice en TEORIA.md y TEORIA_KUBERNETES.md):
- Docker: multi-stage builds, redes personalizadas, Swarm, registries
  privados en profundidad, CI/CD y optimización fina de imágenes.
- Kubernetes: Helm, operadores, RBAC en detalle, StatefulSets, políticas de
  red, service mesh, autoescalado real (HPA/VPA) y multi-cluster.

Si se cuelan, el módulo se desborda. Y si alguien pregunta por ellos en
directo, la respuesta honesta es: "existe, es lo siguiente que aprenderéis,
y con lo de hoy tenéis la base para entenderlo".
