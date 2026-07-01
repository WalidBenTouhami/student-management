# 🚀 Student Management - DevOps All-in-One Manager

Le script `devops-menu.sh` a été conçu pour simplifier et automatiser la gestion quotidienne de l'infrastructure Vagrant et Kubernetes du projet **Student Management**.

## 🌟 Fonctionnalités (v3.0 - Production Ready)

- **Gestion Interactive & Batch** : Utilisable via un menu interactif coloré ou intégré dans un pipeline CI/CD via des arguments en ligne de commande.
- **Robustesse & Logs** : Mode `set -eo pipefail`, capture des signaux via `trap`, et centralisation de tous les événements dans `./logs/devops-menu.log`.
- **Modularité** : Toute la configuration (IPs, Ports, Namespaces) a été extraite dans `config.conf`.
- **Exécution Parallèle** : L'état des services Kubernetes et Vagrant est récupéré en parallèle pour une exécution ultra-rapide.
- **Audit & Autoréparation** : Capacité intégrée à détecter les pods en erreur et à redémarrer les services si l'API est indisponible.
- **Sécurité** : Injection sécurisée des variables Kubernetes (les mots de passe BDD ne sont ni loggés ni écrits en clair).

## 🛠️ Installation

1. Assurez-vous d'avoir les prérequis installés (`vagrant`, `git`, `curl`, `jq`).
2. Rendez le script exécutable (Linux/Mac/Git Bash) :
   ```bash
   chmod +x devops-menu.sh
   ```
3. (Optionnel) Copiez le fichier de configuration exemple :
   ```bash
   cp config.conf.example config.conf
   ```
   Vous pouvez ensuite modifier `config.conf` pour l'adapter à vos besoins (changement de port ou d'IP).

## 💻 Utilisation Interactive (Menu)

Lancez simplement le script sans argument pour afficher le menu complet :
```bash
./devops-menu.sh
```

## 🤖 Utilisation Non-Interactive (Mode CI/CD)

Idéal pour vos pipelines Jenkins ou GitHub Actions. Le script retourne un code de sortie explicite (0 ou 1) selon la réussite de la tâche.

**Options disponibles :**
- `-h, --help` : Affiche l'aide
- `-c, --config <file>` : Utiliser un fichier de configuration spécifique
- `-a, --action <action>` : Déclencher une action spécifique silencieusement

**Actions supportées :**
- `start` : Démarrage de la VM Vagrant
- `stop` : Arrêt Vagrant
- `status` : Affiche le statut global (Vagrant + K8s)
- `health` : Curl HTTP sur le l'Actuator de l'API Spring Boot
- `backup` : Dump MySQL dynamique dans `/backups`
- `audit` : Lance l'autoréparation (nettoyage pods failed, redémarrage K8s)

**Exemple dans un script Jenkins :**
```bash
# Vérifier la santé de l'API
./devops-menu.sh --action health

# Lancer un backup et générer un audit
./devops-menu.sh --action backup
./devops-menu.sh --action audit
```

## 📁 Structure des fichiers générés

Le script crée et gère automatiquement les répertoires suivants :
- `./logs/` : Fichiers de trace du script (rotation à 7 jours).
- `./audits/` : Rapports textuels générés par l'option d'Audit.
- `./backups/` : Fichiers `.sql` extraits depuis le pod MySQL.
- `./demos/` : Vidéos capturées (si la fonction est activée).
