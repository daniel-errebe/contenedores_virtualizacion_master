# Airflow 3 + PostgreSQL — Local Docker Compose Stack

Local Apache Airflow environment used for the containerization / data
engineering master classes. Runs Airflow 3.3.1 (Python 3.14) with a
PostgreSQL 18 metadata database, split into its real production-like
components instead of a single "standalone" container.

## Architecture

| Service                 | Role                                                              |
|--------------------------|--------------------------------------------------------------------|
| `postgres`               | Metadata database                                                  |
| `airflow-init`           | One-off container: runs `airflow db migrate`, then exits           |
| `airflow-api-server`     | REST API + Web UI, exposed at http://localhost:8080                |
| `airflow-scheduler`      | Schedules DAG runs and queues task instances (LocalExecutor)        |
| `airflow-dag-processor`  | Parses DAG files (mandatory, separate component since Airflow 3)    |
| `airflow-triggerer`      | Runs deferrable ("async") tasks                                    |

No Celery/Redis is used — `LocalExecutor` runs tasks as subprocesses of the
scheduler, which is enough for a single-machine classroom setup.

## Requirements

- Docker and Docker Compose v2 (`docker compose version`)
- ~4 GB of RAM available to Docker

## Usage

```bash
# Start everything in the background
docker compose up -d

# Watch containers become healthy
docker compose ps

# Follow logs for a specific service
docker compose logs -f airflow-scheduler

# Stop the stack (keeps the Postgres volume/data)
docker compose down

# Stop and wipe all data (fresh start)
docker compose down -v
```

Once `airflow-api-server` reports `(healthy)`, open http://localhost:8080.
Authentication uses Airflow's **simple auth manager** with
`AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=true`, so any username/password
you type logs you in as admin. This is convenient for class but is only
appropriate for an isolated local environment — see the comments in
[docker-compose.yml](docker-compose.yml) for how to configure named users
instead.

## Project layout

```
dags/        # Your DAG files (mounted into every Airflow container)
logs/        # Task logs written by Airflow (git-ignored)
plugins/     # Custom operators/hooks/plugins (mounted into every container)
ejercicios/  # Teaching material (theory + exercises) — see below
.env         # Image versions, ports and Postgres credentials
```

## Teaching material

The `ejercicios/` folder contains the full 5-hour classroom session (in
Spanish), built around this exact stack:

| File | Audience | Content |
|---|---|---|
| [ejercicios/TEORIA.md](ejercicios/TEORIA.md) | Students | Theory: containers, images, Dockerfile, Compose, networking, volumes. Includes a command cheat-sheet and a troubleshooting table. |
| [ejercicios/EJERCICIOS.md](ejercicios/EJERCICIOS.md) | Students | 10 core exercises (~3 h 10 min of hands-on) that rebuild this project from scratch. |
| [ejercicios/EJERCICIOS_EXTRA.md](ejercicios/EJERCICIOS_EXTRA.md) | Students | 9 optional exercises for extra time or homework. |
| [ejercicios/GUIA_PROFESOR.md](ejercicios/GUIA_PROFESOR.md) | Instructor | Minute-by-minute schedule, pre-class checklist, common classroom problems, what to cut when running late. |

Students work in `ejercicios/sandbox/` on port **8088**, so the exercises
never conflict with this project running on port 8080.

## Customizing

All tunables (image tag, ports, Postgres credentials, host UID) live in
[.env](.env). Edit that file rather than the compose file for day-to-day
changes.

On Linux, set `AIRFLOW_UID` in `.env` to your host user id (`id -u`) so files
written under `./dags`, `./logs` and `./plugins` are owned by you instead of
root.
