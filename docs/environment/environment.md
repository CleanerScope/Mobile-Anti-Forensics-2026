# Environment

## Purpose

This document records the main technical environment used in the CleanerScope study and in the reviewer-facing replication package. It consolidates the host, emulator, physical-device, ADB, and static-analysis context needed to understand how the experiments were executed.

This file should be read alongside:

- `docs/static_analysis/jadx_version_and_flags.md`
- `docs/methodology/experiment_workflow_and_phases.md`

## Host environment

The working environment for the project was a Windows-based host with:

- PowerShell as the primary shell
- Android Debug Bridge (`adb`) for device and emulator interaction
- JADX for static analysis

The release package focuses on the reproducible workflow rather than freezing the full host software bill of materials, but the key analysis- and acquisition-relevant components are documented below.

## Emulator environment

The main comparative study used an Android emulator environment based on:

- **AVD name:** `Pixel_3a`
- **Display profile:** `Pixel 3a`
- **Target:** `android-28`
- **System image:** `system-images\android-28\google_apis\x86_64\`
- **Architecture:** `x86_64`
- **ABI:** `x86_64`
- **RAM:** `4096 MB`
- **Data partition size:** `32G`
- **SD card size:** `512M`
- **Tag:** `Google APIs`

This corresponds to an Android 9 emulator environment and was the primary comparative environment for the nine-app study.

## Emulator boot-state and reproducibility note

The inspected AVD configuration included:

- `fastboot.forceFastBoot=yes`
- `fastboot.forceColdBoot=no`

This means emulator-managed fast-boot state was enabled by default. Exact experimental state therefore depended not only on the nominal AVD definition, but also on the writable runtime state managed by the emulator between runs.

## QCOW2 overlay note

The emulator environment should be treated as **overlay-backed**, not as a simple flat-image setup.

The project state previously confirmed that writable emulator images included QCOW2 overlays in addition to base image files. This matters because:

- exact test state is not represented by a single flat userdata image alone,
- Quick Boot or snapshot state can preserve prior runtime state,
- reproducibility requires controlling overlay and snapshot state between runs.

For reviewer-facing documentation, the correct interpretation is:

- the Android 9 emulator used writable QCOW2-managed overlay state,
- and exact rerun conditions depend on controlled reset of that state.

## Physical-device environment

The paper-facing physical validation used a rooted Android tablet:

- **Model:** `SM-T220`
- **Android version:** `14`
- **Access model:** rooted via Magisk `su`

This device was used for targeted external-validity validation rather than for the full nine-app comparative matrix.

Paper-facing physical validation apps:

- Android Eraser
- Shreddit
- ZERDAVA

## Root model

Two shell contexts mattered during the project:

- standard shell context:
  - `uid=2000(shell)`
- rooted shell context:
  - `uid=0(root)` through `su`

This distinction is important because many artifact classes required root access, including:

- app-private sandbox inspection under `/data/data/<package>/`
- rooted recent-task inspection
- rooted snapshot enumeration
- system-managed persistence paths

## ADB assumptions

The acquisition workflow assumed:

- `adb` connectivity to emulator or device
- permission to use `adb shell`
- rooted escalation via `su` where required

Operationally, the project used `adb` for:

- package checks
- file staging
- `logcat` clear and dump
- `dumpsys` collection
- uninstall/reboot control
- rooted shell access
- artifact pull and preservation

## Static-analysis environment

The shared static-analysis baseline was:

- **Tool:** `JADX`
- **Version:** `1.5.5`

Observed flags:

- `--show-bad-code`
- `--comments-level debug`

Standard baseline:

```text
jadx 1.5.5 --show-bad-code
```

Additional debug-oriented pass where needed:

```text
jadx 1.5.5 --show-bad-code --comments-level debug
```

These settings were especially important for:

- obfuscated applications
- selector-dispatch logic
- code paths with decompiler control-flow issues

## Static-analysis input handling

The study used two static-analysis input modes:

### Direct APK analysis

Used when the application package was directly available as a standard APK.

### XAPK extraction followed by main-APK analysis

Used when the app was distributed as an XAPK or split-package archive. In those cases:

- the main APK was extracted first,
- JADX was run on the extracted main package.

Documented examples include:

- ZERDAVA
- ZeroFill
- iShredder

## Environment-sensitive interpretation

Several parts of the study depend on environment details and should be interpreted accordingly:

- emulator reset behavior depends on overlay/snapshot control,
- rooted physical-device artifact visibility can differ from emulator visibility,
- some recent-task or snapshot artifacts on Android 14 may appear in newer or less readable formats,
- decompilation output can vary across JADX versions,
- write durability semantics depend partly on the platform and file path, not only on the app code.

## Scope note

This environment note applies to:

- the nine successful applications retained in the study,
- the Android 9 emulator comparative environment,
- and the rooted Android 14 physical-device validation used in the paper.

It does not attempt to document discarded app candidates, failed trials, or unrelated exploratory environments.

## Summary

CleanerScope was executed in a mixed environment:

- a Windows host,
- an Android 9 `Pixel_3a` emulator with QCOW2-backed writable state,
- and a rooted Android 14 physical tablet for targeted validation.

Static analysis used JADX `1.5.5`, primarily with `--show-bad-code`, and with `--comments-level debug` when required for difficult code paths. These environment details are important because both acquisition behavior and decompilation output are sensitive to platform and tool configuration.
