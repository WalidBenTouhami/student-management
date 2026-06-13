# 🥷 Advanced Setup: SRE / DevOps

Ce guide décrit l'architecture avancée de la plateforme `student-management` déployée sur Kubernetes (Minikube).

## 1. 🌐 Ingress (`student.local`)

L'API est exposée via l'Ingress Controller NGINX. 
Pour y accéder localement, ajoutez cette ligne à votre fichier `hosts` (`/etc/hosts` sous Linux/Mac ou `C:\Windows\System32\drivers\etc\hosts` sous Windows) :

```
<IP-DE-MINIKUBE> student.local
```
*(Obtenez l'IP avec la commande `minikube ip`)*

Accès API : `http://student.local/student/actuator/health`

## 2. 📈 Autoscaling (HPA)

Un HorizontalPodAutoscaler (HPA) gère dynamiquement le nombre de pods de l'API.
- **CPU Target** : 50%
- **Memory Target** : 70%
- **Réplicas** : Min 2, Max 6

Pour surveiller l'autoscaling :
```bash
kubectl get hpa -n student-management -w
```

## 3. 📊 Monitoring (Prometheus & Grafana)

La stack `kube-prometheus-stack` est déployée et scrappe automatiquement les métriques de Spring Boot.

**Accéder à Grafana :**
```bash
kubectl port-forward svc/prometheus-grafana -n student-management 3000:80
```
- **URL** : http://localhost:3000
- **User** : `admin`
- **Password** : `admin`

Le dashboard Spring Boot (ID: 12900) est importé et pré-configuré.

## 4. 🪵 Centralized Logging (Loki)

Loki collecte et indexe les logs JSON formatés en ECS (Elastic Common Schema).
Dans Grafana (voir ci-dessus), allez dans **Explore**, sélectionnez la source de données **Loki**, et utilisez cette requête LogQL :
```logql
{app_kubernetes_io_name="student-management"}
```

## 5. 🔄 GitOps (ArgoCD)

Le déploiement continu est orchestré par ArgoCD via les manifests Kustomize (`k8s/base` et `k8s/overlays/dev`).

**Accéder à l'interface ArgoCD :**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
- **URL** : https://localhost:8080
- **User** : `admin`
- **Password** : `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

L'application GitOps pointe vers `https://github.com/NadineMili/student-management-devops`. Toute modification pushée sur la branche sera synchronisée automatiquement.
