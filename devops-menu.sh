#!/bin/bash
# ==============================================================================
# 🚀 Student Management - DevOps All-in-One Manager (Production Ready v3.0)
# Auteur      : Senior DevOps Architect
# Description : Script interactif et batch pour la gestion complète de
#               l'environnement de développement et de production K8s/Vagrant.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PARAMÉTRAGE STRICT ET GESTION DES SIGNAUX
# ------------------------------------------------------------------------------
set -eo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
    local exit_code=$?
    # Ne rien faire si on quitte proprement
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Le script s'est arrêté de manière inattendue avec le code $exit_code."
        echo -e "${RED}❌ Une erreur critique est survenue. Vérifiez les logs.${NC}"
    fi
    trap - SIGINT SIGTERM ERR EXIT
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
    # Affichage désactivé en mode non interactif pour ne pas polluer stdout
else
    # Valeurs par défaut hardcodées si aucun fichier n'existe
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

# Nettoyage des logs plus vieux que 7 jours (Rotation simple)
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
    for cmd in vagrant git curl jq; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd n'est pas installé ou n'est pas dans le PATH."
            MISSING=1
        fi
    done
    if [ $MISSING -eq 1 ]; then
        print_error "Veuillez installer les outils manquants avant de continuer."
        exit 1
    fi
}

check_k8s_auth() {
    local AUTH=$(vm_exec "kubectl auth can-i get pods -n $NAMESPACE" | tr -d '\r')
    if [[ "$AUTH" != "yes" ]]; then
        print_error "Permissions Kubernetes insuffisantes pour le namespace $NAMESPACE."
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# 4. FONCTIONNALITÉS (Actions Core)
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
    print_info "Vérification de l'état des services (en parallèle)..."
    # Execution en parallèle (background) pour accélérer l'affichage
    (
        echo -e "${BLUE}--- État de Vagrant ---${NC}"
        vagrant status | grep -E "running|saved|poweroff|aborted" || true
    ) &
    
    (
        echo -e "\n${BLUE}--- État des Pods Kubernetes ---${NC}"
        vm_exec "kubectl get pods -n $NAMESPACE" || true
    ) &
    
    wait
    print_success "Affichage de l'état terminé."
}

cmd_dashboards() {
    print_info "Ouverture des dashboards..."
    open_url "$JENKINS_URL"
    open_url "$SONAR_URL"
    open_url "$GRAFANA_URL"
    open_url "$PROMETHEUS_URL"
    open_url "$API_SWAGGER_URL"
}

cmd_health() {
    print_info "Health check de l'API (${API_HEALTH_URL})..."
    local HTTP_CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL" || echo "000")
    if [ "$HTTP_CODE" -eq 200 ]; then
        print_success "L'API est EN LIGNE (HTTP 200)."
    else
        print_error "L'API est HORS LIGNE ou injoignable (HTTP $HTTP_CODE)."
        exit 1
    fi
}

cmd_backup() {
    print_info "Création d'un backup MySQL..."
    local FILE_NAME="backup_$(date +%F_%H-%M-%S).sql"
    local POD_NAME=$(vm_exec "kubectl get pods -n $NAMESPACE -l $DB_LABEL -o jsonpath='{.items[0].metadata.name}'" | tr -d '\r')
    
    if [ -z "$POD_NAME" ]; then
        print_error "Impossible de trouver le pod MySQL."
        return 1
    fi

    # Le mot de passe est récupéré dynamiquement depuis l'environnement du pod.
    vm_exec "kubectl exec -n $NAMESPACE $POD_NAME -- bash -c 'mysqldump -u root -p\$MYSQL_ROOT_PASSWORD studentdb'" > "${BACKUP_DIR}/${FILE_NAME}"
    
    if [ -s "${BACKUP_DIR}/${FILE_NAME}" ]; then
        local SIZE=$(du -h "${BACKUP_DIR}/${FILE_NAME}" | cut -f1)
        print_success "Backup réussi ! Fichier: ${BACKUP_DIR}/${FILE_NAME} (Taille: $SIZE)"
    else
        print_error "Échec du backup. Fichier vide."
        rm -f "${BACKUP_DIR}/${FILE_NAME}"
        return 1
    fi
}

