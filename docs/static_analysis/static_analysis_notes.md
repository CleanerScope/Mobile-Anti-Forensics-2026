# Static Analysis Notes

This section documents how static analysis was used in the CleanerScope study to interpret app-specific wiping artifacts for the 9 successful applications retained in the paper.

## Purpose of static analysis in CleanerScope

Static analysis was used for four main purposes:

1. to identify where the app stored wipe-method configuration or state
2. to map recovered selector values to human-readable wiping-method labels
3. to inspect the actual overwrite behavior implemented by the code
4. to qualify cases where the stored label, selector, or user-facing method name diverged from the real implementation

This means static analysis in CleanerScope was not used only to “look at code.” It was used as an interpretive bridge between:
- recovered artifact values
- mapped method labels
- verified overwrite behavior

## What is documented here

The static-analysis package is organized into two layers.

### 1. Shared environment and methodology
These files document the common decompilation environment and interpretation rules:
- `docs/static_analysis/jadx_version_and_flags.md`
- `docs/interpretation/analysis_and_interpretation_rules.md`
- `mappings/selector_method_mappings.csv`
- `mappings/overwrite_behavior_notes.csv`

### 2. Per-app notes
Each successful paper app will have a normalized per-app note in:
- `docs/static_analysis/per_app_notes/`

Each per-app note should document:
- package and tested version
- primary artifact paths inspected
- recovered selector or method values
- mapping from raw value to method label where needed
- overwrite implementation summary
- any discrepancy between label and implementation
- supporting decompiled code references used to justify the interpretation

## How these notes should be read

The per-app static-analysis notes should be interpreted together with the dynamic findings.

### Direct-evidence apps
For some apps, static analysis primarily confirms the meaning of a directly stored method value.

Examples:
- Android Eraser
- Shreddit

### Selector-mapping apps
For other apps, static analysis is essential because the dynamic artifact stores only an indirect selector or intensity value.

Examples:
- ZERDAVA
- Andro Shredder

### Code-derived or implementation-qualification apps
For some apps, static analysis is necessary either because:
- the live method artifact is missing, or
- the user-facing label does not faithfully describe the implemented overwrite behavior

Examples:
- Safe Delete
- ZeroFill
- Shredder

## What is not included

This package should not include full decompiled app distributions or full proprietary source trees.

Instead, it should include only:
- concise per-app analysis notes
- small supporting code excerpts where necessary
- mapping tables
- overwrite-behavior summaries

This keeps the replication package focused on reproducibility of interpretation rather than redistribution of third-party code.

## App scope

The static-analysis scope is limited to the 9 successful apps retained in the paper:
- Android Eraser
- Andro Shredder
- iShredder
- Shredder
- Shreddit
- Safe Delete
- Wipe Files
- ZERDAVA
- ZeroFill

Failed trials, discarded apps, and non-paper exploratory analysis are intentionally excluded.

## Relationship to the reviewer concern

These notes address the reviewer’s reproducibility concern by making the following explicit:
- which app artifacts were statically inspected
- how selector-to-method mappings were derived
- which overwrite routines were actually examined
- which conclusions are direct, mapped, or code-derived

## Next outputs

The next files in this section are the per-app notes in:
- `docs/static_analysis/per_app_notes/`

Those notes are the app-level source material for:
- `mappings/selector_method_mappings.csv`
- `mappings/overwrite_behavior_notes.csv`