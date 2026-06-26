#!/bin/bash
# scripts/ingress-tunnel.sh

PORT=80
SERVICE="service/ingress-nginx-controller"
NAMESPACE="ingress-nginx"

echo "🔍 Vérification du port $PORT..."

# Nettoyage automatique : tuer les anciens processus "kubectl port-forward" suspendus
sudo pkill -f "port-forward.*$SERVICE" 2>/dev/null || true
sleep 1

# Recherche d'un port libre si le port 80 est toujours occupé par un autre outil
while sudo lsof -i :$PORT >/dev/null 2>&1 || sudo netstat -tuln | grep ":$PORT " >/dev/null 2>&1; do
    echo "⚠️ Le port $PORT est occupé par une autre application. Recherche d'un nouveau port..."
    PORT=$((PORT + 1))
done

echo "✅ Port $PORT disponible ! Ouverture du tunnel Ingress..."
echo "=========================================================="
if [ "$PORT" -eq 80 ]; then
    echo "🌐 Swagger   : http://api.student.local/student/swagger-ui.html"
    echo "📈 Grafana   : http://grafana.student.local"
else
    echo "🌐 Swagger   : http://api.student.local:$PORT/student/swagger-ui.html"
    echo "📈 Grafana   : http://grafana.student.local:$PORT"
fi
echo "🚀 Jenkins   : http://192.168.56.10:8080"
echo "🔍 SonarQube : http://192.168.56.10:9000"
echo "📊 Prometheus: http://192.168.56.10:30090"
echo "=========================================================="
echo "⚠️  GARDEZ CE TERMINAL OUVERT ⚠️"

sudo kubectl --kubeconfig=/home/vagrant/.kube/config port-forward --address 0.0.0.0 -n $NAMESPACE $SERVICE $PORT:80
