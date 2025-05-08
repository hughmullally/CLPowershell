function Test-FileSize {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [long]$MaxSizeMB
    )

    if (Test-Path $Path -PathType Leaf) {
        $size = (Get-Item $Path).Length / 1MB
        if ($size -gt $MaxSizeMB) {
            throw "File size ($size MB) exceeds maximum allowed size ($MaxSizeMB MB): $Path"
        }
    }

    return $true
}

