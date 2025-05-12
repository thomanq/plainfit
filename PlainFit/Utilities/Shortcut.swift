import AppIntents
import SwiftUI

func copyUrl(_ fileURL: URL, _ savedBookmark: Data?) async -> IntentResultContainer<
  String, Never, Never, Never
> {
  do {
    guard let bookmarkData = savedBookmark else {
      return .result(value: "No bookmark data available")
    }
    var isStale = false
    let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)

    guard !isStale else {
      return .result(value: "Bookmark data is stale")
    }

    guard bookmarkUrl.startAccessingSecurityScopedResource() else {
      return .result(value: "Can't access security scoped resource")
    }

    defer { bookmarkUrl.stopAccessingSecurityScopedResource() }

    try FileManager.default.moveItem(
      at: fileURL, to: bookmarkUrl.appendingPathComponent(fileURL.lastPathComponent))

    return .result(value: "PlainFit data exported")
  } catch {
    return .result(value: "Error: \(error.localizedDescription)")
  }
}

struct ExportToCSVIntent: AppIntent {
  @AppStorage("bookmarkData") var savedBookmark: Data?

  static var title: LocalizedStringResource = "Export to CSV"

  @MainActor
  func perform() async -> some IntentResult & ReturnsValue<String> {
    guard let fileURL = exportToCSVFile() else {
      return .result(value: "Failed to export data")
    }

    return await copyUrl(fileURL, savedBookmark)
  }
}

struct BackupDataBaseIntent: AppIntent {
  @AppStorage("bookmarkData") var savedBookmark: Data?

  static var title: LocalizedStringResource = "Back up database"

  @MainActor
  func perform() async -> some IntentResult & ReturnsValue<String> {
    guard let fileURL = extractDatabaseFile() else {
      return .result(value: "Failed to export data")
    }

    return await copyUrl(fileURL, savedBookmark)
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
    AppShortcut(
      intent: BackupDataBaseIntent(),
      phrases: ["Back up the \(.applicationName) database"],
      shortTitle: "Back up database",
      systemImageName: "square.and.arrow.up"
    )
  }
}
