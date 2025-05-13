# Release Deployment Tool

A PowerShell tool for managing and deploying releases across client environments.

## Features

- Deploy releases to client environments
- Track file deployments with CSV audit trails
- Validate release deployments
- Support for cascading releases
- Detailed logging
- User-friendly GUI interface

## Prerequisites

- PowerShell 5.1 or higher
- Windows operating system

## Installation

1. Clone this repository:
```powershell
git clone https://github.com/yourusername/CopyReleaseToPSFolders.git
cd CopyReleaseToPSFolders
```

2. Create a `config.json` file in the root directory with your configuration:
```json
{
    "defaultPaths": {
        "rootFolder": "C:\\Releases",
        "gitRootFolder": "C:\\Git"
    },
    "logging": {
        "logPath": "C:\\Logs\\ReleaseDeployment.log",
        "logLevel": "Information"
    },
    "folderMappings": [
        {
            "sourceFolder": "Scripts",
            "targetFolder": "PS"
        }
    ]
}
```

## Usage

### Using the GUI

The easiest way to use the tool is through the graphical user interface:

```powershell
.\Deploy-ReleaseGUI.ps1
```

The GUI provides the following features:
- Select target client from available clients
- Add and manage releases to deploy
- Browse and select configuration file
- Deploy releases with a single click
- Confirm deployments and view results
- Real-time logging in the interface

### Command Line Usage

You can also use the tool from the command line:

#### Deploying Releases

To deploy one or more releases to a client:

```powershell
.\Deploy-Release.ps1 -TargetClient "ClientName" -Releases "9.4.0,9.4.2" -ConfigPath ".\config.json"
```

#### Confirming Deployments

To verify that releases were deployed correctly:

```powershell
.\Confirm-ReleaseDeployment.ps1 -TargetClient "ClientName" -Releases "9.4.0,9.4.2" -CheckContents $true
```

## Configuration

### Folder Mappings

The `folderMappings` section in `config.json` defines how source folders map to target folders:

```json
"folderMappings": [
    {
        "sourceFolder": "Scripts",
        "targetFolder": "PS"
    },
    {
        "sourceFolder": "Config",
        "targetFolder": "Configuration"
    }
]
```

### Logging

Configure logging in `config.json`:

```json
"logging": {
    "logPath": "C:\\Logs\\ReleaseDeployment.log",
    "logLevel": "Information"  // Options: Debug, Information, Warning, Error
}
```

## Output Files

The tool generates several CSV files for tracking:

- `DeployTracker.csv`: Tracks all file deployments
- `Confirm-Release.csv`: Records deployment validation results

## Troubleshooting

1. **Release Not Found**
   - Ensure release folders follow the format: `V9.4.0`
   - Check that the root folder path in config.json is correct

2. **Permission Issues**
   - Run PowerShell as Administrator
   - Verify write permissions to target folders

3. **Logging Issues**
   - Ensure the log directory exists
   - Check write permissions for the log file

4. **GUI Issues**
   - Make sure you're running PowerShell 5.1 or higher
   - Run as Administrator if you encounter permission issues
   - Check that all required modules are loaded

## Support

For issues or questions, please create an issue in the repository. 