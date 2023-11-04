import jenkins
import os
from github import Auth, Github

# GitHub credentials
GITHUB_AUTH_TOKEN = os.environ.get("GITHUB_AUTH_TOKEN")
if not GITHUB_AUTH_TOKEN:
    raise Exception("GITHUB_AUTH_TOKEN environment variable must be set.")
GITHUB_REPOSITORY_URL = os.environ.get("GITHUB_REPOSITORY_URL")
if not GITHUB_REPOSITORY_URL or not  "github.com" in GITHUB_REPOSITORY_URL:
    raise Exception("GITHUB_REPOSITORY environment variable must be set to a fully qualified github.com URL.")

# Strip it down to just the owner/repo
GITHUB_REPOSITORY = GITHUB_REPOSITORY_URL.split("github.com/")[-1]
GITHUB_REPOSITORY = GITHUB_REPOSITORY.replace(".git", "")
if GITHUB_REPOSITORY.endswith("/"):
    GITHUB_REPOSITORY = GITHUB_REPOSITORY[:-1]

# Jenkins credentials
JENKINS_ENDPOINT = os.environ.get("JENKINS_ENDPOINT")
JENKINS_USERNAME = os.environ.get("JENKINS_USERNAME")
JENKINS_PASSWORD = os.environ.get("JENKINS_PASSWORD")

def setup_github_webhook():
    auth = Auth.Token(GITHUB_AUTH_TOKEN)

    # First create a Github instance:

    # Public Web Github
    g = Github(auth=auth)
    
    webhook_url = f"{JENKINS_ENDPOINT}/github-webhook/"

    webhook_events = ["push", "pull_request"]


    # Get the repository
    repo = g.get_repo(GITHUB_REPOSITORY)

    # Create the webhook
    # sort of kind of idempotent, sure
    try:
        # This name seems to be required to be "web" for some reason
        repo.create_hook("web", {"url": webhook_url, "content_type": "json"}, webhook_events, active=True)
    except Exception as e:
        if "Hook already exists on this repository" in str(e):
            hooks = repo.get_hooks()
            for hook in hooks:
                if hook.config["url"] == webhook_url:
                    hook.edit(name = hook.name, config={"url": webhook_url, "content_type": "json"}, events=webhook_events, active=True)
            return
        
        print(f"Failed to create webhook for {GITHUB_REPOSITORY} on url {webhook_url}.")
        print(e)
        raise e

def setup_jenkins_project():
    # Initialize the Jenkins server connection
    server = jenkins.Jenkins(JENKINS_ENDPOINT, username=JENKINS_USERNAME, password=JENKINS_PASSWORD)

    # TODO: Make all these names into parameters as well
    # Create a new Jenkins folder
    folder_name = "inadev-kmeyer"
    try:
        server.create_folder(folder_name)
    except jenkins.JenkinsException as original_exception:
        try:
            server.assert_folder(folder_name)
        except jenkins.JenkinsException as assert_exception:
            print(f"Failed to create Jenkins folder '{folder_name}'.")
            print(f"Original exception: {original_exception}")
            print(f"Assert exception: {assert_exception}")
            raise original_exception

    # Do not ask how long it took me to figure out that .strip() was needed here
    project_config = (f"""
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1360.vc6700e3136f5">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@1.9.3"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@1.9.3">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.37.3.1">
      <projectUrl>{GITHUB_REPOSITORY_URL}</projectUrl>
      <displayName></displayName>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3806.va_3a_6988277b_2">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.2.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>{GITHUB_REPOSITORY_URL}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
""").strip()
    project_name = f"{folder_name}/inadev-pipeline"
    # Create a new Jenkins project
    server.upsert_job(project_name, project_config)

def main():
    setup_jenkins_project()
    setup_github_webhook()


if __name__ == "__main__":
    main()
