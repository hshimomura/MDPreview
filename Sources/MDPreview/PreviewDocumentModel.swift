import Darwin
import Foundation
import Observation

@MainActor
@Observable
final class PreviewDocumentModel {
  enum ReloadState: Equatable {
    case watching
    case reloaded(Date)
    case unavailable
  }

  private(set) var text: String
  private(set) var content: MarkdownContent
  private(set) var reloadState: ReloadState

  let fileURL: URL?

  init(text: String, fileURL: URL?) {
    self.text = text
    self.fileURL = fileURL
    content = MarkdownContentParser.parse(text)
    reloadState = fileURL == nil ? .unavailable : .watching
  }

  func monitorFile() async {
    guard let fileURL else { return }
    var knownSignature = FileSignature(fileURL: fileURL)

    while !Task.isCancelled {
      do {
        try await Task.sleep(for: .milliseconds(400))
      } catch {
        return
      }

      guard let signature = FileSignature(fileURL: fileURL) else {
        reloadState = .unavailable
        continue
      }
      guard signature != knownSignature else {
        if reloadState == .unavailable {
          reloadState = .watching
        }
        continue
      }
      knownSignature = signature

      do {
        let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
        guard let newText = String(data: data, encoding: .utf8) else {
          reloadState = .unavailable
          continue
        }
        guard newText != text else {
          reloadState = .watching
          continue
        }
        text = newText
        content = MarkdownContentParser.parse(newText)
        reloadState = .reloaded(Date())
      } catch {
        reloadState = .unavailable
      }
    }
  }
}

private struct FileSignature: Equatable {
  let device: UInt64
  let inode: UInt64
  let size: Int64
  let modifiedSeconds: Int64
  let modifiedNanoseconds: Int64

  init?(fileURL: URL) {
    var metadata = stat()
    guard lstat(fileURL.path, &metadata) == 0 else { return nil }
    device = UInt64(metadata.st_dev)
    inode = UInt64(metadata.st_ino)
    size = metadata.st_size
    modifiedSeconds = Int64(metadata.st_mtimespec.tv_sec)
    modifiedNanoseconds = Int64(metadata.st_mtimespec.tv_nsec)
  }
}
