# MD Viewer: Reading Window

MD Viewer is a small, read-only Markdown viewer for macOS 26. Its document UI
is native SwiftUI: there is no editor, Electron runtime, database, account, or
network service. A restricted local WebKit view is used only for Mermaid
diagrams.

The detailed architecture and roadmap are in [DESIGN.md](DESIGN.md).

## MVP architecture

```text
Finder / File > Open
        |
        v
SwiftUI DocumentGroup(viewing:)
        |
        v
PreviewDocumentModel (UTF-8 + live file monitoring)
        |
        v
Heading / Markdown / Mermaid block parser
        |
        +-- Textual StructuredText (native Markdown)
        |
        +-- bundled Mermaid runtime (offline diagram)
```

- `DocumentGroup(viewing:)` provides read-only document lifecycle and
  multiwindow behavior.
- `net.daringfireball.markdown` registers `.md` and `.markdown` with a
  `Viewer` role and `Alternate` handler rank.
- Textual 0.5.0 renders structured Markdown with native SwiftUI views.
- Mermaid 11.15.0 is bundled locally; diagrams require no installation or CDN.
- Swift Package Manager pins the dependency graph in `Package.resolved`.
- The app targets macOS 26 and currently builds an Apple-silicon binary.

## Requirements

- macOS 26
- Xcode 26
- Swift 6.2 or newer
- Network access for the first Swift Package Manager dependency resolution

## Xcode build

```sh
brew install xcodegen
./Scripts/generate-xcode-project.sh
open MDViewer.xcodeproj
```

The generated `MDViewer.xcodeproj` contains the macOS app and unit-test targets.
The App Store scheme uses bundle identifier `io.github.hshimomura.MDViewer`,
App Sandbox, hardened runtime, privacy manifest, and version 1.0 (build 11).

For a command-line local build:

```sh
./Scripts/build-app.sh
./Scripts/verify-app.sh
```

The local app bundle is generated at `dist/MDPreview.app`. Open the sample:

```sh
./Scripts/launch-local-app.sh
```

Pass one or more Markdown paths to open specific documents:

```sh
./Scripts/launch-local-app.sh README.md Sample.md
```

Use the script (or Finder / `open`) for GUI smoke tests. Do not execute
`dist/MDPreview.app/Contents/MacOS/MDPreview` directly from an automation
process; that bypasses normal LaunchServices application registration.

The script build uses ad-hoc signing for local testing. Mac App Store archives
must be created from the Xcode project with an Apple Distribution certificate.

## MVP scope

Included:

- Finder and Open-menu handling for `.md` and `.markdown`
- Multiple read-only document windows, multi-file Open, and side-by-side
  window arrangement
- GitHub-like native rendering
- Tables, lists, code blocks, links, and selectable text
- HTML-style `<br>`, `<br/>`, and `<br />` line breaks, including table cells
- `Command-W` closes the active document window
- The last document-window size is restored across launches
- Native macOS icon built from the `Reading Window` master artwork
- Live reload after saves from external editors, including atomic replacements
- Left-side chapter outline with the current reading section highlighted
- Contents can be shown or hidden from the toolbar or View menu
- Offline Mermaid fenced-code rendering with no user setup
- Native Print panel from File > Print or `Command-P`, with a dedicated
  print layout for headings, body text, lists, tables, quotes, and code.
  Mermaid diagrams print as their source-code fallback. Saving as PDF inherits
  the Markdown document's base file name.
- Light and dark appearance through system colors
- UTF-8 input and an empty-document state

Deferred:

- Relative local image resolution
- Find navigator and zoom
- Quick Look integration (intentionally out of scope)
- Preferences and theme selection
- Intel support and an updater (Mac App Store distribution supplies updates)

## License and release checklist

The application source is MIT licensed. Runtime dependencies are also
permissively licensed, but their notices must travel with distributed binaries.

Before publishing:

1. Review `Package.resolved` and `swift package show-dependencies`.
2. Keep `THIRD_PARTY_NOTICES.md` and bundled license texts in the app.
3. Run tests and build the Xcode `MDPreview` scheme.
4. Complete the checklist in `AppStore/submission-checklist.md`.
5. Archive source for the exact release tag.
6. Publish the source and checksums with the GitHub Release.

GitHub Actions can later build and test pull requests without publishing
secrets. Release signing should use protected repository secrets or a separate
trusted release machine.

## Privacy and support

- Product page: https://hshimomura.github.io/MDPreview/
- Privacy policy: https://hshimomura.github.io/MDPreview/privacy
- Support: https://hshimomura.github.io/MDPreview/support
