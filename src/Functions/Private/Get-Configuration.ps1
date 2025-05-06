function Get-Configuration {
    param (
        [string] $configPath = ".\config.json"
    )

    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    $config = Get-Content $configPath | ConvertFrom-Json
    return $config
} 