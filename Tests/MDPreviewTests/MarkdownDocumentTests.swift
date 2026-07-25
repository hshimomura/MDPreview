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

struct WindowSizeStoreTests {
  @Test
  func storesAndRestoresWindowSize() throws {
    let suiteName = "WindowSizeStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }
    let store = WindowSizeStore(defaults: defaults)

    #expect(store.restoredSize(maximumSize: CGSize(width: 1600, height: 1000)) == nil)
    #expect(
      store.initialSize(maximumSize: CGSize(width: 1600, height: 1000))
        == CGSize(width: 1100, height: 760)
    )

    store.save(CGSize(width: 1280, height: 840))

    #expect(
      store.restoredSize(maximumSize: CGSize(width: 1600, height: 1000))
        == CGSize(width: 1280, height: 840)
    )
  }

  @Test
  func constrainsRestoredSizeToAvailableDisplay() throws {
    let suiteName = "WindowSizeStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }
    let store = WindowSizeStore(defaults: defaults)
    store.save(CGSize(width: 2400, height: 1800))

    #expect(
      store.restoredSize(maximumSize: CGSize(width: 1440, height: 900))
        == CGSize(width: 1440, height: 900)
    )
  }
}

struct MarkdownContentParserTests {
  @Test
  func extractsOutlineAndPreservesHeadingLevels() {
    let content = MarkdownContentParser.parse(
      """
      Intro

      # Overview
      Text

      ## Details
      More text

      # Conclusion
      Done
      """
    )

    #expect(content.headings.map(\.title) == ["Overview", "Details", "Conclusion"])
    #expect(content.headings.map(\.level) == [1, 2, 1])
    #expect(Set(content.headings.map(\.id)).count == 3)
  }

  @Test
  func separatesMermaidFencesFromMarkdown() {
    let content = MarkdownContentParser.parse(
      """
      # Flow

      Before.

      ```mermaid
      flowchart LR
        A --> B
      ```

      After.
      """
    )
    let blocks = content.sections.flatMap(\.blocks)

    #expect(
      blocks.contains {
        if case let .mermaid(source) = $0 {
          return source.contains("A --> B")
        }
        return false
      }
    )
    #expect(
      blocks.compactMap {
        if case let .markdown(source) = $0 { return source }
        return nil
      }
      .joined()
      .contains("After.")
    )
  }

  @Test
  func ignoresHeadingsInsideCodeFences() {
    let content = MarkdownContentParser.parse(
      """
      # Visible

      ```text
      # Not a section
      ```
      """
    )

    #expect(content.headings.map(\.title) == ["Visible"])
  }
}

@MainActor
struct PrintDocumentFormatterTests {
  @Test
  func derivesPDFJobTitleFromMarkdownFileName() {
    let fileURL = URL(
      filePath: "/Documents/Example_Report.md"
    )

    #expect(
      DocumentPrintCoordinator.jobTitle(for: fileURL)
        == "Example_Report"
    )
    #expect(DocumentPrintCoordinator.jobTitle(for: nil) == "Markdown")
  }

  @Test
  func producesVisibleFormattedPrintContent() {
    let rendered = PrintDocumentFormatter.attributedString(
      markdown: """
      # Heading

      Paragraph with **bold** text.

      - First item

      | Name | Value |
      | --- | --- |
      | Alpha | One |
      """
    )

    #expect(rendered.length > 0)
    #expect(rendered.string.contains("Heading"))
    #expect(rendered.string.contains("•\tFirst item"))
    #expect(rendered.string.contains("Name  │  Value"))
  }

  @Test
  func includesMermaidSourceAsPrintFallback() {
    let rendered = PrintDocumentFormatter.attributedString(
      markdown: """
      ```mermaid
      flowchart LR
        A --> B
      ```
      """
    )

    #expect(rendered.string.contains("MERMAID DIAGRAM"))
    #expect(rendered.string.contains("A --> B"))
  }
}

@MainActor
struct PreviewDocumentModelTests {
  @Test
  func reloadsAfterAnAtomicFileReplacement() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "MDPreviewTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    defer {
      try? FileManager.default.removeItem(at: directory)
    }

    let fileURL = directory.appending(path: "Document.md")
    try Data("# Before".utf8).write(to: fileURL)
    let model = PreviewDocumentModel(text: "# Before", fileURL: fileURL)
    let monitoringTask = Task {
      await model.monitorFile()
    }
    defer {
      monitoringTask.cancel()
    }

    try await Task.sleep(for: .milliseconds(500))
    let replacementURL = directory.appending(path: "Replacement.md")
    try Data("# After\n\nReloaded.".utf8).write(to: replacementURL)
    _ = try FileManager.default.replaceItemAt(
      fileURL,
      withItemAt: replacementURL
    )
    try await Task.sleep(for: .milliseconds(900))

    #expect(model.text.contains("Reloaded."))
    #expect(model.content.headings.map(\.title) == ["After"])
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
