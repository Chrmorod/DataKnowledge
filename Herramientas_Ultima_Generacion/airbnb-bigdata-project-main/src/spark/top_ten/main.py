import pyspark
import sys

if len(sys.argv) != 3:
  raise Exception("Exactly 2 arguments are required: <inputUri>, <date_to_process>")

inputUri=sys.argv[1]
date_to_process=sys.argv[2]

sc = pyspark.SparkContext()
sqlContext = pyspark.sql.SQLContext(sc)
 
df = sqlContext.read.json(f"{inputUri}/{date_to_process}")

df.show()
df.select('resourceId').distinct().show()
df.groupBy('resourceId').count().show()
# print(df.count())