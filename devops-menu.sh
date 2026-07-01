#!/bin/bash

# ==============================================================================
# 🚀 Student Management - DevOps All-in-One Manager (Advanced v2.0)
# Auteur: Senior DevOps Architect
# ==============================================================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables Globales
VM_IP="192.168.56.10"
JENKINS_URL="http://${VM_IP}:8088"
SONAR_URL="http://${VM_IP}:9000"
GRAFANA_URL="http://${VM_IP}:3000"
PROMETHEUS_URL="http://${VM_IP}:9090"
API_SWAGGER_URL="http://${VM_IP}:30089/student/swagger-ui.html"
API_HEALTH_URL="http://${VM_IP}:30089/student/actuator/health"
NAMESPACE="devops-tools"
BACKUP_DIR="./backups"

mkdir -p "$BACKUP_DIR"

# Fonction d'ouverture d'URL / Nouveau terminal (cross-platform)
open_url() {
    local URL=$1
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$URL" > /dev/null 2>&1
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "$URL" > /dev/null 2>&1
    elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
        start "$URL" > /dev/null 2>&1
    else
        echo -e "${YELLOW}Veuillez ouvrir manuellement : $URL${NC}"
    fi
}

open_terminal() {
    local CMD=$1
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
        start bash -c "$CMD; echo ''; read -p 'Appuyez sur Entrée pour fermer...'"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "tell application \"Terminal\" to do script \"$CMD\""
    else
        gnome-terminal -- bash -c "$CMD; exec bash" 2>/dev/null || xterm -e "$CMD; bash" 2>/dev/null || echo -e "${RED}Ouverture de terminal non supportée sur cet OS.${NC}"
    fi
}

# Fonction utilitaire pour exécuter une commande dans la VM
vm_exec() {
    vagrant ssh -c "$1"
}

# Pause pour le menu
pause() {
    echo -e "\n${CYAN}Appuyez sur [Entrée] pour retourner au menu...${NC}"
    read -r
}

# ==============================================================================
# VÉRIFICATION DES PRÉREQUIS
# ==============================================================================
check_prerequisites() {
    echo -e "${BLUE}Vérification des prérequis...${NC}"
    local MISSING=0
    for cmd in vagrant git curl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}❌ $cmd n'est pas installé ou n'est pas dans le PATH.${NC}"
            MISSING=1
        fi
    done
    if [ $MISSING -eq 1 ]; then
        echo -e "${RED}Veuillez installer les outils manquants avant de continuer.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Tous les prérequis sont satisfaits.${NC}\n"
}

# ==============================================================================
# ACTIONS DU MENU (Fonctionnalités de base)
# ==============================================================================

start_env() {
    echo -e "${YELLOW}Démarrage de la machine virtuelle Vagrant...${NC}"
    vagrant up
    echo -e "${GREEN}✅ Environnement démarré !${NC}"
}

stop_env() {
    echo -e "${YELLOW}Arrêt de la machine virtuelle...${NC}"
    vagrant halt
    echo -e "${GREEN}✅ Environnement arrêté !${NC}"
}

status_services() {
    echo -e "${BLUE}--- État de Vagrant ---${NC}"
    vagrant status
    echo -e "\n${BLUE}--- État des Pods Kubernetes ---${NC}"
    vm_exec "kubectl get pods -n $NAMESPACE"
}

open_dashboards() {
    echo -e "${YELLOW}Ouverture des dashboards...${NC}"
    open_url "$JENKINS_URL"
    open_url "$SONAR_URL"
    open_url "$GRAFANA_URL"
    open_url "$PROMETHEUS_URL"
    open_url "$API_SWAGGER_URL"
    echo -e "${GREEN}Dashboards ouverts !${NC}"
}

show_logs() {
    echo -e "${YELLOW}Affichage des logs de spring-app...${NC}"
    vm_exec "kubectl logs deployment/spring-app -n $NAMESPACE --tail=50"
}

