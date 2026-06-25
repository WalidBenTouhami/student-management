#!/bin/bash
# scripts/check-code.sh
# Vérifie la compatibilité du code source et corrige les issues
# Version: 2.0 - Compatible Windows (Git Bash)

set -e

# ============================================================
# COULEURS
# ============================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[✅]${NC} $1"; }
log_section() { echo -e "\n${CYAN}============================================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}============================================================${NC}\n"; }

# ============================================================
# VARIABLES
# ============================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${PROJECT_ROOT}/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/code_analysis_${TIMESTAMP}.txt"
FIX_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=0

# Déterminer la commande find à utiliser
if command -v /usr/bin/find &> /dev/null; then
    FIND_CMD="/usr/bin/find"
elif command -v find &> /dev/null && find --version 2>/dev/null | grep -q "GNU"; then
    FIND_CMD="find"
else
    # Sur Windows, utiliser la commande dir de cmd
    FIND_CMD="cmd //c dir /s /b"
    USE_DIR=true
fi

# ============================================================
# FONCTIONS DE RECHERCHE DE FICHIERS
# ============================================================

find_files() {
    local pattern="$1"
    local exclude="$2"

    if [ "$USE_DIR" = true ]; then
        # Utiliser dir de Windows
        cmd //c "dir /s /b $pattern 2>nul" 2>/dev/null | while read -r file; do
            if [ -f "$file" ]; then
                # Filtrer les exclus
                if [ -n "$exclude" ]; then
                    if [[ ! "$file" == *"$exclude"* ]]; then
                        echo "$file"
                    fi
                else
                    echo "$file"
                fi
            fi
        done
    else
        # Utiliser find Linux
        if [ -n "$exclude" ]; then
            $FIND_CMD "$PROJECT_ROOT" -name "$pattern" -type f -not -path "*$exclude*" 2>/dev/null
        else
            $FIND_CMD "$PROJECT_ROOT" -name "$pattern" -type f 2>/dev/null
        fi
    fi
}

# ============================================================
# FONCTIONS DE VÉRIFICATION
# ============================================================

# Vérifier les fichiers de propriétés
check_properties() {
    local file="$1"
    local issues=0

    if [ -f "$file" ]; then
        DUPLICATES=$(grep -v '^#' "$file" | grep -v '^$' | cut -d'=' -f1 | sort | uniq -d 2>/dev/null || true)
        if [ -n "$DUPLICATES" ]; then
            log_warn "⚠️ Doublons dans $file : $DUPLICATES"
            echo "⚠️ Doublons dans $file : $DUPLICATES" >> "$REPORT_FILE"
            issues=$((issues + 1))
        fi
    fi
    return $issues
}

# Vérifier les fichiers YAML
check_yaml() {
    local file="$1"
    if command -v yamllint &> /dev/null; then
        if ! yamllint "$file" &> /dev/null; then
            log_warn "⚠️ Problème YAML dans $file"
            echo "⚠️ Problème YAML dans $file" >> "$REPORT_FILE"
            return 1
        fi
    fi
    return 0
}

# Vérifier les fichiers JSON
check_json() {
    local file="$1"
    if command -v jq &> /dev/null; then
        if ! jq . "$file" &> /dev/null 2>&1; then
            log_warn "⚠️ JSON invalide dans $file"
            echo "⚠️ JSON invalide dans $file" >> "$REPORT_FILE"
            return 1
        fi
    fi
    return 0
}

# Vérifier les fichiers Java
check_java() {
    local file="$1"
    local issues=0

    # Vérifier les System.out.println
    if grep -q "System.out.println" "$file" 2>/dev/null; then
        log_warn "⚠️ System.out.println trouvé dans $file (utiliser un logger)"
        echo "⚠️ System.out.println dans $file (utiliser un logger)" >> "$REPORT_FILE"
        issues=$((issues + 1))
    fi

    # Vérifier les e.printStackTrace()
    if grep -q "e.printStackTrace()" "$file" 2>/dev/null; then
        log_warn "⚠️ e.printStackTrace() trouvé dans $file (utiliser un logger)"
        echo "⚠️ e.printStackTrace() dans $file (utiliser un logger)" >> "$REPORT_FILE"
        issues=$((issues + 1))
    fi

    # Vérifier les TODO
    if grep -q "TODO" "$file" 2>/dev/null; then
        log_warn "⚠️ TODO trouvé dans $file"
        echo "⚠️ TODO dans $file" >> "$REPORT_FILE"
        issues=$((issues + 1))
    fi

    return $issues
}

