# Import the module using the using statement
using module .\ReleaseDeploymentManager.psm1

# Test Release class
try {
    $release = [Release]::new("9.2.0")
    Write-Host "Release class is loaded. Version: $($release.Version)"
} catch {
    Write-Host "Error with Release class: $_"
}

# Test ValidationResult class
try {
    $result = [ValidationResult]::new("test.txt", $release)
    Write-Host "ValidationResult class is loaded. Status: $($result.Status)"
} catch {
    Write-Host "Error with ValidationResult class: $_"
}

# Test FileMapping class
try {
    $mapping = [FileMapping]::new("source", "target")
    Write-Host "FileMapping class is loaded. Source: $($mapping.SourceFolder)"
} catch {
    Write-Host "Error with FileMapping class: $_"
} 