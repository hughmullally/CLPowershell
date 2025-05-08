#Requires -Version 5.1

# Class definitions
class FileMapping {
    [string]$SourceFolder
    [string]$TargetFolder

    FileMapping([string]$sourceFolder, [string]$targetFolder) {
        $this.SourceFolder = $sourceFolder
        $this.TargetFolder = $targetFolder
    }

    [string] GetSourcePath([string]$basePath) {
        return Join-Path $basePath $this.SourceFolder
    }

    [string] GetTargetPath([string]$basePath) {
        return Join-Path $basePath $this.TargetFolder
    }
}

class Release {
    [string]$Version
    [string]$RootFolder
    [string]$ReleaseFolder

    Release([string]$version) {
        $this.Version = $version
    }

    [string] ToString() {
        return $this.Version
    }

    static [Release] FromString([string]$versionString) {
        return [Release]::new($versionString.Trim())
    }

    static [Release[]] FromStringArray([string[]]$versionStrings) {
        return $versionStrings | ForEach-Object { [Release]::FromString($_) }
    }

    static [Release[]] SortByVersion([Release[]]$releases) {
        return $releases | Sort-Object -Property {
            $versionParts = $_.Version -replace '^V', '' -split '\.'
            [version]::new($versionParts -join '.')
        } -Descending
    }
}

class ValidationResult {
    [string]$File
    [Release]$Release
    [string]$Status
    [string]$Details

    ValidationResult([string]$file, [Release]$release) {
        $this.File = $file
        $this.Release = $release
        $this.Status = "Success"
        $this.Details = ""
    }

    [void] SetError([string]$details) {
        $this.Status = "Error"
        $this.Details = $details
    }

    [void] SetWarning([string]$details) {
        $this.Status = "Warning"
        $this.Details = $details
    }
}

# Get the module's root directory
$moduleRoot = Join-Path $PSScriptRoot "src" 

# Import all private functions
$privateFunctions = @(
    'Get-Configuration',
    'Get-ReleaseRootFolder',
    'Get-Release',
    'Get-ReleaseFolder',
    'Test-FolderPermissions',
    'Test-ReleaseFormat',
    'Test-Configuration',
    'Test-FileSize',
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

# Import ReleaseService class
$publicServices = @(
    'ReleaseService',
    'ValidationService'
)

foreach ($service in $publicServices) {
    $servicePath = Join-Path $moduleRoot "Services\$service.ps1"
    if (Test-Path $servicePath) {
        . $servicePath
    }
else {
        Write-Warning "Service class file not found: $servicePath"
    }
}

# Export public functions
Export-ModuleMember -Function $publicFunctions 