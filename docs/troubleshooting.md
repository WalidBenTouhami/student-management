# Troubleshooting Guide

This guide contains solutions to common problems encountered during the setup and deployment of the Student Management System.

## 1. Kubernetes & Minikube Issues

### Pod stuck in Pending
```bash
kubectl describe pod <pod-name> -n student-management
```
Check the **Events** section at the bottom of the output for resource or scheduling issues.

### OOMKilled (Out of Memory)
If pods are frequently killed due to OOM:
```bash
# Increase Minikube memory
minikube stop
minikube start --cpus=4 --memory=6144 --driver=docker
```

### MySQL Connection Refused
If the application pod is crash-looping because it can't connect to MySQL:
```bash
# Check MySQL pod status
kubectl get pods -n student-management -l app.kubernetes.io/name=mysql
kubectl logs -n student-management -l app.kubernetes.io/name=mysql

# Verify the service exists
kubectl get svc mysql-service -n student-management
```

### HPA Not Scaling
If HorizontalPodAutoscaler shows `<unknown>` for metrics:
```bash
# Ensure metrics-server is running
kubectl get pods -n kube-system -l k8s-app=metrics-server

# If not running, enable it:
minikube addons enable metrics-server
```

---

## 2. Jenkins CI/CD Issues

### Quality Gate Timeout
If the pipeline is stuck waiting for SonarQube's Quality Gate result:
1. Ensure the SonarQube webhook is configured.
2. Go to **SonarQube → Administration → Configuration → Webhooks**.
3. Create a webhook pointing to your Jenkins instance:
   `http://YOUR_JENKINS_URL/sonarqube-webhook/`

### Trivy "Command Not Found"
If the pipeline fails at the Trivy step:
```bash
# On the Jenkins agent, install Trivy:
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### Kubectl Access Denied
If the Jenkins "Deploy to Kubernetes" stage fails with permission errors:
```bash
# On the Jenkins agent, ensure the kubeconfig is valid
kubectl --kubeconfig /path/to/kube/config cluster-info
```
Ensure the `kubeconfig-minikube` credential in Jenkins has the correct contents from your Minikube host's `~/.kube/config` file, and that the certificate paths inside the config are resolvable by Jenkins.
