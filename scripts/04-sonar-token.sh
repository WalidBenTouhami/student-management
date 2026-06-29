#!/bin/bash
echo "Waiting for SonarQube to be UP..."
while true; do
  STATUS=$(curl -s -u admin:admin 'http://localhost:9000/api/system/status' | jq -r '.status' 2>/dev/null)
  if [ "$STATUS" == "UP" ]; then
    break
  fi
  sleep 5
done

echo "SonarQube is UP! Disabling force user authentication..."
curl -s -u admin:admin -X POST 'http://localhost:9000/api/settings/set?key=sonar.core.forceAuthentication&value=false'

echo "Creating SonarQube token for Jenkins..."
curl -s -u admin:admin -X POST 'http://localhost:9000/api/user_tokens/revoke?name=jenkins' > /dev/null
TOKEN=$(curl -s -u admin:admin -X POST 'http://localhost:9000/api/user_tokens/generate?name=jenkins' | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    # Maybe default password is not admin anymore, or token generation failed
    echo "Failed to generate SonarQube token."
    exit 1
fi
echo "Generated token: $TOKEN"

echo "Configuring token in Jenkins..."
cat << EOF > /tmp/add-sonar-token.groovy
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

def instance = jenkins.model.Jenkins.getInstance()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def tokenCredentials = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "sonar-token",
    "SonarQube Token",
    Secret.fromString("${TOKEN}")
)

def existing = store.getCredentials(Domain.global()).find { it.id == "sonar-token" }
if (existing != null) {
    store.removeCredentials(Domain.global(), existing)
}

store.addCredentials(Domain.global(), tokenCredentials)
instance.save()
EOF

curl -s -u admin:admin --data-urlencode "script=$(cat /tmp/add-sonar-token.groovy)" http://localhost:8080/scriptText
echo "Token successfully injected into Jenkins."
