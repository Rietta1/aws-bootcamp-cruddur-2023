# Week 0 — Billing and Architecture



### Install and verify AWS CLI

I installed the aws cli using gitpod, i downloaded my credential from aws and added them to gitpod.

### Created IAM User

i created IAM user and added authentication using Authy because i can use Authy on both mobile phones and desktop, i gave the user admin privellages by creating a user group and adding it.

![MFA Setup](https://user-images.githubusercontent.com/101978292/219798601-633697d8-af7d-4b41-8e68-f96026593740.jpg)

### Create a Budget

- I created my own Budget for $3 because that is how much spend i can afford.

- I did not create a second Budget because i created a billing alarm using **cloudwatch** and **sns**, and i also setup **85% freeteir use alert** and i was also concerned of budget spending going over the 2 budget free limit.

- I also used the AWS console to Create them because , these was amongst the first task i carried out before installing the aws cli on gitpod

 

![budgets](https://user-images.githubusercontent.com/101978292/219797553-6aff738e-9148-49b0-ab70-899829855277.jpg)

![eventbridge](https://user-images.githubusercontent.com/101978292/219800399-cb911c2b-d294-4087-8aa2-3ac9e97ea845.jpg)


![sns topic](https://user-images.githubusercontent.com/101978292/219799131-53499842-1002-48be-9ac4-ed58dcc63e12.jpg)


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

- Lucid kept crashing at some point

## This week challenge

