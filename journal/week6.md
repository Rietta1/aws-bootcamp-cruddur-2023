# Week 6 — Deploying Containers on ECS and DNS configuration

There are two methods of deployin on AWS ECS
- Deploying  inside the EC2 (Virtual Machine)
- Deploying the containers with , Serverless Fargate on ECS


## Technical Tasks 
This will be on Fragate 

### Test RDS Connecetion
First we need to create a script to check if we can estabilish a connection with the RDS

this is the script` backend-flask/bin/db/test`

Add this `test` script into `db` so we can easily check our connection from our container.

```sh
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```

- Task Flask Script

We'll add the following endpoint for our backend-flask `app.py`:

```py
# line 125 to 127
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```
- Backend Health Check

We'll create a new bin script at `bin/flask/health-check` make it excutable `chmod u+x bin/flask/health-check` and run it `./bin/flask/health-check`

```py
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```

Create CloudWatch Log Group
```sh
# run
aws logs create-log-group --log-group-name cruddur

aws logs put-retention-policy --log-group-name cruddur --retention-in-days 1
```
Create ECS Cluster

```sh
# run
aws ecs create-cluster \
--cluster-name cruddur \

<!-- aws cloud map -->
--service-connect-defaults namespace=cruddur
```

### Gaining Access to ECS Fargate Backend Container
- Create ECR repo and push image, we are to create 3 repos, 1st for the base image python1, 2nd for backend flask and  3rd for frontend-react-js.

- Repo For Base-image python
```sh
# run
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```
*go to the newly created repo and click on `view push commands` to see the steps in push an image to the repocruddur-python*

OR use 

Login to ECR 
```sh
# run
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
so we have to pull the image from docker first then push it to ecr

- For Python
Set URL

```sh
# run
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"

echo $ECR_PYTHON_URL
```
Pull Image `docker pull python:3.10-slim-buster`

Tag Image `docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster`

Push Image `docker push $ECR_PYTHON_URL:3.10-slim-buster`

### **Deploy Backend-Flask**

- For Backend-Flask
In your flask dockerfile update the from to instead of using DockerHub's python image you use your own image.

*remember to put the :latest tag on the end*

Go to the backend-flask Dockerfile and replace the `python:3.10-slim-buster` with the image URL in your cruddur-python repo.

Run a docker-compose up select services `docker compose up backend-flask db` , run them both

Create Repo
```sh
# run
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

Set URL
```sh
# run
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"

echo $ECR_BACKEND_FLASK_URL
```
Build Image `docker build -t backend-flask .`

Tag Image `docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest`

Push Image `docker push $ECR_BACKEND_FLASK_URL:latest`

### Setup ECS Severless Fargate for the Backend
1. Register Task Defintions

- Passing Senstive Data to Task Defintion on AWS Console ,AWS Systems Manager, Parameter STORE

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-ssm-paramstore.html

```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

2. Create Task and Exection Roles for Task Defintion
> docker contest is a tool that  can take a docker compose file and deploy it directly but then we wont have cloudformation and cicd

- Create ExecutionRole

 create file in aws/policies/service-assume-role-execution-policy.json and add the command to the file

```sh

{
    "Version":"2012-10-17",
    "Statement":[{
        "Action":["sts:AssumeRole"],
        "Effect":"Allow",
        "Principal":{
          "Service":["ecs-tasks.amazonaws.com"]
      }}]
  }
```
Run this in the teminal to create role
```sh
# run
aws iam create-role \
    --role-name CruddurServiceExecutionRole \
    --assume-role-policy-document "file://aws/policies/service-assume-role-execution-policy.json"
```

3. create file in aws/policies/service-execution-policy.json and add the command to the file

```sh
{
  "Sid": "VisualEditor0",
  "Effect": "Allow",
  "Action": [
    "ssm:GetParameters",
    "ssm:GetParameter"
  ],
  "Resource": "arn:aws:ssm:ca-central-1:387543059434:parameter/cruddur/backend-flask/*"
}
```

Run this in the teminal to create role
```sh
aws iam put-role-policy \
  --policy-name CruddurServiceExecutionPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document "file://aws/policies/service-execution-policy.json"

```

4.  Create TaskRole

```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"

# create SSMAccessPolicy and attach it to CruddurTaskRole
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"
# attach CloudWatchFullAccess policy to CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole

