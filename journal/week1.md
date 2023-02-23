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
python3 -m flask run --host=0.0.0.0 --port=4567
cd ..

```

- make sure to unlock the port on the port tab
- open the link for 4567 in your browser
- append to the url to `/api/activities/home`
- you should get back json
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

docker build -t  backend-flask ./backend-flask

#to view the image create
docker images

```

### Run backend-flask Container 

There are several ways of running a container
Preferd the first command:

Run any of these:

```sh

# this is setting the environmental variable -e is the evn var
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask

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

- What the first command has done is to create a container and name it *backendflaskCon* 

- While the second command put in the remove *rm* when the container is stopped

```sh
docker run -d --name backendflaskCon - p 4567:4567 backend-flask

OR

docker container run --rm -p 4567:4567 -d backend-flask

```

Return the container id into an Env Var

```sh

CONTAINER_ID=$(docker run --rm -p 4567:4567 -d backend-flask)

```
## Containerize Frontend

## Run NPM Install

We have to run NPM Install before building the container since it needs to copy the contents of node_modules

```
cd frontend-react-js
npm i
```


### Create DockerFile for Frontend

Create a file here: `frontend-react-js/Dockerfile`

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

docker build -t frontend-react ./frontend-react-js

```

### Build and Run the frontend Container

```sh

docker run -d --name frontendflaskCon - p 3000:3000 frontend-react

OR

docker run -p 3000:3000 -d frontend-react-js
```

******


## Multiple Containers (DockerCompose)

Then go back a directory to **aws-bootcamp-cruddur-2023** then create a docker-compose file

### Create a docker-compose file

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
Then Run the docker-compose file

```
docker compose up

OR

docker-compose up
```


