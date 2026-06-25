#!/bin/bash
# scripts/health-check.sh
# Health check de l'application

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE}  🏥 HEALTH CHECK${NC}"
echo -e "${BLUE}============================================================${NC}\n"

APP_URL="http://192.168.56.10:8089/student/actuator/health"

log_info "Vérification de l'application sur $APP_URL..."

# Test de l'application
if curl -f -s -o /dev/null "$APP_URL"; then
    log_info "✅ Application : OK"
else
    log_error "❌ Application : DOWN"
    exit 1
fi

# Vérification des services
log_info "\n📊 Vérification des services..."

# Jenkins
if curl -f -s -o /dev/null http://192.168.56.10:8080; then
    log_info "✅ Jenkins : OK"
else
    log_warn "⚠️ Jenkins : DOWN"
fi

# SonarQube
if curl -f -s -o /dev/null http://192.168.56.10:9000; then
    log_info "✅ SonarQube : OK"
else
    log_warn "⚠️ SonarQube : DOWN"
fi

# Grafana
if curl -f -s -o /dev/null http://192.168.56.10:3000; then
    log_info "✅ Grafana : OK"
else
    log_warn "⚠️ Grafana : DOWN"
fi

# Prometheus
if curl -f -s -o /dev/null http://192.168.56.10:9090; then
    log_info "✅ Prometheus : OK"
else
    log_warn "⚠️ Prometheus : DOWN"
fi

echo -e "\n${GREEN}✅ Health check terminé${NC}\n"