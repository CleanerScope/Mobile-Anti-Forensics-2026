# Artifact Source Inventory

## Purpose

This inventory records where CleanerScope recovered its most relevant evidence for each of the nine successful applications retained in the study. The goal is to make the evidentiary basis of each app-level interpretation explicit and reproducible.

The inventory distinguishes:

- **app-private artifacts** recovered from the application sandbox,
- **system-level artifacts** recovered from Android services or system-managed paths,
- the **strongest artifact source** for each app,
- the **method-evidence class** used in interpretation.

This file is intended to be read alongside:

- `docs/manifests/tested_apps_manifest.md`
- `docs/static_analysis/per_app_notes/`
- `mappings/selector_method_mappings.csv`
- `mappings/overwrite_behavior_notes.csv`

## Evidence class definitions

- **Direct dynamic method evidence**: the recovered artifact already stores the method as a readable label or structured method object.
- **Mapped dynamic method evidence**: the recovered artifact stores a selector, intensity, or other indirect value that must be mapped to a label using code or resources.
- **Direct configuration evidence**: the recovered artifact stores configuration values that directly determine wipe behavior, even though no named standard method exists.
- **Code-derived only**: no live method artifact was recovered; the wipe method is reconstructed from code inspection.

## Per-app inventory

### Android Eraser

- **Primary app-private artifacts**
  - `shared_prefs/com.cbinnovations.androideraser.xml`
  - `savekey_reports`
  - `cb_default_method`
- **Primary system-level artifacts**
  - `dumpsys usagestats`
  - `recent_tasks`
  - snapshots / recents traces where available
- **Strongest artifact source**
  - app-private `shared_prefs` report and method object
- **Method-evidence class**
  - direct dynamic method evidence
- **Filename source**
  - `savekey_reports` reportDetail, plus Phase B logcat
- **Notes**
  - strongest combination of direct method object, per-file report data, timestamps, and outcome records

### Andro Shredder

- **Primary app-private artifacts**
  - `shared_prefs/com.apparillos.android.androshredder.MainActivity.xml`
  - `shared_prefs/com.apparillos.android.androshredder_preferences.xml`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces when present
- **Strongest artifact source**
  - activity-private `shredIntensity` / `wipeIntensity` values plus completion-state preferences
- **Method-evidence class**
  - mapped dynamic method evidence
- **Filename source**
  - Phase B logcat, plus `shredFinishedFiles` for screenshots
- **Notes**
  - selector value identifies the displayed label; code inspection is required to show that all methods collapse to the same random-buffer behavior

### iShredder

- **Primary app-private artifacts**
  - `shared_prefs/com.projectstar.ishredder.android.standard_preferences.xml`
  - `ishredder_default_method`
  - `reports_v2`
  - `Reports.xml`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces when present
- **Strongest artifact source**
  - serialized method object in app-private preferences, corroborated by report storage
- **Method-evidence class**
  - direct dynamic method evidence
- **Filename source**
  - none recovered; `Reports.xml` / `reports_v2` lacked per-file filename disclosure
- **Notes**
  - one of the strongest direct method-storage apps; report artifacts may also preserve per-file paths

### Shredder

- **Primary app-private artifacts**
  - `shared_prefs/com.trictech.shred_preferences.xml`
  - `algorithm`
  - `type`
  - optional SAF tree URI preference
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / task traces when present
- **Strongest artifact source**
  - direct `algorithm` value in app-private preferences
- **Method-evidence class**
  - direct dynamic method evidence
- **Filename source**
  - Phase B logcat (media-scanning entries)
- **Notes**
  - path-dependent implementation means the same stored method label may correspond to different actual pass behavior on direct vs SAF storage

### Shreddit

- **Primary app-private artifacts**
  - `shared_prefs/com.palmtronix.shreddit.v1_preferences.xml`
  - `shred.algo`
  - `number_of_passes`
  - `secureDeletedMode`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces
- **Strongest artifact source**
  - direct app-private algorithm label, supported by runtime filename/path traces in `logcat`
- **Method-evidence class**
  - direct dynamic method evidence
- **Filename source**
  - Phase B logcat
- **Notes**
  - especially strong when app-private method state and runtime file-path disclosure are both available

### Safe Delete

- **Primary app-private artifacts**
  - `shared_prefs/com.seeroo.safedeleteApp_preferences.xml`
  - `rootmode`
  - `URI`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces when present
- **Strongest artifact source**
  - static code inspection of `PermanentDeleteTask`
- **Method-evidence class**
  - code-derived only
- **Filename source**
  - indirect Phase B logcat exception traces
- **Notes**
  - `rootmode` and `URI` describe deletion-path context only; they do not store any method selector, pass count, algorithm label, or overwrite pattern. Safe Delete therefore remains a code-derived only method case.

### Wipe Files

- **Primary app-private artifacts**
  - `shared_prefs/uk.org.platitudes.wipefiles_preferences.xml`
  - `number_passes`
  - `zero_wipe`
  - `block_size`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces
- **Strongest artifact source**
  - direct configuration values in app-private preferences
- **Method-evidence class**
  - direct configuration evidence
- **Filename source**
  - limited Phase B logcat file-view intent traces
- **Notes**
  - no named standard method exists; the interpretive value comes from configuration recovery plus code validation of the likely partial-overwrite defect

### ZERDAVA

- **Primary app-private artifacts**
  - `shared_prefs/ZerdavaAndroidFileShredderPreferenceHelper.xml`
  - `KEY_SELECTED_SHRED_TYPE`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces
- **Strongest artifact source**
  - app-private selector value mapped through decompiled registry logic
- **Method-evidence class**
  - mapped dynamic method evidence
- **Filename source**
  - Phase B logcat progress/completion traces
- **Notes**
  - strongest selector-to-method mapping case in the set; runtime traces can also disclose filenames and folder access

### ZeroFill

- **Primary app-private artifacts**
  - `/data/data/com.ekyoulabs.zerofill/files/datastore/shred_prefs.preferences_pb`
  - `last_algorithm_id`
  - `secure_erase_mode`
- **Primary system-level artifacts**
  - `logcat`
  - `dumpsys usagestats`
  - recents / activity traces
- **Strongest artifact source**
  - DataStore method ID plus secure-erase control flag
- **Method-evidence class**
  - direct dynamic method evidence
- **Filename source**
  - persisted system `external.db` entries
- **Notes**
  - key interpretive condition is that `secure_erase_mode=false` means the app deletes without overwrite

## Cross-app summary

Across the nine retained applications:

- **Direct dynamic method evidence** was strongest for:
  - Android Eraser
  - iShredder
  - Shredder
  - Shreddit
  - ZeroFill
- **Mapped dynamic method evidence** was strongest for:
  - Andro Shredder
  - ZERDAVA
- **Direct configuration evidence** was strongest for:
  - Wipe Files
- **Code-derived only interpretation** was required for:
  - Safe Delete

In general, the highest-value method artifacts were recovered from:

- app-private `shared_prefs`,
- app-private DataStore files,
- app-private report objects,
- and only secondarily from system-level traces.

System-level artifacts such as `dumpsys usagestats`, recents, snapshots, and `logcat` were most valuable for:

- app-use detection,
- timeline reconstruction,
- file-selection disclosure,
- and post-uninstall/post-reboot survivor analysis.
