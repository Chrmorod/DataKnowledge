from datetime import datetime

from flask import jsonify
from google.cloud import firestore

db = firestore.Client()

# # https://europe-west1-airbnb-bigdata-project.cloudfunctions.net/add_resource
def add_resource(request):
  payload = request.get_json(silent=True)

  doc_ref = db.collection('resources').document()
  doc_ref.set({
    'tenant': payload['tenant'],
    'id': payload['id'],
    'name': payload['name'],
    'categoryId': payload['categoryId'],
    'providerId': payload['providerId'],
    'promotion': payload['promotion'],
    'created': datetime.utcnow().isoformat()
  })

  return jsonify({ 'externalId': doc_ref.id })

