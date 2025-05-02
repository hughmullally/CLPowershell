# Validation Module

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

function Test-FolderPermissions {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Read', 'Write', 'Modify')]
        [string]$Permission
    )

    try {
        $testPath = $Path
        if (-not (Test-Path $Path)) {
            $testPath = Split-Path $Path -Parent
        }

        $acl = Get-Acl $testPath
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $currentUserSid = $currentUser.User
        $currentUserGroups = $currentUser.Groups

        # Check both direct user permissions and group permissions
        $hasPermission = $false
        foreach ($access in $acl.Access) {
            # Check if the access rule applies to the current user or their groups
            if ($access.IdentityReference -eq $currentUser.Name -or 
                $access.IdentityReference -eq $currentUserSid -or
                $currentUserGroups.Contains($access.IdentityReference) -or
                $access.IdentityReference -eq "BUILTIN\Users" -or
                $access.IdentityReference -eq "NT AUTHORITY\Authenticated Users") {
                
                # Check if the access rule is Allow (not Deny)
                if ($access.AccessControlType -eq 'Allow') {
                    switch ($Permission) {
                        'Read' { 
                            if ($access.FileSystemRights -match 'Read|ReadAndExecute|FullControl') {
                                $hasPermission = $true
                                break
                            }
                        }
                        'Write' {
                            if ($access.FileSystemRights -match 'Write|Modify|FullControl') {
                                $hasPermission = $true
                                break
                            }
                        }
                        'Modify' {
                            if ($access.FileSystemRights -match 'Modify|FullControl') {
                                $hasPermission = $true
                                break
                            }
                        }
                    }
                }
            }
        }

        if (-not $hasPermission) {
            throw "No $Permission permission for path: $Path"
        }

        return $true
    }
    catch {
        throw "Error checking permissions for path $Path : $_"
    }
    finally {
        # Ensure we return a single boolean value
        [bool]$hasPermission
    }
}

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

# Export the functions
Export-ModuleMember -Function Test-ReleaseFormat, Test-FolderPermissions, Test-Configuration, Test-FileSize 