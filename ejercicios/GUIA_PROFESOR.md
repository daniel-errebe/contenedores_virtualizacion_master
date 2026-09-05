# Guía del profesor — sesión de contenedores (5 h)

Documento operativo para impartir la sesión. Los alumnos no necesitan
leerlo.

Material: [TEORIA.md](./TEORIA.md) · [EJERCICIOS.md](./EJERCICIOS.md) ·
[EJERCICIOS_EXTRA.md](./EJERCICIOS_EXTRA.md)

---

## 1. Idea central de la sesión

El público son **Data Engineers, no DevOps**. El objetivo no es que dominen
Docker, sino que sean **autónomos con los stacks de datos** que van a
encontrarse: levantarlos, modificarlos, depurarlos y no perder datos.

Todo el material se organiza alrededor de cuatro preguntas que un Data
Engineer se hace de verdad:

1. ¿Cómo levanto esto? → Compose
2. ¿Cómo meto mi librería? → Dockerfile
3. ¿Por qué no conecta con la base de datos? → Red y nombres de servicio
4. ¿Dónde están mis datos? → Volúmenes

Si al final de la clase saben responder a esas cuatro, la sesión es un
éxito, aunque no sepan qué es un *multi-stage build*.

---

## 2. Cronograma

| Tramo | Duración | Contenido |
|---|---|---|
| 00:00 – 00:15 | 15 min | Bienvenida. Comprobar que a todos les funciona Docker. |
| 00:15 – 00:40 | 25 min | **Teoría** §1, §2, §3 — contenedor vs imagen, ciclo de vida, tags |
| 00:40 – 01:30 | 50 min | **Práctica bloque 1** — ejercicios 1, 2, 3 |
| 01:30 – 01:40 | 10 min | ☕ Descanso |
| 01:40 – 02:00 | 20 min | **Teoría** §4 y §4.1 — Dockerfile y extender imágenes |
| 02:00 – 02:40 | 40 min | **Práctica bloque 2** — ejercicios 4, 5 |
| 02:40 – 02:55 | 15 min | ☕ Descanso |
| 02:55 – 03:20 | 25 min | **Teoría** §7, §8, §9 — Compose, red, volúmenes |
| 03:20 – 04:15 | 55 min | **Práctica bloque 3** — ejercicios 6, 7, 8 |
| 04:15 – 04:25 | 10 min | ☕ Descanso |
| 04:25 – 04:45 | 20 min | **Teoría** §5, §10, §11 + **ejercicio 9** |
| 04:45 – 05:00 | 15 min | **Ejercicio 10** (guiado por ti) + cierre y preguntas |

**Margen real: prácticamente cero.** Está calculado para que salga justo.
Ver la sección 5 para saber qué recortar si vas retrasado.

### Vídeos

Si la asignatura incluye vídeos asíncronos, el mejor reparto es:

- **Antes de clase**: instalación de Docker + los ejercicios 1 y 2. Así
  llegan con las manos ya calientes y ganas ~30 min de la sesión.
- **Después de clase**: recorrido comentado del `docker-compose.yml` final y
  uno o dos ejercicios de [EJERCICIOS_EXTRA.md](./EJERCICIOS_EXTRA.md).

---

## 3. Checklist previo

### Para ti (la semana anterior)

