# Physical Validation Summary

## Purpose

This document summarizes the targeted rooted physical-device validation runs retained in the paper-facing release materials. The goal of these runs was not to reproduce the full nine-app comparative study on new hardware, but to test whether the main CleanerScope artifact classes also appeared on a contemporary rooted Android device outside the Android 9 emulator environment.

Only the three physical validation apps used in the paper are included here:

- Android Eraser
- Shreddit
- ZERDAVA

ZeroFill is intentionally excluded from this public physical-validation summary because it was not retained as a paper-facing physical validation case.

## Device context

Validated physical device:

- **Model:** Samsung `SM-T220`
- **Android version:** `14`
- **Access model:** rooted via `su`

These runs were executed as targeted external-validity checks using the same general four-phase structure applied in the main study:

- Phase A baseline
- Phase B immediate post-wipe
- Phase C post-uninstall
- Phase D post-reboot

## What was being validated

The physical runs were used to test whether CleanerScope could still recover:

- app-private method artifacts,
- app-private report/configuration artifacts,
- exact filenames or folder-access traces,
- `usage_stats` timeline traces,
- recents/task traces,
- meaningful post-uninstall and post-reboot survivors.

The physical validation therefore focused on **artifact-class transferability**, not on reproducing every result from the emulator one-for-one.

## App 1: Android Eraser

### Main result

Android Eraser reproduced strongly on the rooted Android 14 device.

### Strongest Phase B artifact

The strongest physical Phase B artifact was the app-private shared-preferences file:

```text
/data/data/com.cbinnovations.androideraser/shared_prefs/com.cbinnovations.androideraser.xml
```

This artifact preserved:

- direct method evidence,
- structured `savekey_reports`,
- start/end timestamps,
- bytes processed,
- exact filename-bearing report entries,
- per-item success/failure state.

### Method recovery

Direct method recovery succeeded from app-private report-bearing state. This reproduced the same high-value artifact model seen in the emulator study.

### Timeline and app-use

Strong system-level traces were also recovered from:

- `dumpsys usagestats`
- recents/task state
- activity-state output

### Persistence

- **Phase C:** app-private report/method artifacts were removed by uninstall, but system-level traces such as `usage_stats` and task/snapshot residue remained.
- **Phase D:** some system-level survivors remained visible after reboot, while app-private method/report state remained absent.

### Interpretation

Android Eraser provided the strongest physical confirmation that CleanerScope can recover direct app-private method and report artifacts on a rooted modern Android device.

## App 2: Shreddit

### Main result

Shreddit also reproduced strongly on the rooted Android 14 device, but with a different evidence profile from Android Eraser.

### Strongest Phase B artifacts

The strongest app-private artifact was:

```text
/data/data/com.palmtronix.shreddit.v1/shared_prefs/com.palmtronix.shreddit.v1_preferences.xml
```

Recovered values included:

- `shred.algo`
- `secureDeletedMode`
- `number_of_passes`
- `shredjob.count`

### Runtime filename/path traces

Shreddit also preserved strong runtime filename and path traces in `logcat`, especially for the screenshot-target run. These traces disclosed:

- exact screenshot filenames,
- the screenshot folder path,
- runtime wipe progress and deletion messages.

This made Shreddit one of the strongest physical examples of combining:

- app-private method storage, and
- runtime filename/path disclosure.

### Timeline and app-use

Strong Phase B timeline traces were recovered from:

- `dumpsys usagestats`
- recents/task metadata
- foreground-service activity for the shred service

### Persistence

- **Phase C:** uninstall removed the app-private method/configuration artifact; `usage_stats` remained the strongest survivor.
- **Phase D:** `usage_stats` still preserved package-level and task-root historical references after reboot, while recents text hits and activity-state residue were no longer useful.

### Interpretation

Shreddit showed that CleanerScope can recover direct method state and exact runtime filename/path traces on a physical rooted Android 14 device, but that the richer evidence surface contracts quickly after uninstall.

## App 3: ZERDAVA

### Main result

ZERDAVA reproduced strongly as the clearest selector-mapping case on the physical device.

### Strongest Phase B artifact

The strongest app-private artifact was:

```text
/data/data/com.zerdava.fileshredder/shared_prefs/ZerdavaAndroidFileShredderPreferenceHelper.xml
```

This preserved:

- `KEY_SELECTED_SHRED_TYPE`

Recovered example:

```xml
<int name="KEY_SELECTED_SHRED_TYPE" value="128" />
```

### Method recovery

Selector recovery succeeded and mapped to the expected method label through the decompiled registry logic. This is the strongest physical confirmation of the selector-to-method branch of CleanerScope.

### Filename and path traces

ZERDAVA also preserved useful runtime filename/path disclosure in `logcat`, including:

- screenshot filename updates,
- screenshot-folder access traces.

### Timeline and app-use

Strong supporting traces were recovered from:

- `dumpsys usagestats`
- recents/task traces
- activity-state output

### Persistence

- **Phase C:** uninstall removed the app-private selector artifact; `usage_stats` remained the strongest survivor and a small amount of activity-state residue remained.
- **Phase D:** `usage_stats` remained the only strong survivor; recents text hits and activity-state residue were no longer useful.

### Interpretation

ZERDAVA showed that CleanerScope's selector-mapping branch remains viable on a rooted modern Android device and that filename/path disclosure can still be recovered even when the app-private surface is minimal.

## Cross-app comparison

The three physical validation apps covered three complementary evidence models:

- **Android Eraser:** direct method object plus structured app-private wipe report
- **Shreddit:** direct method label plus strong runtime filename/path disclosure
- **ZERDAVA:** selector-based method recovery plus runtime filename/path disclosure

Together, these runs validate that CleanerScope is not limited to one narrow artifact model.

## Emulator vs physical-device differences

The physical Android 14 device did not always expose artifacts in the same way as the emulator. Observed differences included:

- stricter access to some rooted system-managed paths,
- less convenient access to snapshots and some task artifacts,
- newer or less human-readable task formats in some cases,
- smaller or more volatile survivor surfaces after uninstall/reboot.

However, the physical runs still reproduced the main high-level pattern observed in the emulator:

- strongest direct method evidence appears in Phase B,
- uninstall removes app-private method/report state,
- system-level survivor traces can remain through Phase C and sometimes into Phase D.

## Summary

The rooted Android 14 validation runs show that CleanerScope's main artifact classes remain recoverable beyond the emulator:

- direct app-private method/report artifacts,
- direct app-private method labels,
- selector-based method artifacts,
- runtime filename/path traces,
- `usage_stats` timeline survivors.

These results strengthen the paper's external-validity position without claiming that the physical device reproduced every emulator artifact in identical form.
