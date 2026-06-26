#!/bin/bash
# scripts/k8s-expose.sh
# Expose automatiquement un service Kubernetes en trouvant un port libre sur la VM

SERVICE=$1
TARGET_PORT=$2
NAMESPACE=${3:-devops-tools}

if [ -z "$SERVICE" ] || [ -z "$TARGET_PORT" ]; then
    echo "Usage: $0 <service-name> <target-port> [namespace]"
    echo "Exemple: $0 grafana-service 3000 devops-tools"
    exit 1
fi

LOCAL_PORT=$TARGET_PORT

# Trouver le premier port libre
while netstat -tuln 2>/dev/null | grep -qE ":$LOCAL_PORT\b"; do
    echo "⚠️  Le port $LOCAL_PORT est déjà utilisé. Essai du port $((LOCAL_PORT+1))..."
    LOCAL_PORT=$((LOCAL_PORT+1))
done

echo "============================================================"
echo "✅ Port libre trouvé : $LOCAL_PORT"
echo "🌐 Vous pouvez accéder au service via : http://192.168.56.10:$LOCAL_PORT"
echo "============================================================"
echo "🔄 Lancement du port-forwarding (Faites Ctrl+C pour arrêter)..."

kubectl port-forward --address 0.0.0.0 svc/$SERVICE $LOCAL_PORT:$TARGET_PORT -n $NAMESPACE
