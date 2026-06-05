# Core Evidence Examples

## Purpose

This file provides a small set of reviewer-facing evidence excerpts drawn from the CleanerScope experiment materials. The goal is to make the main evidence classes easy to inspect without requiring full traversal of the raw capture tree.

The examples below are intentionally compact and representative. They are not a substitute for the full capture folders, static-analysis notes, or mapping tables.

## Example 1: direct app-private method artifact

**Case:** Shreddit, rooted physical-device Phase B

**Artifact type:** direct dynamic method evidence

**Source artifact:**

```text
/data/data/com.palmtronix.shreddit.v1/shared_prefs/com.palmtronix.shreddit.v1_preferences.xml
```

**Recovered excerpt:**

```xml
<string name="shred.algo">US_DOD_5220</string>
<boolean name="secureDeletedMode" value="true" />
<string name="number_of_passes">1</string>
<int name="shredjob.count" value="6" />
```

**Why it matters**

- preserves the selected wipe method directly,
- preserves whether secure delete mode was enabled,
- preserves stored pass count,
- requires no selector-mapping step to identify the chosen method label.

## Example 2: mapped selector artifact

**Case:** ZERDAVA, rooted physical-device Phase B

**Artifact type:** mapped dynamic method evidence

**Source artifact:**

```text
/data/data/com.zerdava.fileshredder/shared_prefs/ZerdavaAndroidFileShredderPreferenceHelper.xml
```

**Recovered excerpt:**

```xml
<int name="KEY_SELECTED_SHRED_TYPE" value="128" />
```

**Mapped interpretation:**

```text
128 -> British HMG Enhanced
```

**Why it matters**

- preserves the selected shred type in app-private state,
- requires explicit static mapping through the decompiled registry,
- demonstrates the selector-to-method branch of CleanerScope.

## Example 3: exact runtime filename and path disclosure

**Case:** Shreddit, rooted physical-device Phase B

**Artifact type:** runtime filename/path evidence from `logcat`

**Recovered excerpt:**

```text
06-03 21:57:09.630 ... Created with options => mFile=/storage/emulated/0/DCIM/Screenshots/screenshots/Screenshot 2026-05-11 162605.png, mSizeToShred=679231, buffer, mPasses=1
06-03 21:57:09.707 ... File deleted successfully/storage/emulated/0/DCIM/Screenshots/screenshots/Screenshot 2026-05-11 162605.png
06-03 21:57:09.707 ... Shredding file/storage/emulated/0/DCIM/Screenshots/screenshots/Screenshot 2026-05-11 162554.png
06-03 21:57:09.708 ... Created with options => mFile=/storage/emulated/0/DCIM/Screenshots/screenshots/Screenshot 2026-05-11 162554.png, mSizeToShred=1374751, buffer, mPasses=1
```

**Why it matters**

- preserves exact filenames,
- preserves exact folder path,
- preserves per-file wipe execution context,
- preserves pass-count and size information during runtime.

## Example 4: system-level timeline evidence

**Case:** Shreddit, rooted physical-device Phase B

**Artifact type:** `usage_stats` workflow/timeline evidence

**Recovered excerpt:**

```text
time="2026-06-03 21:53:37" type=ACTIVITY_RESUMED package=com.palmtronix.shreddit.v1 class=com.palmtronix.shreddit.v1.view.AuthenticateActivity
time="2026-06-03 21:53:37" type=ACTIVITY_RESUMED package=com.palmtronix.shreddit.v1 class=com.palmtronix.shreddit.v1.view.StorageActivity
time="2026-06-03 21:54:30" type=ACTIVITY_RESUMED package=com.palmtronix.shreddit.v1 class=com.palmtronix.shreddit.v1.MainActivity
time="2026-06-03 21:54:44" type=FOREGROUND_SERVICE_START package=com.palmtronix.shreddit.v1 class=com.palmtronix.shreddit.v1.service.ShredderService
time="2026-06-03 21:54:45" type=FOREGROUND_SERVICE_STOP package=com.palmtronix.shreddit.v1 class=com.palmtronix.shreddit.v1.service.ShredderService
```

**Why it matters**

- confirms the app was actively used,
- reconstructs the workflow sequence,
- shows the foreground wipe service lifecycle,
- supports app-use and event chronology even when app-private reports are absent.

## Example 5: direct report artifact with file-level detail

**Case:** Android Eraser, rooted physical-device Phase B

**Artifact type:** direct app-private method/report evidence

**Source artifact:**

```text
/data/data/com.cbinnovations.androideraser/shared_prefs/com.cbinnovations.androideraser.xml
```

**Recovered excerpt summary:**

```text
method.mValue = BSI_TL_03423
method.mCycles = 8
method.mPattern = [[255],[0],[-1],[255],[-1],[0],[255],[170]]
method.mVersion = ENT
```

**Recovered file-level report content included:**

```text
reportDetail -> exact filenames, timestamps, byte counts, success/failure, errorMessage
```

**Why it matters**

- preserves a direct structured method object,
- preserves method pattern and pass count,
- preserves per-file report entries,
- combines method recovery and file-level wipe outcome evidence in one app-private artifact.

## Example 6: post-uninstall survivor evidence

**Case:** Android Eraser, rooted physical-device Phase C

**Artifact type:** system-level survivor evidence

**Recovered survivor classes:**

```text
usage_stats
recent_tasks
snapshots index
activity-state residue
```

**Interpretation summary:**

```text
App-private report and method artifacts were removed by uninstall, but system-level use-history and task/snapshot traces remained recoverable.
```

**Why it matters**

- demonstrates the persistence distinction between Phase B and Phase C,
- shows that uninstall removes the sandbox but does not necessarily erase all system-level traces,
- supports CleanerScope’s persistence analysis model.

## Example 7: post-reboot historical survivor evidence

**Case:** Shreddit, rooted physical-device Phase D

**Artifact type:** post-reboot `usage_stats` survivor

**Recovered excerpt:**

```text
time="2026-06-03 21:53:48" type=ACTIVITY_RESUMED package=com.android.settings class=com.android.settings.Settings$AppManageExternalStorageActivity ... taskRootPackage=com.palmtronix.shreddit.v1 taskRootClass=com.palmtronix.shreddit.v1.view.StorageActivity
time="2026-06-03 21:53:53" type=ACTIVITY_RESUMED package=com.android.settings class=com.android.settings.SubSettings ... taskRootPackage=com.palmtronix.shreddit.v1 taskRootClass=com.palmtronix.shreddit.v1.view.StorageActivity
```

**Why it matters**

- shows that the surviving post-reboot signal may be indirect rather than a fresh app activity,
- preserves task-root attribution back to the uninstalled app,
- demonstrates the difference between Phase D historical residue and Phase B direct method evidence.

## How to use these examples

These excerpts are intended to support three reviewer-facing claims:

1. CleanerScope recovers app-private method evidence when such artifacts exist.
2. CleanerScope can map indirect selectors to named methods when direct labels are absent.
3. CleanerScope distinguishes immediate wipe evidence from uninstall and reboot survivors.

For full context, these examples should be read together with:

- `docs/interpretation/artifact_source_inventory.md`
- `docs/interpretation/analysis_and_interpretation_rules.md`
- `docs/methodology/physical_validation_summary.md`
- `docs/static_analysis/per_app_notes/`
