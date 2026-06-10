# Analysis and Interpretation Rules

## Purpose

This document records the rules used to interpret artifacts recovered by CleanerScope. It is intended to make the reasoning process explicit and reproducible. The rules below were applied across the nine successful applications retained in the study.

This file should be read alongside:

- `docs/interpretation/artifact_source_inventory.md`
- `mappings/selector_method_mappings.csv`
- `mappings/overwrite_behavior_notes.csv`
- `docs/static_analysis/per_app_notes/`

## Core principle

CleanerScope distinguishes between:

- **what the application says it did**,
- **what an app-private artifact directly preserves**,
- **what a system-level artifact indirectly supports**,
- and **what the decompiled code shows the application actually implements**.

The framework does not assume that:

- a UI label equals the implemented overwrite behavior,
- a stored selector equals a standard-compliant method,
- or a deletion event implies a successful overwrite.

## Artifact classes

### Direct dynamic method evidence

This class is used when the recovered app-private artifact already stores the method in readable or structured form.

Examples:

- Android Eraser `savekey_reports` / `cb_default_method`
- iShredder `Reports.xml` / `ishredder_default_method`
- Shreddit `shred.algo`
- Shredder `algorithm`
- ZeroFill `last_algorithm_id`

Interpretation rule:

- the recovered value is treated as the primary method indicator,
- but implementation validation is still performed if the app may collapse or diverge from advertised behavior.

### Mapped dynamic method evidence

This class is used when the recovered artifact stores an indirect value that must be mapped to a label using resources or code.

Examples:

- Andro Shredder `shredIntensity`
- ZERDAVA `KEY_SELECTED_SHRED_TYPE`

Interpretation rule:

- the recovered selector is preserved as evidence,
- the mapping step is documented explicitly,
- the label is not treated as self-proving without code support.

### Direct configuration evidence

This class is used when no named standard method is stored, but the configuration values directly determine the overwrite routine.

Example:

- Wipe Files `number_passes`, `zero_wipe`, `block_size`

Interpretation rule:

- the configuration tuple is treated as the method-defining artifact,
- the effective pass sequence is derived from code,
- any likely implementation defect is stated explicitly.

### Code-derived only

This class is used when no live method artifact is recoverable and the wipe behavior must be reconstructed entirely from code.

Example:

- Safe Delete

Interpretation rule:

- the absence of a live method artifact is stated explicitly,
- the method is reconstructed from the implemented overwrite routine,
- the result is not presented as equivalent to direct dynamic method recovery.

## App-private vs system-level evidence

### App-private evidence

Artifacts recovered from:

- `/data/data/<package>/shared_prefs/`
- `/data/data/<package>/files/`
- `/data/data/<package>/files/datastore/`
- `/data/data/<package>/databases/`

were treated as higher-value sources for:

- method reconstruction,
- app configuration,
- per-session reports,
- per-file outcome records.

Interpretation rule:

- app-private artifacts are preferred over system-level traces when method recovery is the goal.

### System-level evidence

Artifacts recovered from:

- `dumpsys usagestats`
- `dumpsys activity recents`
- `dumpsys activity activities`
- rooted `recent_tasks`
- snapshots
- `logcat`

were treated as higher-value sources for:

- app-use detection,
- workflow/timeline reconstruction,
- runtime filename/path disclosure,
- persistence after uninstall and reboot.

Interpretation rule:

- system-level traces were not treated as substitutes for app-private method artifacts,
- but they were treated as strong supporting evidence for use history and runtime behavior.

## Method interpretation rules

### Rule 1: Stored value first, code second

When a direct or mapped method value was recovered, the value was recorded first and then checked against decompiled code. The stored value identifies what the app preserved about the selected method. The code analysis determines whether that value corresponds to a distinct, standard-compliant, or misleading implementation.

### Rule 2: Labels are not assumed to equal implementation

UI-facing labels such as:

- DoD,
- HMG,
- GOST,
- BSI VSITR,
- Schneier,
- Gutmann

were not treated as sufficient evidence of actual overwrite behavior. Where code showed divergence, the implementation caveat was carried forward into the interpretation.

Examples:

- Andro Shredder labels collapse to one random-buffer model
- Shredder path-dependent DoD/HMG behavior differs by storage path
- Wipe Files exposes no named standard at all

