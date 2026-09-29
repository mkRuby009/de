from airflow.sdk import dag, task
import os
import pendulum

DATA_PATH = "/opt/airflow/logs/data/orchestrator_data_2.txt"

@dag(dag_id='second_orchestrator_dag',
    schedule=None, 
    tags=['samples'])
def second_orchestrator_dag():
    @task.python
    def first_task():
        print("first task")
    
    @task.python
    def second_task():
        print("second task")

    @task.python
    def third_task():
        uri = DATA_PATH
        os.makedirs(os.path.dirname(uri), exist_ok=True)
        with open(uri,"w") as file:
            file.write(f"Data fetched successfully at {pendulum.now('Asia/Dubai')}\n")

    first = first_task()
    second = second_task()
    third = third_task()    

    first >> second >> third


second_orchestrator_dag()