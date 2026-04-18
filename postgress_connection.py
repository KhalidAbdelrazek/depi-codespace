from airflow import DAG
from datetime import datetime
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

def fetch_data_from_postgres():
    # Create a PostgresHook instance
    postgres_hook = PostgresHook(
        postgres_conn_id='my_postgres_connection',  # Connection ID defined in Airflow
        schema='my_database'  # Database name
    )
    conn = postgres_hook.get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM my_table;")  # Replace with your query
    results = cursor.fetchall()
    print(results)  # Print the results or process them as needed
    conn.close()
    
with DAG(
    dag_id="postgres_connection_dag",
    start_date=datetime(2024, 1, 1),
    schedule='0 0 * * *',
    catchup=False
) as dag:
    fetch_data_task = BashOperator(
        task_id='fetch_data_from_postgres',
        bash_command='python -c "from postgress_connection import fetch_data_from_postgres; fetch_data_from_postgres()"'
    )