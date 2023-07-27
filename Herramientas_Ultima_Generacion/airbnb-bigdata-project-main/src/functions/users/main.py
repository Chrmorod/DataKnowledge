from datetime import datetime

from flask import jsonify
from google.cloud import firestore

db = firestore.Client()

# https://europe-west1-airbnb-bigdata-project.cloudfunctions.net/add_user
def add_user(request):
  payload = request.get_json(silent=True)

  doc_ref = db.collection('users').document()
  doc_ref.set({
      'id': payload['id'],
      'tenant': payload['tenant'],
      'name': payload['name'],
      'email': payload['email'],
      'age': payload['age'],
      'created': datetime.utcnow().isoformat()
  })

  return jsonify({ 'externalId': doc_ref.id })
