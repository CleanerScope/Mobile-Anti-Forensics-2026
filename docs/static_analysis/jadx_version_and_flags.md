# JADX Version And Flags

This note centralizes the static-analysis environment details used to derive selector-to-method mappings and overwrite-routine interpretations for the 9 successful apps in the CleanerScope study.

## Primary decompilation tool

- Tool: `JADX`
- Version: `1.5.5`

This version is explicitly recorded in the per-app static-analysis findings and should be treated as the reference version for reproducibility.

## Observed command-line options

Across the saved findings, the following JADX options were explicitly documented:

- `--show-bad-code`
- `--comments-level debug`

## How these options were used

### Standard pass
The standard pass used:

```text
jadx 1.5.5 --show-bad-code
```

This was the common baseline for extracting:
- package and version identity
- shared-preference keys
- selector storage keys
- enum or array-based method names
- wipe-engine classes
- overwrite-loop structure

### Debug pass for difficult/obfuscated paths
For some apps, especially heavily obfuscated ones such as ZERDAVA, an additional debug-oriented pass was documented:

```text
jadx 1.5.5 --show-bad-code --comments-level debug
```

This second pass was used when needed to:
- inspect switch dispatch more clearly
- trace obfuscated wipe-engine methods
- verify selector-to-method mappings
- confirm overwrite-pass behavior in decompiled control flow

## App-specific observations from the findings

### ZERDAVA
The saved findings explicitly record two passes:
- pass 1: `--show-bad-code`
- pass 2: `--show-bad-code --comments-level debug`

Reason documented in the findings:
- critical wipe methods required a second debug-oriented pass on the extracted main APK
- the app is heavily obfuscated

### Other apps
The sampled findings for:
- Android Eraser
- Andro Shredder
- Shreddit
- ZeroFill

all explicitly record `JADX 1.5.5 (--show-bad-code)` as the analysis baseline.

## Input artifact handling

The saved findings show two common input patterns:

### Direct APK analysis
Used for ordinary APK inputs where the primary application package was directly available.

### XAPK extraction followed by main-APK analysis
Used for apps distributed as split packages or XAPK archives.

Documented examples include:
- ZERDAVA
- ZeroFill

In these cases, the main application APK was extracted first and then analyzed with JADX.

## Reproducibility note

Different JADX versions can produce meaningfully different decompilation output, especially for:
- obfuscated applications
- Kotlin-heavy applications
- switch-based dispatch code
- enum reconstruction
- synthetic helper methods

For that reason, the replication package standardizes on:
- `JADX 1.5.5`
- `--show-bad-code`
- and, where needed for critical interpretation, `--comments-level debug`

## Relationship to the static-analysis notes

This file documents the shared decompilation environment only.
The app-specific interpretation outputs should be documented separately in:
- `docs/static_analysis/per_app_notes/`
- `mappings/selector_method_mappings.csv`
- `mappings/overwrite_behavior_notes.csv`

## Scope note

This note applies only to the 9 successful apps retained in the paper.
It does not describe failed app trials, discarded app candidates, or non-paper exploratory analysis.