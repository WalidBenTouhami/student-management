#!/bin/bash
# ============================================================================
# Script: jenkins_jobs_monitor.sh
# Description: Surveillance avancée des jobs Jenkins (Optimisé)
# Author: DevOps Ninja Team
# Version: 3.1 - Bug fixes
# ============================================================================

set -euo pipefail

# ============================================================================
# Configuration - Variables d'environnement supportées
# ============================================================================
readonly SCRIPT_NAME=$(basename "$0")
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN:-${JENKINS_PASS:-}}"
readonly LOG_FILE="${JENKINS_MONITOR_LOG:-/tmp/jenkins-jobs-monitor.log}" # Changé vers /tmp pour éviter les erreurs de permission
readonly REPORT_FILE="${JENKINS_MONITOR_REPORT:-/tmp/jenkins-jobs-report.json}"
readonly MAX_LOG_SIZE="${JENKINS_MAX_LOG_SIZE:-10485760}"
readonly REQUEST_TIMEOUT="${JENKINS_REQUEST_TIMEOUT:-10}"
readonly RETRY_COUNT="${JENKINS_RETRY_COUNT:-3}"
readonly RETRY_DELAY="${JENKINS_RETRY_DELAY:-2}"

# Couleurs (désactivées si NO_COLOR est défini)
if [[ -z "${NO_COLOR:-}" ]] && [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly MAGENTA='\033[0;35m'
    readonly NC='\033[0m'
else
    readonly RED=''; readonly GREEN=''; readonly YELLOW=''
    readonly BLUE=''; readonly CYAN=''; readonly MAGENTA=''; readonly NC=''
fi

# Flags
VERBOSE=false
JSON_OUTPUT=false
WATCH_MODE=false
REFRESH_SEC=5
CRUMB=""

# ============================================================================
# Fonctions utilitaires
# ============================================================================

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_line="${timestamp} [${level}] ${message}"

    # Affiche dans le terminal
    echo -e "$log_line"
    # Tente d'écrire dans le fichier silencieusement
    echo -e "$log_line" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() { log "INFO" "$1"; }
log_error() { log "${RED}ERROR${NC}" "$1"; }
log_success() { log "${GREEN}SUCCESS${NC}" "$1"; }
log_warn() { log "${YELLOW}WARN${NC}" "$1"; }

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         SURVEILLANCE DES JOBS JENKINS                          ║"
    echo "╠════════════════════════════════════════════════════════════════════════════════╣"
    printf "║ %-30s ║ %-30s ║ %-10s ║ %-20s ║\n" "JOB" "STATUT" "BUILD #" "DERNIER RÉSULTAT"
    echo "╠════════════════════════════════════════════════════════════════════════════════╣"
}

print_footer() {
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    local total=$(curl_with_auth "${JENKINS_URL}/api/json" 2>/dev/null | grep -o '"name"' | wc -l)
    echo -e "${CYAN}📊 RÉSUMÉ : $total jobs${NC}"
}

# Fonction d'authentification unifiée avec gestion du crumb
curl_with_auth() {
    local url="$1"
    local method="${2:-GET}"
    local output=""
    local retry=0
    local data="${3:-}"

    local curl_opts=(
        -s
        -X "$method"
        --connect-timeout "$REQUEST_TIMEOUT"
        --max-time "$REQUEST_TIMEOUT"
    )

    # Ajouter authentification si token ou password fourni
    if [[ -n "$JENKINS_TOKEN" ]]; then
        curl_opts+=(--user "${JENKINS_USER}:${JENKINS_TOKEN}")
    fi

    # Ajouter le crumb s'il existe
    if [[ -n "$CRUMB" ]]; then
        local crumb_field=$(echo "$CRUMB" | cut -d':' -f1)
        local crumb_value=$(echo "$CRUMB" | cut -d':' -f2-)
        curl_opts+=(-H "${crumb_field}: ${crumb_value}")
    fi

    # Ajouter les données pour POST
    if [[ -n "$data" ]]; then
        curl_opts+=(-H "Content-Type: application/json" -d "$data")
    fi

    # Retry logic
    while [[ $retry -lt $RETRY_COUNT ]]; do
        output=$(curl "${curl_opts[@]}" "$url" 2>/dev/null) && break
        retry=$((retry + 1))
        [[ $retry -lt $RETRY_COUNT ]] && sleep "$RETRY_DELAY"
    done

    echo "$output"
}

