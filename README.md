# Install_WU_Drivers

PowerShell script to find, download, and install available Windows Update driver updates on a machine.

## What this script does

- Searches Windows Update for available driver updates that are not installed.
- Downloads all detected driver updates.
- Installs the downloaded driver updates.
- Logs each step and a final install summary.
- Reports whether a reboot is required (but does not reboot automatically).

## Requirements

- Windows OS with access to Windows Update.
- PowerShell 5.1 or later.
- Script execution policy that allows running local scripts.
- Administrative privileges (recommended for successful driver installation).

## Files

- `Install_WU_Drivers.ps1`: Main script.
- `LICENSE`: Project license.

## Logging

The script writes logs to:

- `C:\PKGLOG\Install_WU_Drivers.log`

If `C:\PKGLOG` does not exist, the script creates it.

Log levels used:

- INFO
- WARNING
- ERROR

## Usage

Run from an elevated PowerShell session:

```powershell
Set-Location "<path-to-repo>"
.\Install_WU_Drivers.ps1
```

Optional: if script execution is blocked for the current process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Install_WU_Drivers.ps1
```

## Script flow

1. Initializes logging.
2. Creates a Windows Update session via COM (`Microsoft.Update.Session`).
3. Searches using query: `IsInstalled=0 and Type='Driver'`.
4. Exits cleanly if no driver updates are found.
5. Downloads and installs all found driver updates.
6. Writes per-update results and a success/failure summary.
7. Prints overall result code and reboot requirement.

## Notes

- The script suppresses automatic reboot even when one is required.
- A failed driver update includes its HResult code in the log for troubleshooting.

## Troubleshooting

- No updates found:
  - Confirm the device can reach Windows Update.
  - Verify there are driver updates applicable to the hardware.
- Access denied or install failures:
  - Run PowerShell as Administrator.
- COM/WUA errors:
  - Ensure Windows Update services are enabled and not blocked by policy.

## Disclaimer

Use in test environments first and validate driver behavior before broad deployment.