cmd_audit() {
    print_info "DÉBUT DE L'AUDIT & AUTORÉPARATION"
    local REPORT_FILE="${AUDITS_DIR}/audit_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "=========================================="
        echo " RAPPORT D'AUDIT & AUTORÉPARATION - $(date)"
        echo "=========================================="
        
        echo -e "\n[ Étape 1 : VM Vagrant ]"
        if vagrant status | grep -q "running"; then
            echo "✅ VM Vagrant en cours d'exécution."
        else
            echo "❌ VM Vagrant arrêtée ou introuvable. Action corrective : vagrant up"
            vagrant up || echo "Échec de vagrant up"
        fi

        echo -e "\n[ Étape 2 : Pods Kubernetes ]"
        local PODS_FAILS=$(vm_exec "kubectl get pods -n $NAMESPACE --field-selector status.phase=Failed -o name" | tr -d '\r')
        if [ -n "$PODS_FAILS" ]; then
            echo "❌ Pods en échec détectés : $PODS_FAILS"
            echo "Action corrective : Suppression des pods en échec..."
            vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE" || true
        else
            echo "✅ Aucun pod en état Failed."
        fi
        
        local CRASH_PODS=$(vm_exec "kubectl get pods -n $NAMESPACE | grep -E 'CrashLoopBackOff|Error|ImagePullBackOff'" | tr -d '\r' || true)
        if [ -n "$CRASH_PODS" ]; then
            echo "❌ Pods défaillants détectés :"
            echo "$CRASH_PODS"
            echo "Action corrective : Redémarrage des déploiements associés..."
            vm_exec "kubectl rollout restart deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE" || true
        else
            echo "✅ Aucun pod en état critique."
        fi

        echo -e "\n[ Étape 3 : API Health Check ]"
        local HTTP_CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL" || echo "000")
        if [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ API Spring Boot répond correctement (HTTP 200)."
        else
            echo "❌ API Spring Boot ne répond pas ou erreur (HTTP $HTTP_CODE)."
            echo "Action corrective : Redémarrage du service..."
            vm_exec "kubectl rollout restart deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE" || true
        fi
        
        echo -e "\n[ Étape 4 : Logs récents (Recherche d'Exceptions) ]"
        local LOG_ERRORS=$(vm_exec "kubectl logs deployment/$APP_DEPLOYMENT_NAME -n $NAMESPACE --tail=200 | grep -i -E 'exception|error|fatal' | tail -n 5" | tr -d '\r' || true)
        if [ -n "$LOG_ERRORS" ]; then
            echo "⚠️ Avertissement : Des erreurs ont été trouvées dans les logs de l'application :"
            echo "$LOG_ERRORS"
        else
            echo "✅ Aucune erreur critique récente dans les logs."
        fi
        
        echo -e "\n=========================================="
        echo " FIN DE L'AUDIT - $(date)"
    } | tee -a "$REPORT_FILE"
    
    print_success "Audit et autoréparation terminés. Rapport : $REPORT_FILE"
}

# ------------------------------------------------------------------------------
# 5. ARGUMENTS LIGNE DE COMMANDE (Mode Non-Interactif / CI-CD)
# ------------------------------------------------------------------------------

usage() {
    echo -e "${GREEN}Utilisation : $0 [options]${NC}"
    echo "Options:"
    echo "  -h, --help       Afficher l'aide"
    echo "  -c, --config     Spécifier un fichier de configuration alternatif"
    echo "  -a, --action     Exécuter une action en mode batch (sans menu)"
    echo ""
    echo "Actions disponibles :"
    echo "  start     : Démarre l'environnement (VM)"
    echo "  stop      : Arrête l'environnement"
    echo "  status    : Affiche l'état K8s et Vagrant"
    echo "  health    : Vérifie la santé de l'API"
    echo "  backup    : Exécute un backup MySQL"
    echo "  audit     : Lance l'audit et l'autoréparation"
    echo ""
    echo "Exemple : $0 --action health"
    exit 0
}

NON_INTERACTIVE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -c|--config) CONFIG_FILE="$2"; source "$CONFIG_FILE"; shift ;;
        -a|--action) 
            NON_INTERACTIVE="true"
            ACTION="$2"
            shift 
            ;;
        *) print_error "Paramètre inconnu: $1"; usage ;;
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
        *) print_error "Action inconnue: $ACTION"; exit 1 ;;
    esac
    exit 0
fi

# ------------------------------------------------------------------------------
# 6. MODE INTERACTIF (Menu)
# ------------------------------------------------------------------------------

show_menu() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🚀 Student Management - DevOps Menu (Production v3.0)${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${CYAN}[ OPÉRATIONS CORE ]${NC}"
    echo "1. Démarrer l'environnement"
    echo "2. Arrêter l'environnement"
    echo "3. État des services"
    echo "4. Ouvrir les dashboards"
    echo "5. Health check API"
    echo -e "${CYAN}[ MAINTENANCE & SÉCURITÉ ]${NC}"
    echo "6. Backup de la Base de Données (MySQL)"
    echo "7. Audit & Autoréparation de l'environnement"
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
        5) cmd_health ;;
        6) cmd_backup ;;
        7) cmd_audit ;;
        q|Q) 
            print_success "Au revoir ! 👋"
            # Cleanup trap gère le reste
            trap - SIGINT SIGTERM ERR EXIT
            exit 0 
            ;;
        *) 
            print_error "Option invalide. Veuillez réessayer." 
            ;;
    esac
    pause
done
