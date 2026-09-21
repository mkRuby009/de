from airflow.sdk import dag, task
from pendulum import datetime,duration
from airflow.timetables.trigger import DeltaTriggerTimetable

@dag(dag_id='delta_schedule_dag',
    start_date=datetime(year=2026, month=2, day=1, tz="Asia/Dubai"),
    end_date=datetime(year=2026, month=5, day=31, tz="Asia/Dubai"),
    schedule=DeltaTriggerTimetable(duration(days=7)),
    is_paused_upon_creation=False,
    catchup=True,
    tags=['samples'])
def delta_schedule_dag():
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


delta_schedule_dag()