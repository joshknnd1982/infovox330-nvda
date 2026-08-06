First release of the Infovox 330 synthesizer add-on for NVDA.

Infovox 330 is a Swedish diphone text-to-speech engine from around 2001, made by Telia
Promotor Infovox AB and later absorbed into Acapela Group. It has not been installable on a
normal modern Windows machine for many years. This add-on revives it: the engine runs
entirely from inside the add-on folder, driven by NVDA, with no installation and no changes
to the Windows registry.

## What you get

Sixteen voices across eleven languages: Poul (Danish), Rik (Dutch), Larry and Lucy
(American English), Roger (British English), Matti (Finnish), Pierre (French), Gerhard and
Helga (German), Snorri (Icelandic), Roberto (Italian), Trygve and Vegard (Norwegian), Juan
(Spanish), and AnnMarie and Ingmar (Swedish).

## Requirements

NVDA 2026.1 or later, on 64-bit Windows. Nothing else — you do not need Infovox installed,
and you do not need administrator rights.

## Download size

**The add-on is about 160 MB.** Nearly all of that is voice data: each voice carries its own
recorded diphone database, and a complete sixteen-voice set is simply large. This is
unusually big for an NVDA add-on, so if you are on a metered or slow connection, plan for it.

## Installing

Download `infovox330.nvda-addon` from the Assets section below and open it. NVDA will ask to
confirm, install it, and offer to restart — say yes. Then choose **Infovox 330** under
*NVDA menu → Preferences → Settings → Speech*.

Installation takes a moment while NVDA unpacks 160 MB. It has not hung.

The first voice the engine offers is Poul, the Danish voice, so do not be surprised if your
screen reader starts reading English with a Danish accent before you pick the voice you
actually want.

Full instructions, and what to do when something goes wrong, are in
[docs/INSTALLING.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/docs/INSTALLING.md).

## Verifying your download

A `.sha256` file is attached alongside the add-on. To check the download:

```powershell
Get-FileHash infovox330.nvda-addon -Algorithm SHA256
```

Compare the result with the contents of `infovox330.nvda-addon.sha256`. Worth doing for a
file this size, since a truncated download will otherwise fail in confusing ways at install
time.

## Removing it

*NVDA menu → Tools → Add-on store → Installed add-ons*, select Infovox 330, choose Remove.
Because the add-on never writes to the registry and never places files outside its own
folder, removal is complete — no leftover COM registration, no orphaned keys.

## Notes

The add-on works by intercepting the engine's registry calls in memory and answering them
from a synthetic configuration built out of the voice metadata, which is what lets a 2001
32-bit COM engine run inside 64-bit NVDA without being installed. If that sounds
interesting, [docs/ARCHITECTURE.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/docs/ARCHITECTURE.md)
explains it.

The Infovox engine and its voice data remain the property of their rights holders and are
not covered by this project's licence. See
[NOTICE.md](https://github.com/joshknnd1982/infovox330-nvda/blob/main/NOTICE.md).
