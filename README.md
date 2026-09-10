# Studee PC — Study Overlay App

Personal desktop study assistant (macOS & Windows) that runs as an overlay above other apps. Organize knowledge by subject, import exam material (text, image, screenshot, PDF), and solve questions using local knowledge plus DeepSeek.

**Primary language:** Vietnamese (`vi`).

## Features

- Isolated subjects (UUID folders + per-subject SQLite)
- Import: paste text, image, screen region, PDF (PDFium text layer or PaddleOCR-VL)
- Grounded solver with fingerprint matching, FTS5, answer precedence, reordered-choice protection
- Always-on-top overlay (compact / expanded)
- Settings: DeepSeek API key only (OS credential store). Local OCR models are **bundled** — users do not download models or paste Hugging Face tokens.
- Subject backup: **Xuất ZIP** / **Nhập từ ZIP** on the subjects list

## Stack

| Area | Choice |
| --- | --- |
| UI | Flutter Material 3, Riverpod, GoRouter |
| DB | SQLite + Drift, FTS5 unicode61 |
| OCR | PaddleOCR-VL 1.6 via JSONL worker (`ocr_worker/`) |
| PDF | PDFium (`pypdfium2`) |
| AI | DeepSeek API (strict JSON + local validation) |
| Secrets | macOS Keychain / Windows Credential Manager |

## Architecture

```
lib/
  app/          # shell, theme, router, DI
  core/         # result, errors, logging, utils
  domain/       # entities, enums, services, repository interfaces
  data/         # Drift DBs, DeepSeek, file storage, repos
  features/     # subjects, ingestion, solver, overlay, history, settings
  platform/     # desktop + OCR worker client
ocr_worker/     # Python child process (JSONL stdin/stdout)
```

Widgets never call SQLite, DeepSeek, OCR, or native window APIs directly.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after Drift schema changes
flutter test
flutter run -d macos
# or
flutter run -d windows
```

### DeepSeek / Mathpix API keys

Open **Cài đặt** and paste your DeepSeek (and Mathpix, if using image OCR) keys. Connection tests send no study content.

### Windows notes

- Use **Visual Studio** with the “Desktop development with C++” workload.
- First run: `flutter config --enable-windows-desktop` then `flutter run -d windows`.
- Camera / screen capture use Windows Privacy settings when prompted.
- Study data lives under AppData; API keys use Windows Credential Manager.
- Portable ZIP packaging (on a Windows machine or via GitHub Actions):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1
# Output: dist/Studee-<version>-windows.zip
```

Reuse an existing release build: `$env:SKIP_BUILD=1; .\scripts\package_windows.ps1`

Uninstall data + Credential Manager entries:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall_windows.ps1
```

CI builds Windows artifacts on every `main` push (see `.github/workflows/windows.yml`).

### OCR worker (development)

```bash
cd ocr_worker
./setup_real_ocr.sh
./warmup_models.sh
./run.sh   # or let the Flutter app spawn it
```

Development uses a labeled **mock** OCR engine when real PaddleOCR-VL weights are not present. Release DMGs embed a standalone Python + models under `Contents/Resources/ocr_runtime/` (no user Python install).

### macOS permissions

- **Screen Recording** — region capture (user-initiated only)
- **User-selected files** — import/export via file picker

Debug (`flutter run`) uses bundle id `com.studee.studeePc.debug` and display
name **Studee (Debug)**. The packaged DMG app uses `com.studee.studeePc` /
**Studee**. Each has its own Screen Recording permission.

If System Settings shows Screen Recording **on** but the app still asks / cannot
capture (common with ad-hoc DMG reinstalls), reset and re-grant:

```bash
./scripts/reset_screen_capture_permission.sh
```

Or in the app: **Cài đặt → Đặt lại quyền Ghi màn hình**, then quit Studee fully
(Dock → Quit), reopen `/Applications/Studee.app`, allow when prompted, quit and
reopen once more.


## Tests

```bash
flutter test
```

Covers Vietnamese normalization/diacritics, fingerprints, reordered-choice mapping, answer precedence, confidence, evidence packages, response validation, path safety, and subject isolation.

## Package macOS DMG

Requires a prepared OCR bundle (one-time / when models change):

```bash
./scripts/prepare_ocr_bundle.sh
./scripts/package_macos_dmg.sh
# Output: dist/Studee-<version>-macos.dmg
```

Reuse an existing Flutter release build: `SKIP_BUILD=1 ./scripts/package_macos_dmg.sh`  
Slim DMG without embedded OCR: `SKIP_OCR_BUNDLE=1 ./scripts/package_macos_dmg.sh`

Recipients: drag **Studee.app** to Applications, then **right-click → Open** (ad-hoc signed; no Apple Developer ID). The DMG also includes `HOW_TO_INSTALL.txt`, `HOW_TO_UNINSTALL.txt`, and `uninstall_macos.sh`.

## Uninstall (macOS)

Complete removal (app, study data, prefs, Keychain API key, OCR caches):

```bash
# From the DMG volume:
./uninstall_macos.sh

# Or after install:
/Applications/Studee.app/Contents/Resources/uninstall_macos.sh

# From this repo (also clears build/ocr_bundle + dist):
./scripts/uninstall_macos.sh
```

Pass `--yes` to skip the confirmation prompt. See `HOW_TO_UNINSTALL.txt` on the DMG.

## Package Windows ZIP

On a Windows machine (or via GitHub Actions `Windows` workflow):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1
# Output: dist/Studee-<version>-windows.zip
```

The ZIP includes `studee_pc.exe`, Flutter runtime files, `HOW_TO_INSTALL.txt`,
`HOW_TO_UNINSTALL.txt`, and `uninstall_windows.ps1`.

## Uninstall (Windows)

```powershell
# From the extracted ZIP folder or repo:
powershell -ExecutionPolicy Bypass -File .\uninstall_windows.ps1
# or
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall_windows.ps1
```

Pass `-Yes` to skip the confirmation prompt.

Note: macOS may leave a tiny `~/Library/Containers/com.studee.studeePc` metadata
folder unless Terminal has **Full Disk Access** — that leftover is harmless.

## Out of scope

Auth/cloud sync, collaboration, mobile, auto-update, vector DB, handwriting OCR, user-managed model downloads.
