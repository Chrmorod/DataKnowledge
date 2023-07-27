# gcloud dataproc clusters create test-storage \
#     --project=airbnb-bigdata-project \
#     --region=europe-west1 \
#     --single-node

gcloud dataproc jobs submit pyspark main.py \
    --cluster=dataproc1 \
    --region=europe-west1 \
    -- gs://bigdataupv2022-airbnb_data/events/raw 2023-01-22

# gcloud dataproc clusters delete test-storage --region=europe-west1