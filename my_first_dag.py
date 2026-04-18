from airflow import DAG
from datetime import datetime
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="welcome_to_airflow",
    start_date= None,
    schedule='0 0 * * *',
    catchup=False
) as dag:
    hello_world = BashOperator(
        task_id='hello_world',
        bash_command='echo "Hello World!"'
    )