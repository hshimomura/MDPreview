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
    }
  }
}
