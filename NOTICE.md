# Legal notices and third-party rights

## License of this repository

The code in this repository is licensed under the **GNU General Public License, version 2
or, at your option, any later version**. The full text is in [COPYING](COPYING).

GPL v2+ is not an arbitrary choice. The synthesizer driver in
`addon/infovox330/synthDrivers32/` and the SAPI 4 interface definitions in
`addon/infovox330/synthDrivers32/_infovox_sapi4.py` are derived from NVDA's own `sapi4.py`
synthesizer driver, which is copyright:

> Copyright (C) 2006-2026 NV Access Limited, Serotek Corporation, Leonard de Ruijter,
> gexgd0419 and other NVDA contributors

and is distributed under the GNU General Public License as modified by the NVDA license.
Because this add-on is a derivative work of that code, it must be distributed under
compatible terms. See <https://github.com/nvaccess/nvda/blob/master/copying.txt> for NVDA's
license and its additional permissions.

Modifications made for this project include the registry-free engine initialisation path
(`_createEngineEnumerator`), the removal of the registry-based SAPI 4 enumerator, and the
add-on packaging and proxy layer.

The GPL covers **this project's own code only** — the driver, the proxy layer, the build
tooling and the documentation. It does not and cannot cover the third-party material
described in the next section, which is not the author's to license.

## Third-party proprietary material included in this repository

> **This repository previously excluded all proprietary engine and voice files. It no longer
> does.** Earlier revisions of this notice stated that no engine binaries or voice data were
> present. That statement was accurate when written and is no longer accurate. This section
> supersedes it.

The following files are present under `addon/infovox330/synthDrivers32/` and are **not**
covered by the GPL, not owned by the author of this project, and not distributed under any
licence granted by a rights holder:

| Location | Contents |
| --- | --- |
| `Ivx330/Ivx330nt.dll`, `Ivx330/Sx32w.dll` | Infovox 330 speech engine |
| `Ivx330/cryput.dll` | CrypKey licensing/copy-protection component |
| `Voices Ivx330/*.ddb` | Voice databases |
| `Voices Ivx330/*.phm` | Phone maps |
| `Voices Ivx330/*.ivx`, `darules.dll` | Pronunciation rule files |

The rights in this material originated with Telia Promotor Infovox AB and passed through
Babel-Infovox AB to **Acapela Group**, which merged with Babel Technologies and Elan Speech
in 2003 and remains in business today. Infovox is a registered trademark of Acapela Group.

Infovox 330 is old, but it is **not abandonware in any legal sense**. The copyrights did not
lapse. They were transferred to a company that still trades and still sells products under
the Infovox name. Age and commercial unavailability do not create a licence.

## Please read this before using or redistributing this repository

**The presence of these files here does not grant you any right to them.** Cloning this
repository, or installing a build made from it, gives you a copy of copyrighted software
that neither you nor the author is licensed to distribute. If you do not hold your own
licence to Infovox 330, obtaining the engine and voice data this way is copyright
infringement on your part as well as the author's.

Two further points, each independent of the copyright question:

- **Anti-circumvention.** `cryput.dll` is part of the CrypKey copy-protection system. If the
  licensing behaviour of the engine has been altered or bypassed in any way, distributing
  the result may engage 17 U.S.C. § 1201 in the United States and Article 6 of the EU
  Copyright Directive. That exposure is separate from, and additional to, infringement.
- **GPL compatibility.** Shipping non-redistributable binaries alongside GPL-licensed code
  in a single work is in tension with the GPL itself, which requires that the freedoms it
  grants can actually be passed on. The GPL grant above extends to this project's own code;
  it cannot extend to files the author has no right to sublicense.

The clean path remains to ask Acapela Group for permission. Preservation requests for a
twenty-five-year-old discontinued product are not unreasonable, and rights holders sometimes
grant them. Absent that, the defensible arrangement is to publish the source alone and let
each person build from media they are licensed to use — which is what
[docs/BUILDING.md](docs/BUILDING.md) describes, and what `.gitignore` was originally written
to enforce.

If you are a rights holder and want this material removed, please open an issue or contact
the repository owner through GitHub; it will be taken down.

Nothing in this document is legal advice, and its author is not a lawyer. If you plan to
distribute any of this, talk to someone who is.

## Trademarks

Infovox is a trademark of Acapela Group. NVDA and NonVisual Desktop Access are trademarks of
NV Access Limited. This project is independent and is not affiliated with, endorsed by, or
supported by either organisation.
