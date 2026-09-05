#!/usr/bin/env bash
#
# Genera todas las salidas de las diapositivas del módulo de contenedores.
#
#   ./construir.sh          → PDF y PPTX de cada sesión + del módulo completo
#
# El markdown es la fuente de verdad. Este script no edita ningún .md a mano:
# el deck combinado (modulo-completo.md) se REGENERA cada vez a partir de los
# cuatro archivos de sesión, así que nunca se queda desincronizado.
#
set -euo pipefail
cd "$(dirname "$0")"

MARP="npx --yes @marp-team/marp-cli@latest"
TEMA="--theme-set tema-pontia.css --html --allow-local-files"

# marp-cli busca soffice en /Applications/LibreOffice.app; si el cask quedó
# solo en el Caskroom (sin symlink en /Applications), se indica aquí.
if [ -z "${SOFFICE_PATH:-}" ] && [ ! -x "/Applications/LibreOffice.app/Contents/MacOS/soffice" ]; then
  CASK_SOFFICE=$(ls /opt/homebrew/Caskroom/libreoffice/*/LibreOffice.app/Contents/MacOS/soffice 2>/dev/null | head -1 || true)
  [ -n "$CASK_SOFFICE" ] && export SOFFICE_PATH="$CASK_SOFFICE"
fi

SESIONES=(
  sesion-0-que-es-docker
  sesion-1-docker-fundamentos
  sesion-2-docker-compose
  sesion-3-kubernetes
)

# ── 1. Construir el deck combinado ──────────────────────────────────────────
# Del primer archivo se conserva todo (incluido su front matter YAML).
# De los siguientes se elimina el front matter y se pega detrás de un "---".

echo "→ Generando modulo-completo.md"
COMBINADO=modulo-completo.md

{
  cat "${SESIONES[0]}.md"

  for s in "${SESIONES[@]:1}"; do
    echo
    echo "---"
    echo
    # Elimina el bloque de front matter: desde el primer "---" hasta el segundo.
    awk 'NR==1 && $0=="---" {en_frontmatter=1; next}
         en_frontmatter && $0=="---" {en_frontmatter=0; next}
         !en_frontmatter {print}' "$s.md"
  done
} > "$COMBINADO"

# ── 2. Exportar cada sesión y el combinado ──────────────────────────────────

for f in "${SESIONES[@]}" modulo-completo; do
  echo "→ $f.pdf"
  $MARP "$f.md" $TEMA --pdf  -o "$f.pdf"
  echo "→ $f.pptx (editable, requiere LibreOffice/soffice)"
  $MARP "$f.md" $TEMA --pptx-editable -o "$f.pptx"
done

echo
echo "Listo."
ls -lh ./*.pdf ./*.pptx
