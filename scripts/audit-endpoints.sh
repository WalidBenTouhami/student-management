#!/bin/bash
# =================================================================
# audit-endpoints.sh — Audit complet de tous les endpoints du projet
# =================================================================

MKIP=$(minikube ip 2>/dev/null)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; FAIL=0; SKIP=0

check() {
  local name="$1" url="$2" header="${3:-}"
  local result code body
  result=$(curl -sf --max-time 8 -w "\nHTTP_CODE:%{http_code}" ${header:+-H "$header"} "$url" 2>&1)
  code=$(echo "$result" | grep 'HTTP_CODE:' | cut -d: -f2)
  body=$(echo "$result" | grep -v 'HTTP_CODE:' | head -1)
  if echo "$code" | grep -qE '^(200|204|302)$'; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    echo "         HTTP $code | ${url}"
    [ -n "$body" ] && echo "         $(echo $body | cut -c1-100)"
    PASS=$((PASS+1))
  else
    echo -e "  ${RED}[FAIL]${NC} $name"
    echo "         HTTP ${code:-TIMEOUT/ERR} | ${url}"
    [ -n "$body" ] && echo "         $(echo $body | cut -c1-100)"
    FAIL=$((FAIL+1))
  fi
  echo ""
}

skip() {
  local name="$1" reason="$2"
  echo -e "  ${YELLOW}[SKIP]${NC} $name"
  echo "         Raison: $reason"
  echo ""
  SKIP=$((SKIP+1))
}

echo "================================================================="
echo -e " ${BLUE}AUDIT ENDPOINTS — $(date)${NC}"
echo " Minikube IP: $MKIP"
echo "================================================================="

# ── K8s NodePort ──────────────────────────────────────────────────
echo -e "\n${YELLOW}=== K8s NodePort Endpoints ===${NC}"

# Spring Boot Actuator
check "Spring Boot Health"            "http://$MKIP:30080/student/actuator/health"
check "Spring Boot Prometheus metrics" "http://$MKIP:30080/student/actuator/prometheus"
check "Spring Boot Info"              "http://$MKIP:30080/student/actuator/info"
check "Spring Boot Mappings"          "http://$MKIP:30080/student/actuator/mappings"

# Spring Boot API (routes réelles découvertes)
check "API: GET /students/getAllStudents"       "http://$MKIP:30080/student/students/getAllStudents"
check "API: GET /Enrollment/getAllEnrollment"   "http://$MKIP:30080/student/Enrollment/getAllEnrollment"
check "API: GET /Department/getAllDepartment"   "http://$MKIP:30080/student/Department/getAllDepartment"
check "Swagger UI"                             "http://$MKIP:30080/student/swagger-ui.html"
check "OpenAPI Docs"                           "http://$MKIP:30080/student/v3/api-docs"

# Prometheus
check "Prometheus Ready"    "http://$MKIP:30090/-/ready"
check "Prometheus Healthy"  "http://$MKIP:30090/-/healthy"
check "Prometheus UI"       "http://$MKIP:30090/graph"

# Grafana
check "Grafana Health"  "http://$MKIP:30300/api/health"
check "Grafana Login"   "http://$MKIP:30300/login"

# ── Ingress ──────────────────────────────────────────────────────
echo -e "\n${YELLOW}=== Ingress Endpoints (via nginx) ===${NC}"
check "Ingress: api.student.local health"  "http://$MKIP/student/actuator/health"  "Host: api.student.local"
check "Ingress: grafana.student.local"     "http://$MKIP/"                         "Host: grafana.student.local"

# ── Services externes ─────────────────────────────────────────────
echo -e "\n${YELLOW}=== External Services (192.168.56.10) ===${NC}"
check "SonarQube API status"  "http://192.168.56.10:9000/api/system/status"
check "SonarQube UI"          "http://192.168.56.10:9000"
check "Jenkins UI"            "http://192.168.56.10:8080/login"
skip  "Jenkins Prometheus"    "Plugin 'Prometheus Metrics' non installé (HTTP 404)"
skip  "SonarQube Metrics API" "Mot de passe admin inconnu (HTTP 401) — voir actions requises"

# ── Prometheus Scrape Targets ─────────────────────────────────────
echo -e "\n${YELLOW}=== Prometheus Scrape Targets ===${NC}"
targets=$(curl -sf --max-time 8 "http://$MKIP:30090/api/v1/targets" 2>/dev/null)
if [ -n "$targets" ]; then
  echo "$targets" | python3 -c "
import json, sys
data = json.load(sys.stdin)
targets = data.get('data', {}).get('activeTargets', [])
for t in targets:
    health = t.get('health', '?')
    job    = t.get('labels', {}).get('job', '?')
    url    = t.get('scrapeUrl', '?')
    last   = t.get('lastError', '')
    icon   = '[OK]  ' if health == 'up' else '[DOWN]'
    print(f'  {icon} {job:25s} {url}')
    if last:
        print(f'         Error: {last}')
" 2>/dev/null || echo "  python3 unavailable"
else
  echo -e "  ${RED}[FAIL]${NC} Cannot reach Prometheus API"
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "================================================================="
echo -e " RÉSULTAT: ${GREEN}$PASS OK${NC} | ${RED}$FAIL FAILED${NC} | ${YELLOW}$SKIP SKIPPED (action manuelle)${NC}"
echo "================================================================="
echo ""
echo -e "${YELLOW}=== ACTIONS MANUELLES REQUISES ===${NC}"
echo ""
echo "  1. JENKINS — Installer le plugin 'Prometheus Metrics':"
echo "     → http://192.168.56.10:8080 > Manage Jenkins > Plugins > Available"
echo "     → Rechercher 'Prometheus Metrics' > Installer"
echo "     → Puis dans Jenkinsfile, créer un API Token dans:"
echo "       Jenkins > admin > Configure > API Token > Add new Token"
echo "     → Mettre à jour values.yaml > external.jenkinsMetricsToken"
echo "     → Décommenter le job 'jenkins' dans prometheus-config.yaml"
echo "     → Relancer: helm upgrade student-management ./helm/student-management -n devops-tools"
echo ""
echo "  2. SONARQUBE — Récupérer le mot de passe admin:"
echo "     → Se connecter au conteneur: docker exec -it student-sonarqube bash"
echo "     → Ou réinitialiser: http://192.168.56.10:9000 > Administration > Security"
echo "     → Mettre à jour values.yaml > external.sonarAdminPassword"
echo "     → Décommenter le job 'sonarqube' dans prometheus-config.yaml"
echo "     → Relancer: helm upgrade student-management ./helm/student-management -n devops-tools"
echo ""