- [ ] Enviar a los alumnos la sección *"Antes de la clase"* de
      [EJERCICIOS.md](./EJERCICIOS.md#antes-de-la-clase-obligatorio). **Esto
      es lo más importante de toda la preparación.** Si descargan la imagen
      de Airflow (~1,5 GB) en clase, pierdes 30-40 minutos.
- [ ] Pedirles que confirmen que `docker run --rm hello-world` funciona.
- [ ] Preparar un USB o una carpeta compartida con las imágenes exportadas
      (`docker save`) por si el wifi del aula va mal.
- [ ] Levantar tú el proyecto real (`docker compose up -d`) y dejarlo
      funcionando como demostración de referencia.

### El día de la clase, primeros 15 minutos

Que todos ejecuten y enseñen el resultado:

```bash
docker compose version
docker image ls | grep -E "airflow|postgres|alpine"
```

Quien no tenga las imágenes, que las descargue **mientras empieza la
teoría** — no le hacen falta hasta el ejercicio 3.

---

## 4. Problemas frecuentes en el aula

| Problema | Solución rápida |
|---|---|
| Docker Desktop no arranca (Windows) | WSL2 sin habilitar. Es la causa nº 1 en Windows y **no se arregla en clase**: que se emparejen con un compañero y lo resuelvan después. |
| Todo va lentísimo | Docker con poca RAM. Settings → Resources → 4 GB mínimo. Requiere reiniciar Docker. |
| `port is already allocated` | Alguien tiene el proyecto real levantado. El sandbox usa **8088** justo para esto; que revisen `docker ps`. |
| Airflow tarda 2-3 min en levantar | Es normal. Aprovecha para explicar los healthchecks mientras arranca. |
| Permisos en `logs/` (Linux) | `AIRFLOW_UID` mal configurado. En Linux: `echo "AIRFLOW_UID=$(id -u)" >> .env`. En Mac/Windows no suele pasar. |
| Un alumno se ha perdido del todo | `docker compose down -v` y que copie la solución del ejercicio actual. No dejes que arrastre el error al siguiente bloque. |
| Se les llena el disco | `docker system prune`. Avísalo antes del bloque 4. |

La chuleta completa está en
[TEORIA.md § Apéndice B](./TEORIA.md#apéndice-b--cuando-algo-falla). Remite
allí a los alumnos en vez de responder uno por uno.

---

## 5. Si vas justo de tiempo

Recorta en este orden (de lo primero a sacrificar a lo último):

1. **Ejercicio 10 → hazlo tú en proyección.** Es más de leer y entender que
   de descubrir. 15 min ahorrados.
2. **Ejercicio 4 → sáltalo.** El 5 lo cubre y es más útil. 15 min.
3. **Ejercicio 9 → da el YAML completo.** Que solo lo levanten y hagan el
   experimento de parar el `dag-processor`. 10 min.
4. **Ejercicio 3 → demostración en vivo.** Es muy visual, pero se puede
   enseñar sin que lo repliquen todos. 15 min.

**Nunca recortes** los ejercicios 5 (dependencias Python) y 7 (red de
Compose). Son los dos que van a usar en su primer día de trabajo.

## 6. Si te sobra tiempo

- Ejercicio **A** (Adminer) es el mejor relleno: 15 min, muy visual y
  refuerza el concepto de red.
- Ejercicio **D** (`down` vs `down -v`) son 10 min y deja huella.
- Ejercicio **E** (depuración a ciegas) funciona muy bien **por parejas** y
  como cierre alternativo si la clase va sobrada.
- Los ejercicios **B** y **C** son excelentes, pero necesitan 30-40 min:
  mejor como trabajo posterior que como relleno.

---

## 6 bis. La sesión de Kubernetes: plan B si minikube falla

Aunque [REQUISITOS.md](./REQUISITOS.md) obliga a arrancar el cluster **antes**
de clase, cada año hay dos o tres portátiles que no levantan. Ten esto
decidido de antemano, en vez de improvisarlo con la clase parada.

| Síntoma | Qué hacer en el momento |
|---|---|
| `minikube start` se queda colgado | `minikube delete && minikube start --driver=docker`. Si pasa de 3 min, plan B. |
| No hay RAM para los 4 GB | `minikube start --memory=2560 --cpus=2`. Sobra para los ejercicios 1-5. |
| Docker Desktop no arranca (WSL2) | No se arregla en clase. Plan B directo. |
| `ImagePullBackOff` con su propia imagen | No hizo el `docker push`. Que use la de un compañero mientras la sube. |

**El plan B, en orden:**

1. **Emparejar.** Dos alumnos, un portátil. Teclea el que tiene el cluster
   roto y dicta el otro. Funciona mejor de lo que parece y no pierdes a nadie.
2. **Un cluster proyectado.** Tú aplicas los manifiestos que escriben ellos.
   Se pierde el músculo de la terminal, no el concepto.
3. **Terminal en el navegador.** Con wifi decente, un *playground* de
   Kubernetes (Killercoda, Play with Kubernetes) da un cluster real durante
   una hora sin instalar nada. Sirve para los ejercicios 1, 2, 3 y 5; el 4
   depende del *storage class* del entorno.

Decide en los **primeros 20 minutos** — el bloque 0 existe justo para esto —
quién sigue con su cluster y quién pasa a plan B. No dejes a nadie peleándose
con la instalación durante el ejercicio 1.

**Si vas justo de tiempo en Kubernetes**, recorta en este orden: ejercicio 6
(ya está marcado como opcional) → el reto de diagnóstico a ciegas → ejercicio 3
(hazlo en proyección). **Nunca recortes** los ejercicios 4 y 5: la persistencia
y el CronJob son lo único de esta sesión que van a usar tal cual en su trabajo.

---

## 7. Agujeros de conejo que evitar

Estos temas surgirán en preguntas. Responde brevemente y **sigue adelante**;
son de perfil DevOps y no aportan a un Data Engineer en su primera sesión.

| Si preguntan por... | Respuesta corta |
|---|---|
| Kubernetes | "Es el siguiente paso cuando necesitas varios servidores. Compose te sirve para un solo servidor, y eso cubre el 90 % del desarrollo." |
| Multi-stage builds | "Sirve para reducir el tamaño de la imagen. Se ve en el módulo de optimización." |
| Docker vs máquina virtual (a fondo) | Quédate en la tabla de §1. Namespaces y cgroups no aportan hoy. |
| Redes personalizadas / `network_mode` | "Compose crea la red por ti y en el 99 % de los casos es la que quieres." |
| Seguridad, escaneo de imágenes, *hardening* | "Módulo de *Security and Optimization*, fuera del alcance de hoy." Ojo: los **permisos de un bind mount** sí se ven hoy (sección 3), y son otra cosa. |
| Podman / Rancher / alternativas | "Los comandos son casi idénticos. Lo que aprendes hoy te vale." |
| ARM vs x86 (Mac con Apple Silicon) | Hay diapositiva propia en la sección 4. Quédate en `--platform linux/amd64` y sigue. |

---

## 8. Ideas para la evaluación

Opciones alineadas con lo que realmente enseñas:

1. **Entrega práctica (recomendada)**: dar a los alumnos un
   `docker-compose.yml` roto (como el del ejercicio E, con 4-5 fallos) y
   pedirles que lo arreglen y expliquen cada arreglo. Evalúa comprensión
   real, no memorización.
2. **Extensión del proyecto**: añadir un servicio nuevo al stack (Adminer,
   MinIO, Jupyter) y un DAG que lo use.
3. **Pipeline propio**: el ejercicio C con un dataset elegido por ellos.

Evita exámenes tipo test sobre flags de la CLI: eso se busca en la
documentación en 10 segundos y no mide nada.
