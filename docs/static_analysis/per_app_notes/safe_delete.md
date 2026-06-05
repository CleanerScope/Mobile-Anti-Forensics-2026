# Safe Delete Static-Analysis Note

## App identity

- **Application:** Safe Delete
- **Package:** `com.seeroo.safedeleteApp`
- **Version name:** `1.7`
- **Version code:** `7`
- **Launcher:** `com.amaze.filemanager.activities.MainActivity`

## Why this app matters

Safe Delete is the clearest fixed-method case in the dataset. It does not expose any algorithm selector, pass-count setting, or named standard. The wipe behavior is entirely code-derived: one pass of zero overwrite followed by delete. It is also important because the implementation includes dead `SecureRandom` code and a path-dependent limitation for SAF-protected external storage.

## Primary artifact path

The app does not store a selectable wipe method. The relevant persistent configuration is instead found in:

```text
/data/data/com.seeroo.safedeleteApp/shared_prefs/com.seeroo.safedeleteApp_preferences.xml
```

Relevant keys:

- `rootmode`
- `URI`

These keys affect deletion path behavior, but not the overwrite algorithm itself.

## Method storage model

No user-configurable algorithm selection was identified.

There is:

- no method selector,
- no pass-count preference,
- no named standard,
- no overwrite-pattern preference.

CleanerScope therefore treats Safe Delete as a **code-derived only** method case:

- the wipe behavior is reconstructed from static code inspection,
- not from a stored dynamic selector or direct method record.

## Verified overwrite behavior

Static analysis showed a single hard-coded overwrite routine:

| Algorithm model | Passes | Pattern |
|---|---:|---|
| fixed | 1 | `[0x00]` |

The app:

1. opens the file with `RandomAccessFile(path, "rw")`,
2. maps the whole file into memory using `MappedByteBuffer`,
3. writes `0x00` byte-by-byte through the mapped region,
4. calls `buffer.force()`,
5. deletes the file.

Representative implementation summary:

```java
MappedByteBuffer buffer = channel.map(READ_WRITE, 0L, raf.length());
while (buffer.hasRemaining()) {
    buffer.put((byte) 0);
}
buffer.force();
```

This is one of the stronger flush paths in the dataset because `buffer.force()` maps to an `msync`-style durability call.

## Critical implementation caveat: dead SecureRandom code

The code constructs:

```java
new SecureRandom();
```

but the instance is never stored or used. No random bytes are ever written in the observed overwrite path.

This matters because:

- the code may appear to suggest a stronger random-wipe design,
- but the actual implementation is still only a single zero-fill pass.

## Delete behavior

After overwrite, deletion proceeds through the file-manager stack:

- standard `file.delete()`,
- `DocumentFile.delete()` fallback for some SAF cases,
- MediaStore cleanup calls,
- optional root shell deletion if normal delete fails and `rootmode=true`.

Important characteristics:

- no rename-before-delete,
- no timestamp zeroing,
- filename remains unchanged until deletion,
- MediaStore entries are explicitly cleaned up.

## External-SD / SAF limitation

This is the main limitation that should accompany the code-derived method claim.

The overwrite path uses:

```java
new RandomAccessFile(path, "rw")
```

on the raw file path before delete. For files on external SD storage that require SAF-mediated access, that overwrite open may fail. The code catches exceptions without converting them into a stronger failure signal. In that case:

- the overwrite may not occur,
- the subsequent delete path may still remove the file,
- the file may therefore be deleted without any preceding overwrite.

This is a real implementation constraint and should be stated explicitly.

## Additional forensic artifacts

No per-session wipe record, processed-file list, byte count, duration record, or report object was identified.

Persistent wipe-relevant state is minimal:

- `rootmode` indicates whether root-assisted delete behavior was enabled,
- `URI` may indicate that the user had granted SAF access for external storage.

Neither key identifies a wipe algorithm, because no configurable algorithm exists.

## Free-space wipe

No free-space wipe feature was identified in this application.

## Forensic interpretation

For Safe Delete, CleanerScope reconstructs the method from code only:

1. confirm that no user-selectable method artifact exists,
2. inspect `PermanentDeleteTask`,
3. derive the overwrite model as one zero-fill pass plus delete,
4. qualify the conclusion with the external-SD/SAF limitation and the absence of random overwrite.

This app therefore demonstrates the **code-only reconstruction** branch of the framework.

## Suggested supporting snippets

Code-derived method snippet:

```java
while (buffer.hasRemaining()) {
    buffer.put((byte) 0);
}
buffer.force();
```

Dead-code snippet:

```java
new SecureRandom();   // instantiated but unused
```

Interpretive snippet:

```text
No dynamic method selector exists; the wipe behavior is reconstructed directly from PermanentDeleteTask.
```

## Confidence classification

- **Artifact class:** code-derived only
- **Interpretation confidence:** high for the fixed one-pass zero-fill overwrite on normal writable paths
- **Implementation confidence:** moderate to high overall, with an explicit limitation for SAF-protected external storage where overwrite may fail before deletion

## Conclusion

Safe Delete implements a single hard-coded one-pass zero overwrite through memory-mapped I/O followed by `buffer.force()`. It has no user-selectable method state, no multi-pass logic, and no working random-overwrite path. The main caveat is that external-SD files requiring SAF access may be deleted without a successful overwrite if the raw-path memory-mapped open fails.
