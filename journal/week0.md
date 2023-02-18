# Week 0 — Billing and Architecture



### Install and verify AWS CLI

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
i downloaded my credential from aws and added them to gitpod.
We'll also run these commands indivually to perform the install manually

### Create a new User and Generate AWS Credentials

- Go to IAM  create a new user
- `Enable console access` for the user
- Create a new `Admin` Group and apply `AdministratorAccess`
- Create the user and go find and click into the user
- Click on `Security Credentials` and `Create Access Key`
- Choose AWS CLI Access
- Download the CSV with the credentials

### Set Env Vars

We will set these credentials for the current bash terminal
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

### Created IAM User

i created IAM user and added authentication using Authy because i can use Authy on both mobile phones and desktop, i gave the user admin privellages by creating a user group and adding it.


### Create a Budget

- I created my own Budget for $3 because that is how much spend i can afford.

- I did not create a second Budget because i created a billing alarm using **cloudwatch** and **sns**, and i also setup **85% freeteir use alert** and i was also concerned of budget spending going over the 2 budget free limit.

- I also used the AWS console to Create them because , these was amongst the first task i carried out before installing the aws cli on gitpod

![Image of The Budget Alarm I Created]() 


### Recreate Logical Architectural Design


I created the Architectural design

![Cruddur Logical Design](assets/logical-architecture-recreation-diagram.png)

[Lucid Charts Share Link](https://lucid.app/lucidchart/b873ffef-686d-4b5e-ba38-2c223d0ed424/edit?viewport_loc=495%2C228%2C1128%2C649%2C0_0&invitationId=inv_c60d0705-8e5e-4572-880c-28566427ceae
)


### Recreate Conceptual Design

Here is the diagram of the conceptual design



[Lucid Charts Share Link](https://lucid.app/lucidchart/b873ffef-686d-4b5e-ba38-2c223d0ed424/edit?viewport_loc=495%2C228%2C1128%2C649%2C0_0&invitationId=inv_c60d0705-8e5e-4572-880c-28566427ceae
)


### Issues faced

- I was able to access the billing from the IAM user despite giving it full access permission, administrative permission and billing permission

- Lucid kept crashing at some point

## This week challenge

