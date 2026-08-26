# Entorno para las prácticas

Con solo 2h30 en directo, evita que la clase se pierda instalando `minikube`/`kind` en portátiles distintos. Usa un sandbox en el navegador.

## Opciones recomendadas (sin instalación)

- **Killercoda** (killercoda.com/playgrounds) — playgrounds de Kubernetes gratuitos en el navegador, arrancan en segundos.
- **KodeKloud Playgrounds** (kodekloud.com/studio/playgrounds) — cluster de un solo nodo, listo para usar, buena opción si el máster ya usa KodeKloud para los vídeos de referencia.

## Evitar

- **Play with Kubernetes** (labs.play-with-k8s.com) — el propio sitio avisa de que **deja de estar disponible a partir del 1 de marzo de 2026**. No lo uses como entorno base del máster.

## Si prefieres un cluster local (backup)

- `kind` (Kubernetes in Docker) — como ya tienen Docker instalado del bloque anterior, es la opción local más coherente: usa Docker para simular los nodos.
- `minikube` — alternativa igual de válida, un poco más pesada.

Recomendación: pide a los alumnos que **prueben el acceso al playground elegido 1-2 días antes**, no el mismo día de la sesión — así el bloque de "10-25 min: verificar acceso" del guion de ejercicios es solo una confirmación, no una sesión de soporte técnico improvisada.
