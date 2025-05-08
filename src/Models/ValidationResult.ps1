#Requires -Version 5.1

class ValidationResult {
    [string]$File
    [string]$Release
    [string]$Status
    [string]$Details

    ValidationResult([string]$file, [string]$release) {
        $this.File = $file
        $this.Release = $release
        $this.Status = "OK"
        $this.Details = ""
    }

    [void] SetError([string]$details) {
        $this.Status = "ERROR"
        $this.Details = $details
    }

    [void] SetWarning([string]$details) {
        $this.Status = "WARNING"
        $this.Details = $details
    }
} 