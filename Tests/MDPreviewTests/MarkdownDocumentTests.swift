import Foundation
import Testing

@testable import MDPreview

struct MarkdownDocumentTests {
  @Test
  func storesMarkdownText() {
    let source = "# Hello\n\nThis is **Markdown**."
    let document = MarkdownDocument(text: source)

    #expect(document.text == source)
  }

  @Test
  func declaresMarkdownUTType() {
    #expect(
      MarkdownDocument.readableContentTypes
        .contains { $0.identifier == "net.daringfireball.markdown" }
    )
  }
}

@MainActor
struct HTMLBreakMarkdownParserTests {
  private let parser = HTMLBreakMarkdownParser()

  @Test
  func convertsHTMLBreakTagsToLineBreaks() throws {
    let rendered = try parser.attributedString(
      for: "before<br>middle<BR />after"
    )

    #expect(String(rendered.characters) == "before\nmiddle\nafter")
  }

  @Test
  func convertsBreaksInsideTableCells() throws {
    let source = """
      | Status | Details |
      | --- | --- |
      | Ready<br>Now | FW: 1.0<br>PRI: Generic |
      """
    let rendered = try parser.attributedString(for: source)

    #expect(String(rendered.characters).contains("Ready\nNow"))
    #expect(String(rendered.characters).contains("FW: 1.0\nPRI: Generic"))
  }

  @Test
  func preservesBreakTagsInCode() throws {
    let source = """
      Inline `<br>` remains code.

      ```html
      <br>
      ```
      """
    let rendered = try parser.attributedString(for: source)

    #expect(String(rendered.characters).contains("<br> remains code"))
    #expect(String(rendered.characters).contains("<br>"))
    #expect(!String(rendered.characters).contains("\n\n\n"))
  }

  @Test
  func preservesOtherInlineHTML() throws {
    let rendered = try parser.attributedString(
      for: "before<span>content</span>after"
    )

    #expect(
      String(rendered.characters) == "before<span>content</span>after"
    )
  }
}
