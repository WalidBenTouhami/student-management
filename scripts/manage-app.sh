#!/bin/bash
# scripts/manage-app.sh
# Gestionnaire de cycle de vie pour l'application Spring Boot

set -e

# ============================================================
# VARIABLES
# ============================================================
APP_NAME="student-management"
APP_PORT=8089
PID_FILE="/tmp/${APP_NAME}.pid"
LOG_FILE="/tmp/${APP_NAME}.log"
JAR_FILE="target/${APP_NAME}-*.jar"
PROJECT_DIR="/vagrant"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================
# FONCTIONS
# ============================================================

# Vérifier si l'application est en cours d'exécution
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Trouver les processus occupant le port
find_port_processes() {
    local pids=$(lsof -ti :$APP_PORT 2>/dev/null || netstat -tlnp 2>/dev/null | grep ":$APP_PORT" | awk '{print $7}' | cut -d'/' -f1)
    echo "$pids"
}

# Tuer les processus orphelins sur le port
kill_orphaned() {
    local pids=$(find_port_processes)
    if [ -n "$pids" ]; then
        log_warn "Processus orphelins trouvés sur le port $APP_PORT : $pids"
        echo "$pids" | xargs kill -9 2>/dev/null || true
        log_info "✅ Processus orphelins nettoyés"
    fi
}

# ============================================================
# COMMANDES
# ============================================================

start() {
    cd "$PROJECT_DIR" || { log_error "Projet introuvable"; exit 1; }

    log_warn "⚠️ L'application est maintenant configurée pour tourner sur Kubernetes (Minikube)."
    log_warn "Le démarrage natif est utilisé comme secours de développement."

    # Nettoyer les orphelins avant le démarrage
    kill_orphaned

    if is_running; then
        log_warn "L'application est déjà en cours d'exécution (PID: $(cat $PID_FILE))"
        return 0
    fi

    log_info "🚀 Démarrage de l'application $APP_NAME..."

    # Construire le JAR avec détection des changements
    log_info "📦 Construction ou mise à jour du JAR..."
    ./mvnw package -DskipTests

    # Lancer l'application en arrière-plan
    nohup java -jar $(ls -t $JAR_FILE | head -1) > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"

    # Attendre que l'application démarre
    sleep 5
    if is_running; then
        log_info "✅ Application démarrée (PID: $pid)"
        log_info "📋 Logs: tail -f $LOG_FILE"
        log_info "🌐 URL: http://localhost:$APP_PORT/student"
    else
        log_error "❌ Échec du démarrage. Voir les logs: cat $LOG_FILE"
        return 1
    fi
}

stop() {
    log_info "🛑 Arrêt de l'application $APP_NAME..."

    # Tuer le processus géré
    if is_running; then
        local pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null || true
        sleep 2
        rm -f "$PID_FILE"
        log_info "✅ Processus PID $pid arrêté"
    fi

    # Nettoyer les processus orphelins
    kill_orphaned
    log_info "✅ Nettoyage terminé"
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        log_info "✅ Application en cours d'exécution (PID: $pid)"
        log_info "🌐 URL: http://localhost:$APP_PORT/student"
        return 0
    else
        log_warn "❌ Application arrêtée"
        return 1
    fi
}

clean() {
    log_info "🧹 Nettoyage complet..."

    # Arrêter l'application gérée
    if is_running; then
        local pid=$(cat "$PID_FILE")
        kill -9 "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
        log_info "✅ Processus géré PID $pid tué"
    fi

    # Nettoyer tous les processus Java sur le port
    kill_orphaned

    # Nettoyer les fichiers temporaires
    rm -f "$PID_FILE"
    log_info "✅ Nettoyage terminé"
}

logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        log_warn "Aucun fichier de log trouvé"
    fi
}

# ============================================================
# AIDE
# ============================================================
show_help() {
    cat << EOF
📋 Gestionnaire de l'application $APP_NAME

Usage: $0 {start|stop|restart|status|clean|logs|help}

Commandes:
  start    - Démarrer l'application en arrière-plan
  stop     - Arrêter l'application proprement
  restart  - Redémarrer l'application
  status   - Vérifier si l'application est en cours d'exécution
  clean    - Nettoyer tous les processus orphelins
  logs     - Afficher les logs en temps réel
  help     - Afficher cette aide

Exemples:
  $0 start    # Démarrer l'application
  $0 status   # Vérifier le statut
  $0 logs     # Voir les logs
EOF
}

# ============================================================
# MAIN
# ============================================================
case "${1:-help}" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    status)  status ;;
    clean)   clean ;;
    logs)    logs ;;
    help|*)  show_help ;;
esac
