#!/bin/bash
# scripts/check-health.sh
# Vérification complète de la santé des conteneurs et pods

echo "🏥 VÉRIFICATION DE LA SANTÉ DES CONTENEURS ET PODS"
echo "=================================================="
echo ""

# ============================================================
# 1. CONTENEURS DOCKER
# ============================================================
echo "🐳 1. CONTENEURS DOCKER EN COURS D'EXÉCUTION"
echo "---------------------------------------------"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "📊 Statistiques Docker :"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""

# ============================================================
# 2. PODS KUBERNETES
# ============================================================
echo "☸️ 2. PODS KUBERNETES"
echo "---------------------"
kubectl get pods -n devops-tools -o wide
echo ""

# ============================================================
# 3. SERVICES KUBERNETES
# ============================================================
echo "🌐 3. SERVICES KUBERNETES"
echo "--------------------------"
kubectl get svc -n devops-tools
echo ""

# ============================================================
# 4. DÉPLOIEMENTS KUBERNETES
# ============================================================
echo "📦 4. DÉPLOIEMENTS KUBERNETES"
echo "------------------------------"
kubectl get deployments -n devops-tools
echo ""

# ============================================================
# 5. ÉVÉNEMENTS RÉCENTS
# ============================================================
echo "📋 5. ÉVÉNEMENTS RÉCENTS (10 derniers)"
echo "----------------------------------------"
kubectl get events -n devops-tools --sort-by='.lastTimestamp' | tail -10
echo ""

# ============================================================
# 6. VÉRIFICATION DES PODS EN ÉCHEC
# ============================================================
echo "⚠️ 6. PODS EN ÉCHEC"
echo "-------------------"
kubectl get pods -n devops-tools | grep -E "CrashLoopBackOff|Error|ImagePullBackOff|Pending" || echo "✅ Aucun pod en échec"
echo ""

# ============================================================
# 7. LOGS DES DERNIERS PODS
# ============================================================
echo "📄 7. LOGS DES DERNIERS PODS (Spring App)"
echo "------------------------------------------"
kubectl logs -l app=spring-app -n devops-tools --tail=10 2>/dev/null || echo "⚠️ Aucun log disponible"
echo ""

echo "✅ Vérification terminée !"
