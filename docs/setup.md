# First-Time Setup

This guide sets up a Windows Sunshine host so a laptop running Moonlight can act as a streamed secondary monitor.

The workflow is:

1. Windows creates a virtual display.
2. You arrange that virtual display as a second monitor.
3. Monitor Profile Switcher saves the normal and streaming layouts.
4. Sunshine runs this project script before and after the Moonlight session.
5. The laptop opens the Sunshine app in Moonlight and displays the virtual monitor fullscreen.

## 1. Install the Required Tools

Install these on the Windows host:

- Sunshine.
- A Windows virtual display driver.
- Monitor Profile Switcher.

Install Moonlight on the laptop.

Do not copy downloaded installers or executables into this repository. The only third-party executable the runtime folder needs is `MonitorSwitcher.exe`.

## 2. Create the Runtime Folder

On the Windows host, create the default folder:

```powershell
New-Item -ItemType Directory -Force -Path "C:\SunshineSecondMonitor\profiles"
```

Copy this project script into that folder:

```powershell
Copy-Item ".\scripts\SunshineSecondMonitor.ps1" "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1"
```

Copy `MonitorSwitcher.exe` from your Monitor Profile Switcher download into:

```text
C:\SunshineSecondMonitor\MonitorSwitcher.exe
```

The target layout should be:

```text
C:\SunshineSecondMonitor\
├─ SunshineSecondMonitor.ps1
├─ MonitorSwitcher.exe
├─ profiles\
└─ sunshine-second-monitor.log
```

The profile XML files and log file are created by the script.

## 3. Save Your Normal Monitor Layout

Set Windows Display Settings to your everyday monitor arrangement. This should be the state you want after a Moonlight session ends.

Then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode save-normal
```

This creates:

```text
C:\SunshineSecondMonitor\profiles\normal.xml
```

## 4. Enable and Arrange the Virtual Display

Use your virtual display driver control app or Windows Display Settings to enable the virtual monitor.

In Windows Display Settings:

1. Choose `Extend these displays`.
2. Set the virtual display resolution to match the laptop where possible.
3. Set a refresh rate supported by the laptop and network.
4. Arrange the virtual display where you want it relative to your host displays.
5. Set scaling for readable text on the laptop.

For a simple second-monitor workflow, leave your physical display as the primary display and put the virtual display to the side.

## 5. Save the Streaming Layout

With the virtual display enabled and arranged, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode save-stream
```

This creates:

```text
C:\SunshineSecondMonitor\profiles\moonlight-second-monitor.xml
```

## 6. Test Start and Stop

Before configuring Sunshine, test both profile switches manually:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode stop
```

If the display arrangement does not change as expected, fix it now and re-run `save-normal` or `save-stream`.

Check status:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode status
```

Check the log:

```powershell
Get-Content "C:\SunshineSecondMonitor\sunshine-second-monitor.log" -Tail 50
```

## 7. Find the Sunshine Display ID

Run this exact command on the host:

```powershell
& "$env:ProgramFiles\Sunshine\tools\dxgi-info.exe"
```

Look for the virtual display. Sunshine may accept a display path like:

```text
\\.\DISPLAY29
```

Newer Sunshine versions may also show a `device_id` GUID. If Sunshine exposes or prefers that value in your version, use the GUID.

Run `dxgi-info.exe` after loading the streaming layout, because display IDs are easiest to verify while the virtual display is active:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start
& "$env:ProgramFiles\Sunshine\tools\dxgi-info.exe"
```

## 8. Configure Sunshine

Follow [sunshine-configuration.md](sunshine-configuration.md) to:

- Set the Sunshine Display ID to the virtual display.
- Add the `Laptop Second Monitor` app.
- Add the do command.
- Add the undo command.

## 9. Pair and Connect Moonlight

On the laptop:

1. Install Moonlight.
2. Pair it with the Sunshine host.
3. Select the `Laptop Second Monitor` app.
4. Use fullscreen mode.
5. Match the Moonlight stream resolution to the virtual display resolution.

See [moonlight-client.md](moonlight-client.md) for client-side notes and the optional launcher script.

## 10. Recovery Tips

If you lose your expected display arrangement:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode stop
```

If Windows puts the desktop on a display you cannot see, try `Win + P`, then cycle back to a visible display mode. If the virtual display driver causes a black screen after driver updates, boot into Safe Mode and uninstall or disable the virtual display driver.
