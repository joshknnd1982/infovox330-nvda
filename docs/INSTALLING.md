# Installing and running the add-on

## Getting the add-on file

Built add-ons are published on the
[Releases page](https://github.com/joshknnd1982/infovox330-nvda/releases). Each release
carries a single `infovox330.nvda-addon` file as an attached asset.

Because the file is roughly 160 MB, it is attached as a release asset rather than committed:
GitHub caps files inside a repository at 100 MB, while release assets may be up to 2 GB. So
cloning does not hand you a ready-built `.nvda-addon` — you download it from the release
page, or you build one following [BUILDING.md](BUILDING.md). (The repository does contain the
engine and voice files a build needs; see [NOTICE.md](../NOTICE.md) for what that means.)

On the release page, expand the **Assets** section and choose `infovox330.nvda-addon`. Your
browser may warn about the file type or the size. It is a ZIP archive with a custom
extension, which is what NVDA expects.

Each release also carries an `infovox330.nvda-addon.sha256` file. Checking it is worth the
few seconds for a download this size, because a truncated file fails at install time in ways
that look like a broken add-on rather than a broken download:

```powershell
Get-FileHash infovox330.nvda-addon -Algorithm SHA256
```

> **If no release is published**, build the add-on yourself from your own Infovox 330 media.
> [BUILDING.md](BUILDING.md) has the procedure and it is not difficult.

## Requirements

You need NVDA 2026.1 or later on 64-bit Windows. The add-on declares
`minimumNVDAVersion = 2026.1.0` because it depends on NVDA's bundled 32-bit synthesizer host
(`_bridge.clients.synthDriverHost32`), which older NVDA releases do not provide. Installing
on an earlier NVDA will be refused by the add-on store rather than failing mysteriously
later.

You do **not** need Infovox 330 installed on the machine, and you do not need administrator
rights. That is the entire point of the design: the add-on carries its own engine and serves
it a synthetic registry from memory.

You also do **not** need the Microsoft SAPI 4 runtime. This surprises people, because the
engine is a SAPI 4 engine and the original Infovox media ships `spchapi.exe` to install that
runtime. It is not needed here, for two reasons. `Ivx330nt.dll` is a self-contained
in-process COM server whose only imports are Windows system libraries and its own bundled
`Sx32w.dll` — it links against no part of the SAPI 4 runtime, statically or dynamically. And
the add-on never asks COM for a SAPI 4 object: `infovox_host.dll` calls the engine's
`DllGetClassObject` entry point directly, and the SAPI 4 interfaces the driver uses are
vendored as plain `comtypes` definitions in `_infovox_sapi4.py`, which are type descriptions
rather than code needing a runtime. The audio sink handed to the engine is the add-on's own
Python object, not the runtime's `MMAudioDest`. Nothing in the speech path touches
`spchapi.exe`, `Speech.dll` or `xtts50.dll`.

## Installing

The simplest route is to open the downloaded `.nvda-addon` file — double-click it, or press
Enter on it in File Explorer. Windows hands it to NVDA, which shows a confirmation dialog
describing the add-on. Choose **Yes**.

If the file association is not set up, install from inside NVDA instead. Press `NVDA+N` to
open the NVDA menu, then go to **Tools → Add-on store**, activate the **Install from
external source** button, and browse to the downloaded file.

Either way, NVDA installs the add-on and then asks to restart. Say yes. The add-on is not
active until NVDA has restarted, and installation of a 160 MB add-on takes a noticeable
moment while NVDA unpacks it — do not assume it has hung.

## Selecting the synthesizer

Once NVDA is back, press `NVDA+Ctrl+S` to open the Synthesizer dialog directly, or navigate
**NVDA menu → Preferences → Settings → Speech**.

In the synthesizer list, choose **Infovox 330** and confirm with **OK**. NVDA switches
immediately and you will hear the new voice. The first voice in the list is whichever one
the engine enumerates first, which is normally Poul, the Danish voice — so do not be alarmed
if your screen reader suddenly starts speaking English text with a Danish accent. Pick the
voice you actually want next.

Voice selection lives in the same Speech settings panel. The **Voice** combo box lists all
sixteen. Rate, pitch and volume sliders appear underneath, but note that which of them are
available depends on the selected voice: the driver queries each voice's declared
capabilities and only shows the controls that voice genuinely supports. A voice offering no
pitch control will simply not show a pitch slider.

## If it does not appear in the list

When a synthesizer is missing from NVDA's list, it means the driver's `check()` method
returned false — NVDA silently hides synthesizers that report themselves unavailable rather
than offering something that cannot start.

For this add-on, `check()` verifies two things: that `infovox_host.dll` is present in
`synthDrivers32`, and that `Ivx330\Ivx330nt.dll` is present alongside it. If either is
missing the synthesizer will not be offered. The usual cause is a build where the engine
files were not supplied, producing an add-on that installs perfectly happily and then does
nothing.

Verify by looking inside the installed add-on folder, which lives at:

```
%APPDATA%\nvda\addons\infovox330\synthDrivers32\
```

You should see `infovox_host.dll`, an `Ivx330` folder containing three DLLs, and a
`Voices Ivx330` folder containing several hundred megabytes of `.ddb` files. If the voices
folder is empty or the `Ivx330` folder is missing, rebuild the add-on and supply the missing
inputs.

## If it appears but does not speak

This is the more interesting failure, and it means the driver loaded but the engine did not
produce audio.

Start by enabling debug logging for the synthesizer, since the driver is instrumented
throughout and will tell you a great deal. Set NVDA's log level to Debug under **Preferences
→ Settings → General**, restart NVDA, reproduce the problem, then open the log with
`NVDA+F1`. Entries are prefixed `SAPI4:` and trace the audio handshake — claim, start,
buffer writes, bookmarks — step by step.

The registry-virtualisation shim writes its own log next to the driver, at
`synthDrivers32\_infovox_host.log`. This is the file to read when the engine fails to
initialise at all, because it records how many import-address-table hooks were installed and
which synthetic registry queries the engine made. An engine that queries a key the shim does
not serve will fail in exactly this way, and the log names the key.

Two failure signatures are worth knowing. `Infovox host init failed` means `IVX_Init`
returned non-zero, so the engine DLL could not be loaded or the hooks could not be installed
— usually a missing `cryput.dll` or `Sx32w.dll`. `No Sapi4 engines available` means the
engine loaded but enumerated zero voices, which points at the voice folder: either it is
empty, or `VoiceDescriptions.txt` references `.ddb` files that are not actually present.

If NVDA speaks with other synthesizers but not this one, and neither log shows an error, the
problem is more likely to be audio output device selection than the engine. The driver
creates its wave player using NVDA's configured output device, so an output device that has
disappeared since it was configured will produce silence without complaint.

## Uninstalling

Open **NVDA menu → Tools → Add-on store → Installed add-ons**, select Infovox 330, and
activate **Remove**. NVDA restarts and the add-on is gone.

Because the add-on never writes to the registry and never installs files outside its own
folder, removal is genuinely complete. There is no leftover COM registration, no orphaned
`HKLM` key, and no engine installed system-wide. If NVDA was using Infovox 330 as its
synthesizer at the time, it falls back to its default automatically.
