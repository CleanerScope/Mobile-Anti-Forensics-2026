# ZeroFill Static-Analysis Note

## App identity

- **Application:** ZeroFill Secure Data Eraser
- **Package:** `com.ekyoulabs.zerofill`
- **Version name:** `2.0.0-130426`
- **Version code:** `20000`
- **Launcher:** `com.ekyoulabs.zerofill.MainActivity`
- **Target SDK:** `36`

## Why this app matters

ZeroFill is one of the strongest method-implementation cases in the dataset. It stores the last used algorithm in Jetpack DataStore rather than in XML `SharedPreferences`, and its write engine uses both `SecureRandom` and `RandomAccessFile("rwd")`, making it one of the strongest overwrite implementations observed in the study.

## Primary artifact path

ZeroFill uses Jetpack DataStore, not `SharedPreferences`.

Relevant storage location:

```text
/data/data/com.ekyoulabs.zerofill/files/datastore/
```

Important persisted keys:

- `last_algorithm_id`
- `secure_erase_mode`
- `passes_count`
- `incognito_mode`

The exact protobuf filename may vary with DataStore configuration, but the app-private method artifact is expected under the `files/datastore/` path.

## Method storage model

The selected method is identified by:

```text
last_algorithm_id
```

which stores a string algorithm ID such as:

```text
us_dod_5220_22m
german_vsitr
russian_gost_p50739
```

CleanerScope therefore treats ZeroFill as a **direct dynamic method evidence** case, with one important wrinkle:

- the artifact is a DataStore protobuf/preferences record rather than an XML preference file,
- so recovery depends on locating and parsing the DataStore artifact correctly.

## Critical control key

The most important accompanying key is:

```text
secure_erase_mode
```

If this value is `false`, the overwrite loop is skipped and the app performs only:

```java
file.delete()
```

So `secure_erase_mode=false` is forensically decisive: it means no overwrite occurred, regardless of what `last_algorithm_id` says.

## Algorithm registry

Static analysis identified 23 algorithm IDs.

Representative examples:

| Algorithm ID | Passes | Decompiled sequence |
|---|---:|---|
| `british_hmg_is5` | 3 | `FIXED_ZERO`, `FIXED_ONE`, `RANDOM` |
| `us_dod_5220_22m` | 3 | `FIXED_ZERO(v)`, `FIXED_ONE(v)`, `RANDOM(v)` |
| `german_vsitr` | 7 | `ZERO`, `ONE`, `ZERO`, `ONE`, `ZERO`, `ONE`, `FIXED_CUSTOM('A')` |
| `russian_gost_p50739` | 2 | `ZERO`, `RANDOM` |
| `bruce_schneier` | 7 | `ONE`, `ZERO`, `RANDOM x5` |
| `nist_800_88_rev1` | 1 | `RANDOM(v)` |
| `bsi_2011_vs` | 5 | `RANDOM`, `COMPLEMENT`, `RANDOM`, `COMPLEMENT`, `RANDOM` |
| `gutmann` | 35 | embedded 35-pass schedule |
| `ekyou_labs_extreme` | 50 | extended custom schedule |

`(v)` marks a read-back verification pass after writing.

## Verified overwrite behavior

ZeroFill’s core wipe engine uses:

```java
new RandomAccessFile(file, "rwd")
```

with:

- fixed 1 MB chunks,
- per-chunk writes,
- explicit per-pass patterns,
- optional verification,
- delete after overwrite.

This is one of the strongest I/O designs in the set because `"rwd"` provides data-synchronous writes at the `write()` level.

## Random generation quality

ZeroFill is also the strongest PRNG implementation in the dataset.

Static analysis showed:

```java
static SecureRandom b = new SecureRandom();
```

and random passes use that `SecureRandom` source for buffer generation.

This makes ZeroFill the only app in the study where random overwrite passes were clearly backed by a cryptographically strong random generator rather than `java.util.Random`.

## Pattern types

The engine supports multiple pass descriptor types:

- `FIXED_ZERO`
- `FIXED_ONE`
- `RANDOM`
- `FIXED_CUSTOM`
- `COMPLEMENT`

The `COMPLEMENT` mode is notable because it:

1. reads the existing chunk,
2. bitwise-NOTs each byte,
3. writes the complemented chunk back.

That behavior is used in algorithms such as `bsi_2011_vs`.

## Delete behavior

After overwrite, the app:

- calls `file.delete()`,
- calls `MediaScannerConnection.scanFile(...)`.

Important characteristics:

- no rename-before-delete,
- no timestamp zeroing,
- original filename remains until delete.

## Free-space wipe behavior

ZeroFill also uses the same engine family for free-space wipe paths triggered through service actions such as:

- `START_WIPE_FREE_SPACE`
- `START_WIPE_FULL_STORAGE`

These routes still use the same core algorithm model rather than a separate simplistic filler routine.

## Verification behavior

Some pass descriptors set `verify=true`, which causes the engine to read back the written data and compare it with the expected pattern. This appears to be an audit/check step, not a retry loop. The write is not automatically repeated on mismatch.

This matters because:

- verification increases interpretive confidence that the app intends read-back checking,
- but it should not be overstated as a self-healing or guaranteed retry mechanism.

## Forensic interpretation

For ZeroFill, CleanerScope reconstructs the method as follows:

1. recover `last_algorithm_id` from DataStore,
2. recover `secure_erase_mode`,
3. map the stored algorithm ID to the decompiled pass schedule,
4. qualify the result with whether overwrite was actually enabled,
5. interpret the implementation as one of the strongest in the set because of `SecureRandom` and `"rwd"`.

This app therefore demonstrates:

- **direct method recovery from DataStore**, and
- **strong implementation verification from code**.

## Suggested supporting snippets

Method-storage snippet:

```text
last_algorithm_id = german_vsitr
```

Control-state snippet:

```text
secure_erase_mode = true
```

Implementation-strength snippet:

```java
new RandomAccessFile(file, "rwd")
static SecureRandom b = new SecureRandom();
```

## Confidence classification

- **Artifact class:** direct dynamic method evidence
- **Interpretation confidence:** high for recovered algorithm ID and overwrite-enabled state
- **Implementation confidence:** high for PRNG quality and write-path behavior, with a caveat that some verification-path details were partially obscured by JADX reconstruction warnings

## Conclusion

ZeroFill stores the last used wiping algorithm directly in Jetpack DataStore and couples that with a strong overwrite engine based on `SecureRandom` and `RandomAccessFile("rwd")`. The most important interpretive condition is `secure_erase_mode`: if false, no overwrite occurs regardless of the persisted algorithm ID. When overwrite is enabled, ZeroFill represents one of the strongest algorithm implementations in the study.
