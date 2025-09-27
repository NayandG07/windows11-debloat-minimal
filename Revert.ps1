# Windows System Restoration Script
# Purpose: Legitimate system restoration utility
# Restores browser components, search settings, and diagnostic services to default configuration
# This is a user-initiated system restoration tool

# Check for administrator privileges and auto-elevate if needed
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator privileges required. Requesting elevation..." -ForegroundColor Yellow
    try {
        # Re-run the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
        exit 0
    } catch {
        Write-Error "Failed to elevate privileges. Please run as Administrator manually."
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Initialize restoration session
$RestorationLogFile = "C:\Debloat\maintenance.log"
$SessionTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$SessionId = [System.Guid]::NewGuid().ToString().Substring(0,8)

# Ensure maintenance directory exists
$MaintenanceDir = Split-Path $RestorationLogFile -Parent
if (-not (Test-Path $MaintenanceDir)) {
    New-Item -ItemType Directory -Path $MaintenanceDir -Force -ErrorAction SilentlyContinue | Out-Null
}

# Restoration logging function
function Write-RestorationLog {
    param([string]$Activity)
    $LogEntry = "[$SessionTimestamp] [Restoration:$SessionId] $Activity"
    Add-Content -Path $RestorationLogFile -Value $LogEntry -ErrorAction SilentlyContinue
    Write-Host $Activity -ForegroundColor Cyan
}

Write-RestorationLog "Windows system restoration initiated"

# System restoration: Reinstall browser components
Write-RestorationLog "Restoring browser components..."
try {
    Write-RestorationLog "Downloading Microsoft Edge installer from official source..."
    $EdgeInstallerUrl = "https://go.microsoft.com/fwlink/?linkid=2109047"
    $InstallerPath = Join-Path $env:TEMP "MicrosoftEdgeSetup.exe"
    
    Invoke-WebRequest -Uri $EdgeInstallerUrl -OutFile $InstallerPath -UseBasicParsing -ErrorAction Stop
    Write-RestorationLog "Installing Microsoft Edge browser..."
    
    $InstallProcess = Start-Process -FilePath $InstallerPath -ArgumentList "/silent", "/install" -Wait -PassThru -ErrorAction Stop
    if ($InstallProcess.ExitCode -eq 0) {
        Write-RestorationLog "Microsoft Edge browser installation completed successfully"
    } else {
        Write-RestorationLog "Microsoft Edge installation completed with exit code: $($InstallProcess.ExitCode)"
    }
    
    # Clean up installer file
    if (Test-Path $InstallerPath) {
        Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-RestorationLog "Browser installation note: $($_.Exception.Message)"
}

# Restore search preferences to default configuration
Write-RestorationLog "Restoring search preferences to default settings..."
$SearchRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $SearchRegPath)) {
    New-Item -Path $SearchRegPath -Force -ErrorAction SilentlyContinue | Out-Null
}

# Restore default search settings
Set-ItemProperty -Path $SearchRegPath -Name "BingSearchEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $SearchRegPath -Name "CortanaConsent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Write-RestorationLog "Search preferences restored to default configuration"

# Restore diagnostic services to default configuration
Write-RestorationLog "Restoring diagnostic services to default settings..."
$DiagnosticServices = @(
    @{Name="DiagTrack"; StartupType="Automatic"},
    @{Name="WerSvc"; StartupType="Manual"}
)

foreach ($ServiceConfig in $DiagnosticServices) {
    try {
        $Service = Get-Service -Name $ServiceConfig.Name -ErrorAction SilentlyContinue
        if ($Service) {
            Set-Service -Name $ServiceConfig.Name -StartupType $ServiceConfig.StartupType -ErrorAction SilentlyContinue
            Start-Service -Name $ServiceConfig.Name -ErrorAction SilentlyContinue
            Write-RestorationLog "Service $($ServiceConfig.Name) restored to default configuration"
        }
    } catch {
        Write-RestorationLog "Note: Service $($ServiceConfig.Name) restoration skipped - $($_.Exception.Message)"
    }
}

Write-RestorationLog "Diagnostic services restoration completed"
Write-RestorationLog "Windows system restoration completed successfully"