from airflow.decorators import dag, task
from airflow.operators.python import PythonOperator
from datetime import datetime

@dag(dag_id="new_syntax_dag")

def welcome_dag():
    @task
    def greet_user():
        print("Hello from a Python function!")
        return "@@@@@@@@@abc@@@@@@@@@@@@@@@@@@@@@@@"

    @task
    def second_task( name ):
        print("This is the second task in the DAG.")
        print(name)

    @task
    def third_task():
        print("This is the third task in the DAG.")
    
    t1 = greet_user()
    t2 = second_task(t1)
    t3 = third_task()

    t1 >> t2 >> t3

dag = welcome_dag()