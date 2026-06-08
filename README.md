# 🎓 Student Management System

Bienvenue dans le projet **Student Management** ! Il s'agit d'une application backend robuste construite avec Spring Boot, gérant des étudiants, des cours et des départements.

Ce projet est conçu avec une approche **DevOps complète**. Il inclut une configuration Docker avancée et un pipeline CI/CD automatisé sous Jenkins.

---

## 🚀 1. Développement Local

Si vous souhaitez faire tourner le projet sur votre propre machine pour le modifier ou le tester :

### Prérequis
- **Java 21** (ou supérieur)
- **Docker** (pour la base de données locale)

### Compiler le projet
Nous utilisons Maven (via le wrapper `mvnw` fourni) pour compiler l'application. Cette étape va télécharger les dépendances et générer un fichier `.jar` exécutable :

```bash
# Sous Linux / Mac / WSL
./mvnw clean package

# Sous Windows (PowerShell/CMD)
./mvnw.cmd clean package
```
> *Astuce : Ajoutez `-DskipTests` à la fin de la commande si vous souhaitez ignorer l'exécution des tests unitaires pour compiler plus vite.*

---

## 🐳 2. Architecture Docker

L'application est conteneurisée à l'aide d'un fichier `Dockerfile` utilisant la technique du **Multi-stage build**.
1. **Stage de Build** : Utilise une image contenant Maven pour compiler le code de manière isolée.
2. **Stage de Run** : Utilise une image "distroless" (ultra-légère et sécurisée, sans système d'exploitation complet) pour exécuter l'application.

### Lancer l'environnement complet (App + Base de données)
Vous pouvez démarrer l'application ainsi qu'une base de données MySQL via Docker :

```bash
# 1. Créer un réseau privé pour que les conteneurs communiquent entre eux
docker network create app-network

# 2. Démarrer MySQL
docker run -d --name mysql --network app-network -e MYSQL_ROOT_PASSWORD=*** -e MYSQL_DATABASE=studentdb mysql:8.0

# 3. Construire et Démarrer l'application
docker build -t student-management:latest .
docker run -d --name student-app --network app-network -p 8089:8089 -e SPRING_DATASOURCE_URL="jdbc:mysql://mysql:3306/studentdb" -e SPRING_DATASOURCE_USERNAME=root -e SPRING_DATASOURCE_PASSWORD=*** student-management:latest
```

---

## ⚙️ 3. Intégration et Déploiement Continus (CI/CD)

Le projet intègre un pipeline **Jenkins** entièrement automatisé, défini dans le fichier `Jenkinsfile`.

### Les étapes du Pipeline (Stages) :
1. **Checkout** : Jenkins récupère le code source le plus récent depuis GitHub suite à un évènement (Webhook).
2. **Build and Test** : Exécution de Maven (`./mvnw clean package`) pour s'assurer que le code compile et que les tests passent.
3. **Build Docker Image** : Création de l'image Docker de l'application à partir du `Dockerfile`.
4. **Push to Registry** : L'image est poussée sur Docker Hub pour être disponible depuis n'importe quel serveur.
5. **Clean & Deploy** : Jenkins arrête les anciens conteneurs sur le serveur, met à jour l'image, et redémarre la base de données et l'application sur le réseau Docker.

> 🔒 **Sécurité :** Les mots de passe et identifiants (Docker Hub, MySQL) sont injectés via des variables d'environnement secrètes gérées par Jenkins. Ils n'apparaissent jamais en clair dans le code.

---

## 📊 4. Surveillance Jenkins en Terminal (Bonus DevOps)

Le projet inclut un script Bash fait maison pour surveiller l'état de vos pipelines Jenkins en direct, sans ouvrir de navigateur !

### Installation
Le script se trouve dans le dossier `scripts/`. Assurez-vous qu'il est exécutable :
```bash
chmod +x scripts/jenkins_jobs_monitor.sh
```

### Utilisation (Mode Surveillance en temps réel)
Lancez le script avec l'option `--watch` pour afficher un tableau de bord qui se met à jour automatiquement (par défaut toutes les 5 secondes, ici réglé sur 10) :

```bash
./scripts/jenkins_jobs_monitor.sh \
  --url=http://<votre-ip-jenkins>:8080 \
  --user=admin \
  --password=<votre-mot-de-passe-ou-token> \
  --watch \
  --refresh=10
```

> 💡 **Astuce Vagrant :** Si vous lancez ce script depuis une machine virtuelle Vagrant (VirtualBox) pour observer un Jenkins installé sur votre Windows physique, remplacez l'IP par `10.0.2.2`.

---
*Ce projet est une démonstration complète d'une architecture backend moderne, de la conception logicielle au déploiement automatisé.*
