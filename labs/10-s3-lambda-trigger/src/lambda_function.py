import json
import os
import boto3

glue_client = boto3.client("glue")


def lambda_handler(event, context):
    workflow_name = os.environ["GLUE_WORKFLOW_NAME"]
    triggered_objects = []

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        triggered_objects.append(f"s3://{bucket}/{key}")

    response = glue_client.start_workflow_run(
        Name=workflow_name,
        RunProperties={
            "triggered_by": "s3_object_created",
            "object_count": str(len(triggered_objects)),
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "workflow_name": workflow_name,
                "run_id": response.get("RunId"),
                "files": triggered_objects,
            }
        ),
    }