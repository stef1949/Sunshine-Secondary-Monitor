# Moonlight Laptop Client

The laptop is the Moonlight client. It does not create the virtual display; it only receives the stream from Sunshine and shows it fullscreen.

## Basic Setup

1. Install Moonlight on the laptop.
2. Make sure the laptop and host are on the same network, or configure your preferred remote access network.
3. Pair Moonlight with the Sunshine host.
4. In Moonlight settings, choose a resolution and refresh rate that match the virtual display on the host.
5. Open the `Laptop Second Monitor` app.
6. Switch Moonlight to fullscreen.

## Recommended Client Settings

Start conservative, then increase quality:

- Resolution: 1920x1080 for first test, then the laptop's native resolution if performance is good.
- Refresh rate: 60 Hz for first test.
- Bitrate: increase until desktop text is clear without network stutter.
- Fullscreen: enabled.
- V-sync/frame pacing: use Moonlight defaults first.

If the laptop panel is high DPI, set Windows scaling on the host virtual display to a readable value.

## Using the Laptop as a Second Monitor

When connected, Windows treats the virtual display like an extended monitor. You can move windows onto it from the host.

Important behavior:

- The laptop is showing a streamed desktop, so latency depends on encoding, network, and Moonlight settings.
- Clipboard, keyboard shortcuts, and pointer capture depend on Moonlight client behavior.
- Closing the Moonlight session should trigger Sunshine's undo command and restore the host layout.
- If the host layout does not restore, run the `stop` mode manually on the host.

## Optional Launcher Script

This repository includes:

```text
examples\laptop-moonlight-launcher.ps1
```

Copy or reference it on the laptop, then edit the host name or pass it as a parameter:

```powershell
.\laptop-moonlight-launcher.ps1 -HostName "192.168.1.25"
```

The launcher looks for `Moonlight.exe` in common install paths and runs:

```text
Moonlight.exe stream HOST "Laptop Second Monitor"
```

Use the exact app name configured in Sunshine.
