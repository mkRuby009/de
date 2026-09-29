# Full airflow 3.2.2 project

## Steps to create this airflow 3.2.2 project:


1. Create a new project and open it in vscode
2. Manually create folders for dags, logs, plugins, config
3. Pull docker compose from airflow latets version, to be able to deploy airflow on docker compose
4. Add port where you prefer to expose postgres container's 5432 port
5. Create .env file at root level of the project and add 2 env variables for AIRFLOW_UID and FERNET_KEY(you can generate fernet key using command:  
 `python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"`) or use fernet key generator from standard site

6. Create python running environment which will be used for airflow only to resolve errors and suggestions in the editor. Use uv for this.
    ```
    uv init
    uv sync
    uv add apache-airflow
    ```
    Note: Docker containers do not need your local python environment to run.

7. Test airflow project by running command `docker compose up -d`

8. Open airflow UI (localhost:8080) in browser and login using default credentials: `airflow`/`airflow`

9. Create a new simple dag and check it using airflow UI
10. You can check logs in UI.Also check local logs to confirm if dag is parsed or not. Note that dags in folder get rerun based on the dagbag refresh interval in airflow.cfg default value is 30 seconds.

11. You can also check logs in docker container logs. to connect with postgres container for example, you can use command:
    ```
    docker exec -it airflow-3-full-latest-project-postgres-1 psql -U airflow -d airflow
    ```

