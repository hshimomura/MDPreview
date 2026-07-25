import SwiftUI

struct PreviewCommandActions {
  let isContentsVisible: Bool
  let toggleContents: () -> Void
  let printDocument: () -> Void
}

private struct PreviewCommandActionsKey: FocusedValueKey {
  typealias Value = PreviewCommandActions
}

extension FocusedValues {
  var previewCommandActions: PreviewCommandActions? {
    get { self[PreviewCommandActionsKey.self] }
    set { self[PreviewCommandActionsKey.self] = newValue }
  }
}
