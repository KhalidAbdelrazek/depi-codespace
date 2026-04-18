from airflow import DAG
from datetime import datetime
from airflow.operators.python import PythonOperator

def push_xcom(**kwargs):
    kwargs['ti'].xcom_push(key='my_key', value='Hello from XCom!')

def pull_xcom(**kwargs):
    value = kwargs['ti'].xcom_pull(key='my_key', task_ids='push_xcom')
    print(f"Pulled value from XCom: {value}")

with DAG(
    dag_id="xcom_example_dag",
    start_date=datetime(2024, 1, 1),
    schedule='0 0 * * *',
    catchup=False
) as dag:
    push_xcom_task = PythonOperator(
        task_id='push_xcom',
        python_callable=push_xcom,
    )
    
    pull_xcom_task = PythonOperator(
        task_id='pull_xcom',
        python_callable=pull_xcom,
    )
    
    push_xcom_task >> pull_xcom_task