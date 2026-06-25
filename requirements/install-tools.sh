#!/bin/bash
# requirements/install-tools.sh
# Script principal d'installation des outils DevOps

set -e

# ============================================================
# COULEURS ET STYLES
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ============================================================
# FONCTIONS DE LOGGING
# ============================================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${PURPLE}[SUCCESS]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
}

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║  $1${NC}"
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================
# VÉRIFICATION DES PRÉREQUIS
# ============================================================
check_prerequisites() {
    log_section "🔍 VÉRIFICATION DES PRÉREQUIS"

    # Vérifier que le script est exécuté sur Ubuntu/Debian
    if ! grep -q "Ubuntu\|Debian" /etc/os-release 2>/dev/null; then
        log_error "Ce script est conçu pour Ubuntu/Debian uniquement"
        exit 1
    fi

    # Vérifier les droits sudo
    if ! sudo -v 2>/dev/null; then
        log_error "Les droits sudo sont requis"
        exit 1
    fi

    log_success "✅ Prérequis vérifiés"
}

# ============================================================
# FONCTION PRINCIPALE
# ============================================================
main() {
    log_header "🚀 INSTALLATION DES OUTILS DEVOPS"

    # Vérification des prérequis
    check_prerequisites

    # Mise à jour du système
    log_section "📦 MISE À JOUR DU SYSTÈME"
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y -q
    sudo apt-get upgrade -y -q
    sudo apt-get autoremove -y -q

    # Installation des outils
    log_section "🛠️ INSTALLATION DES OUTILS DE BASE"
    sudo apt-get install -y -q \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        git \
        vim \
        htop \
        net-tools \
        wget \
        tree \
        jq \
        unzip \
        make \
        build-essential \
        gnupg-agent \
        dnsutils \
        netcat \
        telnet \
        gnupg2 \
        redis-tools

    # Java 21
    bash requirements/install-java.sh

    # Maven 3.9.9
    bash requirements/install-maven.sh

    # Docker
    bash requirements/install-docker.sh

    # Kubernetes (kubectl, minikube, helm)
    bash requirements/install-kubernetes.sh

    # Jenkins
    bash requirements/install-jenkins.sh

    # Services (SonarQube, Grafana, Prometheus)
    bash requirements/install-services.sh

    # Vérification finale
    log_section "📋 VÉRIFICATION FINALE"
    bash requirements/check-versions.sh

    log_header "✅ INSTALLATION TERMINÉE AVEC SUCCÈS !"

    echo ""
    echo "📝 RÉSUMÉ DES SERVICES INSTALLÉS :"
    echo "-----------------------------------"
    echo "🔧 Jenkins     : http://192.168.56.10:8088"
    echo "📊 SonarQube   : http://192.168.56.10:9000"
    echo "📈 Grafana     : http://192.168.56.10:3000"
    echo "📉 Prometheus  : http://192.168.56.10:9090"
    echo ""
    echo "🔑 MOT DE PASSE JENKINS :"
    echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    echo ""
}

# ============================================================
# EXÉCUTION
# ============================================================
main "$@"
