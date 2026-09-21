from airflow.sdk import dag, task
from pendulum import datetime
from airflow.timetables.interval import CronDataIntervalTimetable

@dag(
    schedule=CronDataIntervalTimetable("@daily",timezone="Asia/Dubai"),
    start_date=datetime(year=2026, month=6, day=1, tz="Asia/Dubai"),
    end_date=datetime(year=2026, month=6, day=5, tz="Asia/Dubai"),
    catchup=True
)
def incremental_load_dag():
    @task.python
    def incremental_data_fetch(**kwargs):
        date_interval_start = kwargs['data_interval_start']
        date_interval_end = kwargs['data_interval_end']
        print(f"fetching data from {date_interval_start} to {date_interval_end}")
    
    #data_interval_start and data_interval_end are automatically rendered to the bash operators
    @task.bash
    def incremental_data_process():
        return "echo 'processing incremental data from " \
        "{{data_interval_start}} to {{data_interval_end}}'"

    fetch_task = incremental_data_fetch()
    process_task = incremental_data_process()

    fetch_task >> process_task

incremental_load_dag()
