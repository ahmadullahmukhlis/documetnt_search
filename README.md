# Document Search

Fast, offline document search across folders and drives. Supports PDF, DOC/DOCX, XLS/XLSX, TXT, CSV, and MD.

## Features
- Scan folders or entire system drives (desktop)
- Background indexing for fast search
- File type filters
- Open documents directly

## Cross-Platform Setup (Recommended)
Use the official Flutter SDK on all OS (not Snap) to avoid toolchain/linker issues.

1. Install Flutter stable from:
   - https://docs.flutter.dev/get-started/install
2. Enable desktop targets:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```
3. In this project:
```bash
flutter clean
flutter pub get
```

## Build Release By OS

### Linux
Install required build tools:
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```
Build:
```bash
flutter build linux --release
```

### macOS
Requirements:
- Xcode + command line tools

Build:
```bash
flutter build macos --release
```

### Windows
Requirements:
- Visual Studio 2022 with "Desktop development with C++"

Build:
```powershell
flutter build windows --release
```

## Snap Flutter Linux Error (`ld.lld` / `ld` not found)
If you installed Flutter via Snap and see:
`Failed to find any of [ld.lld, ld] in ... /snap/flutter/.../llvm-10/bin`

Fix:
1. Remove Snap Flutter:
```bash
sudo snap remove flutter
```
2. Install official Flutter SDK (git/archive), add it to `PATH`, then run:
```bash
flutter doctor
flutter clean
flutter pub get
flutter build linux --release
```

## Build Windows Installer (MSIX)
The GitHub Action builds a Windows MSIX installer and also exports a self‑signed test certificate.

### Install on Windows (Test Certificate)
If you use the self‑signed certificate, Windows will warn that the publisher is unknown until you install the certificate.

Steps on the target PC:
1. Download the artifact from GitHub Actions.
2. Double‑click `github_actions_cert.cer`.
3. Click **Install Certificate**.
4. Choose **Local Machine**.
5. Select **Place all certificates in the following store**.
6. Install into:
   - **Trusted Root Certification Authorities**
   - **Trusted People**
7. Install the `.msix` file.

For production distribution, use a real code‑signing certificate so Windows verifies the publisher.
