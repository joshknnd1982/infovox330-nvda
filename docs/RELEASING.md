# Cutting a release

Read [NOTICE.md](../NOTICE.md) before attaching a built add-on to a public release. The
built file embeds the proprietary Infovox engine and the complete voice data, and publishing
it is a materially different decision from publishing this source code.

## Why the add-on goes in Releases rather than the repository

GitHub refuses any file over 100 MB inside a repository. Release assets may be up to 2 GB.
The built add-on is around 160 MB, essentially all of it voice data, so Releases is the only
place on GitHub it can live. This is why cloning the repository does not give you a usable
add-on, and why the install instructions send people to the Releases page.

## The short version

```powershell
# 1. build, so the asset matches the source you are about to tag
pwsh -File tools\build_addon.ps1 -Engine "..\Ivx330" -Voices "..\Voices Ivx330"

# 2. tag, create the release, upload the asset and its checksum
pwsh -File tools\publish_release.ps1 -Addon .\dist\infovox330.nvda-addon
```

`publish_release.ps1` takes the version from `addon/manifest.ini` unless you pass
`-Version`. It is safe to re-run: an existing tag or release is reused rather than
duplicated, and assets are replaced rather than rejected, so a failed 160 MB upload is
recovered by simply running it again.

## What the script checks before it publishes anything

The checks exist because a release is hard to un-publish, and because the failure modes here
are quiet ones — an add-on that installs perfectly and then never speaks looks identical, at
install time, to one that works.

It confirms the archive is a readable ZIP with `manifest.ini` at the root, since NVDA
rejects anything else. It confirms voice data is actually present, because an add-on built
without the `Voices Ivx330` folder installs happily and produces silence. It confirms the
version inside the shipped manifest matches the tag you are creating, so the asset cannot
disagree with its own release. It compares the driver, the manifest and the host shim inside
the archive against the committed source, and warns you if they differ — which is what
happens when you tag after editing but forget to rebuild. And it refuses to tag a dirty
working tree, because a tag should point at a commit that reflects what you released.

Every one of those stops the script rather than warning and continuing, except the staleness
check, which asks. Pass `-Yes` to answer it in advance, or `-SkipDirtyCheck` to override the
working-tree check when you have a reason.

## Useful switches

`-Draft` creates the release as a draft, so nobody can see it until you publish it from the
release page. This is the low-risk way to test the whole pipeline, including a real upload,
without making anything public.

`-PreRelease` marks it as a pre-release, which keeps it off the repository's headline
"Latest release" slot.

`-NotesFile <path>` supplies release notes. If you omit it the script looks for
`docs/release-notes-<version>.md` and falls back to GitHub's generated notes if that is
missing too.

## Preparing a version

Keep three things in step: `version` in `addon/manifest.ini`, the heading in
`CHANGELOG.md`, and the tag. Move the `Unreleased` entries under the new version heading and
date them. Write `docs/release-notes-<version>.md` — the script picks it up automatically,
and it is the text most people will actually read.

Then build and **test before tagging, not after**. Install the built add-on into a real NVDA,
select the synthesizer, and listen to at least one voice per language. The failure where an
engine enumerates a voice successfully and then produces silence is common enough with
material this old to be worth checking properly every time.

## Verifying after upload

The script computes a SHA-256 of the add-on, writes it to a `.sha256` file and uploads both.
Confirm the round trip before telling anyone the release exists:

```powershell
gh release download v1.0.0 --repo joshknnd1982/infovox330-nvda `
    --pattern '*.nvda-addon' --dir $env:TEMP --clobber
Get-FileHash $env:TEMP\infovox330.nvda-addon -Algorithm SHA256
```

`--repo` matters here. `gh` works out which repository you mean from the current folder's
git remote, so without it the command fails with `not a git repository` anywhere outside a
clone — which is exactly where you tend to be when spot-checking a download. Inside the
repository you can drop the switch.

A 160 MB upload that silently truncated is worth ruling out.

## What release notes should say

Four things, before anyone commits to the download: which NVDA versions it works with, which
voices are included, **the file size**, and where to go when it does not speak. Link
[INSTALLING.md](INSTALLING.md) for the last of these rather than repeating it.

State the size explicitly. Many users of this add-on are on metered or slow connections, and
an unannounced 160 MB download is a poor first impression.

## Doing it by hand

If you would rather not use the script:

```powershell
git tag -a v1.0.0 -m "Infovox 330 for NVDA 1.0.0"
git push origin v1.0.0

gh release create v1.0.0 --title "Infovox 330 for NVDA 1.0.0" `
    --notes-file docs\release-notes-1.0.0.md

gh release upload v1.0.0 dist\infovox330.nvda-addon
```

The upload takes several minutes and `gh` prints no progress, so do not assume it has
stalled. If it fails partway, `gh release upload --clobber` replaces the partial asset.
