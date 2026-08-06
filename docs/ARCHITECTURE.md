# How the add-on works

There are three obstacles between a 2001 speech engine and a modern screen reader, and the
add-on solves each one in a different place. Understanding which layer does what makes the
code much easier to follow.

## Obstacle one: the engine is 32-bit and NVDA is not

Infovox 330 ships as `Ivx330nt.dll`, a 32-bit in-process COM server. NVDA on modern Windows
runs as a 64-bit process, and a 64-bit process cannot load a 32-bit DLL into its address
space. No amount of clever code changes this; it is a property of the platform.

NVDA solves this generally with a bundled 32-bit synthesizer host, exposed to add-on authors
as `_bridge.clients.synthDriverHost32.SynthDriverProxy32`. The host is a separate 32-bit
process that loads a synthesizer driver on NVDA's behalf and proxies speech calls across the
process boundary.

That is why there are two driver files with the same name:

`addon/synthDrivers/infovox330.py` is loaded by NVDA itself, in the 64-bit process. It is
twenty lines long and does almost nothing. It subclasses `SynthDriverProxy32`, points
`synthDriver32Path` at the sibling `synthDrivers32` folder, and overrides `check()` to
additionally confirm that `infovox_host.dll` exists before advertising itself as available.

`addon/synthDrivers32/infovox330.py` is the real driver, loaded by the 32-bit host. This is
where all the SAPI 4 work happens. Everything below this point in the document concerns that
file and the shim it calls.

## Obstacle two: SAPI 4 is a dead API with sharp edges

SAPI 4 predates SAPI 5 by years and works on completely different principles. It is
apartment-threaded COM that requires a running Windows message loop, it hands audio to the
application through a COM interface the application must implement rather than writing to a
device itself, and it notifies about speech progress through a second set of callback
interfaces.

The driver in `synthDrivers32/infovox330.py` is derived from NVDA's own `sapi4.py`, which
already solves these problems, and the shape of that solution is visible throughout.

A dedicated `_ComThread` owns every COM call. It creates a message queue, calls
`CoInitialize`, and then runs a `GetMessage` loop, processing queued work between message
dispatches rather than inside window procedures — the comment in the code explains why, and
the answer is `RPC_E_CANTCALLOUT_INEXTERNALCALL`. Every COM pointer the driver holds is
wrapped in a `_ComProxy`, whose `__getattr__` reroutes any method call onto that thread. The
effect is that the rest of the driver can be written as ordinary synchronous code while the
threading requirement is satisfied invisibly.

Audio flows the opposite way from what you might expect. `SynthDriverAudio` implements the
SAPI 4 `IAudio` and `IAudioDest` interfaces and is handed *to* the engine, which then calls
into it: `WaveFormatSet` to declare the format, `Claim` to reserve the device, repeated
`DataSet` calls to push PCM, `BookMark` to request notification when playback reaches a
point, and `UnClaim` when finished. The class buffers that data and feeds it to an
`nvwave.WavePlayer`, translating between the engine's byte-position world and NVDA's
index-notification world along the way. Two seconds of buffering is not an arbitrary choice
— SAPI 4 requires at least that much.

