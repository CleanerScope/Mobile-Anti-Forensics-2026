# Extractor Output Examples

## Purpose

This file provides compact reviewer-facing examples of the normalized JSON emitted by:

- `scripts/Extract-CleanerScopeEvidence.ps1`

These examples are drawn from retained study capture folders and are intended to show what the bounded extractor returns for direct, mapped, configuration-driven, and code-only cases.

## Scope note

These examples do **not** imply universal support for arbitrary Android wiping applications or future app versions. They only demonstrate the retained nine-app study set documented in this package.

## Example 1: Android Eraser

Input capture folder:

```text
C:\AndroidForensicsProject\CleanerScope\captures\AndroidEraser_Physical\Rooted\PhaseB_PostClean_LogicalRun
```

Output:

```json
{
  "app": "Android Eraser",
  "package": "com.cbinnovations.androideraser",
  "version_name": "1.5",
  "version_code": "1500",
  "artifact_path": "app_private\\shared_prefs\\com.cbinnovations.androideraser.xml",
  "raw_value": "savekey_reports.method",
  "evidence_class": "direct_dynamic_method_evidence",
  "mapped_label": "BSI_TL_03423",
  "implementation_note": "Direct stored method object or report field; no selector mapping required",
  "extracted_from": [
    "savekey_reports"
  ]
}
```

## Example 2: Andro Shredder

Input capture folder:

```text
C:\AndroidForensicsProject\CleanerScope\captures\AndroShredder2\PhaseB_PostClean_LogicalRun
```

Output:

```json
{
  "app": "Andro Shredder",
  "package": "com.apparillos.android.androshredder",
  "version_name": "2.0.7",
  "version_code": "207",
  "artifact_path": "app_private_shared_prefs\\shared_prefs\\MainActivity.xml",
  "raw_value": "3",
  "evidence_class": "mapped_dynamic_method_evidence",
  "mapped_label": "U.S. DoD 5220.22-M (E) / British HMG IS5 (E)",
  "implementation_note": "Label is recoverable, but implementation still uses the same random buffer model with different pass count only",
  "recovered_key": "shredIntensity",
  "wipe_intensity": null
}
```

## Example 3: ZERDAVA

Input capture folder:

```text
C:\AndroidForensicsProject\CleanerScope\captures\ZERDAVA_Physical\Rooted\PhaseB_PostClean_LogicalRun
```

Output:

```json
{
  "app": "ZERDAVA",
  "package": "com.zerdava.fileshredder",
  "version_name": "1.01.7725",
  "version_code": "7725",
  "artifact_path": "app_private\\shared_prefs\\ZerdavaAndroidFileShredderPreferenceHelper.xml",
  "raw_value": "128",
  "evidence_class": "mapped_dynamic_method_evidence",
  "mapped_label": "British HMG Enhanced",
  "implementation_note": "Selector mapping verified from decompiled registry; implementation pattern [0xFF,0x00,random]",
  "recovered_key": "KEY_SELECTED_SHRED_TYPE"
}
```

## Example 4: Wipe Files

Input capture folder:

```text
C:\AndroidForensicsProject\CleanerScope\captures\WipeFiles2\PhaseB_PostClean_LogicalRun
```

Output:

```json
{
  "app": "Wipe Files",
  "package": "uk.org.platitudes.wipefiles",
  "version_name": "0.3",
  "version_code": "3",
  "artifact_path": "app_private\\shared_prefs\\uk.org.platitudes.wipefiles_preferences.xml",
  "raw_value": {
    "number_passes": "3",
    "zero_wipe": "true",
    "block_size": "8192"
  },
  "evidence_class": "direct_configuration_evidence",
  "mapped_label": "Configuration-driven wipe method",
  "implementation_note": "No named standard algorithms; effective behavior is derived from number_passes, zero_wipe, and block_size"
}
```

## Example 5: Safe Delete

Input capture folder:

```text
C:\AndroidForensicsProject\CleanerScope\captures\SafeDelete\Rooted\PhaseB_PostClean_Logical
```

Output:

```json
{
  "app": "Safe Delete",
  "package": "com.seeroo.safedeleteApp",
  "version_name": "1.7",
  "version_code": "7",
  "artifact_path": "N/A",
  "raw_value": "code_only=true",
  "evidence_class": "code_only_reconstruction",
  "mapped_label": "Fixed one-pass zero overwrite",
  "implementation_note": "No user-selectable method artifact exists; overwrite model derived directly from PermanentDeleteTask",
  "rootmode": null
}
```

## Interpretation

These examples show the four evidence patterns used in the study:

- direct dynamic method evidence
- mapped dynamic method evidence
- direct configuration evidence
- code-only reconstruction

Together, they provide a concrete reviewer-facing demonstration that the package contains a bounded implementation of the framework-level extraction step for the retained study apps.
