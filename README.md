# CleanerScope Replication Package

## Overview

This package contains the reviewer-facing replication materials for the CleanerScope study on forensic artifact recovery from Android secure-deletion applications.

The package is designed to answer four practical questions:

1. **Which apps were actually studied?**
2. **How were the experiments run?**
3. **How were method artifacts interpreted?**
4. **What concrete evidence supports the paper's claims?**

The release is intentionally scoped to the **nine successful applications retained in the paper**. Failed app trials, excluded candidates, abandoned scripts, and unrelated working files are not part of this package.

## Study scope

The package covers:

- the nine successful apps retained in the paper,
- the Android 9 emulator comparative workflow,
- the rooted Android 14 targeted physical validation cases retained in the paper,
- the static-analysis notes used to derive selector mappings and overwrite-behavior conclusions,
- curated evidence examples and supporting documentation.

The package does **not** attempt to include:

- full raw working-directory history,
- failed app experiments,
- discarded scripts,
- full proprietary APK redistribution,
- complete decompiled code dumps for third-party apps.

## Quick start

If you are reading this package for the first time, use this order:

1. `docs/manifests/tested_apps_manifest.md`
2. `docs/methodology/experiment_workflow_and_phases.md`
3. `docs/interpretation/artifact_source_inventory.md`
4. `docs/interpretation/analysis_and_interpretation_rules.md`
5. `examples/core_evidence_examples.md`
6. `docs/methodology/physical_validation_summary.md`

If you specifically want the static-analysis basis for selector mapping and overwrite-behavior interpretation, then start with:

1. `docs/static_analysis/jadx_version_and_flags.md`
2. `docs/static_analysis/static_analysis_notes.md`
3. `docs/static_analysis/per_app_notes/`
4. `mappings/selector_method_mappings.csv`
5. `mappings/overwrite_behavior_notes.csv`

## Package structure

### `docs/manifests/`

- tested application manifest
- package names
- version names and version codes
- scope of paper-facing physical validation

### `docs/methodology/`

- phase-based acquisition workflow
- baseline and post-wipe/post-uninstall/post-reboot structure
- physical validation summary for the three retained paper-facing device runs

### `docs/environment/`

- emulator environment
- physical-device environment
- ADB/root assumptions
- QCOW2 overlay note
- tool environment context

### `docs/interpretation/`

- artifact-source inventory
- analysis and interpretation rules
- evidence-class definitions

### `docs/static_analysis/`

- shared JADX environment note
- static-analysis overview
- one normalized per-app note for each of the nine retained apps

### `mappings/`

- selector-to-method mapping table
- app-to-artifact-path mapping table
- overwrite-behavior summary table

### `examples/`

- curated evidence excerpts
- bounded extractor output examples
- reviewer-facing examples of direct method artifacts, mapped selectors, runtime traces, and survivor evidence

### `reports/`

- script and config index

## The nine retained applications

The retained app set is documented in:

- `docs/manifests/tested_apps_manifest.csv`
- `docs/manifests/tested_apps_manifest.md`

These materials record:

- app name
- package name
- tested version
- APK source reference
- whether the app is included in the paper-facing physical validation summary

## Physical validation scope

The paper-facing physical validation summary intentionally includes only:

- Android Eraser
- Shreddit
- ZERDAVA

This is deliberate. Those three runs were retained because they provide the clearest physical-device evidence across three distinct artifact models:

- direct method/report artifact
- direct method label plus runtime filename/path traces
- selector-based method recovery

## Static-analysis scope

The static-analysis materials cover all nine successful retained apps.

These materials were used to:

- map selector values to named methods,
- verify whether stored labels matched implemented overwrite routines,
- identify PRNG quality,
- identify flush/durability behavior,
- identify implementation discrepancies and limitations.

The shared static-analysis environment is documented in:

- `docs/static_analysis/jadx_version_and_flags.md`

## Scripts and configs

The current project's reproducible automation surface is documented in:

- `reports/scripts_and_configs_index.md`

The key script entry point is:

- `scripts/Invoke-CleanerScopePipeline.ps1`

The package also includes a bounded study extractor:

- `scripts/Extract-CleanerScopeEvidence.ps1`

Reviewer-facing example outputs for that extractor are provided in:

- `examples/extractor_output_examples.md`

This extractor is intentionally limited to the retained nine-app study set. It normalizes recovered method/configuration artifacts into JSON output and uses the package mapping materials to interpret selector-style values.

Important limitation:

- the experiments were not fully headless,
- application execution still required controlled manual interaction for UI navigation, file selection, and wipe confirmation.

## Reproducibility notes

### Emulator state

The Android 9 emulator used writable emulator-managed state with QCOW2 overlays. Exact reruns therefore depend on controlling:

- overlay state,
- fast boot / snapshot state,
- staged dataset reset.

This is documented in:

- `docs/environment/environment.md`

### Static analysis

Decompiler output is version-sensitive, especially for obfuscated or Kotlin-heavy apps. The package standardizes on:

- JADX `1.5.5`
- `--show-bad-code`
- and, where needed, `--comments-level debug`

### Interpretation

CleanerScope does not assume that:

- a stored label equals a correct implementation,
- a selector is self-interpreting,
- a deletion event proves a wipe completed,
- or a post-uninstall survivor is equivalent to a Phase B method artifact.

Those interpretation rules are documented explicitly in:

- `docs/interpretation/analysis_and_interpretation_rules.md`

## What this package is for

This package is intended to let a reviewer or later researcher:

- verify the retained app set,
- understand the acquisition workflow,
- inspect the static basis of selector mapping and overwrite-behavior claims,
- inspect compact evidence excerpts,
- and follow how CleanerScope's conclusions were derived.

It is not intended to redistribute proprietary apps or provide a one-click automation harness for every UI path across all nine applications.