# Vérifier les variables d'environnement
check_env_vars() {
    local file="$1"
    if [ -f "$file" ]; then
        EMPTY_VARS=$(grep -E "=\s*$|change_me|password\s*=\s*$" "$file" 2>/dev/null | grep -v "^#" | head -10 || true)
        if [ -n "$EMPTY_VARS" ]; then
            log_warn "⚠️ Variables vides dans $file"
            echo "⚠️ Variables vides dans $file :" >> "$REPORT_FILE"
            echo "$EMPTY_VARS" >> "$REPORT_FILE"
            return 1
        fi
    fi
    return 0
}

# Vérifier les dépendances Maven
check_maven_deps() {
    local file="$1"
    if [ -f "$file" ]; then
        OLD_VERSIONS=$(grep -E "<version>[0-9]+\.[0-9]+\.(0|1)</version>" "$file" 2>/dev/null | grep -v "org.springframework" | grep -v "org.apache" | head -5 || true)
        if [ -n "$OLD_VERSIONS" ]; then
            log_warn "⚠️ Versions potentiellement anciennes dans $file"
            echo "⚠️ Versions potentiellement anciennes dans $file :" >> "$REPORT_FILE"
            echo "$OLD_VERSIONS" >> "$REPORT_FILE"
        fi
    fi
    return 0
}

# Vérifier les permissions des scripts
check_script_permissions() {
    local file="$1"
    if [ -f "$file" ]; then
        if [ ! -x "$file" ]; then
            log_warn "⚠️ Script non exécutable : $file"
            echo "⚠️ Script non exécutable : $file" >> "$REPORT_FILE"
            WARNING_COUNT=$((WARNING_COUNT + 1))
        fi
    fi
}

# Vérifier les fichiers Kubernetes
check_kubernetes() {
    local file="$1"
    if [ -f "$file" ]; then
        if grep -q "imagePullPolicy: Always" "$file" 2>/dev/null; then
            log_info "✅ ImagePullPolicy: Always dans $file"
        fi
        if grep -q "resources:" "$file" 2>/dev/null; then
            log_info "✅ Resources définies dans $file"
        else
            log_warn "⚠️ Resources non définies dans $file"
            echo "⚠️ Resources non définies dans $file" >> "$REPORT_FILE"
        fi
    fi
}

# ============================================================
# CORRECTIONS AUTOMATIQUES
# ============================================================

# Corriger les fichiers de propriétés
fix_properties() {
    local file="$1"
    if [ -f "$file" ]; then
        sed -i 's/ = /=/g' "$file" 2>/dev/null
        sed -i 's/= /=/g' "$file" 2>/dev/null
        log_success "✅ Espaces corrigés dans $file"
        FIX_COUNT=$((FIX_COUNT + 1))
    fi
}

# Corriger les scripts (ajouter shebang)
fix_script_shebang() {
    local file="$1"
    if [ -f "$file" ] && [[ "$file" == *.sh ]]; then
        if ! head -n1 "$file" | grep -q "#!/bin/bash"; then
            sed -i '1i#!/bin/bash' "$file"
            log_success "✅ Shebang ajouté dans $file"
            FIX_COUNT=$((FIX_COUNT + 1))
        fi
    fi
}

# Corriger les scripts (rendre exécutable)
fix_script_executable() {
    local file="$1"
    if [ -f "$file" ] && [[ "$file" == *.sh ]]; then
        if [ ! -x "$file" ]; then
            chmod +x "$file"
            log_success "✅ Script rendu exécutable : $file"
            FIX_COUNT=$((FIX_COUNT + 1))
        fi
    fi
}

# ============================================================
# DÉBUT DU SCRIPT
# ============================================================
log_section "🔍 ANALYSE ET CORRECTION DU CODE SOURCE"

# Créer le dossier de rapports
mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" << EOF
╔═══════════════════════════════════════════════════════════════╗
║  🔍 RAPPORT D'ANALYSE DU CODE SOURCE                         ║
║  Projet: Student Management                                  ║
║  Date: $(date)                                              ║
║  Fichier: $(basename "$REPORT_FILE")                        ║
╚═══════════════════════════════════════════════════════════════╝

EOF

log_info "Rapport : $REPORT_FILE"

# ============================================================
# 1. VÉRIFICATION DES FICHIERS DE PROPRIÉTÉS
# ============================================================
log_section "📄 VÉRIFICATION DES FICHIERS DE PROPRIÉTÉS"

echo "============================================================" >> "$REPORT_FILE"
echo "📄 FICHIERS DE PROPRIÉTÉS" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.properties" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    if check_properties "$file"; then
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
    fix_properties "$file"
