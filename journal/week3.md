# Week 3 — Decentralized Authentication

## Technical Tasks -


Decentralized authentication is an approach to user authentication that relies on decentralized systems, rather than a centralized authority, to authenticate user identities. In a decentralized authentication system, users are authenticated through the use of digital signatures and cryptographic keys, rather than through a central authentication server.

AWS Cognito is a fully managed identity service offered by Amazon Web Services (AWS). It provides user sign-up, sign-in, and access control capabilities to web and mobile applications.


### Video Review

* Watched: [Week 3 - Live Streamed Video – Decentralized Authentication](https://www.youtube.com/live/9obl7rVgzJw)
* Watched: [Week 3 - Cognito Custom Pages](https://youtu.be/T4X4yIzejTc)
* Watched: [Week 3 - Cognito – JWT Server Side Verify](https://youtu.be/d079jccoG-M)
* Watched: [Week 3 - Exploring JWTs](https://youtu.be/nJjbI4BbasU)
* Watched: [Week 3 - Improving UI Contrast and Implementing CSS Variables for Theming](https://youtu.be/m9V4SmJWoJU)
* Watched: [Week 3 - Security Considerations - Decentralized Authentication](https://youtu.be/tEJIeII66pY)



### STEP 1 - FRONTEND AUTHENTICATION, Provision via ClickOps a Amazon Cognito User Pool

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

### JWT 

### Authenticating Server Side [BACKEND AUTHENTICATION]

Add in the frontend-react-js , `HomeFeedPage.js` a header eto pass along the access token

```js
//add it to line 27 to 29. above method:"GET"
  headers: {
    Authorization: `Bearer ${localStorage.getItem("access_token")}`
  }
```
Create s folder in `backend-flask` named `lib` and create a file named `cognito_jwt_token` add this code:

```py
import time
import requests
from jose import jwk, jwt
from jose.exceptions import JOSEError
from jose.utils import base64url_decode

class FlaskAWSCognitoError(Exception):
  pass

class TokenVerifyError(Exception):
  pass

def extract_access_token(request_headers):
    access_token = None
    auth_header = request_headers.get("Authorization")
    if auth_header and " " in auth_header:
        _, access_token = auth_header.split()
    return access_token

class CognitoJwtToken:
    def __init__(self, user_pool_id, user_pool_client_id, region, request_client=None):
        self.region = region
        if not self.region:
            raise FlaskAWSCognitoError("No AWS region provided")
        self.user_pool_id = user_pool_id
        self.user_pool_client_id = user_pool_client_id
        self.claims = None
        if not request_client:
            self.request_client = requests.get
        else:
            self.request_client = request_client
        self._load_jwk_keys()


    def _load_jwk_keys(self):
        keys_url = f"https://cognito-idp.{self.region}.amazonaws.com/{self.user_pool_id}/.well-known/jwks.json"
        try:
            response = self.request_client(keys_url)
            self.jwk_keys = response.json()["keys"]
        except requests.exceptions.RequestException as e:
            raise FlaskAWSCognitoError(str(e)) from e

    @staticmethod
    def _extract_headers(token):
        try:
            headers = jwt.get_unverified_headers(token)
            return headers
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e

    def _find_pkey(self, headers):
        kid = headers["kid"]
        # search for the kid in the downloaded public keys
        key_index = -1
        for i in range(len(self.jwk_keys)):
            if kid == self.jwk_keys[i]["kid"]:
                key_index = i
                break
        if key_index == -1:
            raise TokenVerifyError("Public key not found in jwks.json")
        return self.jwk_keys[key_index]

    @staticmethod
    def _verify_signature(token, pkey_data):
        try:
            # construct the public key
            public_key = jwk.construct(pkey_data)
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e
        # get the last two sections of the token,
        # message and signature (encoded in base64)
        message, encoded_signature = str(token).rsplit(".", 1)
        # decode the signature
        decoded_signature = base64url_decode(encoded_signature.encode("utf-8"))
        # verify the signature
        if not public_key.verify(message.encode("utf8"), decoded_signature):
            raise TokenVerifyError("Signature verification failed")

    @staticmethod
    def _extract_claims(token):
        try:
            claims = jwt.get_unverified_claims(token)
            return claims
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e

    @staticmethod
    def _check_expiration(claims, current_time):
        if not current_time:
            current_time = time.time()
        if current_time > claims["exp"]:
            raise TokenVerifyError("Token is expired")  # probably another exception

    def _check_audience(self, claims):
        # and the Audience  (use claims['client_id'] if verifying an access token)
        audience = claims["aud"] if "aud" in claims else claims["client_id"]
        if audience != self.user_pool_client_id:
            raise TokenVerifyError("Token was not issued for this audience")

    def verify(self, token, current_time=None):
        """ https://github.com/awslabs/aws-support-tools/blob/master/Cognito/decode-verify-jwt/decode-verify-jwt.py """
        if not token:
            raise TokenVerifyError("No token provided")

        headers = self._extract_headers(token)
        pkey_data = self._find_pkey(headers)
        self._verify_signature(token, pkey_data)

        claims = self._extract_claims(token)
        self._check_expiration(claims, current_time)
        self._check_audience(claims)

        self.claims = claims 
        return claims

```

Add this `Flask-AWSCognito` to your `requirements.txt` file in backend-flask folder

Go to the backend-flask `cd backend-flask` and run this command `pip install -r requirements.txt` to install a libary, compose up

Add this for authentication to app.py

```py

#paste on line 17 under import
from lib.cognito_jwt_token import CognitoJwtToken, extract_access_token, TokenVerifyError



#paste on line 72 to 76 under app = Flask(__name__)
cognito_jwt_token = CognitoJwtToken(
  user_pool_id=os.getenv("AWS_COGNITO_USER_POOL_ID"), 
  user_pool_client_id=os.getenv("AWS_COGNITO_USER_POOL_CLIENT_ID"),
  region=os.getenv("AWS_DEFAULT_REGION")
)
```

```py
#replace cors on line 90 t0 96 under origins = [frontend, backend]
cors = CORS(
  app, 
  resources={r"/api/*": {"origins": origins}},
  headers=['Content-Type', 'Authorization'], 
  expose_headers='Authorization',
  methods="OPTIONS,GET,HEAD,POST"
)
```
Go to class `HomeActivities.py` and add 
  `def run(cognito_user_id=None)` to line8, under `class HomeActivities:`

  ```py
  #paste on line 55 to 65 above span.set, this is to test the configuration
      if cognito_user_id != None:
        extra_crud = {
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Lore',
          'message': 'My dear brother, it the humans that are the problem',
          'created_at': (now - timedelta(hours=1)).isoformat(),
          'expires_at': (now + timedelta(hours=12)).isoformat(),
          'likes': 1042,
          'replies': []
        }
        results.insert(0,extra_crud)
  ```

  ## Stretch Homework

  (Still working on them)

 - Decouple the JWT verify from the application code by writing a  Flask Middleware
- Decouple the JWT verify by implementing a Container Sidecar pattern using AWS’s official Aws-jwt-verify.js library
- Decouple the JWT verify process by using Envoy as a sidecar https://www.envoyproxy.io/
- Implement a IdP login eg. Login with Amazon or Facebook or Apple.
- Implement MFA that send an SMS (text message), warning this has spend, investigate spend before considering, text messages are not eligible for AWS Credits
