# 🚑 Guide de Dépannage (TROUBLESHOOTING.md)

Ce document répertorie les problèmes courants rencontrés lors de l'installation ou du déploiement de l'application **Student Management**, ainsi que leurs solutions.

---

## 1. 🔍 La règle d'Or : Consulter les Logs d'Audit
**Symptômes** : Une option du menu `devops-menu.sh` a échoué silencieusement ou affiche une erreur générique avec un statut non-nul.
**Solutions** :
* Grâce à la fonction de sécurité `run_with_audit`, **toute exécution de commande est sauvegardée**.
* Si une erreur survient, le script affichera le chemin du fichier (ex: `audits/debug_cmd_ci_deploy_20260702_120000.log`).
* Ouvrez ce fichier pour lire la cause exacte de l'échec (souvent liée à un problème réseau, un timeout Docker ou un crash de pod). C'est votre premier réflexe de réparation !

## 2. Problème : La VM Vagrant ne démarre pas ou fige
**Symptômes** : La commande `vagrant up` reste bloquée indéfiniment ou renvoie une erreur VirtualBox (ex: `VT-x is not enabled`).
**Solutions** :
* **Virtualisation matérielle** : Allez dans le BIOS/UEFI de votre ordinateur physique et assurez-vous que `VT-x` (Intel) ou `AMD-V` (AMD) est activé.
* **Conflit Hyper-V (Windows)** : Si vous êtes sous Windows, Hyper-V peut bloquer VirtualBox. Désactivez-le via PowerShell en Administrateur : `Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All` puis redémarrez.
* **Manque de RAM** : Si la VM fige pendant le lancement de Jenkins ou Minikube, ouvrez VirtualBox, modifiez la configuration de la VM `devops-vm` pour lui allouer au moins **6144 Mo** de RAM.

## 2. Problème : Le pod Kubernetes ne démarre pas (CrashLoopBackOff)
**Symptômes** : L'application Spring Boot reste en statut `CrashLoopBackOff` ou `Error` dans Kubernetes.
**Solutions** :
* **Voir les logs** :
  ```bash
  $ kubectl logs -f deployment/spring-app -n devops-tools
  ```
* **Base de données indisponible** : Vérifiez que le pod MySQL est bien `Running`. L'application Java plantera si elle ne peut pas se connecter à la base MySQL.
* **Vérifier les Probes (Liveness/Readiness)** : Si Spring Boot met trop de temps à démarrer, la `livenessProbe` peut tuer le conteneur prématurément. Kubelet affichera cela dans les événements :
  ```bash
  $ kubectl describe pod -l app=spring-app -n devops-tools
  ```
  *Solution* : Augmenter l'`initialDelaySeconds` ou le `failureThreshold` de la `startupProbe` dans `values.yaml`.

## 3. Problème : Jenkins ne répond pas
**Symptômes** : Impossible d'accéder à `http://192.168.56.10:8088`.
**Solutions** :
* **Port bloqué** : Assurez-vous qu'aucune autre application locale (comme un Tomcat) n'utilise le port 8088 de votre machine hôte.
* **Vérifier le conteneur Jenkins** : Dans la VM, tapez :
  ```bash
  $ docker ps | grep jenkins
  $ docker logs <container_id>
  ```
* **Mot de passe initial** : S'il vous demande un mot de passe d'administration, récupérez-le avec :
  ```bash
  $ docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
  ```

## 4. Problème : L'API renvoie une Erreur 500
**Symptômes** : Les requêtes HTTP renvoient une erreur serveur interne.
**Solutions** :
* Les erreurs 500 proviennent souvent d'une erreur Hibernate/JPA.
* Regardez les logs du pod Spring Boot (`kubectl logs`).
* Vérifiez que le mot de passe de la DB configuré dans les `Secrets` Kubernetes (via Helm) correspond bien au mot de passe du serveur MySQL.

## 5. Problème : SonarQube ne reçoit pas les rapports (Quality Gate en attente)
**Symptômes** : Le pipeline Jenkins réussit, mais SonarQube n'affiche aucune couverture de code.
**Solutions** :
* **Token Invalide** : Vérifiez que le `SONAR_TOKEN` défini dans les *Credentials* de Jenkins est bien valide pour le projet.
* **Rapport JaCoCo** : Assurez-vous que l'étape `mvn test jacoco:report` génère bien le fichier `target/site/jacoco/jacoco.xml`. Si les tests échouent, le fichier n'est pas généré.

## 6. Problème : Les métriques Prometheus ne sont pas visibles dans Grafana
**Symptômes** : Les dashboards Grafana affichent "No Data".
**Solutions** :
* **Configuration du Scraping** : Vérifiez que Prometheus arrive bien à joindre l'application. Dans l'interface web de Prometheus (`http://192.168.56.10:9090`), allez dans **Status > Targets**. L'endpoint `spring-app` doit être en vert (`UP`).
* S'il est rouge, vérifiez que l'`APP_SECURITY_USERNAME` et `PASSWORD` définis dans `prometheus.yml` (Basic Auth) correspondent bien à ceux de l'application Java.
