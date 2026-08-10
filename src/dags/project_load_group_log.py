"""Шаг 3. Читаем /data/group_log.csv и грузим в MY__STAGING.group_log."""
import os

import pandas as pd
import pendulum
import vertica_python
from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

# Параметры подключения берём из переменных окружения — секреты не хранятся
# в репозитории. Перед запуском DAG задайте в окружении Airflow:
#   VERTICA_HOST, VERTICA_PORT, VERTICA_USER, VERTICA_PASSWORD,
#   VERTICA_DB, VERTICA_STAGING_SCHEMA
conn_info = {
    "host": os.environ.get("VERTICA_HOST"),
    "port": os.environ.get("VERTICA_PORT", "5433"),
    "user": os.environ.get("VERTICA_USER"),
    "password": os.environ.get("VERTICA_PASSWORD"),
    "database": os.environ.get("VERTICA_DB", "dwh"),
    "autocommit": True,
}

SCHEMA = os.environ.get("VERTICA_STAGING_SCHEMA")
CHUNK = 50_000


def load_group_log():
    df_group_log = pd.read_csv("/data/group_log.csv")

    # Пустые значения превращают int-колонку во float — фиксируем тип Int64,
    # он допускает пропуски и не ломает данные при вставке.
    df_group_log["user_id_from"] = pd.array(
        df_group_log["user_id_from"], dtype="Int64"
    )

    columns = ["group_id", "user_id", "user_id_from", "event", "datetime"]

    with vertica_python.connect(**conn_info) as conn:
        cur = conn.cursor()
        cur.execute(f"TRUNCATE TABLE {SCHEMA}.group_log")

        for start in range(0, len(df_group_log), CHUNK):
            chunk = df_group_log.iloc[start:start + CHUNK]
            rows = [
                tuple(None if pd.isna(v) else v for v in rec)
                for rec in chunk[columns].itertuples(index=False, name=None)
            ]
            cur.executemany(
                f"INSERT INTO {SCHEMA}.group_log "
                f"({', '.join(columns)}) VALUES (%s, %s, %s, %s, %s)",
                rows,
                use_prepared_statements=False,
            )

        cur.execute(f"SELECT COUNT(*) FROM {SCHEMA}.group_log")
        print("loaded rows:", cur.fetchone()[0])


@dag(
    schedule_interval=None,
    start_date=pendulum.parse("2022-07-13"),
    catchup=False,
    tags=["sprint6", "project"],
)
def project_load_group_log():
    start = EmptyOperator(task_id="start")

    load = PythonOperator(
        task_id="load_group_log",
        python_callable=load_group_log,
    )

    end = EmptyOperator(task_id="end")

    start >> load >> end


_ = project_load_group_log()