trigger_build() {
    echo -e "${YELLOW}Déclenchement du build dans Jenkins...${NC}"
    open_url "${JENKINS_URL}/job/student-management-pipeline/"
}

health_check() {
    echo -e "${YELLOW}Vérification de la santé de l'API (Actuator Health)...${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL")
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ L'API est EN LIGNE (HTTP 200).${NC}"
    else
        echo -e "${RED}❌ L'API est HORS LIGNE ou injoignable (HTTP $HTTP_CODE).${NC}"
    fi
}

restart_service() {
    echo -e "${CYAN}Redémarrage du pod Spring Boot dans Kubernetes...${NC}"
    vm_exec "kubectl rollout restart deployment/spring-app -n $NAMESPACE"
}

update_deployment() {
    echo -e "${YELLOW}Mise à jour du déploiement via Helm...${NC}"
    vm_exec "helm upgrade student-management /vagrant/helm/student-management -n $NAMESPACE"
}

network_info() {
    echo -e "${BLUE}--- Informations Réseau ---${NC}"
    echo -e "💻 IP VM Vagrant : ${GREEN}${VM_IP}${NC}"
    echo -e "API K8s (NodePort) : 30089"
}

# ==============================================================================
# NOUVELLES FONCTIONNALITÉS AVANCÉES
# ==============================================================================

backup_db() {
    echo -e "${YELLOW}Création d'un backup MySQL...${NC}"
    local FILE_NAME="backup_$(date +%F_%H-%M-%S).sql"
    local POD_NAME=$(vagrant ssh -c "kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}'" | tr -d '\r')
    
    if [ -z "$POD_NAME" ]; then
        echo -e "${RED}Impossible de trouver le pod MySQL.${NC}"
        return
    fi

    echo "Exécution de mysqldump sur le pod $POD_NAME..."
    vagrant ssh -c "kubectl exec -n $NAMESPACE $POD_NAME -- bash -c 'mysqldump -u root -p\$MYSQL_ROOT_PASSWORD studentdb'" > "${BACKUP_DIR}/${FILE_NAME}"
    
    if [ -s "${BACKUP_DIR}/${FILE_NAME}" ]; then
        local SIZE=$(du -h "${BACKUP_DIR}/${FILE_NAME}" | cut -f1)
        echo -e "${GREEN}✅ Backup réussi ! Fichier: ${BACKUP_DIR}/${FILE_NAME} (Taille: $SIZE)${NC}"
    else
        echo -e "${RED}❌ Échec du backup. Fichier vide.${NC}"
        rm -f "${BACKUP_DIR}/${FILE_NAME}"
    fi
}

