# Legal notices and third-party rights

## License of this repository

The code in this repository is licensed under the **GNU General Public License, version 2
or, at your option, any later version**. The full text is in [COPYING](COPYING).

GPL v2+ is not an arbitrary choice. The synthesizer driver in `addon/synthDrivers32/` and
the SAPI 4 interface definitions in `addon/synthDrivers32/_infovox_sapi4.py` are derived
from NVDA's own `sapi4.py` synthesizer driver, which is copyright:

> Copyright (C) 2006-2026 NV Access Limited, Serotek Corporation, Leonard de Ruijter,
> gexgd0419 and other NVDA contributors

and is distributed under the GNU General Public License as modified by the NVDA license.
Because this add-on is a derivative work of that code, it must be distributed under
compatible terms. See <https://github.com/nvaccess/nvda/blob/master/copying.txt> for NVDA's
license and its additional permissions.

Modifications made for this project include the registry-free engine initialisation path
(`_createEngineEnumerator`), the removal of the registry-based SAPI 4 enumerator, and the
add-on packaging and proxy layer.

## Third-party software NOT distributed here

This repository deliberately contains **no** Infovox engine binaries and **no** voice data.

The Infovox 330 speech engine (`Ivx330nt.dll`, `Sx32w.dll`), its voice databases (`.ddb`),
phone maps (`.phm`), pronunciation rule files (`.ivx`) and associated documentation are
copyrighted works. The rights originated with Telia Promotor Infovox AB and passed through
Babel-Infovox AB to **Acapela Group**, which merged with Babel Technologies and Elan Speech
in 2003 and remains in business today.

`cryput.dll` is part of the CrypKey licensing system used by the engine and is likewise not
distributed here.

To build a working add-on you must supply these files yourself from media you are licensed
to use. [docs/BUILDING.md](docs/BUILDING.md) explains what is needed.

## Please read this before publishing a binary build

The build produced by `tools/build_addon.ps1` embeds the proprietary engine and the complete
voice data inside the `.nvda-addon` file. **Distributing that file publicly is a different
act from publishing this source code, and carries real legal risk.**

Infovox 330 is old, but it is not abandonware in any legal sense. The copyrights did not
lapse — they were transferred to a company that still trades and still sells products under
the Infovox name. Redistributing the engine or the voice data without permission is
copyright infringement regardless of the software's age or commercial availability.

Separately, if the licensing behaviour of the engine has been altered or bypassed in any
way, redistributing the result may also engage anti-circumvention law, including 17 U.S.C.
§ 1201 in the United States and Article 6 of the EU Copyright Directive. That exposure is
independent of, and additional to, the copyright question.

If you want to make builds available to others, the clean path is to ask Acapela Group for
permission. Preservation requests for a twenty-five-year-old discontinued product are not
unreasonable, and rights holders sometimes grant them. Failing that, share the source and
let each person build from their own licensed media — which is the arrangement this
repository is deliberately set up to support.

Nothing in this document is legal advice, and its author is not a lawyer. If you plan to
distribute binaries, talk to someone who is.

## Trademarks

Infovox is a trademark of Acapela Group. NVDA and NonVisual Desktop Access are trademarks of
NV Access Limited. This project is independent and is not affiliated with, endorsed by, or
supported by either organisation.
