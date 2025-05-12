import AppIntents
import SwiftUI

struct ExportToCSVIntent: AppIntent {
  @AppStorage("bookmarkData") var savedBookmark: Data?

  static var title: LocalizedStringResource = "Export to CSV"

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    guard let fileURL = exportToCSVFile() else {
      return .result(value: "Failed to export data")
    }

    do {
      guard let bookmarkData = savedBookmark else {
        return .result(value: "No bookmark data available")
      }
      var isStale = false
      let downloadsUrl = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)

      guard !isStale else {
        return .result(value: "Bookmark data is stale")
      }

      guard downloadsUrl.startAccessingSecurityScopedResource() else {
        return .result(value: "Can't access security scoped resource")
      }

      defer { downloadsUrl.stopAccessingSecurityScopedResource() }

      try FileManager.default.moveItem(
        at: fileURL, to: downloadsUrl.appendingPathComponent(fileURL.lastPathComponent))

      return .result(value: "PlainFit data exported to CSV")
    } catch {
      return .result(value: "Error: \(error.localizedDescription)")
    }
  }
}

struct PlainFitShortcuts: AppShortcutsProvider {
  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ExportToCSVIntent(),
      phrases: ["Export my \(.applicationName) data to CSV"],
      shortTitle: "Export to CSV",
      systemImageName: "square.and.arrow.up"
    )
  }
}
