# Week 5 — DynamoDB and Serverless Caching

## Technical Tasks 

### Provision RDS Instance

### Install BOTO3 
We need to install Postgres Engine so that we can run the database setup just created

- We'll add the following to our requirments.txt

```sh
boto3
```
run `pip install -r requirements.txt` backend-flask terminal

Create a folder under bin name it db and move all the db files into it, rename them by removing all the db in front of them, what you will have now will be connect,create,e.t.c.
Do the same with rds

Make a new folder named ddb in `bin`, this is going to contain all of our Dynamodb stuff. Create files named `schema-load`, `seed`, `drop`e.t.c

>We dont create databases, we create tables in dynamodb

- create a file named `schema-load` to create tables in dynamodb  `backend-flask/bin/ddb/schema-load` and add this
*`./bin/ddb/schema-load` to run this file*
```sh

#!/usr/bin/env python3

import boto3
import sys

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

ddb = boto3.client('dynamodb',**attrs)

table_name = 'cruddur-messages'


response = ddb.create_table(
  TableName=table_name,
  AttributeDefinitions=[
    {
      'AttributeName': 'pk',
      'AttributeType': 'S'
    },
    {
      'AttributeName': 'sk',
      'AttributeType': 'S'
    },
  ],
  KeySchema=[
    {
      'AttributeName': 'pk',
      'KeyType': 'HASH'
    },
    {
      'AttributeName': 'sk',
      'KeyType': 'RANGE'
    },
  ],
  #GlobalSecondaryIndexes=[
  #],
  BillingMode='PROVISIONED',
  ProvisionedThroughput={
      'ReadCapacityUnits': 5,
      'WriteCapacityUnits': 5
  }
)

print(response)
```

Create a file in ddb named `list-tables` to list the tables created with schema-load  `backend-flask/bin/ddb/list-tables`
*`./bin/ddb/list-tables` to run this file*

```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
 fi

aws dynamodb list-tables $ENDPOINT_URL \
--query TableNames \
--output table
```

Create a file in ddb named `drop` to delete tables created  `backend-flask/bin/ddb/drop` 
*`./bin/ddb/drop` to run this file*

```sh
#! /usr/bin/bash

set -e # stop if it fails at any point

if [ -z "$1" ]; then
  echo "No TABLE_NAME argument supplied eg ./bin/ddb/drop cruddur-messages prod "
  exit 1
fi
TABLE_NAME=$1

if [ "$2" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

echo "deleting table: $TABLE_NAME"

aws dynamodb delete-table $ENDPOINT_URL \
  --table-name $TABLE_NAME
```
*run this command `./bin/ddb/drop <table name>`*

- Create a file named `seed` and paste the conversation and instructions created into it, this is a way of working through this tables to seeing what you get `backend-flask/db/seed.sql`

- Make sure your rds local is running correctly, you can run `/.bin/db/setup` since this runs,connect,create,drop and seed,

- now run your dynamodb seed `./bin/ddb/seed`

Create a file in ddb named `scan` to see the content of the  cruddur-messeges table `backend-flask/bin/ddb/scan` 
*`./bin/ddb/scan` to run this file*

```sh
#!/usr/bin/env python3

import boto3

attrs = {
  'endpoint_url': 'http://localhost:8000'
}
ddb = boto3.resource('dynamodb',**attrs)
table_name = 'cruddur-messages'

table = ddb.Table(table_name)
response = table.scan()

items = response['Items']
for item in items:
  print(item)
```
- Create a folder in `ddb` named `patterns`

- Create a file in `patterns` named `get-conversations` which is the get the conversation `backend-flask/bin/ddb/patterns/get-conversations` to run this file*
*`./bin/ddb/patterns/get-conversations` to run this file*


```sh
#!/usr/bin/env python3

import boto3
import sys
import json
import datetime

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"

# define the query parameters
query_params = {
  'TableName': table_name,
  'ScanIndexForward': False,
  'Limit': 20,
  'ReturnConsumedCapacity': 'TOTAL',
  'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
  #'KeyConditionExpression': 'pk = :pk AND sk BETWEEN :start_date AND :end_date',
  'ExpressionAttributeValues': {
    ':year': {'S': '2023'},
    #":start_date": { "S": "2023-03-01T00:00:00.000000+00:00" },
    #":end_date": { "S": "2023-03-19T23:59:59.999999+00:00" },
    ':pk': {'S': f"MSG#{message_group_uuid}"}
  }
}


# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))

# print the consumed capacity
print(json.dumps(response['ConsumedCapacity'], sort_keys=True, indent=2))

items = response['Items']
reversed_array = items[::-1]

for item in reversed_array:
  sender_handle = item['user_handle']['S']
  message       = item['message']['S']
  timestamp     = item['sk']['S']
  dt_object = datetime.datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
  formatted_datetime = dt_object.strftime('%Y-%m-%d %I:%M %p')
  print(f'{sender_handle: <12}{formatted_datetime: <22}{message[:40]}...')
  ```


- Create a file in `patterns` named `list-conversations` which is the access pattern `backend-flask/bin/ddb/patterns/list-conversations` to run this file*
*`./bin/ddb/patterns/list-conversations` to run this file*


```sh
#!/usr/bin/env python3

import boto3
import sys
import json
import os

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..', '..'))
sys.path.append(parent_path)
from lib.db import db

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

def get_my_user_uuid():
  sql = """
    SELECT 
      users.uuid
    FROM users
    WHERE
      users.handle =%(handle)s
  """
  uuid = db.query_value(sql,{
    'handle':  'andrewbrown'
  })
  return uuid

my_user_uuid = get_my_user_uuid()
print(f"my-uuid: {my_user_uuid}")

# define the query parameters
query_params = {
  'TableName': table_name,
  'KeyConditionExpression': 'pk = :pk',
  'ExpressionAttributeValues': {
    ':pk': {'S': f"GRP#{my_user_uuid}"}
  },
  'ReturnConsumedCapacity': 'TOTAL'
}

# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))
```

- Edit a file in `patterns` named `list-conversations` which is the access pattern `backend-flask/bin/ddb/patterns/list-conversations` to run this file*
*`./bin/ddb/patterns/list-conversations` to run this file*

- Create a file in `lib` and name it `ddb.py`

run `aws cognito-idp list-users --user-pool-id=us-east-1_YMdvcghdH`

- backend/bin/cognito/list-users

```
export AWS_COGNITO_USER_POOL_ID=us-east-1_YMdvcghdH
gp env AWS_COGNITO_USER_POOL_ID=us-east-1_YMdvcghdH
``

- backend-flask/bin/db/update_cognito_user_ids
run `chmod u+x bin/db/update_cognito_user_ids`

- update backend-flask/bin/db/setup
run `./bin/db/setup`
```
source "$bin_path/update_cognito_user_ids"
```
#line 44
    self.print_sql('commit with returning',sql,params)
./bin/db/update_cognito_user_ids

- make edits to app.py

- backend-flask/services/message_groups.py

- backend-flask/db/sql/users/uuid_from_cognito_user_id.sql
```
SELECT
  users.uuid
FROM public.users
WHERE 
  users.cognito_user_id = %(cognito_user_id)s
LIMIT 1
```