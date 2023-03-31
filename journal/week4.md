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
psql postgresql://postgres:password@localhost:5432/crudder

-- set it as an env variable with this
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/crudder"

-- set for gitpod workspace
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/crudder"

-- set for your aws postgres db created for production(you will find the endpoint in aws console, RDS/Databases/cruddur-db-instance)
export CONNECTION_URL="postgresql://crudderroot:password1@cruddur-db-instance.cyckofd4eywp.us-east-1.rds.amazonaws.com:5432/crudder"

-- set for gitpod workspace 
gp env CONNECTION_URL="postgresql://crudderroot:password1@cruddur-db-instance.cyckofd4eywp.us-east-1.rds.amazonaws.com:5432/crudder"
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


- Create a Directory called `bin` and create 5 more dir inside it named `db-create`, `db-drop`, `db-schema-load`, `db-connect`,`db-setup`.

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

- Add this bashscripts to `db-schema-load`

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

Now in other to execute any of these files you need to give the files executable permission. Run these commands;

```sh
# this sets for only user
chmod u+x bin/db-create 

# this sets for all 3 different levels permission 
chmod +x bin/db-drop

chmod +x bin/db-schema-load

chmod +x bin/db-connect

chmod u+x bin/db-setup

# you could also use chmod 644 bin/db-create

# to see the permissions
ls -la
```
Now to execute the files run `./<folder>/<file>` or `source <folder>/<file>`

```sh
 ./bin/db-drop or source bin/db-drop
```

### Install Postgres Engine for python

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

- Create a connection by adding this to `dockercompose` file

```yml
     CONNECTION_URL: "${PROD_CONNECTION_URL}"
      #CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"
```

- Go to `home_activities.py`

```py
# add this to line 4 under from opentelemetry import trace
from lib.db import db
```
