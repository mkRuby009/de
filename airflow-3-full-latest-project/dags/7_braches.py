from airflow.sdk import dag, task

@dag(dag_id='branch_dag',
    schedule=None, 
    tags=['samples'])
def branch_dag():
    @task.python
    def extract_task(**kwargs):
        print("extracting the data ..")
        ti = kwargs['ti']
        extracted_data_dict = {"api_extracted_data": [1, 2, 3, 4, 5],
                               "db_extracted_data": [6, 7, 8, 9, 10],
                               "s3_extracted_data": [11, 12, 13, 14, 15],
                               "weekend_flag": "false"}

        ti.xcom_push(key='return_value', value=extracted_data_dict)

    @task.python
    def transform_task_api(**kwargs):
        ti = kwargs['ti']
        api_extracted_data = ti.xcom_pull(task_ids='extract_task',key='return_value')['api_extracted_data']
        print(f"transforming API data: {api_extracted_data}")
        transformed_data = [x*10 for x in api_extracted_data]
        ti.xcom_push(key='return_value', value=transformed_data)

    @task.python
    def transform_task_db(**kwargs):
        ti = kwargs['ti']
        db_extracted_data = ti.xcom_pull(task_ids='extract_task')['db_extracted_data']
        print(f"transforming DB data: {db_extracted_data}")
        transformed_data = [x*20 for x in db_extracted_data]
        ti.xcom_push(key='return_value', value=transformed_data)

    @task.python
    def transform_task_s3(**kwargs):
        ti = kwargs['ti']
        s3_extracted_data = ti.xcom_pull(task_ids='extract_task')['s3_extracted_data']
        print(f"transforming S3 data: {s3_extracted_data}")
        transformed_data = [x*30 for x in s3_extracted_data]
        ti.xcom_push(key='return_value', value=transformed_data)
    
    @task.branch
    def decider_task(**kwargs):
        ti = kwargs['ti']
        extracted_data = ti.xcom_pull(task_ids='extract_task')['weekend_flag']
        if extracted_data == "true":
            return 'no_load_task'
        else:
            return 'load_task'
    
    @task.bash
    def no_load_task(**kwargs):
        print("no loading on the weekends...")
        return "echo 'no task executed'"

    @task.bash
    def load_task(**kwargs):
        api_data = kwargs['ti'].xcom_pull(task_ids='transform_task_api')
        db_data = kwargs['ti'].xcom_pull(task_ids='transform_task_db')
        s3_data = kwargs['ti'].xcom_pull(task_ids='transform_task_s3')
        return f" echo 'loaded data: {api_data}, {db_data}, {s3_data}'"

    #defining the tasks
    extract = extract_task()
    transform_api = transform_task_api()
    transform_db = transform_task_db()
    transform_s3 = transform_task_s3()
    load = load_task()
    no_load = no_load_task()

    #defining the task dependencies
    extract >> [transform_api, transform_db, transform_s3] >> decider_task() >> [load, no_load]

branch_dag()