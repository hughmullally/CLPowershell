function Test-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Config
    )

    $requiredPaths = @(
        'defaultPaths.rootFolder',
        'defaultPaths.gitRootFolder',
        'logging.logPath'
    )

    foreach ($path in $requiredPaths) {
        $value = $Config
        foreach ($part in $path.Split('.')) {
            if (-not $value.PSObject.Properties.Name.Contains($part)) {
                throw "Missing required configuration: $path"
            }
            $value = $value.$part
        }

        if ([string]::IsNullOrEmpty($value)) {
            throw "Empty value for required configuration: $path"
        }
    }

    if (-not $Config.folderMappings -or $Config.folderMappings.Count -eq 0) {
        throw "No folder mappings defined in configuration"
    }

    foreach ($mapping in $Config.folderMappings) {
        if (-not $mapping.sourceFolder -or -not $mapping.targetFolder) {
            throw "Invalid folder mapping: Source or target folder is missing"
        }
    }

    return $true
}
