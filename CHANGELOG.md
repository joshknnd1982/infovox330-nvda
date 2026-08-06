# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Repository structure for public distribution: documentation set, GPL v2 license text,
  third-party rights notice, continuous-integration checks, and a `.gitignore` that keeps
  proprietary engine and voice material out of version control.
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

- Add-on manifest now states 11 languages rather than 12, which is the correct count; the
  previous figure double-counted American and British English while listing English once.
- Manifest `url` now points at the project repository.

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
