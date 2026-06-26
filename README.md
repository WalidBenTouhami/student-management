# 🎓 Student Management System
-----------------------------------
Bienvenue sur le projet **Student Management**, une application robuste développée avec **Spring Boot (Java 25 LTS)**, intégrant un environnement de développement et de déploiement DevOps complet.

---

## 🚀 Fonctionnalités Principales
- Gestion des **Étudiants** (Création, lecture, mise à jour, suppression).
- Gestion des **Départements**.
- Gestion des **Inscriptions (Enrollments)** aux différents cours.
- API REST documentée.

---

## 🛠️ Stack Technique
- **Langage** : Java 25 LTS
- **Framework** : Spring Boot
- **Base de données** : MySQL 8.0
- **DevOps** :
  - **CI/CD** : Jenkins (Pipeline as Code via `Jenkinsfile`)
  - **Conteneurisation** : Docker & Docker Compose
  - **Orchestration** : Kubernetes (Manifests dans le dossier `k8s/`)
  - **Analyse de Qualité** : SonarQube avec couverture JaCoCo
  - **Monitoring** : Prometheus & Grafana
  - **Environnement Virtuel** : Vagrant (Ubuntu 22.04 LTS)

---

## ⚙️ Démarrage Rapide

### Option 1 : Environnement Vagrant Complet (DevOps)
Si vous souhaitez bénéficier de la machine virtuelle complète avec Jenkins, SonarQube et Grafana installés :
```bash
vagrant up
vagrant ssh
```
> [!NOTE]
> La VM sera disponible à l'adresse **192.168.56.10**.

### Option 2 : Docker Compose (API & BDD)
Pour démarrer rapidement l'application locale et sa base de données MySQL :
```bash
docker-compose -f docker/docker-compose.yml up -d
```
L'API sera disponible sur : `http://localhost:8089/student`

### Option 3 : En local (via le gestionnaire)
Assurez-vous d'avoir configuré une base de données MySQL (`studentdb`, `spring`/`spring123`).

Utilisez notre gestionnaire pour démarrer l'application proprement en arrière-plan :
```bash
./scripts/manage-app.sh start
```

---

## 🚀 Gestion de l'Application

### Démarrer l'application
```bash
./scripts/manage-app.sh start
```

### Arrêter l'application
```bash
./scripts/manage-app.sh stop
```

### Voir le statut
```bash
./scripts/manage-app.sh status
```

### Voir les logs
```bash
./scripts/manage-app.sh logs
```

### Nettoyer les processus orphelins
```bash
./scripts/manage-app.sh clean
```

---

## 🧪 Tests et Qualité de Code
Les tests unitaires sont couverts avec JUnit 5 et Mockito. Un rapport JaCoCo est généré pour SonarQube.
Pour exécuter les tests :
```bash
mvn clean test jacoco:report
```

---

## 📊 URLs de l'Environnement (Vagrant)
| Service | URL | Identifiants par défaut |
|---|---|---|
| **Spring Boot API** | `http://192.168.56.10:8089/student` | N/A |
| **Jenkins** | `http://192.168.56.10:8080` | Voir logs Vagrant |
| **SonarQube** | `http://192.168.56.10:9000` | `admin` / `admin` |
| **Grafana** | `http://192.168.56.10:3000` | `admin` / `admin` |
| **Prometheus** | `http://192.168.56.10:9090` | N/A |

---

## 📁 Architecture du Dépôt
- `src/` : Code source Java.
- `docker/` : Dockerfiles, configuration Compose et Monitoring.
- `k8s/` : Manifestes de déploiement Kubernetes.
- `scripts/` : Scripts bash d'utilitaires (Check, Deploy).
- `Jenkinsfile` : Pipeline CI/CD.
- `Vagrantfile` : Infrastructure as Code de l'environnement de développement.
