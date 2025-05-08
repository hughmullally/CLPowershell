function Test-ReleaseFormat {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Release
    )

    # Remove 'V' prefix and trim all spaces
    $release = $Release.TrimStart('V').Trim()
    
    # Check if empty after trimming
    if ([string]::IsNullOrEmpty($release)) {
        throw "Release number is empty after trimming spaces"
    }
    
    # Check format: major.minor[.patch[.build]]
    if (-not ($release -match '^\d+\.\d+(\.\d+(\.\d+)?)?$')) {
        $example = "9.2.0 or 9.2.4.0"
        throw "Invalid release format: '$Release'. Expected format: major.minor[.patch[.build]] (e.g., $example)"
    }

    # Validate each part is a valid number
    $parts = $release.Split('.')
    foreach ($part in $parts) {
        if (-not ([int]::TryParse($part, [ref]$null))) {
            throw "Invalid release number part: '$part' in release '$Release'. All parts must be numbers."
        }
    }

    return $true
}
