# Week 3 — Decentralized Authentication

## Technical Tasks -

Decentralized authentication is an approach to user authentication that relies on decentralized systems, rather than a centralized authority, to authenticate user identities. In a decentralized authentication system, users are authenticated through the use of digital signatures and cryptographic keys, rather than through a central authentication server.

AWS Cognito is a fully managed identity service offered by Amazon Web Services (AWS). It provides user sign-up, sign-in, and access control capabilities to web and mobile applications.

### STEP 1 -  Provision via ClickOps a Amazon Cognito User Pool

- Go to aws and cognito, 
- dont click on federated identity providers,
- check email, 
- next click congnito defaults , 
- no mfa, enable self-service recovery, 
- click email only, enable self-registration,  
- allow congnito to automatically send messages to verify and confirm recommended , 

----
* check send email msg very email, 
- check keep original attribute value active when update is pending ,
- Click email address , Select( drop down)name and preferred_username ,
- click send email cognito,  
- next > userpool name =crudder-user-pool, click use a cognito domain, 
- App type, click public client, 
- App client name = crudder, click don't generate a client secret, 
- next> create user pool

Go to your github 
*you would find most of the instructions in aws amplify Javascript liberay*
Open it on your gitpod and cd into frontend 
 install aws amplify into frontend-react-js

```sh
cd frontend-react-js
npm i aws-amplify --save
```

You should see `“aws-amplify”: ”^5.0.16”` , in package.json

- Configure Amplify
We need to hook up our cognito pool to our code in the App.js


```js

//paste it on line 18 below } from “react-router-dom”;
import { Amplify } from 'aws-amplify';


Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});

```
Add this variables to your dockerfile

```yml
//add this to dockercompode under honeycomb
AWS_COGNITO_USER_POOL_ID: "us-east-1_9SSnqJfAp"
AWS_COGNITO_USER_POOL_CLIENT_ID: "54egusrg833i2no7gg5ooknnkk"

// `paste in docker-compose-file at line 28, this under REACT_APP_BACKEND_URL: codespaces` 

REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
//user pool id is in the aws console user pool u just created
REACT_APP_AWS_USER_POOLS_ID: "us-east-1_9SSnqJfAp"
//found in app integration 
REACT_APP_CLIENT_ID: "54egusrg833i2no7gg5ooknnkk"

```
*commit code* add  image 1 and 2



### Conditionally show components based on logged in or logged out status

*what this does is it determines what a user is shown if they are logged in and not*

Inside our `HomeFeedPage.js`

```js
//paste this at line 4 under import React from import React from "react";

import { Auth } from 'aws-amplify';

//already in the code
// set a state
const [user, setUser] = React.useState(null);

//replace line 40 to 49 with this new code
// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};


//we already have it at line 64
// check when the page loads if we are authenicated
React.useEffect(()=>{
  loadData();
  checkAuth();
}, [])
```

Go to components/DesktopNavigation.js

We'll want to pass user to the following components:



//clean up  line 19 to 28 on DesktopSidebar.js


We will update `ProfileInfo.js`

```js

//replace at line 6 import cookies from ‘js-cookie’, under // [TODO] Authentication 
import { Auth } from 'aws-amplify';

//replace line 15 to 25( cookies configuration with this:)
const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

Compose up to see of the app configuration is working


## Signin Page
Go to pages dir and Signin.js

```js
//replace line 7, import Cookies from ‘js-cookie’ under //[TODO] Authentication  to this:
import { Auth } from 'aws-amplify';

//Already replaced with another code
const [cognitoErrors, setCognitoErrors] = React.useState('');

//replace with line 15 to 26 event.preventDefault();
 const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    try {
      Auth.signIn(email, password)
        .then(user => {
          console.log('user' ,user)
          localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
          window.location.href = "/"
        })
        .catch(error => {
        if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
  });
    } catch (error) {
      }
    return false
  }

// let errors;
// if (cognitoErrors){
//   errors = <div className='errors'>{cognitoErrors}</div>;
// }

// //just before submit component
// {errors}
```

Go over to cognito user pool created(crudder-user-pool) and create a user
-name: loretta
- email address = "rietta"
- password= 
- create user
- confirm the user

To fix the error of forced password change

aws  `aws cognito-idp admin-set-user-password -–username loretta -–password Testing  -–user-pool-id us-east-1_9SSnqJfAp  -–permanent`

aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_9SSnqJfAp \
  --username loretta \
  --password Password70% \
  --permanent

To check env variables 
`aws sts get-caller-identity`

Go back to aws user pool and edit, add the name and preferred name to the name of your choice
then signout and sign in, you will see the changes

Now delete the user created in aws user pool =loretta so that we can create the signup page, 



### Signup Page

Go to frontend-react-js/pages dir 
```js
//replace line 7,import Cookies from ‘js-cookie’ under //[TODO] Authentication 
import { Auth } from 'aws-amplify';

//already have this
const [cognitoErrors, setCognitoErrors] = React.useState('');

//replace prev onsubmit to this, from line 18 to 29
const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
  } catch (error) {
      console.log(error);
      setErrors(error.message)
  }
  return false
}

```

## Confirmation Page
Go to confirmationpage.js
```js
//replace line 7, under //[TODO] Authentication
import { Auth } from 'aws-amplify';

//replace fron line 24 to line 27
  const resend_code = async (event) => {
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
    //replace fron line 43 to line 53
  }
   const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }

```
 Recreate the user-pool, and uncheck username, check email, this will remove the error gotten from the signup page




### Recovery Page

Go to RecoveryPage.js

```js
//paste this on line5 import { Link } from "react-router-dom";
import { Auth } from 'aws-amplify';

//replace fron line 16 to line 20
const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setErrors(err.message) );
  return false
}
//replace fron line 24 to line 28
const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setCognitoErrors(err.message) );
  } else {
    setErrors('Passwords do not match')
  }
  return false
}

## Authenticating Server Side

Add in the `HomeFeedPage.js` a header eto pass along the access token

```js
  headers: {
    Authorization: `Bearer ${localStorage.getItem("access_token")}`
  }
```

In the `app.py`

```py
cors = CORS(
  app, 
  resources={r"/api/*": {"origins": origins}},
  headers=['Content-Type', 'Authorization'], 
  expose_headers='Authorization',
  methods="OPTIONS,GET,HEAD,POST"
)
```