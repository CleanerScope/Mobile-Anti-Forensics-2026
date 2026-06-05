# Andro Shredder Static-Analysis Note

## App identity

- **Application:** Andro Shredder
- **Package:** `com.apparillos.android.androshredder`
- **Version name:** `2.0.7`
- **Version code:** `207`
- **Launcher:** `com.apparillos.android.androshredder.MainActivity`

## Why this app matters

Andro Shredder is a strong example of why CleanerScope separates **user-facing method labels** from **verified overwrite behavior**. The app stores the selected method as an integer intensity value, and that value maps cleanly to visible algorithm names. However, decompiled code shows that those names do not correspond to distinct standard overwrite schedules in the implementation.

## Primary artifact paths

### Selected method state

The last selected method is stored in activity-private preferences:

```text
/data/data/com.apparillos.android.androshredder/shared_prefs/com.apparillos.android.androshredder.MainActivity.xml
```

Relevant keys:

- `shredIntensity`
- `wipeIntensity`

### Post-operation result log

The app also records completion summaries in default shared preferences:

```text
/data/data/com.apparillos.android.androshredder/shared_prefs/com.apparillos.android.androshredder_preferences.xml
```

Relevant keys include:

- `shredFinishedFlag`
- `shredFinishedTotal`
- `shredFinishedShredded`
- `shredFinishedMBS`
- `shredFinishedDuration`
- `shredFinishedNumFiles`
- `shredFinishedErrors`
- `shredFinishedFiles`

## Selector storage model

Andro Shredder stores the selected wipe method as an integer intensity value from `1` to `9`. Those values are displayed through resource-backed method names loaded from `R.array.general_method_names`.

Recovered example:

```xml
<int name="shredIntensity" value="3" />
```

Mapped user-facing names:

| Intensity | Displayed method name |
|---|---|
| `1` | `Quick` |
| `2` | `Russian GOST P50739-95` |
| `3` | `U.S. DoD 5220.22-M (E) / British HMG IS5 (E)` |
| `4` | `2 x Russian GOST P50739-95` |
| `5` | `Russian GOST P50739-95 + U.S. DoD 5220.22-M` |
| `6` | `2 x British HMG IS5 (E)` |
| `7` | `German BSI VSITR / U.S. DoD 5220.22-M (ECE)` |
| `8` | `4 x Russian GOST P50739-95` |
| `9` | `German BSI VSITR + Russian GOST P50739-95` |

CleanerScope therefore treats Andro Shredder as a **mapped dynamic method evidence** case: the recovered intensity value identifies the selected label, but the actual overwrite behavior must still be checked in code.

## Verified overwrite behavior

Static analysis showed that the displayed methods do **not** correspond to distinct standard overwrite algorithms. All intensity levels use the same random overwrite pattern. The intensity changes only the **number of passes**, not the per-pass byte pattern.

### File-shredding path

The main file-shredding service:

- uses a 4 MB chunk size,
- initializes `SecureRandom` once per shred session,
- calls `sr.nextBytes(chunk)` once before the file loop,
- reuses that same chunk for all passes of all files,
- calls `Os.fsync(fd)` after each 4 MB write in the primary SAF path.

Implementation summary:

```java
sr.nextBytes(chunk);   // once at session start
while (pass < intensity) {
    Os.lseek(fd, 0L, SEEK_SET);
    while (written < fileSize) {
        Os.write(fd, chunk, 0, chunkSizeToWrite);
        Os.fsync(fd);
    }
    pass++;
}
```

### Free-space wipe path

The free-space wipe service:

- uses a 5 MB chunk size,
- also generates the random chunk once,
- reuses the same random data for repeated in-place passes,
- writes temporary files named `AndroShredderWipeFile0`, `AndroShredderWipeFile1`, and so on.

## Critical implementation caveat

This is the main result that should accompany any selector mapping:

- the app displays named methods such as DoD, GOST, and BSI VSITR,
- but decompiled code does **not** implement their distinct fixed pass patterns,
- all passes use the same generated random buffer,
- only the pass count changes.

So a recovered intensity value tells the analyst which **label** the user chose, but not that the advertised standard was actually implemented faithfully.

## Flush behavior

The primary SAF-based path uses:

```java
Os.fsync(fd)
```

after each 4 MB write, which is stronger than a plain buffered flush. The direct-file fallback path instead uses:

```java
fos.flush()
```

without an explicit `fsync`, so the fallback path does not provide the same hardware-flush guarantee.

## Additional forensic artifacts

The default preferences file records high-value post-operation metadata:

- total bytes selected,
- bytes actually written,
- duration,
- throughput,
- number of processed files,
- JSON list of processed file URIs,
- JSON list of error objects.

Of these, `shredFinishedFiles` is especially important because it can preserve a JSON array of the selected file URIs.

Optional human-readable task logs may also be written under:

```text
/data/data/com.apparillos.android.androshredder/files/tasklog__[taskName]_[yyyyMMddHHmmss]
```

Free-space wipe temp files left behind under user storage indicate an interrupted wipe if cleanup did not finish.

## Forensic interpretation

For Andro Shredder, CleanerScope reconstructs the method in two steps:

1. recover `shredIntensity` or `wipeIntensity` from activity-private preferences,
2. map the recovered integer to the corresponding user-visible method label from resources,
3. verify the implementation in code to determine whether the label matches a distinct overwrite routine.

This app is therefore a textbook case where:

- **selector recovery succeeds**, but
- **implementation validation changes the interpretation**.

## Suggested supporting snippets

Selector artifact snippet:

```xml
<int name="shredIntensity" value="3" />
```

Implementation caveat snippet:

```text
All intensity levels reuse the same random buffer. The selected method changes pass count, not overwrite pattern.
```

Post-operation evidence snippet:

```text
shredFinishedFiles = JSON array of processed file URIs
```

## Confidence classification

- **Artifact class:** mapped dynamic method evidence
- **Interpretation confidence:** high for recovered intensity value
- **Implementation confidence:** high for the conclusion that all methods collapse to the same random-overwrite pattern with different pass counts

## Conclusion

Andro Shredder stores the selected method as a recoverable intensity value, but static analysis shows that the nine displayed methods are user-facing labels only. The implementation uses one session-generated random buffer reused across all passes, so the recovered selector identifies the chosen label while code inspection determines the actual overwrite behavior.
