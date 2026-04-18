from airflow import DAG
from datetime import datetime
from airflow.operators.python import PythonOperator
from airflow.models import Variable
def greet_user():
    name = Variable.get("name")
    print(f"Hello, {name}! This is a Python function.")

def seconed_task():
    print("This is the second task in the DAG.")

def third_task():
    print("This is the third task in the DAG.")

with DAG(
    dag_id="python_dag",
    default_args={
        'owner': 'airflow',
        'retries': 2,
    },
    description='A simple DAG that greets the user',
    tags = ['begginer']

) as dag:
    first_task = PythonOperator(
        task_id='first_task',
        python_callable=greet_user
    )
    second_task = PythonOperator(
        task_id='second_task',
        python_callable=seconed_task
    )
    third_task = PythonOperator(
        task_id='third_task',
        python_callable=third_task
    )
    first_task >> second_task >> third_task