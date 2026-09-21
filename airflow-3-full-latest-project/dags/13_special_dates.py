from airflow.sdk import dag, task
from pendulum import datetime
from airflow.timetables.events import EventsTimetable

special_dates = EventsTimetable(event_dates=
[
    datetime(year=2026, month=5, day=1),
    datetime(year=2026, month=5, day=15),
    datetime(year=2026, month=5, day=26),
    datetime(year=2026, month=5, day=30),
])

@dag(
    schedule=special_dates,
    start_date=datetime(year=2026, month=5, day=1, tz="Asia/Dubai"),
    end_date=datetime(year=2026, month=5, day=31, tz="Asia/Dubai"),
    catchup=True
)
def special_dates_dag():
    @task.python
    def special_events_task(**kwargs):
        execution_date = kwargs['logical_date']
        print(f"Running task for a special event on {execution_date}")
    
    special_event = special_events_task()

special_dates_dag()