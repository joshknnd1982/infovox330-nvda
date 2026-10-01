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
| **License** | MIT — see [LICENSE](LICENSE); the NVDA-derived driver files stay GPL v2 or later, see [NOTICE.md](NOTICE.md) |

## What this repository contains

> **Read [NOTICE.md](NOTICE.md) before cloning.** Alongside this project's own code, this
> repository contains the Infovox 330 engine binaries and the complete voice databases.
> That material is **not** covered by the MIT License or the GPL, is not the author's to
> license, and remains the copyrighted property of Acapela Group (formerly Babel-Infovox AB /
> Telia Promotor Infovox AB). Cloning gives you a copy of software neither you nor the author
> is licensed to distribute. NOTICE.md sets out exactly which files these are and what that
> means for you.

The MIT License covers the registry-virtualisation shim, the build tooling and the
documentation. The driver files (the 32-bit driver, its SAPI 4 interface definitions and the
64-bit proxy) stay under the GNU General Public License, because the driver is derived from
NVDA's own `sapi4.py`; [NOTICE.md](NOTICE.md) lists them.

If you hold your own Infovox 330 licence and would rather build from your own media,
[docs/BUILDING.md](docs/BUILDING.md) describes that route; the build script assembles an
add-on from an engine folder and a voices folder you supply.

## Installing a release

If you already have a built `infovox330.nvda-addon` file — either from the
[Releases page](https://github.com/joshknnd1982/infovox330-nvda/releases) or from your own
build — the short version is: open the file, let NVDA install it and restart, then choose
**Infovox 330** under *NVDA menu → Preferences → Settings → Speech*.

The long version, including troubleshooting, is in [docs/INSTALLING.md](docs/INSTALLING.md).

## Known limitations

**Audio ducking is unavailable while Infovox 330 is the active synthesizer.** The
combo box in *NVDA menu → Preferences → Settings → Audio* disappears, and the ducking
gesture stops responding. This is intended NVDA behaviour rather than an add-on defect.
NVDA 2026.1 suspends audio ducking for every synthesizer that runs in the 32-bit synth
host, because such a driver produces audio in its own process and NVDA cannot duck
external audio without also ducking its own speech. NVDA's own SAPI 4 and 32-bit SAPI 5
drivers are affected identically. Selecting any in-process synthesizer, such as eSpeak
NG, restores the setting. See [nvaccess/nvda#19432](https://github.com/nvaccess/nvda/pull/19432).

**The `useWASAPIForSAPI4` advanced setting has no effect on this add-on.** NVDA offers a
switch to route SAPI 4 audio through WinMM instead of WASAPI. Infovox 330 always uses the
WASAPI sink, because the engine only sets its native 16 kHz format when the sink reports
no format of its own, which the WinMM path does not do. Toggling the setting changes
nothing here.

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
