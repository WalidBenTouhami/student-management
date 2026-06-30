#!/bin/bash
# =================================================================
# audit-endpoints.sh — Audit complet de tous les endpoints du projet
# =================================================================

MKIP=$(minikube ip 2>/dev/null)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

check() {
  local name="$1" url="$2" header="${3:-}"
  local opts="-sf --max-time 8 -w '\nHTTP_CODE:%{http_code}'"
  if [ -n "$header" ]; then opts="$opts -H '$header'"; fi
  result=$(curl -sf --max-time 8 -w "\nHTTP_CODE:%{http_code}" ${header:+-H "$header"} "$url" 2>&1)
  code=$(echo "$result" | grep 'HTTP_CODE:' | cut -d: -f2)
  body=$(echo "$result" | grep -v 'HTTP_CODE:' | head -1)
  if echo "$code" | grep -qE '^(200|204|302)$'; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    echo "         URL: $url  HTTP $code"
    echo "         $body" | cut -c1-100
    PASS=$((PASS+1))
  else
    echo -e "  ${RED}[FAIL]${NC} $name"
    echo "         URL: $url  HTTP ${code:-TIMEOUT/ERR}"
    echo "         $body" | cut -c1-100
    FAIL=$((FAIL+1))
  fi
  echo ""
}

echo "================================================================="
echo " AUDIT ENDPOINTS — $(date)"
echo " Minikube IP: $MKIP"
echo "================================================================="

# ── K8s NodePort ──────────────────────────────────────────────────
echo -e "\n${YELLOW}=== K8s NodePort Endpoints ===${NC}"
check "Spring Boot Health"       "http://$MKIP:30080/student/actuator/health"
check "Spring Boot Info"         "http://$MKIP:30080/student/actuator/info"
check "Spring Boot Prometheus"   "http://$MKIP:30080/student/actuator/prometheus"
check "Spring Boot API (students)" "http://$MKIP:30080/student/students"
check "Prometheus Ready"         "http://$MKIP:30090/-/ready"
check "Prometheus Healthy"       "http://$MKIP:30090/-/healthy"
check "Prometheus UI"            "http://$MKIP:30090/graph"
check "Grafana Health"           "http://$MKIP:30300/api/health"
check "Grafana Login"            "http://$MKIP:30300/login"

# ── Ingress ──────────────────────────────────────────────────────
echo -e "\n${YELLOW}=== Ingress Endpoints ===${NC}"
check "Ingress: api.student.local health" "http://$MKIP/student/actuator/health" "Host: api.student.local"
check "Ingress: grafana.student.local"    "http://$MKIP/"                        "Host: grafana.student.local"

# ── Services externes ─────────────────────────────────────────────
echo -e "\n${YELLOW}=== External Services (192.168.56.10) ===${NC}"
check "SonarQube API status"  "http://192.168.56.10:9000/api/system/status"
check "SonarQube UI"          "http://192.168.56.10:9000"
check "Jenkins UI"            "http://192.168.56.10:8080/login"
check "Jenkins Prometheus"    "http://192.168.56.10:8080/prometheus/"

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
    icon   = '[OK] ' if health == 'up' else '[DOWN]'
    print(f'  {icon} {job:20s} {url}')
    if last:
        print(f'         Error: {last}')
" 2>/dev/null || echo "  python3 unavailable, raw output:"
else
  echo -e "  ${RED}[FAIL]${NC} Cannot reach Prometheus API"
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "================================================================="
echo -e " RÉSULTAT: ${GREEN}$PASS OK${NC} / ${RED}$FAIL FAILED${NC}"
echo "================================================================="
