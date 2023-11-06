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
OPENWEATHERMAP_API_KEY = "<A value>" // Change to your OpenWeatherMap API key
```

and replace my account id with yours. 

```
IMAGE_REPOSITORY = "123456789012.dkr.ecr.us-east-2.amazonaws.com/weather"
OPENWEATHERMAP_API_KEY = "<A value>" // Change to your OpenWeatherMap API key
```

3. Set some environment variables

```
# Make one at https://home.openweathermap.org/api_keys
export OPENWEATHERMAP_API_KEY=<An API key>

# 
export GITHUB_AUTH_TOKEN=github_pat_<value goes here>
```