# attach AWSXRayDaemonWriteAccess policy to CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

5. Create Task Definition Json file
Create a new folder called `aws/task-definitions` and place the following files in there:

`backend-flask.json`

```json
{
  "family": "backend-flask",
  "executionRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "backend-flask",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "name": "backend-flask",
          "containerPort": 4567,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "ca-central-1",
            "awslogs-stream-prefix": "backend-flask"
        }
      },
      "environment": [
        {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
        {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
        {"name": "AWS_COGNITO_USER_POOL_ID", "value": ""},
        {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": ""},
        {"name": "FRONTEND_URL", "value": ""},
        {"name": "BACKEND_URL", "value": ""},
        {"name": "AWS_DEFAULT_REGION", "value": ""}
      ],
      "secrets": [
        {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
        {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
        {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/CONNECTION_URL" },
        {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
        {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        
      ]
    }
  ]
}
```

6. Register Backend Task Defintion

```sh
# run task-definitions/backend-flask
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```


add this to json to service-execution-policy on iam to enable ecs execution task access to ecr and full cloud watch acess

```sh
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource": "arn:aws:ssm:ca-central-1:387543059434:parameter/cruddur/backend-flask/*"
        }
    ]
}
```

7. Get the default vpc and subnets

```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

```sh
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
8. Create Security Group

```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```
- Give it access to port 80
```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

9. Create clusters Services
create a file `service-backend-flask.json` in aws/json/


```sh
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
    {
        "targetGroupArn": "arn:aws:elasticloadbalancing:ca-central-1:387543059434:targetgroup/cruddur-backend-flask-tg/87ed2a3daf2d2b1d",
        "containerName": "backend-flask",
        "containerPort": 4567
    }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-04bdc8d5443cc8283"
      ],
      "subnets": [
        "subnet-0462b87709683ccaa",
        "subnet-066a53dd88d557e05",
        "subnet-021a6adafb79249e3"
      ]
    }
  },
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  },
  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask"
```

```sh
# run create-service backend-flask
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

### Not able to use Sessions Manager to get into cluster EC2 sintance
The instance can hang up for various reasons. You need to reboot and it will force a restart after 5 minutes So you will have to wait 5 minutes or after a timeout.

You have to use the AWS CLI. You can't use the AWS Console. it will not work as expected.

The console will only do a graceful shutdodwn The CLI will do a forceful shutdown after a period of time if graceful shutdown fails.

```
aws ec2 reboot-instances --instance-ids i-0d15aef0618733b6d
```
- Connection via Sessions Manager (Fargate)

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-linux https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-verify

- Install for Ubuntu

```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

- Verify its working `session-manager-plugin`

- Connect to the backend container 
Create a file called `connect-to-backend-flask` in `backend-flask/bin/ecs/connect-to-backend-flask`, change the permission to executable and the run `./backend-flask/bin/ecs/connect-to-backend-flask`

```sh
#! /usr/bin/bash
if [ -z "$1" ]; then
  echo "No TASK_ID argument supplied eg ./bin/ecs/connect-to-backend-flask 9c7ac22f488a40c8a831c47a19e43bec"
  exit 1
fi
TASK_ID=$1

CONTAINER_NAME=backend-flask

echo "TASK ID : $TASK_ID"
echo "Container Name: $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/bash" \
--interactive

```
*commands you can run to check your container `


- create a application load balancer and 2 target groups for frontend and backend, create a security group for the load balancer, open port 4567 and 3000. add the health check
Route the ecs service security group port to the load balancer

<br>

----------------------------------------------------

<br>

### **Deploy Frontend-react-js**
- For Frontend React

Create Repo
```sh
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```

Set URL

```sh
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```


- Create a new folder called `aws/task-definitions` and place the following files in there:

`frontend-react-js.json`

```json
{
    "family": "frontend-react-js",
    "executionRoleArn": "arn:aws:iam::319506457158:role/CruddurServiceExecutionRole",
    "taskRoleArn": "arn:aws:iam::319506457158:role/CruddurTaskRole",
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": [ 
      "FARGATE" 
    ],
    "containerDefinitions": [
      {
        "name": "frontend-react-js",
        "image": "319506457158.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js:latest",
        "essential": true,
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "curl -f http://localhost:3000 || exit 1"
          ],
        "portMappings": [
          {
            "name": "frontend-react-js",
            "containerPort": 3000,
            "protocol": "tcp", 
            "appProtocol": "http"
          }
        ],
  
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "cruddur",
              "awslogs-region": "us-east-1",
              "awslogs-stream-prefix": "frontend-react-js"
          }
        }
      }
    ]
  }
```

