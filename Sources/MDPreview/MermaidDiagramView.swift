import SwiftUI
import WebKit

struct MermaidDiagramView: View {
  let source: String

  @Environment(\.colorScheme) private var colorScheme
  @State private var height: CGFloat = 180
  @State private var canLoadRenderer = false

  var body: some View {
    Group {
      if canLoadRenderer {
        MermaidWebView(
          source: source,
          theme: colorScheme == .dark ? "dark" : "light",
          height: $height
        )
      } else {
        ProgressView()
          .controlSize(.small)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.separator.opacity(0.55), lineWidth: 1)
    }
    .accessibilityLabel("Mermaid diagram")
    .task {
      try? await Task.sleep(for: .milliseconds(120))
      guard !Task.isCancelled else { return }
      canLoadRenderer = true
    }
  }
}

private struct MermaidWebView: NSViewRepresentable {
  let source: String
  let theme: String
  @Binding var height: CGFloat

  func makeCoordinator() -> Coordinator {
    Coordinator(height: $height)
  }

  func makeNSView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    configuration.userContentController.add(
      context.coordinator,
      name: Coordinator.messageName
    )

    let webView = IntrinsicSizeNeutralWebView(
      frame: .zero,
      configuration: configuration
    )
    webView.navigationDelegate = context.coordinator
    webView.underPageBackgroundColor = .clear
    webView.enclosingScrollView?.hasVerticalScroller = false
    webView.enclosingScrollView?.hasHorizontalScroller = false
    context.coordinator.webView = webView
    DispatchQueue.main.async { [weak coordinator = context.coordinator] in
      coordinator?.loadRenderer()
    }
    return webView
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize,
    nsView: WKWebView,
    context: Context
  ) -> CGSize? {
    CGSize(
      width: max(proposal.width ?? 600, 1),
      height: max(height, 80)
    )
  }

  func updateNSView(_ webView: WKWebView, context: Context) {
    context.coordinator.render(source: source, theme: theme)
  }

  static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
    webView.configuration.userContentController.removeScriptMessageHandler(
      forName: Coordinator.messageName
    )
    webView.navigationDelegate = nil
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let messageName = "diagram"

    weak var webView: WKWebView?
    private var pendingSource: String?
    private var pendingTheme: String?
    private var renderedSource: String?
    private var renderedTheme: String?
    private var rendererReady = false
    private var height: Binding<CGFloat>

    init(height: Binding<CGFloat>) {
      self.height = height
    }

    func loadRenderer() {
      guard let resourcesURL = Bundle.main.resourceURL, let webView else {
        return
      }
      let rendererURL = resourcesURL
        .appending(path: "MDPreview_MDPreview.bundle", directoryHint: .isDirectory)
        .appending(path: "Resources/Mermaid", directoryHint: .isDirectory)
        .appending(path: "renderer.html", directoryHint: .notDirectory)

      webView.loadFileURL(
        rendererURL,
        allowingReadAccessTo: rendererURL.deletingLastPathComponent()
      )
    }

    func render(source: String, theme: String) {
      pendingSource = source
      pendingTheme = theme
      guard rendererReady else { return }
      guard source != renderedSource || theme != renderedTheme else { return }
      performRender(source: source, theme: theme)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      rendererReady = true
      if let pendingSource, let pendingTheme {
        performRender(source: pendingSource, theme: pendingTheme)
      }
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler:
        @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.cancel)
        return
      }

      if navigationAction.navigationType == .other,
         url.isFileURL || url.absoluteString == "about:blank"
      {
        decisionHandler(.allow)
      } else {
        decisionHandler(.cancel)
      }
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard
        message.name == Self.messageName,
        let body = message.body as? [String: Any],
        let reportedHeight = body["height"] as? Double
      else {
        return
      }
      height.wrappedValue = min(max(reportedHeight, 80), 4_000)
    }

    private func performRender(source: String, theme: String) {
      guard let webView else { return }
      renderedSource = source
      renderedTheme = theme

      let sourceJSON = Self.jsonString(source)
      let themeJSON = Self.jsonString(theme)
      webView.evaluateJavaScript(
        "window.renderDiagram(\(sourceJSON), \(themeJSON));"
      )
    }

    private static func jsonString(_ value: String) -> String {
      guard
        let data = try? JSONSerialization.data(withJSONObject: [value]),
        var encoded = String(data: data, encoding: .utf8)
      else {
        return "\"\""
      }
      encoded.removeFirst()
      encoded.removeLast()
      return encoded
    }
  }
}

private final class IntrinsicSizeNeutralWebView: WKWebView {
  override var intrinsicContentSize: NSSize {
    NSSize(
      width: NSView.noIntrinsicMetric,
      height: NSView.noIntrinsicMetric
    )
  }
}
