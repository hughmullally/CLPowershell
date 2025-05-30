function CleanTargetFolder() {
    param (
        [string]$Client
    )
    $rootFolder = "C:\git\ClientReleases\$Client\Release"
    y$confirmation = Read-Host "Are you sure you want to clean folder '$rootFolder'? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled"
        exit
    }

    Write-Host "Cleaning target folder: $rootFolder"
    Get-ChildItem -Path $rootFolder -Recurse -File | ForEach-Object {
        if ($_.DirectoryName -notlike $rootFolder) {       
            try {
                Write-Host "Deleting file: $($_.FullName)"
                Remove-Item $_.FullName -Force
            }
            catch {
                Write-Warning "Failed to delete file: $($_.FullName). Error: $_"
            }
        }
    }
    Write-Host "Finished cleaning target folder"
}

CleanTargetFolder 'Wintershall'
