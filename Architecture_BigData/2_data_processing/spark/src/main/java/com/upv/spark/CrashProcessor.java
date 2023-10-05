package com.upv.spark;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.streaming.StreamingQuery;
import org.apache.spark.sql.streaming.StreamingQueryException;
import org.apache.spark.sql.types.StructType;

import java.util.concurrent.TimeoutException;

import static org.apache.spark.sql.functions.from_json;

public class CrashProcessor {

    public static final String KAFKA_BROKER = "localhost:9092";
    public static final String SOURCE_TOPIC = "CrashMotorVehiclesPeople";
    public static final String DESTINATION_TOPIC = "Crash_transformed";

    public static void main(String args[]) throws TimeoutException, StreamingQueryException {
        // Show environment info
        System.out.println("HADOOP_HOME: " + System.getenv("HADOOP_HOME"));
        System.out.println("PATH: " + System.getenv("PATH"));

        // Crash schema definition
        StructType crashSchema = new StructType()
                .add("unique_id", "string")
                .add("collision_id", "string")
                .add("crash_date", "string")
                .add("crash_time", "string")
                .add("person_id", "string")
                .add("person_type", "string")
                .add("person_injury", "string")
                .add("ped_role", "string")
                .add("person_sex", "string");

        // Setup Spark
        SparkSession spark = SparkSession
                .builder()
                .appName("Crash Processor")
                .config("spark.master", "local")
                .config("spark.eventLog.enabled", "false")
                .getOrCreate();


        // Setup Kafka reader
        // TODO: remove "startingOffsets" if you only want to receive new messages
        Dataset<Row> rawDF = spark
                .readStream()
                .format("kafka")
                .option("kafka.bootstrap.servers", KAFKA_BROKER)
                .option("subscribe", SOURCE_TOPIC)
                .option("startingOffsets", "earliest")
                .load();

        // Get only the value of the Kafka messages (it also has key, partition, offset...)
        Dataset<Row> crashStringDF = rawDF.selectExpr("CAST(value AS STRING)");

        // Convert the JSON String to the schema defined above
        Dataset<Row> crashSchemaDF = crashStringDF
                .select(from_json(crashStringDF.col("value"), crashSchema).as("crash"))
                .select("crash.*");

        // Print the schema (for reference)
        crashSchemaDF.printSchema();

        // Set the dataframe as a table (for querying)
        crashSchemaDF.createOrReplaceTempView("crashes");

        // TODO: Implement your logic here (in SQL format)
        String sql = "SELECT * FROM crashes";
        Dataset<Row> crashQuery = spark.sql(sql);

        // Print the results via console
        //StreamingQuery query = crashQuery.writeStream()
        //        .outputMode("append")
        //        .format("console")
        //        .start();
        //query.awaitTermination();


        // Send the results to Kafka
        // TODO: Uncomment to send data back to Kafka
        crashQuery.selectExpr("CAST(crashes.unique_id AS STRING) AS key", "to_json(struct(crashes.*)) AS value")
                .writeStream()
                .format("kafka")
                .outputMode("append")
                .option("kafka.bootstrap.servers", KAFKA_BROKER)
                .option("topic", DESTINATION_TOPIC)
                .option("checkpointLocation", "/tmp")
                .start()
                .awaitTermination();
    }
}
