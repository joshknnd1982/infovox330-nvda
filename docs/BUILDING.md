# Building the add-on from source

## What you are building, and why it takes two ingredients

The finished add-on is a single `.nvda-addon` file, which is really just a ZIP archive with
a different extension. Inside it sit two very different kinds of material.

The first kind is the code in this repository: the NVDA synthesizer driver, the SAPI 4
interface definitions, and the registry-virtualisation shim. That material is open, it is
version-controlled here, and it is what the project actually consists of.

The second kind is the Infovox 330 engine itself and its voice databases. Those are
copyrighted works belonging to Acapela Group, successor to Babel-Infovox AB, and they are
**not** distributed in this repository. You have to supply them from your own copy of
Infovox 330.

The build script's job is to marry the two together and zip the result. Everything else
here is detail.

## Prerequisites

You need a Windows machine — the build produces a Windows add-on and the script copies
Windows binaries, so building on Linux or macOS is not supported. Windows PowerShell 5.1,
which ships with Windows, is sufficient; PowerShell 7 works equally well. Git is useful for
cloning but you can also download the repository as a ZIP.

You do **not** need a compiler. The registry-virtualisation shim, `infovox_host.dll`, is
committed to this repository as a prebuilt 32-bit binary, so the build is a pure assemble-
and-zip operation with no compilation step.

Finally, you need roughly 700 MB of free disk space. The voice data is about 250 MB, the
staging copy is another 250 MB, and the compressed output is around 160 MB.

## The files you must supply

### The engine

Three DLLs, which live in the Infovox 330 program directory of an installed copy — by
default `C:\Program Files\Telia Promotor\Ivx330` — or in the `Ivx330` folder on the original
distribution CD.

| File | Approximate size | What it is |
|---|---|---|
| `Ivx330nt.dll` | 380 KB | the Infovox 330 SAPI 4 engine itself |
| `Sx32w.dll` | 37 KB | engine support library |
| `cryput.dll` | 220 KB | the CrypKey licensing runtime the engine links against |

Ideally put all three in one folder and point `-Engine` at it; the default is a folder called
`Ivx330` next to the repository. They do not strictly have to be together, though — on
machines where Infovox was unpacked rather than properly installed, `cryput.dll` often ends
up a level above the other two, so the script also searches the parent of `-Engine` and the
folder containing the repository. It prints where it found each file, so you can confirm it
picked up what you expected.

### The voices

A folder — conventionally called `Voices Ivx330` — containing the voice data. The script
copies every file with a `.ddb`, `.ivx`, `.phm`, `.dll` or `.txt` extension, and requires
`VoiceDescriptions.txt` to be present because the shim parses it to discover which voices
exist.

Each voice contributes a diphone database (`.ddb`, the bulk of the size), a phone mapping
file (`.phm`), and shares a language-wide pronunciation rule file (`.ivx`) with the other
voices of the same language. Danish additionally ships a `darules.dll`.

A complete 16-voice set runs to about 250 MB. You do not have to include all of them — if
you only want, say, Swedish and English, copy only those voices' files plus their rule
files and edit `VoiceDescriptions.txt` down to match. The add-on will be correspondingly
smaller.

## Building

Clone the repository and run the build script, pointing it at your two folders:

```powershell
git clone https://github.com/joshknnd1982/infovox330-nvda.git
cd infovox330-nvda

powershell -ExecutionPolicy Bypass -File tools\build_addon.ps1 `
    -Engine "C:\Program Files\Telia Promotor\Ivx330" `
    -Voices "D:\Voices Ivx330"
```

If you have the classic working layout — `Ivx330` and `Voices Ivx330` sitting alongside the
repository folder — you can omit both switches and just run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_addon.ps1
```

The script validates your inputs before touching anything, stages the add-on tree into
`build\`, copies the engine and then the voices, and finally zips everything into
`dist\infovox330.nvda-addon`. Expect the voice copy to dominate the runtime; on a mechanical
drive it can take a couple of minutes, and the script shows a progress bar throughout.

On success you get a summary with the output path and its size. A typical full build lands
around 160 MB.

## What the build actually assembles

The staged tree that gets zipped looks like this:

```
infovox330/
  manifest.ini                          from the repository
  synthDrivers/
    infovox330.py                       from the repository - 64-bit proxy
  synthDrivers32/
    infovox330.py                       from the repository - the real driver
    _infovox_sapi4.py                   from the repository - SAPI 4 definitions
    infovox_host.dll                    from the repository - registry shim
    Ivx330/
      Ivx330nt.dll                      YOURS
      Sx32w.dll                         YOURS
      cryput.dll                        YOURS
    Voices Ivx330/
      VoiceDescriptions.txt             YOURS
      *.ddb  *.phm  *.ivx  darules.dll  YOURS
```

The split between `synthDrivers/` and `synthDrivers32/` is the heart of the design. NVDA
itself is a 64-bit process and cannot load a 32-bit COM engine directly, so the file in
`synthDrivers/` is a thin proxy that asks NVDA's bundled 32-bit synthesizer host to load the
real driver out of `synthDrivers32/`. [ARCHITECTURE.md](ARCHITECTURE.md) covers this in
more depth.

## Verifying the result

Two quick checks are worth doing before you trust a build.

Confirm the archive contains what you expect, particularly that the voice data actually made
it in:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead("dist\infovox330.nvda-addon")
$z.Entries.Count
$z.Entries | Where-Object { $_.FullName -like '*.ddb' } | Select-Object -First 5 FullName, Length
$z.Dispose()
```

Then install it into NVDA and listen. There is no substitute for this step: the engine can
load successfully, enumerate all sixteen voices, and still produce silence if the voice data
paths are subtly wrong. [INSTALLING.md](INSTALLING.md) walks through installation and what
to do when something is wrong.

## Diagnostic tools

Two helper scripts in `tools/` survive from the original reverse-engineering work.

`ivx_diag.ps1` inspects the machine for an existing Infovox installation, checks registry
state, and reports what it finds. It is useful when you are trying to work out where a
legacy install put its files.

`run_speak.ps1` drives the engine directly, outside NVDA, and speaks every voice in turn.
When NVDA reports the synthesizer as unavailable, this tells you whether the problem is in
the engine layer or the NVDA layer — a distinction that saves a lot of time.

Both expect the companion diagnostic executables from the original working folder, which are
not part of this repository.

## A note on rebuilding the shim

`infovox_host.dll` is committed as a binary because its C source is not currently part of
this repository. It was built with MinGW-w64 GCC 13 targeting 32-bit Windows, and it exports
three functions: `IVX_Init`, `IVX_CreateEnumerator` and `IVX_Shutdown`. If you would rather
not run an unbuildable binary — an entirely reasonable position — the exported interface is
small and documented in [ARCHITECTURE.md](ARCHITECTURE.md), and reimplementing it is a
tractable weekend project. Publishing that source is the main outstanding task for this
repository.
