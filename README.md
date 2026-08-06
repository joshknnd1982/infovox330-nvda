# Infovox 330 for NVDA

An [NVDA](https://www.nvaccess.org/) synthesizer add-on that revives the **Infovox 330**
diphone text-to-speech engine — a Swedish synthesizer from around 2001 — and runs it on
modern 64-bit Windows without installing anything into the Windows registry.

The add-on carries a small registry-virtualisation shim that lets the original 32-bit
Infovox engine run entirely out of the add-on's own folder. Nothing is registered,
nothing is written to `HKLM`, and removing the add-on removes every trace of it.

| | |
|---|---|
| **Voices** | 16 |
| **Languages** | 11 (Danish, Dutch, English, Finnish, French, German, Icelandic, Italian, Norwegian, Spanish, Swedish) |
| **Engine** | Infovox 330, diphone concatenation, 32-bit SAPI 4 |
| **Requires** | NVDA 2026.1 or later, 64-bit Windows |
| **License** | GPL v2 or later — see [COPYING](COPYING) and [NOTICE.md](NOTICE.md) |

## What this repository contains

This repository holds **the add-on's source code only**. It does not contain the Infovox
speech engine or the voice databases, because those remain the copyrighted property of
Acapela Group (formerly Babel-Infovox AB / Telia Promotor Infovox AB). To produce a
working add-on you supply those files yourself from your own Infovox 330 media, and the
build script assembles them together with the code here.

See [docs/BUILDING.md](docs/BUILDING.md) for the full procedure.

## Installing a release

If you already have a built `infovox330.nvda-addon` file — either from the
[Releases page](https://github.com/joshknnd1982/infovox330-nvda/releases) or from your own
build — the short version is: open the file, let NVDA install it and restart, then choose
**Infovox 330** under *NVDA menu → Preferences → Settings → Speech*.

The long version, including troubleshooting, is in [docs/INSTALLING.md](docs/INSTALLING.md).

## Background

Infovox traces back to multilingual speech-synthesis research at KTH in Stockholm and was
sold commercially through Telia Promotor Infovox AB. The line survives today inside Acapela
Group. [docs/ABOUT.md](docs/ABOUT.md) tells that story properly and explains where this
particular engine sits in it.

## How it works

The interesting part of this project is the registry-virtualisation shim, which intercepts
the engine's registry calls in memory and answers them from a synthetic voice configuration
built out of `VoiceDescriptions.txt`. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains
the design.

## Repository layout

```
addon/                    add-on source tree, zipped into the .nvda-addon
  manifest.ini            NVDA add-on manifest
  synthDrivers/           64-bit proxy driver loaded by NVDA itself
  synthDrivers32/         32-bit driver, SAPI 4 interface definitions, host shim
docs/                     documentation
tools/                    build and diagnostic scripts
```

## Credits

The NVDA driver code is derived from NVDA's own `sapi4.py` synthesizer, copyright
NV Access Limited and contributors, used under the GNU General Public License. The Infovox
engine and its voice data are the property of their respective rights holders and are not
distributed here.