Speech commands are translated into the engine's inline escape syntax rather than API calls.
An `IndexCommand` becomes `\mrk=N\`, a `BreakCommand` becomes `\Pau=N\`, character mode
toggles with `\RmS=1\`, and prosody uses `\Pit=`, `\Spd=` and `\Vol=`. There is a defensive
wrinkle here worth noting: because some SAPI 4 voices reset all prosody on receiving any
prosody command while others never restore it, the driver brackets any sequence containing
prosody with explicit defaults at both ends.

Two workarounds exist purely because engines of this era were unreliable about COM reference
counting. Both `SynthDriverBufSink` and `SynthDriverAudio` override `IUnknown_Release` to
refuse to drop to zero while a `_allowDelete` flag is false, because engines have been
observed calling `Release` more times than they called `AddRef`. Without this the driver
crashes on shutdown.

## Obstacle three: the engine expects to be installed, and it is not

This is the part that is specific to this project rather than inherited from NVDA.

`Ivx330nt.dll` was written on the assumption that Infovox 330 had been installed by its
setup program. On startup it reads `HKLM\SOFTWARE\Babel-Infovox AB\Infovox 330`, walks the
`Modes` subkey to discover which voices exist, reads each voice's mode GUID, speaker name,
language ID, diphone file and rule file from there, and consults `LicenseDir` to find its
licensing state. If those keys are absent the engine reports that no voices are available.

Registering the engine properly would mean running `regsvr32` as administrator, importing a
large `.reg` file into `HKLM`, and leaving a system-wide COM registration behind. For a
screen-reader add-on that a user may want to try and then remove, that is an unacceptable
footprint.

`infovox_host.dll` avoids it. The shim is a small 32-bit DLL, built with MinGW-w64 GCC 13,
exporting three functions:

```c
int  IVX_Init(const wchar_t *enginePath, const wchar_t *voicesDir);
HRESULT IVX_CreateEnumerator(void **ppEnum);   /* yields an ITTSEnumW */
void IVX_Shutdown(void);
```

`IVX_Init` loads the engine DLL manually and then rewrites its **import address table**,
replacing the entries for the advapi32 registry functions — `RegOpenKeyExA`,
`RegCreateKeyExA`, `RegQueryValueExA`, `RegEnumKeyExA`, `RegQueryInfoKeyA`, `RegCloseKey`,
`RegSetValueExA`, `RegSetValueA`, `RegDeleteKeyA`, `RegDeleteValueA` — with its own
implementations. From that moment on, every registry call the engine makes is answered from
a synthetic in-memory hive rather than from Windows.

That hive is built by parsing `VoiceDescriptions.txt` from the voices folder, which contains
exactly the per-voice metadata the engine is looking for: mode GUID, language ID, speaker
name, gender, age, default pitch and dynamics, and the filenames of the diphone database,
phone map and rule file. The shim reproduces the `Infovox 330\Modes\...` key structure the
engine walks, rewrites file paths to point inside the add-on folder, and supplies
`LicenseDir`. The engine reads all this back, concludes it is properly installed, and
enumerates its voices.

`IVX_CreateEnumerator` then instantiates the engine's class factory directly and returns an
`ITTSEnumW` — the same interface the driver would have received from
`CoCreateInstance(CLSID_TTSEnumerator)` had the engine been registered. The shim writes a
log of what it did to `_infovox_host.log` beside itself, including how many IAT hooks it
installed, which is the first thing to read when initialisation fails.

The driver's side of this is deliberately small. `SynthDriver._createEngineEnumerator` loads
the shim with `ctypes.CDLL`, calls `IVX_Init` with the engine path and voices directory,
calls `IVX_CreateEnumerator`, and casts the resulting pointer to `POINTER(ITTSEnumW)`. From
that point the code is indistinguishable from talking to a normally registered SAPI 4
engine, which is exactly the design goal: the shim's entire job is to make the difference
invisible to everything above it.

## Why `_infovox_sapi4.py` is vendored

The interface definitions in `synthDrivers32/_infovox_sapi4.py` — `ITTSEnumW`,
`ITTSCentralW`, `IAudio`, `IAudioDest`, the `TTSMODEINFOW` structure and the rest — duplicate
definitions that also exist inside NVDA. They are vendored rather than imported for two
reasons. The 32-bit synthesizer host does not put NVDA's own `synthDrivers` package on the
import path for add-on drivers, and pinning the definitions in the add-on means an internal
reorganisation on NVDA's side cannot silently break the add-on. The driver inserts its own
directory into `sys.path` at import time so this module resolves.

## The consequence

Because nothing is registered and nothing is installed, the add-on is fully self-contained.
It needs no administrator rights, it coexists with any real Infovox installation without
interfering with it, and uninstalling it removes every trace. The cost is that the add-on
must carry the entire engine and all of its voice data, which is why the built file is
roughly 160 MB — an unusual size for an NVDA add-on, and the reason releases are distributed
as release assets rather than through the add-on store.
