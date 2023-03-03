# Week 1 — App Containerization

## Technical Tasks

### STEP 1 - Containerize the Backend 


*note: run ALL your `dockerfile` builds from your project dir ` 
aws-bootcamp-cruddur-2023`*<br></br>

1. Setup the environmental varables

First we containerize the backend;**backend-flask**
we need to feedin or set the env var to the server by running:

cd into backend-flask and set the environment

**Run flask**

```sh

cd backend-flask
export FRONTEND_URL="*"
export BACKEND_URL="*"
pip3 install -r requirements.txt
python3 -m flask run --host=0.0.0.0 --port=4567
cd ..

```

- make sure to unlock the port on the port tab
- open the link for 4567 in your browser
- append to the url to `/api/activities/home`
- you should get back json

Remove this environment above because it was just a test
*ctrl c to stop your command running*
*to clear out env var `export BACKEND_URL` and `unset FRONTEND_URL`, you can confirm by using `env | grep _URL`*
<br></br>



![1](https://user-images.githubusercontent.com/101978292/222433945-741b06ea-9dc8-421f-bb70-f7ffd9a5808c.jpg)


2. Add Dockerfile for backend

Open your github repo, open the gitpod 
Create a `Dockerfile` on backend-flask directory,*Create a file here: `backend-flask/Dockerfile`* and put in these commands:

```sh

FROM python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .
ENV FLASK_ENV=development

EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]

```


![2](https://user-images.githubusercontent.com/101978292/222433975-a4f98288-c73f-4e41-9af7-87b1fca62d43.jpg)


- Now go out from **backend-flask** dir and go into the project dir **aws-bootcamp-cruddur-2023**

3. Build the backend-flask Image

 - First create a custom image 

```sh
#create an image named backend-flask, check in the folder /backend-flask
docker build -t  backend-flaskimage ./backend-flask


#to view the image create
docker images

```


![3](https://user-images.githubusercontent.com/101978292/222434005-eaba175b-3893-4768-8453-00f8981fbdea.jpg)


4. Create the backend-flask Container 

There are several ways of running a container
We use one:

Run any of these:

```sh

# this is setting the environmental variable -e is the evn var
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flaskimage

OR

docker run --rm -p 4567:4567 -it backend-flask
FRONTEND_URL="*" BACKEND_URL="*" docker run --rm -p 4567:4567 -it backend-flask
# this is setting the environmental variable 
export FRONTEND_URL="*"
export BACKEND_URL="*"


OR

docker run --rm -p 4567:4567 -it  -e FRONTEND_URL -e BACKEND_URL backend-flask
# to clear out env var
unset FRONTEND_URL="*"
unset BACKEND_URL="*"

# to check the containers created
docker ps

# check your list of containers
sudo docker container ls -la
```


5. You should always run it in background using the command below:
 *recommended* 
 [*-d means run it in the background - p means print The put in the remove *rm* when the container is stopped*]

```sh
docker container run --rm -p 4567:4567 -d backend-flaskimage
```


Return the container id into an Env Var

```sh
CONTAINER_ID=$(docker run --rm -p 4567:4567 -d backend-flask)
```


### STEP 2 - Containerize the Frontend

1. Run NPM Install

We have to run NPM Install before building the container since it needs to copy the contents of node_modules

```sh
cd frontend-react-js
npm i
```
*if you ever run into errors with npm use; `npm audit fix --force` and `npm audit fix`*

2. Create DockerFile for Frontend

Create a file here: `frontend-react-js/Dockerfile`

```sh

FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]

```

3. Build Image for the Frontend image

Go back a directory 

```sh
docker build -t frontend-reactimage ./frontend-react-js
```

4. Build and Run the frontend Container

```sh
docker run -p 3000:3000 -d frontend-reactimage

OR

docker container run --rm -p 3000:3000 -d frontend-reactimage
```




![4](https://user-images.githubusercontent.com/101978292/222434105-394b2e71-baf3-4fa0-addc-54c4f1e771be.jpg)

******


### STEP 3 - Multiple Containers (DockerCompose)

Then go back a directory to **aws-bootcamp-cruddur-2023** then create a docker-compose file

1. Create a docker-compose file

Create `docker-compose.yml` at the root of your project.

```yaml

version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js

# the name flag is a hack to change the default prepend folder
# name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur

```

- Then Run the docker-compose file

```
docker compose up

OR

docker-compose up
```

![6](https://user-images.githubusercontent.com/101978292/222434190-13f5ddbd-4ee5-41a8-a59f-1c285837b8fd.jpg)

![9](https://user-images.githubusercontent.com/101978292/222434621-110dd58a-96c1-4858-893d-bd02e3855621.jpg)


### STEP 4 - Create the notification feature (Backend and Front)

- Go to your gitpod and turn on your docker-compose, you will see that your frontend wont turn on, 

- Go to your gitpod and cd into **frontend-react-js** and install npm 
```
npm i 
npm audit fix --force 
npm audit fix
npm update -g
```
then go and turn on your docker compose `docker compose up`

- Open the frontend-react-js in the browser and sign in, you will see that the notification hasnt been made

- Turn of docker compose

- Go to the api on gitpod and open the api file for **openapi-3.0.yml** already created and add an api end for notifications `api/activities/notification`
*go to [openapi specification](https://spec.openapis.org/oas/v3.1.0) to understand how to get the appropiate parameters*


```
/api/activities/notification:
    get:
      description: 'Return a feed of activity for all of those that i follow'
      tags:
        - "activities"
      parameters: []
      responses:
        '200':
          description: 'Returns an array of activities'
          content:
            application/json:
              schema:
                type: "array"
                items:
                    $ref: '#/components/schemas/Activity'

```
![10](https://user-images.githubusercontent.com/101978292/222435440-e6cd2751-f193-4c09-895d-b79b85722f10.jpg)


 2. Implement a Backend endpoint

 
  - Go to **app.py** and then **services** and create a folder and name it **notificataions_activites.py**

 - The entry endpoint for the backend is **app.py** and add this:

 ```py
@app.route("/api/activities/notifications", methods=['GET'])
def data_notifications():
  data = NotificationsActivities.run()
  return data, 200
 ```
 
 ![11](https://user-images.githubusercontent.com/101978292/222435520-a87592a1-4753-4259-b98b-1d079b6a2d96.jpg)


- Go to the top arrangements of api structure and add this line for organization

```py
from services.notifications_activities import *
```
![12](https://user-images.githubusercontent.com/101978292/222435595-460103e8-47b8-4106-97ce-cab16648d817.jpg)


- Open the newly created folder named **notificataions_activites.py** and add this code

*copy homeactivities.py which is similar and make changes* Change anywhere with the home to notifications

![13](https://user-images.githubusercontent.com/101978292/222435700-b8e3efb9-2934-467a-a8b8-fa2a0633db8d.jpg)


- open the link for 4567 in your browser and append to the url to `/api/activities/notifications`

![14](https://user-images.githubusercontent.com/101978292/222435746-0d653cbd-4ca2-42f5-8684-aa9f6ce01b47.jpg)


 3. Implement a Frontend endpoint

 - The entry endpoint for the frontend is **App.js**

- Go to the top arrangements of api structure and add this line for organization

```js
import NotificationsFeedPage from './pages/NotificationsFeedPage';
```
and

```js
{
    path: "/notifications",
    element: <NotificationsFeedPage />
  },
```

![15](https://user-images.githubusercontent.com/101978292/222435906-15b2641a-b559-44e3-800d-37145c07f5c9.jpg)

![16](https://user-images.githubusercontent.com/101978292/222435963-be68b648-5e1e-41e5-9b3b-0670c34abc64.jpg)


- And the line of code for notifications and then go to **Pages** and create a folder and name it **NotificationsFeedPage.js**

*copy homepagefeed.js which is similar and make changes* Change anywhere with the home to notifications

![17](https://user-images.githubusercontent.com/101978292/222436082-2549adb3-986a-4aee-8dc9-3216ae60e686.jpg)


### STEP 4 - Run DynamoDB Local Container and ensure it works

add this too docker compose.yml file

```
 dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal

```

![18](https://user-images.githubusercontent.com/101978292/222436151-9aace384-f4ee-4428-9bfa-92ddd12520cc.jpg)
![20](https://user-images.githubusercontent.com/101978292/222436310-f38a94ca-899b-465d-ac1b-1dc78b19c984.jpg)

![19](https://user-images.githubusercontent.com/101978292/222436209-c3dac3ae-77d3-4d2d-b68f-b4ad50caefac.jpg)

![21](https://user-images.githubusercontent.com/101978292/222436359-94b4c5cb-67c5-49f6-b009-4d4b97e08e52.jpg)

added postgres
```
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data

```

```
volumes:
  db:
    driver: local
```

![22](https://user-images.githubusercontent.com/101978292/222436414-c288274e-7154-4800-bdd3-375ec6f3cce8.jpg)
![22](https://user-images.githubusercontent.com/101978292/222436602-de98310e-d405-4ce2-8f87-f5d04d3d0751.jpg)


##  Homework Challenge

1. I Launched an EC2 instance that has docker installed, and pulled a container to demonstrate you can run your own docker processes. 

2. I Launched an ubuntu EC2 instance, installed java.jdk

```
sudo yum install java-1.8.0-openjdk-devel -y

```

installed docker 

```
sudo apt update

sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

apt-cache policy docker-ce

sudo apt install docker-ce

sudo systemctl status docker

```
add docker to the wheel group

```
cat /etc/group

sudo usermod -aG docker ec2-user

groups ec2-user
```
then i installed docker-compose
```
sudo apt get docker compose
```
Then installed `npm install`
then i pulled the crudder repo into the ec2 instance and, installed `npm i` in the frontend folder and then ran the containers `docker-compose up` to demonstrate you can run my own docker processes. 
 
 to  remove sveral containers at once
```
docker container rm -f $(docker container ls -aq)

docker image rm -f $(docker image ls -aq)

```

*the issue i faced was that the  ports werent showing the apps, so i connected the instance to the vscode and i foundout that the cantainers werent actually running, after days of troubleshooting i realised that the ec2 instance type was to small so i increased it from a t2micro to a t2.medium, all the ports started running, however the contains like the writeup werent showing, i am still trying to figure it out*

![27](https://user-images.githubusercontent.com/101978292/222475524-88c11f5d-328b-4847-8c02-0a86e1b5336f.jpg)

![25](https://user-images.githubusercontent.com/101978292/222475434-7a2bccfd-8be7-4844-95b9-ef4294e850e2.jpg)
![26](https://user-images.githubusercontent.com/101978292/222475572-4dfacce2-4caa-4a5c-8c08-893a2da6a0c7.jpg)


*When i relunched the instance after stoping it i received a message when trying to run npm i in the frontend folder that my server was full. so i debugged it by deleting the npm. at the home page and deleting the ovarlay at docker which caused issues*
```
sudo cd /var/lib/docker/overlay2

```

3. I Pushed and tagged the frontend,backend and dynamodb images to DockerHub 
- [Frontend](https://hub.docker.com/r/rietta/backend-flask)
- [Backend](https://hub.docker.com/r/rietta/backend-flask)
- [Dynamodb](https://hub.docker.com/r/rietta/dynamodb-local)


4. I researched best practices of Dockerfiles and attempt to implement it in your Dockerfile

 - i used official docker images as base image
 - i used specific image versions
 - optimized caching image layers
 - used multi stage builds
 - i used the least privileged user
 - scanned images for vulnerabilities


5. I Implemented a healthcheck in the V3 Docker compose file using synk


![28](https://user-images.githubusercontent.com/101978292/222495626-b5125f10-bca9-46fb-9853-135f1ec29b9e.jpg)


6. i installed Docker on my localmachine and get the same containers running outside of Gitpod / Codespaces

7. i Ran the dockerfile CMD as an external script

8. I tried using a multi-stage building for a Dockerfile build in the frontend, i created a new folder titled multistageSample.
I havent fully understood the different ways it can be used










