# What Infovox 330 is, and who made it

## The short version

Infovox 330 is a multilingual text-to-speech synthesizer for Windows, released around 2001
by **Telia Promotor Infovox AB** of Solna, Sweden. It speaks 16 voices across 11 languages
using diphone concatenation, and it talks to applications through Microsoft's SAPI 4 speech
interface. The company that made it was absorbed into **Acapela Group** in 2003, and the
Infovox brand is still in use by Acapela today for entirely different, modern products.

This add-on is a preservation project. It takes the original 32-bit engine — which has not
been installable on a normal modern Windows machine for many years — and gets it speaking
again inside NVDA.

## The longer version

### Origins at KTH

Infovox did not begin life as a product. It grew out of decades of speech research at the
Royal Institute of Technology (KTH) in Stockholm, at what is now the Department of Speech,
Music and Hearing. That department is the intellectual home of Gunnar Fant, whose work on
the acoustic theory of speech production underpins essentially all formant synthesis, and
of Rolf Carlson and Björn Granström, who through the 1970s and 1980s built a multilingual
text-to-speech system explicitly designed so that the same synthesis machinery could be
retargeted to new languages by swapping the linguistic rule set rather than rewriting the
engine.

That design choice is why a small Swedish product ended up shipping Icelandic and Dutch and
Italian voices. The multilingual structure was in the architecture from the beginning, not
bolted on later.

### Commercialisation

The research system was commercialised under the Infovox name and sold through a division
of the Swedish telecommunications company Telia, trading as Telia Promotor Infovox AB. The
original documentation on the Infovox 330 CD reflects this directly: the default
installation directory is `C:\Program Files\Telia Promotor\Ivx330`, support enquiries go to
`sales@infovox.se`, and the manual points users at `http://www.infovox.se`.

The company was later restructured as Babel-Infovox AB, and the Infovox 330 engine records
its configuration under the registry key `HKLM\SOFTWARE\Babel-Infovox AB\Infovox 330` — a
naming detail that turns out to matter quite a lot to this add-on, since the shim has to
reproduce exactly that key layout in memory.

Infovox was strongly oriented toward the blind and low-vision community. In Sweden and the
wider Nordic region it was for years *the* screen-reader voice, in much the way that
DECtalk and Eloquence were in English-speaking countries. For a lot of people who used
computers non-visually in the 1990s and 2000s, this is the voice their computer had.

### Two generations: 230 and 330

The Infovox line shipped in two overlapping generations, and the distinction explains what
this add-on actually sounds like.

The **Infovox 230** was a formant synthesizer. It generated speech by modelling the
resonances of the vocal tract mathematically — no recorded human audio at all. Formant
synthesis is compact, endlessly tunable, and extremely intelligible at high speaking rates,
which is exactly why screen-reader users liked it, but it sounds unmistakably synthetic.

The **Infovox 330** moved to **diphone concatenation**. A diphone is the slice of audio
running from the middle of one phone to the middle of the next, so it captures the
transition between two sounds — the hardest part to synthesise convincingly — as a single
recorded unit. The engine stitches these recorded fragments together and adjusts their
pitch and duration to fit the requested prosody. The result is noticeably more natural than
the 230, still clearly a synthesizer, and far more compact than the unit-selection and
neural systems that came afterward.

This is what the large `.ddb` files in a voice folder are: the diphone databases. A single
voice can run anywhere from about 5 MB to over 20 MB, which is why a complete 16-voice
installation comes to roughly 250 MB. Alongside each database sits a `.phm` phone-mapping
file and a language-wide `.ivx` rule file holding the text-to-phoneme rules for that
language.

### Into Acapela

In 2003 three European speech-technology companies merged to form **Acapela Group**: Babel
Technologies of Belgium, Elan Speech of France, and Infovox of Sweden. Acapela still trades
today and still uses the Infovox name for assistive-technology products — Infovox iVox for
macOS, and the Infovox4 range — though these are entirely modern voices with no code
relationship to the 2001 engine revived here.

The practical upshot for this project is that **Infovox 330 is not abandonware in the legal
sense**. The rights did not lapse; they were transferred, and the successor company is
still in business. That is why this repository ships the driver code but not the engine or
the voices.

## The voices

| Voice | Language | Gender | Diphone database |
|---|---|---|---|
| Poul | Danish | Male | `DA01.DDB` |
| Rik | Dutch | Male | `DU00.DDB` |
| Larry | English (American) | Male | `AM00.DDB` |
| Lucy | English (American) | Female | `AM01.DDB` |
| Roger | English (British) | Male | `BR00.DDB` |
| Matti | Finnish | Male | `FI00.DDB` |
| Pierre | French | Male | `FR00.DDB` |
| Gerhard | German | Male | `GE01.DDB` |
| Helga | German | Female | `GE00.DDB` |
| Snorri | Icelandic | Male | `IC00.DDB` |
| Roberto | Italian | Male | `IT00.DDB` |
| Trygve | Norwegian | Male | `NO01.DDB` |
| Vegard | Norwegian | Male | `NO00.DDB` |
| Juan | Spanish | Male | `SP00.DDB` |
| AnnMarie | Swedish | Female | `SW00.DDB` |
| Ingmar | Swedish | Male | `SW01.DDB` |

Sixteen voices across eleven languages, or twelve locales if you count American and British
English separately. Each voice is identified to SAPI 4 by a mode GUID, listed in
`VoiceDescriptions.txt` in the voice folder; the host shim reads that file to build the
synthetic registry the engine expects.

Icelandic is worth singling out. Icelandic has always been an underserved language in
speech technology, and Snorri was for a long stretch one of very few options available to
Icelandic screen-reader users. A voice like that has real preservation value beyond
nostalgia.

## Who made this add-on

The NVDA add-on — the driver, the registry-virtualisation host, the build tooling — is by
Josh (joshknnd1982@gmail.com). The driver is derived from NVDA's own SAPI 4 synthesizer,
which is copyright NV Access Limited, Serotek Corporation, Leonard de Ruijter, gexgd0419
and other contributors, and is used under the GNU General Public License.

Nothing about this add-on is a product of, endorsed by, or supported by Acapela Group.

## Sources

- [Acapela Group company timeline](https://www.acapela-group.com/about-us/company-timeline/) — 2003 merger of Babel Technologies, Elan Speech and Infovox
- [Summary of Speech Synthesis Products (Helsinki University of Technology)](http://piisami.net/dippa/appb.html) — Telia Promotor Infovox AB, Solna; Infovox 230 as formant synthesis, 330 as diphone concatenation
- [Infovox iVox, Acapela Group](https://www.acapela-group.com/infovox-ivox/) — continued use of the Infovox brand
- *Getting Started with the Infovox 230/330 v2.2*, Telia Promotor Infovox AB, February 2002 — included on the original distribution media
