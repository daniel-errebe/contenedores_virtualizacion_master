# Contenedores y Virtualización (Docker y Kubernetes)

Material del módulo. El hilo conductor es una aplicación de datos real,
**Apache Airflow 3 + PostgreSQL**, que empezamos ejecutando en un contenedor y
acabamos desplegando en un cluster de Kubernetes.

---

## 1. Antes de la primera clase

1. Sigue **[ejercicios/REQUISITOS.md](ejercicios/REQUISITOS.md)** hasta el final,
   incluida la verificación. Necesitas Docker (con Compose), una cuenta de
   Docker Hub con `docker login` hecho, Git, un editor de código y minikube con
   kubectl.
2. Mira los vídeos de teoría de cada sesión **antes** de la clase (ver tabla).

Si algo falla, escribe al profesor **con varios días de antelación**, indicando
tu sistema operativo, el comando que ejecutaste y el error completo.

## 2. Calendario

| Fecha | Sesión | Vídeos previos | Teoría | Ejercicios |
|---|---|---|---|---|
| **24 de noviembre** | Docker | Bienvenida → 5.3 | [TEORIA.md](ejercicios/TEORIA.md) §1–§6 | [EJERCICIOS.md](ejercicios/EJERCICIOS.md) 1–5 y 5 bis |
| **26 de noviembre** | Docker Compose | 6 → 7.3 | [TEORIA.md](ejercicios/TEORIA.md) §7–§11 | [EJERCICIOS.md](ejercicios/EJERCICIOS.md) 6–10 |
| **1 de diciembre** | Kubernetes | 8 → 8.10 | [TEORIA_KUBERNETES.md](ejercicios/TEORIA_KUBERNETES.md) | [EJERCICIOS_KUBERNETES.md](ejercicios/EJERCICIOS_KUBERNETES.md) |

## 3. Qué hay en esta carpeta

```
contenido_alumnos/
├── README.md                  ← estás aquí
├── docker-compose.yml         ← stack real de Airflow 3 + PostgreSQL
├── .env                       ← versiones, puertos y credenciales LOCALES de clase
├── dags/                      ← DAGs de Airflow
├── plugins/                   ← plugins de Airflow
├── logs/                      ← logs de Airflow (se generan solos)
├── ejercicios/
│   ├── REQUISITOS.md          ← instalación del entorno (empieza por aquí)
│   ├── TEORIA.md              ← teoría de Docker y Docker Compose
│   ├── EJERCICIOS.md          ← ejercicios de clase de Docker y Compose
│   ├── EJERCICIOS_EXTRA.md    ← ejercicios de ampliación
│   ├── TEORIA_KUBERNETES.md   ← teoría de Kubernetes
│   ├── EJERCICIOS_KUBERNETES.md ← ejercicios de clase de Kubernetes
│   ├── PROYECTO_FINAL_MORTAL.md ← proyecto de práctica de todo el módulo, por niveles
│   └── sandbox/               ← tu espacio de trabajo para los ejercicios
├── apuntes/                   ← apuntes de cada sesión (PDF)
├── diapositivas/              ← diapositivas del módulo (PDF)
└── evaluacion/
    ├── ENTREGA_FINAL.md       ← enunciado de los dos proyectos evaluables
    └── Guion_Entrega_Final_Contenedores.docx
```

| Material | Para qué |
|---|---|
| [Apuntes](apuntes/) | Resumen de cada sesión, para repasar. |
| [Diapositivas](diapositivas/) | Las que se usan en clase. |
| [Teoría](ejercicios/TEORIA.md) | Explicación completa, con chuleta de comandos y tabla de problemas frecuentes. |
| [Ejercicios](ejercicios/EJERCICIOS.md) | Lo que haremos en clase, con soluciones ocultas. |
| [Proyecto Final Mortal](ejercicios/PROYECTO_FINAL_MORTAL.md) | Repaso de todo el módulo en 16 niveles, para hacer en casa. |
| [Entrega final](evaluacion/ENTREGA_FINAL.md) | Enunciado de los proyectos de Docker/Compose y Kubernetes, sus entregables y criterios de evaluación. |

## 4. El proyecto de Airflow

Esta carpeta es, en sí misma, un proyecto de Airflow funcionando. Sirve como
referencia de "a dónde llegamos": en los ejercicios lo reconstruimos paso a
paso dentro de `ejercicios/sandbox/` (puerto **8088**), sin tocar este
(puerto **8080**).

| Servicio | Función |
|---|---|
| `postgres` | Base de datos de metadatos |
| `airflow-init` | Contenedor de un solo uso: prepara la base de datos y termina |
| `airflow-api-server` | API y web, en http://localhost:8080 |
| `airflow-scheduler` | Planifica y lanza las tareas |
| `airflow-dag-processor` | Lee los ficheros de DAGs |
| `airflow-triggerer` | Ejecuta las tareas asíncronas |

```bash
cd contenido_alumnos

docker compose up -d                        # arrancar todo en segundo plano
docker compose ps                           # esperar a que estén (healthy)
docker compose logs -f airflow-scheduler    # ver logs de un servicio
docker compose down                         # parar (conserva los datos)
docker compose down -v                      # parar y BORRAR los datos
```

Cuando `airflow-api-server` aparezca como `(healthy)`, abre
http://localhost:8080. Cualquier usuario y contraseña te dan acceso como
administrador: es cómodo para clase, pero **solo es apropiado en local**.

Las versiones, puertos y credenciales están en [.env](.env). Son valores de
ejemplo para un entorno local de clase: nunca los reutilices en un entorno
real. En Linux, pon en `AIRFLOW_UID` tu id de usuario (`id -u`) para que los
ficheros de `dags/`, `logs/` y `plugins/` sean tuyos y no de root.

## 5. Dudas

Usa el canal de la asignatura: así la respuesta sirve a todo el grupo.