restore_db() {
    echo -e "${CYAN}--- Restauration de Backup MySQL ---${NC}"
    local backups=(${BACKUP_DIR}/*.sql)
    if [ ${#backups[@]} -eq 0 ] || [ ! -e "${backups[0]}" ]; then
        echo -e "${RED}Aucun fichier de backup trouvé dans ${BACKUP_DIR}.${NC}"
        return
    fi

    echo "Backups disponibles :"
    for i in "${!backups[@]}"; do
        echo "$((i+1)). $(basename "${backups[$i]}")"
    done

    read -p "Entrez le numéro du backup à restaurer (ou 0 pour annuler) : " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#backups[@]}" ]; then
        local file="${backups[$((choice-1))]}"
        local POD_NAME=$(vagrant ssh -c "kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}'" | tr -d '\r')
        
        echo -e "${YELLOW}Restauration de $file dans la base de données...${NC}"
        cat "$file" | vagrant ssh -c "kubectl exec -i -n $NAMESPACE $POD_NAME -- bash -c 'mysql -u root -p\$MYSQL_ROOT_PASSWORD studentdb'"
        echo -e "${GREEN}✅ Restauration terminée !${NC}"
    else
        echo -e "${YELLOW}Annulation.${NC}"
    fi
}

helm_rollback() {
    echo -e "${BLUE}--- Historique des Releases Helm ---${NC}"
    vm_exec "helm history student-management -n $NAMESPACE"
    
    echo -e "\n${CYAN}Si une mise à jour a cassé la production, vous pouvez revenir en arrière.${NC}"
    read -p "Entrez le numéro de REVISION pour le rollback (ou 0 pour annuler) : " rev
    if [[ "$rev" =~ ^[0-9]+$ ]] && [ "$rev" -gt 0 ]; then
        echo -e "${YELLOW}Rollback vers la révision $rev...${NC}"
        vm_exec "helm rollback student-management $rev -n $NAMESPACE"
        echo -e "${GREEN}✅ Rollback exécuté !${NC}"
    fi
}

smoke_tests() {
    echo -e "${BLUE}--- Smoke Tests (Tests de charge / Connectivité) ---${NC}"
    local endpoints=(
        "http://${VM_IP}:30089/student/actuator/health"
        "http://${VM_IP}:30089/student/students"
        "http://${VM_IP}:30089/student/departments"
        "http://${VM_IP}:30089/student/enrollments"
    )

    for url in "${endpoints[@]}"; do
        echo -n "Testing $url ... "
        # Format: HTTP_CODE TIME_TOTAL
        res=$(curl -o /dev/null -s -w "%{http_code} %{time_total}s\n" "$url")
        code=$(echo $res | awk '{print $1}')
        time=$(echo $res | awk '{print $2}')
        if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
            echo -e "${GREEN}OK ($code) - $time${NC}"
        else
            echo -e "${RED}FAIL ($code) - $time${NC}"
        fi
    done
}

realtime_monitoring() {
    echo -e "${YELLOW}Ouverture d'un nouveau terminal pour la supervision...${NC}"
    open_terminal "vagrant ssh -c 'kubectl get pods -n $NAMESPACE -w'"
    open_terminal "vagrant ssh -c 'kubectl logs -f deployment/spring-app -n $NAMESPACE'"
    echo -e "${GREEN}✅ Terminaux ouverts !${NC}"
}

trivy_scan() {
    echo -e "${YELLOW}Scan de vulnérabilités Docker avec Trivy...${NC}"
    # Vérifie si trivy est installé dans la VM, sinon l'installe temporairement ou affiche l'erreur
    vm_exec "if ! command -v trivy &> /dev/null; then 
        echo 'Trivy non installé sur la VM. Installation...'
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.49.1
    fi
    trivy image esprit/student-management:latest --severity HIGH,CRITICAL"
}

manage_secrets() {
    echo -e "${BLUE}--- Gestion des Secrets Kubernetes ---${NC}"
    vm_exec "kubectl get secrets -n $NAMESPACE"
    
    echo -e "\n${CYAN}Voulez-vous modifier un secret (ex: app-secrets) ?${NC}"
    read -p "(y/n) : " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "Nom du secret à éditer : " sec_name
        echo -e "${YELLOW}Attention, vous allez utiliser l'éditeur VI dans la VM.${NC}"
        vm_exec "kubectl edit secret $sec_name -n $NAMESPACE"
    fi
}

pod_details() {
    echo -e "${BLUE}--- Utilisation des Ressources (Metrics Server) ---${NC}"
    vm_exec "kubectl top pods -n $NAMESPACE" || echo -e "${RED}Metrics server peut ne pas être installé.${NC}"
    
    echo -e "\n${BLUE}--- Détails des Pods (Redémarrages, Status) ---${NC}"
    vm_exec "kubectl get pods -n $NAMESPACE -o wide"
}

generate_report() {
    echo -e "${YELLOW}Génération du rapport d'état...${NC}"
    local REPORT_FILE="status_report_$(date +%F_%H-%M-%S).txt"
    {
        echo "=========================================="
        echo " RAPPORT D'ÉTAT - STUDENT MANAGEMENT"
        echo " Date: $(date)"
        echo "=========================================="
        echo -e "\n--- NODES ---"
        vagrant ssh -c "kubectl get nodes"
        echo -e "\n--- PODS ---"
        vagrant ssh -c "kubectl get pods -n $NAMESPACE"
        echo -e "\n--- SERVICES ---"
        vagrant ssh -c "kubectl get svc -n $NAMESPACE"
        echo -e "\n--- RELEASES HELM ---"
        vagrant ssh -c "helm list -n $NAMESPACE"
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✅ Rapport généré : $REPORT_FILE${NC}"
}

update_hosts() {
    echo -e "${CYAN}Mise à jour du fichier Hosts (Windows / OS X)${NC}"
    echo -e "Pour accéder aux services via des noms de domaine (ex: api.student.local), vous devez ajouter cette ligne dans votre fichier hosts :"
    echo -e "${YELLOW}${VM_IP} api.student.local grafana.student.local jenkins.student.local${NC}"
    
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win32" ]]; then
        echo -e "Sur Windows, modifiez le fichier en tant qu'Administrateur : ${GREEN}C:\Windows\System32\drivers\etc\hosts${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        echo -e "Sur Linux/Mac, tapez : ${GREEN}sudo nano /etc/hosts${NC}"
    fi
}

ssh_tunnel() {
    echo -e "${YELLOW}Ouverture d'une session SSH interactive dans un nouveau terminal...${NC}"
    open_terminal "vagrant ssh"
}

advanced_cleanup() {
    echo -e "${RED}⚠️ ATTENTION : Nettoyage Avancé.${NC}"
    echo -e "1. Suppression des pods en erreur (Evicted, CrashLoopBackOff)"
    echo -e "2. Suppression des images Docker non utilisées (dangling)"
    read -p "Continuer ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE"
        vm_exec "eval \$(minikube docker-env) && docker image prune -a -f"
        echo -e "${GREEN}✅ Nettoyage terminé.${NC}"
    fi
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

show_menu() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🚀 Student Management - DevOps Menu (Advanced v2.0)${NC}"
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
    echo "8. Rollback Helm (Revenir en arrière)"
    echo "9. Redémarrer le service Spring App"
    echo "10. Gestion des Secrets K8s"
    echo "11. Informations réseau"
    echo -e "${CYAN}[ SUPERVISION & LOGS ]${NC}"
    echo "12. Logs basiques (Spring Boot)"
    echo "13. Détails des Pods et Ressources (Top/Describe)"
    echo "14. Supervision en temps réel (Nouveau terminal)"
    echo "15. Générer un rapport d'état système"
    echo -e "${CYAN}[ MAINTENANCE & SÉCURITÉ ]${NC}"
    echo "16. Backup de la Base de Données (MySQL)"
    echo "17. Restaurer un Backup MySQL"
    echo "18. Scan de vulnérabilités Docker (Trivy)"
    echo "19. Smoke Tests (Test de charge API)"
    echo "20. Nettoyage avancé (Images, Pods Failed)"
    echo "21. Mettre à jour le fichier Hosts DNS"
    echo "22. Ouvrir un Tunnel SSH (Vagrant SSH)"
    echo -e "${RED}q. Quitter${NC}"
    echo -e "${BLUE}======================================================${NC}"
}

# Initialisation
check_prerequisites

# Boucle principale
while true; do
    show_menu
    read -p "Votre choix : " choice
    echo ""

    case $choice in
        1) start_env ;;
        2) stop_env ;;
        3) status_services ;;
        4) open_dashboards ;;
        5) trigger_build ;;
        6) health_check ;;
        7) update_deployment ;;
        8) helm_rollback ;;
        9) restart_service ;;
        10) manage_secrets ;;
        11) network_info ;;
        12) show_logs ;;
        13) pod_details ;;
        14) realtime_monitoring ;;
        15) generate_report ;;
        16) backup_db ;;
        17) restore_db ;;
        18) trivy_scan ;;
        19) smoke_tests ;;
        20) advanced_cleanup ;;
        21) update_hosts ;;
        22) ssh_tunnel ;;
        q|Q) 
            echo -e "${GREEN}Au revoir ! 👋${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}❌ Option invalide. Veuillez réessayer.${NC}" 
            ;;
    esac
    pause
done
