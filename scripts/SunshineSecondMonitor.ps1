#Requires -Version 5.1
<#
.SYNOPSIS
Saves and restores monitor layouts for a Sunshine virtual second-monitor workflow.

.DESCRIPTION
This script wraps MonitorSwitcher.exe from Monitor Profile Switcher. It saves a
normal physical-monitor layout, saves a Moonlight/virtual-display layout, loads
the streaming layout before Sunshine starts, and restores the normal layout when
the Sunshine/Moonlight session ends.

MonitorSwitcher.exe is not bundled with this project. Download Monitor Profile
Switcher separately and place MonitorSwitcher.exe in the configured base folder.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('save-normal', 'save-stream', 'start', 'stop', 'status')]
    [string] $Mode,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $BaseDir = 'C:\SunshineSecondMonitor'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$logPath = $null

function ConvertTo-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    return [System.IO.Path]::GetFullPath($expandedPath)
}

function Write-SsmLog {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $LogPath
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff zzz'
    $entry = '{0} [{1}] {2}' -f $timestamp, $Level, $Message

    try {
        Add-Content -LiteralPath $LogPath -Value $entry -Encoding UTF8
    }
    catch {
        Write-Warning ('Could not write to log file "{0}": {1}' -f $LogPath, $_.Exception.Message)
    }
}

function Initialize-RequiredDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Path
    )

    foreach ($directory in $Path) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
    }
}

function Get-ProfilePathInfo {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $item = Get-Item -LiteralPath $Path
        return '{0} (exists, {1:n0} bytes, modified {2})' -f $Path, $item.Length, $item.LastWriteTime
    }

    return '{0} (missing)' -f $Path
}

function ConvertTo-DisplayFlagText {
    param(
        [Parameter(Mandatory = $true)]
        [uint32] $StateFlags
    )

    $flags = New-Object System.Collections.Generic.List[string]

    if (($StateFlags -band 0x00000001) -ne 0) { $flags.Add('Attached') }
    if (($StateFlags -band 0x00000004) -ne 0) { $flags.Add('Primary') }
    if (($StateFlags -band 0x00000008) -ne 0) { $flags.Add('Mirror') }
    if (($StateFlags -band 0x00000010) -ne 0) { $flags.Add('VGACompatible') }
    if (($StateFlags -band 0x00000020) -ne 0) { $flags.Add('Removable') }
    if (($StateFlags -band 0x02000000) -ne 0) { $flags.Add('Disconnected') }
    if (($StateFlags -band 0x04000000) -ne 0) { $flags.Add('Remote') }
    if (($StateFlags -band 0x08000000) -ne 0) { $flags.Add('ModesPruned') }

    if ($flags.Count -eq 0) {
        return 'None'
    }

    return ($flags -join ', ')
}

function Get-DisplayDeviceInfo {
    $typeName = 'SunshineSecondMonitor.NativeDisplay'

    if (-not ($typeName -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace SunshineSecondMonitor
{
    public static class NativeDisplay
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        public struct DISPLAY_DEVICE
        {
            public int cb;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string DeviceName;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceString;

            public int StateFlags;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceID;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceKey;
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern bool EnumDisplayDevices(
            IntPtr lpDevice,
            uint iDevNum,
            ref DISPLAY_DEVICE lpDisplayDevice,
            uint dwFlags);
    }
}
'@
    }

    $index = [uint32] 0
    $devices = New-Object System.Collections.Generic.List[object]

    while ($true) {
        $displayDevice = New-Object SunshineSecondMonitor.NativeDisplay+DISPLAY_DEVICE
        $displayDevice.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($displayDevice)

        $found = [SunshineSecondMonitor.NativeDisplay]::EnumDisplayDevices([IntPtr]::Zero, $index, [ref] $displayDevice, 0)
        if (-not $found) {
            break
        }

        $stateFlags = [uint32] $displayDevice.StateFlags
        $devices.Add([pscustomobject] @{
                Display     = $displayDevice.DeviceName
                Description = $displayDevice.DeviceString
                Flags       = ConvertTo-DisplayFlagText -StateFlags $stateFlags
                StateHex    = ('0x{0:X8}' -f $stateFlags)
            })

        $index++
    }

    return $devices
}

function Get-CimMonitorInfo {
    try {
        $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop
    }
    catch {
        return @()
    }

    foreach ($monitor in $monitors) {
        $name = ($monitor.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char] $_ }) -join ''
        if ([string]::IsNullOrWhiteSpace($name)) {
            $name = '(no friendly name)'
        }

        [pscustomobject] @{
            InstanceName = $monitor.InstanceName
            Name         = $name
            Active       = $monitor.Active
        }
    }
}

