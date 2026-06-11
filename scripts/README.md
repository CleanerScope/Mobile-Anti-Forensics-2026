# CleanerScope Pipeline

This folder contains the PowerShell automation for the CleanerScope acquisition workflow.

Main files:
- `Invoke-CleanerScopePipeline.ps1`
- `pipeline.config.example.json`
- > **Note:** Paths in this README and in the example configs
> use the original project layout. Replace all absolute paths
> with your own working directory before running.

## What The Script Automates

The script automates the acquisition side of the experiment:
- reset emulator/device to baseline
- uninstall target app
- clear shared-storage test locations
- optionally clear rooted system artifacts during reset
- push `Test_data4`
- install the target APK
- optionally launch the app
- capture Phase A, B, C, and D
- separate rooted and non-root branches
- keep one app capture directory with:
  - `Rooted\...`
  - `NonRoot\...`
  - one `Findings.txt`

## What The Script Does Not Automate

The script does not automate:
- in-app navigation
- selecting wipe methods inside the app UI
- pressing wipe/delete buttons
- static analysis
- forensic interpretation of the recovered artifacts

The wipe step remains manual by design. The script pauses during a full run and waits for you to complete the wipe in the app.

## Folder Output Structure

For a config with:
- `captureDirName = "SafeDelete"`

the script writes to:

```text
C:\AndroidForensicsProject\CleanerScope\captures\SafeDelete\
    Findings.txt
    Rooted\
        PhaseA_Baseline\
        PhaseB_PostClean_Logcat\
        PhaseB_PostClean\
        PhaseC_PostUninstall\
        PhaseD_PostRestart\
    NonRoot\
        PhaseA_Baseline\
        PhaseB_PostClean_Logcat\
        PhaseB_PostClean\
        PhaseC_PostUninstall\
        PhaseD_PostRestart\
```

## Prerequisites

Before running the script, make sure:
- `adb` is installed and available in `PATH`, or set `adbPath` in the config
- the target emulator/device is visible in `adb devices`
- the APK path in the config is correct
- `captureRoot` exists
- `datasetRoot` points to the dataset you want to push
- if rooted mode is used, the device supports `adb root`

## Create A Config

Start by copying the example config:

```powershell
cd C:\AndroidForensicsProject\CleanerScope\scripts
Copy-Item .\pipeline.config.example.json .\my-app.json
```

Then edit `my-app.json`.

Important fields:
- `displayName`
- `captureDirName`
- `packageName`
- `apkPath`
- `mainActivity`
- `deviceSerial`
- `captureRoot`
- `datasetRoot`

Dataset mapping fields:
- `sharedStorageTargets`
- `datasetMap`

Rooted logical pull fields:
- `rootAppPrivateSubdirs`
- `additionalRootPulls`

Reset behavior fields:
- `useRootForReset`
- `rootResetPaths`
- `resetExtraSharedPaths`

## Run The Whole Pipeline

Rooted full run:

```powershell
cd C:\AndroidForensicsProject\CleanerScope\scripts
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action Full
```

Non-root full run:

```powershell
cd C:\AndroidForensicsProject\CleanerScope\scripts
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action Full
```

## What Happens During `-Action Full`

The script runs these stages:
1. `Reset`
2. `PushData`
3. `Install`
4. `Launch`
5. `PhaseA`
6. clear logcat
7. pause for manual wipe
8. `PhaseB`
9. `PhaseC`
10. `PhaseD`

During the manual pause, the script prompts:
- perform the wipe in the app
- return to the terminal
- press Enter to continue

## Run Step By Step

If you want tighter control, run each stage separately.

Rooted example:

```powershell
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action Reset
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action PushData
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action Install
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action Launch
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action PhaseA
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action PhaseB
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action PhaseC
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode Rooted -Action PhaseD
```

Non-root example:

```powershell
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action Reset
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action PushData
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action Install
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action Launch
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action PhaseA
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action PhaseB
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action PhaseC
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\my-app.json -Mode NonRoot -Action PhaseD
```

## Notes On Branch Behavior

### Rooted

The rooted branch:
- switches `adb` to root mode
- pulls app-private files
- pulls rooted `recent_tasks`
- pulls rooted `snapshots`
- pulls rooted `usage_stats`
- can clear rooted system artifacts during reset

### NonRoot

The non-root branch:
- switches `adb` to non-root mode
- uses `dumpsys` for collection
- records snapshot access attempts as probe output
- cannot pull app-private paths directly

## Expected Manual Workflow

A typical rooted run:
1. Start the script with `-Action Full`
2. Let it reset, push data, install, and launch
3. Use the app manually to perform the wipe
4. Return to the terminal
5. Press Enter when prompted
6. Let the script finish Phase B, C, and D

## Troubleshooting

If `adb shell` hangs:
- reboot the emulator/device
- verify `adb devices`
- retry after the package and activity services are fully ready

If `adb root` fails:
- the target does not support rooted mode
- use `-Mode NonRoot`

If install fails:
- verify `apkPath`
- verify ABI compatibility
- verify Android API compatibility

If the app crashes on launch:
- the script can still capture baseline state
- but the experiment is not valid until the app runs correctly

If capture folders already exist:
- the script writes into the existing app directory
- phase folders are reused
- `Findings.txt` is appended to, not rebuilt

## Minimal Example

```powershell
cd C:\AndroidForensicsProject\CleanerScope\scripts
Copy-Item .\pipeline.config.example.json .\safe-delete.json
.\Invoke-CleanerScopePipeline.ps1 -ConfigPath .\safe-delete.json -Mode Rooted -Action Full
```

## Recommendation

Use `-Action Full` only after you have already verified:
- the app installs
- the app launches
- the target wipe workflow is reproducible manually

For new or unstable apps, use step-by-step mode first.
