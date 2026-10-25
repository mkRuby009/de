# airflow3-feature-lab
 
A personal practice project to learn and test the core features of Apache Airflow 3.
It runs locally on Docker Compose.  
Each DAG in `dags/` focuses on one feature.
 
## Tech stack
 
| Tool | Version |
|---|---|
| Apache Airflow | 3.2.2 (`apache/airflow:3.2.2`, Python 3.13) |
| Executor | CeleryExecutor |
| PostgreSQL | 16 (metadata database) |
| Redis | 7.2 (Celery broker) |
| Docker Compose | v2 |
| uv | local virtual environment for editor support |
| VS Code | editor |
 
## What I practiced
 
| DAG file | Topic |
|---|---|
| `1_first_dag.py` | First DAG |
| `2_dag_versioning.py` | DAG versioning |
| `3_operators.py` | Operators |
| `4_xcoms_auto.py` | XComs passed automatically (TaskFlow return values) |
| `5_xcoms_kwargs.py` | XComs through task kwargs |
| `6_parallel_tasks.py` | Parallel tasks |
| `7_braches.py` | Branching |
| `8_schedule_preset.py` | Schedule presets |
| `9_schedule_catchup.py` | Catchup |
| `10_schedule_cron.py` | Cron schedules |
| `11_schedule_delta.py` | Time-delta schedules |
| `12_incremental_load.py` | Incremental load |
| `13_special_dates.py` | Scheduling on special dates |
| `asset_export.py` | Asset producer |
| `15_asset_dependent.py` | Asset-triggered DAG (consumer) |
| `dags_orchestrate_parent.py` | Parent DAG that orchestrates other DAGs |
| `dag_orchestrate_1.py`, `dag_orchestrate_2.py` | Child DAGs triggered by the parent |
 
## Project structure
 
```text
airflow3-feature-lab/
├── dags/                  # practice DAGs
├── logs/
├── plugins/
├── config/
├── docker-compose.yaml    # official Airflow 3.3.2 compose file
├── .env                   # AIRFLOW_UID, FERNET_KEY (not committed)
└── pyproject.toml         # uv environment, editor only
```
 
## Setup
 
1. Created the `dags`, `logs`, `plugins` and `config` folders.
2. Used the official Airflow `docker-compose.yaml` and mapped the Postgres port to the host, so I can inspect the metadata database.
3. Added a `.env` file with `AIRFLOW_UID` and a generated `FERNET_KEY`.  
   To generate fernet key using command:
   
   `python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"`
   
   or alternatively use fernet key generator from standard site
5. Set up a local Python environment with uv (`apache-airflow==3.2.2`). It is only for auto-completion and linting in the editor. The containers do not use it.
   ```
    uv init
    uv sync
    uv add apache-airflow
   ```

6. Started the stack by running docker compose.
   `docker compose up -d`

8. Open airflow UI (localhost:8080) in browser and login using default credentials: `airflow`/`airflow`

9. Create a new simple dag and check it using airflow UI
10. You can check logs in UI.Also check local logs to confirm if dag is parsed or not. Note that dags in folder get rerun based on the dagbag refresh interval in airflow.cfg default value is 30 seconds.

11. You can also check logs in docker container logs. to connect with postgres container for example, you can use command:
    ```
    docker exec -it airflow-3-full-latest-project-postgres-1 psql -U airflow -d airflow
    ```
## Notes
 
- **DAG parsing:** The DAG processor scans for new files every 300 seconds (`[dag_processor] refresh_interval`). It re-parses known files every 30 seconds (`min_file_process_interval`).
- **Debugging parsing:** the DAG processor logs in `logs/dag_processor/`, and `docker compose logs airflow-dag-processor`.
- **Metadata database:** `docker compose exec postgres psql -U airflow -d airflow`

