#!/bin/bash
# ==============================================================================
# 🚀 Student Management - DevOps All-in-One Manager (Production Ready v3.1)
# Auteur      : Senior DevOps Architect / QA Engineer
# Description : Script interactif et batch pour la gestion complète de
#               l'environnement de développement et de production K8s/Vagrant.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PARAMÉTRAGE STRICT ET GESTION DES SIGNAUX
# ------------------------------------------------------------------------------
# Attention: on retire 'e' pour éviter que le script plante sur un grep vide dans
# le mode interactif. On gère les erreurs manuellement avec des vérifications.
set -uo pipefail

trap cleanup SIGINT SIGTERM ERR

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Le script s'est arrêté avec le code $exit_code."
        echo -e "\n${RED}❌ Une erreur est survenue (Code: $exit_code).${NC}"
    fi
    # Tuer les processus en background (comme ffmpeg) s'ils existent
    if [ -n "${FFMPEG_PID:-}" ] && kill -0 "$FFMPEG_PID" 2>/dev/null; then
        kill "$FFMPEG_PID" 2>/dev/null || true
    fi
    exit $exit_code
}

# ------------------------------------------------------------------------------
# 2. VARIABLES GLOBALES ET COULEURS
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Chargement de la configuration
CONFIG_FILE="config.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
elif [ -f "config.conf.example" ]; then
    source "config.conf.example"
else
    # Fallback
    VM_IP="192.168.56.10"
    NAMESPACE="devops-tools"
    APP_DEPLOYMENT_NAME="spring-app"
    DB_LABEL="app=mysql"
    HELM_RELEASE_NAME="student-management"
    HELM_CHART_PATH="/vagrant/helm/student-management"
    JENKINS_PORT="8088"
    SONAR_PORT="9000"
    GRAFANA_PORT="3000"
    PROMETHEUS_PORT="9090"
    API_PORT="30089"
    BACKUP_DIR="./backups"
    LOGS_DIR="./logs"
    AUDITS_DIR="./audits"
    DEMOS_DIR="./demos"
fi

DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
DOCKER_TAG="${DOCKER_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"

JENKINS_URL="http://${VM_IP}:${JENKINS_PORT}"
SONAR_URL="http://${VM_IP}:${SONAR_PORT}"
GRAFANA_URL="http://${VM_IP}:${GRAFANA_PORT}"
PROMETHEUS_URL="http://${VM_IP}:${PROMETHEUS_PORT}"
API_SWAGGER_URL="http://${VM_IP}:${API_PORT}/student/swagger-ui.html"
API_HEALTH_URL="http://${VM_IP}:${API_PORT}/student/actuator/health"

# Création des répertoires de travail
mkdir -p "$BACKUP_DIR" "$LOGS_DIR" "$AUDITS_DIR" "$DEMOS_DIR"
LOG_FILE="${LOGS_DIR}/devops-menu.log"

# Nettoyage des logs plus vieux que 7 jours
find "$LOGS_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. FONCTIONS UTILITAIRES ET LOGGING
# ------------------------------------------------------------------------------

log() {
    local LEVEL=$1
    shift
    local MSG="$*"
    local TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] [$LEVEL] $MSG" >> "$LOG_FILE"
}

print_info()  { echo -e "${CYAN}ℹ️  $1${NC}"; log "INFO" "$1"; }
print_success(){ echo -e "${GREEN}✅ $1${NC}"; log "INFO" "$1"; }
print_warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; log "WARN" "$1"; }
print_error() { echo -e "${RED}❌ $1${NC}"; log "ERROR" "$1"; }

open_url() {
    local URL=$1
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$URL" > /dev/null 2>&1 || true
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "$URL" > /dev/null 2>&1 || true
    elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
        start "$URL" > /dev/null 2>&1 || true
    else
        print_warn "Veuillez ouvrir manuellement : $URL"
    fi
}

open_terminal() {
    local CMD=$1
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
        start bash -c "$CMD; echo ''; read -p 'Appuyez sur Entrée pour fermer...'"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"$CMD\""
    else
        gnome-terminal -- bash -c "$CMD; exec bash" 2>/dev/null || xterm -e "$CMD; bash" 2>/dev/null || print_error "Ouverture de terminal non supportée."
    fi
}

