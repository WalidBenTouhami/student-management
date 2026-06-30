#!/bin/bash
# auth-test.sh — Tester les credentials Jenkins et SonarQube

echo "=== Restart Prometheus pour recharger la ConfigMap ==="
kubectl rollout restart deployment/prometheus -n devops-tools
echo "Attente 15s..."
sleep 15

echo ""
echo "=== Test Jenkins Prometheus endpoint ==="
echo "--- admin:apitoken (sans slash final) ---"
curl -v --max-time 8 \
  -u "admin:${JENKINS_TOKEN:-<INSERT_JENKINS_TOKEN>}" \
  "http://192.168.56.10:8080/prometheus" 2>&1 | grep -E "^< HTTP|WWW-Authenticate|Unauthorized"

echo ""
echo "--- Test si le plugin Prometheus est installé ---"
curl -sf --max-time 8 -u "admin:${JENKINS_TOKEN:-<INSERT_JENKINS_TOKEN>}" \
  "http://192.168.56.10:8080/api/json?tree=jobs[name]" -o /dev/null -w "Jenkins API: HTTP %{http_code}\n"

echo ""
echo "=== Test SonarQube /api/monitoring/metrics ==="
for pass in admin sonar esprit admin123 walid@123; do
  code=$(curl -sf --max-time 5 -u "admin:$pass" \
    "http://192.168.56.10:9000/api/monitoring/metrics" \
    -o /dev/null -w "%{http_code}")
  echo "  admin:$pass -> HTTP $code"
done

echo ""
echo "=== Vérifier les scrape targets Prometheus (après restart) ==="
MKIP=$(minikube ip 2>/dev/null)
sleep 5
curl -sf --max-time 8 "http://$MKIP:30090/api/v1/targets" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data.get('data', {}).get('activeTargets', []):
    health = t.get('health', '?')
    job    = t.get('labels', {}).get('job', '?')
    url    = t.get('scrapeUrl', '?')
    err    = t.get('lastError', '')
    icon   = '[OK] ' if health == 'up' else '[DOWN]'
    print(f'  {icon} {job:20s} {url}')
    if err:
        print(f'         Error: {err}')
" 2>/dev/null

echo ""
echo "=== DONE ==="
