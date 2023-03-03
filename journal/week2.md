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

configuring otel(OpenTelemetry) part of the cnnf (cloud native computing foundation) that also runs kubernates{really well governed communites} to send to honeycomb
your cloud envrionments sends standarzied info to honeycomb, which honey comb gives you a UI to look at them, u can also send to other backends like kubernates

Go to the docker-compose.yml 
add this 

```
OTEL_SERVICE_NAME: "backend-flask"
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```

Go to the backend-flask

This is a quick start guide for Python with Flask.
1. Install Packages
Install these packages to instrument a Flask app with OpenTelemetry:
```
pip install opentelemetry-api
``` 
When creating a new dataset in Honeycomb it will provide all these installation insturctions

We'll add the following files to our `requirements.txt`

```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```

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

use this who check whose apikey you might have used in your workstation for honeycomb configuration
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