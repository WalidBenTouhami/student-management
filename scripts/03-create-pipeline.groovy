import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.UserRemoteConfig
import hudson.plugins.git.BranchSpec

def instance = Jenkins.getInstance()
def jobName = "student-management-pipeline"

// Create the pipeline job if it doesn't exist
def job = instance.getItem(jobName)
if (job == null) {
    job = instance.createProject(WorkflowJob.class, jobName)
}

// Configure Git SCM
def userRemoteConfig = new UserRemoteConfig("https://github.com/WalidBenTouhami/student-management.git", "", "", "")
def branchSpec = new BranchSpec("*/main")
def scm = new GitSCM([userRemoteConfig], [branchSpec], false, [], null, null, [])

// Configure Flow Definition
def flowDefinition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
flowDefinition.setLightweight(true)
job.setDefinition(flowDefinition)

job.save()
