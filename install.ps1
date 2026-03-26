[CmdletBinding()]
param(
    [string[]]$Tools = @("stipe", "mycelium", "hyphae", "rhizome", "cortina"),
    [string]$Prefix = $(if ($env:MYCELIUM_BIN_DIR) { $env:MYCELIUM_BIN_DIR } elseif ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "Basidiocarp\bin" } else { Join-Path $HOME "AppData\Local\Basidiocarp\bin" }),
    [switch]$NoConfigure,
    [string]$Version = "",
    [switch]$Uninstall,
    [Alias("h")]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AllTools = @("stipe", "mycelium", "hyphae", "rhizome", "cortina")
$GitHubOrg = "basidiocarp"

function Write-Info([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Warning $Message
}

function Fail([string]$Message) {
    throw $Message
}

function Show-Usage {
    @"
Basidiocarp Ecosystem Installer

Usage:
  install.ps1 [-Tools stipe,mycelium] [-Prefix PATH] [-NoConfigure] [-Version VER] [-Uninstall]

Examples:
  irm https://raw.githubusercontent.com/basidiocarp/.github/main/install.ps1 | iex
  .\install.ps1 -Tools mycelium,hyphae
  .\install.ps1 -Prefix "$env:LOCALAPPDATA\Basidiocarp\bin"
  .\install.ps1 -NoConfigure
  .\install.ps1 -Uninstall
"@ | Write-Host
}

function Normalize-Tools([string[]]$RequestedTools) {
    $normalized = @()
    foreach ($entry in $RequestedTools) {
        foreach ($tool in ($entry -split ",")) {
            $trimmed = $tool.Trim().ToLowerInvariant()
            if ($trimmed) {
                $normalized += $trimmed
            }
        }
    }

    foreach ($tool in $normalized) {
        if ($tool -notin $AllTools) {
            Fail "Unknown tool '$tool'. Available: $($AllTools -join ', ')"
        }
    }

    $ordered = foreach ($tool in $AllTools) {
        if ($tool -in $normalized) {
            $tool
        }
    }

    if (-not $ordered) {
        Fail "No tools selected."
    }

    return $ordered
}

function Get-TargetTriple {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        ([System.Runtime.InteropServices.Architecture]::X64) { return "x86_64-pc-windows-msvc" }
        ([System.Runtime.InteropServices.Architecture]::Arm64) { return "aarch64-pc-windows-msvc" }
        default { Fail "Unsupported Windows architecture: $arch" }
    }
}

function New-TempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString("N"))
    [System.IO.Directory]::CreateDirectory($path) | Out-Null
    return $path
}

function Get-DownloadUrl([string]$Tool, [string]$Target) {
    $asset = "$Tool-$Target.zip"
    if ($Version) {
        return "https://github.com/$GitHubOrg/$Tool/releases/download/v$Version/$asset"
    }

    return "https://github.com/$GitHubOrg/$Tool/releases/latest/download/$asset"
}

function Install-Tool([string]$Tool, [string]$Target, [string]$InstallDir) {
    $asset = "$Tool-$Target.zip"
    $url = Get-DownloadUrl -Tool $Tool -Target $Target
    $tmpDir = New-TempDirectory
    $archivePath = Join-Path $tmpDir $asset
    $extractDir = Join-Path $tmpDir "extract"
    $binaryName = "$Tool.exe"
    $installedPath = Join-Path $InstallDir $binaryName

    try {
        Write-Info "Downloading $Tool ($Target)..."
        Invoke-WebRequest -Uri $url -OutFile $archivePath

        Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force

        $binaryPath = Join-Path $extractDir $binaryName
        if (-not (Test-Path $binaryPath)) {
            Fail "Binary '$binaryName' not found in archive."
        }

        Move-Item -Path $binaryPath -Destination $installedPath -Force
        Write-Ok "$Tool installed to $installedPath"
        return $true
    }
    catch {
        Write-Warn "Failed to install $Tool from $url"
        Write-Warn $_.Exception.Message
        return $false
    }
    finally {
        if (Test-Path $tmpDir) {
            Remove-Item -Path $tmpDir -Recurse -Force
        }
    }
}

function Invoke-Uninstall([string]$InstallDir) {
    Write-Info "Uninstalling Basidiocarp tools from $InstallDir..."
    foreach ($tool in $AllTools) {
        $toolPath = Join-Path $InstallDir "$tool.exe"
        if (Test-Path $toolPath) {
            Remove-Item -Path $toolPath -Force
            Write-Ok "$tool removed"
        }
        else {
            Write-Warn "$tool not found in $InstallDir"
        }
    }

    Write-Host ""
    Write-Info "Uninstall complete."
    Write-Info "MCP server registrations may remain in your editor configs."
    Write-Info "Run 'stipe uninstall --all' before removing stipe for full cleanup."
}

function Show-Verification([string[]]$InstalledTools, [string]$InstallDir) {
    foreach ($tool in $InstalledTools) {
        $toolPath = Join-Path $InstallDir "$tool.exe"
        if (Test-Path $toolPath) {
            try {
                $versionOutput = & $toolPath --version 2>&1
                if ($LASTEXITCODE -eq 0 -and $versionOutput) {
                    Write-Ok ($versionOutput | Select-Object -First 1)
                }
                else {
                    Write-Ok "$tool installed"
                }
            }
            catch {
                Write-Ok "$tool installed"
            }
        }
    }
}

function Show-PathGuidance([string]$InstallDir) {
    $pathEntries = ($env:PATH -split ";") | Where-Object { $_ }
    if ($pathEntries -contains $InstallDir) {
        return
    }

    Write-Host ""
    Write-Warn "$InstallDir is not in your PATH."
    Write-Host "Add it for the current session with:"
    Write-Host "  `$env:Path = `"$InstallDir;`$env:Path`""
    Write-Host "Persist it for your user account with:"
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$InstallDir', 'User')"
    Write-Host "Then open a new PowerShell session."
}

function Invoke-Configure([string]$InstallDir) {
    $stipePath = Join-Path $InstallDir "stipe.exe"
    if (-not (Test-Path $stipePath)) {
        Write-Warn "stipe not installed. Skipping editor configuration."
        Write-Warn "Run 'stipe init' manually after installing stipe."
        return
    }

    Write-Host ""
    Write-Info "Configuring hosts..."
    try {
        & $stipePath init
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "stipe init had issues. Run 'stipe doctor' to diagnose."
        }
    }
    catch {
        Write-Warn "stipe init had issues. Run 'stipe doctor' to diagnose."
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

$selectedTools = Normalize-Tools -RequestedTools $Tools

Write-Host ""
Write-Host "Basidiocarp Ecosystem Installer" -ForegroundColor White
Write-Host ""

if ($Uninstall) {
    Invoke-Uninstall -InstallDir $Prefix
    exit 0
}

$target = Get-TargetTriple

[System.IO.Directory]::CreateDirectory($Prefix) | Out-Null

$installed = @()
$failed = @()
foreach ($tool in $selectedTools) {
    if (Install-Tool -Tool $tool -Target $target -InstallDir $Prefix) {
        $installed += $tool
    }
    else {
        $failed += $tool
    }
}

if (-not $NoConfigure) {
    Invoke-Configure -InstallDir $Prefix
}

Write-Host ""
Write-Info "Summary"
Show-Verification -InstalledTools $installed -InstallDir $Prefix

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Warn "Failed: $($failed -join ', ')"
}

Show-PathGuidance -InstallDir $Prefix
