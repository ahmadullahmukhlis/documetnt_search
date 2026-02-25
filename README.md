# Document Search

Fast, offline document search across folders and drives. Supports PDF, DOC/DOCX, XLS/XLSX, TXT, CSV, and MD.

## Features
- Scan folders or entire system drives (desktop)
- Background indexing for fast search
- File type filters
- Open documents directly

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