- Register for Frontend Task Defintion

```sh
# run task-definitions/frontend-react
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```

Create a new dockerfile for prod `Dockerfile.prod

```sh

# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

- create a file in the frontend-recat-js named `nginx.conf`

```sh
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```

Run `npm run build` to build



Build Image frontend images

```s
docker build \
--build-arg REACT_APP_BACKEND_URL="http://cruddur-alb-1801626232.us-east-1.elb.amazonaws.com:4567" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="ca-central-1_CQ4wDfnwc" \
--build-arg REACT_APP_CLIENT_ID="25jlejh9os80sll6an57quh8ab" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```

Tag Image `docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest`

Login to ECR

```
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

Push Image `docker push $ECR_FRONTEND_REACT_URL:latest`


If you want to run and test it locally

```sh
docker run --rm -p 3000:3000 -it frontend-react-js 
```



- Create clusters Services create a file `service-frontend-flask.json` in aws/json/ 

```json
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
    {
        "targetGroupArn": "arn:aws:elasticloadbalancing:ca-central-1:387543059434:targetgroup/cruddur-frontend-react-js/562db3dc9c310eee",
        "containerName": "frontend-react-js",
        "containerPort": 3000
    }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-04bdc8d5443cc8283"
      ],
      "subnets": [
        "subnet-0462b87709683ccaa",
        "subnet-066a53dd88d557e05",
        "subnet-021a6adafb79249e3"
      ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "frontend-react-js",
  "taskDefinition": "frontend-react-js",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "frontend-react-js",
        "discoveryName": "frontend-react-js",
        "clientAliases": [{"port": 3000}]
      }
    ]
  }
}
```

```sh
# run create-service/frontend-react-js
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```

- create a application load balancer and 2 target groups for frontend and backend, create a security group for the load balancer, open port 4567 and 3000. add the health check `/api/health-check` for the backend to the target group
Route the ecs service security group port to the load balancer


- Connect to the frontend container 
Create a file called `connect-to-frontend-react-js` in `backend-flask/bin/ecs/connect-to-frontend-react-js`, change the permission to executable and the run `./backend-flask/bin/ecs/connect-to-frontend-react-js`

```sh
#! /usr/bin/bash
if [ -z "$1" ]; then
  echo "No TASK_ID argument supplied eg ./bin/ecs/connect-to-frontend-react-js 56531dd50c8146e683ff5a33ae4392dc"
  exit 1
fi
TASK_ID=$1

CONTAINER_NAME=frontend-react-js

echo "TASK ID : $TASK_ID"
echo "Container Name: $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/sh" \
--interactive
```

*commands you can run to check your container 
```
ls
curl localhost:3000
```
(possible prompt: write a health check that uses curl to localhost:3000 for a task definiation for ecs fargate)

<br>

----------------------------------------------------

<br>

### **Implementation of the SSL and configuration of Domain with Route53**

- Create a hosted zone and copy the namesavers details to where your domain name ns

- Go to AWS Certificate Manager and create an ssl certificate
domain name = rietta.online
click on add another name to this certificate = *.rietta.online

- go to the alb `cruddur-alb` | Add listener 
http = 80,
Redirect to | https = 443 | select : 302 not found
create record in Route53

* Add another listener 
https = 443,
Forword to | = cruddur-frontend-react-js-tg | select From ACM = rietta.online

- Delete the previous listeners for the backend and frontend prev added by you 3000 and 4567 

- click on https/443 , then click on edit rules, then insert a new rule and then under **IF (all match)** click on Host header... and add api.rietta.online and the under **Then** click on Forward to... and add cruddur-backend-flask-tg

-Go to hosted zones on route53 and create a record for the frontend, leave the record name empty and record tyme = A- Routes traffic to an IPV4 address, and some AWS resources, turn on Alias, click alias to application load balancer, simple route and the create.

Create another record for the backend, record name = api , record type = A- , turn on Alias, click alias to application load balancer, simple route and the create.

*ping api.rietta.online, curl api.rietta.online, in the terminal to check*

-Go to the backend task defininations and change 

```json
{"name": "FRONTEND_URL", "value": "*"},
{"name": "BACKEND_URL", "value": "*"},

