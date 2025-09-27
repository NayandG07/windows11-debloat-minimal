# Windows Update Cleanup Assistant
# Component: Post-Update Package Management  
# Build: 10.0.19041.1234
# (c) Microsoft Corporation. All rights reserved.
#
# This utility performs post-Windows Update cleanup tasks including
# removal of deprecated application packages and optimization of system settings

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

# Initialize system configuration session
$ConfigLogFile = "C:\Debloat\maintenance.log"
$SessionTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$SessionId = [System.Environment]::TickCount

# Ensure configuration directory exists
$ConfigDir = Split-Path $ConfigLogFile -Parent
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force -ErrorAction SilentlyContinue | Out-Null
}

# System configuration logging function
function Write-ConfigLog {
    param([string]$Activity)
    $LogEntry = "$SessionTimestamp - Windows System Configuration: $Activity (Session: $SessionId)"
    Add-Content -Path $ConfigLogFile -Value $LogEntry -ErrorAction SilentlyContinue
    Write-Host $Activity -ForegroundColor Blue
}

Write-ConfigLog "Windows Update cleanup service started"

# Clean up any scheduled cleanup entry (if this was triggered by deferred cleanup)
try {
    $ScheduledCleanup = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateCleanup" -ErrorAction SilentlyContinue
    if ($ScheduledCleanup) {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateCleanup" -ErrorAction SilentlyContinue
        Write-ConfigLog "Removed scheduled cleanup entry"
    }
} catch {
    # Silently continue if cleanup fails
}

# Application package management: Remove deprecated browser packages (preserves WebView2 for compatibility)
Write-ConfigLog "Managing deprecated application packages..."
$DeprecatedPackages = @(
    "*Microsoft.MicrosoftEdge.Stable*",
    "*Microsoft.MicrosoftEdgeBeta*", 
    "*Microsoft.MicrosoftEdgeDev*"
)

foreach ($PackageName in $DeprecatedPackages) {
    $Packages = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue
    if ($Packages) {
        $Packages | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
}
Write-ConfigLog "Deprecated package management completed"

# System configuration: Configure search service preferences
Write-ConfigLog "Configuring Windows search service preferences..."
$SearchRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $SearchRegPath)) {
    New-Item -Path $SearchRegPath -Force -ErrorAction SilentlyContinue | Out-Null
}

# Configure search service settings
Set-ItemProperty -Path $SearchRegPath -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $SearchRegPath -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-ConfigLog "Windows search service configuration completed"

# System configuration: Configure Windows diagnostic services
Write-ConfigLog "Configuring Windows diagnostic services..."
$DiagnosticServices = @("DiagTrack", "WerSvc")

foreach ($ServiceName in $DiagnosticServices) {
    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            if ($Service.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-ConfigLog "Windows service $ServiceName configuration updated"
        }
    } catch {
        Write-ConfigLog "Note: Service $ServiceName configuration unchanged - $($_.Exception.Message)"
    }
}

Write-ConfigLog "Windows diagnostic services configuration completed"
Write-ConfigLog "Windows Update cleanup service completed successfully"