from google.cloud import storage
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType
storage_client = storage.Client()
#Prueba Individual:
#bucket = storage_client.bucket('bigdataupv2022-airbnb_data')
#new_blob = bucket.blob("events/event-0671a422-7b2f-4c7b-a132-be8db516c4cf.json")
#Parametros necesarios para estructura el dataframe
schema = StructType([
    StructField('countryCode', StringType(),True),
    StructField('created', StringType(),True), 
    StructField('duration', IntegerType(),True), 
    StructField('eventId', StringType(),True), 
    StructField('eventTime', StringType(),True), 
    StructField('externalId', StringType(),True), 
    StructField('itemPrice', DoubleType(),True), 
    StructField('processTime', StringType(),True), 
    StructField('resourceId', StringType(),True), 
    StructField('tenantId', StringType(),True), 
    StructField('userId', StringType(),True)])
spark = SparkSession.builder.master("local[1]").appName("SparkPrueba").getOrCreate()
#Creación dataframe vacio donde almacenamos los datos del bucket
df_events = spark.createDataFrame([],schema)
#Almacenamiento de datos
for blob in storage_client.list_blobs('bigdataupv2022-airbnb_data', prefix='events'):
    df = spark.read.format('json').load(f"gs://bigdataupv2022-airbnb_data/{blob.name}")
    #print(df.dtypes)
    df_events = df_events.union(df)
df_events.show(truncate=False)
