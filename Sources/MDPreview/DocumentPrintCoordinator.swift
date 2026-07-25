import AppKit
import Foundation

@MainActor
final class DocumentPrintCoordinator {
  func printDocument(markdown: String, fileURL: URL?) {
    let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .automatic
    printInfo.isHorizontallyCentered = true
    printInfo.isVerticallyCentered = false

    let printableWidth = max(printInfo.imageablePageBounds.width, 420)
    let textView = makeTextView(
      attributedString: PrintDocumentFormatter.attributedString(markdown: markdown),
      width: printableWidth
    )

    let operation = NSPrintOperation(view: textView, printInfo: printInfo)
    operation.jobTitle = Self.jobTitle(for: fileURL)
    operation.showsPrintPanel = true
    operation.showsProgressPanel = true
    operation.printPanel.options.insert([
      .showsCopies,
      .showsOrientation,
      .showsPaperSize,
      .showsPreview,
      .showsScaling,
    ])
    operation.run()
  }

  static func jobTitle(for fileURL: URL?) -> String {
    guard let fileURL else { return "Markdown" }
    let baseName = fileURL.deletingPathExtension().lastPathComponent
    return baseName.isEmpty ? "Markdown" : baseName
  }

  private func makeTextView(
    attributedString: NSAttributedString,
    width: CGFloat
  ) -> NSTextView {
    let textStorage = NSTextStorage(attributedString: attributedString)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(
      containerSize: NSSize(
        width: width,
        height: .greatestFiniteMagnitude
      )
    )
    textContainer.widthTracksTextView = true
    textContainer.lineFragmentPadding = 0
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)

    let textView = NSTextView(
      frame: NSRect(x: 0, y: 0, width: width, height: 1),
      textContainer: textContainer
    )
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = true
    textView.drawsBackground = true
    textView.backgroundColor = .white
    textView.textContainerInset = NSSize(width: 24, height: 28)
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.maxSize = NSSize(
      width: width,
      height: .greatestFiniteMagnitude
    )

    layoutManager.ensureLayout(for: textContainer)
    let contentHeight = layoutManager.usedRect(for: textContainer).height
      + (textView.textContainerInset.height * 2)
    textView.frame.size.height = max(contentHeight, 1)
    return textView
  }
}

@MainActor
enum PrintDocumentFormatter {
  private static let bodyFont = NSFont.systemFont(ofSize: 11.5)
  private static let codeFont = NSFont.monospacedSystemFont(
    ofSize: 10.5,
    weight: .regular
  )
  private static let textColor = NSColor.black
  private static let secondaryColor = NSColor.darkGray
  private static let codeBackground = NSColor(
    calibratedWhite: 0.94,
    alpha: 1
  )

  static func attributedString(markdown: String) -> NSAttributedString {
    let output = NSMutableAttributedString()
    let content = MarkdownContentParser.parse(markdown)

    for section in content.sections {
      for block in section.blocks {
        switch block {
        case let .markdown(source):
          appendMarkdown(source, to: output)
        case let .mermaid(source):
          appendMermaid(source, to: output)
        }
      }
    }

    if output.length == 0 {
      output.append(
        NSAttributedString(
          string: "This Markdown document is empty.",
          attributes: baseAttributes(font: bodyFont, color: secondaryColor)
        )
      )
    }
    return output
  }

  private static func appendMarkdown(
    _ source: String,
    to output: NSMutableAttributedString
  ) {
    var paragraphLines: [String] = []
    var codeLines: [String] = []
    var codeLanguage: String?
    var codeFence: Character?

    func flushParagraph() {
      guard !paragraphLines.isEmpty else { return }
      appendInline(
        paragraphLines.joined(separator: " "),
        font: bodyFont,
        paragraphStyle: paragraphStyle(spacingAfter: 8),
        to: output
      )
      output.append(NSAttributedString(string: "\n"))
      paragraphLines.removeAll(keepingCapacity: true)
    }

    func flushCode() {
      guard !codeLines.isEmpty || codeLanguage != nil else { return }
      appendCodeBlock(
        codeLines.joined(separator: "\n"),
        language: codeLanguage,
        to: output
      )
      codeLines.removeAll(keepingCapacity: true)
      codeLanguage = nil
    }

    for line in source.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      if let fence = codeFence {
        if isClosingFence(trimmed, marker: fence) {
          flushCode()
          codeFence = nil
        } else {
          codeLines.append(line)
        }
        continue
      }

      if let openingFence = openingFence(trimmed) {
        flushParagraph()
        codeFence = openingFence.marker
        codeLanguage = openingFence.language
        continue
      }

      if trimmed.isEmpty {
        flushParagraph()
        continue
      }

      if let heading = heading(in: trimmed) {
        flushParagraph()
        appendHeading(
          heading.title,
          level: heading.level,
          to: output
        )
        continue
      }

      if isTableDivider(trimmed) {
        flushParagraph()
        continue
      }

      if let cells = tableCells(in: trimmed) {
        flushParagraph()
        appendTableRow(cells, to: output)
        continue
      }

      if let item = unorderedListItem(in: trimmed) {
        flushParagraph()
        appendListItem("•", text: item, to: output)
        continue
      }

      if let item = orderedListItem(in: trimmed) {
        flushParagraph()
        appendListItem(item.marker, text: item.text, to: output)
        continue
      }

      if trimmed.hasPrefix(">") {
        flushParagraph()
        let quote = trimmed.dropFirst()
          .trimmingCharacters(in: .whitespaces)
        appendQuote(quote, to: output)
        continue
      }

      if isThematicBreak(trimmed) {
        flushParagraph()
        appendThematicBreak(to: output)
        continue
      }

      paragraphLines.append(trimmed)
    }

