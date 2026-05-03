# Sunshine Configuration

This document configures Sunshine to stream the virtual display and run monitor layout commands at session start and stop.

## Find the Display ID

Load the streaming layout first:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start
```

Then run this exact command:

```powershell
& "$env:ProgramFiles\Sunshine\tools\dxgi-info.exe"
```

Find the virtual display in the output.

Sunshine may ask for `Display ID`. Depending on the Sunshine version and capture path, the correct value may be a display path such as:

```text
\\.\DISPLAY29
```

In newer Sunshine versions, `dxgi-info.exe` may also show a `device_id` GUID. If Sunshine exposes that field and your version expects it, use the GUID instead of the `\\.\DISPLAY...` path.

If Sunshine streams the wrong monitor later, re-run `dxgi-info.exe` while the streaming layout is active and update this setting.

## Set the Sunshine Display

Open the Sunshine web UI on the host. The local URL is commonly:

```text
https://localhost:47990
```

Find the display or video configuration field for the output display, then enter the virtual display ID you found with `dxgi-info.exe`.

Save and restart Sunshine if the UI asks you to.

## Add the Sunshine App

Create a new app with these values.

App name:

```text
Laptop Second Monitor
```

Command:

```text
cmd.exe /c start explorer.exe
```

Do command:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start
```

Undo command:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode stop
```

The command opens Explorer as a harmless desktop process. The important work is done by the do and undo commands.

## Why Do and Undo Commands Matter

The do command runs before the app launches. It loads:

```text
C:\SunshineSecondMonitor\profiles\moonlight-second-monitor.xml
```

The undo command runs after the app closes. It restores:

```text
C:\SunshineSecondMonitor\profiles\normal.xml
```

If the session closes unexpectedly and the layout is not restored, run the stop command manually.

## Optional Base Directory

If you installed the runtime files somewhere else, include `-BaseDir` in both commands.

Do command example:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Tools\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start -BaseDir "D:\Tools\SunshineSecondMonitor"
```

Undo command example:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Tools\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode stop -BaseDir "D:\Tools\SunshineSecondMonitor"
```

## Service and User Session Notes

Monitor layout changes usually need to run in the interactive Windows user session. If Sunshine is installed as a service and the prep command cannot change displays, try:

- Running Sunshine in the same user session you use for the desktop.
- Confirming the do/undo commands work from a normal PowerShell window.
- Checking `C:\SunshineSecondMonitor\sunshine-second-monitor.log`.
- Checking Sunshine logs for command execution failures.

Avoid running the monitor switching script as administrator unless your display driver or Monitor Profile Switcher setup requires it. The normal workflow should not require admin after the virtual display driver is installed.
