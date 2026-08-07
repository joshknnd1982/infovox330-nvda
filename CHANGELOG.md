# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-08-07

Housekeeping and documentation. No change to speech output: the only code removed was
unreachable, so the driver behaves identically to 1.0.0.

### Added

- Repository structure for public distribution: documentation set, GPL v2 license text,
  third-party rights notice, continuous-integration checks, and a `.gitignore` covering
  proprietary engine and voice material. Note that the engine binaries and voice databases
  were subsequently committed anyway and the `.gitignore` rules do not apply retroactively
  to tracked files; `NOTICE.md` documents what is present and supersedes any earlier
  statement that the repository held source alone.
- `tools/build_addon.ps1` rewritten to build from the repository tree with user-supplied
  engine and voice folders, rather than from a prepacked kit archive. Takes `-Engine`,
  `-Voices` and `-OutFile` parameters, validates its inputs before doing any work, and
  reports progress during the long voice copy.
- `tools/publish_release.ps1` tags a version, creates the GitHub release and uploads the
  built add-on as a release asset with a SHA-256 checksum file. Refuses to publish an
  archive that is corrupt, missing voice data, missing `manifest.ini` at its root, versioned
  differently from the tag, or built from source other than what is committed. Safe to
  re-run after a failed upload.
- `docs/release-notes-1.0.0.md`, picked up automatically by the publish script.
- **Known limitations** section in `README.md`, covering two things users are likely to
  report as bugs. Audio ducking is unavailable while Infovox 330 is selected, because
  NVDA 2026.1 suspends ducking for every driver hosted in the 32-bit synth host — a
  proxied driver produces audio in its own process, so NVDA cannot duck background audio
  without ducking its own speech. NVDA's own SAPI 4 driver behaves the same way. Separately,
  NVDA's `useWASAPIForSAPI4` advanced setting has no effect here, since this driver always
  requires the WASAPI sink.
- `docs/INSTALLING.md` now states explicitly that the Microsoft SAPI 4 runtime is not
  required. The engine imports no part of it, and the add-on reaches the engine through
  `DllGetClassObject` rather than through COM, so `spchapi.exe` never needs to be run.

### Removed

- **`SynthDriverMMAudio` and `_mmDeviceEndpointIdToWaveOutId`**, inherited from NVDA's
  `sapi4.py` and unreachable since the first build: the driver selects the WASAPI sink
  unconditionally, so nothing ever constructed them. Beyond being dead weight, they were
  the only code in the add-on that called `CoCreateInstance` on a SAPI 4 CLSID, which
  would have introduced a genuine dependency on the SAPI 4 runtime and broken the
  add-on's self-containment had anything ever reached them. Their now-unused imports
  (`CoCreateInstance`, `CLSID_MMAudioDest`, `IAudioMultiMediaDevice`, `winBindings.winmm`,
  `MMSYSERR_NOERROR`, `DriverMessage`, `c_wchar`, `create_string_buffer`, `HANDLE`) went
  with them, along with two imports that were already unused, `winreg` and
  `CLSID_TTSEnumerator`. 145 lines net.

### Fixed

- **Archives built under Windows PowerShell 5.1 used backslash path separators.**
  `ZipFile.CreateFromDirectory` writes the platform separator into entry names, producing
  paths like `synthDrivers32\infovox_host.dll`; the ZIP specification requires forward
  slashes, and spec-following readers cannot locate those entries. The packager now adds
  entries individually with normalised names, and verifies the finished archive before
  reporting success. `publish_release.ps1` accepts either separator so older archives still
  validate, but warns when it sees backslashes.
- `build_addon.ps1` now finds the three engine DLLs across several candidate directories
  rather than requiring all of them in one folder. On machines where Infovox was unpacked
  rather than installed, `cryput.dll` commonly sits a level above the other two, which made
  the build fail over a file that was present all along.

### Changed

- **The CI proprietary-material guard now checks the inventory rather than forbidding it.**
  The old guard failed whenever engine or voice files were tracked, which has been the case
  since they were committed — so it failed on every push, and a check that always fails is a
  check nobody reads. It now compares the tracked set against
  `.github/proprietary-inventory.txt` and fails only when the set changes without
  `NOTICE.md` being updated to match. Committing a built `.nvda-addon` remains a hard error,
  as does exceeding GitHub's 100 MB file limit.
- Fixed a latent bug in that guard while rewriting it: patterns such as `Ivx330nt.dll` were
  passed to `git ls-files` without a wildcard, and a git pathspec with no wildcard anchors at
  the repository root. Those four engine-binary patterns therefore matched nothing, and the
  guard had never once checked for the engine DLLs it was written to catch.
- `README.md` and `docs/INSTALLING.md` no longer describe the repository as holding source
  code alone, which stopped being true when the engine and voice data were committed. Both
  now point at `NOTICE.md` for the full position.
- Add-on manifest now states 11 languages rather than 12, which is the correct count; the
  previous figure double-counted American and British English while listing English once.
- Manifest `url` now points at the project repository. Both this and the language count were
  recorded as done in the 1.0.0 development notes but had never actually been applied to
  `manifest.ini`; they are applied now.
- `lastTestedNVDAVersion` raised to 2026.1.1. `minimumNVDAVersion` stays at 2026.1.0, which
  is the first release providing `_bridge.clients.synthDriverHost32`.

## [1.0.0] - 2026-08-06

First working build.

### Added

- NVDA synthesizer driver for the Infovox 330 diphone engine, supporting all 16 voices
  across 11 languages.
- Registry-free engine initialisation via `infovox_host.dll`, which hooks the engine's
  import address table and serves a synthetic registry built from `VoiceDescriptions.txt`.
  The add-on makes no changes to the Windows registry and requires no administrator rights.
- 64-bit proxy driver built on NVDA's bundled 32-bit synthesizer host, allowing the 32-bit
  SAPI 4 engine to be driven from 64-bit NVDA.
- Vendored SAPI 4 COM interface definitions so the driver does not depend on NVDA internals
  remaining stable.
