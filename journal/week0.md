# Week 0 — Billing and Architecture



### Install and verify AWS CLI

I installed the aws cli using gitpod, i downloaded my credential from aws and added them to gitpod.

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

