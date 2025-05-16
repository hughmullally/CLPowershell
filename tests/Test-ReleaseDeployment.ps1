# Import the required modules
# using module ..\ReleaseDeploymentManager.psm1

# Client-Release mapping table
$ClientReleaseMap = @{
    'Anglo'         = '9.1.2.0, 9.1.2.44'
    'Drax'          = '9.2.4.0, 9.2.4.5'
    'EnBW'          = '10.0.0.0, 10.0.0.13'
    'Gunvor'        = '10.0.0.0, 10.0.0.27'
    'Wintershall'   = '9.2.2.0, 9.2.2.34'
}

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

function DeployClient([string] $client)
{
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("$($client) Deployment", {
        $clientReleases = $ClientReleaseMap[$client]
        if ($null -eq $clientReleases) {
            throw "No releases found for client $client"
        }
        Deploy-Release -TargetClient $client -Release $clientReleases
    })
}

function ConfirmClient([string] $client) {
    $tester = [ReleaseDeploymentTest]::new()
    $tester.RunTest("$($client) Confirmation", {
        $clientReleases = $ClientReleaseMap[$client]
        if ($null -eq $clientReleases) {
            throw "No releases found for client $client"
        }
        Confirm-ReleaseDeployment -TargetClient $client -Release $clientReleases
    })
}

# Run tests
# Test-Deployment
# Test-Confirmation

DeployClient -client "EnBW"
# ConfirmClient -client "Anglo"
