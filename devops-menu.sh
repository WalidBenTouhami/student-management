#!/bin/bash

# ==============================================================================
# 🚀 Student Management - DevOps All-in-One Manager
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

# Fonction d'ouverture d'URL (cross-platform)
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
        else
            echo -e "${GREEN}✅ $cmd est installé.${NC}"
        fi
    done
    if [ $MISSING -eq 1 ]; then
        echo -e "${RED}Veuillez installer les outils manquants avant de continuer.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Tous les prérequis sont satisfaits.${NC}\n"
}

# ==============================================================================
# ACTIONS DU MENU
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
    
    echo -e "\n${BLUE}--- État des Pods Kubernetes (Namespace: $NAMESPACE) ---${NC}"
    vm_exec "kubectl get pods -n $NAMESPACE"
    
    echo -e "\n${BLUE}--- État des services Docker Compose ---${NC}"
    vm_exec "cd /vagrant/docker && docker compose ps"
}

open_dashboards() {
    echo -e "${YELLOW}Ouverture des dashboards dans votre navigateur par défaut...${NC}"
    echo -e "🔗 Jenkins : ${JENKINS_URL}"
    open_url "$JENKINS_URL"
    
    echo -e "🔗 SonarQube : ${SONAR_URL}"
    open_url "$SONAR_URL"
    
    echo -e "🔗 Grafana : ${GRAFANA_URL}"
    open_url "$GRAFANA_URL"
    
    echo -e "🔗 Prometheus : ${PROMETHEUS_URL}"
    open_url "$PROMETHEUS_URL"
    
    echo -e "🔗 API Swagger : ${API_SWAGGER_URL}"
    open_url "$API_SWAGGER_URL"
    
    echo -e "${GREEN}Dashboards ouverts !${NC}"
}

show_logs() {
    echo -e "${CYAN}Quel composant voulez-vous inspecter ?${NC}"
    echo "1. Pod Spring Boot (Kubernetes)"
    echo "2. Jenkins (Docker)"
    echo "3. MySQL (Kubernetes)"
    echo "4. Grafana (Docker)"
    read -p "Choix : " log_choice

    case $log_choice in
        1)
            echo -e "${YELLOW}Affichage des 50 dernières lignes de spring-app...${NC}"
            vm_exec "kubectl logs deployment/spring-app -n $NAMESPACE --tail=50"
            ;;
        2)
            echo -e "${YELLOW}Affichage des logs de Jenkins...${NC}"
            vm_exec "docker logs jenkins --tail=50"
            ;;
        3)
            echo -e "${YELLOW}Affichage des logs MySQL (K8s)...${NC}"
            vm_exec "kubectl logs deployment/mysql-deployment -n $NAMESPACE --tail=50"
            ;;
        4)
            echo -e "${YELLOW}Affichage des logs Grafana...${NC}"
            vm_exec "cd /vagrant/docker && docker compose logs --tail=50 grafana"
            ;;
        *)
            echo -e "${RED}Choix invalide.${NC}"
            ;;
    esac
}

trigger_build() {
    echo -e "${YELLOW}Pour lancer un build Jenkins, un webhook ou un appel API est nécessaire.${NC}"
    echo -e "Voici la commande cURL pour déclencher un build (Assurez-vous d'avoir configuré un token) :"
    echo -e "${CYAN}curl -X POST ${JENKINS_URL}/job/student-management-pipeline/build --user USER:TOKEN${NC}"
    echo -e "\nSinon, veuillez ouvrir Jenkins et cliquer sur 'Build Now'."
    open_url "${JENKINS_URL}/job/student-management-pipeline/"
}

show_endpoints() {
    echo -e "${BLUE}--- Endpoints de l'API Student Management ---${NC}"
    echo -e "🌍 Base URL : http://${VM_IP}:30089/student\n"
    
    echo -e "${CYAN}Étudiants :${NC}"
    echo " - GET    /students"
    echo " - POST   /students"
    echo " - PUT    /students/{id}"
    echo " - DELETE /students/{id}"
    
    echo -e "\n${CYAN}Exemple de requête (Lister les étudiants) :${NC}"
    echo "curl -X GET http://${VM_IP}:30089/student/students"
}

health_check() {
    echo -e "${YELLOW}Vérification de la santé de l'API (Actuator Health)...${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_HEALTH_URL")
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ L'API est EN LIGNE (HTTP 200).${NC}"
        echo "Détails :"
        curl -s "$API_HEALTH_URL" | grep -o '{"status":"[^"]*"' | tr -d '"{}'
    else
        echo -e "${RED}❌ L'API est HORS LIGNE ou injoignable (HTTP $HTTP_CODE).${NC}"
    fi
}

restart_service() {
    echo -e "${CYAN}Redémarrage du pod Spring Boot dans Kubernetes...${NC}"
    vm_exec "kubectl rollout restart deployment/spring-app -n $NAMESPACE"
    echo -e "${GREEN}✅ Ordre de redémarrage (Rolling Update) envoyé !${NC}"
}

update_deployment() {
    echo -e "${YELLOW}Mise à jour du déploiement via Helm...${NC}"
    vm_exec "helm upgrade student-management /vagrant/helm/student-management -n $NAMESPACE"
    echo -e "${GREEN}✅ Mise à jour Helm terminée !${NC}"
}

clean_env() {
    echo -e "${RED}⚠️ ATTENTION : Nettoyage de l'environnement.${NC}"
    echo -e "Cette action va purger les images Docker non utilisées et les pods en échec."
    read -p "Voulez-vous continuer ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        vm_exec "docker system prune -f"
        vm_exec "kubectl delete pods --field-selector status.phase=Failed -n $NAMESPACE"
        echo -e "${GREEN}✅ Nettoyage terminé.${NC}"
    else
        echo -e "${YELLOW}Opération annulée.${NC}"
    fi
}

network_info() {
    echo -e "${BLUE}--- Informations Réseau ---${NC}"
    echo -e "💻 IP de la VM Vagrant : ${GREEN}${VM_IP}${NC}"
    echo -e "⚓ IP de Minikube (Interne VM) :"
    vm_exec "minikube ip"
    echo -e "🔄 Ports forwardés :"
    echo -e "   - Jenkins : 8088"
    echo -e "   - SonarQube : 9000"
    echo -e "   - Grafana : 3000"
    echo -e "   - Prometheus : 9090"
    echo -e "   - API K8s (NodePort) : 30089"
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

show_menu() {
    clear
    echo -e "${BLUE}====================================${NC}"
    echo -e "${GREEN}🚀 Student Management - DevOps Menu${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo "1. Démarrer l'environnement"
    echo "2. Arrêter l'environnement"
    echo "3. État des services"
    echo "4. Ouvrir les dashboards"
    echo "5. Logs"
    echo "6. Lancer un build Jenkins"
    echo "7. Voir les endpoints API"
    echo "8. Health check API"
    echo "9. Redémarrer un service (Spring App)"
    echo "10. Mettre à jour le déploiement (Helm)"
    echo "11. Nettoyer l'environnement"
    echo "12. Informations réseau"
    echo -e "${RED}q. Quitter${NC}"
    echo -e "${BLUE}====================================${NC}"
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
        5) show_logs ;;
        6) trigger_build ;;
        7) show_endpoints ;;
        8) health_check ;;
        9) restart_service ;;
        10) update_deployment ;;
        11) clean_env ;;
        12) network_info ;;
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
