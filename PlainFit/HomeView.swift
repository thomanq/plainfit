import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static var sqliteDatabase: UTType {
    UTType(exportedAs: "com.sqlite.database")
  }
}

private enum ImportType {
  case csv
  case database

  var contentTypes: [UTType] {
    switch self {
    case .csv:
      return [.commaSeparatedText]
    case .database:
      return [.sqliteDatabase, UTType(filenameExtension: "db")!]
    }
  }
}

struct HomeView: View {
  @Environment(\.colorScheme) var colorScheme

  @State private var fitnessEntries: [FitnessEntry] = []
  @State private var currentDate: Date = Date()
  @State private var categories: [Category] = []
  @State private var selectedCategoryId: Int64?
  @State private var showingCategorySheet = false
  @State private var newCategoryName = ""
  @State private var showCategoryPicker: Bool = false
  @State private var showEditExerciseSet: Bool = false
  @State private var editExerciseType: ExerciseType = ExerciseType(id: 0, name: "", type: "")
  @State private var editExerciseSetId: Int64 = 0
  @State private var showingCalendar = false
  @State private var showingSettings = false
  @State private var showingDeleteConfirmation = false
  @State private var showingImportCsvConfirmation = false
  @State private var setToDelete: Int64? = nil
  @State private var showingImportPicker = false
  @State private var showingRestoreDbConfirmation = false
  @State private var showingRestoreDbPicker = false
  @State private var currentImportType: ImportType?
  @State private var isFileImporterPresented = false

  func exportToCSVFile() -> URL? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let dateSuffix = dateFormatter.string(from: Date())
    let fileName = "PlainFit_\(dateSuffix).csv"

    let csvString = DatabaseHelper.shared.exportToCSV()

