from airflow.sdk import dag, task
from airflow.providers.standard.operators.bash import BashOperator

@dag(dag_id='operators_dag',
    schedule=None, 
    tags=['samples'])
def operators_dag():
    @task.python
    def first_task():
        print("first task")
    
    @task.python
    def second_task():
        print("second task")

    @task.bash
    def bash_task():
        return "echo https://airflow.apache.org"

    bask_task_old_school = BashOperator(
    task_id="run_after_loop",
    bash_command="echo https://airflow.apache.org/",
    )

    first = first_task()
    second = second_task()  
    bash_job = bash_task()

    first >> second >> bash_job >> bask_task_old_school


operators_dag()