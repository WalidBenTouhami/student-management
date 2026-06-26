# 🎓 Student Management System
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD_Automated-blue?logo=jenkins)
![SonarQube](https://img.shields.io/badge/SonarQube-Quality_Gate_Passed-success?logo=sonarqube)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployed-326ce5?logo=kubernetes)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5.16-6DB33F?logo=spring)
-----------------------------------
Bienvenue sur le projet **Student Management**, une application robuste développée avec **Spring Boot (Java 25 LTS)**, intégrant un environnement de développement et de déploiement DevOps complet.

---

## 🚀 Architecture et Fonctionnement du Projet

L'infrastructure du projet est entièrement conteneurisée et automatisée. Le pipeline CI/CD déploie l'application directement dans un cluster Kubernetes local (Minikube) situé à l'intérieur de la machine virtuelle Vagrant.

```mermaid
graph TD
    User([Développeur / Utilisateur]) -->|1. Git Push| GitHub(Dépôt GitHub)
    GitHub -->|2. Webhook| Jenkins(Jenkins CI/CD)
    
    subgraph Vagrant VM [Vagrant VM - 192.168.56.10]
        Jenkins -->|3. Maven Build & Sonar| SonarQube(SonarQube)
        Jenkins -->|4. Docker Build & Trivy Scan| Minikube((Minikube K8s Cluster))
        Jenkins -->|5. helm upgrade| Minikube
        
        subgraph Minikube Cluster [Cluster Minikube]
            Ingress(NGINX Ingress)
            AppPod(Spring Boot Pod)
            DBPod[(MySQL Pod & PVC)]
            PrometheusPod(Prometheus Pod)
            GrafanaPod(Grafana Pod)
            
            Ingress -->|api.student.local| AppPod
            Ingress -->|grafana.student.local| GrafanaPod
            AppPod --> DBPod
            PrometheusPod -.->|6. Scrape Metrics| AppPod
            GrafanaPod -->|7. Read Metrics| PrometheusPod
        end
    end
    
    User -->|8. Accès API & Swagger| Ingress
    User -->|9. Accès Dashboards| Ingress
```

---

## 🚀 Fonctionnalités Principales
- Gestion des **Étudiants** (Création, lecture, mise à jour, suppression).
- Gestion des **Départements**.
- Gestion des **Inscriptions (Enrollments)** aux différents cours.
- API REST documentée interactivement avec **Swagger UI**.

---

## 🛠️ Stack Technique
- **Langage** : Java 25 LTS
- **Framework** : Spring Boot
- **Base de données** : MySQL 8.0
- **DevOps & SecOps** :
  - **CI/CD** : Jenkins (Pipeline as Code)
  - **Orchestration** : Kubernetes (Minikube) & Helm (Package Manager)
  - **Ingress Routing** : NGINX Ingress Controller
  - **Qualité & Sécurité** : SonarQube (SAST), Trivy (Container Scanning)
  - **Monitoring** : Prometheus & Grafana
  - **Environnement Virtuel** : Vagrant (Ubuntu 22.04 LTS)

---

## ⚙️ Démarrage Rapide

### Option 1 : Déploiement Complet K8s & CI/CD (Recommandé)
1. Démarrez la machine virtuelle Vagrant :
```bash
vagrant up
vagrant ssh
```
2. Installez Minikube et Kubectl via le script automatisé :
```bash
cd /vagrant
./scripts/install-k8s.sh
```
3. Poussez votre code sur GitHub pour déclencher le pipeline Jenkins (ou lancez le build manuellement). Jenkins se chargera de builder, analyser, conteneuriser et déployer l'application sur le cluster Kubernetes local.

### Option 2 : Démarrage Natif de Secours
Si vous ne souhaitez pas utiliser Kubernetes, vous pouvez utiliser notre gestionnaire bash local. Notez que l'application est prioritairement conçue pour être gérée par K8s.
```bash
./scripts/manage-app.sh start
./scripts/manage-app.sh stop
./scripts/manage-app.sh status
./scripts/manage-app.sh clean
```

---

## 📊 URLs de l'Environnement (Vagrant)

| Service | URL | Identifiants par défaut |
|---|---|---|
| **Spring Boot API** | `http://api.student.local` (via Ingress) | N/A |
| **Swagger UI** | `http://api.student.local/student/swagger-ui.html` | N/A |
| **Jenkins** | `http://192.168.56.10:8080` | Voir logs Vagrant |
| **SonarQube** | `http://192.168.56.10:9000` | `admin` / `admin` |
| **Grafana** | `http://grafana.student.local` (via Ingress) | `admin` / `admin` |
| **Prometheus** | `http://192.168.56.10:30090` (NodePort K8s) | N/A |

---

## 📁 Architecture du Dépôt
- `src/` : Code source Java.
- `docker/` : Dockerfiles, configuration Compose (infra monitoring & CI).
- `helm/student-management/` : Chart Helm contenant toute l'infrastructure dynamique (Deployments, Services, Ingress, PVC, ConfigMaps).
- `scripts/` : Scripts bash d'utilitaires :
  - `install-k8s.sh` : Installe et configure Minikube pour Jenkins.
  - `k8s-expose.sh` : Expose automatiquement un service K8s sur le premier port libre.
  - `manage-app.sh` : Gestionnaire local de secours de l'application Spring Boot.
- `Jenkinsfile` : Pipeline CI/CD automatisé de bout en bout.
- `Vagrantfile` : Infrastructure as Code de l'environnement de développement.
