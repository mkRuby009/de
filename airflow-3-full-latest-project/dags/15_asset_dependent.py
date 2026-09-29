from airflow.sdk import dag, task, asset
import pendulum
import os
from asset_export import fetch_data

DATA_PATH = "/opt/airflow/logs/data/data_processed.txt"
@asset(schedule=fetch_data,
    #optional but good to include for clearity about the asset's location
    uri=DATA_PATH,
    name="process_data"
)
def process_data(self, context):
    uri = DATA_PATH
    os.makedirs(os.path.dirname(uri), exist_ok=True)
    with open(uri,"w") as file:
        file.write(f"Data processed successfully at {pendulum.now('Asia/Dubai')}\n")
    
    print(f"Data is written to {self.uri}")
    print(f"context type: {type(context)}")
    print(f"context attrs: {dir(context)}")
    print(f"CWD: {os.getcwd()}")
    print(f"logs dir exists: {os.path.exists('/opt/airflow/logs')}")
    print(f"logs dir writable: {os.access('/opt/airflow/logs', os.W_OK)}")
    