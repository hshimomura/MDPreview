import SwiftUI
import Textual

struct PreviewView: View {
  let document: MarkdownDocument
  let fileURL: URL?

  var body: some View {
    Group {
      if document.text.isEmpty {
        ContentUnavailableView(
          "Empty Markdown File",
          systemImage: "doc.text.magnifyingglass",
          description: Text("This document contains no text.")
        )
      } else {
        ScrollView {
          StructuredText(document.text, parser: HTMLBreakMarkdownParser())
            .textual.structuredTextStyle(.gitHub)
            .textual.textSelection(.enabled)
            .frame(maxWidth: 880, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 36)
            .padding(.vertical, 30)
        }
      }
    }
    .frame(minWidth: 560, minHeight: 420)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      statusBar
    }
  }

  private var statusBar: some View {
    HStack {
      Label(
        fileURL?.lastPathComponent ?? "Markdown",
        systemImage: "doc.text"
      )
      .lineLimit(1)

      Spacer()

      Text("Read Only")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 12)
    .frame(height: 28)
    .background(.bar)
    .overlay(alignment: .top) {
      Divider()
    }
  }
}
