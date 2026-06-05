# Scripts and Configs Index

## Purpose

This document records the script and configuration surface used to support the CleanerScope experiments. It is intended to answer the reviewer’s reproducibility question without including failed, discarded, or unrelated working files.

Only the script/config materials relevant to the retained study workflow are included here.

## Source scope

The current project contains the following relevant script/config assets under:

```text
C:\AndroidForensicsProject\CleanerScope\scripts\
```

Observed files:

- `Invoke-CleanerScopePipeline.ps1`
- `pipeline.config.example.json`
- `README.md`
- `shredder.rooted.json`
- `shredder.test.json`

No separate top-level `configs/` directory was present in the inspected project tree at the time this index was generated, so the package documents the actual configuration artifacts currently stored alongside the scripts.

## Script inventory

### `Invoke-CleanerScopePipeline.ps1`

**Role**

- main acquisition pipeline entry point

**Purpose**

- orchestrates the logical acquisition workflow
- supports phase-based collection
- provides a repeatable starting point for emulator or device artifact capture

**Used for**

- baseline package checks
- artifact collection
- phase-oriented acquisition flow
- standardizing repeated collection steps

**Notes**

- this is the most important automation artifact in the current project
- release documentation should point to this script first

### `README.md`

**Role**

- operator-facing usage documentation for the script folder

**Purpose**

- explains how to run the pipeline
- documents expected configuration structure
- provides operational context for the acquisition script

**Used for**

- setting up the script workflow
- understanding the config-driven execution model

### `pipeline.config.example.json`

**Role**

- generic example pipeline configuration

**Purpose**

- provides a reusable template for configuring the main pipeline script
- documents expected fields and structure for a run

**Used for**

- new environment setup
- cloning a baseline configuration for a specific experiment

### `shredder.rooted.json`

**Role**

- rooted example configuration

**Purpose**

- demonstrates how a rooted acquisition case can be configured
- serves as a concrete configuration example rather than a paper-wide universal template

**Used for**

- rooted trial setup
- validating config structure against a known app case

### `shredder.test.json`

**Role**

- test/example configuration

**Purpose**

- supports validation of pipeline behavior on a constrained case
- useful as an operator sanity-check artifact

**Used for**

- checking config parsing and pipeline wiring

## What was automated

The script/config surface supported or partially supported:

- package/version checks
- staged acquisition flow
- phase folder organization
- repeated rooted pulls
- `dumpsys` collection
- `logcat` capture
- consistent naming and output structure

## What remained manual

The experiments were not fully headless.

Manual steps still included:

- navigating application UIs,
- selecting files or directories to wipe,
- setting algorithms or overwrite options in-app,
- confirming the destructive wipe action,
- handling app-specific permission screens,
- handling some rooted physical-device contingencies.

This was intentional. A single fully automated UI-driving framework was not used because the selected applications differed substantially in workflow and storage permissions.

## Recommended release organization

For the public package, the script/config materials should be exposed in two layers:

### Layer 1: actual runnable artifacts

- `scripts/Invoke-CleanerScopePipeline.ps1`
- `scripts/pipeline.config.example.json`
- `scripts/shredder.rooted.json`
- `scripts/shredder.test.json`

### Layer 2: explanatory documentation

- `scripts/README.md`
- this index file
- `docs/methodology/experiment_workflow_and_phases.md`

## Scope control

This index intentionally excludes:

- failed or abandoned scripts,
- dead branches of the workflow,
- app experiments excluded from the retained nine-app set,
- unrelated working files from the broader project tree.

## Summary

The reproducible automation surface of CleanerScope is centered on:

- one main acquisition pipeline script,
- one generic example configuration,
- a small set of rooted/test configuration examples,
- and supporting README documentation.

The package is therefore honest about its state:

- acquisition and artifact collection were systematized,
- but application execution still required controlled manual interaction.
