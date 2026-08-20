# 1-timezone

A tiny [KOReader](https://koreader.rocks) user patch that forces a correct timezone inside the KOReader process. It fixes a wrong footer clock, a "Synchronize time" that never seems to help, and AutoWarmth picking up a nonsense timezone, on devices that run KOReader **without the vendor reader framework**.

Ships with a default of Eastern Time (`America/Toronto`). One line changes it to your zone.

## The problem it solves

When KOReader runs standalone, without the device maker's reading app around it (the common case on a jailbroken Kindle that boots straight into KOReader), nothing exports a `TZ` to the process. The base system then resolves `os.date()` against whatever `/etc/localtime` happens to be. On many devices that is not your real zone but a **Local Mean Time** entry, which produces a fractional-hour offset like `-4:56`.

The symptoms all trace back to that one cause:

- **The footer clock is off**, typically by around an hour, sometimes an odd number of minutes.
- **"Synchronize time" does not fix it.** NTP sync corrects the absolute instant (UTC). The wrong part is the *offset* the device applies for display, which sync never touches, so the clock snaps right back.
- **AutoWarmth stores a strange timezone.** Its `getTimezoneOffset()` just asks the OS for `localtime - UTC`, so it faithfully records the bogus offset (for example `-4.9333`), and the warm-light schedule ends up shifted from real local time.

## What it does

The patch sets the POSIX `TZ` environment variable inside the KOReader process and calls `tzset()`, early, before anything reads the clock. After that, `os.date()`, the footer clock, time sync, and AutoWarmth all agree on the same real local time, with daylight saving handled automatically.

It only touches the KOReader process. The vendor OS clock and its own settings are left alone, so nothing changes if you ever boot back into the stock reader.

## Requirements

- KOReader on a device where you can drop files into `koreader/patches/` (Kindle, Kobo, PocketBook, reMarkable, Android, and so on).
- A build with the FFI POSIX header available (standard on all the above). The patch uses `setenv` from `ffi/posix_h` plus a one-line `tzset` declaration.

This is aimed at framework-less installs, but it is harmless anywhere: if a correct `TZ` is already in effect, setting the same value again is a no-op.

## Installation

1. Copy `1-timezone.lua` into your `koreader/patches/` directory.
   - **Keep the `1-` filename prefix.** KOReader runs `1-` patches early in startup, which is what lets this one set the zone before the first `os.date()` call.
2. Set your zone (see [Configuration](#configuration)) if you are not on Eastern Time.
3. Restart KOReader (a full exit and relaunch, not just a wake from sleep). Patches load at startup.

## Configuration

Open `1-timezone.lua` and edit the one line near the top:

```lua
local TZ = "EST5EDT,M3.2.0,M11.1.0"
```

The value is a POSIX `TZ` string: `STDoffset[DST[offset][,startrule,endrule]]`. The offset sign is inverted from UTC, so zones west of UTC are positive. The `,M<month>.<week>.<day>` rules encode the daylight-saving switchover, so DST flips automatically twice a year with no further edits.

| Zone | `TZ` value |
| --- | --- |
| America/Toronto (Eastern) | `EST5EDT,M3.2.0,M11.1.0` (shipped default) |
| America/Chicago (Central) | `CST6CDT,M3.2.0,M11.1.0` |
| America/Denver (Mountain) | `MST7MDT,M3.2.0,M11.1.0` |
| America/Los_Angeles (Pacific) | `PST8PDT,M3.2.0,M11.1.0` |
| Europe/London | `GMT0BST,M3.5.0/1,M10.5.0` |
| Europe/Berlin (Central Europe) | `CET-1CEST,M3.5.0,M10.5.0/3` |
| Fixed offset, no DST (example UTC-5) | `EST5` |

For anywhere else, the POSIX `TZ` string for a given IANA zone is the last line of its `zdump -v` output, or you can build one by hand from the rules above.

## Verifying it worked

After a full restart:

- The footer clock matches a known-good clock (your phone).
- If you use AutoWarmth, reopen its settings; the stored timezone should now read a clean whole (or half) hour matching your zone rather than a fractional value. AutoWarmth rewrites it from the OS on its next run, so this is a good confirmation the process now has the right zone.

If the clock is still wrong, the patch did not load. Check `koreader/crash.log` for a load error, and confirm the file is named with the `1-` prefix and sits directly in `koreader/patches/`.

## How it works

```lua
local ffi = require("ffi")
require("ffi/posix_h")            -- provides setenv()
ffi.cdef[[ void tzset(void); ]]
ffi.C.setenv("TZ", TZ, 1)
ffi.C.tzset()
```

`setenv("TZ", ...)` sets the timezone for the process, and `tzset()` makes the C library re-read it so the very next `os.date()` reflects the new zone. Because the file runs as a `1-` patch, this happens before KOReader builds any clock or scheduling state. `setenv` is already declared in KOReader's `ffi/posix_h`; only `tzset` needs the extra one-line declaration.

## License

Licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0), matching KOReader, on which this patch depends. See [`LICENSE`](LICENSE) for the full text.

### support

if any of this is useful to you and you'd like to chip in:

```
bc1qkge6zr45tzqfwfmvma2ylumt6mg7wlwmhr05yv
```

https://liberapay.com/bdkl/
