
from airflow.sdk import dag, task

@dag(dag_id='dag_versioning',
    schedule=None, 
    tags=['samples'])
def versioned_dag():
    @task.python
    def first_task():
        print("first task")
    
    @task.python
    def second_task():
        print("second task")

    @task.python
    def third_task():
        print("third task")

    @task.python
    def version_task():
        print("version task")
    first = first_task()
    second = second_task()
    third = third_task()
    version= version_task()

    first >> second >> third >> version


versioned_dag()