function Test-MonitorSwitcherFile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $MonitorSwitcherPath
    )

    if (-not (Test-Path -LiteralPath $MonitorSwitcherPath -PathType Leaf)) {
        throw ('MonitorSwitcher.exe was not found at "{0}". Download Monitor Profile Switcher separately and copy MonitorSwitcher.exe into the base directory.' -f $MonitorSwitcherPath)
    }
}

function Test-ProfileFile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProfilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ModeName
    )

    if (-not (Test-Path -LiteralPath $ProfilePath -PathType Leaf)) {
        throw ('The {0} profile does not exist at "{1}". Run the appropriate save mode first.' -f $ModeName, $ProfilePath)
    }
}

function Invoke-MonitorSwitcher {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('save', 'load')]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProfilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $MonitorSwitcherPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $LogPath
    )

    Test-MonitorSwitcherFile -MonitorSwitcherPath $MonitorSwitcherPath

    $argument = '-{0}:"{1}"' -f $Action, $ProfilePath
    Write-SsmLog -Level INFO -LogPath $LogPath -Message ('Running MonitorSwitcher.exe {0} for "{1}".' -f $Action, $ProfilePath)

    $process = Start-Process `
        -FilePath $MonitorSwitcherPath `
        -ArgumentList $argument `
        -WorkingDirectory $WorkingDirectory `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) {
        throw ('MonitorSwitcher.exe exited with code {0} while trying to {1} "{2}".' -f $process.ExitCode, $Action, $ProfilePath)
    }

    Write-SsmLog -Level INFO -LogPath $LogPath -Message ('MonitorSwitcher.exe completed {0} for "{1}".' -f $Action, $ProfilePath)
}

function Show-Status {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Context
    )

    Write-Output 'Sunshine Second Monitor status'
    Write-Output ('Computer: {0}' -f $env:COMPUTERNAME)
    Write-Output ('User: {0}\{1}' -f $env:USERDOMAIN, $env:USERNAME)
    Write-Output ('Base directory: {0}' -f $Context.BaseDir)
    Write-Output ('MonitorSwitcher.exe: {0}' -f (Get-ProfilePathInfo -Path $Context.MonitorSwitcherPath))
    Write-Output ('Profiles directory: {0}' -f $Context.ProfilesDir)
    Write-Output ('Normal profile: {0}' -f (Get-ProfilePathInfo -Path $Context.NormalProfilePath))
    Write-Output ('Streaming profile: {0}' -f (Get-ProfilePathInfo -Path $Context.StreamProfilePath))
    Write-Output ('Log path: {0}' -f $Context.LogPath)
    Write-Output ''
    Write-Output 'Detected Windows display devices:'

    try {
        $displayDevices = @(Get-DisplayDeviceInfo)
        if ($displayDevices.Count -eq 0) {
            Write-Output '  No display devices were returned by EnumDisplayDevices.'
        }
        else {
            $displayDevices | Format-Table -AutoSize | Out-String | Write-Output
        }
    }
    catch {
        Write-Output ('  Could not query display devices through EnumDisplayDevices: {0}' -f $_.Exception.Message)
    }

    $cimMonitors = @(Get-CimMonitorInfo)
    if ($cimMonitors.Count -gt 0) {
        Write-Output 'Detected monitor identity records:'
        $cimMonitors | Format-Table -AutoSize | Out-String | Write-Output
    }
}

