# iShredder Static-Analysis Note

## App identity

- **Application:** iShredder
- **Package:** `com.projectstar.ishredder.android.standard`
- **Version name:** `7.2.3`
- **Version code:** `7230`
- **Launcher:** `com.protectstar.module.myps.activity.MYPSMain`

## Why this app matters

iShredder is one of the strongest direct-method apps in the dataset. It stores the selected wipe method as a serialized object rather than as an opaque selector, and the decompiled implementation defines a large algorithm registry with explicit per-pass schedules. This makes it useful for demonstrating full method recovery and implementation verification from app-private artifacts.

## Primary artifact path

The main method-bearing artifact is stored in default shared preferences:

```text
/data/data/com.projectstar.ishredder.android.standard/shared_prefs/com.projectstar.ishredder.android.standard_preferences.xml
```

Relevant keys include:

- `ishredder_default_method`
- `report_history`
- `report_files_allowed`
- `reports_v2`
- `savekey_reports`
- `max_free_space_progress`

## Method storage model

The selected wipe method is stored in:

```text
ishredder_default_method
```

as a Gson-serialized method object. The serialized object includes:

- display name,
- internal method enum,
- pass count,
- per-pass pattern array,
- edition tier.

CleanerScope therefore treats iShredder as a **direct dynamic method evidence** case: if `ishredder_default_method` is recovered, the selected method and its stored pass schedule are directly reconstructable without a selector-mapping step.

## Algorithm registry

Static analysis identified 27 algorithms in the registry, each defined with:

- `mName`
- `mDescription`
- `mCycles`
- `mPattern`
- `mValue`
- `mVersion`

Representative examples:

| Display name | Internal enum | Passes | Decompiled pattern |
|---|---|---:|---|
| `0xFF` | `N0xFF` | 1 | `[0xFF]` |
| `0x00` | `N0x00` | 1 | `[0x00]` |
| `Random` | `Zufall` | 1 | `[-1]` |
| `RUSSIAN GOST R 50739-95` | `GOST_R_50739_95` | 2 | `[0x00], [-1]` |
| `DoD 5220.22-M (E)` | `DoD5220_22_ME` | 3 | `[0x55], [0xAA], [-1]` |
| `DoD 5220.22 ECE` | `DoD5220_22_ECE` | 7 | `[0xF6], [0x09], [-1], [0x00], [0xFF], [-1], [-1]` |
| `BSI-VSITR (TL-03423)` | `BSI_TL_03423` | 8 | `[0xFF], [0x00], [-1], [0xFF], [0x00], [0xFF], [0x00], [0xAA]` |
| `Gutmann` | `Gutmann` | 35 | literal 35-pass schedule in source |

## Verified overwrite behavior

Unlike apps that collapse multiple labels into one behavior, iShredder implements distinct schedules for many methods. The decompiled code iterates per-pass `int[]` patterns and generates the output buffer for each pass according to the encoded pattern:

- `-1` means random fill,
- `0–255` means fixed byte fill,
- multi-element arrays mean a cycling byte sequence,
- `BSI-2011-VS` uses a special hash-chain generator.

This makes iShredder one of the clearer cases where the stored method object and the implemented schedule can be matched directly.

## Critical implementation caveat: PRNG quality

The most important static-analysis caveat is that almost all random passes use:

```java
new Random().nextBytes(...)
```

and **not** `SecureRandom`.

The only clear exception identified in the analysis is:

- `BSI-2011-VS`, which uses a SHA-1 hash-chain derived from a `SecureRandom`-seeded 20-byte value.

This means the app distinguishes algorithms correctly at the schedule level, but most random passes do not use a cryptographically strong random source.

## File-shredding implementation summary

The primary file path:

- opens a `ParcelFileDescriptor`,
- writes through `FileChannel.write(ByteBuffer)`,
- uses a maximum chunk size of 32 KB,
- calls `channel.force(false)` once at the end of each full file pass,
- renames the target to a UUID-like hidden filename before deletion,
- sets timestamps to zero before deletion,
- deletes the MediaStore entry afterward.

Implementation summary:

```java
while (passIndex < method.f7516d.length) {
    int[] passPattern = method.f7516d[passIndex];
    p(file, passIndex, passPattern, ...);
    passIndex++;
}
channel.force(false);
```

Important consequence:

- the app does **not** force every chunk write,
- only the end of a full pass is explicitly forced,
- so intermediate writes may still be OS-cached before the pass ends.

## Free-space wipe behavior

Free-space wipe uses:

- temp files named `.FREESPACEERASE`, `.FREESPACEERASE1`, and so on,
- 1 MB chunk writes,
- `channel.force(true)` only every 5 GB,
- the same pass-pattern interpretation as file shredding.

Interrupted wipes may therefore leave `.FREESPACEERASE*` artifacts behind.

## Report artifacts

iShredder also preserves high-value report artifacts:

- `reports_v2`
- `savekey_reports`

The report object structure includes:

- report ID,
- start and end time,
- app version,
- Android version,
- nested method object,
- total bytes written,
- total items written,
- success flag,
- optional per-file detail list.

When `report_files_allowed` is enabled, report details may preserve exact file paths and per-item outcomes.

This is a strong secondary evidence path in addition to `ishredder_default_method`.

## Forensic interpretation

For iShredder, CleanerScope reconstructs the method directly:

1. recover `ishredder_default_method`,
2. parse the serialized method object,
3. extract pass count and pattern,
4. compare the stored object against the decompiled registry and write logic,
5. use `reports_v2` or `savekey_reports` as corroboration when present.

This app therefore supports:

- **direct dynamic method recovery**, and
- **direct verification of stored method structure against code-defined schedules**.

## Suggested supporting snippets

Method-storage snippet:

```text
ishredder_default_method = Gson-serialized method object
```

PRNG caveat snippet:

```java
new Random().nextBytes(bArr)
```

Report-value snippet:

```text
reports_v2 stores timestamps, byte counts, method details, and optional per-file paths.
```

## Confidence classification

- **Artifact class:** direct dynamic method evidence
- **Interpretation confidence:** high for stored method recovery
- **Implementation confidence:** high for algorithm registry recovery; moderate to high for runtime durability conclusions because flush behavior depends partly on the platform

## Conclusion

iShredder is a strong direct-evidence app. The selected method is recoverable from app-private preferences as a serialized method object, and the static algorithm registry defines distinct pass schedules for 27 methods. The main implementation weakness is that most random passes use `java.util.Random` rather than `SecureRandom`, and explicit flushes occur at pass boundaries rather than after every chunk.
