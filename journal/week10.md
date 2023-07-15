# Week 10 — CloudFormation Part 1

<!-- # Description:
<!-- # Parameters:
<!-- # Mappings: -->
<!-- # Resources: -->
<!-- # Outputs: -->
<!-- # Metadata: --> 



Cloudformation will help us to setup our AWS resources so that we can spend less time creating or managing those resourses and more time developing our application. 

#### Cost
In Cloudformation, you only pay for what you use, with no minimum fees and no required upfront commitment. If you are using a registry extension with cloudformation, you incur charges per handler operation., Handler operations are: CREATE, UPDATE, DELETE, READ, or LIST actions on a resource type and CREATE, UPDATE, or DELETE actions for Hook type.


#### Best security practices for cfn

+ Least Privilege
+ Secure IAM Roles
+ Secure Template Storage
+ Parameter Encryption
+ Enable AWS CloudTrail
+ Validate Templates
+ Secure Parameter Values
+ Enable Stack Termination Protection
+ Regularly Update AWS CLI and SDKs
+ Regular Auditing and Monitoring


## CFN Live Streaming
create a file called template.yaml under the aws/cfn with the following structure


```yml

AWSTempleteFormatVersion: 2010-09-09
Description: |
    Setup ECS Cluster

Resources:
  ECSCluster: #Logical Name 
    Type: 'AWS::ECS::Cluster'
    Properties:
        ClusterName: MyCluster
        CapacityProviders:
            - FARGATE
#Parameters:
#Mappings:
#Resources:
#Outputs:
#Metadata


```

Note: 
- Some aws services want the extension `.yml`. An example is `buildspec` (codebuild). Other services like cloudformation want the `.yaml`` extension. For some samples, you can reference the  [aws templates](https://aws.amazon.com/cloudformation/resources/templates/)


Create an s3 bucket in the same region using the following command:

```bash
export RANDOM_STRING=$(aws secretsmanager get-random-password --exclude-punctuation --exclude-uppercase --password-length 6 --output text --query RandomPassword)
aws s3 mb s3://cfn-artifacts-$RANDOM_STRING

export CFN_BUCKET="cfn-artifacts-$RANDOM_STRING"

gp env CFN_BUCKET="cfn-artifacts-$RANDOM_STRING"
```
Note: This command creates an S3 Bucket called `cfn-artifacts-xxxxxx`. The xxxxxx will be generated randomly by the secret manager.

- To deploy the cloudformation, create a folder called  `cfn` and inside call the script `deploy`

```sh
#! /usr/bin/env bash
set -e # stop execution of the script if it fails

#This script will pass the value of the main root in case you use a local dev
export THEIA_WORKSPACE_ROOT=$(pwd)
echo $THEIA_WORKSPACE_ROOT


CFN_PATH="$THEIA_WORKSPACE_ROOT/aws/cfn/template.yaml"

cfn-lint $CFN_PATH
aws cloudformation deploy \
  --stack-name "Cruddur" \
  --template-file $CFN_PATH \
  --s3-bucket cfn-artifacts-$RANDOM_STRING \
  --no-execute-changeset \
  --capabilities CAPABILITY_NAMED_IAM
```
Note: 
- the   `--no-execute-changeset` will validate the code but not execute it.
- Once you run the command, the cli will create a script to check the outcome. you can use the code generated or check it on the cloud formation via the console.
- changeset in the console is useful to understand the behaviour of the change and to see if there is a difference in your infrastructure (i.e a critical database run in production. By seeing the changeset you know if the resource will be removed). check also the Update requires voice in the [documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-service.html)
- check the tab `replacement` if it is `true`. this helps to see if one part of the stack will be replaced.

from the aws console, check the stack deploy and see what has been deployed. click on `execute` change set`

Install cfn lint using the following command
```bash
pip install cfn-lint
```

and also add into gitpod.yml/.devcontainer file so it is installed in your cloud environment such as codespaces or gitpod.

