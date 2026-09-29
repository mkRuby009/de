from airflow.sdk import dag, task, asset
import pendulum
import os

DATA_PATH = "/opt/airflow/logs/data/data_extract.txt"
@asset(schedule="@daily",
    #optional but good to include for clearity about the asset's location
    uri=DATA_PATH,
    name="fetch_data"
)
def fetch_data(self, context):
    uri = DATA_PATH
    os.makedirs(os.path.dirname(uri), exist_ok=True)
    with open(uri,"w") as file:
        file.write(f"Data fetched successfully at {pendulum.now('Asia/Dubai')}\n")
    
    print(f"Data is written to {self.uri}")
    print(f"context type: {type(context)}")
    print(f"context attrs: {dir(context)}")
    print(f"CWD: {os.getcwd()}")
    print(f"logs dir exists: {os.path.exists('/opt/airflow/logs')}")
    print(f"logs dir writable: {os.access('/opt/airflow/logs', os.W_OK)}")
    