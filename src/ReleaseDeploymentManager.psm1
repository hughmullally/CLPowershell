# Get the module's root directory
$moduleRoot = $PSScriptRoot

# Import all private functions
$privateFunctions = @(
    'Get-Configuration',
    'Get-ReleaseRootFolder',
    'New-Logger',
    'Process-Release'
)

foreach ($function in $privateFunctions) {
    $functionPath = Join-Path $moduleRoot "Functions\Private\$function.ps1"
    if (Test-Path $functionPath) {
        . $functionPath
    }
    else {
        Write-Warning "Private function file not found: $functionPath"
    }
}

# Import all public functions
$publicFunctions = @(
    'Deploy-Release',
    'Confirm-ReleaseDeployment'
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path $moduleRoot "Functions\$function.ps1"
    if (Test-Path $functionPath) {
        . $functionPath
    }
    else {
        Write-Warning "Public function file not found: $functionPath"
    }
}

# Export only the public functions
Export-ModuleMember -Function $publicFunctions 