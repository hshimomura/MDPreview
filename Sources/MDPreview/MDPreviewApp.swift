import AppKit
import SwiftUI

@main
struct MDPreviewApp: App {
  var body: some Scene {
    DocumentGroup(viewing: MarkdownDocument.self) { configuration in
      PreviewView(
        document: configuration.document,
        fileURL: configuration.fileURL
      )
    }
    .commands {
      CommandGroup(replacing: .saveItem) {
        Button("Close Window") {
          NSApp.keyWindow?.performClose(nil)
        }
        .keyboardShortcut("w", modifiers: .command)
      }

      CommandGroup(replacing: .printItem) {
        PrintDocumentCommand()
      }

      CommandGroup(replacing: .sidebar) {
        ToggleContentsCommand()
      }
    }
  }
}

private struct PrintDocumentCommand: View {
  @FocusedValue(\.previewCommandActions) private var actions

  var body: some View {
    Button("Print…") {
      actions?.printDocument()
    }
    .keyboardShortcut("p", modifiers: .command)
    .disabled(actions == nil)
  }
}

private struct ToggleContentsCommand: View {
  @FocusedValue(\.previewCommandActions) private var actions

  var body: some View {
    Button(actions?.isContentsVisible == true ? "Hide Contents" : "Show Contents") {
      actions?.toggleContents()
    }
    .keyboardShortcut("s", modifiers: [.command, .control])
    .disabled(actions == nil)
  }
}
