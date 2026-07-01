# 🚀 Guide d'Installation (INSTALL.md)

Ce guide détaille les étapes pour mettre en place l'environnement complet du projet **Student Management** sur votre machine locale.

## 📋 Prérequis détaillés
Assurez-vous de disposer des logiciels suivants sur votre machine hôte :
- **VirtualBox** : Version 7.0+ (Nécessaire pour exécuter la machine virtuelle).
- **Vagrant** : Version 2.3+ (Pour orchestrer le déploiement de la VM).
- **Git** : Pour cloner le dépôt.
- **Ressources matérielles** :
  - **RAM** : 8 Go (Strict minimum) - 16 Go recommandés.
  - **CPU** : 4 Cœurs.
  - **Espace disque** : ~20 Go libres.

> [!WARNING]
> Sous Windows, assurez-vous que la virtualisation matérielle (VT-x / AMD-V) est activée dans le BIOS. Si vous utilisez WSL2 ou Hyper-V, il peut y avoir des conflits avec VirtualBox. Il est conseillé de désactiver Hyper-V si VirtualBox refuse de lancer la VM.

---

## 🛠️ Étape 1 : Cloner le dépôt

Ouvrez un terminal et exécutez la commande suivante :
```bash
$ git clone https://github.com/votre-org/student-management.git
$ cd student-management
```

---

## ⚙️ Étape 2 : Lancer l'environnement Vagrant

L'ensemble de l'infrastructure est défini comme code (Infrastructure as Code) via le `Vagrantfile`.

```bash
$ vagrant up
```

> [!NOTE]
> **Provisionnement de la VM**
> Lors du premier lancement, Vagrant va télécharger l'image Ubuntu, installer Docker, Minikube, Helm, Jenkins et tous les outils DevOps. Cette opération est lourde et peut prendre **entre 15 et 30 minutes** selon votre connexion internet. Soyez patient !

Une fois terminé, vous pouvez vous connecter à la machine virtuelle :
```bash
$ vagrant ssh
```

---

## 🌐 Étape 3 : Accéder aux Services

La machine virtuelle est accessible depuis votre hôte Windows/Mac via l'IP privée `192.168.56.10` ou via les redirections de ports (Port Forwarding).

| Service | URL / Port | Identifiants par défaut |
|---|---|---|
| **Jenkins** | [http://192.168.56.10:8088](http://192.168.56.10:8088) ou `localhost:8088` | (Voir `docker/secrets/jenkinsAdminPassword`) |
| **SonarQube** | [http://192.168.56.10:9000](http://192.168.56.10:9000) | `admin` / `admin` (Change à la 1ère connexion) |
| **Grafana** | [http://192.168.56.10:3000](http://192.168.56.10:3000) | `admin` / `admin` |
| **Prometheus** | [http://192.168.56.10:9090](http://192.168.56.10:9090) | (Pas d'authentification) |
| **API (NodePort)** | [http://192.168.56.10:30089/student/swagger-ui.html](http://192.168.56.10:30089/student/swagger-ui.html) | Dépend de la conf |

---

## 💻 Étape 4 : Lancement en mode développement local (Optionnel)

Si vous êtes développeur et que vous souhaitez tester l'application Java sans Kubernetes, vous pouvez utiliser Docker Compose ou Maven directement depuis la racine du projet (sur votre machine hôte si vous avez Java installé, ou dans la VM).

**Avec Docker Compose :**
```bash
$ docker compose -f docker/docker-compose.yml up -d
```
Cela lancera la BDD MySQL, l'application Spring Boot, et la supervision.

**Avec Maven (nécessite Java 25) :**
Assurez-vous qu'une base MySQL tourne sur le port `3306`, puis :
```bash
$ ./mvnw spring-boot:run
```

---

## 🚑 Dépannage rapide

* **Port déjà utilisé** : Si `vagrant up` échoue avec une erreur de port (ex: 8080), modifiez le `Vagrantfile` pour changer le port hôte (ex: `host: 8089`).
* **La VM fige ou est très lente** : Arrêtez la VM (`vagrant halt`), ouvrez VirtualBox, et augmentez la RAM allouée (ex: 6144 Mo) et les processeurs, puis relancez (`vagrant up`).
* **Minikube n'est pas prêt** : Dans la VM, vérifiez le statut avec `minikube status`. S'il est arrêté, tapez `minikube start`.

Pour des problèmes plus complexes (Kubernetes, Jenkins, CI/CD), référez-vous au fichier [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
