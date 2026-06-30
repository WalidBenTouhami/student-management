#!/bin/bash
# scripts/audit-api.sh
# Audit des configurations API

echo "🌐 AUDIT DES CONFIGURATIONS API"
echo "================================"
echo ""

# ============================================================
# 1. SPRING BOOT ACTUATOR
# ============================================================
echo "📄 1. VÉRIFICATION DES ENDPOINTS SPRING BOOT"
echo "---------------------------------------------"

if [ -f "src/main/resources/application.properties" ]; then
    echo "📄 Vérification de application.properties"
    
    # Vérification Actuator
    if grep -q "management.endpoints.web.exposure.include" src/main/resources/application.properties; then
        endpoints=$(grep "management.endpoints.web.exposure.include" src/main/resources/application.properties | cut -d'=' -f2)
        echo "   ✅ Endpoints exposés : $endpoints"
        if [[ "$endpoints" == "*" ]]; then
            echo "   ⚠️  Tous les endpoints sont exposés (risque de sécurité !)"
        fi
    else
        echo "   ⚠️  Actuator non configuré"
    fi
    
    # Vérification Swagger
    if grep -q "springdoc" src/main/resources/application.properties; then
        echo "   ✅ Swagger configuré"
        swagger_path=$(grep "springdoc.swagger-ui.path" src/main/resources/application.properties | cut -d'=' -f2)
        echo "      - Swagger UI : $swagger_path"
    else
        echo "   ⚠️  Swagger non configuré"
    fi
    
    # Vérification CORS
    if grep -q "spring.web.cors" src/main/resources/application.properties; then
        echo "   ✅ CORS configuré"
    else
        echo "   ⚠️  CORS non configuré"
    fi
fi

echo ""

# ============================================================
# 2. KUBERNETES SERVICES
# ============================================================
echo "📄 2. VÉRIFICATION DES SERVICES KUBERNETES"
echo "--------------------------------------------"

if [ -f "k8s/service.yaml" ]; then
    echo "📄 Vérification de k8s/service.yaml"
    
    # Type de service
    service_type=$(grep -E "type:" k8s/service.yaml | awk '{print $2}')
    echo "   - Type : $service_type"
    
    # Ports exposés
    echo "   - Ports exposés :"
    grep -E "port:|nodePort:" k8s/service.yaml | sed 's/^/      /'
fi

echo ""

# ============================================================
# 3. HELM VALUES
# ============================================================
echo "📄 3. VÉRIFICATION DES CONFIGURATIONS HELM"
echo "--------------------------------------------"

if [ -f "helm/student-management/values.yaml" ]; then
    echo "📄 Vérification de helm/student-management/values.yaml"
    
    # Ports configurés
    if grep -q "service:" helm/student-management/values.yaml; then
        echo "   ✅ Service configuré"
        grep -A 5 "service:" helm/student-management/values.yaml | head -6
    fi
    
    # Ingress configuré
    if grep -q "ingress:" helm/student-management/values.yaml; then
        echo "   ✅ Ingress configuré"
    else
        echo "   ⚠️  Ingress non configuré"
    fi
fi

echo ""

# ============================================================
# 4. CONFIGURATION DOCKER
# ============================================================
echo "📄 4. VÉRIFICATION DE LA CONFIGURATION DOCKER"
echo "-----------------------------------------------"

if [ -f "docker/docker-compose.yml" ]; then
    echo "📄 Vérification de docker/docker-compose.yml"
    
    # Ports exposés
    echo "   - Services Docker :"
    grep -E "^\s+ports:" docker/docker-compose.yml -B 5 | grep -E "services:|ports:" | sed 's/^/     /'
fi

echo ""

# ============================================================
# 5. CONFIGURATION PROMETHEUS
# ============================================================
echo "📄 5. VÉRIFICATION DE PROMETHEUS"
echo "----------------------------------"

if [ -f "docker/prometheus/prometheus.yml" ]; then
    echo "📄 Vérification de docker/prometheus/prometheus.yml"
    
    # Jobs configurés
    jobs=$(grep -c "job_name:" docker/prometheus/prometheus.yml)
    echo "   - $jobs job(s) configuré(s) :"
    grep "job_name:" docker/prometheus/prometheus.yml | sed 's/^/      /'
fi

echo ""

# ============================================================
# 6. CONFIGURATION GRAFANA
# ============================================================
echo "📄 6. VÉRIFICATION DE GRAFANA"
echo "--------------------------------"

if [ -d "docker/grafana" ]; then
    echo "📄 Vérification du dossier grafana"
    
    # Data sources
    if [ -f "docker/grafana/provisioning/datasources/datasource.yml" ]; then
        echo "   ✅ Source de données configurée"
        grep "name:" docker/grafana/provisioning/datasources/datasource.yml | head -3
    else
        echo "   ⚠️  Aucune source de données configurée"
    fi
    
    # Dashboards
    if [ -d "docker/grafana/dashboards" ]; then
        dashboards=$(find docker/grafana/dashboards -name "*.json" | wc -l)
        echo "   - $dashboards dashboard(s) disponible(s)"
    fi
fi

echo ""
echo "✅ Audit API terminé !"
