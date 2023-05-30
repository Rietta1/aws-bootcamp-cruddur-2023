# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

## Technical Task


This week, we built a CI/CD, which stands for Continuous Integration/Continuous Deployment, which is the development software that will help us speed the process of creating, testing, and releasing software.


### CI/CD Security

+ Control resource access with AWS Identity and Access Management (IAM).
+ To safeguard the pipeline, use security controls such as network segmentation and firewalls.
+ Encrypt data while it is in transit and at rest.
+ Implement security testing across the pipeline to detect vulnerabilities as soon as possible.
+ Containerization may be used to segregate and secure application components.
+ Monitor the pipeline for suspicious behavior and respond to events using alerts and automation.


### Create Codepipeline and Codebuild

Go to AWS and search for Codepipeline, then construct a codepipeline using the following values:

Always check the advanced settings as a best practice:

**SOURCE**
-   Go to code pipeline, create a pipeline

<image1

- Add source stage selecting the Source provider GitHub V2 that uses codestar from aws, then click connection to connect your Github with aws:


- Type the desired name for the connection and click connect:

<img width="1435" alt="Week9-GitHubConnection" src="https://user-images.githubusercontent.com/125006062/233819703-e32a857e-fe18-44c8-ac17-8b16ec3b1497.png">


- Authorize aws to connect with github:

<img width="723" alt="Week9-Authorize" src="https://user-images.githubusercontent.com/125006062/233819782-d21a5077-0176-4a88-a0d7-a24b849aac97.png">


- Click install app:

<img width="867" alt="Week9-InstallApp" src="https://user-images.githubusercontent.com/125006062/233819797-1f4f5a12-d7ff-472e-b740-3fcad1a6f360.png">


- Select just the repository that you wish to connect with aws, in this case will be aws-bootcamp-cruddur-2023:

- Finish the connection clicking connect:

<img width="879" alt="Week9-GithubApp" src="https://user-images.githubusercontent.com/125006062/233819885-875e6e66-432e-47b6-91ca-418b84db80aa.png">


- If the connection was successful with appear "ready to connect": 

- Go to github and create a "prod" branch by clicking on branch:

- Choose desired Repository

- Then click new branch and name it "prod" for production:

<img 2

- Click Output artifact format '
CodePipeline default'

- On the codepipeline settings select your repository, then the new branch just created:

- Variable namespace 'SourceVariables`

- Output artifacts 'SourceArtifact'

**BUILD**
You can Skip the build step and continue:

OR

Go to code build and create a build:

- Action name `Build`
- Action provider `AWS CodeBuild`
- Region `US East`
- Input artifacts `SourceArtifact`
- Project name `cruddur-backend-flask-bake-image`
- Build type `Single build`
- Output artifacts `ImageDefinition`


<images> build


**DEPLOY**
- in deploy option select ecs option and backend-flask

- Action name `Deploy`
- Action provider `Amazon ECS`
- Region `US East`
- Input artifacts `ImageDefinition`
- Cluster name `cruddur`
- Service name `backend-flask`
- Image definitions file - optional `imagedefinitions.json`
- Review the settings and create the pipeline:

<image deploy>




### Issues documentation

I was able to complete the required assignment. I faced a problem

1. i got these error when trying to use codebuild "CodeBuild Error: Cannot have more than 0 builds in queue for the account". Apparently, There are various account-level quotas that AWS sets for some new and existing accounts, i contacted support and requested the restriction on my account to be lifted and i should be allowed about 10 builds

2. Codebuild access denied when running pipeline

