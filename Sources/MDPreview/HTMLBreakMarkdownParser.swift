import Foundation
import Textual

@MainActor
struct HTMLBreakMarkdownParser: MarkupParser {
  private let parser: AttributedStringMarkdownParser

  init(baseURL: URL? = nil) {
    parser = AttributedStringMarkdownParser(baseURL: baseURL)
  }

  func attributedString(for input: String) throws -> AttributedString {
    let parsed = try parser.attributedString(for: input)
    var result = AttributedString()

    for run in parsed.runs {
      let content = parsed[run.range]

      guard
        run.inlinePresentationIntent?.contains(.inlineHTML) == true,
        isBreakTag(String(content.characters))
      else {
        result.append(AttributedString(content))
        continue
      }

      var lineBreak = AttributedString("\n")
      lineBreak.setAttributes(run.attributes)
      lineBreak.inlinePresentationIntent = nil
      result.append(lineBreak)
    }

    return result
  }

  private func isBreakTag(_ tag: String) -> Bool {
    let compactTag =
      tag
      .filter { !$0.isWhitespace }
      .lowercased()

    return compactTag == "<br>" || compactTag == "<br/>"
  }
}
