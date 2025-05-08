# Import the required modules
# using module ..\ReleaseDeploymentManager.psm1

$modulePath = Join-Path $PWD.Path "ReleaseDeploymentManager.psd1"
Remove-Module ReleaseDeploymentManager -ErrorAction SilentlyContinue
Import-Module $modulePath -Force

# $requiredFunctions = @('Deploy-Release', 'Get-Configuration')
$requiredFunctions = @('Deploy-Release')
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
        throw "Required function '$function' not found after script import"
    }
}

# Test Case 1: Basic deployment
# Test Case 2: Multiple releases
Write-Host "`nTest Case 2: Multiple releases" -ForegroundColor Cyan
try {
    Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0"
    Write-Host "Test Case 2 passed" -ForegroundColor Green
}
catch {
    Write-Host "Test Case 2 failed: $_" -ForegroundColor Red
}

# Test Case 3: Invalid release format
Write-Host "`nTest Case 3: Invalid release format" -ForegroundColor Cyan
try {
    Deploy-Release -TargetClient "Drax" -Release "invalid"
    Write-Host "Test Case 3 failed: Expected error was not thrown" -ForegroundColor Red
}
catch {
    Write-Host "Test Case 3 passed: Expected error was thrown: $_" -ForegroundColor Green
}

# Test Case 4: Non-existent client
Write-Host "`nTest Case 4: Non-existent client" -ForegroundColor Cyan
try {
    Deploy-Release -TargetClient "NonExistentClient" -Release "9.2.0"
    Write-Host "Test Case 4 failed: Expected error was not thrown" -ForegroundColor Red
}
catch {
    Write-Host "Test Case 4 passed: Expected error was thrown: $_" -ForegroundColor Green
}

# Test Case 5: Invalid configuration
Write-Host "`nTest Case 5: Invalid configuration" -ForegroundColor Cyan
try {
    # Create invalid config
    @{
        defaultPaths = @{
            rootFolder = ""
            gitRootFolder = ""
        }
    } | ConvertTo-Json | Set-Content -Path ".\config.json"
    
    Deploy-Release -TargetClient "Drax" -Release "9.2.0"
    Write-Host "Test Case 5 failed: Expected error was not thrown" -ForegroundColor Red
}
catch {
    Write-Host "Test Case 5 passed: Expected error was thrown: $_" -ForegroundColor Green
}

# Cleanup
Remove-Item -Path ".\config.json" -Force
Write-Host "`nTest script completed" -ForegroundColor Yellow 