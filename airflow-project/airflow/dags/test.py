from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'simple_test_dag',
    default_args=default_args,
    description='A simple test DAG for demonstration',
    schedule_interval=timedelta(days=1),  # Run daily
    catchup=False,
    tags=['test', 'demo'],
)

# Define a simple Python function
def print_hello():
    print("Hello from Airflow!")
    return "Hello World!"

def print_goodbye():
    print("Goodbye from Airflow!")
    return "Goodbye World!"

# Task 1: Print hello message
hello_task = PythonOperator(
    task_id='print_hello',
    python_callable=print_hello,
    dag=dag,
)

# Task 2: Print current date
date_task = BashOperator(
    task_id='print_date',
    bash_command='date',
    dag=dag,
)

# Task 3: Print goodbye message
goodbye_task = PythonOperator(
    task_id='print_goodbye',
    python_callable=print_goodbye,
    dag=dag,
)

# Set task dependencies
hello_task >> date_task >> goodbye_task
