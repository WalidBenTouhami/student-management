# Kubernetes Setup Guide (Minikube)

## 1. Start Minikube

```bash
# Start with enough resources for 2 app pods + MySQL
minikube start \
  --cpus=4 \
  --memory=4096 \
  --disk-size=20g \
  --driver=docker

# Enable required addons
minikube addons enable metrics-server   # Required for HPA
minikube addons enable ingress          # Optional: nginx ingress
```

## 2. Verify Cluster

```bash
kubectl cluster-info
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   5m    v1.28.x
```

## 3. Deploy with Helm

```bash
# 1. Lint the chart
make helm-lint

# 2. Dry-run to preview K8s objects
make helm-dry-run

# 3. Set secrets as environment variables (never hardcode)
export MYSQL_ROOT_PASSWORD="s3cr3t-root-$(openssl rand -hex 8)"
export MYSQL_APP_USER="student_user"
export MYSQL_APP_PASSWORD="s3cr3t-app-$(openssl rand -hex 8)"
export ACTUATOR_USER="actuator-admin"
export ACTUATOR_PASSWORD="s3cr3t-act-$(openssl rand -hex 8)"
export API_USER="api-user"
export API_PASSWORD="s3cr3t-api-$(openssl rand -hex 8)"

# 4. Deploy
make k8s-deploy

# 5. Check status
make k8s-status
```

## 4. Access Application

```bash
export MINIKUBE_IP=$(minikube ip)

# Application health
curl -u "$ACTUATOR_USER:$ACTUATOR_PASSWORD" \
  http://$MINIKUBE_IP:30089/student/actuator/health | python3 -m json.tool

# Prometheus metrics
curl http://$MINIKUBE_IP:30089/student/actuator/prometheus | head -30

# Open browser
minikube service student-management-service -n student-management --url
```

## 5. Monitor HPA

```bash
# Watch HPA in real-time
watch kubectl get hpa -n student-management

# Generate load to trigger autoscaling (in a separate terminal)
kubectl run load-test --image=busybox -n student-management --rm -it -- \
  sh -c "while true; do wget -q -O- http://student-management-service:8089/student/actuator/health; done"
```

## 6. Check Logs

```bash
# All app pods
make k8s-logs

# Specific pod
kubectl logs -n student-management <pod-name> --follow

# MySQL logs
kubectl logs -n student-management -l app.kubernetes.io/name=mysql -f
```

## 7. Deploy via Raw YAML (without Helm)

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Create secrets (edit the template first with your base64 values)
# echo -n "your-value" | base64
cp k8s/secret.yaml.template k8s/secret-actual.yaml
# Edit k8s/secret-actual.yaml with your base64 values
kubectl apply -f k8s/secret-actual.yaml

# 3. Apply all resources
make k8s-apply-raw

# 4. Check status
kubectl get all -n student-management
```

## 8. Troubleshooting

### Pod stuck in Pending
```bash
kubectl describe pod <pod-name> -n student-management
# Check: Events section for resource/scheduling issues
```

### OOMKilled (Out of Memory)
```bash
# Increase Minikube memory or reduce resource limits in values.yaml
minikube stop
minikube start --memory=6144
```

### MySQL connection refused
```bash
# Check MySQL pod status
kubectl get pods -n student-management -l app.kubernetes.io/name=mysql
kubectl logs -n student-management -l app.kubernetes.io/name=mysql

# Verify service
kubectl get svc mysql-service -n student-management
```

### HPA not scaling (metrics not available)
```bash
# Ensure metrics-server is running
kubectl get pods -n kube-system -l k8s-app=metrics-server
# If not running:
minikube addons enable metrics-server
```
