PROJECT_ID?=airbnb-bigdata-project
REGION?=europe-west1
FUNCTION_URL:=https://$(REGION)-$(PROJECT_ID).cloudfunctions.net/$(FUNCTION_NAME)

CLOUD_RUN_URL:=gcloud functions describe $(FUNCTION_NAME) --region $(REGION) --format="value(serviceConfig.uri)"

.PHONY: delete
delete: ## Removes deployment
	gcloud functions delete --region $(REGION) --quiet $(FUNCTION_NAME)

.PHONY: deploy
deploy: ## Deploys function
	gcloud functions deploy $(FUNCTION_NAME) $(GEN) --runtime python39 --trigger-http --allow-unauthenticated --project $(PROJECT_ID) --region $(REGION) $(DEPLOY_PARAMS)
