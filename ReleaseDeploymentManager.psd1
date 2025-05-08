@{
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'A PowerShell module for managing and validating release deployments to client folders'
    PowerShellVersion = '5.1'
    RootModule = 'ReleaseDeploymentManager.psm1'
    ScriptsToProcess = @()
    TypesToProcess = @()
    FormatsToProcess = @()
    FunctionsToExport = @(
        'Deploy-Release',
        'Confirm-ReleaseDeployment'
    )
    CmdletsToExport = @()
    VariablesToExport = @('LogLevel')
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Release', 'Deployment', 'Validation', 'FileCopy')
            ProjectUri = 'https://github.com/yourusername/ReleaseDeploymentManager'
        }
    }
} 