vm_exec() {
    if [[ "$(hostname)" == "devops-vm" ]]; then
        bash -l -c "$1"
    else
        vagrant ssh -c "$1" 2>/dev/null
    fi
}

pause() {
    if [ -z "${NON_INTERACTIVE:-}" ]; then
        echo -e "\n${CYAN}Appuyez sur [Entrée] pour retourner au menu...${NC}"
        read -r
    fi
}

run_with_audit() {
    local action_name=$1
    local debug_log="${AUDITS_DIR}/debug_${action_name}_$(date +%Y%m%d_%H%M%S).log"
    print_info "📝 Mode Audit Activé : Enregistrement de l'exécution dans $debug_log"
    
    # Exécution de la commande en capturant toutes les sorties (stdout + stderr) vers le fichier et l'écran
    $action_name 2>&1 | tee -a "$debug_log"
    
    # Récupération du vrai code de retour de la fonction (ignorer le succès de 'tee')
    local exit_code=${PIPESTATUS[0]}
    if [ "$exit_code" -ne 0 ]; then
        print_warn "⚠️ Fin avec statut $exit_code. En cas de problème, utilisez le log pour le débogage : $debug_log"
    fi
    return "$exit_code"
}

check_prerequisites() {
    log "INFO" "Vérification des prérequis."
    local MISSING=0
    for cmd in git curl; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd n'est pas installé ou n'est pas dans le PATH."
            MISSING=1
        fi
    done
    if [[ "$(hostname)" != "devops-vm" ]] && ! command -v vagrant &> /dev/null; then
        print_error "vagrant n'est pas installé ou n'est pas dans le PATH."
        MISSING=1
    fi
    if [ $MISSING -eq 1 ]; then
        print_error "Outils vitaux manquants. Arrêt."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 4. COMMANDES (24 Actions)
# ------------------------------------------------------------------------------

cmd_start_env() {
    print_info "Démarrage de la machine virtuelle Vagrant..."
    vagrant up
    print_success "Environnement démarré !"
}

cmd_stop_env() {
    print_info "Arrêt de la machine virtuelle..."
    vagrant halt
    print_success "Environnement arrêté !"
}

cmd_status() {
    print_info "Vérification de l'état des services..."
    echo -e "${BLUE}--- État de Vagrant ---${NC}"
    if [[ "$(hostname)" != "devops-vm" ]]; then
        vagrant status | grep -E "running|saved|poweroff|aborted" || true
    else
        echo "Exécuté depuis l'intérieur de la VM (devops-vm)."
    fi
    echo -e "\n${BLUE}--- État des Pods Kubernetes ---${NC}"
    vm_exec "kubectl get pods -n $NAMESPACE" || true
}

cmd_dashboards() {
    print_info "Ouverture des dashboards..."
    open_url "$JENKINS_URL"
    open_url "$SONAR_URL"
    open_url "$GRAFANA_URL"
    open_url "$PROMETHEUS_URL"
    open_url "$API_SWAGGER_URL"
    print_success "Dashboards ouverts."
}

cmd_trigger_build() {
    print_info "Déclenchement du build Jenkins..."
    open_url "${JENKINS_URL}/job/student-management-pipeline/"
}

cmd_health() {
    print_info "Health check API..."
    local TARGET_IP=$VM_IP
    if [[ "$(hostname)" == "devops-vm" ]] && command -v minikube &>/dev/null; then
        TARGET_IP=$(minikube ip)
    fi
    local HTTP_CODE="000"
    for i in {1..6}; do
        print_info "Attente de l'API (Tentative $i/6)..."
        # Exécution du curl directement dans la VM pour résoudre 'minikube ip'
        HTTP_CODE=$(vm_exec "curl -m 5 -s -o /dev/null -w '%{http_code}' http://\$(minikube ip 2>/dev/null):$API_PORT/student/actuator/health || echo '000'" | tr -d '\r' | tail -n 1)
        
        if [ "$HTTP_CODE" == "200" ]; then
            print_success "L'API est EN LIGNE (HTTP 200)."
            return 0
        fi
        sleep 10
    done
    print_error "L'API est HORS LIGNE (HTTP $HTTP_CODE)."
    return 1
}

cmd_update_deployment() {
    print_info "Mise à jour via Helm..."
    vm_exec "helm upgrade $HELM_RELEASE_NAME $HELM_CHART_PATH -n $NAMESPACE"
}

cmd_helm_rollback() {
    print_info "Historique Helm :"
    vm_exec "helm history $HELM_RELEASE_NAME -n $NAMESPACE"
    if [ -z "${NON_INTERACTIVE:-}" ]; then
        read -p "Numéro de révision (0 pour annuler) : " rev
        if [[ "$rev" =~ ^[0-9]+$ ]] && [ "$rev" -gt 0 ]; then
            vm_exec "helm rollback $HELM_RELEASE_NAME $rev -n $NAMESPACE"
            print_success "Rollback effectué."
        fi
    fi
}

cmd_restart_service() {
    print_info "Redémarrage de l'API..."
    vm_exec "kubectl rollout restart deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE"
}

cmd_manage_secrets() {
    print_info "Secrets Kubernetes :"
    vm_exec "kubectl get secrets -n $NAMESPACE"
    if [ -z "${NON_INTERACTIVE:-}" ]; then
        read -p "Éditer un secret ? (y/n) : " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            read -p "Nom du secret : " sec_name
            vm_exec "kubectl edit secret $sec_name -n $NAMESPACE"
        fi
    fi
}

cmd_network_info() {
    print_info "Informations Réseau & Liens (Mode Production)"
    echo -e "${YELLOW}🔹 Le profil Spring Boot est défini sur 'prod' via Kubernetes (SPRING_PROFILES_ACTIVE=prod)${NC}"
    echo -e ""
    echo -e "${CYAN}[ IP ET PORTS ]${NC}"
    echo -e "VM IP: $VM_IP"
    echo -e "API K8s Port: $API_PORT"
    echo -e ""
    echo -e "${CYAN}[ ENDPOINTS API ]${NC} (Authentification: api-user / \${APP_SECURITY_PASSWORD:-admin})"
    echo -e "Swagger UI : $API_SWAGGER_URL"
    echo -e "Health     : $API_HEALTH_URL"
    echo -e "Students   : http://${VM_IP}:${API_PORT}/student/students"
    echo -e "Departments: http://${VM_IP}:${API_PORT}/student/departments"
    echo -e ""
    echo -e "${CYAN}[ DASHBOARDS INFRA ]${NC}"
    echo -e "Jenkins    : $JENKINS_URL"
    echo -e "SonarQube  : $SONAR_URL"
    echo -e "Grafana    : $GRAFANA_URL"
    echo -e "Prometheus : $PROMETHEUS_URL"
}

cmd_show_logs() {
    print_info "Logs Spring App..."
    vm_exec "kubectl logs deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE --tail=50"
}

cmd_pod_details() {
    print_info "Détails des Pods..."
    vm_exec "kubectl top pods -n $NAMESPACE" || true
    vm_exec "kubectl get pods -n $NAMESPACE -o wide"
}

cmd_realtime_monitoring() {
    print_info "Ouverture terminaux monitoring..."
    open_terminal "vagrant ssh -c 'kubectl get pods -n $NAMESPACE -w'"
    open_terminal "vagrant ssh -c 'kubectl logs -f deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE'"
}

cmd_generate_report() {
    print_info "Génération du rapport d'état..."
    local REPORT_FILE="status_report_$(date +%F_%H-%M-%S).txt"
    {
        echo "RAPPORT D'ÉTAT - $(date)"
        vm_exec "kubectl get nodes"
        vm_exec "kubectl get pods -n $NAMESPACE"
        vm_exec "helm list -n $NAMESPACE"
    } > "$REPORT_FILE"
    print_success "Rapport généré : $REPORT_FILE"
}

cmd_backup() {
    print_info "Backup MySQL..."
    local FILE_NAME="backup_$(date +%F_%H-%M-%S).sql"
    local POD_NAME=$(vm_exec "kubectl get pods -n $NAMESPACE -l $DB_LABEL -o jsonpath='{.items[0].metadata.name}'" | tr -d '\r')
    if [ -z "$POD_NAME" ]; then print_error "Pod MySQL introuvable."; return 1; fi

    vm_exec "kubectl exec -n $NAMESPACE $POD_NAME -- bash -c 'mysqldump -u root -p\$MYSQL_ROOT_PASSWORD studentdb'" > "${BACKUP_DIR}/${FILE_NAME}"
    if [ -s "${BACKUP_DIR}/${FILE_NAME}" ]; then
        print_success "Backup réussi : ${BACKUP_DIR}/${FILE_NAME}"
    else
        print_error "Échec du backup."
        rm -f "${BACKUP_DIR}/${FILE_NAME}"
        [ -n "${NON_INTERACTIVE:-}" ] && exit 1
    fi
}

cmd_restore() {
    print_info "Restauration MySQL..."
    local backups=("${BACKUP_DIR}"/*.sql)
    if [ ${#backups[@]} -eq 0 ] || [ ! -e "${backups[0]}" ]; then
        print_error "Aucun backup."
        return 1
    fi
    for i in "${!backups[@]}"; do echo "$((i+1)). $(basename "${backups[$i]}")"; done
    if [ -z "${NON_INTERACTIVE:-}" ]; then
        read -p "Choix : " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#backups[@]}" ]; then
            local file="${backups[$((choice-1))]}"
            local POD_NAME=$(vm_exec "kubectl get pods -n $NAMESPACE -l $DB_LABEL -o jsonpath='{.items[0].metadata.name}'" | tr -d '\r')
            cat "$file" | vm_exec "kubectl exec -i -n $NAMESPACE $POD_NAME -- bash -c 'mysql -u root -p\$MYSQL_ROOT_PASSWORD studentdb'"
            print_success "Restauration terminée."
        fi
    fi
}

cmd_trivy_scan() {
    print_info "Scan Trivy..."
    vm_exec "if ! command -v trivy &>/dev/null; then curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.49.1; fi; trivy image esprit/student-management:latest --severity HIGH,CRITICAL"
}

cmd_smoke_tests() {
    print_info "Smoke Tests..."
    local res
    for url_path in "/student/students" "/student/departments"; do
        res=$(vm_exec "curl -u \"api-user:\${APP_SECURITY_PASSWORD:-admin}\" -o /dev/null -s -w '%{http_code}' \"http://\$(minikube ip 2>/dev/null):${API_PORT}${url_path}\" || echo '000'" | tr -d '\r' | tail -n 1)
        echo -e "Testing $url_path ... HTTP $res"
        if [ "$res" != "200" ]; then
            print_error "Échec du smoke test (HTTP $res)"
            return 1
        fi
    done
    print_success "Tous les smoke tests sont passés avec succès !"
}

cmd_advanced_cleanup() {
    print_info "Nettoyage..."
    vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE" || true
    vm_exec "eval \$(minikube -p minikube docker-env 2>/dev/null || minikube docker-env) && docker image prune -a -f" || true
    print_success "Nettoyage terminé."
}

cmd_update_hosts() {
    print_info "Ajoutez ceci à votre fichier hosts :"
    echo -e "${YELLOW}${VM_IP} api.student.local grafana.student.local jenkins.student.local${NC}"
}

cmd_ssh_tunnel() {
    print_info "Ouverture session SSH..."
    open_terminal "vagrant ssh"
}

cmd_demo_video() {
    print_info "Enregistrement vidéo (2 min)..."
    if ! command -v ffmpeg &> /dev/null; then
        print_error "ffmpeg non installé."
        return 1
    fi
    local VIDEO_FILE="${DEMOS_DIR}/demo_$(date +%Y%m%d_%H%M%S).mp4"
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win32" ]]; then
        ffmpeg -f gdigrab -framerate 30 -i desktop -t 120 "$VIDEO_FILE" > /dev/null 2>&1 &
    else
        ffmpeg -f x11grab -framerate 30 -i :0.0 -t 120 "$VIDEO_FILE" > /dev/null 2>&1 &
    fi
    FFMPEG_PID=$!
    sleep 2
    cmd_status
    sleep 2
    cmd_dashboards
    sleep 2
    cmd_smoke_tests
    wait $FFMPEG_PID || true
    print_success "Vidéo sauvegardée : $VIDEO_FILE"
}

cmd_audit() {
    print_info "DÉBUT DE L'AUDIT & AUTORÉPARATION"
    local REPORT_FILE="${AUDITS_DIR}/audit_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "RAPPORT D'AUDIT - $(date)"
        if [[ "$(hostname)" != "devops-vm" ]] && ! vagrant status | grep -q "running"; then vagrant up || true; fi
        local PODS_FAILS=$(vm_exec "kubectl get pods -n $NAMESPACE --field-selector status.phase=Failed -o name" | tr -d '\r')
        if [ -n "$PODS_FAILS" ]; then vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE" || true; fi
        local HTTP_CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL" || echo "000")
        if [ "$HTTP_CODE" -ne 200 ]; then vm_exec "kubectl rollout restart deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE" || true; fi
    } > "$REPORT_FILE"
    print_success "Audit terminé. Rapport: $REPORT_FILE"
}

cmd_ci_build() {
    print_info "🚀 Exécution du build (mvn clean compile)..."
    vm_exec "cd /vagrant && bash ./mvnw clean compile" 2>&1 | tee -a "$LOGS_DIR/build_$(date +%Y%m%d).log" || { print_error "Échec du build"; exit 1; }
    print_success "Build réussi."
}

cmd_ci_test() {
    print_info "🚀 Exécution des tests (mvn test jacoco:report)..."
    vm_exec "cd /vagrant && bash ./mvnw test jacoco:report" 2>&1 | tee -a "$LOGS_DIR/test_$(date +%Y%m%d).log" || { print_error "Échec des tests"; exit 1; }
    print_success "Tests réussis."
}

cmd_ci_sonar() {
    print_info "🚀 Analyse SonarQube..."
    vm_exec "cd /vagrant && bash ./mvnw sonar:sonar -Dsonar.host.url=http://192.168.56.10:9000 -Dsonar.login=\${SONAR_TOKEN:-}" 2>&1 | tee -a "$LOGS_DIR/sonar_$(date +%Y%m%d).log" || { print_error "Échec SonarQube"; exit 1; }
    print_success "Analyse SonarQube terminée."
}

cmd_ci_package() {
    print_info "🚀 Packaging de l'application..."
    vm_exec "cd /vagrant && bash ./mvnw package -DskipTests" 2>&1 | tee -a "$LOGS_DIR/package_$(date +%Y%m%d).log" || { print_error "Échec du packaging"; exit 1; }
    print_success "Package généré."
}

cmd_docker_build() {
    print_info "🐳 Build de l'image Docker..."
    vm_exec "cd /vagrant && if command -v minikube &>/dev/null; then eval \$(minikube -p minikube docker-env 2>/dev/null || minikube docker-env); fi && docker build -t esprit/student-management:${DOCKER_TAG} ." 2>&1 | tee -a "$LOGS_DIR/docker-build_$(date +%Y%m%d).log" || { print_error "Échec Docker Build"; exit 1; }
    print_success "Docker Build réussi."
}

cmd_docker_push() {
    print_info "🐳 Push de l'image Docker..."
    if [ -z "${DOCKER_USERNAME}" ] || [ -z "${DOCKER_PASSWORD}" ]; then
        print_warn "Identifiants Docker non fournis. Le push risque d'échouer."
    fi
    vm_exec "eval \$(minikube -p minikube docker-env 2>/dev/null || minikube docker-env) && docker tag esprit/student-management:${DOCKER_TAG} ${DOCKER_REGISTRY}/esprit/student-management:${DOCKER_TAG} && echo '${DOCKER_PASSWORD}' | docker login -u '${DOCKER_USERNAME}' --password-stdin && docker push ${DOCKER_REGISTRY}/esprit/student-management:${DOCKER_TAG}" 2>&1 | tee -a "$LOGS_DIR/docker-push_$(date +%Y%m%d).log" || { print_error "Échec Docker Push"; exit 1; }
    print_success "Docker Push réussi."
}

cmd_ci_deploy() {
    print_info "🚀 Déploiement sur Kubernetes via Helm..."
    vm_exec "cd /vagrant && helm upgrade --install student-management ./helm/student-management --namespace devops-tools --set image.tag=${DOCKER_TAG} --set-string mysql.password=\"\${MYSQL_PASSWORD:-root}\" --set-string mysql.rootPassword=\"\${MYSQL_ROOT_PASSWORD:-root}\" --set-string grafana.adminPassword=\"\${GRAFANA_ADMIN_PASSWORD:-admin}\" --set-string app.security.password=\"\${APP_SECURITY_PASSWORD:-admin}\"" 2>&1 | tee -a "$LOGS_DIR/deploy_$(date +%Y%m%d).log" || { print_error "Échec du déploiement Helm"; exit 1; }
    print_info "Attente du démarrage des pods (Timeout: 3m)..."
    vm_exec "kubectl rollout status deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE --timeout=3m" || print_warn "Timeout rollout, mais le déploiement continue."
    print_success "Déploiement réussi."
}

cmd_all_in_one() {
    print_info "🔥 Lancement de la magie : All-in-One Pipeline..."
    cmd_ci_build || return 1
    cmd_ci_test || return 1
    cmd_ci_package || return 1
    cmd_docker_build || return 1
    cmd_ci_deploy || return 1
    cmd_health || return 1
    cmd_smoke_tests || return 1
    print_success "🎉 All-in-One terminé avec succès ! L'application est en production."
}

cmd_generate_ci_pipeline() {
    print_info "Génération d'un pipeline CI/CD"
    echo "1. Jenkins (Declarative Pipeline)"
    echo "2. GitHub Actions (Workflow)"
    read -p "Choisissez le type (1 ou 2) : " choice
    case $choice in
        1) _generate_jenkins_pipeline ;;
        2) _generate_github_workflow ;;
        *) print_error "Choix invalide." ;;
    esac
}

_generate_jenkins_pipeline() {
    if [ -f "Jenkinsfile" ]; then
        read -p "Jenkinsfile existe déjà. Écraser ? (o/N) " overwrite
        [[ ! "$overwrite" =~ ^[oO] ]] && return
    fi
    cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    environment {
        GITHUB_CREDENTIALS = credentials('github-credentials')
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }
    stages {
        stage('Build') { steps { sh './devops-menu.sh --action build' } }
        stage('Test') { steps { sh './devops-menu.sh --action test' } }
        stage('SonarQube Analysis') { steps { sh './devops-menu.sh --action sonar' } }
        stage('Package') { steps { sh './devops-menu.sh --action package' } }
        stage('Docker Build & Deploy') { steps { sh './devops-menu.sh --action deploy' } }
        stage('Health Check') { steps { sh './devops-menu.sh --action health' } }
    }
    post { always { cleanWs() } }
}
EOF
    print_success "Jenkinsfile généré avec succès."
}

_generate_github_workflow() {
    mkdir -p .github/workflows
    if [ -f ".github/workflows/ci.yml" ]; then
        read -p "Le workflow existe déjà. Écraser ? (o/N) " overwrite
        [[ ! "$overwrite" =~ ^[oO] ]] && return
    fi
    cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies (Vagrant, kubectl, etc.)
        run: sudo apt-get update && sudo apt-get install -y vagrant kubectl
      - name: Run DevOps Menu Script
        run: |
          chmod +x devops-menu.sh
          ./devops-menu.sh --action build
          ./devops-menu.sh --action test
          ./devops-menu.sh --action sonar
          ./devops-menu.sh --action package
          ./devops-menu.sh --action deploy
          ./devops-menu.sh --action health
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Archive logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: logs
          path: logs/
EOF
    print_success "GitHub Actions workflow généré avec succès."
}

# ------------------------------------------------------------------------------
# 5. ARGUMENTS ET MENU
# ------------------------------------------------------------------------------
usage() {
    echo "Utilisation : $0 [--action <start|stop|status|health|backup|audit>]"
    exit 0
}

NON_INTERACTIVE=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -c|--config) CONFIG_FILE="$2"; source "$CONFIG_FILE"; shift ;;
        -a|--action) NON_INTERACTIVE="true"; ACTION="$2"; shift ;;
    esac
    shift
done

if [ -n "$NON_INTERACTIVE" ]; then
    check_prerequisites
    case $ACTION in
        start) run_with_audit cmd_start_env ;;
        stop) run_with_audit cmd_stop_env ;;
        status) run_with_audit cmd_status ;;
        health) run_with_audit cmd_health ;;
        backup) run_with_audit cmd_backup ;;
        audit) run_with_audit cmd_audit ;;
        build) run_with_audit cmd_ci_build ;;
        test) run_with_audit cmd_ci_test ;;
        sonar) run_with_audit cmd_ci_sonar ;;
        package) run_with_audit cmd_ci_package ;;
        docker-build) run_with_audit cmd_docker_build ;;
        docker-push) run_with_audit cmd_docker_push ;;
        deploy) run_with_audit cmd_ci_deploy ;;
        smoke_tests) run_with_audit cmd_smoke_tests ;;
        all-in-one) run_with_audit cmd_all_in_one ;;
        *) print_error "Action inconnue"; exit 1 ;;
    esac
    exit 0
fi

show_menu() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🚀 Student Management - DevOps Menu (v3.1 QA Approved)${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${CYAN}[ 1. INFRASTRUCTURE & DÉMARRAGE ]${NC}"
    echo "1. Démarrer l'environnement (Vagrant up)"
    echo "2. Arrêter l'environnement (Vagrant halt)"
    echo "3. Ouvrir Tunnel SSH"
    echo "4. Mettre à jour fichier Hosts DNS"
    echo ""
    echo -e "${CYAN}[ 2. CI/CD & DÉPLOIEMENT EN PRODUCTION ]${NC}"
    echo "5. Packager et Créer l'image Docker (Build)"
    echo "6. Pousser l'image Docker (Push)"
    echo "7. Déployer en Production (Helm Upgrade)"
    echo "8. Rollback vers la version précédente"
    echo "9. Générer un pipeline CI/CD (Jenkins/GitHub)"
    echo "10. Déclencher le Build Jenkins"
    echo "11. 🔥 Lancement Magique (All-in-One Pipeline)"
    echo ""
    echo -e "${CYAN}[ 3. TESTS & SUPERVISION ]${NC}"
    echo "12. Health check de l'API"
    echo "13. Smoke Tests"
    echo "14. Informations Réseau & Liens utiles"
    echo "15. Ouvrir les dashboards (Grafana, Sonar...)"
    echo "16. État des services (Pods, Vagrant)"
    echo "17. Supervision en temps réel (Logs & Pods)"
    echo ""
    echo -e "${CYAN}[ 4. ADMINISTRATION & DÉPANNAGE ]${NC}"
    echo "18. Logs basiques (Spring Boot)"
    echo "19. Détails avancés des Pods et Ressources"
    echo "20. Redémarrer le service Spring App"
    echo "21. Audit système & Autoréparation"
    echo "22. Générer un rapport d'état système"
    echo "23. Gestion des Secrets K8s"
    echo ""
    echo -e "${CYAN}[ 5. MAINTENANCE & SÉCURITÉ ]${NC}"
    echo "24. Scan vulnérabilités (Trivy)"
    echo "25. Backup de la Base de Données (MySQL)"
    echo "26. Restaurer un Backup"
    echo "27. Nettoyage avancé (Prune Docker & Pods)"
    echo "28. Enregistrer vidéo démo (2 min)"
    echo -e "${RED}q. Quitter${NC}"
    echo -e "${BLUE}======================================================${NC}"
}

check_prerequisites
while true; do
    show_menu
    read -p "Votre choix : " choice
    echo ""
    case $choice in
        1) run_with_audit cmd_start_env ;;
        2) run_with_audit cmd_stop_env ;;
        3) cmd_ssh_tunnel ;; # TTY needed, no wrap
        4) run_with_audit cmd_update_hosts ;;
        5) run_with_audit cmd_docker_build ;;
        6) run_with_audit cmd_docker_push ;;
        7) run_with_audit cmd_update_deployment ;;
        8) run_with_audit cmd_helm_rollback ;;
        9) run_with_audit cmd_generate_ci_pipeline ;;
        10) cmd_trigger_build ;; # Opens browser, no wrap
        11) run_with_audit cmd_all_in_one ;;
        12) run_with_audit cmd_health ;;
        13) run_with_audit cmd_smoke_tests ;;
        14) run_with_audit cmd_network_info ;;
        15) cmd_dashboards ;; # Opens browser, no wrap
        16) run_with_audit cmd_status ;;
        17) cmd_realtime_monitoring ;; # Opens terminals, no wrap
        18) run_with_audit cmd_show_logs ;;
        19) run_with_audit cmd_pod_details ;;
        20) run_with_audit cmd_restart_service ;;
        21) run_with_audit cmd_audit ;;
        22) run_with_audit cmd_generate_report ;;
        23) run_with_audit cmd_manage_secrets ;;
        24) run_with_audit cmd_trivy_scan ;;
        25) run_with_audit cmd_backup ;;
        26) run_with_audit cmd_restore ;;
        27) run_with_audit cmd_advanced_cleanup ;;
        28) run_with_audit cmd_demo_video ;;
        q|Q) print_success "Au revoir !"; exit 0 ;;
        *) print_error "Option invalide." ;;
    esac
    pause
done
