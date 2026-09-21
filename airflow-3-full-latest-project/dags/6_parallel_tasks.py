from airflow.sdk import dag, task

@dag(dag_id='parallel_dag',
    schedule=None, 
    tags=['samples'])
def parallel_dag():
    @task.python
    def extract_task(**kwargs):
        print("extracting the data ..")
        ti = kwargs['ti']
        extracted_data_dict = {"api_extracted_data": [1, 2, 3, 4, 5],
                               "db_extracted_data": [6, 7, 8, 9, 10],
                               "s3_extracted_data": [11, 12, 13, 14, 15]}

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

    #defining the task dependencies
    extract >> [transform_api, transform_db, transform_s3] >> load

parallel_dag()