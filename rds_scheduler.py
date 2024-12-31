import boto3
import os

def rds_scheduler(event, context):
    action = event.get('action', None)
    db_instance = os.environ.get('DB_INSTANCE')
    rds = boto3.client('rds')

    if action == "stop":
        response = rds.stop_db_instance(DBInstanceIdentifier=db_instance)
        return {"status": "stopped", "response": response}

    elif action == "start":
        response = rds.start_db_instance(DBInstanceIdentifier=db_instance)
        return {"status": "started", "response": response}

    return {"status": "unknown action"}
