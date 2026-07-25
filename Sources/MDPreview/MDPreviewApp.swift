import AppKit
import SwiftUI

@main
struct MDPreviewApp: App {
  init() {
    NSWindow.allowsAutomaticWindowTabbing = false
  }

  var body: some Scene {
    DocumentGroup(viewing: MarkdownDocument.self) { configuration in
      PreviewView(
        document: configuration.document,
        fileURL: configuration.fileURL
      )
    }
    .commands {
      OpenMarkdownFilesCommands()

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

      CommandGroup(after: .windowArrangement) {
        Button("Arrange Markdown Windows Side by Side") {
          MarkdownWindowArranger.arrangeVisibleWindows()
        }
      }
    }
  }
}

private struct OpenMarkdownFilesCommands: Commands {
  @Environment(\.openDocument) private var openDocument

  var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button("Open Markdown Files…") {
        openMarkdownFiles()
      }
      .keyboardShortcut("o", modifiers: .command)
    }
  }

  private func openMarkdownFiles() {
    let panel = NSOpenPanel()
    panel.title = "Open Markdown Files"
    panel.message = "Select one or more Markdown files to open in separate windows."
    panel.prompt = "Open"
    panel.allowedContentTypes = [.markdownDocument]
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false

    guard panel.runModal() == .OK else { return }

    Task { @MainActor in
      for url in panel.urls {
        do {
          try await openDocument(at: url)
        } catch {
          NSAlert(error: error).runModal()
        }
      }
    }
  }
}

@MainActor
private enum MarkdownWindowArranger {
  static var visibleDocumentWindows: [NSWindow] {
    NSApp.windows.filter { window in
      window.isVisible
        && window.canBecomeMain
        && !(window is NSPanel)
        && window.styleMask.contains(.titled)
    }
  }

  static func arrangeVisibleWindows() {
    let windows = visibleDocumentWindows
    guard windows.count > 1, let screen = NSApp.keyWindow?.screen ?? NSScreen.main
    else {
      return
    }

    let visibleFrame = screen.visibleFrame
    let columnCount = min(windows.count, 3)
    let rowCount = Int(ceil(Double(windows.count) / Double(columnCount)))
    let windowWidth = visibleFrame.width / CGFloat(columnCount)
    let windowHeight = visibleFrame.height / CGFloat(rowCount)
    let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    NSAnimationContext.runAnimationGroup { context in
      context.duration = shouldAnimate ? 0.2 : 0

      for (index, window) in windows.enumerated() {
        let column = index % columnCount
        let row = index / columnCount
        let frame = NSRect(
          x: visibleFrame.minX + CGFloat(column) * windowWidth,
          y: visibleFrame.maxY - CGFloat(row + 1) * windowHeight,
          width: windowWidth,
          height: windowHeight
        )
        window.animator().setFrame(frame, display: true)
      }
    }

    windows.first?.makeKeyAndOrderFront(nil)
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
