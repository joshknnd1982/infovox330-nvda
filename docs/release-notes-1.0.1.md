A housekeeping release. **Speech output is unchanged from 1.0.0** — the only code removed
was unreachable, so the driver behaves exactly as before. If 1.0.0 is working for you, there
is no urgency in updating.

The reason to read on is the first item: a change in NVDA 2026.1 that people will otherwise
report as a bug in this add-on.

## Audio ducking does not work while Infovox 330 is selected

If you open *NVDA menu → Preferences → Settings → Audio*, the **Audio ducking mode** combo
box is missing, and the ducking gesture does nothing. This is expected, it is not a fault in
this add-on, and there is nothing to fix on your machine.

NVDA 2026.1 suspends audio ducking for every synthesizer that runs in NVDA's 32-bit
synthesizer host. Such a driver produces its audio in a separate process, and NVDA cannot
quieten background audio without also quietening its own speech — so rather than duck
itself, it turns the feature off while that driver is loaded. NVDA's own SAPI 4 and 32-bit
SAPI 5 drivers behave identically. Infovox 330 is a SAPI 4 engine and runs in that host, so
it is affected too.

Selecting any in-process synthesizer, such as eSpeak NG, brings the setting straight back.

The relevant NVDA change is [nvaccess/nvda#19432](https://github.com/nvaccess/nvda/pull/19432).

## You do not need the Microsoft SAPI 4 runtime

This comes up because Infovox 330 is a SAPI 4 engine, and the original Infovox media ships
`spchapi.exe` to install that runtime. You do not need to run it.

The engine links against no part of the SAPI 4 runtime, and the add-on never asks COM for a
SAPI 4 object — it loads the engine directly and implements the audio interfaces itself. A
plain 64-bit Windows install with NVDA 2026.1 is the whole requirement.

## Everything else

- Removed about 145 lines of unreachable code inherited from NVDA's own SAPI 4 driver: a
  WinMM audio path that this driver never selects, because the Infovox engine requires the
  WASAPI one.
- NVDA's `useWASAPIForSAPI4` advanced setting has no effect on this add-on, which always
  uses the WASAPI audio sink. Documented rather than changed — the engine only sets its
  native 16 kHz format when the audio sink reports no format of its own, which the WinMM
  path does not do.
- Corrected the add-on description, which claimed 12 languages while listing 11. Eleven is
  right; the old figure counted American and British English separately in the total but not
  in the list.
- The add-on now declares a project URL, and records NVDA 2026.1.1 as the version it was
  last tested against.
- Documentation corrections, including an accurate statement of what this repository
  contains. See [NOTICE.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/NOTICE.md).

## What you get

Unchanged from 1.0.0: sixteen voices across eleven languages — Poul (Danish), Rik (Dutch),
Larry and Lucy (American English), Roger (British English), Matti (Finnish), Pierre (French),
Gerhard and Helga (German), Snorri (Icelandic), Roberto (Italian), Trygve and Vegard
(Norwegian), Juan (Spanish), and AnnMarie and Ingmar (Swedish).

## Requirements

NVDA 2026.1 or later, on 64-bit Windows. Nothing else — no Infovox installation, no
administrator rights, no SAPI 4 runtime.

## Download size

**The add-on is about 160 MB.** Nearly all of that is voice data: each voice carries its own
recorded diphone database, and a complete sixteen-voice set is simply large. If you are on a
metered or slow connection, plan for it.

## Installing

Download `infovox330.nvda-addon` from the Assets section below and open it. NVDA will ask to
confirm, install it, and offer to restart — say yes. Then choose **Infovox 330** under
*NVDA menu → Preferences → Settings → Speech*.

Installation takes a moment while NVDA unpacks 160 MB. It has not hung.

Upgrading from 1.0.0 works the same way; NVDA replaces the installed copy.

Full instructions, and what to do when something goes wrong, are in
[docs/INSTALLING.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/docs/INSTALLING.md).

## Verifying your download

A `.sha256` file is attached alongside the add-on:

```powershell
Get-FileHash infovox330.nvda-addon -Algorithm SHA256
```

Compare the result with the contents of `infovox330.nvda-addon.sha256`. Worth doing for a
file this size, since a truncated download otherwise fails in confusing ways at install time.

## Removing it

*NVDA menu → Tools → Add-on store → Installed add-ons*, select Infovox 330, choose Remove.
Because the add-on never writes to the registry and never places files outside its own
folder, removal is complete.

## Notes

The Infovox engine and its voice data remain the property of their rights holders and are not
covered by this project's licence. See
[NOTICE.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/NOTICE.md).
