"""
Don't actually run this, but copy-paste the code into a Python REPL
"""

# pylint: skip-file

import jenkins
import os
from github import Auth, Github

JENKINS_ENDPOINT = os.environ.get("JENKINS_ENDPOINT")
JENKINS_USERNAME = os.environ.get("JENKINS_USERNAME")
JENKINS_PASSWORD = os.environ.get("JENKINS_PASSWORD")

server = jenkins.Jenkins(
    JENKINS_ENDPOINT, username=JENKINS_USERNAME, password=JENKINS_PASSWORD)

job_name = "inadev-kmeyer/inadev-pipeline"
