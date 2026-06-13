<#
.SYNOPSIS
    AUDIT RUNNER SCRIPT (Windows PowerShell)
    Performs a complete automated audit of the Student Management Platform.
#>

$ErrorActionPreference = "Stop"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ReportDir = Join-Path $RootDir "reports\audit"
$ReportFile = Join-Path $ReportDir "audit_log_$Timestamp.json"

if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
}

Write-Host "[*] Starting Comprehensive Platform Audit..." -ForegroundColor Cyan
Write-Host "[*] Output will be saved to: $ReportFile" -ForegroundColor Cyan

$ResultObj = @{
    timestamp = $Timestamp
    results = @{}
}

Set-Location $RootDir

# 1. Dependency Analysis
Write-Host "[1/4] Running Maven Dependency Analysis..."
try {
    $null = .\mvnw.cmd dependency:analyze 2>&1
    if ($LASTEXITCODE -eq 0) { $ResultObj.results.dependency_analysis = "PASS" } else { $ResultObj.results.dependency_analysis = "FAIL_OR_WARNINGS" }
} catch {
    $ResultObj.results.dependency_analysis = "ERROR"
}

# 2. Security Check (OWASP)
Write-Host "[2/4] Running OWASP Dependency Check..."
try {
    $null = .\mvnw.cmd org.owasp:dependency-check-maven:check 2>&1
    if ($LASTEXITCODE -eq 0) { $ResultObj.results.security_scan = "PASS" } else { $ResultObj.results.security_scan = "FAIL_OR_NOT_CONFIGURED" }
} catch {
    $ResultObj.results.security_scan = "ERROR"
}

# 3. Compilation & Type Checking
Write-Host "[3/4] Running Strict Compilation Check..."
try {
    $null = .\mvnw.cmd clean compile 2>&1
    if ($LASTEXITCODE -eq 0) { $ResultObj.results.compilation = "PASS" } else { $ResultObj.results.compilation = "FAIL" }
} catch {
    $ResultObj.results.compilation = "ERROR"
}

# 4. Docker Config Validation
Write-Host "[4/4] Validating Docker Compose Configuration..."
try {
    $null = docker-compose config -q 2>&1
    if ($LASTEXITCODE -eq 0) { $ResultObj.results.docker_compose = "PASS" } else { $ResultObj.results.docker_compose = "FAIL" }
} catch {
    $ResultObj.results.docker_compose = "ERROR"
}

$ResultObj | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportFile -Encoding UTF8

Write-Host "[*] Audit Complete! Review the logs in $ReportFile" -ForegroundColor Green
