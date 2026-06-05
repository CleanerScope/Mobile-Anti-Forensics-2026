# Android Eraser

## App identity

- App: Android Eraser
- Package: `com.cbinnovations.androideraser`
- versionName: `1.5`
- versionCode: `1500`
- Launcher: `com.cbinnovations.androideraser.Firstlaunch`
- Static-analysis source file:
  - `C:\AndroidForensicsProject\CleanerScope\static analysis findings\andrioderaser\Static_Analysis_Findings.txt`

## Why this app matters in CleanerScope

Android Eraser is the clearest direct-evidence case in the study.
Its static-analysis value is not primarily selector mapping. Instead, it shows a strong direct bridge between:
- the stored method object in app-private preferences
- the named wipe algorithm selected by the user
- the overwrite implementation used by the wipe engine

It is also one of the richest apps for report persistence, because it stores full wipe-session records in app-private preferences.

## Primary artifact paths inspected

### App-private SharedPreferences
- `/data/data/com.cbinnovations.androideraser/shared_prefs/com.cbinnovations.androideraser.xml`

### Relevant keys
- `cb_default_method`
- `generate_report`
- `cb_is_premium`
- `savekey_reports`

### Other relevant implementation paths
- algorithm classes under:
  - `shredder/shred/methods/algorithms/`
- core wipe executor:
  - `shredder/shred/ShredderData.java`

## Recovered method model

Android Eraser defines six named wipe methods in the method enum and implements each as a discrete algorithm class.

| User-facing name | Enum value | Cycles |
|---|---|---:|
| `0x00` | `N0x00` | `1` |
| `CSEC ITSG-06` | `CSEC_ITSG06` | `3` |
| `DoD 5220.22-M (E)` | `DoD5220_22_ME` | `3` |
| `BSI-2011-VS` | `BSI_2011_VS` | `5` |
| `NATO Standard` | `NATO` | `7` |
| `BSI TL-03423` | `BSI_TL_03423` | `8` |

## Stored method artifact

The selected method is stored in SharedPreferences key `cb_default_method` as a Gson-serialized JSON object.

Relevant stored fields include:
- `mValue`
- `mCycles`
- `mPattern`
- `mVersion`

### Interpretation class
- Evidence class: **direct dynamic method evidence**
- Mapping class: **direct**

Reason:
- the recovered JSON `mValue` directly names the algorithm enum
- `mCycles` directly records the pass count
- no selector mapping step is needed

## Overwrite implementation summary

### Core executor
- `ShredderData.Clear.override()`
- `deleteFile()`

### Primary file-path I/O primitive
- `RandomAccessFile(file, "rws")`

Interpretation:
- the primary path intends synchronous writes for both content and metadata
- this is stronger than ordinary buffered-file output

### Per-pass behavior
For each cycle:
- the code reads the current per-pass pattern from `mEraseMethod.mPattern[i]`
- fixed byte values are expanded into overwrite buffers
- `-1` is treated as a random pass

### Randomness
- random passes use `SecureRandom`
- this is a meaningful implementation-strength point compared with apps that use `java.util.Random`

## Directly observed algorithm patterns

| Algorithm | Observed pass pattern |
|---|---|
| `Shred0x00` | `{0x00}` |
| `CSEC ITSG-06` | `{0xFF}`, `{0x00}`, `{random}` |
| `DoD 5220.22-M (E)` | `{0x35}`, `{0xCA}`, `{random}` |
| `BSI-2011-VS` | `{random}`, `{random}`, `{0xFF}`, `{0x00}`, `{0x00}` |
| `NATO Standard` | `{0x00}`, `{0xFF}`, `{0x00}`, `{0xFF}`, `{0x00}`, `{0xFF}`, `{random}` |
| `BSI TL-03423` | `{0xFF}`, `{0x00}`, `{random}`, `{0xFF}`, `{random}`, `{0x00}`, `{0xFF}`, `{0xAA}` |

## Forensically important report storage

The highest-value static-analysis finding is that Android Eraser stores a report list in SharedPreferences key `savekey_reports`.

Stored report fields include:
- `method`
- `startTime`
- `endTime`
- `totalBytes`
- `success`
- `errors`
- `reportDetail`
- `appVersion`
- `appCode`
- `deviceVersion`

This makes Android Eraser a strong direct-report app, because the static analysis predicts exactly the kind of rich app-private artifact later recovered dynamically in the experiment.

## Supporting implementation notes

### Post-overwrite behavior
The app performs additional cleanup and anti-recovery steps after overwrite, including:
- overwrite-MFT-style file-name churn (`overrideMFT()`)
- UUID rename-before-delete through `SessionIdentifierGenerator.delete()`
- media-index cleanup through `MediaScannerConnection` and `ContentResolver.delete()`

### Free-space wipe
The free-space wipe creates a temp file named:
- `.AnShFreeSpace`

This is useful because the presence of that file during live acquisition can indicate that a free-space wipe was active or interrupted.

## Confidence classification

### Directly observed in code
- six algorithm definitions
- exact cycle counts
- exact per-pass pattern arrays
- `SecureRandom` use for random passes
- `RandomAccessFile("rws")` in the primary wipe path
- `cb_default_method` storage
- `savekey_reports` storage

### Mapped from code/resources
- enum values to user-facing labels
- pass-count interpretation from constructor definitions

### Inferred but not runtime-validated by static analysis alone
- the exact storage-layer effect of `"rws"` depends on underlying filesystem and platform behavior
- the SAF path is weaker because no explicit `channel.force(true)` is called

## Static-analysis conclusion

Android Eraser is the most implementation-transparent app in the successful app set.
Its stored method object maps directly and unambiguously to a named wipe method, and the code confirms the pass structure for each algorithm. Static analysis also predicts a rich app-private report artifact through `savekey_reports`, which makes this app especially strong for dynamic forensic recovery.

## Suggested supporting snippets for release package

### Method-object storage concept
```text
SharedPreferences key: cb_default_method
Fields: mValue, mCycles, mPattern, mVersion
```

### Report-storage concept
```text
SharedPreferences key: savekey_reports
Fields: method, startTime, endTime, totalBytes, success, errors, reportDetail
```

### Strong implementation note
```text
Primary wipe path uses RandomAccessFile(file, "rws") and SecureRandom for random passes.
```