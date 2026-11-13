# Entrega final: despliegue de una aplicación de datos

## Introducción

En esta entrega pondrás en práctica los conceptos del módulo mediante **dos proyectos**. Primero desplegarás una aplicación de ingeniería de datos con Docker y Docker Compose; después llevarás la misma aplicación a Kubernetes usando minikube.

El material de partida incluirá una aplicación y fallos que tendrás que localizar y corregir. La entrega no consiste solo en conseguir que funcione: también tendrás que registrar cómo avanzaste y explicar las decisiones tomadas y los problemas que resolviste.

## Objetivos

Al terminar los proyectos, deberías poder:

- Construir y ejecutar una imagen propia.
- Desplegar varios servicios que colaboran y comprobar que se comunican.
- Mantener los datos aunque los contenedores o Pods se eliminen y se creen de nuevo.
- Diagnosticar fallos a partir del estado del sistema y de sus logs.
- Documentar un despliegue para que otra persona pueda reproducirlo.

## Aplicación

Trabajarás con una aplicación de datos proporcionada por el docente. Como referencia, el sistema representa un flujo sencillo de ingesta: lee datos de un fichero, los procesa, los guarda en PostgreSQL y permite consultarlos mediante una API.

El docente facilitará el código de partida y los archivos iniciales necesarios para cada proyecto. Parte de la configuración tendrá problemas intencionados. No se indicará dónde están: deberás observar el comportamiento, investigar la causa y corregirlos.

---

## Proyecto 1: Docker y Docker Compose

### Objetivo

Construir y desplegar la aplicación en contenedores, primero de forma aislada y luego como un conjunto de servicios que colaboran.

### Fases de trabajo

1. **Explora el material.** Lee el código y los archivos entregados. Identifica qué componentes forman la aplicación y qué función cumple cada uno.
2. **Trabaja con contenedores.** Ejecuta los comandos indicados en el enunciado, comprueba el estado de los contenedores y revisa sus logs. Observa qué ocurre con los datos al eliminar un contenedor.
3. **Construye la imagen de la aplicación.** Completa o revisa el Dockerfile, construye la imagen y ejecútala para comprobar que el programa realiza su tarea.
4. **Despliega la aplicación con Compose.** Levanta los servicios necesarios —por ejemplo, el proceso de ingesta, PostgreSQL y la API— y verifica que se comunican correctamente.
5. **Diagnostica y corrige los problemas.** Investiga los fallos que encuentres. Anota el síntoma, cómo llegaste a la causa y qué cambio aplicaste.
6. **Comprueba la persistencia.** Detén y vuelve a levantar la aplicación. Verifica que los datos almacenados siguen disponibles.

### Resultado esperado

La aplicación debe poder iniciarse siguiendo tus instrucciones, procesar datos, guardarlos en PostgreSQL y permitir consultarlos. Los datos deben conservarse al detener y volver a levantar el stack, siempre que no se solicite explícitamente borrar el almacenamiento.

---

## Proyecto 2: Kubernetes

### Objetivo

Desplegar la aplicación en un clúster local de Kubernetes y comprobar cómo Kubernetes mantiene los componentes en el estado esperado.

### Fases de trabajo

1. **Prepara minikube.** Inicia el clúster y comprueba que está disponible.
2. **Prepara la aplicación.** Reutiliza la imagen construida en el Proyecto 1 y confirma que minikube puede acceder a ella.
3. **Despliega la base de datos.** Configura PostgreSQL con almacenamiento persistente y proporciona la configuración y las credenciales por separado.
4. **Despliega la aplicación y la API.** Aplica los manifiestos necesarios, expón la API y comprueba que puedes consultar los datos.
5. **Programa la ingesta.** Despliega un proceso periódico que cargue datos y verifica sus ejecuciones.
6. **Diagnostica y corrige los problemas.** Revisa el estado de los recursos y sus logs para encontrar y solucionar los fallos incluidos en el material.
7. **Comprueba la recuperación y la persistencia.** Elimina un Pod de la aplicación y comprueba que se recupera. Elimina y recrea el Pod de PostgreSQL y verifica que los datos siguen disponibles.

### Resultado esperado

La aplicación debe funcionar de extremo a extremo en minikube: el proceso periódico escribe datos, PostgreSQL los conserva y la API permite consultarlos. Los componentes administrados deben recuperarse si se elimina uno de sus Pods, sin perder los datos persistidos.

---

## Registro del trabajo

Mantén un **repositorio de GitHub** con los archivos de los dos proyectos. Registra el trabajo progresivamente mediante commits descriptivos; el historial debe reflejar las distintas fases y correcciones.

Para cada paso importante, anota:

- Qué comando o acción realizaste.
- Qué resultado obtuviste.
- Qué intentabas comprobar o conseguir.
- Por qué elegiste ese procedimiento.

Para cada fallo que resuelvas, documenta:

- El síntoma observado.
- Cómo lo investigaste (por ejemplo, qué estado o logs consultaste).
- La causa que encontraste.
- El cambio que aplicaste y por qué lo resuelve.

Puedes guardar esta información en el README o en archivos Markdown separados, siempre que esté ordenada y sea fácil de seguir. Si no puedes incluir una salida de terminal de forma legible en el repositorio, adjunta un PDF con capturas en las que se vean claramente el comando y su resultado.

## Entrega

El repositorio debe incluir, como mínimo:

- Los archivos finales de Docker y Compose, el código de la aplicación y los manifiestos de Kubernetes.
- Instrucciones para preparar el entorno y reproducir cada despliegue.
- El registro de comandos y resultados, o las evidencias en PDF cuando sea necesario.
- La explicación de los pasos y el registro de los fallos encontrados y corregidos.

No incluyas contraseñas reales, tokens ni otros secretos en el repositorio. Usa los mecanismos de configuración previstos y, si hace falta, proporciona un ejemplo sin credenciales reales.

La entrega se realizará por el medio y en la fecha que indique el docente. Incluye la URL del repositorio y comprueba que el docente puede acceder a él.

## Criterios de evaluación

Se valorará:

- Que cada aplicación quede desplegada y que las pruebas de funcionamiento y persistencia se completen.
- Que identifiques y corrijas los problemas incluidos en el material.
- Que expliques las causas y justifiques tus decisiones, en lugar de limitarte a copiar comandos o probar cambios al azar.
- Que el repositorio esté ordenado y otra persona pueda reproducir los pasos.
- Que el historial de Git muestre el proceso de trabajo.

La evaluación es **práctica y basada en los dos proyectos**. No habrá preguntas tipo test sobre sintaxis de comandos: puedes consultar la documentación; lo importante es que comprendas y puedas explicar lo que haces.
