# inadev-infra-screen

# Prerquisites

- helm
- kubectl
- docker
- the aws cli hooked up to an admin user
- jq
- A github PAT
- An OpenWeather API token

# Instructions
1. Get an OpenWeatherMap API key from https://home.openweathermap.org/api_keys.  Make an account if required.  
2. Fix the Jenkinsfile

This are the two magic strings I never figured out how to get rid of.  Find the line in the Jenkinsfile that says:

```
IMAGE_REPOSITORY = "386145735201.dkr.ecr.us-east-2.amazonaws.com/weather"
```

and replace my account id with yours. 

```
IMAGE_REPOSITORY = "123456789012.dkr.ecr.us-east-2.amazonaws.com/weather"
```

3. Set some environment variables

```
# Make one at https://home.openweathermap.org/api_keys
export OPENWEATHERMAP_API_KEY=<An API key>

# 
export GITHUB_AUTH_TOKEN=github_pat_<value goes here>
```

4. Run `./one_script.sh` from the root of the checked-out repository

This, in order, makes: 
- 2 ECR repositories for your app and your Jenkins
- Builds the Jenkins Agent and your app
- Pushes them both to ECR
- Stands up the k8s cluster
- Installs Jenkins on the K8s cluster
- Runs a script in a container to setup a new project/update the existing one against your currently checked-out branch
- Triggers a build

The bottom of your output will look like this: 

```
To access the cluster, run the following command:
aws eks --region us-east-2 update-kubeconfig --name inadev-kmeyer

Your image repository is at: 386145735201.dkr.ecr.us-east-2.amazonaws.com/weather
Please update the Jenkinsfile to use the correct ECR repository

Jenkins is up at http://a848ba3a8bc7a439886231a2e9f3cc62-1450682592.us-east-2.elb.amazonaws.com
Username: admin
Password: <a password>
Your service can be found at: http://a3c68d60dfcfa4f829de10d20a0dd3d7-1998966705.us-east-2.elb.amazonaws.com
```

To rip it all down, `teardown.sh` will make a valiant attempt at killing everything, though from experience deleting the VPC always finds something that's still around

Particularly, I reccomend looking at your load balancers in EC2.  

