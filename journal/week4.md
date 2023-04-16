# Week 4 — Postgres and RDS

## Technical Tasks 

### Provision RDS Instance

First provision your RDS instance , cd into frontend and run this command

```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password password1 \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

> This will take about 10-15 mins, We can temporarily stop our RDS instance for 7 days when we aren't using it. Turn off the instance temporarily until ready to use

- dockercompose up

To connect to psql via the psql client cli tool remember to use the host flag to specific localhost.

```sh
psql -Upostgres --host localhost
```
> It will prompt for password, it is password



### Create (and dropping) our database

(We can use the createdb command to create our database:

https://www.postgresql.org/docs/current/app-createdb.html

```sh
#this is like a one line command for creating it and an alise of CREATE database cruddur;
createdb cruddur -h localhost -U postgres
```

```s
#an alias of CREATE database cruddur;
psql -U postgres -h localhost

# list databases 
\l
```

Then create the database within the PSQL client

```sql
-- i used this
CREATE database cruddur;

-- list databases created 
\l

-- used to delete a database
DROP database cruddur;
```
> We need to create tables, usually when you a web framework like  RubyonRails you have a file called schema.sql or RBthat defines your schema, flask doesnt have it so we need to create it manually, the schema contains all stuff to setup the structure of your database and after that is done we are going to Seed our data with some test data.
### Add UUID Extension to the schema.sql file

We are going to have Postgres generate out UUIDs.
We'll need to use an extension called:

```sql
CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
Quit from the postgres `\q`

>Now Run the schema.sql file
*make sure you cd into  the`backend-flask’  dir*

The command to import:
```sql
psql cruddur < db/schema.sql -h localhost -U postgres

-- <!-- you will get a password prompt -->
```
*add a screenshot *

Make the password sign in process automatic

> Use connection url string: this is a way of providing all the details that it needs to authenticate to your server

Run this command on the terminal 

```sql
-- run this command, if it connects automatically that means it works
psql postgresql://postgres:password@localhost:5432/cruddur

-- set it as an env variable with this
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

-- set for gitpod workspace
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

-- set for your aws postgres db created for production(you will find the endpoint in aws console, RDS/Databases/cruddur-db-instance)
export PROD_CONNECTION_URL="postgresql://cruddurroot:password1@cruddur-db-instance.cyckofd4eywp.us-east-1.rds.amazonaws.com:5432/cruddur"

-- set for gitpod workspace 
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:password1@cruddur-db-instance.cyckofd4eywp.us-east-1.rds.amazonaws.com:5432/cruddur"
```
Then you can run the command directly to connect to your postgres
 
`psql $CONNECTION_URL` to connect directly to the db server


### Import Script

Create a folder `db` in `backend-flask`
We'll create a new SQL file called `schema.sql`
and we'll place it in `backend-flask/db` and paste this in the file created

```sql
-- Schema is used to define the structure of your db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;


CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

-- psql cruddur < db/schema.sql -h localhost -U postgres
```
### 2ndImport Script
Create a folder `db` in `backend-flask`
We'll create a new SQL file called `seed.sql`
and we'll place it in `backend-flask/db` and paste this in the file created
```sql
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```



- Create a Directory called `bin` and create 5 more dir inside it named `db-create`, `db-drop`, `db-schema-load`, `db-connect`,`db-setup`,`db-seed` ,`db-sessions`.


- Add this bashscripts to `db-connect`

```sh
#this script is to connect to the db server
#! /usr/bin/bash
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

# psql $URL
```

- Add these bashscripts to `db-create` this is used to create databases

```sh
#! /usr/bin/bash
# to create the database
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```

- Add this bash script to `db-drop` this is used to delete databases

```sh
#! /usr/bin/bash
# to delete the database created
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```

- Add this bashscripts  `db-schema-load` to run `schema.sql`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

# psql $URL cruddur < $schema_path

```

- Add this bashscripts to `db-seed`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```


- Add this bashscripts to `db-setup`

```sh
#! /usr/bin/bash
# stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```

- Add this bashscripts to `db-session`


Now in other to execute any of these files you need to give the files executable permission. Run these commands;

```sh
# this sets for only user
chmod u+x bin/db-create 

# this sets for all 3 different levels permission 
chmod +x db/schema.sql

chmod +x db/seed.sql

chmod +x bin/db-connect

chmod +x bin/db-drop

chmod +x bin/db-schema-load

chmod +x bin/db-seed

chmod u+x bin/db-setup

chmod +x bin/db-sessions

# you could also use chmod 644 bin/db-create

# to see the permissions
ls -la
```
Now to execute the files run `./<folder>/<file>` or `source <folder>/<file>`

```sh
 ./bin/db-setup or source bin/db-setup

#  to connect to Prodution database put prod at the end
../bin/db-setup prod
```


### Install Postgres Engine for python
We need to install Postgres Engine so that we can run the database setup just created

- We'll add the following to our requirments.txt

