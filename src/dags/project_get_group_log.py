"""Шаг 1. Забираем group_log.csv из S3 в папку /data."""
import os

import boto3
import pendulum
from airflow.decorators import dag
from airflow.operators.python import PythonOperator

# Ключи доступа берём из переменных окружения — секреты не хранятся в репозитории.
# Перед запуском DAG задайте в окружении Airflow:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")

BUCKET = "sprint6"


def fetch_s3_file(bucket: str, key: str):
    session = boto3.session.Session()
    s3_client = session.client(
        service_name="s3",
        endpoint_url="https://storage.yandexcloud.net",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    )
    s3_client.download_file(
        Bucket=bucket,
        Key=key,
        Filename=f"/data/{key}",
    )


@dag(
    schedule_interval=None,
    start_date=pendulum.parse("2022-07-13"),
    catchup=False,
    tags=["sprint6", "project"],
)
def project_get_group_log():
    bucket_files = ["group_log.csv"]

    for file_name in bucket_files:
        PythonOperator(
            task_id=f"fetch_{file_name}",
            python_callable=fetch_s3_file,
            op_kwargs={"bucket": BUCKET, "key": file_name},
        )


_ = project_get_group_log()