```yaml
- name: CFN
    before: |
      pip install cfn-lint
      cargo install cfn-guard
      gen install cfn-toml
```

Create a `task-definition.guard` under the `aws/cfn`

```guard
aws_ecs_cluster_configuration {
  rules = [
    {
      rule = "task_definition_encryption"
      description = "Ensure task definitions are encrypted"
      level = "error"
      action {
        type = "disallow"
        message = "Task definitions in the Amazon ECS cluster must be encrypted"
      }
      match {
        type = "ecs_task_definition"
        expression = "encrypt == false"
      }
    },
    {
      rule = "network_mode"
      description = "Ensure Fargate tasks use awsvpc network mode"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must use awsvpc network mode"
      }
      match {
        type = "ecs_task_definition"
        expression = "network_mode != 'awsvpc'"
      }
    },
    {
      rule = "execution_role"
      description = "Ensure Fargate tasks have an execution role"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must have an execution role"
      }
      match {
        type = "ecs_task_definition"
        expression = "execution_role == null"
      }
    },
  ]
}

```

Note: cfn-guard is an open-source command line interface (CLI) that checks CloudFormation templates for policy compliance using a simple, policy-as-code, declarative language. for more details refer to the following [link](https://github.com/aws-cloudformation/cloudformation-guard)

to install cfn-guard 
```bash
cargo install cfn-guard
```

launch the following command
```bash
cfn-guard rulegen --template /workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml
```

it will give the following result
```
let aws_ecs_cluster_resources = Resources.*[ Type == 'AWS::ECS::Cluster' ]
rule aws_ecs_cluster when %aws_ecs_cluster_resources !empty {
  %aws_ecs_cluster_resources.Properties.CapacityProviders == ["FARGATE"]
  %aws_ecs_cluster_resources.Properties.ClusterName == "MyCluster"
}
```

copy the following code and create a file called `ecs-cluster.guard` under `aws/cfn`

and run the following command
```
cfn-guard validate -r ecs-cluster.guard
```
Note: make sure to be in the directory where is the file




### 1. Starting with the `newtorking layer` of the infrastructure. CFN Network Template


1. Before you run any templates, be sure to create an S3 bucket to contain
all of our artifacts for CloudFormation.

```
aws s3 mk s3://cfn-artifactscruddur
export CFN_BUCKET="cfn-artifactscruddur"
gp env CFN_BUCKET="cfn-artifactscruddur"
```
> remember bucket names are unique to the provide code example you may need to adjust


- Create a folder `cfn` in aws folder, and create another folder in the cfn folder named `networking`

- Create a file `template.yml`

- Create a file called `template.yaml` under the path `aws/cfn/networking`

This file will contain the structure of our network layer such as VPC, Internet Gateway, Route tables and 6 Public/Private Subnets, route table, and the outpost.

```yml

AWSTemplateFormatVersion: "2010-09-09"


AWSTemplateFormatVersion: "2010-09-09"


## Block definations[What is expected in a block]
# Parameters:
# Mappings:
# Resources:
# Outputs:
# Metadata
# =============================
# VPC
# IGW
# Route Tables
# Subnet A
# Subnet B
# Subnet C



Description: |
  The base networking components for our stack:
  - VPC
    - sets DNS hostnames for EC2 instances
    - Only IPV4, IPV6 is disabled
  - InternetGateway
  - Route Table
    - route to the IGW
    - route to Local
  - 6 Subnets Explicity Associated to Route Table
    - 3 Public Subnets numbered 1 to 3
    - 3 Private Subnets numbered 1 to 3
Parameters:
  VpcCidrBlock:
    Type: String
    Default: 10.0.0.0/16
  Az1:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1a
  SubnetCidrBlocks: 
    Description: "Comma-delimited list of CIDR blocks for our private public subnets"
    Type: CommaDelimitedList
    Default: >
      10.0.0.0/24, 
      10.0.4.0/24, 
      10.0.8.0/24, 
      10.0.12.0/24,
      10.0.16.0/24,
      10.0.20.0/24
  Az2:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1b
  Az3:
    Type: AWS::EC2::AvailabilityZone::Name
    Default: us-east-1c

Resources:
  VPC:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidrBlock
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags:
        - Key: Name
          Value: !Sub "${AWS::StackName}VPC"

  IGW:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-internetgateway.html
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}IGW"
  AttachIGW:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc-gateway-attachment.html
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref IGW

  RouteTable:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-routetable.html
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId:  !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}RT"
  RouteToIGW:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-route.html
    Type: AWS::EC2::Route
    DependsOn: AttachIGW
    Properties:
      RouteTableId: !Ref RouteTable
      GatewayId: !Ref IGW
      DestinationCidrBlock: 0.0.0.0/0

  SubnetPub1:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az1
      CidrBlock: !Select [0, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: true #public subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPub1"
  SubnetPub2:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az2
      CidrBlock: !Select [1, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: true #public subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPub2"
  SubnetPub3:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az3
      CidrBlock: !Select [2, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: true #public subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPub3"
  SubnetPriv1:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az1
      CidrBlock: !Select [3, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: false #private subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPriv1"
  SubnetPriv2:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az2
      CidrBlock: !Select [4, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: false #private subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPriv2"
  SubnetPriv3:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: !Ref Az3
      CidrBlock: !Select [5, !Ref SubnetCidrBlocks]
      EnableDns64: false
      MapPublicIpOnLaunch: false #private subnest
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}SubnetPriv3"
  SubnetPub1RTAssociation:
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub1
      RouteTableId: !Ref RouteTable
  SubnetPub2RTAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub2
      RouteTableId: !Ref RouteTable
  SubnetPub3RTAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPub3
      RouteTableId: !Ref RouteTable
  SubnetPriv1RTAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv1
      RouteTableId: !Ref RouteTable
  SubnetPriv2RTAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv2
      RouteTableId: !Ref RouteTable
  SubnetPriv3RTAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetPriv3
      RouteTableId: !Ref RouteTable

Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}VpcId"
  VpcCidrBlock:
    Value: !GetAtt VPC.CidrBlock
    Export:
      Name: !Sub "${AWS::StackName}VpcCidrBlock"
  SubnetCidrBlocks:
    Value: !Join [",", !Ref SubnetCidrBlocks]
    Export:
      Name: !Sub "${AWS::StackName}SubnetCidrBlocks"
  PublicSubnetIds:
    Value: !Join 
      - ","
      - - !Ref SubnetPub1
        - !Ref SubnetPub2
        - !Ref SubnetPub3
    Export:
      Name: !Sub "${AWS::StackName}PublicSubnetIds"
  PrivateSubnetIds:
    Value: !Join 
      - ","
      - - !Ref SubnetPriv1
        - !Ref SubnetPriv2
        - !Ref SubnetPriv3
    Export:
      Name: !Sub "${AWS::StackName}PrivateSubnetIds"
  AvailabilityZones:
    Value: !Join 
      - ","
      - - !Ref Az1
        - !Ref Az2
        - !Ref Az3
    Export:
      Name: !Sub "${AWS::StackName}AvailabilityZones"



```


Install cfn-toml `gen install cfn-toml` which is used by ruby, so we can pass the parameters.
*note you will be creating a NEW CFN-STACK  in which the code is placed in the `network-deploy` file*

- Create  cfn-toml files `aws/cfn/networking/config.toml`
`config.toml`

```
[deploy]
bucket = 'cfn-artifactscruddur'
region = 'us-east-1'
stack_name = 'CrdNet'

```
```
[deploy]
bucket = ''
region = ''
stack_name = ''

```
*- *If you want to get the list of your region `aws ec2 describe-availability-zones --region $AWS_DEFAULT_REGION`*
**Note: If you have set `$AWS_DEFAULT_REGION`, this is the region that you have inserted in your env vars either locally or on Gitpod/Codespace*

- Change the cluster script `deploy` you  created earlier to `networking-deploy` for changeset

```sh

#! /usr/bin/env bash
set -e # stop the execution of the script if it fails

CFN_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"

CONFIG_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/networking/config.toml"

CFN_PATH="/workspaces/aws-bootcamp-cruddur-2023/aws/cfn/networking/template.yaml"

CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/networking/config.toml"

echo $CFN_PATH

cfn-lint $CFN_PATH

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)

aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --s3-bucket $BUCKET \
  --region $REGION \
  --template-file "$CFN_PATH" \
  --no-execute-changeset \
  --capabilities CAPABILITY_NAMED_IAM

```
- Then run `./bin/cfn/networking-deploy` to deploy `template.yaml` to the cluster

- Then go the cluster created, navigate to the change set and apply the recent deplayed change set 





### 2. Starting with the `ECS Fargate Cluster` of the infrastructure. CFN Network Template
*note you will be creating a NEW CFN-STACK  in which the code is placed in the `network-deploy` file*

Install cfn-toml `gen install cfn-toml` which is used by ruby, so we can pass the parameters.

- Create  cfn-toml files `aws/cfn/cluster/config.toml`

`config.toml`
```
[deploy]
bucket = 'cfn-artifactscruddur'
region = 'us-east-1'
stack_name = 'CrdCluster'

[parameters]
CertificateArn = 'arn:aws:acm:ca-central-1:387543059434:certificate/3c49f37a-a67c-43a4-adb0-53e38d8892dd'

NetworkingStack = 'CrdNet'
```
```
[deploy]
bucket = ''
region = ''
stack_name = ''

[parameters]
CertificateArn = ''
```

- Change the cluster script `deploy` you  created earlier to `cluster-deploy` for changeset

```sh
#! /usr/bin/env bash
set -e # stop the execution of the script if it fails

## VScode
# CFN_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/cluster/template.yaml"
# CONFIG_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/cluster/config.toml"

CFN_PATH="/workspaces/aws-bootcamp-cruddur-2023/aws/cfn/service/template.yaml"
CONFIG_PATH="/workspaces/aws-bootcamp-cruddur-2023/aws/cfn/service/config.toml"
echo $CFN_PATH

cfn-lint $CFN_PATH

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
# PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --s3-bucket $BUCKET \
  --region $REGION \
  --template-file "$CFN_PATH" \
  --no-execute-changeset \
  --tags group=cruddur-backend-flask \
  --capabilities CAPABILITY_NAMED_IAM
  #--parameter-overrides $PARAMETERS \
```


- Create a folder `cfn` in aws folder, and create another folder in the cfn folder named `cluster`

- Create a file `template.yml`

- Create a file called `template.yaml` under the path `aws/cfn/cluster`

This file will contain the structure of our `ECS Fargate cluster` such as NetworkingStack, FargateCluster, ALB, Listeners, ALB Security Group,Target Groups and the outpost.

```yml

##### to long#

# This file is for Creating ECS Fargate Cluster

## Block definations[What is expected in a block]
# Parameters:
# Mappings:
# Resources:
# Outputs:
# Metadata
# =============================
# NetworkingStack
# FargateCluster
# ALB 
# Listeners
# ALB Security Group
# Target Groups


Description: |
  The networking and cluster configuration to support fargate containers
  - ECS Fargate Cluster
  - Application Load Balanacer (ALB)
    - ipv4 only
    - internet facing
    - certificate attached from Amazon Certification Manager (ACM)
  - ALB Security Group
  - HTTPS Listerner
    - send naked domain to frontend Target Group
    - send api. subdomain to backend Target Group
  - HTTP Listerner
    - redirects to HTTPS Listerner
  - Backend Target Group
  - Frontend Target Group

##### to long#

```

- Then run `./bin/cfn/cluster-deploy` to deploy `template.yaml` to the cluster

- Then go the cluster created, navigate to the change set and apply the recent deplayed change set 



### 3.  Starting with the `ECS Service Layer` of the infrastructure. CFN Network Template
*note you will be creating a NEW CFN-STACK  in which the code is placed in the `service-deploy` file*



- Create  cfn-toml files `aws/cfn/service/config.toml`

`config.toml`
```
[deploy]
bucket = 'cfn-artifactscruddur'
region = 'us-east-1'
stack_name = 'CrdSrvBackendFlask'
```
```
[deploy]
bucket = ''
region = ''
stack_name = ''
```

- Change the cluster script `deploy` you  created earlier to `service-deploy` for changeset

```sh
#! /usr/bin/env bash
set -e # stop the execution of the script if it fails

# CFN_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/cluster/template.yaml"
# CONFIG_PATH="/mnt/c/DevOps/aws-bootcamp-cruddur-2023/aws/cfn/cluster/config.toml"

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/template.yaml"
CONFIG_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/cluster/config.toml"
echo $CFN_PATH

cfn-lint $CFN_PATH

BUCKET=$(cfn-toml key deploy.bucket -t $CONFIG_PATH)
REGION=$(cfn-toml key deploy.region -t $CONFIG_PATH)
STACK_NAME=$(cfn-toml key deploy.stack_name -t $CONFIG_PATH)
PARAMETERS=$(cfn-toml params v2 -t $CONFIG_PATH)

aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --s3-bucket $BUCKET \
  --region $REGION \
  --template-file "$CFN_PATH" \
  --no-execute-changeset \
  --tags group=cruddur-cluster \
  --parameter-overrides $PARAMETERS \
  --capabilities CAPABILITY_NAMED_IAM
```
 - create a file in `aws/json/service-backend-flask.CFN.json` and add these:

 ```js
{
  "cluster": "CrdClusterFargateCluster",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
    {
        "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:319506457158:loadbalancer/app/CrdClusterALB/d542f23d3635ebbd",
        "containerName": "backend-flask",
        "containerPort": 4567
    }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-0e51bc0876edb8728"
      ],
      "subnets": [
        "subnet-03937a2231049a334",
        "subnet-081314a7dac239d45",
        "subnet-0b3a1a3d92fded0ec"
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
}
 ```

- Create a file in `bin/backend` named` create-serviceCFN` and add these:

```sh
#! /usr/bin/bash

CLUSTER_NAME="CrdClusterFargateCluster"
SERVICE_NAME="backend-flask"
TASK_DEFINTION_FAMILY="backend-flask"


LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINTION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

echo "TASK DEF ARN:"
echo $LATEST_TASK_DEFINITION_ARN

aws ecs create-service \
--cluster $CLUSTER_NAME \
--service-name $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN

```

- Create a folder `cfn` in aws folder, and create another folder in the cfn folder named `cluster`

- Create a file `template.yml`

- Create a file called `template.yaml` under the path `aws/cfn/cluster`

This file will contain the structure of our `ECS Fargate cluster` such as NetworkingStack, FargateCluster, ALB, Listeners, ALB Security Group,Target Groups and the outpost.

```yml

#### too long

```

- Then run `./bin/cfn/cluster-deploy` to deploy `template.yaml` to the cluster

- Then go the cluster created, navigate to the change set and apply the recent deplayed change set 



### Links to Achitectural Diagrams

[Network layer](http://bitly.ws/JdmD)










## Debug

to debug try to check `cloudtrail` to see the error

to validate the yaml/json template, use the following command
```bash
​aws cloudformation validate-template --template-body file:///workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml
```

another tool is to use `cfn lint`

Install cfn lint using the following command
```bash
pip install cfn-lint
```

and the run the following command
```bash
cfn-lint /workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml
```

Use the cloud formation designer if you want to convert your yaml file to json or viceversa.

### Reference

- [AWS Cloudformation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)

