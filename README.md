# MDPreview

MDPreview is a small, read-only Markdown viewer for macOS 26. It is native
SwiftUI software: there is no editor, embedded browser, Electron runtime,
database, account, or network service.

The detailed architecture and roadmap are in [DESIGN.md](DESIGN.md).

## MVP architecture

```text
Finder / File > Open
        |
        v
SwiftUI DocumentGroup(viewing:)
        |
        v
MarkdownDocument (UTF-8, immutable String)
        |
        v
Textual StructuredText (native SwiftUI rendering)
        |
        v
Scrollable, selectable preview
```

- `DocumentGroup(viewing:)` provides read-only document lifecycle and
  multiwindow behavior.
- `net.daringfireball.markdown` registers `.md` and `.markdown` with a
  `Viewer` role and `Alternate` handler rank.
- Textual 0.5.0 renders structured Markdown with native SwiftUI views.
- Swift Package Manager pins the dependency graph in `Package.resolved`.
- The app targets macOS 26 and currently builds an Apple-silicon binary.

## Requirements

- macOS 26
- Xcode 26
- Swift 6.2 or newer
- Network access for the first Swift Package Manager dependency resolution

## Build

```sh
chmod +x Scripts/build-app.sh Scripts/verify-app.sh
./Scripts/build-app.sh
./Scripts/verify-app.sh
```

The app bundle is generated at `dist/MDPreview.app`.

Open the sample:

```sh
open -a "$PWD/dist/MDPreview.app" "$PWD/Sample.md"
```

The build uses ad-hoc signing for local testing. A public binary should use a
Developer ID Application certificate, hardened runtime, notarization, and a
stapled notarization ticket.

## MVP scope

Included:

- Finder and Open-menu handling for `.md` and `.markdown`
- Multiple read-only document windows
- GitHub-like native rendering
- Tables, lists, code blocks, links, and selectable text
- HTML-style `<br>`, `<br/>`, and `<br />` line breaks, including table cells
- `Command-W` closes the active document window
- Light and dark appearance through system colors
- UTF-8 input and an empty-document state

Deferred:

- Automatic reload after external file changes
- Relative local image resolution
- Find navigator, outline, zoom, and print
- Preferences and theme selection
- Universal binary, release signing, notarization, and updater

## License and release checklist

The application source is MIT licensed. Runtime dependencies are also
permissively licensed, but their notices must travel with distributed binaries.

Before publishing:

1. Replace the bundle identifier and copyright holder.
2. Review `Package.resolved` and `swift package show-dependencies`.
3. Keep `THIRD_PARTY_NOTICES.md` and bundled license texts in the app.
4. Run tests, build, and `Scripts/verify-app.sh`.
5. Archive source for the exact release tag.
6. Sign with Developer ID, enable hardened runtime, notarize, and staple.
7. Publish the source and checksums with the GitHub Release.

GitHub Actions can later build and test pull requests without publishing
secrets. Release signing should use protected repository secrets or a separate
trusted release machine.