# Récupération du crumb
get_crumb() {
    # Si pas de token fourni, pas besoin de crumb pour les GET
    if [[ -z "$JENKINS_TOKEN" ]]; then
        return 0
    fi

    local response=$(curl_with_auth "${JENKINS_URL}/crumbIssuer/api/json" 2>/dev/null)
    if [[ -n "$response" ]]; then
        local crumb_field=$(echo "$response" | grep -o '"crumbRequestField":"[^"]*"' | cut -d'"' -f4)
        local crumb_value=$(echo "$response" | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$crumb_field" ]] && [[ -n "$crumb_value" ]]; then
            CRUMB="${crumb_field}:${crumb_value}"
            log_info "✓ Crumb récupéré avec succès"
            return 0
        fi
    fi

    log_warn "Impossible de récupérer le crumb (peut nécessiter authentification)"
    return 1
}

get_status_icon() {
    local color="$1"
    case "$color" in
        "blue") echo -e "${GREEN}● SUCCÈS${NC}" ;;
        "blue_anime") echo -e "${BLUE}▶ EN COURS${NC}" ;;
        "red") echo -e "${RED}● ÉCHEC${NC}" ;;
        "red_anime") echo -e "${RED}▶ EN COURS (ECHEC)${NC}" ;;
        "yellow") echo -e "${YELLOW}⚠ INSTABLE${NC}" ;;
        "yellow_anime") echo -e "${YELLOW}▶ EN COURS (INSTABLE)${NC}" ;;
        "grey") echo -e "${MAGENTA}○ INACTIF${NC}" ;;
        "disabled") echo -e "${MAGENTA}⊘ DÉSACTIVÉ${NC}" ;;
        "notbuilt") echo -e "${MAGENTA}◌ NON BUILD${NC}" ;;
        *) echo -e "${NC}? INCONNU${NC}" ;;
    esac
}

get_job_color() {
    local job="$1"
    local encoded_job=$(printf '%s' "$job" | sed 's/\//%2F/g')
    local response=$(curl_with_auth "${JENKINS_URL}/job/${encoded_job}/api/json")
    echo "$response" | grep -o '"color":"[^"]*"' | cut -d'"' -f4 | head -1 | sed 's/notfound/grey/'
}

get_last_build_number() {
    local job="$1"
    local encoded_job=$(printf '%s' "$job" | sed 's/\//%2F/g')
    local response=$(curl_with_auth "${JENKINS_URL}/job/${encoded_job}/api/json")
    echo "$response" | grep -o '"number":[0-9]*' | head -1 | cut -d':' -f2 | sed 's/^$/0/'
}

get_last_build_result() {
    local job="$1"
    local encoded_job=$(printf '%s' "$job" | sed 's/\//%2F/g')
    local response=$(curl_with_auth "${JENKINS_URL}/job/${encoded_job}/lastBuild/api/json" 2>/dev/null)
    echo "$response" | grep -o '"result":"[^"]*"' | cut -d'"' -f4 | sed 's|^$|N/A|'
}

check_jenkins() {
    log_info "Vérification de la connexion à Jenkins..."
    local response=$(curl_with_auth "${JENKINS_URL}/api/json")
    if [[ -z "$response" ]] || echo "$response" | grep -qi "Authentication required\|HTTP 403"; then
        echo -e "${RED}❌ Jenkins n'est pas accessible sur ${JENKINS_URL}${NC}"
        echo -e "${YELLOW}💡 Astuce: Définissez les variables d'environnement:${NC}"
        echo "   export JENKINS_TOKEN='votre_token'"
        echo "   export JENKINS_URL='http://votre_jenkins:8080'"
        return 1
    fi
    log_success "✓ Jenkins accessible"
    return 0
}

list_jobs() {
    curl_with_auth "${JENKINS_URL}/api/json" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sort
}

display_jobs() {
    local jobs=$(list_jobs)
    local count=0
    local failed_jobs=0
    local success_jobs=0

    print_header

    while IFS= read -r job; do
        [[ -z "$job" ]] && continue
        local color=$(get_job_color "$job")
        local status=$(get_status_icon "$color")
        local build_num=$(get_last_build_number "$job")
        local build_result=$(get_last_build_result "$job")

        printf "║ %-30s ║ %-30s ║ %-10s ║ %-20s ║\n" "$job" "$status" "$build_num" "$build_result"

        case "$color" in
            "blue"|"blue_anime") success_jobs=$((success_jobs + 1)) ;;
            "red"|"red_anime") failed_jobs=$((failed_jobs + 1)) ;;
        esac
        count=$((count + 1))

    done <<< "$jobs"

    print_footer
    echo -e "${CYAN}📈 STATS: ${GREEN}$success_jobs succès${NC} | ${RED}$failed_jobs échecs${NC} | Total: $count${NC}"
}

