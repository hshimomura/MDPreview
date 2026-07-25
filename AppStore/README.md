# Public App Store metadata

This directory contains only information suitable for a public open-source
repository. App Store Connect is the source of truth for review workflow and
submission state.

## Public app record

- Name: `MD Viewer: Reading Window`
- Installed name: `MD Viewer`
- Bundle ID: `io.github.hshimomura.MDViewer`
- Platform: macOS
- Primary category: Productivity
- Price: Free
- Version: `1.0`
- Build: `13`
- Copyright: `2026 Hideaki Shimomura`
- Support URL: `https://hshimomura.github.io/MDPreview/support`
- Marketing URL: `https://hshimomura.github.io/MDPreview/`
- Privacy Policy URL: `https://hshimomura.github.io/MDPreview/privacy`

## Tracked public material

- English (U.S.) product-page text in `metadata/en-US`
- Japanese product-page text in `metadata/ja`
- Screenshot requirements in `Screenshots/README.md`
- Reproducible source and build checks in `release-checklist.md`

The screenshot image files themselves are ignored by Git. Store media must use
only the bundled public `Sample.md` and must not contain private documents.

## Privacy and export compliance

The app does not collect data or perform tracking. Documents and bundled
Mermaid rendering remain local. `ITSAppUsesNonExemptEncryption` is `false`
because the app does not implement or ship encryption beyond Apple system
frameworks.

## Repository policy

Do not commit App Store review status, submission dates or identifiers,
reviewer contact details, review notes, agreement status, trader declarations,
certificate identities, provisioning profiles, or screenshots containing
non-public documents.

Local operational records belong under `AppStore/private/`, which is ignored
by Git.

## Validation

Validate both localizations against App Store Connect character limits after
making changes:

```sh
./Scripts/verify-app-store-metadata.sh
```
