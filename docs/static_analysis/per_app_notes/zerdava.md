# ZERDAVA

## App identity

- App: ZERDAVA File Shredder
- Package: `com.zerdava.fileshredder`
- versionName: `1.01.7725`
- versionCode: `7725`
- Launcher: `com.zerdava.fileshredder.FileShreddingActivity`
- Static-analysis source file:
  - `C:\AndroidForensicsProject\CleanerScope\static analysis findings\zerdava\Static_Analysis_Findings.txt`

## Why this app matters in CleanerScope

ZERDAVA is the clearest selector-mapping case in the successful app set.
Its dynamic artifact stores an integer selector rather than a self-explanatory method label, so static analysis is required to convert the recovered value into a human-readable wiping method and then verify what the code actually does.

It is also useful because the app is heavily obfuscated, which makes it a good reproducibility test for the static-analysis workflow itself.

## Primary artifact paths inspected

### App-private SharedPreferences
- `/data/data/com.zerdava.fileshredder/shared_prefs/ZerdavaAndroidFileShredderPreferenceHelper.xml`

### Relevant keys
- `KEY_SELECTED_SHRED_TYPE`
- `KEY_LICENSE_KEY_ACTIVATED`
- `KEY_IS_LAST_EMPTY_SHRED_FINISHED`

### Other relevant implementation paths
- SharedPreferences wrapper:
  - `b.c.a.l0.e`
- wipe engine:
  - `b.c.a.l0.h`
- algorithm registry:
  - `b.c.a.m0.o`

## Recovered selector model

The active method is stored as an integer under:
- `KEY_SELECTED_SHRED_TYPE`

This integer is dispatched through the wipe engine method `o()` and resolved against the algorithm registry defined in `b.c.a.m0.o.f1267a`.

### Interpretation class
- Evidence class: **mapped dynamic method evidence**
- Mapping class: **selector-to-label mapping required**

Reason:
- the dynamic artifact stores only an integer ID
- the human-readable method name must be reconstructed from the registry and dispatcher logic

## Key recovered selector example

```xml
<int name="KEY_SELECTED_SHRED_TYPE" value="128" />
```

Mapped interpretation:
- `128` -> `British HMG Enhanced`

Observed pass structure for `128`:
- `[0xFF, 0x00, random]`

This specific mapping is one of the most important cross-links between the static-analysis notes and the dynamic forensic findings.

## Algorithm set and mapping behavior

ZERDAVA exposes 22 wipe modes as integer bit-flag IDs.
Examples from the saved findings include:

| Selector ID | Mapped label | Observed passes |
|---:|---|---|
| `1` | `Random` | `[random]` |
| `2` | `All Zeros` | `[0x00]` |
| `4` | `All Ones` | `[0xFF]` |
| `8` | `Schneier` | `[0xFF, 0x00, random x5]` |
| `128` | `British HMG Enhanced` | `[0xFF, 0x00, random]` |
| `16384` | `BSI-VSITR` | `[0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, random]` |
| `262144` | `BSI TL-03423` | `[0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, random, random]` |
| `524288` | `GUTMANN` | `35-pass schedule confirmed` |

## Overwrite implementation summary

### Core write primitives
The wipe engine uses two principal write helpers in `b.c.a.l0.h`:
- `p(...)` for fixed-pattern writes
- `q(...)` for random writes

### Fixed-pattern behavior
- 1-byte patterns are expanded into repeated 1 MB buffers
- multi-byte patterns are cycled across the output buffer
- writes are performed through `FileOutputStream`

### Randomness behavior
ZERDAVA uses:
- `java.util.Random`
- not `SecureRandom`

Important implication:
- random overwrite behavior is not cryptographically strong
- this matters for implementation-quality interpretation

### I/O durability note
- writes close the output stream normally
- no explicit `fsync()` / `force()` is called in the documented write path
- hardware flush is therefore not guaranteed by the implementation alone

## Important implementation discrepancies

The saved findings document several meaningful divergences between user-facing method names and actual implementation behavior.

### CSEC ITSG-06 bug
Selector:
- `131072`

Observed issue:
- the final pass intended to be random is dead-code affected
- the generated random byte is discarded
- the written buffer is a zero-initialized new byte array

Actual sequence:
- `[0x00, 0xFF, 0x00]`

This is a strong example of why static implementation validation is necessary even when a named method is recoverable.

### NATO / RCMP / BSI-VSITR collapse
Selectors:
- `32768` = NATO
- `65536` = RCMP TSSIT OPS-II
- `16384` = BSI-VSITR

Observed issue:
- all three execute the same code path
- all three produce the same pass structure

Implication:
- the stored label does not reliably distinguish the implemented schedule

### US DoD 5220.22M ECE divergence
Selector:
- `512`

Observed issue:
- pass structure diverges from the expected complement-pair form associated with the named standard

### PRNG weakness
Observed issue:
- all random data paths use `java.util.Random`
- no `SecureRandom` is used in overwrite execution

## Forensically important static locations

### Method selector storage
```text
/data/data/com.zerdava.fileshredder/shared_prefs/ZerdavaAndroidFileShredderPreferenceHelper.xml
Key: KEY_SELECTED_SHRED_TYPE
```

### Free-space wipe completion state
```text
Key: KEY_IS_LAST_EMPTY_SHRED_FINISHED
```

This key is useful as supporting app-state evidence for empty-space wiping.

## Confidence classification

### Directly observed in code
- selector storage key `KEY_SELECTED_SHRED_TYPE`
- switch-based algorithm dispatcher
- integer-to-pass mapping in the wipe engine
- use of `java.util.Random`
- specific discrepancy cases such as CSEC ITSG-06

### Mapped from code/resources
- selector IDs to named methods
- free vs pro availability split via license bitmask logic

### Inferred but not runtime-validated by static analysis alone
- exact storage-layer durability effect of the write path
- runtime persistence of each selector in specific user flows

## Static-analysis conclusion

ZERDAVA is a strong mapped-evidence app. The app-private selector artifact is clearly recoverable, but its meaning must be resolved through static mapping and then checked against the actual overwrite implementation. This app is important because it demonstrates that selector recovery alone is not enough: the code reveals several cases where named standards collapse together, diverge from specification, or contain implementation defects.

## Suggested supporting snippets for release package

### Selector storage concept
```text
SharedPreferences file: ZerdavaAndroidFileShredderPreferenceHelper.xml
Key: KEY_SELECTED_SHRED_TYPE
Example recovered value: 128
```

### Mapping example
```text
128 -> British HMG Enhanced -> [0xFF, 0x00, random]
```

### Implementation caveat example
```text
131072 (CSEC ITSG-06) executes [0x00, 0xFF, 0x00] due to dead random-code behavior.
```