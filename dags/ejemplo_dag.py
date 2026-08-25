from datetime import datetime

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

with DAG(
    dag_id="hola_data_engineer",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["ejemplo", "master-containerizacion"],
) as dag:

    tarea_hola = BashOperator(
        task_id="imprimir_saludo",
        bash_command='echo "¡Airflow 3 corriendo sobre Docker con Postgres!"',
    )