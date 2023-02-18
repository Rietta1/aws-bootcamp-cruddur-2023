# Week 0 — Billing and Architecture





### Created IAM User


- Go to IAM  create a new user
- `Enable console access` for the user
- Create a new `Admin` Group and apply `AdministratorAccess` `full access` and `billing access` because i would like my admin to have these privillages
-Go to authenication and create a multi authenication using authy. *Authy because i can use Authy on both mobile phones and desktop, i gave the user admin privellages by creating a user group and adding it.*
- Create the user and go find and click into the user
- Click on `Security Credentials` and `Create Access Key`
- Choose AWS CLI Access
- Download the CSV with the credentials

i created IAM user and added authentication using 

![MFA Setup](https://user-images.githubusercontent.com/101978292/219798601-633697d8-af7d-4b41-8e68-f96026593740.jpg)

### Create a Budget

- I created my own Budget for $3 because that is how much spend i can afford.


- I did not create a second Budget because i created a billing alarm using **cloudwatch** and **sns**, and i also setup **85% freeteir use alert** and i was also concerned of budget spending going over the 2 budget free limit.

- I also used the AWS console to Create them because , these was amongst the first task i carried out before installing the aws cli on gitpod

 

![budgets](https://user-images.githubusercontent.com/101978292/219797553-6aff738e-9148-49b0-ab70-899829855277.jpg)

![eventbridge](https://user-images.githubusercontent.com/101978292/219800399-cb911c2b-d294-4087-8aa2-3ac9e97ea845.jpg)


![sns topic](https://user-images.githubusercontent.com/101978292/219799131-53499842-1002-48be-9ac4-ed58dcc63e12.jpg)

### Install and verify AWS CLI on Gitpod

I installed the aws cli using gitpod using the [documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html )


```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

unzip -u awscliv2.zip

sudo ./aws/install

```



Update our `.gitpod.yml` to include the following task.

```sh
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    init: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
```
I downloaded my credential from aws and added them to gitpod.
and ran these commands indivually to perform the install manually

###  Generate AWS Credentials

- Go to the IAM user just created
- on the Created user and go find and click into the user
- Click on `Security Credentials` and `Create Access Key`
- Choose AWS CLI Access
- Download the CSV with the credentials

### Set Env Vars

Set these credentials for the current bash terminal

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=us-east-1
```

We'll tell Gitpod to remember these credentials if we relaunch our workspaces
```
gp env AWS_ACCESS_KEY_ID=""
gp env AWS_SECRET_ACCESS_KEY=""
gp env AWS_DEFAULT_REGION=us-east-1
``` 
*Note: to remove previous cridentials just rerun the credentials commands empty just as seen above*

![gitpod aws cli](https://user-images.githubusercontent.com/101978292/219803845-05311f37-1a82-4318-a33e-0a62b41a80b1.jpg)

### The CLI command to create billing and budget


### Check that the AWS CLI is working and you are the expected user

```sh
aws sts get-caller-identity
```

You should see something like this:
```json
{
    "UserId": "AIFBZRJIQN2ONP4ET4EK4",
    "Account": "655602346534",
    "Arn": "arn:aws:iam::655602346534:user/andrewcloudcamp"
}
```

### Enable Billing 

We need to turn on Billing Alerts to recieve alerts...


- In your Root Account go to the [Billing Page](https://console.aws.amazon.com/billing/)
- Under `Billing Preferences` Choose `Receive Billing Alerts`
- Save Preferences


### Creating a Billing Alarm

### Create SNS Topic

- We need an SNS topic before we create an alarm.
- The SNS topic is what will delivery us an alert when we get overbilled
- [aws sns create-topic](https://docs.aws.amazon.com/cli/latest/reference/sns/create-topic.html)

We'll create a SNS Topic
```sh
aws sns create-topic --name billing-alarm
```
which will return a TopicARN

We'll create a subscription supply the TopicARN and our Email
```sh
aws sns subscribe \
    --topic-arn TopicARN \
    --protocol email \
    --notification-endpoint your@email.com
```

Check your email and confirm the subscription

#### Create Alarm

- [aws cloudwatch put-metric-alarm](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/put-metric-alarm.html)
- [Create an Alarm via AWS CLI](https://aws.amazon.com/premiumsupport/knowledge-center/cloudwatch-estimatedcharges-alarm/)
- We need to update the configuration json script with the TopicARN we generated earlier
- We are just a json file because --metrics is is required for expressions and so its easier to us a JSON file.

```sh
aws cloudwatch put-metric-alarm --cli-input-json file://aws/json/alarm_config.json
```

### Create an AWS Budget

[aws budgets create-budget](https://docs.aws.amazon.com/cli/latest/reference/budgets/create-budget.html)

Get your AWS Account ID
```sh
aws sts get-caller-identity --query Account --output text
```

- Supply your AWS Account ID
- Update the json files
- This is another case with AWS CLI its just much easier to json files due to lots of nested json

```sh
aws budgets create-budget \
    --account-id AccountID \
    --budget file://aws/json/budget.json \
    --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```


### Recreate Logical Architectural Design


I created the Architectural design

![archtectural daigram](https://user-images.githubusercontent.com/101978292/219797615-68301fcb-766a-4f2a-81e0-3d74cbd34755.jpg)


[Lucid Charts Share Link](https://lucid.app/lucidchart/b873ffef-686d-4b5e-ba38-2c223d0ed424/edit?viewport_loc=495%2C228%2C1128%2C649%2C0_0&invitationId=inv_c60d0705-8e5e-4572-880c-28566427ceae
)


### Recreate Conceptual Design

Here is the diagram of the conceptual design

![conceptual diagram](https://user-images.githubusercontent.com/101978292/219797639-7a983072-cdf8-4f58-b33c-439cba925a78.jpg)


[Lucid Charts Share Link](https://lucid.app/lucidchart/cb69420f-fa70-4965-bfaa-f22e66b93075/edit?invitationId=inv_9c7d7b53-58a5-4f20-bdbe-d3c7789899f9)



### Issues faced

- I was able to access the billing from the IAM user despite giving it full access permission, administrative permission and billing permission

- My cloudshell wont open

- Lucid kept crashing at some point

- I dont really understand how to create how to forecast spend at scale for a million users

## Week0 weekly challenge


I set Set MFA, IAM role
- Go to authenication and create a multi authenication using authy. *Authy because i can use Authy on both mobile phones and desktop, i gave the user admin privellages by creating a user group and adding it.* 
- I created an architectural diagram in Lucid Charts
[Lucid Charts Share Link](https://lucid.app/lucidchart/b873ffef-686d-4b5e-ba38-2c223d0ed424/edit?viewport_loc=495%2C228%2C1128%2C649%2C0_0&invitationId=inv_c60d0705-8e5e-4572-880c-28566427ceae
)



