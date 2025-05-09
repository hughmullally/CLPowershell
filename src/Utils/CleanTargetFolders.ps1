$Client = "Drax"
$rootFolder = "C:\git\ClientReleases\$Client\Release"


$confirmation = Read-Host "Are you sure you want to clean folder '$rootFolder'? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Operation cancelled"
    exit
}

Write-Host "Cleaning target folder: $rootFolder"
Get-ChildItem -Path $rootFolder -Recurse -File | ForEach-Object {
    Write-Host "Deleting file: $($_.FullName)"
    try {
        Remove-Item $_.FullName -Force
    }
    catch {
        Write-Warning "Failed to delete file: $($_.FullName). Error: $_"
    }
}
Write-Host "Finished cleaning target folder"

