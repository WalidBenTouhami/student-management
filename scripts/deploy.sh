#!/bin/bash
# scripts/deploy.sh
# Script de déploiement sur Kubernetes

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

log_section "🚀 DÉPLOIEMENT DE L'APPLICATION SUR KUBERNETES"

# Variables
NAMESPACE="${K8S_NAMESPACE:-devops-tools}"
IMAGE="${DOCKER_IMAGE:-esprit/student-management:latest}"

# Vérification de kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl non trouvé"
    exit 1
fi

# Vérification du namespace
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_info "Création du namespace $NAMESPACE..."
    kubectl create namespace "$NAMESPACE"
fi

# Application des manifests
log_info "Application des manifests Kubernetes..."
kubectl apply -f k8s/secrets.yaml -n "$NAMESPACE"
kubectl apply -f k8s/configmap.yaml -n "$NAMESPACE" 2>/dev/null || true
kubectl apply -f k8s/mysql-deployment.yaml -n "$NAMESPACE"
kubectl apply -f k8s/mysql-service.yaml -n "$NAMESPACE"
kubectl apply -f k8s/deployment.yaml -n "$NAMESPACE"
kubectl apply -f k8s/service.yaml -n "$NAMESPACE"

# Attendre le déploiement
log_info "Attente du déploiement..."
kubectl rollout status deployment/spring-app -n "$NAMESPACE" --timeout=300s

# Vérification
log_info "Vérification des pods..."
kubectl get pods -n "$NAMESPACE"

log_info "Vérification des services..."
kubectl get svc -n "$NAMESPACE"

log_section "✅ DÉPLOIEMENT TERMINÉ"
echo ""
echo "🌐 Application disponible sur : http://192.168.56.10:30080/student"