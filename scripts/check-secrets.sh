#!/bin/bash
# scripts/check-secrets.sh
# Vérification des secrets avant déploiement

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}============================================================${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}============================================================${NC}\n"; }

log_section "🔐 VÉRIFICATION DES SECRETS"

# Vérifier le fichier .env
if [ ! -f ".env" ]; then
    log_error "Fichier .env manquant"
    log_info "Copiez .env.example vers .env et configurez les secrets"
    exit 1
fi

# Charger .env
source .env

# Liste des variables requises
required_vars=(
    "SPRING_DATASOURCE_PASSWORD"
    "JWT_SECRET"
    "MAIL_PASSWORD"
    "DOCKER_PASSWORD"
    "SONAR_TOKEN"
)

# Vérification
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [ "${!var}" = "change_me" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    log_error "Variables manquantes ou non définies :"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

log_section "✅ TOUS LES SECRETS SONT DÉFINIS"