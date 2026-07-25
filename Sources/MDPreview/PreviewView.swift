import SwiftUI
import Textual

struct PreviewView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var model: PreviewDocumentModel
  @State private var sectionTops: [String: CGFloat] = [:]
  @State private var currentSectionID: String?
  @State private var scrollRequest: OutlineScrollRequest?
  @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
  @State private var printCoordinator = DocumentPrintCoordinator()

  init(document: MarkdownDocument, fileURL: URL?) {
    _model = State(
      initialValue: PreviewDocumentModel(
        text: document.text,
        fileURL: fileURL
      )
    )
  }

  var body: some View {
    Group {
      if model.text.isEmpty {
        ContentUnavailableView(
          "Empty Markdown File",
          systemImage: "doc.text.magnifyingglass",
          description: Text("This document contains no text.")
        )
      } else {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
          OutlineSidebar(
            headings: model.content.headings,
            currentSectionID: currentSectionID
          ) { sectionID in
            scrollRequest = OutlineScrollRequest(sectionID: sectionID)
          }
          .navigationSplitViewColumnWidth(
            min: 190,
            ideal: 230,
            max: 320
          )
        } detail: {
          documentPreview
        }
        .navigationSplitViewStyle(.prominentDetail)
      }
    }
    .frame(minWidth: 700, minHeight: 420)
    .background(WindowSizeRestorer())
    .safeAreaInset(edge: .bottom, spacing: 0) {
      statusBar
    }
    .focusedSceneValue(
      \.previewCommandActions,
      PreviewCommandActions(
        isContentsVisible: isContentsVisible,
        toggleContents: toggleContents,
        printDocument: {
          printCoordinator.printDocument(
            markdown: model.text,
            fileURL: model.fileURL
          )
        }
      )
    )
    .task(id: model.fileURL) {
      await model.monitorFile()
    }
    .onChange(of: model.content) {
      sectionTops.removeAll(keepingCapacity: true)
      currentSectionID = model.content.headings.first?.id
    }
  }

  private var documentPreview: some View {
    ScrollViewReader { scrollProxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(model.content.sections) { section in
            MarkdownSectionView(section: section)
              .id(section.id)
              .background {
                GeometryReader { geometry in
                  Color.clear.preference(
                    key: SectionTopPreferenceKey.self,
                    value: [
                      section.id:
                        geometry.frame(in: .named("document-scroll")).minY
                    ]
                  )
                }
              }
          }
        }
        .frame(maxWidth: 880, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 36)
        .padding(.vertical, 30)
      }
      .coordinateSpace(name: "document-scroll")
      .onPreferenceChange(SectionTopPreferenceKey.self) { values in
        sectionTops = values
        updateCurrentSection()
      }
      .onChange(of: scrollRequest) { _, request in
        guard let request else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
          scrollProxy.scrollTo(request.sectionID, anchor: .top)
        }
      }
    }
  }

  private var statusBar: some View {
    HStack(spacing: 12) {
      Label(
        model.fileURL?.lastPathComponent ?? "Markdown",
        systemImage: "doc.text"
      )
      .lineLimit(1)

      if let currentHeading {
        Divider()
          .frame(height: 12)
        Text(currentHeading.title)
          .lineLimit(1)
      }

      Spacer()

      reloadStatus

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

  @ViewBuilder
  private var reloadStatus: some View {
    switch model.reloadState {
    case .watching:
      Label("Live", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
    case .reloaded:
      Label("Reloaded", systemImage: "checkmark.circle")
    case .unavailable:
      Label("Not Watching", systemImage: "exclamationmark.triangle")
    }
  }

  private var currentHeading: MarkdownHeading? {
    model.content.headings.first { $0.id == currentSectionID }
  }

  private var isContentsVisible: Bool {
    splitViewVisibility != .detailOnly
  }

  private func updateCurrentSection() {
    let orderedSections = model.content.sections
    let readingLine: CGFloat = 72

    let passed = orderedSections.compactMap { section -> (String, CGFloat)? in
      guard let top = sectionTops[section.id], top <= readingLine else {
        return nil
      }
      return (section.id, top)
    }
    let candidate = passed.max { $0.1 < $1.1 }?.0
      ?? orderedSections.first {
        guard let top = sectionTops[$0.id] else { return false }
        return top > readingLine
      }?.id

    guard candidate != currentSectionID else { return }
    currentSectionID = candidate
  }

  private func toggleContents() {
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
      splitViewVisibility = isContentsVisible ? .detailOnly : .all
    }
  }
}

private struct OutlineScrollRequest: Equatable {
  let sectionID: String
  let nonce = UUID()
}

private struct MarkdownSectionView: View {
  let section: MarkdownSection

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
        switch block {
        case let .markdown(source):
          StructuredText(source, parser: HTMLBreakMarkdownParser())
            .textual.structuredTextStyle(.gitHub)
            .textual.textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        case let .mermaid(source):
          MermaidDiagramView(source: source)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 26)
  }
}

private struct OutlineSidebar: View {
  let headings: [MarkdownHeading]
  let currentSectionID: String?
  let onSelect: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Contents", systemImage: "list.bullet.indent")
        .font(.headline)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)

      Divider()

      if headings.isEmpty {
        ContentUnavailableView(
          "No Headings",
          systemImage: "text.alignleft",
          description: Text("Add Markdown headings to show an outline.")
        )
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 1) {
            ForEach(headings) { heading in
              Button {
                onSelect(heading.id)
              } label: {
                Text(heading.title)
                  .font(.callout)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.leading, CGFloat(max(heading.level - 1, 0)) * 14)
                  .padding(.horizontal, 9)
                  .padding(.vertical, 4)
                  .contentShape(.rect)
              }
              .buttonStyle(.plain)
              .foregroundStyle(
                currentSectionID == heading.id ? .primary : .secondary
              )
              .background(
                currentSectionID == heading.id
                  ? Color.accentColor.opacity(0.16)
                  : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
              )
              .accessibilityAddTraits(
                currentSectionID == heading.id ? .isSelected : []
              )
            }
          }
          .padding(8)
        }
      }
    }
    .background(.background.secondary)
  }
}

private struct SectionTopPreferenceKey: PreferenceKey {
  static let defaultValue: [String: CGFloat] = [:]

  static func reduce(
    value: inout [String: CGFloat],
    nextValue: () -> [String: CGFloat]
  ) {
    value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
  }
}
