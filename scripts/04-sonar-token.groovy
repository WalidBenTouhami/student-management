import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

def instance = jenkins.model.Jenkins.getInstance()
def store = instance.getExtensionList("com.cloudbees.plugins.credentials.SystemCredentialsProvider")[0].getStore()

def tokenCredentials = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "sonar-token",
    "SonarQube Token",
    Secret.fromString("squ_1a68065e9dfc64029cc28b2f1c355beab1c5cc1c")
)

def existing = store.getCredentials(Domain.global()).find { it.id == "sonar-token" }
if (existing != null) {
    store.removeCredentials(Domain.global(), existing)
}

store.addCredentials(Domain.global(), tokenCredentials)
instance.save()