    do {
      let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
      return fileURL
    } catch {
      print("Error writing CSV to file: \(error)")
      return nil
    }
  }

  private func exportEntries() {
    if let fileURL = exportToCSVFile() {
      let activityViewController = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first,
        let rootViewController = window.rootViewController
      {
        rootViewController.present(activityViewController, animated: true)
      }
    } else {
      print("Failed to generate CSV file.")
    }
  }

  private func backupDatabase() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let dateSuffix = dateFormatter.string(from: Date())
    let fileName = "PlainFit_\(dateSuffix).db"

    do {
      let databaseURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      ).appendingPathComponent("plainfit.sqlite")

      let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try FileManager.default.copyItem(at: databaseURL, to: temporaryURL)

      let activityViewController = UIActivityViewController(
        activityItems: [temporaryURL],
        applicationActivities: nil
      )
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.windows.first?.rootViewController
      {
        rootViewController.present(activityViewController, animated: true)
      }
    } catch {
      print("Error accessing or copying database file: \(error)")
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {

        VStack(spacing: 16) {
          HStack {
            Button(action: {
              currentDate =
                Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }) {
              Image(systemName: "chevron.left")
                .foregroundColor(.blue)
            }

            Spacer()

            Button(action: {
              showingCalendar = true
            }) {
              Image(systemName: "calendar")
            }
            .padding(.trailing, 8)

            Text(currentDate.formatted(date: .abbreviated, time: .omitted))
              .font(.headline)

            Button(action: {
              currentDate = Date()
            }) {
              Image(systemName: "circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            }
            .padding(.leading, 8)
            Spacer()
            Button(action: {
              currentDate =
                Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }) {
              Image(systemName: "chevron.right")
                .foregroundColor(.blue)
            }

          }
          .padding(.horizontal)

          let groupedEntries = Dictionary(
            grouping: fitnessEntries.sorted(by: { $0.date < $1.date }), by: { $0.setId })
          List {
            ForEach(groupedEntries.keys.sorted(), id: \.self) { setId in
              VStack(alignment: .leading) {

                if let entries: [FitnessEntry] = groupedEntries[setId] {
                  let hasDuration = entries.contains { $0.duration > 0 }
                  let hasReps = entries.contains { $0.reps > 0 }
                  let hasDistance = entries.contains { $0.distance != nil }
                  let hasWeight = entries.contains { $0.weight != nil }

                  VStack(spacing: 0) {
                    if let firstEntry = entries.first,
                      let exerciseTypeBySetId = DatabaseHelper.shared.fetchExerciseTypeBySetId(
                        setId: firstEntry.setId)
                    {
                      Text(exerciseTypeBySetId.name)
                        .font(.headline)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                      Text("#")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .frame(width: 20, alignment: .leading)
                        .foregroundColor(.secondary)
                      if hasDuration {
                        Text("Duration")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                      }
                      if hasReps {
                        Text("Reps")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                      if hasDistance {
                        Text("Distance")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                      if hasWeight {
                        Text("Weight")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(
                      colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Data rows
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                      VStack(alignment: .leading) {
                        HStack {
                          Text("\(index + 1)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)

                          if hasDuration {
                            Text(formatDuration(entry.duration))
                              .font(.system(.body, design: .rounded))
                              .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                          }
                          if hasReps {
                            Text(entry.reps > 0 ? "\(entry.reps)" : "-")
                              .font(.system(.body, design: .rounded))
                              .frame(maxWidth: .infinity, alignment: .leading)
                          }
                          if hasDistance {
                            Text(entry.distance.map { String(format: "%.1f", $0) } ?? "-")
                              .font(.system(.body, design: .rounded))
                              .frame(maxWidth: .infinity, alignment: .leading)
                          }
                          if hasWeight {
                            Text(entry.weight.map { String(format: "%.1f", $0) } ?? "-")
                              .font(.system(.body, design: .rounded))
                              .frame(maxWidth: .infinity, alignment: .leading)
                          }
                        }
                        if let description = entry.description, !description.isEmpty {
                          Text(description)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                            .padding(.leading, 28)
                        }
                        Divider()
                      }
                      .padding(.vertical, 8)
                    }
                  }
                  .padding(.horizontal)
                }
              }.listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    deleteSet(setId: setId)
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {

                  Button(action: {
                    if let exerciseTypeBySetId = DatabaseHelper.shared.fetchExerciseTypeBySetId(
                      setId: setId)
                    {
                      editExerciseType = exerciseTypeBySetId
                    }
                    editExerciseSetId = setId
                    showEditExerciseSet = true
                  }) {
                    Label("Edit", systemImage: "pencil")
                  }
                  .tint(.blue)

                }
            }
          }
          .listStyle(PlainListStyle())
        }
        .navigationDestination(isPresented: $showEditExerciseSet) {
          AddExerciseEntryView(
            exerciseType: editExerciseType,
            selectedDate: currentDate,
            showCategoryPicker: $showCategoryPicker,
            showEditExerciseSet: $showEditExerciseSet,
            setId: editExerciseSetId)
        }
        VStack {
          Spacer()
          Image(systemName: "plus.circle.fill")
            .font(.system(size: 50))
            .foregroundColor(.blue)
            .background(Color.white.clipShape(Circle()))
            .onTapGesture {
              showCategoryPicker = true
            }
            .padding(.bottom, 16)
        }
        .navigationDestination(isPresented: $showCategoryPicker) {
          CategoryPicker(
            selectedDate: currentDate, showCategoryPicker: $showCategoryPicker,
            showEditExerciseSet: $showEditExerciseSet, )
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("PlainFit Fitness Tracker")
            .font(.headline)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button(action: { showingSettings = true }) {
              Label("Settings", systemImage: "gear")
            }
            Menu {
              Button(action: {
                showingImportCsvConfirmation = true
              }) {
                Label("Import CSV", systemImage: "square.and.arrow.down")
              }
              Button(action: exportEntries) {
                Label("Export to CSV", systemImage: "square.and.arrow.up")
              }
              Button(action: {
                showingRestoreDbConfirmation = true
              }) {
                Label("Restore DB", systemImage: "tray.and.arrow.down")
              }
              Button(action: backupDatabase) {
                Label("Back up DB", systemImage: "tray.and.arrow.up")
              }
            } label: {
              Label("Import / Export", systemImage: "arrow.left.arrow.right")
            }
          } label: {
            Image(systemName: "line.horizontal.3")
          }
        }
      }
      .onChange(of: currentDate) { oldValue, newValue in
        fitnessEntries = DatabaseHelper.shared.fetchEntries(for: newValue)
      }
      .onAppear {
        fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
        categories = DatabaseHelper.shared.fetchCategories()
      }
      .navigationBarTitleDisplayMode(.inline)
      .confirmationDialog(
        "Are you sure you want to delete this exercise set?",
        isPresented: $showingDeleteConfirmation,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let setId = setToDelete {
            DatabaseHelper.shared.deleteEntriesBySetId(setId: setId)
            fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
          }
          setToDelete = nil
        }
        Button("Cancel", role: .cancel) {}
      }
      .confirmationDialog(
        "Are you sure you want to import the CSV? This will erase all current data and replace it with the content of the file.",
        isPresented: $showingImportCsvConfirmation,
        titleVisibility: .visible
      ) {
        Button(
          "Import", role: .destructive
        ) {
          isFileImporterPresented = true
          currentImportType = .csv
        }

        Button("Cancel", role: .cancel) {}
      }
      .confirmationDialog(
        "Are you sure you want to restore the database? This will erase all current data in the app.",
        isPresented: $showingRestoreDbConfirmation,
        titleVisibility: .visible
      ) {
        Button("Restore", role: .destructive) {
          isFileImporterPresented = true
          currentImportType = .database
        }
        Button("Cancel", role: .cancel) {}
      }
    }
    .sheet(isPresented: $showingCalendar) {
      CalendarView(selectedDate: $currentDate)
    }
    .sheet(isPresented: $showingSettings) {
      NavigationView {
        SettingsView()
      }
    }
    .fileImporter(
      isPresented: $isFileImporterPresented,
      allowedContentTypes: currentImportType?.contentTypes ?? []
    ) { result in
      switch result {
      case .success(let url):
        if let importType = currentImportType {
          switch importType {
          case .csv:
            do {
              let csvString = try String(contentsOf: url, encoding: .utf8)
              let success = DatabaseHelper.shared.importFromCSV(csvString: csvString)
              if success {
                fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
              }
            } catch {
              print("Error reading CSV file")
            }
          case .database:
            if DatabaseHelper.shared.restoreDatabase(from: url) {
              fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
            }
          }
        }
      case .failure:
        print("Failed to import file")
        break
      }
      DispatchQueue.main.async {
        currentImportType = nil
        isFileImporterPresented = false
      }
    }
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  private func deleteSet(setId: Int64) {
    showingDeleteConfirmation = true
    setToDelete = setId
  }
}
