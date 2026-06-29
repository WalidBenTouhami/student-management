import jenkins.model.*
import hudson.plugins.sonar.*
import hudson.plugins.sonar.model.TriggersConfig
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

def instance = Jenkins.getInstance()
def sonarGlobalConfig = instance.getDescriptor(SonarGlobalConfiguration.class)

// Configure SonarQube Installation
def sonarInst = new SonarInstallation(
    "SonarQube", // Name
    "http://192.168.56.10:9000", // Server URL
    "sonar-token", // Credentials ID (to be created later)
    "", // Server version
    "", // Additional properties
    new TriggersConfig(),
    ""
)

sonarGlobalConfig.setInstallations(sonarInst)
sonarGlobalConfig.save()
