# Third-party notices

MDPreview includes the following runtime dependencies. Their complete license
texts are copied into the built application under
`Contents/Resources/ThirdPartyLicenses`.

| Component | Version | License | Source |
| --- | --- | --- | --- |
| Textual | 0.5.0 | MIT | https://github.com/gonzalezreal/textual |
| SwiftUIMath | 0.1.0 | MIT | https://github.com/gonzalezreal/swiftui-math |
| ConcurrencyExtras | 1.4.0 | MIT | https://github.com/pointfreeco/swift-concurrency-extras |
| Prism.js | 1.29.0 (bundled by Textual) | MIT | https://github.com/PrismJS/prism |
| Mermaid | 11.15.0 | MIT | https://github.com/mermaid-js/mermaid |

SwiftUIMath includes math fonts under the SIL Open Font License 1.1 and the
GUST Font License. The complete `OFL.txt` and `GUST-FONT-LICENSE.txt` files
are retained inside the distributed
`swiftui-math_SwiftUIMath.bundle/mathFonts.bundle`.

Mermaid is included as a fixed local browser bundle so diagrams render
offline. Its complete MIT license is copied to
`ThirdPartyLicenses/Mermaid-LICENSE.txt`.

Before each public release, regenerate `Package.resolved`, review the complete
dependency graph with `swift package show-dependencies`, and confirm that this
notice matches the distributed binary.