Change it to this

{"name": "FRONTEND_URL", "value": "rietta.online"},
{"name": "BACKEND_URL", "value": "api.rietta.online"},
```

Then re run the backend task definition to up date it 
`aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json`

- Go and rebuild your frontend image, change the backend_url to the new backend address, `api.rietta.online` and push it bcos these new changes are baked into it.

Run `npm run build` to build



Build Image frontend images

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.rietta.online" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_YMdvcghdH" \
--build-arg REACT_APP_CLIENT_ID="25jlejh9os80sll6an57quh8ab" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```


- Go to the aws console and update the cluster service, `force new deyployment` with the `LATEST`

### **Fixing Debug messages showing production**

- Create a new docker file in backend-flask for production `Dockerfile.prod` to remove the debug logs showing

```yml
FROM 387543059434.dkr.ecr.ca-central-1.amazonaws.com/cruddur-python:3.10-slim-buster

# Inside Container
# make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period . /backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug","--no-debugger","--no-reload"]
```

```sh
# run
docker build -f Dockerfile.prod -t backend-flask-prod .
```

- create a file `./backend-flask/bin/docker/build/backend-flask-prod`
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BUILD_PATH=$(dirname $ABS_PATH)
DOCKER_PATH=$(dirname $BUILD_PATH)
BIN_PATH=$(dirname $DOCKER_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"

docker build \
-f "$BACKEND_FLASK_PATH/Dockerfile.prod" \
-t backend-flask-prod \
"$BACKEND_FLASK_PATH/."
```


create a file `./backend-flask/bin/docker/run/backend-flask-prod`
```sh

#! /usr/bin/bash

docker run --rm \
-p 4567:4567 \
--env AWS_ENDPOINT_URL="http://dynamodb-local:8000" \
--env CONNECTION_URL="postgresql://postgres:password@db:5432/cruddur" \
--env FRONTEND_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
--env BACKEND_URL="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
--env OTEL_SERVICE_NAME='backend-flask' \
--env OTEL_EXPORTER_OTLP_ENDPOINT="https://api.honeycomb.io" \
--env OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=${HONEYCOMB_API_KEY}" \
--env AWS_XRAY_URL="*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*" \
--env AWS_XRAY_DAEMON_ADDRESS="xray-daemon:2000" \
--env AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
--env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
--env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
--env ROLLBAR_ACCESS_TOKEN="${ROLLBAR_ACCESS_TOKEN}" \
--env AWS_COGNITO_USER_POOL_ID="${AWS_COGNITO_USER_POOL_ID}" \
--env AWS_COGNITO_USER_POOL_CLIENT_ID="25jlejh9os80sll6an57quh8ab" \
-it backend-flask-prod
```

create a file `./backend-flask/bin/docker/push/backend-flask-prod`
```sh
#! /usr/bin/bash

ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL

docker tag backend-flask-prod:latest $ECR_BACKEND_FLASK_URL:latest
docker push $ECR_BACKEND_FLASK_URL:latest
```

create a file `./backend-flask/bin/ecs/force-deploy-backend-flask` to force redeploy on ecs

```sh
#! /usr/bin/bash

CLUSTER_NAME="cruddur"
SERVICE_NAME="backend-flask"
TASK_DEFINTION_FAMILY="backend-flask"


LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINTION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN \
--force-new-deployment

#aws ecs describe-services \
#--cluster $CLUSTER_NAME \
#--service $SERVICE_NAME \
#--query 'services[0].deployments' \
#--output table
```

We moved bin from backend-flask to a top level to make things in there absolute path so `./bin/ `

`./bin/docker/build/frontend-react-js`
```sh

#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BUILD_PATH=$(dirname $ABS_PATH)
DOCKER_PATH=$(dirname $BUILD_PATH)
BIN_PATH=$(dirname $DOCKER_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"

docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_YMdvcghdH" \
--build-arg REACT_APP_CLIENT_ID="25jlejh9os80sll6an57quh8ab" \
-t frontend-react-js \
-f "$FRONTEND_REACT_JS_PATH/Dockerfile.prod" \
"$FRONTEND_REACT_JS_PATH/."
```

We moved bin from backend-flask to a top level to make things in there absolute path so `./bin/ `

`./bin/docker/build/backend-flask`

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BUILD_PATH=$(dirname $ABS_PATH)
DOCKER_PATH=$(dirname $BUILD_PATH)
BIN_PATH=$(dirname $DOCKER_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"

docker build \
-f "$BACKEND_FLASK_PATH/Dockerfile.prod" \
-t backend-flask-prod \
"$BACKEND_FLASK_PATH/."

```

So you have to make some changes to some other files:

 bin/db/schema-load

```sh 
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
schema_path="$BACKEND_FLASK_PATH/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

bin/db/seed

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
schema_path="$BACKEND_FLASK_PATH/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```

bin/db/setup

```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
bin_path=$(dirname $ABS_PATH)

source "$bin_path/db/drop"
source "$bin_path/db/create"
source "$bin_path/db/schema-load"
source "$bin_path/db/seed"
python "$bin_path/db/update_cognito_user_ids"
```

### **Fixing the Check Auth Token**
As you may already know, at the moment the token wont update.
To do this replace the checkAuth.js with the following code

```py
import { Auth } from 'aws-amplify';
import { resolvePath } from 'react-router-dom';

export async function getAccessToken(){
  Auth.currentSession()
  .then((cognito_user_session) => {
    const access_token = cognito_user_session.accessToken.jwtToken
    localStorage.setItem("access_token", access_token)
  })
  .catch((err) => console.log(err));
}

export async function checkAuth(setUser){
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((cognito_user) => {
    setUser({
      cognito_user_uuid: cognito_user.attributes.sub,
      display_name: cognito_user.attributes.name,
      handle: cognito_user.attributes.preferred_username
    })
    return Auth.currentSession()
  }).then((cognito_user_session) => {
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));
};
```

Replace and add the following code for the following file to the files below

```py
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

import {getAccessToken} from '../lib/CheckAuth';
```


```py
  await getAccessToken()
  const access_token = localStorage.getItem("access_token")
```


```py
Authorization': `Bearer ${access_token}`
```

- `frontend-react-js/src/components/MessageForm.js` (the first line of code)
- `frontend-react-js/src/pages/HomeFeedPage.js`   (the first line of code)
- `frontend-react-js/src/pages/MessageGroupNewPage.js`   (the first line of code)
- `frontend-react-js/src/pages/MessageGroupPage.js`   (the first line of code)
- `frontend-react-js/src/components/MessageForm.js`   (the second line of code)



# Configuring Container Insights BY Implementing Xray 

on our task definition backend and frontend, add the following part for the xray
```json
{
      "name": "xray",
      "image": "public.ecr.aws/xray/aws-xray-daemon" ,
      "essential": true,
      "user": "1337",
      "portMappings": [
        {
          "name": "xray",
          "containerPort": 2000,
          "protocol": "udp"
        }
      ]
    },
```

create the script to create the new task definition
on the folder aws-bootcamp-cruddur-2023/bin/backend create a file called register.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/backend-flask.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```

do the same thing for the frontend
on the folder aws-bootcamp-cruddur-2023/bin/frontend create a file called register.

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/frontend-react-js.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```

on the folder aws-bootcamp-cruddur-2023/bin/backend create a file called run.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/backend-flask.env"

docker run --rm \
--env-file $ENVFILE_PATH \
--network cruddur-net \
--publish 4567:4567 \
-it backend-flask-prod

```
NOTE:
add the  /bin/bash after the -it backend-flask-prod if you want to shell inside the contianer.

on the folder aws-bootcamp-cruddur-2023/bin/frontend create a file called run.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/frontend-react-js.env"

docker run --rm \
--env-file $ENVFILE_PATH \
--network cruddur-net \
--publish 3000:3000 \
-it frontend-react-js-prod

```

change the code of the docker-compose-gitpod.yml of the backend

```sh
environment:
      AWS_ENDPOINT_URL: "http://dynamodb-local:8000"
      #CONNECTION_URL: "${PROD_CONNECTION_URL}"
      CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"
      #FRONTEND_URL: "https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
      #BACKEND_URL: "https://${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      OTEL_SERVICE_NAME: 'backend-flask'
      OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
      OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      #AWS_XRAY_URL: "*${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
      #env var for jwttoken
      AWS_COGNITO_USER_POOL_ID: "${AWS_USER_POOLS_ID}"
      AWS_COGNITO_USER_POOL_CLIENT_ID: "${APP_CLIENT_ID}"
```

with the following code
```
  env_file:
      - backend-flask.env
```

same thing for the frontend

```sh
environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      #REACT_APP_BACKEND_URL: "https://${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
      REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
      #REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID: ""
      REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_USER_POOLS_ID: "${AWS_USER_POOLS_ID}"
      REACT_APP_CLIENT_ID: "${APP_CLIENT_ID}"
```

with the following code

```sh
  env_file:
      - frontend-react-js.env
```

Since the file env does not pass the value of the env var, there is additional implementation that needs to be done.

create a file generate-env-gitpod under the aws-bootcamp-cruddur-2023/bin/backend

and paste the following code
```sh
#! /usr/bin/env ruby

require 'erb'

template = File.read 'erb/backend-flask-gitpod.env.erb'
content = ERB.new(template).result(binding)
filename = "backend-flask.env"
File.write(filename, content)

```


create a file generate-env-gitpod under the aws-bootcamp-cruddur-2023/bin/frontend

and paste the following code
```sh
#! /usr/bin/env ruby

require 'erb'

template = File.read 'erb/frontend-react-js-gitpod.env.erb'
content = ERB.new(template).result(binding)
filename = "frontend-react-js.env"
File.write(filename, content)

```

create  a folder called erb and create the following file backend-flask-gitpod.env.erb under erb folder


```sh
AWS_ENDPOINT_URL=http://dynamodb-local:8000
CONNECTION_URL=postgresql://postgres:password@db:5432/cruddur
FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
OTEL_SERVICE_NAME=backend-flask
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=<%= ENV['HONEYCOMB_API_KEY'] %>
AWS_XRAY_URL=*4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>*
AWS_XRAY_DAEMON_ADDRESS=xray-daemon:2000
AWS_DEFAULT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
AWS_ACCESS_KEY_ID=<%= ENV['AWS_ACCESS_KEY_ID'] %>
AWS_SECRET_ACCESS_KEY=<%= ENV['AWS_SECRET_ACCESS_KEY'] %>
ROLLBAR_ACCESS_TOKEN=<%= ENV['ROLLBAR_ACCESS_TOKEN'] %>
AWS_COGNITO_USER_POOL_ID=<%= ENV['AWS_USER_POOLS_ID'] %>
AWS_COGNITO_USER_POOL_CLIENT_ID=<%= ENV['APP_CLIENT_ID'] %>

```

create  a folder called erb and create the following file frontend-react-js-gitpod.env.erb 

```sh
REACT_APP_BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_AWS_PROJECT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_COGNITO_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_USER_POOLS_ID=<%= ENV['AWS_USER_POOLS_ID'] %>
REACT_APP_CLIENT_ID=<%= ENV['APP_CLIENT_ID'] %>
```

from the gitpod.yml add the scripts to create the files env necessary for the backend and frontend dockers.
```sh
  source  "$THEIA_WORKSPACE_ROOT/bin/backend/generate-env-gitpod"
  source  "$THEIA_WORKSPACE_ROOT/bin/frontend/generate-env-gitpod
```


In this part of the implementation, we link all the containers to connect with a specific network.
change the configuration of your docker-compose.yml
```yml
networks: 
  internal-network:
    driver: bridge
    name: cruddur
```
with the following code

```yml
networks: 
  cruddur-net:
    driver: bridge
    name: cruddur-net
```

and for each services, make sure to attach the crudduer-net network by adding the following code
```yml
  networks:
      - cruddur-net
```

to troublshoot, you can use a busy box.
create a file under aws-bootcamp-cruddur-2023/bin called busybox
and paste the following code
```yml
#! /usr/bin/bash

docker run --rm \
  --network cruddur-net \
  -p 4567:4567 \
  -it busybox
```

also we can add some tools such as ping on our dockerfile.prod
after url of the image. this is for the debugging

```sh
RUN apt-get update -y
RUN apt-get install iputils-ping -y
```
# Enable Container Insights

To enable this function, go to the cluster and click on update cluster.

Under the section Monitoring, toggle on Use Container Insights

# Implementation Time Zone

from the ddb/seed change the following line of code

```
now = datetime.now(timezone.utc).astimezone()
```

with the following

```
now = datetime.now()
```
from the same file, change also the following code
```
  created_at = (now + timedelta(hours=-3) + timedelta(minutes=i)).isoformat()
```
with the following

```
  created_at = (now - timedelta(days=1) + timedelta(minutes=i)).isoformat()
```

from the ddb.py change the following code
```
 now = datetime.now(timezone.utc).astimezone().isoformat()
created_at = now
```

with the following
```
created_at = datetime.now().isoformat()

```

from the frontend-react-js/src/lib/ create a file called DateTimeFormats.js with the following code
```py
import { DateTime } from 'luxon';

export function format_datetime(value) {
  const datetime = DateTime.fromISO(value, { zone: 'utc' })
  const local_datetime = datetime.setZone(Intl.DateTimeFormat().resolvedOptions().timeZone);
  return local_datetime.toLocaleString(DateTime.DATETIME_FULL)
}

export function message_time_ago(value){
  const datetime = DateTime.fromISO(value, { zone: 'utc' })
  const created = datetime.setZone(Intl.DateTimeFormat().resolvedOptions().timeZone);
  const now     = DateTime.now()
  console.log('message_time_group',created,now)
  const diff_mins = now.diff(created, 'minutes').toObject().minutes;
  const diff_hours = now.diff(created, 'hours').toObject().hours;

  if (diff_hours > 24.0){
    return created.toFormat("LLL L");
  } else if (diff_hours < 24.0 && diff_hours > 1.0) {
    return `${Math.floor(diff_hours)}h`;
  } else if (diff_hours < 1.0) {
    return `${Math.round(diff_mins)}m`;
  } else {
    console.log('dd', diff_mins,diff_hours)
    return 'unknown'
  }
}

export function time_ago(value){
  const datetime = DateTime.fromISO(value, { zone: 'utc' })
  const future = datetime.setZone(Intl.DateTimeFormat().resolvedOptions().timeZone);
  const now     = DateTime.now()
  const diff_mins = now.diff(future, 'minutes').toObject().minutes;
  const diff_hours = now.diff(future, 'hours').toObject().hours;
  const diff_days = now.diff(future, 'days').toObject().days;

  if (diff_hours > 24.0){
    return `${Math.floor(diff_days)}d`;
  } else if (diff_hours < 24.0 && diff_hours > 1.0) {
    return `${Math.floor(diff_hours)}h`;
  } else if (diff_hours < 1.0) {
    return `${Math.round(diff_mins)}m`;
  }
}
```

 do some modifications for the following `messageitem.js`

 

remove the following code

```js
import { DateTime } from 'luxon';

// with

import { format_datetime, message_time_ago } from '../lib/DateTimeFormats';
```

same for the following code
```js
<div className="created_at" title={props.message.created_at}>
<span className='ago'>{format_time_created_at(props.message.created_at)}</span> 

// with the new

  <div className="created_at" title={format_datetime(props.message.created_at)}>
  <span className='ago'>{message_time_ago(props.message.created_at)}</span> 
```

replace also this part of the code
```js
<Link className='message_item' to={`/messages/@`+props.message.handle}>
<div className='message_avatar'></div>

// with the following

 <div className='message_item'>
      <Link className='message_avatar' to={`/messages/@`+props.message.handle}></Link>
```

and do remove the following
```css
 </Link>

/* with */

 </div>
```

from the `messageitem.css` do the following changes

move portion of the code
```css
 cursor: pointer;
text-decoration: none;
```

add  the following code
```css

.message_item .avatar {
  cursor: pointer;
  text-decoration: none;
}

```

do the same for the following `messagegroupitem.js`

remove the following code

```js
import { DateTime } from 'luxon';

// and replace with 

import { format_datetime, message_time_ago } from '../lib/DateTimeFormats';
```

same for the following code
```js
   <div className="created_at" title={props.message_group.created_at}>
  <span className='ago'>{format_time_created_at(props.message_group.created_at)}</span> 

// and replace with the following

<div className="created_at" title={format_datetime(props.message_group.created_at)}>
<span className='ago'>{message_time_ago(props.message_group.created_at)}</span> 
```

remove also this portion of the code
```js
const format_time_created_at = (value) => {
    // format: 2050-11-20 18:32:47 +0000
    const created = DateTime.fromISO(value)
    const now     = DateTime.now()
    const diff_mins = now.diff(created, 'minutes').toObject().minutes;
    const diff_hours = now.diff(created, 'hours').toObject().hours;

    if (diff_hours > 24.0){
      return created.toFormat("LLL L");
    } else if (diff_hours < 24.0 && diff_hours > 1.0) {
      return `${Math.floor(diff_hours)}h`;
    } else if (diff_hours < 1.0) {
      return `${Math.round(diff_mins)}m`;
    }
  };
```

from the `activitycontent.js` do the following amendments:

remove the following code
```js
import { DateTime } from 'luxon';

// and replace with

import { format_datetime, time_ago } from '../lib/DateTimeFormats';
```

and change the following code
```js
  <div className="created_at" title={props.activity.created_at}>
  <span className='ago'>{format_time_created_at(props.activity.created_at)}</span> 

// with the following

<div className="created_at" title={format_datetime(props.activity.created_at)}>
<span className='ago'>{time_ago(props.activity.created_at)}</span> 
```

remove also this portion of the code
```js
 const format_time_created_at = (value) => {
    // format: 2050-11-20 18:32:47 +0000
    const past = DateTime.fromISO(value)
    const now     = DateTime.now()
    const diff_mins = now.diff(past, 'minutes').toObject().minutes;
    const diff_hours = now.diff(past, 'hours').toObject().hours;

    if (diff_hours > 24.0){
      return past.toFormat("LLL L");
    } else if (diff_hours < 24.0 && diff_hours > 1.0) {
      return `${Math.floor(diff_hours)}h ago`;
    } else if (diff_hours < 1.0) {
      return `${Math.round(diff_mins)}m ago`;
    }
  };

  const format_time_expires_at = (value) => {
    // format: 2050-11-20 18:32:47 +0000
    const future = DateTime.fromISO(value)
    const now     = DateTime.now()
    const diff_mins = future.diff(now, 'minutes').toObject().minutes;
    const diff_hours = future.diff(now, 'hours').toObject().hours;
    const diff_days = future.diff(now, 'days').toObject().days;

    if (diff_hours > 24.0){
      return `${Math.floor(diff_days)}d`;
    } else if (diff_hours < 24.0 && diff_hours > 1.0) {
      return `${Math.floor(diff_hours)}h`;
    } else if (diff_hours < 1.0) {
      return `${Math.round(diff_mins)}m`;
    }
  };
```

do the same changes for the following line
```js
 <span className='ago'>{format_time_expires_at(props.activity.expires_at)}</span>

//  with the following

 <span className='ago'>{time_ago(props.activity.expires_at)}</span>
 ```

amend the following code
 ```js
     expires_at =  <div className="expires_at" title={props.activity.expires_at}>

// with the new one

   expires_at =  <div className="expires_at" title={format_datetime(props.activity.expires_at)}>
```

### Challanges faced
1) errors in app.py
__import__(module_name)
File "/backend-flask/app.py", line 109, in <module>
@app.before_first_request
AttributeError: 'Flask' object has no attribute 'before_first_request'.
Did you mean: '_got_first_request'?

solution :# @app.before_first_request
with app.app_context():
  def init_rollbar():



2) Errors from aws-cli which costed several errors

- Unknown options: --service-connect-defaults, namespace=cruddur

- error when trying to create task definitions

```
Parameter validation failed:
Unknown parameter in containerDefinitions[0].portMappings[0]: "name", must be one of: containerPort, hostPort, protocol
Unknown parameter in containerDefinitions[0].portMappings[0]: "appProtocol", must be one of: containerPort, hostPort, protocol
```
solution : changed before to init in the gitpod.yml and make sure when turning your encironment on the aws-cli installs

3) When implementing messaging in production, when i try to send a message as bayko, I get this error.  
`Unexpected token '<', "<!doctype "... is not valid JSON, {type: 'cors', url: , redirected: false, status: 401, 401', When implementing messaging in production, when i try to send a message as bayko, I get this error.  `
Fixed it by , The problem is the uuid_cognito_user field for the 2 users that she was trying to send messages had value mock. using this code 
`update users set cognito_user_id='afc0e30b-63ab-4b46-8aea-789cf14b10d9' where handle='andrewbrown';`