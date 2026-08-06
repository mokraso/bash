from databricks.sdk import WorkspaceClient
from databricks.sdk.service.jobs import JobSettings as Job, Task, SparkPythonTask, QueueSettings, TaskDependency, RunIf
from datetime import datetime, timedelta

# Initialize WorkspaceClient
w = WorkspaceClient(profile="DEFAULT")

# Define date range
start_date = datetime.strptime("2025-03-11", "%Y-%m-%d")
end_date = datetime.strptime("2025-03-31", "%Y-%m-%d")
python_script = "/Workspace/Users/laidq@vingroup.net/pipelines/connected_car.py"

# Generate tasks for each day
tasks = []
current_date = start_date
prev_task_key = None
while current_date <= end_date:
    date_str = current_date.strftime("%Y-%m-%d")
    task = Task(
        task_key=f"{date_str}",
        spark_python_task=SparkPythonTask(
            python_file=python_script,
            parameters=[
                "--from_date",
                date_str,
                "--to_date",
                date_str,
                "--write_mode",
                "append",
            ],
        ),
        existing_cluster_id="0606-080725-qimhkqak",
        depends_on=[TaskDependency(task_key=prev_task_key)] if prev_task_key else None,
        run_if=RunIf.ALL_DONE,
    )
    tasks.append(task)
    prev_task_key = date_str
    current_date += timedelta(days=1)


job = w.jobs.create(
    name="connected_car_separte_date",
    tasks=tasks,
    queue=QueueSettings(
        enabled=True,
    ),
    max_concurrent_runs=1,
)
