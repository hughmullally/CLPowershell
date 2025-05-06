<#
.SYNOPSIS
    Demonstrates the usage of ReleaseDeploymentManager module functions.
.DESCRIPTION
    This script shows how to use Deploy-Release and Confirm-ReleaseDeployment functions
    to deploy and validate releases. It includes examples of successful deployments,
    error handling, and validation checks.
.EXAMPLE
    .\Test-ReleaseDeployment.ps1
#>

# Import the script
$scriptPath = Join-Path $PSScriptRoot "..\CopyReleaseToPSFolders.ps1"
Write-Host "Attempting to import script from: $scriptPath" -ForegroundColor Yellow

if (-not (Test-Path $scriptPath)) {
    throw "Script not found: $scriptPath"
}

try {
    . $scriptPath
    Write-Host "Script imported successfully" -ForegroundColor Green
}
catch {
    throw "Failed to import script: $_"
}

# Verify functions are available
$requiredFunctions = @('Test-ReleaseCopyIntegrity')
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
        throw "Required function '$function' not found after script import"
    }
}

# Setup example configuration
$config = @{
    defaultPaths = @{
        rootFolder = "C:\Releases"
        gitRootFolder = "C:\Git\ClientReleases"
    }
    logging = @{
        logPath = ".\logs\deployment.log"
        logLevel = "Information"
    }
    folderMappings = @(
        @{
            sourceFolder = "\Scripts"
            targetFolder = "scripts"
        },
        @{
            sourceFolder = "\Config"
            targetFolder = "config"
        }
    )
}

# Create logs directory if it doesn't exist
$logsDir = ".\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

# Save configuration
$config | ConvertTo-Json | Set-Content -Path ".\config.json"

# Test Case 1: Basic integrity check
Write-Host "`nTest Case 1: Basic integrity check" -ForegroundColor Cyan
try {
    $results = Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "9.2.0,9.2.4.0,9.2.4.5"
    Write-Host "Validation Results:"
    $results | Format-Table -AutoSize
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Test Case 2: Integrity check with content verification
Write-Host "`nTest Case 2: Integrity check with content verification" -ForegroundColor Cyan
try {
    $results = Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "9.2.0" -CheckContents $true
    Write-Host "Validation Results:"
    $results | Format-Table -AutoSize
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Test Case 3: Error handling - Invalid release format
Write-Host "`nTest Case 3: Error handling - Invalid release format" -ForegroundColor Cyan
try {
    Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "invalid-release"
}
catch {
    Write-Host "Expected Error: $_" -ForegroundColor Yellow
}

# Test Case 4: Error handling - Non-existent client
Write-Host "`nTest Case 4: Error handling - Non-existent client" -ForegroundColor Cyan
try {
    Test-ReleaseCopyIntegrity -TargetClient "NonExistentClient" -Releases "9.2.0"
}
catch {
    Write-Host "Expected Error: $_" -ForegroundColor Yellow
}

# Test Case 5: Error handling - Invalid configuration
Write-Host "`nTest Case 5: Error handling - Invalid configuration" -ForegroundColor Cyan
try {
    # Create invalid configuration
    @{ invalid = "config" } | ConvertTo-Json | Set-Content -Path ".\config.json"
    
    Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "9.2.0"
}
catch {
    Write-Host "Expected Error: $_" -ForegroundColor Yellow
}

Write-Host "`nTest script completed." -ForegroundColor Green 