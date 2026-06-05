# Tested Apps Manifest

This manifest defines the fixed app scope for the CleanerScope replication package.
Only the 9 successful apps retained in the paper are included here. Failed trials, discarded apps, and abandoned scripts are intentionally excluded.

## Scope rules

- `emulator_tested = yes` means the app is part of the core experiment set used in the paper.
- `physical_validation_in_paper = yes` means the app is included in the paper-facing physical-device validation summary.
- `physical_validation_in_paper = no` does not imply the app was never explored physically; it means the app is not part of the public paper-facing physical-validation evidence set.

## App Set

| App | Package | versionName | versionCode | Emulator Tested | Physical Validation In Paper | Notes |
|---|---|---:|---:|---|---|---|
| Android Eraser | `com.cbinnovations.androideraser` | `1.5` | `1500` | yes | yes | Strong app-private report artifact; physically validated on rooted Android 14 |
| Andro Shredder | `com.apparillos.android.androshredder` | `2.0.7` | `207` | yes | no | Selector/intensity mapping case retained in emulator/static-analysis set |
| iShredder | `com.projectstar.ishredder.android.standard` | `7.3` | `7302` | yes | no | Strong static and dynamic method evidence in emulator study |
| Shredder | `com.trictech.shred` | `1.1` | `2` | yes | no | Strong method evidence in emulator study |
| Shreddit | `com.palmtronix.shreddit.v1` | `5.36.251203` | `89` | yes | yes | Physically validated; strong prefs plus runtime filename/path traces |
| Safe Delete | `com.seeroo.safedeleteApp` | `1.7` | `7` | yes | no | Code-derived/fixed-method case in emulator study |
| Wipe Files | `uk.org.platitudes.wipefiles` | `0.3` | `3` | yes | no | Strong emulator evidence; not installable on Android 14 due target SDK floor |
| ZERDAVA | `com.zerdava.fileshredder` | `1.01.7725` | `7725` | yes | yes | Physically validated; selector-based method recovery and filename/path traces |
| ZeroFill | `com.ekyoulabs.zerofill` | `2.0.0-130426` | `20000` | yes | no | Included in paper app set; excluded from paper physical-validation summary |

## Source of truth

The machine-readable source of truth for this table is:
- `docs/manifests/tested_apps_manifest.csv`

## Notes on public package scope

- This manifest preserves the full 9-app experimental scope used in the paper.
- The paper-facing physical-validation section should use only:
  - Android Eraser
  - Shreddit
  - ZERDAVA
- ZeroFill remains part of the 9-app paper set, but it is intentionally excluded from the public paper-facing physical-validation summary.