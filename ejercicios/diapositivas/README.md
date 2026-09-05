# Diapositivas del módulo de contenedores

Presentaciones en Markdown ([Marp](https://marp.app/)) con la estética del
Máster PontIA, replicada a partir del PDF de referencia
*"2026-08 PontIA — Máster DE — Módulo Linux y terminal"*.

---

## Archivos

### Fuentes (edita estas)

| Archivo | Contenido | Diapositivas |
|---|---|---|
| `tema-pontia.css` | Tema visual: paleta, tipografía, componentes | — |
| `sesion-0-que-es-docker.md` | Módulo 0 — ¿Qué es Docker? Contexto e historia (30 min) | 29 |
| `sesion-1-docker-fundamentos.md` | Sesión 1 — Imágenes y contenedores (2 h 40) | 44 |
| `sesion-2-docker-compose.md` | Sesión 2 — Docker Compose (2 h 20) | 37 |
| `sesion-3-kubernetes.md` | Sesión 3 — Kubernetes (2 h 30) | 54 |

El **módulo 0 no tiene ejercicios**: es el bloque de contexto que responde a
*¿qué problema resuelve Docker y de dónde sale?*, y enlaza directamente con la
sesión 1, que empieza justo donde él termina.

### Generados (no los edites)

| Archivo | Qué es |
|---|---|
| `modulo-completo.md` | Las cuatro sesiones concatenadas. Lo **regenera** `construir.sh` |
| `*.pdf` / `*.pptx` | Las salidas de cada sesión y del módulo completo |

El **markdown de sesión es la fuente de verdad**. Si cambias algo, edita el
`sesion-N-*.md` y ejecuta `./construir.sh`; no edites `modulo-completo.md`,
ni el PDF, ni el PPTX a mano.

---

## Cómo verlas

### En VS Code (recomendado mientras editas)

Instala la extensión **Marp for VS Code** (`marp-team.marp-vscode`) y abre el
`.md`. El panel de vista previa se actualiza al escribir.

### Exportar

Un solo comando regenera el deck combinado y las diez salidas:

```bash
cd ejercicios/diapositivas
./construir.sh
```

El script hace dos cosas:

1. **Construye `modulo-completo.md`** concatenando las cuatro sesiones. Conserva
   el *front matter* de la primera y elimina el de las demás, que si no rompe
   el YAML.
2. **Exporta** PDF y PPTX de cada sesión y del módulo completo.

Si solo quieres una sesión suelta:

```bash
npx @marp-team/marp-cli@latest sesion-1-docker-fundamentos.md \
  --theme-set tema-pontia.css --html --allow-local-files \
  --pdf -o sesion-1-docker-fundamentos.pdf
```

Y el HTML, si quieres presentar desde el navegador sin instalar nada:

```bash
npx @marp-team/marp-cli@latest modulo-completo.md \
  --theme-set tema-pontia.css --html -o modulo-completo.html
```

### Sobre el PPTX

Los `.pptx` se generan con `--pptx-editable`: texto y formas reales, editables
desde PowerPoint o Keynote. Requiere **LibreOffice** instalado (aporta el
binario `soffice`, que Marp usa por debajo para la conversión).

```bash
brew install --cask libreoffice
```

Si el cask se instala pero `soffice` no aparece en `/Applications/LibreOffice.app`
(por ejemplo si solo queda en el Caskroom), `construir.sh` lo detecta solo y
exporta `SOFFICE_PATH` automáticamente. También puedes fijarlo a mano:

```bash
export SOFFICE_PATH="/opt/homebrew/Caskroom/libreoffice/*/LibreOffice.app/Contents/MacOS/soffice"
```

Es una función **experimental** de Marp: el traspaso de CSS a formas de
PowerPoint no siempre es exacto (fuentes, sombras, algunos diagramas ASCII).
Revisa el resultado abriéndolo antes de repartirlo. La alternativa `--pptx`
(sin LibreOffice) genera un `.pptx` real pero con cada diapositiva como
imagen: fiel al diseño, no editable.

---

## Paleta

Extraída píxel a píxel del PDF de referencia.

| Uso | Hex |
|---|---|
| Fondo lima (diapositiva destacada) | `#F6FAB2` |
| Verde oscuro (divisor de sección) | `#163932` |
| Azul marino (ejercicio) | `#111E2D` |
| Fondo de bloque de terminal | `#0A111A` |
| Amarillo de acento | `#D8EA7C` |
| Texto principal | `#16181A` |

---

## Componentes del tema

Se aplican con `<!-- _class: nombre -->` en la línea anterior al título,
o con `<div class="nombre">` dentro del cuerpo.

### Fondos de diapositiva

| Clase | Uso |
|---|---|
| `portada` | Primera diapositiva, fondo lima, título grande |
| `seccion` | Divisor de bloque, fondo verde, número en círculo |
| `lima` | Diapositiva destacada, fondo amarillo |
| `verde` | Fondo verde oscuro |
| `navy` / `reto` | Diapositiva de ejercicio, fondo azul marino |
| `denso` | Reduce el tamaño de fuente para tablas largas |
| `arriba` | Contenido pegado arriba en vez de centrado |

### Bloques

```html
<div class="cols">…</div>        <!-- dos columnas iguales -->
<div class="cols-58">…</div>     <!-- dos columnas, la izquierda más ancha -->
<div class="cols-3">…</div>      <!-- tres columnas -->

<div class="pasos">              <!-- lista numerada 01 / 02 / 03 -->
  <div><b>01</b><span>Texto</span></div>
</div>

<div class="destacado">Frase grande centrada</div>
<div class="aviso">Caja de advertencia con filete lateral</div>
<div class="num">3</div>         <!-- número en círculo, solo en .seccion -->

<span class="pill">15 min</span> <!-- etiqueta redondeada -->

<pre class="diagrama">…</pre>    <!-- diagrama ASCII sin barra de ventana -->
```

Los bloques ` ```bash ` normales se pintan como una ventana de terminal con
los tres puntos de macOS, igual que en la plantilla de referencia.

---

## Correspondencia con el resto de la documentación

| Diapositivas | Fuente de contenido |
|---|---|
| Sesión 1 | `TEORIA.md` §1–§6 · `EJERCICIOS.md` ejercicios 1–5 y 5 bis |
| Sesión 2 | `TEORIA.md` §7–§11 · `EJERCICIOS.md` ejercicios 6–10 |
| Sesión 3 | `TEORIA_KUBERNETES.md` §1–§11 · `EJERCICIOS_KUBERNETES.md` |

El reparto de sesiones y sus duraciones están definidos en
`INFO_PARA_DIRECTOR.md`.
