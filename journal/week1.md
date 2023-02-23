# Week 1 — App Containerization


## Containerize the Backend


*note: run your `dockerfile` builds from your project dir ` 
aws-bootcamp-cruddur-2023`*

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

Remove this environment above because it was just a test
*ctrl c to stop your command running*
*to clear out env var `export BACKEND_URL` and `unset FRONTEND_URL`, you can confirm by using `env | grep _URL`*
<br></br>

![1](https://user-images.githubusercontent.com/101978292/220800038-45a8e9fe-3586-4c91-aac6-97c17c1fede8.jpg)



### Add Dockerfile for backend

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

![2](https://user-images.githubusercontent.com/101978292/220800107-ae673054-c704-4130-86d9-0f2eb6677bdc.jpg)


- Now go out from **backend-flask** dir and go into the project dir **aws-bootcamp-cruddur-2023**

#### Build the backend-flask Image

 - First create a custom image 

```sh
#create an image named backend-flask, check in the folder /backend-flask
docker build -t  backend-flaskimage ./backend-flask


#to view the image create
docker images

```

![3](https://user-images.githubusercontent.com/101978292/220800212-938df056-f90a-4812-82c6-3708869d6f5d.jpg)


### Create the backend-flask Container 

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
<br></br>

I named the the container backendflaskCon

- You can run it in background, *recommended* -d means run it in the background - p means print 
 

- The put in the remove *rm* when the container is stopped


```sh

docker container run --rm -p 4567:4567 -d backend-flaskimage

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

```sh

FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]

```

### Build Image for the Frontend image

Go back a directory 

```sh

docker build -t frontend-reactimage ./frontend-react-js
```

### Build and Run the frontend Container

```sh

docker run -p 3000:3000 -d frontend-reactimage
```

![4](https://user-images.githubusercontent.com/101978292/220800505-cb884f37-464e-48f5-ae91-b9fec92feefa.jpg)

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

![6](https://user-images.githubusercontent.com/101978292/220800578-c2b9a7dc-fb74-44f1-ab4e-00b086f310e9.jpg)

