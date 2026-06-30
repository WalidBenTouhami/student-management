#!/bin/bash
# fix-endpoints.sh — Diagnostique et fixe les endpoints défaillants

MKIP=$(minikube ip 2>/dev/null)
echo "=== 1. Routes disponibles Spring Boot ==="
curl -sf --max-time 8 "http://$MKIP:30080/student/actuator/mappings" \
  | python3 -m json.tool \
  | grep '"predicate"' \
  | sort -u \
  | head -30

echo ""
echo "=== 2. Test Jenkins Prometheus token ==="
echo "--- Test avec token actuel (basic auth: prometheus-token:11fd280a...) ---"
curl -v --max-time 8 \
  -u "prometheus-token:11fd280a42943b4f20184833083de7e3c8" \
  "http://192.168.56.10:8080/prometheus/" 2>&1 | grep -E "< HTTP|Authorization|WWW-Auth|error"

echo ""
echo "--- Test sans auth (pour voir si token est nécessaire) ---"
curl -sf --max-time 8 "http://192.168.56.10:8080/prometheus/" -o /dev/null -w "HTTP: %{http_code}\n"

echo ""
echo "=== 3. Test SonarQube Monitoring token ==="
echo "--- Test avec token sqa_ comme password (username vide) ---"
curl -v --max-time 8 \
  -u "sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e:" \
  "http://192.168.56.10:9000/api/monitoring/metrics" 2>&1 | grep -E "< HTTP|error|{" | head -5

echo ""
echo "--- Test avec token comme bearer ---"
curl -sf --max-time 8 \
  -H "Authorization: Bearer sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e" \
  "http://192.168.56.10:9000/api/monitoring/metrics" -w "\nHTTP: %{http_code}\n" | tail -3

echo ""
echo "--- Test passcode SonarQube (token comme passcode) ---"
curl -sf --max-time 8 \
  "http://192.168.56.10:9000/api/monitoring/metrics?passcode=sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e" \
  -w "\nHTTP: %{http_code}\n" | tail -3

echo ""
echo "=== 4. SonarQube: vérifier si endpoint monitoring existe ==="
curl -sf --max-time 8 -u "admin:admin" \
  "http://192.168.56.10:9000/api/monitoring/metrics" -w "\nHTTP: %{http_code}\n" | tail -3

echo "=== DONE ==="
