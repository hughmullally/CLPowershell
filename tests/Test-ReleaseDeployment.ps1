# Import the required modules
# using module ..\ReleaseDeploymentManager.psm1

class ReleaseDeploymentTest {
    [void] Initialize() {
        $modulePath = Join-Path $PWD.Path "ReleaseDeploymentManager.psd1"
        Remove-Module ReleaseDeploymentManager -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force

        $requiredFunctions = @('Deploy-Release')
        foreach ($function in $requiredFunctions) {
            if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
                throw "Required function '$function' not found after script import"
            }
        }
    }

    [void] RunTest([string]$testName, [scriptblock]$testBlock) {
        Write-Host "`n$testName" -ForegroundColor Cyan
        try {
            $this.Initialize()
            & $testBlock
            Write-Host "$testName passed" -ForegroundColor Green
        }
        catch {
            Write-Host "$testName failed: $_" -ForegroundColor Red
        }
    }
}

# Test Case 1: Basic deployment
# Test Case 2: Multiple releases
function Test-Deployment {
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("Test Multiple releases", {
        Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
    })
}

function Test-Confirmation {
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("Confirm Multiple releases", {
        Confirm-ReleaseDeployment -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
    })
}

function DeployClient([string] $client, [string] $releases)
{
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("$($client) Deployment", {
        Deploy-Release -TargetClient $client -Release $releases
    })
}

function ConfirmClient([string] $client, [string] $releases) {
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("$($client) Confirmation", {
        Confirm-ReleaseDeployment -TargetClient $client -Release $releases
    })
}

# Run tests
# Test-Deployment
# Test-Confirmation

DeployClient -client "Anglo" -releases "9.1.2.0, 9.1.2.44"
