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
    if [ -n "${FFMPEG_PID:-}" ] && kill -0 $FFMPEG_PID 2>/dev/null; then
        kill $FFMPEG_PID 2>/dev/null || true
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
    DB_DEPLOYMENT_NAME="mysql-deployment"
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
    vagrant ssh -c "$1" 2>/dev/null
}

pause() {
    if [ -z "${NON_INTERACTIVE:-}" ]; then
        echo -e "\n${CYAN}Appuyez sur [Entrée] pour retourner au menu...${NC}"
        read -r
    fi
}

check_prerequisites() {
    log "INFO" "Vérification des prérequis."
    local MISSING=0
    for cmd in vagrant git curl; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd n'est pas installé ou n'est pas dans le PATH."
            MISSING=1
        fi
    done
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
    vagrant status | grep -E "running|saved|poweroff|aborted" || true
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
    local HTTP_CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL" || echo "000")
    if [ "$HTTP_CODE" -eq 200 ]; then
        print_success "L'API est EN LIGNE (HTTP 200)."
    else
        print_error "L'API est HORS LIGNE (HTTP $HTTP_CODE)."
        [ -n "${NON_INTERACTIVE:-}" ] && exit 1
    fi
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
    print_info "Informations Réseau"
    echo -e "IP VM: $VM_IP"
    echo -e "API K8s Port: $API_PORT"
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
    local backups=(${BACKUP_DIR}/*.sql)
    if [ ${#backups[@]} -eq 0 ] || [ ! -e "${backups[0]}" ]; then
        print_error "Aucun backup."
        return 1
    fi
    for i in "${!backups[@]}"; do echo "$((i+1)). $(basename "${backups[$i]")"; done
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
    for url in "http://${VM_IP}:${API_PORT}/student/students" "http://${VM_IP}:${API_PORT}/student/departments"; do
        local res=$(curl -o /dev/null -s -w "%{http_code}\n" "$url")
        echo -e "Testing $url ... HTTP $res"
    done
}

cmd_advanced_cleanup() {
    print_info "Nettoyage..."
    vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE" || true
    vm_exec "eval \$(minikube docker-env) && docker image prune -a -f" || true
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
        if ! vagrant status | grep -q "running"; then vagrant up || true; fi
        local PODS_FAILS=$(vm_exec "kubectl get pods -n $NAMESPACE --field-selector status.phase=Failed -o name" | tr -d '\r')
        if [ -n "$PODS_FAILS" ]; then vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE" || true; fi
        local HTTP_CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL" || echo "000")
        if [ "$HTTP_CODE" -ne 200 ]; then vm_exec "kubectl rollout restart deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE" || true; fi
    } > "$REPORT_FILE"
    print_success "Audit terminé. Rapport: $REPORT_FILE"
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
        start) cmd_start_env ;;
        stop) cmd_stop_env ;;
        status) cmd_status ;;
        health) cmd_health ;;
        backup) cmd_backup ;;
        audit) cmd_audit ;;
        *) print_error "Action inconnue"; exit 1 ;;
    esac
    exit 0
fi

show_menu() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🚀 Student Management - DevOps Menu (v3.1 QA Approved)${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${CYAN}[ OPÉRATIONS DE BASE ]${NC}"
    echo "1. Démarrer l'environnement"
    echo "2. Arrêter l'environnement"
    echo "3. État des services"
    echo "4. Ouvrir les dashboards"
    echo "5. Déclencher Build Jenkins"
    echo "6. Health check API"
    echo -e "${CYAN}[ DÉPLOIEMENT & INFRA ]${NC}"
    echo "7. Mettre à jour le déploiement (Helm Upgrade)"
    echo "8. Rollback Helm"
    echo "9. Redémarrer le service Spring App"
    echo "10. Gestion des Secrets K8s"
    echo "11. Informations réseau"
    echo -e "${CYAN}[ SUPERVISION & LOGS ]${NC}"
    echo "12. Logs basiques (Spring Boot)"
    echo "13. Détails des Pods et Ressources"
    echo "14. Supervision en temps réel"
    echo "15. Générer un rapport d'état système"
    echo -e "${CYAN}[ MAINTENANCE & SÉCURITÉ ]${NC}"
    echo "16. Backup de la BDD (MySQL)"
    echo "17. Restaurer un Backup"
    echo "18. Scan vulnérabilités (Trivy)"
    echo "19. Smoke Tests"
    echo "20. Nettoyage avancé"
    echo "21. Mettre à jour fichier Hosts DNS"
    echo "22. Ouvrir Tunnel SSH"
    echo -e "${CYAN}[ DÉMO & AUDIT ]${NC}"
    echo "23. Enregistrer vidéo démo (2 min)"
    echo "24. Audit & Autoréparation"
    echo -e "${RED}q. Quitter${NC}"
    echo -e "${BLUE}======================================================${NC}"
}

check_prerequisites
while true; do
    show_menu
    read -p "Votre choix : " choice
    echo ""
    case $choice in
        1) cmd_start_env ;;
        2) cmd_stop_env ;;
        3) cmd_status ;;
        4) cmd_dashboards ;;
        5) cmd_trigger_build ;;
        6) cmd_health ;;
        7) cmd_update_deployment ;;
        8) cmd_helm_rollback ;;
        9) cmd_restart_service ;;
        10) cmd_manage_secrets ;;
        11) cmd_network_info ;;
        12) cmd_show_logs ;;
        13) cmd_pod_details ;;
        14) cmd_realtime_monitoring ;;
        15) cmd_generate_report ;;
        16) cmd_backup ;;
        17) cmd_restore ;;
        18) cmd_trivy_scan ;;
        19) cmd_smoke_tests ;;
        20) cmd_advanced_cleanup ;;
        21) cmd_update_hosts ;;
        22) cmd_ssh_tunnel ;;
        23) cmd_demo_video ;;
        24) cmd_audit ;;
        q|Q) print_success "Au revoir !"; exit 0 ;;
        *) print_error "Option invalide." ;;
    esac
    pause
done
