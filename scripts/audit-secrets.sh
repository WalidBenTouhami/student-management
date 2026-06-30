#!/bin/bash
# scripts/audit-secrets.sh
# Audit complet des secrets et credentials

echo "🔐 AUDIT DES SECRETS ET CREDENTIALS"
echo "==================================="
echo ""

# ============================================================
# 1. AUDIT DES FICHIERS .ENV
# ============================================================
echo "📄 1. VÉRIFICATION DES FICHIERS .ENV"
echo "-----------------------------------"

if [ -f ".env" ]; then
    echo "⚠️  Fichier .env présent !"
    echo "    Vérifiez qu'il n'est pas commité :"
    git check-ignore .env || echo "    ❌ Le fichier .env n'est pas ignoré par Git !"
else
    echo "✅ .env non trouvé (correct)"
fi

if [ -f ".env.example" ]; then
    echo "✅ .env.example présent (template sécurisé)"
else
    echo "❌ .env.example manquant !"
fi

echo ""

# ============================================================
# 2. AUDIT DES FICHIERS DE PROPRIÉTÉS
# ============================================================
echo "📄 2. VÉRIFICATION DES FICHIERS DE PROPRIÉTÉS"
echo "---------------------------------------------"

for file in src/main/resources/application*.properties; do
    if [ -f "$file" ]; then
        echo "📄 Vérification de $file"
        # Recherche de mots de passe en clair
        if grep -E "password.*=" "$file" | grep -v "^\s*#" | grep -v "TODO"; then
            echo "   ⚠️  Des mots de passe sont présents dans $file"
            grep -E "password.*=" "$file" | grep -v "^\s*#" | grep -v "TODO" | head -5
        fi
        # Recherche de secrets JWT
        if grep -E "jwt.*secret.*=" "$file" | grep -v "^\s*#" | grep -v "TODO"; then
            echo "   ⚠️  Un secret JWT est présent dans $file"
        fi
    fi
done

echo ""

# ============================================================
# 3. AUDIT DES FICHIERS KUBERNETES
# ============================================================
echo "📄 3. VÉRIFICATION DES FICHIERS KUBERNETES"
echo "-------------------------------------------"

for file in k8s/*.yaml k8s/*.yml; do
    if [ -f "$file" ]; then
        echo "📄 Vérification de $file"
        if grep -E "stringData:" "$file" -A 10 | grep -E "password|secret|token" | grep -v "^\s*#"; then
            echo "   ⚠️  Des secrets en clair sont présents dans $file"
        fi
    fi
done

echo ""

# ============================================================
# 4. AUDIT DES FICHIERS HELM
# ============================================================
echo "📄 4. VÉRIFICATION DES FICHIERS HELM"
echo "--------------------------------------"

if [ -f "helm/student-management/values.yaml" ]; then
    echo "📄 Vérification de helm/student-management/values.yaml"
    if grep -E "password|secret|token" "helm/student-management/values.yaml" | grep -v "^\s*#"; then
        echo "   ⚠️  Des secrets sont présents dans values.yaml"
        grep -E "password|secret|token" "helm/student-management/values.yaml" | grep -v "^\s*#" | head -5
    fi
fi

echo ""

# ============================================================
# 5. AUDIT DU JENKINSFILE
# ============================================================
echo "📄 5. VÉRIFICATION DU JENKINSFILE"
echo "-----------------------------------"

if [ -f "Jenkinsfile" ]; then
    echo "📄 Vérification de Jenkinsfile"
    if grep -E "credentials\('" Jenkinsfile; then
        echo "   ✅ Utilisation de credentials Jenkins (bonne pratique)"
    else
        echo "   ⚠️  Aucune utilisation de credentials Jenkins détectée"
    fi
    if grep -E "token.*=.*[a-zA-Z0-9]{16,}" Jenkinsfile; then
        echo "   ❌ Un token en clair est présent dans Jenkinsfile !"
        grep -E "token.*=.*[a-zA-Z0-9]{16,}" Jenkinsfile
    fi
fi

echo ""

# ============================================================
# 6. AUDIT DES CONFIGURATIONS DOCKER
# ============================================================
echo "📄 6. VÉRIFICATION DES FICHIERS DOCKER"
echo "---------------------------------------"

if [ -f "docker/docker-compose.yml" ]; then
    echo "📄 Vérification de docker/docker-compose.yml"
    if grep -E "password|secret|token" "docker/docker-compose.yml" | grep -v "^\s*#" | grep -v "^\s*\$"; then
        echo "   ⚠️  Des secrets sont présents dans docker-compose.yml"
    fi
fi

if [ -f "docker/Dockerfile" ]; then
    echo "📄 Vérification de docker/Dockerfile"
    if grep -E "ENV.*password" docker/Dockerfile; then
        echo "   ⚠️  Des secrets sont passés dans le Dockerfile"
    fi
fi

echo ""

# ============================================================
# 7. VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
# ============================================================
echo "📄 7. VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT"
echo "-------------------------------------------------"

if [ -f ".env" ]; then
    echo "Variables définies dans .env :"
    source .env
    for var in SPRING_DATASOURCE_PASSWORD JWT_SECRET MAIL_PASSWORD SONAR_TOKEN DOCKER_PASSWORD; do
        if [ ! -z "${!var}" ] && [ "${!var}" != "change_me" ]; then
            echo "   ✅ $var définie"
        else
            echo "   ⚠️  $var non définie ou valeur par défaut"
        fi
    done
fi

echo ""

# ============================================================
# 8. RAPPORT DE SYNTHÈSE
# ============================================================
echo "========================================="
echo "📊 RAPPORT DE SYNTHÈSE"
echo "========================================="
echo ""

echo "🔴 CRITIQUE (À corriger immédiatement) :"
echo "   - Fichiers .env commités ?"
echo "   - Secrets en clair dans les fichiers ?"
echo "   - Tokens API en clair ?"
echo ""

echo "🟡 MOYEN (À améliorer) :"
echo "   - Utilisation de variables d'environnement"
echo "   - Séparation des profils (dev/prod)"
echo ""

echo "🟢 FAIBLE (Bonnes pratiques) :"
echo "   - Utilisation de credentials Jenkins"
echo "   - Fichiers .example sécurisés"
echo ""

echo "✅ Audit terminé !"
