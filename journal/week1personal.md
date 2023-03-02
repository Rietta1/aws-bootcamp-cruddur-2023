[ USEFUL INFORMATION]
# Week 1 — App Containerization


## Containerize the Backend

#### Setup the environmental varables

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

Delete this environment above because it was just a test
*ctrl c to stop your command running*
*to clear out env var `export BACKEND_URL` and `unset FRONTEND_URL`, you can confirm by using `env | grep _URL`*




### Add Dockerfile for backend



Open your github repo, open the gitpod 
Create a `Dockerfile` on backend-flask directory,*Create a file here: `backend-flask/Dockerfile`* and put in these commands:

```sh
FROM python:3.10-slim-buster

# Inside Container
# this will create a new folder inside container

WORKDIR /backend-flask

# copying from outside container to Inside container
# this contains the libraries you went to install to run the app

COPY requirements.txt requirements.txt

# Inside container
# this will install the python libraries used for the app

RUN pip3 install -r requirements.txt

# Outside container -> inside container
# . means everything in the current directory
# The 1st fullstop means " . " means everything in /backend-flask (outside the container)
# the 2st fullstop means " . " means everything in /backend-flask (inside the container)

COPY . .

# env variables are ways for us to configure our application
# Set environmental variables (Env Vars)
# Inside the container and will remain set when the container is running

ENV FLASK_ENV=development

EXPOSE ${PORT}

# CMD (Command)
# This code is for running flask; when you are running containers it has to be ran on 0.0.0.0 and not local host 127.0.0.0
# python3 -m flask run --host=0.0.0.0 --port=4587

CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]

```

- Now go out from **backend-flask** dir and go into the project dir **aws-bootcamp-cruddur-2023**

#### Build the backend-flask Image

 First create a custom image 

```sh
#create an image named backend-flask, check in the folder /backend-flask
docker build -t  backend-flaskimage ./backend-flask

OR

docker build -t  backend-flask ./backend-flask


#to view the image create
docker images

```

### Create the backend-flask Container 

There are several ways of running a container
Preferred the first command:

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
I named the the container backendflaskCon

- You can run it in background, *recommended* -d means run it in the background - p means print 


- The in the remove *rm* when the container is stopped


```sh

docker container run --rm -p 4567:4567 -d backend-flaskimage

```

Return the container id into an Env Var

```sh

CONTAINER_ID=$(docker run --rm -p 4567:4567 -d backend-flask)

```
<br></br>

## Containerize Frontend

## Run NPM Install

We have to run NPM Install before building the container since it needs to copy the contents of node_modules

```
cd frontend-react-js
npm i
```


### Create DockerFile for Frontend

Create a file here: `frontend-reactimage/Dockerfile`

```dockerfile
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
```

### Build Image for the Frontend image

```sh

docker build -t frontend-reactimage ./frontend-react-js

```

### Build and Run the frontend Container

```sh

docker run -p 3000:3000 -d frontend-reactimage
```

******



### Get Container Images or Running Container Ids

```
docker ps
docker images
```


### Send Curl to Test Server

```sh
curl -X GET http://localhost:4567/api/activities/home -H "Accept: application/json" -H "Content-Type: application/json"
```

### Check Container Logs

```sh
docker logs CONTAINER_ID -f
docker logs backend-flask -f
docker logs $CONTAINER_ID -f
```

###  Debugging  adjacent containers with other containers

```sh
docker run --rm -it curlimages/curl "-X GET http://localhost:4567/api/activities/home -H \"Accept: application/json\" -H \"Content-Type: application/json\""
```

busybosy is often used for debugging since it install a bunch of thing

```sh
docker run --rm -it busybosy
```

### Gain Access to a Container

```sh
docker exec CONTAINER_ID -it /bin/bash
```

> You can just right click a container and see logs in VSCode with Docker extension

### Delete an Image

```sh
docker image rm backend-flask --force
```

> docker rmi backend-flask is the legacy syntax, you might see this is old docker tutorials and articles.

> There are some cases where you need to use the --force

### Overriding Ports

```sh
FLASK_ENV=production PORT=8080 docker run -p 4567:4567 -it backend-flask
```

> Look at Dockerfile to see how ${PORT} is interpolated
]
