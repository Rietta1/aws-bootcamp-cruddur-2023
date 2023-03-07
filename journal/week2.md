# Week 2 — Distributed Tracing

## Technical Tasks - Observability



### Video Review
* Watched [FREE AWS Cloud Project Bootcamp - Update 2023-02-23 Video](https://youtu.be/gQxzMvk6BzM).
* Watched [Week 2 - Live Streamed Video – Honeycomb.io Setup](https://www.youtube.com/live/2GD9xCzRId4?feature=share).
* Watched [Week 2 - Instrument X-Ray Video](https://youtu.be/n2DTsuBrD_A).
* Watched [Week 2 – X-Ray Subsegments Solved Video](https://youtu.be/4SGTW0Db5y0)
* Watched [Week 2 - CloudWatch Logs Video](https://youtu.be/ipdFizZjOF4).
* Watched [Week 2 - Rollbar Video](https://youtu.be/xMBDAb5SEU4).
* Watched [Week 2 – Github Codespaces Crash Course Video](https://youtu.be/L9KKBXgKopA).




### STEP 1 -  implement distributed tracing with Honeycomb.io


Honeycomb's auto-instrumentation allows you to send basic data quickly using the OpenTelemetry industry standard, before adding custom context.

Login into your [HONEYCOMB](https://www.honeycomb.io/), create an environemnt and call it crudder, then copy the api key and install it into your **gitpod workspace** (cd aws-bootcamp-cruddur-2023) , the code format below:

```
exportHONEYCOMB_API_KEY="SBWMg6QIoezI5tUiGh7hnfA"
export HONEYCOMB_SERVICE_NAME="Cruddur"
gp env HONEYCOMB_API_KEY="SBWMg6QIoezI5tUiGh7hnfA"
gp env HONEYCOMB_SERVICE_NAME="Cruddur"


# to double check if the parameters have been added
env | grep HONEY

#to unset the key
unset HONEYCOMB_SERVICE_NAME
```

![1](https://user-images.githubusercontent.com/101978292/222611341-d8c6a890-af6c-4716-9bb3-fc07a5fc1eaa.jpg)

**To set environmenal var for codespaces** 

create a folder named .env and add

```
HONEYCOMB_API_KEY="BWMg6QIoezI5tUiGh7hnfA
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




### STEP 2 -  implement distributed tracing with Instrument AWS X-Ray for Flask

Go to your backend-flask section of the repo, go to **requirements.txt**

```
aws-xray-sdk
```

Install pythonpendencies

```
pip install -r requirements.txt
```

add to **app.py**

```
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware
```

```
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
```

```
XRayMiddleware(app, xray_recorder)
```

create a folder called **aws/json/xray.json** and paste the code below into it

```
{
    "SamplingRule": {
        "RuleName": "Cruddur",
        "ResourceARN": "*",
        "Priority": 9000,
        "FixedRate": 0.1,
        "ReservoirSize": 5,
        "ServiceName": "backend-flask",
        "ServiceType": "*",
        "Host": "*",
        "HTTPMethod": "*",
        "URLPath": "*",
        "Version": 1
    }
  }

```

Copy the code below and imput it in the cli, you will recieve a json output in the terminal

```
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
 This is the json output i revieved, copy it and paste it in xray group you are to create for crudder in the aws account

 ```
{
    "Group": {
        "GroupName": "Cruddur",
        "GroupARN": "arn:aws:xray:us-east-1:319506457158:group/Cruddur/QPVDGFMO7MZ3MF5UTXCICTP7MHLA775AS5WDKENJ7RO4APDAU72Q",
        "FilterExpression": "service(\"backend-flask\")",
        "InsightsConfiguration": {
            "InsightsEnabled": false,
            "NotificationsEnabled": false
        }
    }
}
 ```
Go to aws console and find xray
input this in the cli

```
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
and you will get this response and automatically see it in the sample section of xray
```
Get this responds
```
{
    "SamplingRuleRecord": {
        "SamplingRule": {
            "RuleName": "Cruddur",
            "RuleARN": "arn:aws:xray:us-east-1:319506457158:sampling-rule/Cruddur",
            "ResourceARN": "*",
            "Priority": 9000,
            "FixedRate": 0.1,
            "ReservoirSize": 5,
            "ServiceName": "backend-flask",
            "ServiceType": "*",
            "Host": "*",
            "HTTPMethod": "*",
            "URLPath": "*",
            "Version": 1,
            "Attributes": {}
:
```

Add xray Deamon Service to Docker Compose file

```
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
    ```

    We need to add these two env vars to our backend-flask in our docker-compose.yml file under 
    ```
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
    ```

***Go to services in your backend folder, go to home activities and add 

```
from aws_xray_sdk.core import xray_recorder


# xray ---
  segment = xray_recorder.begin_segment('home_activities')


  subsegment = xray_recorder.begin_subsegment('mock_data')
     # xray -------
    dist = {
      "now": now.isoformat(),
      "results-size": len(model['data'])
    }
  subsegment.put_metadata('key', dict, 'namespace')   
```


### STEP 3 -  implement distributed tracing with ROLLBAR

https://rollbar.com/

Create a new project in Rollbar called Cruddur

Add to requirements.txt

```
blinker
rollbar
```
Install deps in the terminal

```
pip install -r requirements.txt
```
We need to set our access token in the terminal

```
export ROLLBAR_ACCESS_TOKEN=""
gp env ROLLBAR_ACCESS_TOKEN=""
```

import Rollbar to the app.py file

```
import os
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```
add to the app.py file

```
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```

We'll add an endpoint just for testing rollbar to app.py

```
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```


### STEP 4 -  implement distributed tracing with Cloudwatch

Add to the requirements.txt

```
watchtower
```

install watch tower in the backend-flask

```
pip install -r requirements.txt
```

In app.py

```
import watchtower
import logging
from time import strftime
```

```
# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
```

```
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```


We'll log something in an API endpoint `home_activites.py`

```
LOGGER.info('HomeActivities')
```

Add this in `app.py`

```
LOGGER.info('test log')
```

Set the env var in your backend-flask for `docker-compose.yml`

```
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```



Problems faced
I fixed one, which had to do with honeycomb(you have to create a .env directory and add the HONEYCOMB_API_KEY= to it for metrics to be sent to honeycomb.) 
The x-ray configuration for the backend won't run, I strongly believe it has to do with the codespaces configuration( AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"), I tried to fix it to codespaces own but I couldn't.