# Troubleshooting

Start every investigation with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode status
```

Then check:

```powershell
Get-Content "C:\SunshineSecondMonitor\sunshine-second-monitor.log" -Tail 80
```

## Sunshine Streams the Wrong Monitor

Fixes:

- Run `-Mode start` manually so the streaming layout is active.
- Run:

  ```powershell
  & "$env:ProgramFiles\Sunshine\tools\dxgi-info.exe"
  ```

- Find the virtual display and update Sunshine's Display ID.
- Try the `\\.\DISPLAY...` value first, for example `\\.\DISPLAY29`.
- If your Sunshine version shows and expects a `device_id` GUID, use that GUID.
- Re-save the streaming layout after confirming Windows is extended to the virtual display.
- Restart Sunshine after changing display settings.

## Display ID Changed After Reboot

Windows can re-enumerate displays after reboot, GPU driver updates, dock changes, USB-C changes, or virtual display driver reinstallations.

Fixes:

- Load the streaming layout.
- Re-run `dxgi-info.exe`.
- Update Sunshine's Display ID.
- Prefer a `device_id` GUID if your Sunshine version supports it and the GUID remains stable.
- Keep physical monitors plugged into the same ports.
- Re-save `save-stream` after the display order is stable.

## MonitorSwitcher.exe Missing

The script does not bundle Monitor Profile Switcher.

Fixes:

- Download Monitor Profile Switcher separately from its official project page.
- Copy `MonitorSwitcher.exe` to:

  ```text
  C:\SunshineSecondMonitor\MonitorSwitcher.exe
  ```

- Make sure the file is named exactly `MonitorSwitcher.exe`.
- Run `-Mode status` and confirm the script reports the file as present.

## Virtual Display Does Not Appear

Fixes:

- Confirm the virtual display driver is installed.
- Reboot after driver installation.
- Check Device Manager for the virtual display adapter.
- Open Windows Display Settings and choose `Detect`.
- Open the virtual display driver's control app and confirm at least one display is enabled.
- If you recently updated GPU or chipset drivers, reinstall or repair the virtual display driver.
- If a driver update caused a black screen, boot into Safe Mode and uninstall or disable the virtual display driver before reinstalling it.

## Monitor Layout Does Not Restore Correctly

Fixes:

- Run the stop command manually:

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode stop
  ```

- Arrange your physical monitors correctly in Windows Settings.
- Re-run `save-normal`.
- Confirm `normal.xml` exists in `C:\SunshineSecondMonitor\profiles\`.
- Run Sunshine as the same Windows user that saved the profiles.
- Avoid changing monitor ports or docking setup between saving and restoring profiles.
- If Windows puts the desktop on an invisible display, use `Win + P` to cycle back to a visible display mode.

## Moonlight Shows Black Screen

Fixes:

- Confirm Sunshine is streaming the virtual display, not a disabled or disconnected display.
- Load the streaming layout before connecting.
- Set the virtual display to a common resolution and refresh rate, such as 1920x1080 at 60 Hz, for testing.
- Disable HDR until SDR works reliably.
- Update GPU drivers.
- Restart Sunshine after changing the Display ID.
- Test with Moonlight windowed first, then switch to fullscreen.
- Check Sunshine logs for encoder or capture errors.

## Text Looks Blurry

Fixes:

- Set the virtual display resolution to the laptop panel's native resolution, or use a clean lower resolution such as 1920x1080.
- Match Moonlight's stream resolution to the virtual display resolution.
- Use a stable bitrate high enough for desktop text.
- Set Windows scaling on the virtual display to a comfortable value, commonly 100%, 125%, or 150%.
- Avoid odd fractional scaling combinations across the host and virtual display.
- Disable HDR while troubleshooting text clarity.

## Sunshine Cannot Run the Prep Command

Fixes:

- Copy the command exactly, including quotes:

  ```text
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode start
  ```

- Test the command from a normal PowerShell window.
- Check `C:\SunshineSecondMonitor\sunshine-second-monitor.log`.
- Check Sunshine logs for command execution errors.
- Make sure Sunshine runs in the interactive user session that owns the desktop.
- Confirm `MonitorSwitcher.exe` exists and the XML profiles have been saved.
- If using a custom folder, add the same `-BaseDir` value to both do and undo commands.

## PowerShell Execution Policy Blocks the Script

The Sunshine command examples use:

```text
-ExecutionPolicy Bypass
```

That bypass applies only to that PowerShell process.

Other fixes:

```powershell
Unblock-File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Only change execution policy if you understand the effect. For most users, the command-local bypass is enough.

## Windows Rearranges Displays After Sleep/Wake

Fixes:

- Run `stop`, then `start`, to force the saved layout back.
- Re-save both profiles after the physical monitor and dock setup is stable.
- Keep monitors connected to the same GPU ports.
- Avoid changing dock or USB-C topology between sessions.
- Update GPU drivers if Windows frequently loses monitor identity.
- Re-run `dxgi-info.exe` after wake if Sunshine starts streaming the wrong display.

## Collecting Useful Debug Information

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SunshineSecondMonitor\SunshineSecondMonitor.ps1" -Mode status
Get-Content "C:\SunshineSecondMonitor\sunshine-second-monitor.log" -Tail 120
& "$env:ProgramFiles\Sunshine\tools\dxgi-info.exe"
```

If Monitor Profile Switcher itself fails, run `MonitorSwitcher.exe` directly from `cmd.exe` or PowerShell to see whether it can save and load profiles outside Sunshine.