```sh
psycopg[binary]
psycopg[pool]

# cd into backend and run this
pip install -r requirements.txt
```

- In the `backend-flask` create a file under `lib` and name it `db.py` paste this in it
```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

- Create a connection by adding this to `dockercompose` file

```yml
     CONNECTION_URL: "${PROD_CONNECTION_URL}"
      #CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"
```

- Go to `home_activities.py`

```py
# add this to line 4 under from opentelemetry import trace
from lib.db import pool, query_wrap_array
```
```py
class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
        sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-1----")
    print(json[0])
    return json[0]
    return results
```
#####################
### Connect to RDS via Gitpod
In order to connect to the RDS instance we need to provide our Gitpod IP and whitelist for inbound traffic on port 5432.


Run this command in the terminal
```sh
GITPOD_IP=$(curl ifconfig.me)
#copy the ip and use it in your security group in aws 
echo $GITPOD_IP
```

We'll create an inbound rule for Postgres (5432) and provide the GITPOD ID.

We'll get the security group rule id so we can easily modify it in the future from the terminal here in Gitpod.

> run this in your terminal and add it to codespaces settings
```sh
export DB_SG_ID="sg-0107b3fc7d7977da0"
gp env DB_SG_ID="sg-0107b3fc7d7977da0"
export DB_SG_RULE_ID="sgr-092c6e84ccf5ee75f"
gp env DB_SG_RULE_ID="sgr-092c6e84ccf5ee75f"
export GITPOD_IP=$(curl ifconfig.me)
```
Whenever we need to update our security groups we can do this for access. This will set your SG dynamically

execute this command in the terminal
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
To ensure that this loads whenever your workspace opens, create a file in `bin` and name it `rds-update-sg-rule` add the command to it.

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
Then run this to grant executable permission to the file
`chmod u+x bin/rds-update-sg-rule`

Now run `./bin/rds-update-sg-rule`

- Add this to gitpod.yml
```yml
#At line 17 to 19 under sudo apt install -y postgresql-client-13 libpq-dev
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```




### For Post confirmation Lamda

- Create a folder in aws and call it lamdas, now create a file names `cruddur-post-confirmation.py` then add this code.
Go to the aws console, create a lambda function
- click on Author from scratch
- funtion name = cruddur-post-confirmation
- Runtime = Python3.8
- x86.64, then create 
- click on code then paste this command in the `lambda_function `under the Test and then Deploy
```py
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      print('entered-try')
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(
          '{user_display_name}', 
          '{user_email}', 
          '{user_handle}', 
          '{user_cognito_id}'
        )
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```

Go to `configuration` in Environmental variables, Click on add key 
*go to your work env. paste this, `env | grep PROD`, copy the result and in value section in your aws console and create
*Key = CONNECTION_URL
*Value = postgresql://cruddurroot:password1@cruddur-db-instance.cyckofd4eywp.us-east-1.rds.amazonaws.com:5432/cruddur

Here is a link to [ARN](https://github.com/jetbridge/psycopg2-lambda-layer), pick one in your region , navigate to `code` then layers, add layers, click on specify an ARN and paste the ARN in the option it provides, verify and add."lambda:GetLayerVersion" action on the specified resource.

There is a copy ARN and the consle, copy it, `arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py38:2
`, you will get an error

To resolve this issue, you can grant the necessary permissions to the IAM user by following these steps:

> Log in to the AWS Management Console with an account that has the necessary permissions to modify IAM policies.
Navigate to the IAM console and select the user "admin" from the list of users.

- Click on the "Permissions" tab and scroll down to the "Inline Policies" section.

- Click on the "Create Policy" button and select "Create Your Own Policy".

- Give your policy a name and enter the following JSON policy document:

json
Copy code
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "lambda:GetLayerVersion",
            "Resource": "arn:aws:lambda:us-east-1:898466741470:layer:psycop2-py38:2"
        }
    ]
}
- Click "Create Policy" to create the policy.
Once the policy has been created, the "admin" IAM user should now have the necessary permissions to perform "lambda:GetLayerVersion" action on the specified resource.

- Go to cognito, Amazon Cognito>User pools>crudder-user-pool>Add Lambda trigger
*sign up>Post confirmation trigger> cruddur-post-confirmation.*

- Delete previous user you created in coginto so you can  create another one.

- Go back to your frontend and signup
*you will get this error `PostConfirmation failed with error 2023-04-14T13:43:49.576Z a95e8e3a-946a-4495-a5b3-93430c320f48 Task timed out after 3.01 seconds.`*

- Go to IAM in the console and create a policy and name it `AWSLambdaVPCAccessExecustionRole` and then attach it to your lambda function `cruddur-post-confirmation-role`

Add this policy 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
```

Change this in schema.sql file

```sql
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

Make this changes to docker-compose.yml file
``` yml    
 CONNECTION_URL: "${PROD_CONNECTION_URL}"
#CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"

```
> **Run `./bin/db-setup` to setup the schema structure on postgres**



### Refactor the db library

change the db.py file to this

```py
from psycopg_pool import ConnectionPool
import os

class Db:
  def __init__(self):
    self.init_pool()

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  def query_commit(self):
    try:
      conn = self.pool.connection()
      cur =  conn.cursor()
      cur.execute(sql)
      conn.commit() 
    except Exception as err:
      self.print_sql_err(err)
      #conn.rollback()
  # when we want to return a json object
  def query_array_json(self,sql):
    print("SQL STATEMENT-[array]------")
    print(sql + "\n")
    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql):
    print("SQL STATEMENT-[object]-----")
    print(sql + "\n")
    wrapped_sql = self.query_wrap_object(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql)
        json = cur.fetchone()
        return json[0]

  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # psycopg2 extensions.Diagnostics object attribute
    print ("\nextensions.Diagnostics:", err.diag)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()
```

In services create_activity.py

```py
#line for replace the inital from lib.db import pool, query_wrap_array
from lib.db import db



#at line 36 put self.create_activity() under else
    else:
      self.create_activity()
      model['data'] = {
        'uuid': uuid.uuid4(),
        'display_name': 'Andrew Brown',



#past this in line 52-69
        'created_at': now.isoformat(),
        'expires_at': (now + ttl_offset).isoformat()
      }
    return model
  def create_activity(user_uuid, message, expires_at):
    sql = f"""
    INSERT INTO (
      user_uuid,
      message,
      expires_at
    )
    VALUES (
      "{user_uuid}",
      "{message}",
      "{expires_at}"
    )
    """
    #query_commit(sql)
```

In home home_activity.py

```py
#line 4 replace the inital from lib.db import pool, query_wrap_array
from lib.db import db

#replace this at line 12-18
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
    results = db.query_array_json("""
      SELECT
        activities.uuid,
        users.display_name,


#Replace this 28-31
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    return results

```

### Implement create activity


In backend post-confirrmation.py `aws/lambdas/cruddur-post-confirrmation.py`

```py
#replace this at line 20-23
   handle, 
  cognito_user_id
  ) 
VALUES(%s,%s,%s,%s)

#replace this at line 29-35
      params = [
        user_display_name,
        user_email,
        user_handle,
        user_cognito_id
      ]
      cur.execute(sql,*params)
```

Create a new folder in activities named create.sql `backend-flask/db/sql/activities/create.sql`

Paste this

```
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;wq 
```

Create two new folders in db namely sql and activities in sql and create a file named home.sql `backend-flask/db/sql/activities/home.sql`

```
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```

Create a new folder in activities named object.sql `backend-flask/db/sql/activities/object.sql`

```
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s
```

Create a new folder in lib named db.py `backend-flask/lib/db.py`

```py
from psycopg_pool import ConnectionPool
import os
import re
import sys
from flask import current_app as app

class Db:
  def __init__(self):
    self.init_pool()

  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)
  def query_commit(self,sql,params={}):
    self.print_sql('commit with returning',sql)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)

    try:
      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id
    except Exception as err:
      self.print_sql_err(err)
  # when we want to return a json object
  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={}):

    self.print_sql('json',sql)
    self.print_params(params)
    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
        else:
          return json[0]
  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()
```

Edit create_activity `backend-flask/services/create_activity.py`

```py
from datetime import datetime, timedelta, timezone

from lib.db import db

class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      expires_at = (now + ttl_offset)
      uuid = CreateActivity.create_activity(user_handle,message,expires_at)

      object_json = CreateActivity.query_object_activity(uuid)
      model['data'] = object_json
    return model

  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })

```
Edit home_activities.py `backend-flask/services/home_activities.py`

```py
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import db

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results
```

- Edit `backend-flask/app.py` , scroll down to `CreateActivity` and change the user_handle from 'andrewbrown' to your username 'rietta'

```py
@app.route("/api/activities", methods=['POST','OPTIONS'])
@cross_origin()
def data_activities():
  user_handle  = 'rietta'
  message = request.json['message']
  ttl = request.json['ttl']
  model = CreateActivity.run(message, user_handle, ttl)
  if model['errors'] is not None:
    return model['errors'], 422
  else:
    return model['data'], 200
  return

```

## ERRORS FACED
1. I kept getting this error with creating a user: PostConfirmation failed with error 2023-04-14T13:24:11.567Z a3767796-0875-4969-a1ee-2c9ca791ba94 Task timed out after 3.01 seconds.
Turned out it is as a result of my security group not been to set to allow postgres 0.0.0.0

2. Getting this error in the backend logs when trying to post activity create activity failure NotNullViolation .
fixed it by 
: Editing the `backend-flask/app.py` , scroll down to `CreateActivity` and change the user_handle from 'andrewbrown' to your username 'rietta'

3. Remember to install postgres sudo apt install postgres, if the psql command isnt working