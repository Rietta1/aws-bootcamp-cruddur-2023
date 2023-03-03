# Week 2 — Distributed Tracing

## Technical Tasks - Observability

### STEP 1 -  implement distributed tracing with Honeycomb.io


Honeycomb's auto-instrumentation allows you to send basic data quickly using the OpenTelemetry industry standard, before adding custom context.

Login into your [HONEYCOMB](https://www.honeycomb.io/), create an environemnt and call it crudder, then copy the api key and install it into your gitpod workspace (cd aws-bootcamp-cruddur-2023) , the code format below:

```
export HONEYCOMB_API_KEY="BWMg6QIoezI5tUiGh7hnfA"
export HONEYCOMB_SERVICE_NAME="Cruddur"
gp env HONEYCOMB_API_KEY="SBWMg6QIoezI5tUiGh7hnfA"
gp env HONEYCOMB_SERVICE_NAME="Cruddur"


# to double check if the parameters have been added
env | grep HONEY

#to unset the key
unset HONEYCOMB_SERVICE_NAME
```

![1](https://user-images.githubusercontent.com/101978292/222611341-d8c6a890-af6c-4716-9bb3-fc07a5fc1eaa.jpg)


configuring otel(OpenTelemetry) part of the cnnf (cloud native computing foundation) that also runs kubernates{really well governed communites} to send to honeycomb
your cloud envrionments sends standarzied info to honeycomb, which honey comb gives you a UI to look at them, u can also send to other backends like kubernates

Go to the docker-compose.yml 
add this 

```
OTEL_SERVICE_NAME: "backend-flask"
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```

![2](https://user-images.githubusercontent.com/101978292/222611404-fe316421-e5e4-4108-a26a-d0acb5067458.jpg)

Go to the backend-flask

This is a quick start guide for Python with Flask.
1. Install Packages
Install these packages to instrument a Flask app with OpenTelemetry:
```
pip install opentelemetry-api
``` 
![3](https://user-images.githubusercontent.com/101978292/222611480-8dfffbce-1a8b-4187-a982-6aa85deed717.jpg)

When creating a new dataset in Honeycomb it will provide all these installation insturctions

We'll add the following files to our `requirements.txt`

```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
![4](https://user-images.githubusercontent.com/101978292/222611537-8ab85062-e35a-4e7e-bfb0-c832c21f4912.jpg)

We'll install these dependencies:

```
pip install -r requirements.txt
```

Add to the app.py

```
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
```
```
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```

`app = Flask(__name__)`

```
# Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
![5](https://user-images.githubusercontent.com/101978292/222612003-312ad192-a2d9-4f18-93eb-2d808902758b.jpg)
![6](https://user-images.githubusercontent.com/101978292/222612154-6ec80a6c-2036-4da5-b84f-55d8e0fbc537.jpg)

*use this who check whose api key you might have used in your workstation for honeycomb configuration*
`http://honeycomb-whoami.glitch.me/`

Add this to your backend-flask/service/home_activities.py file

```
from opentelemetry import trace

tracer = trace.get_tracer("home.activites")


with tracer.start_as_current_span("home-activities-mock-data"):

span = trace.get_current_span()
span.set_attribute("app.now", now.isoformat())

#add this to the end, above `return results`
span.set_attribute("app.result_length", len(results))
```

![7](https://user-images.githubusercontent.com/101978292/222612304-95309af9-03dc-4f15-83c3-4d475b43c26e.jpg)

![9](https://user-images.githubusercontent.com/101978292/222612381-408c5a27-b64d-4d9b-86b7-f1a82a55a4c2.jpg)

![8](https://user-images.githubusercontent.com/101978292/222612418-8014c874-2b14-47db-8de2-b6c2b78fb98b.jpg)

![11](https://user-images.githubusercontent.com/101978292/222612435-4ca4b44f-e398-4634-aee4-86dc9d3fe630.jpg)




