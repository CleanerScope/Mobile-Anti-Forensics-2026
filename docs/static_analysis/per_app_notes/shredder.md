# Shredder Static-Analysis Note

## App identity

- **Application:** Shredder (Data Sanitizer)
- **Package:** `com.trictech.shred`
- **Version name:** `1.1`
- **Version code:** `2`
- **Launcher:** `com.trictech.shred.SplashActivity`

## Why this app matters

Shredder is important because the selected method is directly recoverable from app-private preferences, but the actual overwrite behavior depends materially on the storage path. The same algorithm label can produce different pass counts and patterns depending on whether the app uses direct file access or SAF/URI access.

## Primary artifact path

The selected method is stored in:

```text
/data/data/com.trictech.shred/shared_prefs/com.trictech.shred_preferences.xml
```

Relevant keys:

- `algorithm`
- `type`
- `delete_thumbnail`
- `hidden`
- `language`

An additional preferences file may store the granted SAF tree URI:

```text
/data/data/com.trictech.shred/shared_prefs/<empty-name>.xml
```

with key:

- `treeUri`

## Method storage model

Shredder stores the selected algorithm as a direct string value under:

```text
algorithm
```

Recovered values map directly to the wipe methods exposed in the UI.

Representative mappings:

| Stored value | Displayed method |
|---|---|
| `dod_3pass` | `DoD 5220.22-M (E) (3 pass)` |
| `british_hmg` | `British HMG IS5 (3 pass)` |
| `russian_gost` | `Russian Standard - GOST-R-50739-95` |
| `schneier_algo` | `Bruce Schneier's algorithm (7 pass)` |
| `german_vsitr` | `German VSITR (7 pass)` |
| `0` | `Overwrite Zeros (1 pass)` |
| `1` | `Overwrite Ones (1 pass)` |
| `random` | `Overwrite Random (1 pass)` |

CleanerScope therefore treats Shredder as a **direct dynamic method evidence** case at the storage level, while still requiring code inspection to determine what the label actually means on a given storage path.

## Path-dependent overwrite behavior

Shredder has two materially different file-shredding paths:

### Direct file path

- `RandomAccessFile(file, "rws")`
- `seek(0L)`
- write the entire file as one buffer
- synchronous write semantics from `"rws"`
- no explicit `fsync()` required because the direct writes are already synchronous

### SAF / URI path

- `ContentResolver.openFileDescriptor(uri, "rw")`
- `FileOutputStream`
- `write(...)`
- `flush()`
- no `fsync()`
- no `FileChannel.force()`

This distinction matters because the same selected method does not always produce the same concrete pass behavior across both paths.

## Critical discrepancies

### DoD 5220.22-M (E)

Stored value:

```text
dod_3pass
```

Observed behavior:

- direct file path: only **2 passes**
  - `[0x00]`
  - `[0xFF]`
- SAF path: **3 passes**
  - `[0x00]`
  - `[0xFF]`
  - `[random]`

So the app advertises a 3-pass DoD method, but the direct internal-file path appears to perform only 2 passes.

### British HMG IS5

Stored value:

```text
british_hmg
```

Observed behavior:

- direct file path:
  - `[0x00]`
  - `[random]`
- SAF path:
  - `[0x00]`
  - `[0x00]`
  - `[random]`

Neither path matches the published `0x00`, `0xFF`, `random` pattern usually associated with HMG IS5 Enhanced.

### Other representative methods

| Stored value | Decompiled pattern |
|---|---|
| `russian_gost` | `[0x00], [random]` |
| `schneier_algo` | `[0x01], [0x00], [random] x5` |
| `german_vsitr` | `[0x00], [0x01], [0x00], [0x01], [0x00], [0x01], [random]` |
| `random` | `[random]` |

## Random generation note

Random-fill generation is version-dependent:

```java
SecureRandom.getInstanceStrong()
```

is used on API `>= 26`, while:

```java
new Random().nextBytes(...)
```

is used on older Android versions. This means PRNG quality depends on platform version rather than only on the selected algorithm.

## Free-space wipe finding

The free-space wipe implementation is a critical negative result.

Static analysis showed that the feature does **not** apply an overwrite pattern to previously deleted free-space content. Instead, it:

- creates a 1 MB sparse file using `setLength()`, and
- writes `ABCDE` to `test.txt` on external storage.

This is not a genuine free-space sanitization routine.

Representative behavior:

```text
setLength(1048576)
write("ABCDE")
```

So for forensic interpretation, Shredder's free-space wipe should be treated as non-functional as a sanitizer.

## Additional forensic artifacts

No clear post-session report object, processed-file list, byte count, or duration record was identified in the examined app-private storage. The persistent app-private state is mostly:

- selected algorithm,
- shred mode (`delete_files` vs `scrap_files`),
- UI options,
- SAF tree URI.

Important interpretation note:

- `type = scrap_files` means overwrite only, no delete
- `type = delete_files` means overwrite followed by delete

That distinction may matter during post-event interpretation if a target file still exists.

## Forensic interpretation

For Shredder, CleanerScope reconstructs the selected method directly from the stored `algorithm` value, but then qualifies the conclusion by checking:

1. whether the storage path was direct or SAF-based,
2. whether the chosen algorithm has path-dependent behavior,
3. whether the free-space wipe claim corresponds to a real overwrite routine.

This app therefore demonstrates that:

- **direct stored method recovery can succeed**, but
- **storage-path-dependent implementation differences still matter**.

## Suggested supporting snippets

Method-storage snippet:

```xml
<string name="algorithm">dod_3pass</string>
```

Path-discrepancy snippet:

```text
DoD 3-pass delivers only 2 passes in the direct file path but 3 passes in the SAF path.
```

Free-space-wipe snippet:

```text
setLength(1048576) + write("ABCDE")
```

## Confidence classification

- **Artifact class:** direct dynamic method evidence
- **Interpretation confidence:** high for stored method recovery
- **Implementation confidence:** moderate to high for path-dependent method behavior; one direct-path DoD branch carries a decompilation-order warning and should be described carefully

## Conclusion

Shredder stores the selected algorithm directly and recoverably in app-private preferences, but its implementation varies significantly by storage path. DoD and British HMG labels do not produce consistent pass behavior across direct and SAF paths, and the free-space wipe feature does not perform meaningful sanitization of existing free-space data.