    flushParagraph()
    if codeFence != nil {
      flushCode()
    }
  }

  private static func appendHeading(
    _ source: String,
    level: Int,
    to output: NSMutableAttributedString
  ) {
    let size: CGFloat
    switch level {
    case 1: size = 24
    case 2: size = 19
    case 3: size = 16
    default: size = 13.5
    }

    appendInline(
      source,
      font: .systemFont(ofSize: size, weight: .semibold),
      paragraphStyle: paragraphStyle(
        spacingBefore: level == 1 ? 0 : 12,
        spacingAfter: 7
      ),
      to: output
    )
    output.append(NSAttributedString(string: "\n"))
  }

  private static func appendListItem(
    _ marker: String,
    text: String,
    to output: NSMutableAttributedString
  ) {
    let style = paragraphStyle(spacingAfter: 3)
    style.headIndent = 22
    style.firstLineHeadIndent = 4
    style.tabStops = [
      NSTextTab(textAlignment: .left, location: 22)
    ]
    appendInline(
      "\(marker)\t\(text)",
      font: bodyFont,
      paragraphStyle: style,
      to: output
    )
    output.append(NSAttributedString(string: "\n"))
  }

  private static func appendQuote(
    _ source: String,
    to output: NSMutableAttributedString
  ) {
    let style = paragraphStyle(spacingAfter: 7)
    style.headIndent = 20
    style.firstLineHeadIndent = 20
    appendInline(
      "│  \(source)",
      font: bodyFont,
      color: secondaryColor,
      paragraphStyle: style,
      to: output
    )
    output.append(NSAttributedString(string: "\n"))
  }

  private static func appendTableRow(
    _ cells: [String],
    to output: NSMutableAttributedString
  ) {
    let style = paragraphStyle(spacingAfter: 2)
    style.lineSpacing = 2
    appendInline(
      cells.joined(separator: "  │  "),
      font: .systemFont(ofSize: 10.5),
      paragraphStyle: style,
      to: output
    )
    output.append(NSAttributedString(string: "\n"))
  }

  private static func appendCodeBlock(
    _ source: String,
    language: String?,
    to output: NSMutableAttributedString
  ) {
    if let language, !language.isEmpty {
      output.append(
        NSAttributedString(
          string: language.uppercased() + "\n",
          attributes: baseAttributes(
            font: .systemFont(ofSize: 9.5, weight: .semibold),
            color: secondaryColor
          )
        )
      )
    }
    let style = paragraphStyle(spacingAfter: 9)
    style.lineSpacing = 2
    output.append(
      NSAttributedString(
        string: source + "\n",
        attributes: [
          .font: codeFont,
          .foregroundColor: textColor,
          .backgroundColor: codeBackground,
          .paragraphStyle: style,
        ]
      )
    )
  }

  private static func appendMermaid(
    _ source: String,
    to output: NSMutableAttributedString
  ) {
    appendCodeBlock(source, language: "Mermaid diagram", to: output)
  }

  private static func appendThematicBreak(
    to output: NSMutableAttributedString
  ) {
    let style = paragraphStyle(spacingBefore: 5, spacingAfter: 9)
    output.append(
      NSAttributedString(
        string: "────────────────────────────────────────\n",
        attributes: baseAttributes(
          font: .systemFont(ofSize: 9),
          color: .lightGray,
          paragraphStyle: style
        )
      )
    )
  }

  private static func appendInline(
    _ source: String,
    font: NSFont,
    color: NSColor = textColor,
    paragraphStyle: NSParagraphStyle,
    to output: NSMutableAttributedString
  ) {
    let parsed: AttributedString
    do {
      parsed = try AttributedString(
        markdown: source,
        options: .init(
          interpretedSyntax: .inlineOnlyPreservingWhitespace,
          failurePolicy: .returnPartiallyParsedIfPossible
        )
      )
    } catch {
      output.append(
        NSAttributedString(
          string: source,
          attributes: baseAttributes(
            font: font,
            color: color,
            paragraphStyle: paragraphStyle
          )
        )
      )
      return
    }

    for run in parsed.runs {
      let runText = String(parsed[run.range].characters)
      var attributes = baseAttributes(
        font: font,
        color: color,
        paragraphStyle: paragraphStyle
      )

      if let intent = run.inlinePresentationIntent {
        var traits: NSFontTraitMask = []
        if intent.contains(.stronglyEmphasized) {
          traits.insert(.boldFontMask)
        }
        if intent.contains(.emphasized) {
          traits.insert(.italicFontMask)
        }
        if !traits.isEmpty {
          attributes[.font] = NSFontManager.shared.convert(
            font,
            toHaveTrait: traits
          )
        }
        if intent.contains(.code) {
          attributes[.font] = codeFont
          attributes[.backgroundColor] = codeBackground
        }
        if intent.contains(.strikethrough) {
          attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
      }

      if let link = run.link {
        attributes[.link] = link
        attributes[.foregroundColor] = NSColor.systemBlue
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
      }

      output.append(
        NSAttributedString(string: runText, attributes: attributes)
      )
    }
  }

  private static func baseAttributes(
    font: NSFont,
    color: NSColor,
    paragraphStyle: NSParagraphStyle? = nil
  ) -> [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
    ]
    if let paragraphStyle {
      attributes[.paragraphStyle] = paragraphStyle
    }
    return attributes
  }

  private static func paragraphStyle(
    spacingBefore: CGFloat = 0,
    spacingAfter: CGFloat = 0
  ) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.paragraphSpacingBefore = spacingBefore
    style.paragraphSpacing = spacingAfter
    style.lineHeightMultiple = 1.08
    style.hyphenationFactor = 0.3
    style.tighteningFactorForTruncation = 0
    return style
  }

  private static func heading(
    in line: String
  ) -> (level: Int, title: String)? {
    let markerCount = line.prefix(while: { $0 == "#" }).count
    guard (1...6).contains(markerCount) else { return nil }
    let titleStart = line.index(line.startIndex, offsetBy: markerCount)
    guard titleStart == line.endIndex || line[titleStart].isWhitespace else {
      return nil
    }
    var title = String(line[titleStart...])
      .trimmingCharacters(in: .whitespaces)
    while title.last == "#" {
      title.removeLast()
      title = title.trimmingCharacters(in: .whitespaces)
    }
    return (markerCount, title)
  }

  private static func unorderedListItem(in line: String) -> String? {
    for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
      return String(line.dropFirst(marker.count))
    }
    return nil
  }

  private static func orderedListItem(
    in line: String
  ) -> (marker: String, text: String)? {
    let digits = line.prefix(while: \.isNumber)
    guard !digits.isEmpty else { return nil }
    let remainder = line.dropFirst(digits.count)
    guard
      let punctuation = remainder.first,
      punctuation == "." || punctuation == ")",
      remainder.dropFirst().first?.isWhitespace == true
    else {
      return nil
    }
    return (
      "\(digits)\(punctuation)",
      String(remainder.dropFirst()).trimmingCharacters(in: .whitespaces)
    )
  }

  private static func tableCells(in line: String) -> [String]? {
    guard line.contains("|") else { return nil }
    var cells = line.split(separator: "|", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespaces) }
    if line.hasPrefix("|"), !cells.isEmpty {
      cells.removeFirst()
    }
    if line.hasSuffix("|"), !cells.isEmpty {
      cells.removeLast()
    }
    return cells.count > 1 ? cells : nil
  }

  private static func isTableDivider(_ line: String) -> Bool {
    guard let cells = tableCells(in: line), !cells.isEmpty else {
      return false
    }
    return cells.allSatisfy { cell in
      let markers = cell.filter { $0 == "-" }.count
      return markers >= 3
        && cell.allSatisfy { $0 == "-" || $0 == ":" || $0.isWhitespace }
    }
  }

  private static func openingFence(
    _ line: String
  ) -> (marker: Character, language: String?)? {
    guard let marker = line.first, marker == "`" || marker == "~" else {
      return nil
    }
    let markerCount = line.prefix(while: { $0 == marker }).count
    guard markerCount >= 3 else { return nil }
    let language = line.dropFirst(markerCount)
      .trimmingCharacters(in: .whitespaces)
    return (marker, language.isEmpty ? nil : language)
  }

  private static func isClosingFence(
    _ line: String,
    marker: Character
  ) -> Bool {
    let markerCount = line.prefix(while: { $0 == marker }).count
    return markerCount >= 3
      && line.dropFirst(markerCount).allSatisfy(\.isWhitespace)
  }

  private static func isThematicBreak(_ line: String) -> Bool {
    let meaningful = line.filter { !$0.isWhitespace }
    guard meaningful.count >= 3, let marker = meaningful.first else {
      return false
    }
    return (marker == "-" || marker == "*" || marker == "_")
      && meaningful.allSatisfy { $0 == marker }
  }
}
