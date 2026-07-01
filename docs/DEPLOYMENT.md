# 🏗️ Architecture et Stratégie de Déploiement (DEPLOYMENT.md)

Le projet **Student Management** intègre une approche CI/CD moderne permettant des déploiements fluides, sécurisés et automatisés via Kubernetes.

---

## 🔄 Architecture du Pipeline CI/CD

Le pipeline est défini de manière déclarative dans le fichier `Jenkinsfile` à la racine du projet. Voici le déroulement exact à chaque `push` :

1. **Checkout Code** : Récupération du code source depuis Git.
2. **Build (Maven)** : Compilation du code Java 25 (`mvn clean compile`). Timeout : 10 minutes.
3. **Test & Coverage** : Exécution des tests unitaires et génération du rapport de couverture JaCoCo (`mvn test jacoco:report`). Timeout : 15 minutes.
4. **SonarQube Analysis** : Analyse statique du code (Bugs, Vulnérabilités, Code Smells) envoyée au serveur SonarQube.
5. **JaCoCo Quality Gate** : Vérification stricte que la couverture de code est au minimum de **70%**. Si la couverture est insuffisante, le pipeline échoue.
6. **Package (JAR)** : Création de l'exécutable `.jar` via `mvn package -DskipTests`.
7. **Docker Build** : Création de l'image Docker Alpine ultra-légère contenant l'application. Cette étape se fait directement dans le démon Docker de Minikube pour éviter un Push vers un registre externe.
8. **Deploy to Kubernetes (Helm)** : Mise à jour du cluster Kubernetes en utilisant Helm.
9. **Clean Up** : Nettoyage de l'espace de travail Jenkins.
10. **Post (Notifications)** : Envoi d'un email de succès ou d'échec via le plugin `emailext`.

---

## 🌍 Environnements

Le projet est conçu pour évoluer dans plusieurs environnements :

| Environnement | Description | Infrastructure |
|---|---|---|
| **Local / Dev** | Pour le développement quotidien des développeurs. | Machine locale + Vagrant (Docker Compose) |
| **Staging** | Environnement de pré-production testé par la CI. | Minikube (dans la VM Vagrant) via Helm |
| **Production** | Environnement final (cible). | Cluster Kubernetes Cloud (EKS, GKE, AKS) |

---

## 🚀 Stratégie de Déploiement (Kubernetes / Helm)

La stratégie utilisée est le **Rolling Update** (Mise à jour progressive) configurée dans les manifestes Kubernetes.

### Zéro Interruption de Service (Zero-Downtime)
* **maxSurge : 1** : Lors d'une mise à jour, K8s crée 1 Pod supplémentaire avant de détruire les anciens.
* **maxUnavailable : 0** : K8s s'assure qu'il y a toujours 100% de la capacité requise disponible pendant la mise à jour.
* **Probes** : Les `livenessProbe` et `readinessProbe` scrutent l'endpoint `/student/actuator/health`. K8s ne route le trafic vers le nouveau Pod que lorsqu'il répond HTTP 200.

### Rollback Automatique
Dans le `Jenkinsfile`, la commande Helm utilisée est :
```bash
helm upgrade student-management ./helm/student-management --install --atomic --timeout 10m ...
```
> [!IMPORTANT]
> L'argument `--atomic` est crucial. Si le déploiement Kubernetes échoue (ex: CrashLoopBackOff, timeout des probes), Helm annulera automatiquement les changements et restaurera la version précédente (Rollback).

---

## 🔐 Variables d'Environnement

Le comportement de l'application est dirigé par des variables d'environnement injectées par Kubernetes via des `Secrets` et des `ConfigMaps` (issues du `values.yaml` et de Jenkins) :

| Variable | Description |
|---|---|
| `SPRING_PROFILES_ACTIVE` | Définit le profil Spring (ex: `prod`). |
| `SPRING_DATASOURCE_URL` | L'URL JDBC complète vers la base MySQL. |
| `SPRING_DATASOURCE_USERNAME` | Utilisateur de la base de données. |
| `SPRING_DATASOURCE_PASSWORD` | Mot de passe de la base de données (Secret K8s). |
| `APP_SECURITY_USERNAME` | Identifiant pour l'accès aux endpoints Actuator/Prometheus. |
| `APP_SECURITY_PASSWORD` | Mot de passe pour l'accès aux métriques. |

---

## 🛠️ Déploiement Manuel

Si vous devez déployer ou mettre à jour l'application manuellement sans Jenkins, utilisez Helm :

```bash
# Vérifier la validité du chart
$ helm lint ./helm/student-management

# Déployer (en injectant vos propres mots de passe)
$ helm upgrade --install student-management ./helm/student-management \
    --namespace devops-tools --create-namespace \
    --set mysql.password="monSuperPass" \
    --set mysql.rootPassword="rootPass" \
    --set app.security.password="metricsPass" \
    --set grafana.adminPassword="admin"
```
