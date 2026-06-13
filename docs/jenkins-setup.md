# Jenkins Setup Guide

## 1. Installation Prerequisites

```bash
# Install Trivy on Jenkins agent
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

# Verify
trivy --version

# Install Helm on Jenkins agent
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify kubectl access to Minikube
kubectl cluster-info --context minikube
```

## 2. Jenkins Global Tool Configuration

Go to **Manage Jenkins → Tools**:

| Tool | Name | Version |
|---|---|---|
| JDK | `JDK21` | Java 21 (Temurin) |
| Maven | `Maven3.9` | 3.9.x |

## 3. SonarQube Server Configuration

Go to **Manage Jenkins → System → SonarQube servers**:
- Name: `SonarQube`
- URL: `http://localhost:9000`
- Server authentication token: (use credential `Sonar_token`)

## 4. Required Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials**:

```
ID: github-token
  Type: Username with password
  Username: your-github-username
  Password: ghp_xxxx (GitHub PAT with repo scope)

ID: docker-hub-credentials
  Type: Username with password
  Username: walid369
  Password: docker-hub-password-or-token

ID: Sonar_token
  Type: Secret text
  Secret: squ_xxxxxxxxxxxx (SonarQube user token)

ID: kubeconfig-minikube
  Type: Secret file
  File: Upload ~/.kube/config (from Minikube machine)

ID: mysql-root-credentials
  Type: Username with password
  Username: root
  Password: your-mysql-root-password

ID: mysql-app-credentials
  Type: Username with password
  Username: student_user
  Password: your-mysql-app-password

ID: actuator-credentials
  Type: Username with password
  Username: actuator-admin
  Password: your-actuator-password

ID: api-credentials
  Type: Username with password
  Username: api-user
  Password: your-api-password
```

## 5. Required Plugins

Install from **Manage Jenkins → Plugins**:

```
✅ Git
✅ Pipeline
✅ Pipeline: Stage View
✅ SonarQube Scanner
✅ Docker Pipeline
✅ JaCoCo
✅ HTML Publisher
✅ Credentials Binding
✅ Timestamper
✅ GitHub Integration (for webhooks)
```

## 6. Create Pipeline Job

1. **New Item** → Pipeline
2. Name: `student-management`
3. **Build Triggers**: ✅ GitHub hook trigger for GITScm polling
4. **Pipeline**: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/WalidBenTouhami/student-management.git`
   - Credentials: `github-token`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

## 7. GitHub Webhook

In your GitHub repo → Settings → Webhooks:
- Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
- Content type: `application/json`
- Events: `Just the push event`

## 8. Troubleshooting

### Quality Gate timeout
```
# SonarQube webhook must be configured:
# SonarQube → Administration → Webhooks → Create
# URL: http://YOUR_JENKINS_URL/sonarqube-webhook/
```

### Trivy not found
```bash
which trivy || curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### kubectl access denied
```bash
# On Jenkins agent, ensure kubeconfig is valid
kubectl --kubeconfig /path/to/config get nodes
```
