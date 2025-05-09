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


# Cleanup

Write-Host "`nTest script completed" -ForegroundColor Yellow 