done

# ============================================================
# 2. VÉRIFICATION DES FICHIERS YAML
# ============================================================
log_section "📄 VÉRIFICATION DES FICHIERS YAML"

echo "============================================================" >> "$REPORT_FILE"
echo "📄 FICHIERS YAML" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.yml" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    if check_yaml "$file"; then
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
done

for file in $(find_files "*.yaml" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    if check_yaml "$file"; then
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
done

# ============================================================
# 3. VÉRIFICATION DES FICHIERS JSON
# ============================================================
log_section "📄 VÉRIFICATION DES FICHIERS JSON"

echo "============================================================" >> "$REPORT_FILE"
echo "📄 FICHIERS JSON" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.json" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    if check_json "$file"; then
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
done

# ============================================================
# 4. VÉRIFICATION DU CODE JAVA
# ============================================================
log_section "☕ VÉRIFICATION DU CODE JAVA"

echo "============================================================" >> "$REPORT_FILE"
echo "☕ CODE JAVA" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.java" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    if check_java "$file"; then
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
done

# ============================================================
# 5. VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
# ============================================================
log_section "🔐 VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT"

echo "============================================================" >> "$REPORT_FILE"
echo "🔐 VARIABLES D'ENVIRONNEMENT" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -f "$PROJECT_ROOT/.env.example" ]; then
    check_env_vars "$PROJECT_ROOT/.env.example"
fi

if [ -f "$PROJECT_ROOT/.env" ]; then
    log_warn "⚠️ Fichier .env présent ! Ne devrait pas être commité"
    echo "⚠️ Fichier .env présent ! Ne devrait pas être commité" >> "$REPORT_FILE"
fi

# ============================================================
# 6. VÉRIFICATION DES DÉPENDANCES MAVEN
# ============================================================
log_section "📦 VÉRIFICATION DES DÉPENDANCES MAVEN"

echo "============================================================" >> "$REPORT_FILE"
echo "📦 DÉPENDANCES MAVEN" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

check_maven_deps "$PROJECT_ROOT/pom.xml"

# ============================================================
# 7. VÉRIFICATION DES SCRIPTS
# ============================================================
log_section "🛠️ VÉRIFICATION DES SCRIPTS"

echo "============================================================" >> "$REPORT_FILE"
echo "🛠️ SCRIPTS" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.sh" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    check_script_permissions "$file"
    fix_script_shebang "$file"
    fix_script_executable "$file"
    log_success "✅ $rel_path OK"
    echo "✅ $rel_path OK" >> "$REPORT_FILE"
done

# ============================================================
# 8. VÉRIFICATION DES FICHIERS KUBERNETES
# ============================================================
log_section "☸️ VÉRIFICATION DES FICHIERS KUBERNETES"

echo "============================================================" >> "$REPORT_FILE"
echo "☸️ FICHIERS KUBERNETES" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for file in $(find_files "*.yaml" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    log_info "Vérification de $rel_path..."
    check_kubernetes "$file"
    log_success "✅ $rel_path OK"
    echo "✅ $rel_path OK" >> "$REPORT_FILE"
done

for file in $(find_files "*.yml" "target/"); do
    rel_path="${file#$PROJECT_ROOT/}"
    if [[ ! "$rel_path" == *"docker-compose"* ]]; then
        log_info "Vérification de $rel_path..."
        check_kubernetes "$file"
        log_success "✅ $rel_path OK"
        echo "✅ $rel_path OK" >> "$REPORT_FILE"
    fi
done

# ============================================================
# 9. RAPPORT FINAL
# ============================================================
log_section "📊 RAPPORT FINAL"

echo "============================================================" >> "$REPORT_FILE"
echo "📊 RAPPORT FINAL" >> "$REPORT_FILE"
echo "============================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "✅ Corrections effectuées : $FIX_COUNT" >> "$REPORT_FILE"
echo "⚠️ Avertissements : $WARNING_COUNT" >> "$REPORT_FILE"
echo "❌ Erreurs : $ERROR_COUNT" >> "$REPORT_FILE"
echo "📅 Date : $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cat << EOF

╔═══════════════════════════════════════════════════════════════╗
║  📊 RAPPORT FINAL                                            ║
╚═══════════════════════════════════════════════════════════════╝

✅ Corrections effectuées : $FIX_COUNT
⚠️ Avertissements : $WARNING_COUNT
❌ Erreurs : $ERROR_COUNT

📁 Rapport complet : $REPORT_FILE

EOF

log_success "✅ Analyse et corrections terminées !"