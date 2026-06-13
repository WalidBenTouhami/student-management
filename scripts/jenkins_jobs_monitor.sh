#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  Student Management — Jenkins + Kubernetes Monitor
#  Usage: ./scripts/jenkins_jobs_monitor.sh [OPTIONS]
#
#  Options:
#    -u  Jenkins URL         (default: http://localhost:8080)
#    -j  Job name            (default: student-management)
#    -n  K8s namespace       (default: student-management)
#    -w  Watch interval (s)  (default: 10)
#    -h  Show help
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JOB_NAME="${JOB_NAME:-student-management}"
K8S_NAMESPACE="${K8S_NAMESPACE:-student-management}"
WATCH_INTERVAL=10
MINIKUBE_IP=""

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No color

# ── Parse args ────────────────────────────────────────────────────────────────
while getopts "u:j:n:w:h" opt; do
    case $opt in
        u) JENKINS_URL="$OPTARG" ;;
        j) JOB_NAME="$OPTARG" ;;
        n) K8S_NAMESPACE="$OPTARG" ;;
        w) WATCH_INTERVAL="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -u  Jenkins URL         (default: http://localhost:8080)
  -j  Job name            (default: student-management)
  -n  K8s namespace       (default: student-management)
  -w  Watch interval (s)  (default: 10)
  -h  Show this help

Environment variables:
  JENKINS_URL, JOB_NAME, K8S_NAMESPACE
  JENKINS_USER, JENKINS_TOKEN (for authenticated requests)
  ACTUATOR_USER, ACTUATOR_PASSWORD (for health check)
EOF
}

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
    local title="$1"
    local width=70
    local line
    line=$(printf '═%.0s' $(seq 1 $width))
    echo -e "\n${CYAN}${BOLD}╔${line}╗${NC}"
    printf "${CYAN}${BOLD}║  %-66s  ║${NC}\n" "$title"
    echo -e "${CYAN}${BOLD}╚${line}╝${NC}"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}── $1 ──────────────────────────────────────────────────────${NC}"
}

status_color() {
    local status="$1"
    case "$status" in
        SUCCESS|UP|Running|PASSED)  echo -e "${GREEN}${status}${NC}" ;;
        FAILURE|DOWN|CRITICAL|FAILED) echo -e "${RED}${status}${NC}" ;;
        UNSTABLE|WARNING|Pending)   echo -e "${YELLOW}${status}${NC}" ;;
        *)                          echo -e "${CYAN}${status}${NC}" ;;
    esac
}

jenkins_api() {
    local path="$1"
    local auth_header=""
    if [[ -n "${JENKINS_USER:-}" && -n "${JENKINS_TOKEN:-}" ]]; then
        auth_header="-u ${JENKINS_USER}:${JENKINS_TOKEN}"
    fi
    # shellcheck disable=SC2086
    curl -sf $auth_header "${JENKINS_URL}${path}" 2>/dev/null || echo "{}"
}

# ── Jenkins Status ─────────────────────────────────────────────────────────────
show_jenkins_status() {
    print_section "Jenkins Pipeline Status"

    # Check Jenkins reachability
    if ! curl -sf --connect-timeout 3 "${JENKINS_URL}" > /dev/null 2>&1; then
        echo -e "  ${RED}❌ Jenkins unreachable at ${JENKINS_URL}${NC}"
        return
    fi
    echo -e "  ${GREEN}✅ Jenkins online: ${JENKINS_URL}${NC}"

    # Get last build info
    local build_json
    build_json=$(jenkins_api "/job/${JOB_NAME}/lastBuild/api/json" 2>/dev/null || echo "{}")

    if [[ "$build_json" == "{}" ]]; then
        echo -e "  ${YELLOW}⚠️  Job '${JOB_NAME}' not found or no builds yet${NC}"
        return
    fi

    local build_num result duration timestamp url
    build_num=$(echo "$build_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('number','?'))" 2>/dev/null || echo "?")
    result=$(echo "$build_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result','IN_PROGRESS') or 'IN_PROGRESS')" 2>/dev/null || echo "?")
    duration=$(echo "$build_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(round(d.get('duration',0)/1000/60,1))" 2>/dev/null || echo "0")
    url=$(echo "$build_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('url',''))" 2>/dev/null || echo "")

    echo ""
    printf "  %-20s %s\n" "Job:" "${BOLD}${JOB_NAME}${NC}"
    printf "  %-20s %s\n" "Last Build:" "#${build_num}"
    printf "  %-20s " "Status:"
    status_color "$result"
    printf "  %-20s %s\n" "Duration:" "${duration} min"
    printf "  %-20s %s\n" "URL:" "${url}"

    # Show last 3 builds
    echo ""
    echo -e "  ${BOLD}Last builds:${NC}"
    for i in 1 2 3; do
        local b_json
        b_json=$(jenkins_api "/job/${JOB_NAME}/lastBuild~${i}/api/json" 2>/dev/null || echo "{}")
        local b_num b_res
        b_num=$(echo "$b_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('number','?'))" 2>/dev/null || echo "?")
        b_res=$(echo "$b_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result','?') or '?')" 2>/dev/null || echo "?")
        [[ "$b_num" == "?" ]] && continue
        printf "    Build #%-6s " "${b_num}"
        status_color "$b_res"
    done
}

