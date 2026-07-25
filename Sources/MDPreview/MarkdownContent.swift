import Foundation

struct MarkdownHeading: Identifiable, Equatable, Sendable {
  let id: String
  let level: Int
  let title: String
}

struct MarkdownSection: Identifiable, Equatable, Sendable {
  let id: String
  let heading: MarkdownHeading?
  let blocks: [MarkdownContentBlock]
}

enum MarkdownContentBlock: Equatable, Sendable {
  case markdown(String)
  case mermaid(String)
}

struct MarkdownContent: Equatable, Sendable {
  let sections: [MarkdownSection]

  var headings: [MarkdownHeading] {
    sections.compactMap(\.heading)
  }
}

enum MarkdownContentParser {
  static func parse(_ source: String) -> MarkdownContent {
    var sections: [MarkdownSection] = []
    var blocks: [MarkdownContentBlock] = []
    var markdownLines: [String] = []
    var mermaidLines: [String] = []
    var openingFenceLine: String?
    var activeFence: Fence?
    var currentHeading: MarkdownHeading?
    var headingNumber = 0

    func flushMarkdown() {
      guard !markdownLines.isEmpty else { return }
      blocks.append(.markdown(markdownLines.joined(separator: "\n")))
      markdownLines.removeAll(keepingCapacity: true)
    }

    func flushSection() {
      flushMarkdown()
      guard !blocks.isEmpty || currentHeading != nil else { return }
      sections.append(
        MarkdownSection(
          id: currentHeading?.id ?? "document-start",
          heading: currentHeading,
          blocks: blocks
        )
      )
      blocks.removeAll(keepingCapacity: true)
    }

    for line in source.components(separatedBy: "\n") {
      if let fence = activeFence {
        if fence.isClosing(line) {
          if fence.isMermaid {
            blocks.append(.mermaid(mermaidLines.joined(separator: "\n")))
            mermaidLines.removeAll(keepingCapacity: true)
            openingFenceLine = nil
          } else {
            markdownLines.append(line)
          }
          activeFence = nil
        } else if fence.isMermaid {
          mermaidLines.append(line)
        } else {
          markdownLines.append(line)
        }
        continue
      }

      if let fence = Fence.opening(line) {
        activeFence = fence
        if fence.isMermaid {
          flushMarkdown()
          openingFenceLine = line
          mermaidLines.removeAll(keepingCapacity: true)
        } else {
          markdownLines.append(line)
        }
        continue
      }

      if let parsedHeading = parseHeading(line) {
        flushSection()
        headingNumber += 1
        let heading = MarkdownHeading(
          id: "section-\(headingNumber)-\(slug(parsedHeading.title))",
          level: parsedHeading.level,
          title: parsedHeading.title
        )
        currentHeading = heading
        markdownLines.append(line)
      } else {
        markdownLines.append(line)
      }
    }

    if let fence = activeFence, fence.isMermaid {
      markdownLines.append(openingFenceLine ?? "```mermaid")
      markdownLines.append(contentsOf: mermaidLines)
    }

    flushSection()

    if sections.isEmpty {
      sections = [
        MarkdownSection(
          id: "document-start",
          heading: nil,
          blocks: [.markdown(source)]
        )
      ]
    }

    return MarkdownContent(sections: sections)
  }

  private static func parseHeading(
    _ line: String
  ) -> (level: Int, title: String)? {
    let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
    let markerCount = trimmed.prefix(while: { $0 == "#" }).count
    guard (1...6).contains(markerCount) else { return nil }

    let titleStart = trimmed.index(trimmed.startIndex, offsetBy: markerCount)
    guard titleStart == trimmed.endIndex || trimmed[titleStart].isWhitespace else {
      return nil
    }

    var title = String(trimmed[titleStart...])
      .trimmingCharacters(in: .whitespaces)
    title = title.replacingOccurrences(
      of: #"\s+#+\s*$"#,
      with: "",
      options: .regularExpression
    )
    title = title.replacingOccurrences(
      of: #"\[([^\]]+)\]\([^)]+\)"#,
      with: "$1",
      options: .regularExpression
    )
    title = title.replacingOccurrences(
      of: #"[*_`~]"#,
      with: "",
      options: .regularExpression
    )

    return (markerCount, title.isEmpty ? "Untitled section" : title)
  }

  private static func slug(_ title: String) -> String {
    let folded = title
      .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
      .lowercased()
    let parts = folded.components(separatedBy: CharacterSet.alphanumerics.inverted)
    let result = parts.filter { !$0.isEmpty }.joined(separator: "-")
    return result.isEmpty ? "heading" : result
  }
}

private struct Fence {
  let marker: Character
  let length: Int
  let isMermaid: Bool

  static func opening(_ line: String) -> Fence? {
    let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
    guard let marker = trimmed.first, marker == "`" || marker == "~" else {
      return nil
    }
    let length = trimmed.prefix(while: { $0 == marker }).count
    guard length >= 3 else { return nil }

    let infoStart = trimmed.index(trimmed.startIndex, offsetBy: length)
    let info = trimmed[infoStart...]
      .trimmingCharacters(in: .whitespaces)
      .split(whereSeparator: \.isWhitespace)
      .first?
      .lowercased()

    return Fence(marker: marker, length: length, isMermaid: info == "mermaid")
  }

  func isClosing(_ line: String) -> Bool {
    let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
    guard trimmed.first == marker else { return false }
    let markerCount = trimmed.prefix(while: { $0 == marker }).count
    let suffix = trimmed.dropFirst(markerCount)
    return markerCount >= length && suffix.allSatisfy(\.isWhitespace)
  }
}
