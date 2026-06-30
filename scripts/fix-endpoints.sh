#!/bin/bash
# deep-fix.sh — Corriger les tokens Jenkins et SonarQube

MKIP=$(minikube ip 2>/dev/null)

echo "=== 1. Spring Boot: trouver les vraies routes ==="
# Activer les mappings dans actuator si pas exposé
curl -sf --max-time 8 "http://$MKIP:30080/student/actuator" | python3 -m json.tool 2>/dev/null | grep -E '"href"' | head -20

echo ""
echo "=== 2. Tester routes Spring Boot API ==="
for route in "/student/api/students" "/student/api/student" "/student/student" "/student/students" "/student/api/enrollment" "/student/api/enrollments"; do
  code=$(curl -sf --max-time 5 "http://$MKIP:30080$route" -o /dev/null -w "%{http_code}")
  echo "  $route -> HTTP $code"
done

echo ""
echo "=== 3. Jenkins: trouver le bon utilisateur pour le token Prometheus ==="
# Le token Jenkins doit être au format user:apitoken
# Testons avec admin:token
curl -sf --max-time 8 \
  -u "admin:11fd280a42943b4f20184833083de7e3c8" \
  "http://192.168.56.10:8080/prometheus/" -o /dev/null -w "admin:token -> HTTP %{http_code}\n"

# Testons aussi sans auth (possible si configuré)
curl -sf --max-time 8 \
  "http://192.168.56.10:8080/metrics" -o /dev/null -w "/metrics (no auth) -> HTTP %{http_code}\n"

echo ""
echo "=== 4. SonarQube: vérifier l'endpoint monitoring et les permissions ==="
# Le token sqa_ est un token de service — vérifier les permissions
curl -sf --max-time 8 \
  -H "Authorization: Bearer sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e" \
  "http://192.168.56.10:9000/api/authentication/validate" -w "\nHTTP: %{http_code}\n"

echo ""
# Vérifier si le token est valide avec une API simple
curl -sf --max-time 8 \
  -H "Authorization: Bearer sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e" \
  "http://192.168.56.10:9000/api/projects/search" -o /dev/null -w "projects/search -> HTTP %{http_code}\n"

# /api/monitoring/metrics nécessite le rôle "Execute Analysis" ou admin global
curl -sf --max-time 8 \
  -u "admin:admin" \
  "http://192.168.56.10:9000/api/monitoring/metrics" -w "\nadmin:admin -> HTTP %{http_code}\n" | tail -3

echo ""
echo "=== 5. SonarQube: version et passcode system ===" 
curl -sf --max-time 8 "http://192.168.56.10:9000/api/system/info" \
  -H "Authorization: Bearer sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e" \
  -o /dev/null -w "system/info with token -> HTTP %{http_code}\n"

echo "=== DONE ==="