display_json() {
    local first=true
    echo '{ "jobs": ['

    while IFS= read -r job; do
        [[ -z "$job" ]] && continue
        $first || echo ','
        first=false
        local color=$(get_job_color "$job")
        local build_num=$(get_last_build_number "$job")
        local build_result=$(get_last_build_result "$job")

        cat <<EOF
        {
            "name": "$job",
            "status": "${color:-unknown}",
            "last_build": ${build_num:-0},
            "last_result": "${build_result:-N/A}"
        }
EOF
    done <<< "$(list_jobs)"

    echo '] }' | jq '.' > "$REPORT_FILE" 2>/dev/null || cat > "$REPORT_FILE" <<< '{"error":"jq not installed"}'
    echo '] }'
}

watch_jobs() {
    while true; do
        clear
        echo -e "${CYAN}🔄 Rafraîchissement toutes les ${REFRESH_SEC} secondes (Ctrl+C pour quitter)${NC}"
        echo -e "${CYAN}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${CYAN}🔐 Utilisateur: ${JENKINS_USER} | URL: ${JENKINS_URL}${NC}"
        display_jobs
        sleep "$REFRESH_SEC"
    done
}

show_usage() {
    cat << EOF
╔═══════════════════════════════════════════════════════════════════════════╗
║                    JENKINS JOBS MONITOR - USAGE                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Usage: $SCRIPT_NAME [OPTIONS]                                             ║
║                                                                           ║
║ Options:                                                                  ║
║   --url=<url>       URL de Jenkins (défaut: http://localhost:8080)       ║
║   --user=<user>     Utilisateur Jenkins (défaut: admin)                   ║
║   --password=<pwd>  Mot de passe ou token Jenkins                        ║
║   --json            Sortie au format JSON                                ║
║   --watch           Mode surveillance (rafraîchissement auto)            ║
║   --refresh=<sec>   Intervalle de rafraîchissement (défaut: 5s)          ║
║   --verbose, -v     Mode verbeux                                         ║
║   --help, -h        Affiche cette aide                                   ║
║                                                                           ║
║ Variables d'environnement supportées:                                     ║
║   JENKINS_URL       URL de Jenkins                                       ║
║   JENKINS_USER      Utilisateur Jenkins                                  ║
║   JENKINS_TOKEN     Token API Jenkins (recommandé)                       ║
║   JENKINS_PASS      Alternative à JENKINS_TOKEN (moins sécurisé)         ║
║   JENKINS_REQUEST_TIMEOUT  Timeout des requêtes (défaut: 10s)            ║
║   NO_COLOR           Désactive les couleurs                              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
}

# ============================================================================
# Initialisation et Main
# ============================================================================

# Rotation des logs
if [[ -f "$LOG_FILE" ]] && [[ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null || true
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url=*) JENKINS_URL="${1#*=}" ;;
        --user=*) JENKINS_USER="${1#*=}" ;;
        --password=*) JENKINS_TOKEN="${1#*=}" ;;
        --json) JSON_OUTPUT=true ;;
        --watch) WATCH_MODE=true ;;
        --refresh=*) REFRESH_SEC="${1#*=}" ;;
        --verbose|-v) VERBOSE=true; set -x ;;
        --help|-h) show_usage; exit 0 ;;
        *) echo "Option inconnue: $1"; show_usage; exit 1 ;;
    esac
    shift
done

# Affichage de la bannière
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     🚀 JENKINS JOBS MONITOR - NINJA DevOps EDITION 🚀           ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log_info "=== Démarrage de la surveillance Jenkins ==="
log_info "URL: ${JENKINS_URL}"
log_info "User: ${JENKINS_USER}"
[[ -n "$JENKINS_TOKEN" ]] && log_info "Token: ************"

# Récupération du crumb
get_crumb || true

# Vérification de Jenkins
if ! check_jenkins; then
    exit 1
fi

# Exécution du mode demandé
if [[ "$WATCH_MODE" = true ]]; then
    watch_jobs
elif [[ "$JSON_OUTPUT" = true ]]; then
    display_json
else
    display_jobs
fi

log_success "=== Surveillance terminée ==="
