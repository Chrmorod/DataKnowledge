import json
import os
from datetime import datetime

from flask import jsonify
from google.cloud import storage


def upload(file_path, content):
    storage_client = storage.Client()
    bucket_name = os.getenv('BUCKET_NAME')
    bucket = storage_client.bucket(bucket_name)
    new_blob = bucket.blob(file_path)
    new_blob.upload_from_string(content)

# https://europe-west1-airbnb-bigdata-project.cloudfunctions.net/add_event


def add_event(request):
    payload = request.get_json(silent=True)
    print(payload)
    eventId = payload['eventId']
    payload['created'] = datetime.utcnow().isoformat()
    payload_as_string = json.dumps(payload)
    upload(
        f"events/raw/{datetime.utcnow().date().isoformat()}/event-{eventId}.json", payload_as_string)

    return jsonify({'externalId': eventId})
