# Shreddit Static-Analysis Note

## App identity

- **Application:** Shreddit
- **Package:** `com.palmtronix.shreddit.v1`
- **Version name:** `5.36.251203`
- **Version code:** `89`
- **Launcher:** `com.palmtronix.shreddit.v1.MainActivity`

## Why this app matters

Shreddit is a direct-label case rather than a selector-mapping case. The chosen shredding algorithm is stored in human-readable form in app-private `SharedPreferences`, and the same app also emits strong runtime filename and path traces during execution. This makes it useful for demonstrating how CleanerScope links app-private method state to system-level runtime traces.

## Primary artifact path

The main method-bearing artifact is stored at:

```text
/data/data/com.palmtronix.shreddit.v1/shared_prefs/com.palmtronix.shreddit.v1_preferences.xml
```

Relevant keys include:

- `shred.algo`
- `number_of_passes`
- `secureDeletedMode`
- `shredjob.count`
- `jobs.under.progress`
- `jobs.paused.state`

## Method storage model

Shreddit stores the selected wipe algorithm as a direct string label rather than as an opaque selector.

Example stored state:

```xml
<string name="shred.algo">US_DOD_5220</string>
<string name="number_of_passes">1</string>
<boolean name="secureDeletedMode" value="true" />
<int name="shredjob.count" value="6" />
```

CleanerScope therefore treats Shreddit as a **direct dynamic method evidence** case: the recovered value is already human-readable and does not require a selector-to-label mapping step.

## Algorithm registry and implementation summary

The decompiled registry exposes multiple advertised algorithms, including:

| Stored label | Decompiled overwrite behavior |
|---|---|
| `BRIT_HMG_IS5` | `0x00`, `0xFF`, random |
| `US_DOD_5220` | `0x00`, `0xFF`, random |
| `DE_VSITR` | `0xAA`, `0x55`, `0xAA`, `0x55`, `0xAA`, `0x55`, random |
| `RU_GOST_P50739` | `0x00`, random |
| `BRUCE_SCHN` | `0x00`, `0xFF`, random x5 |
| `NIST_800_88` | `0x00`, random |
| `ZERO_FILLER` | `0x00` repeated |
| `ONE_FILLER` | `0xFF` repeated |
| `RANDOM_FILLER` | random repeated |

The implementation uses buffered writes through a `BufferedOutputStream(new FileOutputStream(file))` path with chunk sizes up to 8192 bytes. Each pass is flushed, but the implementation does not explicitly force the file descriptor with an `fsync`-style operation.

## Important discrepancies

Static analysis showed that several advertised algorithms collapse or diverge from their expected behavior:

- `BRIT_HMG_IS5` and `US_DOD_5220` compile to the same effective overwrite pattern.
- `DE_VSITR` uses alternating `0xAA` and `0x55` passes rather than the simpler `0x00` / `0xFF` description often used in summaries.
- `SEQUENCE_1` and `SEQUENCE_2` collapse to the same behavior as `ZERO_FILLER`.
- `NIST_800_88` is implemented as a two-pass strategy rather than a single sanitization pass.
- Randomized fills use `java.util.Random`, not `SecureRandom`.

These are exactly the kinds of implementation-level divergences that CleanerScope records separately from the UI-visible algorithm label.

## Random-fill implementation note

The random-overwrite implementation is weaker than a cryptographically strong design. Decompiled buffers indicate:

- an 8 KB buffer model,
- reuse of generated random content within a strategy instance,
- `java.util.Random` rather than `SecureRandom`.

This does not prevent method recovery, but it matters when interpreting the claimed overwrite behavior.

## Deletion and free-space behavior

Shreddit does not implement a rename-before-delete step in the same way some other apps do. For gallery-backed content, the app also updates media visibility state. Free-space wiping creates temporary files using dot-prefixed timestamp-like names such as:

```text
.<hex-timestamp>.dlt
```

The analyzed implementation notes indicate that these temporary files are not aggressively cleaned up by a distinct post-processing routine.

## Forensic interpretation

For Shreddit, CleanerScope reconstructs the method directly from app-private stored values:

1. recover `com.palmtronix.shreddit.v1_preferences.xml`,
2. read `shred.algo`,
3. read supporting state such as `number_of_passes` and `secureDeletedMode`,
4. compare the stored label against the decompiled implementation to determine whether the advertised method matches the concrete overwrite routine.

This app therefore supports both:

- **direct dynamic method recovery** from `SharedPreferences`, and
- **implementation verification** through decompiled overwrite logic.

## Suggested supporting snippets

Method-bearing preference snippet:

```xml
<string name="shred.algo">US_DOD_5220</string>
<boolean name="secureDeletedMode" value="true" />
<string name="number_of_passes">1</string>
```

Implementation summary snippet:

```java
new BufferedOutputStream(new FileOutputStream(file))
```

Interpretive note:

```text
Stored method labels are human-readable, but several advertised algorithms collapse to equivalent or divergent concrete overwrite routines.
```

## Confidence classification

- **Artifact class:** direct dynamic method evidence
- **Interpretation confidence:** high for stored method recovery
- **Implementation confidence:** moderate to high for overwrite-behavior verification from decompiled code

## Conclusion

Shreddit is a strong direct-evidence app. The selected algorithm is stored as a readable label in app-private preferences, and static analysis shows that those labels still require implementation verification because multiple advertised methods collapse to equivalent or divergent overwrite routines.
