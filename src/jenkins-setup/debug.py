import jenkins
import os
from github import Auth, Github

JENKINS_ENDPOINT = os.environ.get("JENKINS_ENDPOINT")
JENKINS_USERNAME = os.environ.get("JENKINS_USERNAME")
JENKINS_PASSWORD = os.environ.get("JENKINS_PASSWORD")

server = jenkins.Jenkins(JENKINS_ENDPOINT, username=JENKINS_USERNAME, password=JENKINS_PASSWORD)