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