try {
    $resolvedBaseDir = ConvertTo-FullPath -Path $BaseDir
    $profilesDir = Join-Path -Path $resolvedBaseDir -ChildPath 'profiles'
    $logPath = Join-Path -Path $resolvedBaseDir -ChildPath 'sunshine-second-monitor.log'
    $monitorSwitcherPath = Join-Path -Path $resolvedBaseDir -ChildPath 'MonitorSwitcher.exe'
    $normalProfilePath = Join-Path -Path $profilesDir -ChildPath 'normal.xml'
    $streamProfilePath = Join-Path -Path $profilesDir -ChildPath 'moonlight-second-monitor.xml'

    Initialize-RequiredDirectory -Path @($resolvedBaseDir, $profilesDir)

    $context = @{
        BaseDir             = $resolvedBaseDir
        ProfilesDir         = $profilesDir
        LogPath             = $logPath
        MonitorSwitcherPath = $monitorSwitcherPath
        NormalProfilePath   = $normalProfilePath
        StreamProfilePath   = $streamProfilePath
    }

    Write-SsmLog -Level INFO -LogPath $logPath -Message ('Mode "{0}" started. BaseDir="{1}".' -f $Mode, $resolvedBaseDir)

    switch ($Mode) {
        'save-normal' {
            # save-normal captures the everyday layout used when Moonlight is not connected.
            Invoke-MonitorSwitcher `
                -Action save `
                -ProfilePath $normalProfilePath `
                -MonitorSwitcherPath $monitorSwitcherPath `
                -WorkingDirectory $resolvedBaseDir `
                -LogPath $logPath

            Write-Output ('Saved normal monitor layout to "{0}".' -f $normalProfilePath)
        }

        'save-stream' {
            # save-stream captures the virtual-display layout that Sunshine should stream.
            Invoke-MonitorSwitcher `
                -Action save `
                -ProfilePath $streamProfilePath `
                -MonitorSwitcherPath $monitorSwitcherPath `
                -WorkingDirectory $resolvedBaseDir `
                -LogPath $logPath

            Write-Output ('Saved streaming monitor layout to "{0}".' -f $streamProfilePath)
        }

        'start' {
            # start loads the virtual-display layout before Sunshine begins the session.
            Test-ProfileFile -ProfilePath $streamProfilePath -ModeName 'streaming'
            Invoke-MonitorSwitcher `
                -Action load `
                -ProfilePath $streamProfilePath `
                -MonitorSwitcherPath $monitorSwitcherPath `
                -WorkingDirectory $resolvedBaseDir `
                -LogPath $logPath

            Write-Output ('Loaded streaming monitor layout from "{0}".' -f $streamProfilePath)
        }

        'stop' {
            # stop restores the normal physical-monitor layout after the session ends.
            Test-ProfileFile -ProfilePath $normalProfilePath -ModeName 'normal'
            Invoke-MonitorSwitcher `
                -Action load `
                -ProfilePath $normalProfilePath `
                -MonitorSwitcherPath $monitorSwitcherPath `
                -WorkingDirectory $resolvedBaseDir `
                -LogPath $logPath

            Write-Output ('Restored normal monitor layout from "{0}".' -f $normalProfilePath)
        }

        'status' {
            # status prints paths, profile state, log location, and detected display devices.
            Show-Status -Context $context
        }
    }

    Write-SsmLog -Level INFO -LogPath $logPath -Message ('Mode "{0}" completed successfully.' -f $Mode)
}
catch {
    $message = $_.Exception.Message

    if (-not [string]::IsNullOrWhiteSpace($logPath)) {
        Write-SsmLog -Level ERROR -LogPath $logPath -Message ('Mode "{0}" failed: {1}' -f $Mode, $message)
    }

    [Console]::Error.WriteLine(('ERROR: {0}' -f $message))
    exit 1
}