### Rule 3: Configuration can be method evidence

Where no named method exists, configuration values were treated as the method-defining artifact if they directly controlled the overwrite routine.

Example:

- Wipe Files: `number_passes` + `zero_wipe` + `block_size`
  
- **Note:** Wipe Files is classified as Direct in the paper's
> summary table (Table 2) for simplicity. The configuration-based
> subclass is documented here for interpretive precision, since the
> recovered values are not a named method string but a configuration
> tuple that defines the overwrite routine.

### Rule 4: Code-only recovery is a separate evidentiary class

If no method artifact existed in live state, the result was recorded as code-derived only, not upgraded into a false dynamic-method recovery.

Example:

- Safe Delete

## Filename and path interpretation rules

### Runtime filename/path traces

Exact filenames or file paths recovered from:

- `logcat`
- report objects
- report detail lists
- JSON URI arrays

were treated as strong evidence when they matched the staged test dataset.

Examples:

- Android Eraser report entries
- Shreddit `logcat` screenshot paths
- ZERDAVA progress-update filename traces

### Source hierarchy for filename evidence

Filename/path evidence was interpreted in this order:

1. structured app-private reports
2. app-private stored file lists or JSON arrays
3. runtime `logcat` traces
4. system-level task or media references

Interpretation rule:

- higher-ranked sources were treated as more specific and less ambiguous,
- lower-ranked sources were still useful, but mainly as corroboration.

### False-positive control

Filename evidence was checked against the staged dataset used in the experiment. The presence of a matching filename alone was not treated as proof of successful overwrite; it was interpreted together with source type and phase.

## Persistence rules

### Phase B

Immediately post-wipe, the strongest artifacts were typically:

- app-private method/configuration state,
- app-private reports,
- runtime `logcat`,
- current `usagestats`,
- active recents/task traces.

Interpretation rule:

- Phase B is the preferred phase for direct method recovery.

### Phase C

After uninstall:

- app-private artifacts were expected to disappear,
- system-level survivors such as `usagestats`, recents/task traces, or snapshots could remain.

Interpretation rule:

- disappearance of the app-private method artifact after uninstall does not weaken its Phase B validity,
- but it changes the persistence class of that artifact.

### Phase D

After reboot:

- the surviving evidence surface was expected to narrow further,
- package-level or task-root historical traces might still remain,
- runtime and app-private traces were expected to be weaker or absent.

Interpretation rule:

- Phase D survivors were treated as persistence evidence, not as replacements for Phase B method artifacts.

## Implementation caveat rules

### Rule 1: Distinguish confirmed code behavior from qualified code behavior

If the relevant method decompiled cleanly, the implementation note was stated directly. If the relevant method carried a strong reconstruction warning, the conclusion was qualified accordingly.

Example:

- Wipe Files likely partial-overwrite defect is stated as code-derived and in need of dynamic confirmation

### Rule 2: PRNG quality matters

Random overwrite passes were not treated equally across apps.

- `SecureRandom`-backed passes were interpreted as stronger implementations
- `java.util.Random`-backed passes were explicitly noted as weaker

This distinction was recorded separately from the label or pass count.

### Rule 3: Flush behavior matters

Write durability was distinguished among:

- `rwd`
- `rws`
- `buffer.force()`
- explicit `fsync`
- `flush()` only
- close-only behavior

This was treated as implementation quality, not as the same thing as method identity.

## Scope rules

Only the nine successful applications retained in the paper were included in this package. Failed apps, excluded apps, abandoned trials, and discarded scripts are outside scope.

For physical validation reporting, only the paper-used physical cases were retained:

- Android Eraser
- Shreddit
- ZERDAVA

ZeroFill remains part of the nine-app static-analysis and mapping set, but not the public paper-facing physical-validation summary.

## Summary

CleanerScope interpretations were based on a consistent hierarchy:

1. recover the strongest available app-private artifact,
2. classify the evidence as direct, mapped, configuration-based, or code-only,
3. validate the implied method against decompiled implementation,
4. use system-level traces to reconstruct timeline and persistence,
5. keep persistence and implementation caveats explicit rather than folding them into the method claim itself.
