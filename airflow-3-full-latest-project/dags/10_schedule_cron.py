from airflow.sdk import dag, task
from pendulum import datetime
from airflow.timetables.trigger import CronTriggerTimetable

@dag(dag_id='cron_schedule_dag',
    start_date=datetime(year=2026, month=1, day=1, tz="Asia/Dubai"),
    end_date=datetime(year=2026, month=1, day=5, tz="Asia/Dubai"),
    schedule=CronTriggerTimetable("0 16 * * 1-5",timezone="Asia/Dubai"),
    is_paused_upon_creation=False,
    catchup=True,
    tags=['samples'])
def cron_schedule_dag():
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


cron_schedule_dag()