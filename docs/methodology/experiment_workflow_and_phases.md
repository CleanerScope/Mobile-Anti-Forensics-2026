# Experiment Workflow and Phases

## Purpose

This document records the operational workflow used in the CleanerScope experiments. It is intended to make the acquisition and interpretation sequence reproducible without exposing the full working directory or discarded branches.

The workflow applies to the nine successful applications retained in the study. It covers both the emulator-based experiments and the targeted rooted physical-device validation runs reported in the paper.

This file should be read alongside:

- `docs/manifests/tested_apps_manifest.md`
- `docs/interpretation/analysis_and_interpretation_rules.md`
- `reports/scripts_and_configs_index.md`

## High-level design

CleanerScope uses a phase-based acquisition model. Each application was exercised against a known staged dataset, and artifacts were collected at specific points in the wipe lifecycle.

The four phases are:

1. **Phase A**: baseline after install and first launch
2. **Phase B**: immediate post-wipe capture
3. **Phase C**: post-uninstall survivor capture
4. **Phase D**: post-reboot survivor capture

This structure separates:

- pre-existing baseline state,
- immediate wipe artifacts,
- uninstall survivors,
- reboot survivors.

## Dataset staging

The experiments used a known dataset staged into ordinary shared-storage locations. The core dataset structure included files under:

- `DCIM/Camera`
- `DCIM/Screenshots`
- `Documents`
- `Download`

In the working project, the staged set was referred to as `Test_data4`.

Interpretation rule:

- recovered filenames, paths, and selection records were checked against the staged dataset,
- this reduced ambiguity when evaluating filename-bearing artifacts.

## Baseline preparation

Before each run, the environment was returned to a clean baseline by:

- uninstalling the previously tested app,
- clearing or removing staged test files,
- clearing rooted task/snapshot residue where applicable,
- confirming target folders were empty,
- confirming the next test app was not already installed.

The exact cleanup sequence varied between emulator and physical-device environments, but the conceptual baseline-reset procedure remained the same.

## Phase A: baseline capture

Phase A was collected after:

- the target application was installed,
- the application was launched once,
- but before the destructive wipe action occurred.

Phase A was used to document:

- initial app-private files created on first launch,
- baseline preferences or configuration state,
- baseline system-level traces such as recents/task state,
- whether a method-bearing artifact already existed before wipe execution.

Important note:

- Phase A is not always an empty sandbox state, because many applications create preferences, report scaffolding, or analytics files on first launch.

## Phase B: immediate post-wipe capture

Phase B is the main evidence-capture phase.

It was collected immediately after the wipe operation completed and typically included:

- `logcat` dump
- app-private sandbox inspection or pull
- `dumpsys usagestats`
- `dumpsys activity recents`
- `dumpsys activity activities`
- rooted recent-task and snapshot checks where available
- supporting process or battery state only when useful

Interpretation rule:

- Phase B is the preferred phase for direct method recovery,
- because app-private preferences, DataStore records, reports, and runtime traces are most likely to still be present here.

## Logcat handling

To reduce noise, `logcat` was cleared immediately before the final wipe action rather than at the beginning of the whole app session.

Operationally, the sequence was:

1. install and set up the app,
2. navigate to the point just before wipe confirmation,
3. clear `logcat`,
4. perform the wipe,
5. dump `logcat` immediately after completion.

This was done so the captured runtime trace would emphasize:

- file selection,
- service start/stop,
- wipe progress,
- per-file deletion messages,
- completion or error messages.

## Phase C: post-uninstall capture

After Phase B, the application was uninstalled and a second capture was performed.

Phase C was used to determine:

- whether app-private method or report artifacts survived uninstall,
- which system-level traces remained visible,
- whether recent-task or snapshot remnants persisted,
- how the evidentiary surface changed after sandbox removal.

Interpretation rule:

- if a Phase B method artifact disappears after uninstall, it is still valid as Phase B evidence,
- but it is classified as non-persistent across uninstall.

## Phase D: post-reboot capture

After Phase C, the device or emulator was rebooted and a final survivor capture was performed.

Phase D was used to evaluate:

- which system-level traces persisted across restart,
- whether task-root historical references remained,
- whether any rooted recent-task or snapshot indices still existed,
- how much evidence remained once runtime state had been reset.

Interpretation rule:

- Phase D evidence was treated primarily as persistence evidence,
- not as a substitute for direct Phase B method recovery.

## Rooted vs non-rooted acquisition

The broader study included both rooted and non-rooted acquisition perspectives, but the strongest artifact recovery depended on root access for:

- app-private sandbox access,
- rooted recent-task inspection,
- rooted snapshot checks,
- deeper system-path inspection.

Non-rooted access remained useful for:

- app-use detection,
- some system-service outputs,
- limited runtime observation.

For the paper-facing physical validation, the targeted Android 14 runs were rooted.

## Emulator workflow

The emulator experiments served as the main comparative study environment.

Key characteristics:

- Android 9 AVD
- emulator-managed writable disk state with QCOW2 overlays present
- repeatable reset and staged dataset workflow
- stronger practical access to some rooted system-managed artifacts than on the physical Android 14 device

The emulator was the main environment for the nine-app comparative analysis.

## Physical-device workflow

The paper also includes targeted rooted physical-device validation on a contemporary Android tablet. These validation runs were narrower than the full emulator study and were used to test whether the main artifact classes reproduced beyond the emulator.

Paper-facing physical validation apps:

- Android Eraser
- Shreddit
- ZERDAVA

Physical-device differences included:

- stricter access controls for some rooted system-managed paths,
- ABX/binary recent-task artifacts rather than easily readable XML in some cases,
- snapshot content that could sometimes be enumerated but not copied directly,
- stronger external-validity value despite lower convenience.

## Manual vs automated steps

The workflow was not fully headless.

Scripted or semi-scripted steps included:

- dataset push
- installation checks
- package/version checks
- rooted pulls
- `dumpsys` collection
- `logcat` dump
- phase folder organization

Manual steps included:

- navigating each application UI,
- selecting the wipe target,
- setting a wipe method or configuration where applicable,
- confirming the destructive wipe action.

Interpretation rule:

- manual interaction was limited to app-execution steps that could not be robustly scripted across all apps,
- artifact collection and preservation were kept as systematic as possible.

## Scope control

Only the nine successful applications retained in the paper were included in the package. Failed apps, excluded apps, and abandoned trials were not carried into the release materials.

For physical validation reporting, only the three paper-used rooted runs were retained:

- Android Eraser
- Shreddit
- ZERDAVA

## Summary

The CleanerScope workflow is a structured phase-based acquisition procedure:

1. reset to a clean baseline,
2. stage a known dataset,
3. install and launch the target app,
4. capture Phase A,
5. clear `logcat` immediately before the destructive action,
6. perform the wipe and capture Phase B,
7. uninstall and capture Phase C,
8. reboot and capture Phase D,
9. interpret app-private, system-level, and static-analysis artifacts together.
