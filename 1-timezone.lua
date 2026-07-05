-- 1-timezone.lua : force a correct timezone inside KOReader.
--
-- Why this exists: on installs that run KOReader WITHOUT the vendor reader
-- framework (e.g. a jailbroken Kindle launched straight into KOReader), no TZ
-- is exported to the process. The base system then resolves os.date() to
-- whatever /etc/localtime happens to be, which is often a bogus Local Mean Time
-- offset (a fractional-hour value like -4:56). The result: a wrong footer
-- clock, "Synchronize time" that never appears to correct it (it fixes UTC, not
-- the offset), and AutoWarmth capturing a nonsense timezone.
--
-- This patch sets the POSIX TZ variable inside the KOReader process and calls
-- tzset(), so os.date(), the footer clock, time sync, and AutoWarmth all agree.
-- It affects the KOReader process only; the vendor OS clock is untouched.
--
-- CONFIG: change the TZ string below to your zone, then restart KOReader.
-- The format is POSIX TZ: STDoffset[DST[offset][,startrule,endrule]].
-- Examples (offset sign is inverted from UTC: west of UTC is positive):
--   America/Toronto (Eastern) ... "EST5EDT,M3.2.0,M11.1.0"   <- shipped default
--   America/Chicago (Central) ... "CST6CDT,M3.2.0,M11.1.0"
--   America/Denver  (Mountain).. "MST7MDT,M3.2.0,M11.1.0"
--   America/Los_Angeles ........ "PST8PDT,M3.2.0,M11.1.0"
--   Europe/London .............. "GMT0BST,M3.5.0/1,M10.5.0"
--   Europe/Berlin (CET) ........ "CET-1CEST,M3.5.0,M10.5.0/3"
--   No DST, e.g. UTC-5 fixed .... "EST5"
-- The ,M<month>.<week>.<day> rules encode the daylight-saving switch, so DST
-- flips automatically twice a year with no further edits.
local TZ = "EST5EDT,M3.2.0,M11.1.0"

local ffi = require("ffi")
require("ffi/posix_h")            -- provides setenv()
ffi.cdef[[ void tzset(void); ]]
ffi.C.setenv("TZ", TZ, 1)
ffi.C.tzset()