Error log:

      [Container] 2023/04/23 08:31:04 Running command aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL

      An error occurred (AccessDeniedException) when calling the GetAuthorizationToken operation: User: arn:aws:sts::250283220840:assumed-role/codebuild-cruddur-backend--service-role/AWSCodeBuild-3158ce99-75d4-4547-87a6-87a6080d7969 is not authorized to perform: ecr:GetAuthorizationToken on resource: * because no identity-based policy allows the ecr:GetAuthorizationToken action
      Error: Cannot perform an interactive login from a non TTY device

      [Container] 2023/04/23 08:31:16 Command did not exit successfully aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL exit status 1
      [Container] 2023/04/23 08:31:16 Phase complete: INSTALL State: FAILED
      [Container] 2023/04/23 08:31:16 Phase context status code: COMMAND_EXECUTION_ERROR Message: Error while executing command: aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL. Reason: exit status 1


Error summary:
The error clearly indicates that our codebuild doesn’t have sufficient permission to connect with ecr cluster backend-flask.

Easy solutions:

1. Go to the AWS Management Console and navigate to the IAM service.
2. Click on "Roles" from the left-hand menu and search for the IAM role associated with the CodeBuild project, in my case the name is codebuild-cruddur-backend-flask-bake-image-service-role1.
3. Click on the IAM role to view its details.
4. Click on the "Attach policies" button.
5. Search for the policy AmazonEC2ContainerRegistryPowerUser and select it.
6. Click on the "Attach policy" button to attach the policy to the IAM role.

<img width="1432" alt="Week9-PermissionsResolved" src="https://user-images.githubusercontent.com/125006062/233832192-db7963e6-9935-44df-b33d-bc87afbb0dec.png">

or

add the following json code to the permissions of the backend-flask cluster:

        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "codebuild"
                    "Effect": "Allow",
                    "Action": [
                        "ecr:GetAuthorizationToken",
                        "ecr:BatchCheckLayerAvailability",
                        "ecr:GetDownloadUrlForLayer",
                        "ecr:GetRepositoryPolicy",
                        "ecr:DescribeRepositories",
                        "ecr:ListImages",
                        "ecr:DescribeImages",
                        "ecr:BatchGetImage",
                        "ecr:GetLifecyclePolicy",
                        "ecr:GetLifecyclePolicyPreview",
                        "ecr:ListTagsForResource",
                        "ecr:DescribeImageScanFindings",
                        "ecr:InitiateLayerUpload",
                        "ecr:UploadLayerPart",
                        "ecr:CompleteLayerUpload",
                        "ecr:PutImage"
                    ],
                    "Resource": "*"
                }
            ]
        }

3. Did not find the image definition file imagedefinitions.json in the input artifacts ZIP file. Verify the file is stored in your pipeline's Amazon S3 artifact bucket: codepipeline-us-east-1-616047380902 key: cruddur-backend-farg/SourceArti/1R4bSSJ

soln : In the build setup under output artifacts put `ImageDefinition`, then go to the deploy section and change the Input artifacts from SourceArtifact to ImageDefinition
## Homework challenge

### Add a test stage in CodePipeline

After the Source stage, choose Add stage.

For Stage name, enter the name of the test stage (for example, Test). If you choose a different name, use it throughout this procedure.

 <img width="1073" alt="Week9-AddTest" src="https://user-images.githubusercontent.com/125006062/235369034-c21ab4a1-b806-4c34-8171-ddaf26f64ec9.png">
 
In the selected stage, choose Add action.
 
In Edit action, for Action name, enter a name for the action (for example, Test). 
 
For Action provider, under Test, choose CodeBuild.

For Input artifacts, select the source value to test.
 
Choose the name of the build project and click "done".

<img width="1222" alt="Week9-TestStage" src="https://user-images.githubusercontent.com/125006062/235370259-e22bf471-ad9c-46f3-92bd-48bb5d799e21.png">


Choose Save.
 
Choose Release change.

<img test


After the pipeline runs successfully, you can get the test results. In the Test stage of the pipeline, choose the CodeBuild hyperlink to open the related build project page in the CodeBuild console.

On the build project page, in Build history, choose the Build run hyperlink.

On the build run page, in Build logs, choose the View entire log hyperlink to open the build log in the Amazon CloudWatch console.
Scroll through the build log to view the test results.



