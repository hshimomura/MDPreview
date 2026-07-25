import AppKit
import SwiftUI

struct WindowSizeStore {
  static let defaultSize = CGSize(width: 1100, height: 760)
  static let minimumSize = CGSize(width: 560, height: 420)

  private let defaults: UserDefaults
  private let widthKey = "documentWindowContentWidth"
  private let heightKey = "documentWindowContentHeight"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func restoredSize(maximumSize: CGSize) -> CGSize? {
    guard
      defaults.object(forKey: widthKey) != nil,
      defaults.object(forKey: heightKey) != nil
    else {
      return nil
    }

    return constrainedSize(
      CGSize(
        width: defaults.double(forKey: widthKey),
        height: defaults.double(forKey: heightKey)
      ),
      maximumSize: maximumSize
    )
  }

  func initialSize(maximumSize: CGSize) -> CGSize {
    restoredSize(maximumSize: maximumSize)
      ?? constrainedSize(Self.defaultSize, maximumSize: maximumSize)
  }

  func save(_ size: CGSize) {
    defaults.set(size.width, forKey: widthKey)
    defaults.set(size.height, forKey: heightKey)
  }

  private func constrainedSize(
    _ size: CGSize,
    maximumSize: CGSize
  ) -> CGSize {
    CGSize(
      width: min(
        max(size.width, Self.minimumSize.width),
        maximumSize.width
      ),
      height: min(
        max(size.height, Self.minimumSize.height),
        maximumSize.height
      )
    )
  }
}

@MainActor
struct WindowSizeRestorer: NSViewRepresentable {
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> TrackingView {
    let view = TrackingView()
    view.coordinator = context.coordinator
    return view
  }

  func updateNSView(_ nsView: TrackingView, context: Context) {
    context.coordinator.attach(to: nsView.window)
  }

  static func dismantleNSView(
    _ nsView: TrackingView,
    coordinator: Coordinator
  ) {
    coordinator.detach()
  }

  @MainActor
  final class TrackingView: NSView {
    weak var coordinator: Coordinator?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      coordinator?.attach(to: window)
    }
  }

  @MainActor
  final class Coordinator: NSObject {
    private weak var window: NSWindow?
    private let store = WindowSizeStore()

    func attach(to window: NSWindow?) {
      guard let window, self.window !== window else {
        return
      }

      detach()
      self.window = window

      let visibleSize =
        window.screen?.visibleFrame.size
        ?? NSScreen.main?.visibleFrame.size
        ?? WindowSizeStore.defaultSize

      window.setContentSize(store.initialSize(maximumSize: visibleSize))

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidResize(_:)),
        name: NSWindow.didResizeNotification,
        object: window
      )
    }

    func detach() {
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.didResizeNotification,
        object: window
      )
      window = nil
    }

    @objc
    private func windowDidResize(_ notification: Notification) {
      guard
        let window = notification.object as? NSWindow,
        !window.styleMask.contains(.fullScreen),
        !window.isMiniaturized,
        let contentSize = window.contentView?.bounds.size
      else {
        return
      }

      store.save(contentSize)
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }
}
