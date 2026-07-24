# MDPreview

This file verifies that **Markdown** opens as a rendered, read-only document.

## Supported MVP content

- Headings and paragraphs
- **Bold**, *emphasis*, and [links](https://example.com)
- Ordered and unordered lists
- Tables and code blocks
- Text selection

| Component | Choice |
| --- | --- |
| UI | SwiftUI |
| Renderer | Textual 0.5.0 |
| Document mode | Viewer |

```swift
DocumentGroup(viewing: MarkdownDocument.self) {
    PreviewView(document: $0.document, fileURL: $0.fileURL)
}
```
