# SevenZipExtractor

SevenZipExtractor is a native macOS archive extractor built around the official 7-Zip `7zz` binary. It is designed for the simple double-click flow: open an archive in Finder, extract it immediately, and keep archive handling lightweight.

## What it does

- Opens archives directly from Finder or via `open`
- Extracts with bundled `7zz`, so no Homebrew or external 7-Zip install is required
- Supports common formats including 7z, zip, rar, tar, gz, bz2, xz, tgz, and tar.gz
- Shows native macOS prompts for passwords, destination selection, and extraction errors
- Includes a Settings window for archive bindings and extraction preferences

## Current release scope

This repository currently targets a GitHub-only unsigned macOS release.

That means:
- the app is packaged and ready to download from GitHub Releases
- the app is not notarized yet
- macOS Gatekeeper may require users to right-click and choose Open on first launch

## Requirements

- macOS
- Xcode for local development and testing

## Project structure

- `SevenZipExtractor/` — app source
- `SevenZipExtractorTests/` — unit, integration, and smoke tests
- `scripts/package-unsigned.sh` — unsigned release packaging script
- `build/` — local build outputs

## Local development

Run the full test suite (paths are relative to the repo root):

```bash
xcodebuild test \
  -project "SevenZipExtractor.xcodeproj" \
  -scheme "SevenZipExtractor" \
  -destination "platform=macOS"
```

Build an unsigned release package:

```bash
bash scripts/package-unsigned.sh
```

The script derives the project root from its own location, so it can run from any checkout. Output lands in:

```text
build/SevenZipExtractor-unsigned-macos.zip
```

## Verified status

Before preparing release, the following checks passed locally:

- full test suite: 40 tests, 0 failures
- bundled `7zz` backend integration test
- packaged app zip structure validation
- automated end-to-end smoke test that opened a real archive with the built `.app` and verified extracted file output

## Limitations

The published releases (v1.0.0, v2.0.0) are intentionally narrow in scope:

- no archive browsing UI
- no notarization or code signing workflow yet
- GUI interaction polish still relies on manual product review even though automated coverage is in place

## License

This project is licensed under the GNU General Public License v3.0 — see the [LICENSE](LICENSE) file for details.