# ── Kubernetes Status ──────────────────────────────────────────────────────────
show_k8s_status() {
    print_section "Kubernetes Cluster Status"

    if ! kubectl cluster-info > /dev/null 2>&1; then
        echo -e "  ${RED}❌ kubectl not available or cluster not reachable${NC}"
        return
    fi

    # Get Minikube IP
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅ Cluster reachable | Minikube IP: ${BOLD}${MINIKUBE_IP}${NC}"

    # Pods
    echo ""
    echo -e "  ${BOLD}Pods (namespace: ${K8S_NAMESPACE}):${NC}"
    if kubectl get pods -n "$K8S_NAMESPACE" --no-headers 2>/dev/null | head -20 | while read -r line; do
        local pod_name status ready
        pod_name=$(echo "$line" | awk '{print $1}')
        ready=$(echo "$line" | awk '{print $2}')
        status=$(echo "$line" | awk '{print $3}')
        printf "    %-50s %-12s " "$pod_name" "$ready"
        status_color "$status"
    done; then
        :
    else
        echo -e "    ${YELLOW}No pods found in namespace ${K8S_NAMESPACE}${NC}"
    fi

    # Services
    echo ""
    echo -e "  ${BOLD}Services:${NC}"
    kubectl get svc -n "$K8S_NAMESPACE" --no-headers 2>/dev/null | while read -r line; do
        printf "    %s\n" "$line"
    done || echo -e "    ${YELLOW}No services found${NC}"

    # HPA
    echo ""
    echo -e "  ${BOLD}HPA (HorizontalPodAutoscaler):${NC}"
    kubectl get hpa -n "$K8S_NAMESPACE" 2>/dev/null || echo -e "    ${YELLOW}No HPA found${NC}"

    # Helm releases
    echo ""
    echo -e "  ${BOLD}Helm Releases:${NC}"
    helm list -n "$K8S_NAMESPACE" 2>/dev/null || echo -e "    ${YELLOW}helm not available${NC}"
}

# ── Application Health ─────────────────────────────────────────────────────────
show_app_health() {
    print_section "Application Health"

    [[ -z "$MINIKUBE_IP" || "$MINIKUBE_IP" == "unknown" ]] && \
        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")

    local base_url="http://${MINIKUBE_IP}:30089/student"
    local auth=""
    if [[ -n "${ACTUATOR_USER:-}" && -n "${ACTUATOR_PASSWORD:-}" ]]; then
        auth="-u ${ACTUATOR_USER}:${ACTUATOR_PASSWORD}"
    fi

    echo -e "  Checking: ${CYAN}${base_url}/actuator/health${NC}"

    # shellcheck disable=SC2086
    local health_response
    # shellcheck disable=SC2086
    health_response=$(curl -sf --connect-timeout 5 $auth "${base_url}/actuator/health" 2>/dev/null || echo "")

    if [[ -z "$health_response" ]]; then
        echo -e "  ${RED}❌ Application not reachable${NC}"
        return
    fi

    local status
    status=$(echo "$health_response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    printf "  Status: "
    status_color "$status"

    # Liveness
    # shellcheck disable=SC2086
    local liveness
    liveness=$(curl -sf --connect-timeout 3 $auth "${base_url}/actuator/health/liveness" 2>/dev/null | \
               python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "?")
    printf "  Liveness: "
    status_color "$liveness"

    # Readiness
    # shellcheck disable=SC2086
    local readiness
    readiness=$(curl -sf --connect-timeout 3 $auth "${base_url}/actuator/health/readiness" 2>/dev/null | \
                python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "?")
    printf "  Readiness: "
    status_color "$readiness"

    # Metrics spot-check
    # shellcheck disable=SC2086
    local metric_count
    metric_count=$(curl -sf --connect-timeout 3 "${base_url}/actuator/prometheus" 2>/dev/null | grep -c "^# HELP" || echo "0")
    echo -e "  Prometheus metrics: ${CYAN}${metric_count} metrics exposed${NC}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    while true; do
        clear
        print_header "Student Management — DevOps Monitor  [$(date '+%Y-%m-%d %H:%M:%S')]"
        echo -e "  ${BOLD}Jenkins:${NC} ${JENKINS_URL}  |  ${BOLD}K8s NS:${NC} ${K8S_NAMESPACE}  |  ${BOLD}Refresh:${NC} ${WATCH_INTERVAL}s"

        show_jenkins_status
        show_k8s_status
        show_app_health

        print_section "Quick Commands"
        echo "  make k8s-status     → kubectl resources"
        echo "  make k8s-logs       → follow app logs"
        echo "  make k8s-rollback   → rollback Helm release"
        echo "  make health         → curl health endpoint"
        echo ""
        echo -e "  ${YELLOW}Press Ctrl+C to exit${NC}  |  Next refresh in ${WATCH_INTERVAL}s..."

        sleep "$WATCH_INTERVAL"
    done
}

# Run once if -o flag, else loop
if [[ "${1:-}" == "-o" ]]; then
    print_header "Student Management — DevOps Monitor  [$(date '+%Y-%m-%d %H:%M:%S')]"
    show_jenkins_status
    show_k8s_status
    show_app_health
else
    main
fi
