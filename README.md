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

1. Fix the Jenkinsfile

This is the one magic string I never figured out how to get rid of.  Find the line in the Jenkinsfile that says:

```
IMAGE_REPOSITORY = "386145735201.dkr.ecr.us-east-2.amazonaws.com/weather"
```

and replace my account id with yours. 

```
IMAGE_REPOSITORY = "123456789012.dkr.ecr.us-east-2.amazonaws.com/weather"
```

2. Set some environment variables

```
# Make one at https://home.openweathermap.org/api_keys
export OPENWEATHERMAP_API_KEY=<An API key>

# 
export GITHUB_AUTH_TOKEN=github_pat_<value goes here>
```