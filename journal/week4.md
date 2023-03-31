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
Quit from the postgres \q

Now Run the schema.sql file
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
```


- Create a Directory called `bin` and create 4 more dir inside it named `db-create`, `db-drop`, `db-schema-load`, `db-connect`.

Add these bashscripts to `db-create` this is used to create databases

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```

Add this bash script to `db-drop` this is used to delete databases

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```

Add this bashscripts to `db-schema-load`

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

psql $URL cruddur < $schema_path

```

Add this bashscripts to `db-connect`

```sh
#this script is to connect to the db server
#! /usr/bin/bash
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```

Now in other to execute any of these files you need to give the files executable permission. Run these commands;

```sh
# this sets for only user
chmod u+x bin/db-create 

# this sets for all 3 different levels permission 
chmod +x bin/db-drop

chmod +x bin/db-schema-load

chmod +x bin/db-connect

# you could also use chmod 644 bin/db-create

# to see the permissions
ls -la
```
Now to execute the files run `./<folder>/<file>` or `source <folder>/<file>`
```sh
 ./bin/db-drop or source bin/db-drop`
```
./db-coonect to connect to the db 









