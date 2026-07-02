# 🏫 Student Management – Projet DevOps

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-85%25-success)
![Java Version](https://img.shields.io/badge/Java-25%20LTS-blue)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5-brightgreen)

## 📖 Description
L'application **Student Management** est une plateforme moderne permettant la gestion complète des étudiants, de leurs départements d'affectation et de leurs inscriptions aux cours.
Ce projet a été conçu avec une approche **DevOps & SRE** forte, intégrant des pipelines CI/CD robustes, une infrastructure Kubernetes (Helm) et une stack de supervision complète.

## 🛠️ Technologies
* **Backend** : [Java 25](https://jdk.java.net/25/) & [Spring Boot 3.5](https://spring.io/projects/spring-boot)
* **Base de données** : [MySQL 8.0](https://www.mysql.com/) avec [Flyway](https://flywaydb.org/)
* **Conteneurisation & Orchestration** : [Docker](https://www.docker.com/), [Kubernetes](https://kubernetes.io/) (Minikube), [Helm](https://helm.sh/)
* **CI/CD** : [Jenkins](https://www.jenkins.io/)
* **Supervision** : [Prometheus](https://prometheus.io/) & [Grafana](https://grafana.com/)
* **Virtualisation locale** : [Vagrant](https://www.vagrantup.com/) & [VirtualBox](https://www.virtualbox.org/)

## ⚙️ Prérequis
* CPU : 4 cœurs minimum recommandés.
* RAM : 8 Go minimum (16 Go recommandés).
* Logiciels :
  * Git
  * Vagrant
  * VirtualBox

## 🚀 Installation rapide
Pour lancer l'environnement complet (VM + Kubernetes + Jenkins + Supervision) en local :

```bash
git clone https://github.com/votre-org/student-management.git
cd student-management
vagrant up

# Déploiement magique complet (Build, Push, Helm, Tests)
./devops-menu.sh --action all-in-one
```
*(Le premier démarrage peut prendre entre 15 et 30 minutes).*

**URLs d'accès par défaut :**
* 🌐 **API Spring Boot** : `http://192.168.56.10:30089/student/api-docs`
* 🛠️ **Jenkins** : `http://192.168.56.10:8088`
* 📊 **Grafana** : `http://192.168.56.10:3000` (admin / admin)
* 📈 **Prometheus** : `http://192.168.56.10:9090`
* 🔍 **SonarQube** : `http://192.168.56.10:9000`

## 📂 Structure du projet
```text
student-management/
├── docs/                 # Documentation détaillée
├── src/                  # Code source Java Spring Boot
├── docker/               # Fichiers Docker Compose et Prometheus/Grafana
├── helm/                 # Charts Helm pour Kubernetes
├── k8s/                  # Manifestes Kubernetes (secrets, RBAC)
├── Vagrantfile           # Configuration de la VM Vagrant
└── Jenkinsfile           # Pipeline CI/CD as Code
```

## 📚 Documentation détaillée
Pour plus d'informations, veuillez consulter les documents suivants :
* [Guide d'Installation (INSTALL.md)](docs/INSTALL.md)
* [Architecture de Déploiement (DEPLOYMENT.md)](docs/DEPLOYMENT.md)
* [Documentation de l'API (API.md)](docs/API.md)
* [Dépannage (TROUBLESHOOTING.md)](docs/TROUBLESHOOTING.md)
* [Guide de Contribution (CONTRIBUTING.md)](docs/CONTRIBUTING.md)

## 🤝 Contributions
Les contributions sont les bienvenues ! Veuillez lire le fichier [CONTRIBUTING.md](docs/CONTRIBUTING.md) pour plus de détails sur notre code de conduite et le processus de soumission des Pull Requests.

## 📄 Licence
Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.
