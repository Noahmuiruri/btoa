# Arnold Addon Installer for Blender 5.x
# This script removes any existing Arnold addon and installs the current version

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Arnold Addon Installer for Blender 5.x" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the current script directory (where the addon files are)
$AddonSourcePath = $PSScriptRoot
$AddonFolderName = Split-Path $AddonSourcePath -Leaf

Write-Host "Addon source: $AddonSourcePath" -ForegroundColor Gray
Write-Host "Addon name: $AddonFolderName" -ForegroundColor Gray
Write-Host ""

# Define Blender AppData paths
$BlenderAppData = "$env:APPDATA\Blender Foundation\Blender"

# Check if Blender AppData folder exists
if (-not (Test-Path $BlenderAppData)) {
    Write-Host "ERROR: Blender folder not found at: $BlenderAppData" -ForegroundColor Red
    Write-Host "Please make sure Blender 5.x is installed and has been run at least once." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found Blender AppData folder: $BlenderAppData" -ForegroundColor Green
Write-Host ""

# Find Blender 5.x version folders only
$BlenderVersions = Get-ChildItem -Path $BlenderAppData -Directory | Where-Object { $_.Name -match '^5\.\d+$' }

if ($BlenderVersions.Count -eq 0) {
    Write-Host "ERROR: No Blender 5.x version folders found in $BlenderAppData" -ForegroundColor Red
    Write-Host ""
    Write-Host "Looking for folders like: 5.0, 5.1, 5.2, etc." -ForegroundColor Yellow
    Write-Host "Please run Blender 5.x at least once to create the necessary folders." -ForegroundColor Yellow
    Write-Host ""
    
    # Show what versions were found
    $AllVersions = Get-ChildItem -Path $BlenderAppData -Directory | Where-Object { $_.Name -match '^\d+\.\d+$' }
    if ($AllVersions.Count -gt 0) {
        Write-Host "Found other Blender versions (not compatible):" -ForegroundColor Gray
        foreach ($version in $AllVersions) {
            Write-Host "  - $($version.Name)" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "This addon requires Blender 5.0 or higher." -ForegroundColor Yellow
    }
    
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found Blender 5.x versions:" -ForegroundColor Cyan
foreach ($version in $BlenderVersions) {
    Write-Host "  - Blender $($version.Name)" -ForegroundColor Green
}
Write-Host ""

# Ask user which version to install to
$targetVersions = @()

if ($BlenderVersions.Count -eq 1) {
    # Only one version found, auto-select it
    $targetVersions = $BlenderVersions
    Write-Host "Auto-selecting Blender $($BlenderVersions[0].Name)..." -ForegroundColor Green
    Write-Host ""
}
else {
    # Multiple versions found, let user choose
    Write-Host "Select Blender 5.x version to install addon:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $BlenderVersions.Count; $i++) {
        Write-Host "  [$($i + 1)] Blender $($BlenderVersions[$i].Name)"
    }
    Write-Host "  [A] Install to ALL Blender 5.x versions" -ForegroundColor Green
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Enter your choice"

    if ($choice -eq "Q" -or $choice -eq "q") {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    elseif ($choice -eq "A" -or $choice -eq "a") {
        $targetVersions = $BlenderVersions
        Write-Host "Installing to ALL Blender 5.x versions..." -ForegroundColor Green
    }
    elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $BlenderVersions.Count) {
        $targetVersions = @($BlenderVersions[[int]$choice - 1])
        Write-Host "Installing to Blender $($targetVersions[0].Name)..." -ForegroundColor Green
    }
    else {
        Write-Host "Invalid choice. Installation cancelled." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host ""
}

# Process each target version
$successCount = 0
$failCount = 0

foreach ($version in $targetVersions) {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Processing Blender $($version.Name)..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    $AddonsPath = Join-Path $version.FullName "scripts\addons"
    $TargetPath = Join-Path $AddonsPath $AddonFolderName
    
    # Create addons directory if it doesn't exist
    if (-not (Test-Path $AddonsPath)) {
        Write-Host "Creating addons directory..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $AddonsPath -Force | Out-Null
            Write-Host "  Created: $AddonsPath" -ForegroundColor Green
        }
        catch {
            Write-Host "  ERROR: Failed to create addons directory: $_" -ForegroundColor Red
            $failCount++
            continue
        }
    }
    
    # Remove existing addon if it exists
    if (Test-Path $TargetPath) {
        Write-Host "Removing existing addon..." -ForegroundColor Yellow
        try {
            Remove-Item -Path $TargetPath -Recurse -Force
            Write-Host "  Removed: $TargetPath" -ForegroundColor Green
        }
        catch {
            Write-Host "  ERROR: Failed to remove existing addon: $_" -ForegroundColor Red
            Write-Host "  Please close Blender and try again." -ForegroundColor Yellow
            $failCount++
            continue
        }
    }
    
    # Copy addon files
    Write-Host "Installing addon..." -ForegroundColor Yellow
    try {
        Copy-Item -Path $AddonSourcePath -Destination $AddonsPath -Recurse -Force
        Write-Host "  Installed to: $TargetPath" -ForegroundColor Green
        $successCount++
        
        # Verify installation
        if (Test-Path (Join-Path $TargetPath "__init__.py")) {
            Write-Host "  Verification: OK" -ForegroundColor Green
        }
        else {
            Write-Host "  WARNING: __init__.py not found. Installation may be incomplete." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ERROR: Failed to copy addon files: $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Start (or restart) Blender 5.x" -ForegroundColor White
    Write-Host "2. Go to Edit > Preferences > Add-ons" -ForegroundColor White
    Write-Host "3. Search for 'Arnold'" -ForegroundColor White
    Write-Host "4. Enable the 'Arnold Render Engine (BtoA)' addon" -ForegroundColor White
    Write-Host ""
    Write-Host "The addon is now compatible with Blender 5.x!" -ForegroundColor Green
    Write-Host "Version: 0.6.2 (Blender 5.0+ compatible)" -ForegroundColor Gray
}

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "Some installations failed. Common solutions:" -ForegroundColor Yellow
    Write-Host "- Close all Blender instances and try again" -ForegroundColor White
    Write-Host "- Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "- Check file permissions in the Blender AppData folder" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"
