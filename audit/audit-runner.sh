#!/usr/bin/env bash
# ==============================================================================
# AUDIT RUNNER SCRIPT (Linux/macOS)
# Performs a complete automated audit of the Student Management Platform.
# ==============================================================================

set -e
set -o pipefail

# Constants
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="../reports/audit"
REPORT_FILE="${REPORT_DIR}/audit_log_${TIMESTAMP}.json"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure report directory exists
mkdir -p "${REPORT_DIR}"

echo "[*] Starting Comprehensive Platform Audit..."
echo "[*] Output will be saved to: ${REPORT_FILE}"
echo "{" > "${REPORT_FILE}"
echo "  \"timestamp\": \"${TIMESTAMP}\"," >> "${REPORT_FILE}"
echo "  \"results\": {" >> "${REPORT_FILE}"

cd "${ROOT_DIR}"

# 1. Dependency Analysis
echo "[1/4] Running Maven Dependency Analysis..."
if ./mvnw dependency:analyze > /dev/null 2>&1; then
    echo "    \"dependency_analysis\": \"PASS\"," >> "${REPORT_FILE}"
else
    echo "    \"dependency_analysis\": \"FAIL_OR_WARNINGS\"," >> "${REPORT_FILE}"
fi

# 2. Security Check (OWASP)
# Requires org.owasp:dependency-check-maven in pom.xml or invoked as standalone goal
echo "[2/4] Running OWASP Dependency Check..."
if ./mvnw org.owasp:dependency-check-maven:check > /dev/null 2>&1; then
    echo "    \"security_scan\": \"PASS\"," >> "${REPORT_FILE}"
else
    echo "    \"security_scan\": \"FAIL_OR_NOT_CONFIGURED\"," >> "${REPORT_FILE}"
fi

# 3. Compilation & Type Checking
echo "[3/4] Running Strict Compilation Check..."
if ./mvnw clean compile > /dev/null 2>&1; then
    echo "    \"compilation\": \"PASS\"," >> "${REPORT_FILE}"
else
    echo "    \"compilation\": \"FAIL\"," >> "${REPORT_FILE}"
fi

# 4. Docker Config Validation
echo "[4/4] Validating Docker Compose Configuration..."
if docker-compose config -q > /dev/null 2>&1; then
    echo "    \"docker_compose\": \"PASS\"" >> "${REPORT_FILE}"
else
    echo "    \"docker_compose\": \"FAIL\"" >> "${REPORT_FILE}"
fi

echo "  }" >> "${REPORT_FILE}"
echo "}" >> "${REPORT_FILE}"

echo "[*] Audit Complete! Review the logs in ${REPORT_FILE}."
