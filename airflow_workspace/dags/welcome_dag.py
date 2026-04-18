from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

with DAG("welcome_to_airflow", start_date=datetime(2025, 1, 1), schedule="@daily", catchup=False) as dag:
    task = PythonOperator(
        task_id="hello_task", 
        python_callable=lambda: print("Airflow is live!")
    )
