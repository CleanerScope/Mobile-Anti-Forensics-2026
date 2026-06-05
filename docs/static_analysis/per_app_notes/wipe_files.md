# Wipe Files Static-Analysis Note

## App identity

- **Application:** Wipe Files
- **Package:** `uk.org.platitudes.wipefiles`
- **Version name:** `0.3`
- **Version code:** `3`
- **Launcher:** `uk.org.platitudes.wipe.main.MainTabActivity`
- **Target SDK:** `22`

## Why this app matters

Wipe Files is not a named-standard app. Instead, it exposes a configurable overwrite model based on pass count, block size, and an optional zero-before-random step. It is also one of the most important implementation-caveat cases in the dataset because static analysis indicates a likely partial-overwrite defect for files larger than the configured block size.

## Primary artifact path

The app stores its wipe configuration in default shared preferences:

```text
/data/data/uk.org.platitudes.wipefiles/shared_prefs/uk.org.platitudes.wipefiles_preferences.xml
```

Relevant wipe keys:

- `number_passes`
- `zero_wipe`
- `block_size`
- `allow_directories_key`
- `allow_recursion_key`

## Method storage model

Wipe Files does not store named algorithms such as DoD, HMG, or GOST. The wipe behavior is reconstructed from configuration parameters:

- `number_passes`
- `zero_wipe`
- `block_size`

Representative configuration:

```xml
<string name="number_passes">3</string>
<boolean name="zero_wipe" value="true" />
<string name="block_size">8192</string>
```

CleanerScope therefore treats Wipe Files as a **direct configuration evidence** case rather than a label-mapping case.

## Effective pass model

Static analysis showed the following pass behavior:

| Configuration | Effective write pattern |
|---|---|
| `zero_wipe=false`, `passes=1` | `[random]` |
| `zero_wipe=false`, `passes=N` | `[random] x N` |
| `zero_wipe=true`, `passes=1` | `[0x00, random]` |
| `zero_wipe=true`, `passes=N` | `[0x00, random] x N` |

Random bytes are generated with:

```java
java.util.Random.nextBytes(...)
```

and not with `SecureRandom`.

## Critical implementation caveat: likely partial-overwrite defect

The most important static-analysis finding is that the core write loop appears to call:

```java
counter.finish()
```

inside the main `while` loop body in `wipePass()`.

If the decompiled placement is correct, this means:

- files smaller than or equal to `block_size` are fully overwritten,
- files larger than `block_size` have only the first block overwritten per pass,
- the remainder of the file is left untouched.

With the default configuration:

- `block_size = 8192`

the likely result is that only the first 8 KB of each pass is written for files larger than 8 KB.

Important qualification:

- the same method carries a JADX restructuring warning,
- so this should be described as a **likely code-derived defect** unless dynamically verified on large files.

This is the correct reviewer-facing formulation.

## Write-path behavior

The core wipe path uses:

```java
new RandomAccessFile(file, "rw")
```

with:

- explicit `seek(0L)`,
- fixed or random block writes,
- no `rws` mode,
- no `getFD().sync()`,
- no `FileChannel.force()`,
- no `fsync`.

So even when a block is written, hardware flush is not explicitly guaranteed by the code.

## Rename-before-delete behavior

After overwrite passes complete, the delete path:

1. generates a random uppercase replacement filename,
2. keeps the same character length as the original filename,
3. attempts rename-plus-delete up to three times.

Characteristics:

- replacement alphabet: `A-Z`
- same filename length preserved
- PRNG source: `java.util.Random`
- no timestamp zeroing
- no MediaStore cleanup

This is one of the clearer rename-before-delete implementations in the set, but it is still based on a weak PRNG and does not clear metadata comprehensively.

## Deletion log behavior

The app maintains a deletion log only in memory:

```text
MainTabActivity.sTheMainActivity.mDeleteLog
```

That log is shown in the UI but is not persisted to:

- shared preferences,
- files,
- or databases.

So once the process terminates, the deletion log is lost.

## Free-space wipe

No free-space wipe feature was identified in this application.

## Forensic interpretation

For Wipe Files, CleanerScope reconstructs the method from configuration state:

1. recover `number_passes`,
2. recover `zero_wipe`,
3. recover `block_size`,
4. derive the intended pass sequence,
5. qualify the result with the likely partial-overwrite defect and the lack of explicit flush guarantees.

This app therefore demonstrates that:

- **configuration recovery can succeed cleanly**, but
- **implementation validation may materially reduce confidence in actual full-file overwrite coverage**.

## Suggested supporting snippets

Configuration snippet:

```xml
<string name="number_passes">3</string>
<boolean name="zero_wipe" value="true" />
<string name="block_size">8192</string>
```

Code-derived caveat snippet:

```text
counter.finish() appears inside the main write loop, likely limiting each pass to the first configured block.
```

Rename behavior snippet:

```text
renameTo(random uppercase same-length filename) -> delete()
```

## Confidence classification

- **Artifact class:** direct configuration evidence
- **Interpretation confidence:** high for recovered configuration values
- **Implementation confidence:** moderate for the likely partial-overwrite conclusion because the same method triggered a JADX restructure warning

## Conclusion

Wipe Files stores its wipe behavior as direct configuration values rather than named algorithms. Static analysis indicates a likely defect in which only the first configured block of files larger than `block_size` is overwritten per pass, although that conclusion should be qualified as code-derived because the affected method decompiled imperfectly. The app also performs a weak-PRNG rename-before-delete step and does not persist a post-session deletion log.
