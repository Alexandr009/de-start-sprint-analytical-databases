"""Шаг 1. Забираем group_log.csv из S3 в папку /data."""
import os 
import boto3
import pendulum
from airflow.decorators import dag
from airflow.operators.python import PythonOperator
from airflow.models import Variable

AWS_ACCESS_KEY_ID = Variable.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = Variable.get('AWS_SECRET_ACCESS_KEY')

BUCKET = "sprint6"


def fetch_s3_file(bucket: str, key: str):

     # Определяем папку, где находится текущий DAG
    dag_folder = os.path.dirname(os.path.abspath(__file__))
    # Путь к подпапке 'data'
    data_folder = os.path.join(dag_folder, 'data')
    # Создаём папку, если её нет
    os.makedirs(data_folder, exist_ok=True)
    # Полный путь к файлу внутри data/
    local_path = os.path.join(data_folder, key)

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
        Filename=local_path,   
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
