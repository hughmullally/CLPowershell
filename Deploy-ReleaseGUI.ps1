#Requires -Version 5.1

# Load required assemblies first
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import required modules
. $PSScriptRoot\src\Services\ReleaseService.ps1
. $PSScriptRoot\src\Services\FileTrackingService.ps1
# . $PSScriptRoot\src\Services\LoggingService.ps1

# Create a custom logger that writes to the rich text box
class GUILogger {
    [object]$LogBox
    [string]$LogLevel
    [string]$LogPath

    GUILogger([object]$logBox, [string]$logLevel, [string]$logPath) {
        $this.LogBox = $logBox
        $this.LogLevel = $logLevel
        $this.LogPath = $logPath
    }

    [void]Log([string]$message, [string]$level) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$level] $message`n"
        
        $this.LogBox.Invoke({
            param($message)
            $this.AppendText($message)
            $this.ScrollToCaret()
        }, $logMessage)
    }

    [void]Information([string]$message) {
        $this.Log($message, "INFO")
    }

    [void]Error([string]$message) {
        $this.Log($message, "ERROR")
    }

    [void]Warning([string]$message) {
        $this.Log($message, "WARNING")
    }

    [void]Debug([string]$message) {
        if ($this.LogLevel -eq "Debug") {
            $this.Log($message, "DEBUG")
        }
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Release Deployment Tool"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Create a status strip
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusStrip.Items.Add($statusLabel)
$form.Controls.Add($statusStrip)

# Create a rich text box for logging
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(10, 300)
$logBox.Size = New-Object System.Drawing.Size(760, 250)
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($logBox)

# Create the main panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(10, 10)
$mainPanel.Size = New-Object System.Drawing.Size(760, 280)
$form.Controls.Add($mainPanel)

# Client Selection
$clientLabel = New-Object System.Windows.Forms.Label
$clientLabel.Location = New-Object System.Drawing.Point(10, 15)
$clientLabel.Size = New-Object System.Drawing.Size(100, 20)
$clientLabel.Text = "Target Client:"
$mainPanel.Controls.Add($clientLabel)

$clientCombo = New-Object System.Windows.Forms.ComboBox
$clientCombo.Location = New-Object System.Drawing.Point(120, 12)
$clientCombo.Size = New-Object System.Drawing.Size(200, 20)
$clientCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$mainPanel.Controls.Add($clientCombo)

# Release Selection
$releaseLabel = New-Object System.Windows.Forms.Label
$releaseLabel.Location = New-Object System.Drawing.Point(10, 45)
$releaseLabel.Size = New-Object System.Drawing.Size(100, 20)
$releaseLabel.Text = "Releases:"
$mainPanel.Controls.Add($releaseLabel)

$releaseList = New-Object System.Windows.Forms.ListBox
$releaseList.Location = New-Object System.Drawing.Point(120, 42)
$releaseList.Size = New-Object System.Drawing.Size(200, 100)
$releaseList.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$mainPanel.Controls.Add($releaseList)

# Add Release Button
$addReleaseButton = New-Object System.Windows.Forms.Button
$addReleaseButton.Location = New-Object System.Drawing.Point(330, 42)
$addReleaseButton.Size = New-Object System.Drawing.Size(100, 23)
$addReleaseButton.Text = "Add Release"
$mainPanel.Controls.Add($addReleaseButton)

# Config File Selection
$configLabel = New-Object System.Windows.Forms.Label
$configLabel.Location = New-Object System.Drawing.Point(10, 155)
$configLabel.Size = New-Object System.Drawing.Size(100, 20)
$configLabel.Text = "Config File:"
$mainPanel.Controls.Add($configLabel)

$configTextBox = New-Object System.Windows.Forms.TextBox
$configTextBox.Location = New-Object System.Drawing.Point(120, 152)
$configTextBox.Size = New-Object System.Drawing.Size(200, 20)
$configTextBox.Text = ".\config.json"
$mainPanel.Controls.Add($configTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(330, 150)
$browseButton.Size = New-Object System.Drawing.Size(75, 23)
$browseButton.Text = "Browse..."
$mainPanel.Controls.Add($browseButton)

# Deploy Button
$deployButton = New-Object System.Windows.Forms.Button
$deployButton.Location = New-Object System.Drawing.Point(120, 190)
$deployButton.Size = New-Object System.Drawing.Size(200, 30)
$deployButton.Text = "Deploy Releases"
$mainPanel.Controls.Add($deployButton)

# Confirm Button
$confirmButton = New-Object System.Windows.Forms.Button
$confirmButton.Location = New-Object System.Drawing.Point(330, 190)
$confirmButton.Size = New-Object System.Drawing.Size(200, 30)
$confirmButton.Text = "Confirm Deployment"
$mainPanel.Controls.Add($confirmButton)

# Add Release Dialog
$addReleaseForm = New-Object System.Windows.Forms.Form
$addReleaseForm.Text = "Add Release"
$addReleaseForm.Size = New-Object System.Drawing.Size(300, 150)
$addReleaseForm.StartPosition = "CenterParent"
$addReleaseForm.FormBorderStyle = "FixedDialog"
$addReleaseForm.MaximizeBox = $false

$releaseInput = New-Object System.Windows.Forms.TextBox
$releaseInput.Location = New-Object System.Drawing.Point(10, 20)
$releaseInput.Size = New-Object System.Drawing.Size(260, 20)
$addReleaseForm.Controls.Add($releaseInput)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(70, 60)
$okButton.Size = New-Object System.Drawing.Size(75, 23)
$okButton.Text = "OK"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$addReleaseForm.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150, 60)
$cancelButton.Size = New-Object System.Drawing.Size(75, 23)
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$addReleaseForm.Controls.Add($cancelButton)

# Event Handlers
$addReleaseButton.Add_Click({
    $addReleaseForm.ShowDialog()
    if ($addReleaseForm.DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $release = $releaseInput.Text.Trim()
        if ($release -and -not $releaseList.Items.Contains($release)) {
            $releaseList.Items.Add($release)
        }
        $releaseInput.Text = ""
    }
})

$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
    $openFileDialog.InitialDirectory = $PSScriptRoot
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $configTextBox.Text = $openFileDialog.FileName
    }
})

$deployButton.Add_Click({
    if ($clientCombo.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select a target client.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ($releaseList.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please add at least one release.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    try {
        $deployButton.Enabled = $false
        $confirmButton.Enabled = $false
        $statusLabel.Text = "Deploying releases..."
        
        # Load configuration
        $config = Get-Content $configTextBox.Text | ConvertFrom-Json
        
        # Initialize services
        $logger = [GUILogger]::new($logBox, $config.logging.logLevel, $config.logging.logPath)
        $releaseService = [ReleaseService]::new($config.defaultPaths.rootFolder, $logger, $clientCombo.SelectedItem)
        $fileTracker = [FileTrackingService]::new($logger, $config.defaultPaths.gitRootFolder, $clientCombo.SelectedItem, "deploy-release-tracker.csv")
        
        # Get selected releases
        $releases = $releaseList.SelectedItems -join ","
        if (-not $releases) {
            $releases = $releaseList.Items -join ","
        }
        
        # Process releases
        $releaseService.ProcessAllReleases(
            $config.defaultPaths.rootFolder,
            $releases,
            $clientCombo.SelectedItem,
            $config.defaultPaths.gitRootFolder,
            $config.folderMappings,
            $fileTracker
        )
        
        $statusLabel.Text = "Deployment completed successfully"
        [System.Windows.Forms.MessageBox]::Show("Deployment completed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $statusLabel.Text = "Deployment failed"
        [System.Windows.Forms.MessageBox]::Show("Error during deployment: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        $deployButton.Enabled = $true
        $confirmButton.Enabled = $true
    }
})

$confirmButton.Add_Click({
    if ($clientCombo.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select a target client.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ($releaseList.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please add at least one release.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    try {
        $deployButton.Enabled = $false
        $confirmButton.Enabled = $false
        $statusLabel.Text = "Confirming deployment..."
        
        # Load configuration
        $config = Get-Content $configTextBox.Text | ConvertFrom-Json
        
        # Initialize services
        $logger = [GUILogger]::new($logBox, $config.logging.logLevel, $config.logging.logPath)
        $releaseService = [ReleaseService]::new($config.defaultPaths.rootFolder, $logger)
        
        # Get selected releases
        $releases = $releaseList.SelectedItems -join ","
        if (-not $releases) {
            $releases = $releaseList.Items -join ","
        }
        
        # Confirm deployment
        $results = $releaseService.ConfirmReleaseDeployment(
            $clientCombo.SelectedItem,
            $releases,
            $config.defaultPaths.gitRootFolder,
            $config,
            $true
        )
        
        # Display results
        $successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
        $errorCount = ($results | Where-Object { $_.Status -eq "Error" }).Count
        
        $statusLabel.Text = "Confirmation completed"
        [System.Windows.Forms.MessageBox]::Show(
            "Confirmation completed:`n`nSuccess: $successCount`nErrors: $errorCount",
            "Confirmation Results",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        $statusLabel.Text = "Confirmation failed"
        [System.Windows.Forms.MessageBox]::Show("Error during confirmation: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        $deployButton.Enabled = $true
        $confirmButton.Enabled = $true
    }
})

# Load available clients
$config = Get-Content ".\config.json" | ConvertFrom-Json
$gitRootFolder = $config.defaultPaths.gitRootFolder
$clientFolders = Get-ChildItem -Path "$gitRootFolder\ClientReleases" -Directory
foreach ($folder in $clientFolders) {
    $clientCombo.Items.Add($folder.Name)
}

# Show the form
$form.ShowDialog() 