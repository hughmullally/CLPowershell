# Import the required modules
# using module ..\ReleaseDeploymentManager.psm1
function Test-Initialize {
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
}

# Test Case 1: Basic deployment
# Test Case 2: Multiple releases
function Test-Deployment {
    Test-Initialize
    Write-Host "`nTest Multiple releases" -ForegroundColor Cyan
    try {
        # Deploy-Release -TargetClient "Drax" -Release "9.2.0"
        Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
        Write-Host "Test Multiple Releases passed" -ForegroundColor Green
    }
    catch {
        Write-Host "Test Multiple Releases failed: $_" -ForegroundColor Red
    }
}
function Test-Confirmation {
    Test-Initialize
    Write-Host "`nConfirm Multiple releases" -ForegroundColor Cyan
    try {
        Confirm-ReleaseDeployment -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
        Write-Host "Confirm Multiple Releases passed" -ForegroundColor Green
    }
    catch {
        Write-Host "Confirm Multiple Releases failed: $_" -ForegroundColor Red
    }
}

# Cleanup

# Test-Deployment
Test-Confirmation