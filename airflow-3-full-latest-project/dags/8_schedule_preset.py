from airflow.sdk import dag, task
from pendulum import datetime


@dag(dag_id='1st_scheduled_dag',
    start_date=datetime(year=2026, month=1, day=1, tz="Asia/Dubai"),
    schedule='@daily',
    is_paused_upon_creation=False,
    tags=['samples'])
def first_scheduled_dag():
    @task.python
    def first_task():
        print("first task")
    
    @task.python
    def second_task():
        print("second task")

    @task.python
    def third_task():
        print("third task")

    first = first_task()
    second = second_task()
    third = third_task()    

    first >> second >> third


first_scheduled_dag()