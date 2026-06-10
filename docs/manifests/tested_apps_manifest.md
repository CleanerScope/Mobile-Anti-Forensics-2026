# Tested Apps Manifest

This manifest defines the fixed app scope for the CleanerScope replication package.
Only the 9 successful apps retained in the paper are included here. Failed trials, discarded apps, and abandoned scripts are intentionally excluded.

## Scope rules

- `emulator_tested = yes` means the app is part of the core experiment set used in the paper.
- `physical_validation_in_paper = yes` means the app is included in the paper-facing physical-device validation summary.
- `physical_validation_in_paper = no` does not imply the app was never explored physically; it means the app is not part of the public paper-facing physical-validation evidence set.

## App Set

| App | Package | versionName | versionCode | APK SHA-256 | Emulator Tested | Physical Validation In Paper | Notes |
|---|---|---:|---:|---|---|---|---|
| Android Eraser | `com.cbinnovations.androideraser` | `1.5` | `1500` | `D49AEEA54BFF5D5B0B288DED50B3ABA28AA86D58CF3AD64F64DA5376F8B1516A` | yes | yes | Strong app-private report artifact; physically validated on rooted Android 14 |
| Andro Shredder | `com.apparillos.android.androshredder` | `2.0.7` | `207` | `8460C49884BE9D1D0F1E11E410E051004848B7492859382E1208EB1CEF3EF41C` | yes | no | Selector/intensity mapping case retained in emulator/static-analysis set |
| iShredder | `com.projectstar.ishredder.android.standard` | `7.3` | `7302` | `4B028F66D02D40DA4017EEE66A5A7C3885940598CB7A933AEF09E2FE2D5ED579` | yes | no | Strong static and dynamic method evidence in emulator study |
| Shredder | `com.trictech.shred` | `1.1` | `2` | `D1F6E1DE1B6EA333C71DF6B27BE7BE27CCE221DFFA0AE592DC2C28D71B0C5BA2` | yes | no | Strong method evidence in emulator study |
| Shreddit | `com.palmtronix.shreddit.v1` | `5.36.251203` | `89` | `605EE6E011E9E0B461848AA96679830ABE66161DFA3DF32C62D0E22A57C514A9` | yes | yes | Physically validated; strong prefs plus runtime filename/path traces |
| Safe Delete | `com.seeroo.safedeleteApp` | `1.7` | `7` | `0670A7BB17F133A8277270BB9AEAC7CAEDE8067D734DB3E7C078037A5F65FA5D` | yes | no | Code-derived/fixed-method case in emulator study |
| Wipe Files | `uk.org.platitudes.wipefiles` | `0.3` | `3` | `F83D5C25D94F690FDE91EA5E7BDCFE96539A7EBA8E9FFFE902FA3D1AE24CA1AA` | yes | no | Strong emulator evidence; not installable on Android 14 due target SDK floor |
| ZERDAVA | `com.zerdava.fileshredder` | `1.01.7725` | `7725` | `793B24AEF79077CFFB82F1C60D379BA7E6790882ABB0AC6FE12078B30D4FC562` | yes | yes | Physically validated; selector-based method recovery and filename/path traces |
| ZeroFill | `com.ekyoulabs.zerofill` | `2.0.0-130426` | `20000` | `EEC10FD0EF4ED8E4F0044135996C012B5D37B4BBB01B7932FBFCF3636149646E` | yes | no | Included in paper app set; excluded from paper physical-validation summary |

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
