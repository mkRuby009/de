from airflow.sdk import dag, task

@dag(dag_id='xcoms_dag_manual',
    schedule=None, 
    tags=['samples'])
def xcoms_dag_manual():
    @task.python
    def first_task(**kwargs):

        # extracting TI from kwargs to push to xcom manually
        ti = kwargs['ti']
        print("Extracting the data .. this is a first task")
        fetched_data = {"data": [1, 2, 3, 4, 5]}
        ti.xcom_push(key='returned_result', value=fetched_data)
    
    @task.python
    def second_task(**kwargs):
        ti = kwargs['ti']
        fetched_data = ti.xcom_pull(task_ids='first_task', key='returned_result')['data']
        transformed_data = [x*2 for x in fetched_data]
        transformed_data_dict = {"trans_data": transformed_data}
        ti.xcom_push(key='transformed_result', value=transformed_data_dict)
    
    @task.python
    def third_task(**kwargs):
        load_data = kwargs['ti'].xcom_pull(task_ids='second_task', key='transformed_result')
        return load_data


    first = first_task()
    second = second_task()
    third = third_task()
    #print(third)

    first >> second >> third

xcoms_dag_manual()