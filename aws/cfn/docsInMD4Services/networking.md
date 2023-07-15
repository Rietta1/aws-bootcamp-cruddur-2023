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
