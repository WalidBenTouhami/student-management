import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import com.cloudbees.jenkins.GitHubPushTrigger

def instance = Jenkins.getInstance()
def jobName = "student-management-pipeline"
def job = instance.getItem(jobName)

if (job != null) {
    def trigger = new GitHubPushTrigger()
    job.addTrigger(trigger)
    trigger.start(job, true)
    job.save()
    println "GitHub Webhook trigger enabled for ${jobName}"
} else {
    println "Job ${jobName} not found!"
}
