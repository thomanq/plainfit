import SwiftUI

enum WeekStart: String, CaseIterable, Identifiable {
  case sunday = "Sunday"
  case monday = "Monday"
  case saturday = "Saturday"

  var id: String { self.rawValue }
}

enum UnitSystem: String, CaseIterable, Identifiable {
  case imperial = "Imperial"
  case metric = "Metric"

  var id: String { self.rawValue }
}

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("weekStart") private var weekStart = WeekStart.sunday
  @AppStorage("unitSystem") private var unitSystem = UnitSystem.imperial

  private let licenseText: String = {
    if let licensePath = Bundle.main.path(forResource: "LICENSE", ofType: ""),
      let content = try? String(contentsOfFile: licensePath, encoding: .utf8)
    {
      return content
    }
    return "License information not available"
  }()

  var body: some View {
    List {
      Section(header: Text("App Settings")) {
        Picker("Week Starts On", selection: $weekStart) {
          ForEach(WeekStart.allCases, id: \.self) { day in
            Text(day.rawValue).tag(day)
          }
        }

        Picker("Unit System", selection: $unitSystem) {
          ForEach(UnitSystem.allCases, id: \.self) { system in
            Text(system.rawValue).tag(system)
          }
        }
      }

      Section(header: Text("About")) {
        NavigationLink(destination: Text("Version 1.0")) {
          Label("Version", systemImage: "info.circle")
        }
        NavigationLink(
          destination: ScrollView {
            Text(licenseText)
              .padding()
          }
          .navigationTitle("License")
          .navigationBarTitleDisplayMode(.inline)
        ) {
          Label("View License", systemImage: "doc.text")
        }
      }
    }
    .navigationTitle("Settings")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          dismiss()
        }
      }
    }
  }
}
