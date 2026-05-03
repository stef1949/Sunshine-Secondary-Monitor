#Requires -Version 5.1
<#
.SYNOPSIS
Launches Moonlight on a laptop and starts the Sunshine app used as a second monitor.

.DESCRIPTION
Set HostName to your Sunshine host name or IP address, then run this script on
the laptop. You can also pass -HostName and -AppName as parameters.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $HostName = 'YOUR-SUNSHINE-HOST',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $AppName = 'Laptop Second Monitor',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $MoonlightPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MoonlightPath {
    param(
        [Parameter()]
        [string] $ConfiguredPath
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        if (Test-Path -LiteralPath $ConfiguredPath -PathType Leaf) {
            return $ConfiguredPath
        }

        throw ('Moonlight.exe was not found at "{0}".' -f $ConfiguredPath)
    }

    $candidatePaths = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidatePaths.Add((Join-Path $env:ProgramFiles 'Moonlight Game Streaming\Moonlight.exe'))
        $candidatePaths.Add((Join-Path $env:ProgramFiles 'Moonlight\Moonlight.exe'))
    }

    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $candidatePaths.Add((Join-Path $programFilesX86 'Moonlight Game Streaming\Moonlight.exe'))
        $candidatePaths.Add((Join-Path $programFilesX86 'Moonlight\Moonlight.exe'))
    }

    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidatePaths.Add((Join-Path $env:LOCALAPPDATA 'Programs\Moonlight Game Streaming\Moonlight.exe'))
        $candidatePaths.Add((Join-Path $env:LOCALAPPDATA 'Programs\Moonlight\Moonlight.exe'))
    }

    foreach ($candidatePath in $candidatePaths) {
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            return $candidatePath
        }
    }

    throw 'Moonlight.exe was not found. Install Moonlight, pass -MoonlightPath, or update the candidate paths in this script.'
}

try {
    if ($HostName -eq 'YOUR-SUNSHINE-HOST') {
        throw 'Set -HostName to your Sunshine host name or IP address, for example: .\laptop-moonlight-launcher.ps1 -HostName "192.168.1.25"'
    }

    $resolvedMoonlightPath = Get-MoonlightPath -ConfiguredPath $MoonlightPath
    $appArgument = '"{0}"' -f $AppName

    Start-Process -FilePath $resolvedMoonlightPath -ArgumentList @('stream', $HostName, $appArgument)
}
catch {
    [Console]::Error.WriteLine(('ERROR: {0}' -f $_.Exception.Message))
    exit 1
}
