#!/bin/bash
# scripts/export-code.sh
# Version 2.1 - Gère les espaces dans les chemins

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
log_section() { echo -e "\n${CYAN}============================================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}============================================================${NC}\n"; }

# ============================================================
# VARIABLES
# ============================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="${OUTPUT_DIR}/code_export_${TIMESTAMP}.txt"

# Déterminer la commande find à utiliser
if command -v /usr/bin/find &> /dev/null; then
    FIND_CMD="/usr/bin/find"
elif command -v find &> /dev/null && find --version 2>/dev/null | grep -q "GNU"; then
    FIND_CMD="find"
else
    FIND_CMD="find"
fi

EXCLUDES=(
    "target/"
    ".git/"
    ".idea/"
    ".vscode/"
    "node_modules/"
    "logs/"
)

# ============================================================
# FONCTIONS
# ============================================================

# Vérifier si un fichier doit être exclu
should_exclude() {
    local file="$1"
    for exclude in "${EXCLUDES[@]}"; do
        if [[ "$file" == *"$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# ============================================================
# DÉBUT DU SCRIPT
# ============================================================
log_section "📦 EXPORT DU CODE SOURCE"

mkdir -p "$OUTPUT_DIR"
log_info "Dossier de sortie : $OUTPUT_DIR"

cat > "$OUTPUT_FILE" << EOF
╔═══════════════════════════════════════════════════════════════╗
║  📦 EXPORT DU CODE SOURCE                                    ║
║  Projet: Student Management                                  ║
║  Date: $(date)                                              ║
║  Fichier: $(basename "$OUTPUT_FILE")                        ║
╚═══════════════════════════════════════════════════════════════╝

EOF

log_info "Fichier de sortie : $OUTPUT_FILE"

# ============================================================
# STRUCTURE DU PROJET
# ============================================================
log_section "📁 STRUCTURE DU PROJET"

echo "============================================================" >> "$OUTPUT_FILE"
echo "📁 STRUCTURE DU PROJET" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if command -v tree &> /dev/null; then
    (cd "$PROJECT_ROOT" && tree -L 3 -I "target|.git|.idea|.vscode|node_modules|logs" >> "$OUTPUT_FILE")
else
    (cd "$PROJECT_ROOT" && find . -maxdepth 3 -type d -not -path "*/\.*" -not -path "*/target*" -not -path "*/node_modules*" 2>/dev/null | sort >> "$OUTPUT_FILE")
fi

echo "" >> "$OUTPUT_FILE"

# ============================================================
# FICHIERS DE CONFIGURATION
# ============================================================
log_section "⚙️ FICHIERS DE CONFIGURATION"

echo "============================================================" >> "$OUTPUT_FILE"
echo "⚙️ FICHIERS DE CONFIGURATION" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

CONFIG_FILES=(
    "pom.xml"
    "Jenkinsfile"
    "Vagrantfile"
    "src/main/resources/application.properties"
    ".env.example"
    ".gitignore"
    "docker/docker-compose.yml"
    "docker/Dockerfile"
    "docker/prometheus/prometheus.yml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
        echo "📄 $file" >> "$OUTPUT_FILE"
        echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        cat "$PROJECT_ROOT/$file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        log_info "✅ $file exporté"
    else
        log_warn "⚠️ $file non trouvé"
    fi
done

# ============================================================
# CODE SOURCE JAVA
# ============================================================
log_section "☕ CODE SOURCE JAVA"

echo "============================================================" >> "$OUTPUT_FILE"
echo "☕ CODE SOURCE JAVA" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Utiliser find avec -print0 pour gérer les espaces
$FIND_CMD "$PROJECT_ROOT/src" -name "*.java" -type f 2>/dev/null -print0 | while IFS= read -r -d '' file; do
    if ! should_exclude "$file"; then
        rel_path="${file#$PROJECT_ROOT/}"
        echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
        echo "☕ $rel_path" >> "$OUTPUT_FILE"
        echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        log_info "✅ $rel_path exporté"
    fi
done

# ============================================================
# FICHIERS DE RESSOURCES
# ============================================================
log_section "📄 FICHIERS DE RESSOURCES"

echo "============================================================" >> "$OUTPUT_FILE"
echo "📄 FICHIERS DE RESSOURCES" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

$FIND_CMD "$PROJECT_ROOT/src/main/resources" -type f \( -name "*.properties" -o -name "*.yml" -o -name "*.yaml" -o -name "*.xml" -o -name "*.json" \) 2>/dev/null -print0 | while IFS= read -r -d '' file; do
    rel_path="${file#$PROJECT_ROOT/}"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "📄 $rel_path" >> "$OUTPUT_FILE"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    log_info "✅ $rel_path exporté"
done

# ============================================================
# SCRIPTS
# ============================================================
log_section "🛠️ SCRIPTS"

echo "============================================================" >> "$OUTPUT_FILE"
echo "🛠️ SCRIPTS" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

$FIND_CMD "$PROJECT_ROOT/scripts" -type f -name "*.sh" 2>/dev/null -print0 | while IFS= read -r -d '' file; do
    rel_path="${file#$PROJECT_ROOT/}"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "🛠️ $rel_path" >> "$OUTPUT_FILE"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    log_info "✅ $rel_path exporté"
done

# ============================================================
# FICHIERS KUBERNETES
# ============================================================
log_section "☸️ FICHIERS KUBERNETES"

echo "============================================================" >> "$OUTPUT_FILE"
echo "☸️ FICHIERS KUBERNETES" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

$FIND_CMD "$PROJECT_ROOT/k8s" -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null -print0 | while IFS= read -r -d '' file; do
    rel_path="${file#$PROJECT_ROOT/}"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "☸️ $rel_path" >> "$OUTPUT_FILE"
    echo "────────────────────────────────────────────────────" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    log_info "✅ $rel_path exporté"
done

# ============================================================
# STATISTIQUES
# ============================================================
log_section "📊 STATISTIQUES"

TOTAL_LINES=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f -not -path "*/\.*" -not -path "*/target/*" -not -path "*/node_modules/*" -not -path "*/logs/*" 2>/dev/null | wc -l)

echo "============================================================" >> "$OUTPUT_FILE"
echo "📊 STATISTIQUES" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Total des fichiers : $TOTAL_FILES" >> "$OUTPUT_FILE"
echo "Total des lignes : $TOTAL_LINES" >> "$OUTPUT_FILE"
echo "Date d'export : $(date)" >> "$OUTPUT_FILE"
echo "Fichier d'export : $(basename "$OUTPUT_FILE")" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

log_section "✅ EXPORT TERMINÉ"
echo ""
echo "📁 Fichier généré : $OUTPUT_FILE"
echo "📊 Total lignes : $TOTAL_LINES"
echo "📄 Total fichiers : $TOTAL_FILES"
echo ""

ln -sf "$(basename "$OUTPUT_FILE")" "$OUTPUT_DIR/latest.txt" 2>/dev/null || true
log_info "🔗 Lien symbolique : $OUTPUT_DIR/latest.txt"