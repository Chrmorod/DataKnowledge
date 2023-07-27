# Data Pipeline: Airbnb [§](#data-pipeline-airbnb)

* [Introducción](#introduccion)
* [Ingesta de datos](#ingesta-de-datos)
    *   [Preparación](#preparacion)
    *   [Recursos: Datos de inmuebles](#recursos-datos-de-inmuebles)
    *   [Usuarios](#usuarios)
    *   [Eventos](#eventos)
    *   [Reset de datos](#reset-de-datos)
    *   [Uso del generador de eventos en local](#uso-del-generador-de-eventos-en-local)
* [Procesado de Datos](#procesado-de-datos)
    * [Top 10 inmuebles más alquilados](#top-10-inmuebles-mas-alquilados)
    * [Royalties](#royalties)
    * [Utilización de la plataforma](#utilizacion-de-la-plataforma)
* [Entregables](#entregables)
* [Enlaces](#enlaces)
    * [Cloud Storage (S3)](#cloud-storage)
    * [Dataproc (Spark)](#dataproc-spark)
    * [Composer (Airflow)](#composer-airflow)
    * [Cloud Functions](#cloud-functions)
    * [BigQuery and Firestore](#bigquery-and-firestore)
    * [Terraform](#terraform)
    * [Other](#other)
    * [Git](#git)

---

## Introducción [§](#introduccion)

El objetivo del ejercicio es diseñar una pipeline de ingesta y procesado de datos, considerando posibles aspectos que tendría un sistema así en un entorno de producción. Para simplificar la implementación nos centraremos en tres componentes básicos:

1.  El servicio de **ingesta** de datos.
2.  El diseño del **almacenamiento** y los distintos esquemas de datos.
3.  El servicio de **procesado en batch**.

Para implementación utilizaremos componentes de Google Cloud, pero es posible utilizar otros proveedores o tecnologías si cada equipo lo justifica adecuadamente y se mantiene Spark como framework de procesado de datos. En el diagrama siguiente se muestran la propuesta con los diferentes componentes:

[![Arquitectura Básica](https://bigdata.luisbelloch.es/diagrama_thumb.jpg)](https://bigdata.luisbelloch.es/diagrama.png)

Para simular la generación de datos, existe un sistema externo que generará distintos eventos cada pocos segundos. El generador de datos aparece en el diagrama en la parte izquierda, en verde. Es posible habilitar o deshabilitar la generación de datos mediante un panel de control en [singularity.luisbelloch.es](http://singularity.luisbelloch.es), donde también puede configurarse la URL donde el generador enviará los datos. El código fuente está disponible en el [repositorio de Github](https://github.com/luisbelloch/data_processing_course).

## Ingesta de datos [§](#ingesta-de-datos)

El servicio de ingesta de datos es el que se encargará de recibir los datos de los eventos generados por el sistema externo y almacenarlos en distintas bases de datos, dependiendo de la naturaleza de los mismos. El sistema a desarrollar debe poder procesar 3 tipos de entidades externas:

1.  Recursos (inmuebles)
2.  Usuarios
3.  Eventos

Para cada una de las entidades a procesar se desarrollara un endpoint HTTP que recibirá del simulador peticiones en formato JSON y los almacenará en la base de datos. Utilizaremos [Cloud Functions](https://console.cloud.google.com/functions) para su desarrollo, aunque es posible también hacer uso de [Cloud Run](https://console.cloud.google.com/run) y un contenedor específico si se desea. Lo único que se pide es que el endpoint sea capaz de absorber los datos para su posterior procesado.

En cada entidad se ha incluido una descripción de los mensajes en formato [Protocol Buffers](https://developers.google.com/protocol-buffers/docs/proto3) como referencia.

### Preparación [§](#preparacion)

En clase veremos como desarrollar _Cloud Functions_ en Python. Puede abrirse el [repositorio de referencia](https://gitlab.com/luisbelloch/functions) con el siguiente enlace:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgitlab.com%2Fluisbelloch%2Ffunctions.git)

O también clonando directamente el [repositorio de Gitlab](https://gitlab.com/luisbelloch/functions):

```bash
git clone https://gitlab.com/luisbelloch/functions.git
```
    

Hemos incluido un `Makefile` para facilitar la ejecución de los ejemplos. Los distintos _targets_ se muestran ejecutando `make help`:

```bash
functions/hello$ make help
delete               Removes deployment
dependencies         Installs python dependencies locally
deploy               Deploys function
describe             Get information about one function
list                 List all cloud functions deployed in region
test                 Runs tests locally using pytest
test_curl            Sends a sample request using cURL
test_httpie          Sends a sample request using HTTPie
```
    

### Recursos: Datos de inmuebles [§](#recursos-datos-de-inmuebles)

En cualquier momento un nuevo recurso (inmueble) puede darse de alta. El servicio debe cumplir este contrato:

```protobuf
syntax = "proto3";

message CreateResourceRequest {
string id = 1;            // identificador inmueble
string name = 2;          // dirección del immueble
string category_id = 3;   // clase de inmueble
string provider_id = 4;   // persona que ofrece el el inmueble en alquiler
bool promotion = 5;       // inmueble en promoción
}

message CreateResourceResponse {
string external_id = 1;
}

service Resource {
rpc CreateResource (CreateResourceRequest) returns (CreateResourceResponse);
}
```
    

Es posible obtener una lista de todos los inmuebles en el sistema mediante la url [`http://singularity.luisbelloch.es/v1/airbnb/resources`](http://singularity.luisbelloch.es/v1/airbnb/resources)

Se recomienda guardar los datos en [Firestore](https://console.cloud.google.com/firestore), ya que el volumen no es muy alto y el esquema de datos es de tipo _documental_. Puede también optarse por otro almacenamiento, siempre que en el entregable se justifique adecuadamente.

### Usuarios [§](#usuarios)

En cualquier momento puede darse de alta nuevos usuarios. El servicio debe cumplir este contrato:

```protobuf	
syntax = "proto3";

message CreateUserRequest {
    string email = 1;
    string name = 2;
    int32 age = 3;
}

message CreateUserResponse {
    string external_id = 1;
}

service User {
    rpc CreateUser (CreateUserRequest) returns (CreateUserResponse);
}
```

Es importante tener en cuenta varias cosas:

1.  El servicio debe crear identificadores únicos para cada nuevo usuario.
2.  No existen restricciones sobre dónde debe guardarse cada usuario. Justificar la elección.
3.  La lista de usuarios que se han registrado correctamente puede consultarse en [`http://singularity.luisbelloch.es/v1/airbnb/users`](http://singularity.luisbelloch.es/v1/airbnb/users)

Se recomienda guardar los datos en [Firestore](https://console.cloud.google.com/firestore), ya que el volumen no es muy alto y el esquema de datos es de tipo _documental_. Puede también optarse por otro almacenamiento, siempre que en el entregable se justifique adecuadamente.

### Eventos [§](#eventos)

Aproximadamente cada segundo, el servidor de eventos generará sucesos para que el sistema los considere. Un ejemplo de evento puede ser el siguiente:

> _En un determinado momento, un usuario alquila un piso en la 'Avenida de Francia' al cliente 'Pedro Martínez' durante tres días_.

Dicho evento sigue el siguiente contrato:

```protobuf
syntax = "proto3";

import "google/protobuf/duration.proto";
import "google/protobuf/timestamp.proto";

message Event {
    string event_id = 1;
    google.protobuf.Timestamp event_time = 2;
    google.protobuf.Timestamp process_time = 3;
    string resource_id = 4;   // identificador inmueble
    string user_id = 5;       // identificador del usuario
    string country_code = 6;  // ISO3166
    google.protobuf.Duration duration = 7;
    double item_price = 8;
}

message EventResponse {
    string external_id = 1;
}

service Events {
    rpc Process (Event) returns (EventResponse);
}
``` 

Es importante saber que **los eventos sólo serán generados para aquellos Usuarios o Recursos previamente guardados**.

En este caso se recomienda utilizar [Cloud Storage](https://console.cloud.google.com/storage) o [BigQuery](https://console.cloud.google.com/bigquery) para los eventos, pero puede utilizarse cualquier otro sistema con su correspondiente justificación.

### Reset de datos [§](#reset-de-datos)

Es posible limpiar todos los registros generados hasta el momento, incluidos los registros de auditoría. Para ello hay que lanzar una petición `POST` a la siguiente url:

```bash
curl -X POST https://singularity.luisbelloch.es/v1/airbnb/reset
```

### Uso del generador de eventos en local [§](#uso-del-generador-de-eventos-en-local)

Es posible arrancar la aplicación que genera los eventos para realizar pruebas, sin depender de [singularity.luisbelloch.es](http://singularity.luisbelloch.es). Para ello, lanza el contenedor de Docker directamente:

```bash
docker run -p 8080:8080 -ti luisbelloch/singularity
```

La aplicación estará disponible en `http://localhost:8080`.

Adicionalmente, se pueden generar datos de forma local y volcarlos a un archivo. Esto puede simplificar el desarrollo de los programas de Spark en la parte 3. Para generar 10 eventos:

```bash
docker run -ti luisbelloch/singularity_mock evento 10 > eventos.jsonl
```

Se pueden también generar `recursos` o `usuarios`:

```bash
docker run -ti luisbelloch/singularity_mock recurso 10
docker run -ti luisbelloch/singularity_mock usuario 10
```

Para los entregables de clase los datos tienen que haber sido guardados mediante las Cloud Functions desarrolladas en este apartado.

## Procesado de Datos [§](#procesado-de-datos)

### Top 10 inmuebles más alquilados [§](#top-10-inmuebles-mas-alquilados)

Generar mediante Spark un informe diario de los 10 inmuebles más alquilados por día y por categoría. Guardar en un bucket de Cloud Storage en formato CSV, con la siguiente estructura:

```csv
position|date|categoryId|categoryName|resourceId|resourceName
```

La definición de las categorías puede extraerse de [`http://singularity.luisbelloch.es/v1/airbnb/categories`](http://singularity.luisbelloch.es/v1/airbnb/categories) al inicio del proceso.

### Royalties [§](#royalties)

Generar, mediante Spark, un fichero mensual con la cantidad que Airbnb debe pagar a cada persona que ofrece el el inmueble en alquiler. Cada pago tiene una clase de asociada que indica el porcentaje que se ha de pagar sobre el total, _excepto_ en algunos inmuebles que vienen con el flag `promotion:true`, en cuyo caso la cantidad total a pagar es cero.

Los archivos han de guardarse en Cloud Storage en formato json por lineas:

```json	
{ "date": "2019-02", "providerId": "BGA543T", "resourceId": "P401", "amount": 340.29 }
{ "date": "2019-02", "providerId": "BGA543T", "resourceId": "P402", "amount": 231.00 }
```

La cantidad debe estar expresada en dólares americanos. Para ello, ha de convertirse el importe de cada pago a `USD`. Puede obtenerse una lista de cambios de divisas mediante:

```bash
GET https://bigdata.luisbelloch.es/exchange_rates/usd
```

La correspondencia entre paises y monedas puede descargarse desde:

```bash
GET https://bigdata.luisbelloch.es/countries.csv
```

Este fichero ha de generarse todos los meses, por lo que tenéis que buscar una forma de automatizar este proceso para que no exista intervención humana. Incluid la configuración del servicio en el entregable. No es necesario utilizar Airflow, puedes buscar otras alternativas.

Los precios por clase de se pueden obtener desde la siguiente URL [`http://singularity.luisbelloch.es/v1/airbnb/categories`](http://singularity.luisbelloch.es/v1/airbnb/categories) y siguen el siguiente formato:

```json
{
    "categoryId": "Z45",
    "categoryName": "Villa de Lujo",
    "percent": 0.12
}
```

### Utilización de la plataforma [§](#utilizacion-de-la-plataforma)

Mediante Spark, extraer dos informes mensuales de utilización de cada inmueble, uno [segmentado](https://spark.apache.org/docs/latest/sql-data-sources-parquet.html#partition-discovery) por país y otro por zona horaria. Los archivos deben guardarse en Cloud Storage en formato Parquet, con las siguientes columnas:

```csv
date,resourceId,countryCode,usagePercentTotal,usagePercentRelativeCountry,totalDurationInSec
```

Donde las columnas significan:

* `usagePercentTotal` - Porcentaje de uso total de cada inmueble relativo al resto.
* `usagePercentRelativeCountry` - Porcentaje de uso relativo al país.
* `totalDurationInSec` - Uso total por inmueble, en segundos.

Y en el caso de las zonas horarias:

```csv
date,resourceId,timeZone,usagePercentTotal,usagePercentRelativeTz,totalDurationInSec
```

Para este ejercicio puede utilizarse tanto Spark como [BigQuery](https://cloud.google.com/bigquery/docs/loading-data). En el caso de utilizar BigQuery, incluir en el entregable los scripts de configuración y carga de datos.

¿Puedes encontrar una forma de computar dichos porcentajes en streaming?

## Entregables [§](#entregables)

El entregable de la asignatura puede realizarse por grupos y debe contener:

1. Las funciones para la ingesta de datos y su posterior almacenamiento:
    * Usuarios
    * Recursos
    * Eventos
2. Tres trabajos de Spark, ejecutables también en Dataproc:
    * Top 10 inmuebles más alquilados
    * Royalties
    * Utilización de la plataforma

Opcionalmente, fuera de evaluación:

1. Batería de pruebas unitarias de los endpoints HTTP y los trabajos de Spark.
    * Ejemplo de prueba para el endpoint http: [hello\_storage/main\_test.py](https://gitlab.com/luisbelloch/functions/-/blob/master/samples/hello_storage/main_test.py)
    * Ejemplo de prueba unitaria para Spark: [test\_ejercicio\_2.py](https://github.com/luisbelloch/data_processing_course/blob/master/assignments/test_ejercicio_2.py)
2.  Scripts de provisionamiento con Terraform.
3.  [10 ejercicios extra](https://github.com/luisbelloch/data_processing_course/blob/master/assignments/README.md) que pueden ser de ayuda.

## Enlaces [§](#enlaces)

### Cloud Storage (S3) [§](#cloud-storage)

* [Creating Storage Buckets](https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-code_samples)
* [Uploading Objects](https://cloud.google.com/storage/docs/uploading-objects#storage-upload-object-code-sample)
* [Downloading Objects](https://cloud.google.com/storage/docs/downloading-objects#storage-download-object-code-sample)
* [List of additional guides](https://cloud.google.com/storage/docs/how-to)

### Dataproc (Spark) [§](#dataproc-spark)

* [PySpark Documentation](https://spark.apache.org/docs/latest/api/python/index.html)
* [Install dependencies (such as Firestore)](https://cloud.google.com/dataproc/docs/tutorials/python-configuration#image_version_20)
* [Use the Cloud Storage connector with Apache Spark](https://cloud.google.com/dataproc/docs/tutorials/gcs-connector-spark-tutorial)
* [Use the BigQuery connector with Spark](https://cloud.google.com/dataproc/docs/tutorials/bigquery-connector-spark-example)

### Composer (Airflow) [§](#composer-airflow)

* [Airflow Documentation](https://airflow.apache.org)
* [Triggering Airflow DAGs when Cloud Storage Buckets Change](https://cloud.google.com/composer/docs/how-to/using/triggering-with-gcf)
* [Google Cloud Composer (Airflow) Quickstart](https://cloud.google.com/composer/docs/quickstart)

### Cloud Functions [§](#cloud-functions)

* [Google Cloud Functions Documentation](https://cloud.google.com/functions/docs/)
* [Samples for Node.js Cloud Functions](https://github.com/GoogleCloudPlatform/nodejs-docs-samples/tree/master/functions)
* [Samples for Python Cloud Functions](https://github.com/GoogleCloudPlatform/python-docs-samples/tree/master/functions)
* [Services you could use from a Cloud Function](https://cloud.google.com/functions/docs/concepts/services)

### BigQuery and Firestore [§](#bigquery-and-firestore)

* [Choosing between native and Datastore mode](https://cloud.google.com/firestore/docs/firestore-or-datastore)
* [Loading data into BigQuery](https://cloud.google.com/bigquery/docs/loading-data)
* [Scheduling Firestore Exports](https://cloud.google.com/firestore/docs/solutions/schedule-export)
* [BigQuery External Data Sources](https://cloud.google.com/bigquery/external-data-sources)
* [Exporting and Importing Data from Google Firestore](https://cloud.google.com/firestore/docs/manage-data/export-import)
* [Writting data to Firestore](https://cloud.google.com/firestore/docs/manage-data/add-data)
* [Firestore documentation for CollectionReference](https://cloud.google.com/nodejs/docs/reference/firestore/0.20.x/CollectionReference)

### Terraform [§](#terraform)

* [Deploying Cloud Function](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions_function)
* [Creating DataProc cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_cluster)
* [Running Spark job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_job)

### Other [§](#other)

* [HTTPie](https://httpie.io/) - `pip3 install httpie`
* [Cloud SDK Quickstart](https://cloud.google.com/sdk/docs/quickstarts/)
* [Cloud Storage Python API](https://googleapis.dev/python/storage/latest/client.html)
* [Protocol Buffers Language Guide (proto3)](https://developers.google.com/protocol-buffers/docs/proto3)
* [Makefile Tutorial](https://makefiletutorial.com)

### Git [§](#git)

* [Using Git](https://docs.github.com/en/free-pro-team@latest/github/using-git)
* Desktop clients, in case you don't want to use the console:
    * [Fork](https://git-fork.com)
    * [Github Desktop](https://desktop.github.com)
    * [Tig](https://github.com/jonas/tig)
* [SSH + Git: Avoid typing user and password each time](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/connecting-to-github-with-ssh)