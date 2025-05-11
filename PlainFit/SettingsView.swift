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

enum ThemeOptions: String, CaseIterable, Identifiable {
  case system = "System"
  case light = "Light"
  case dark = "Dark"

  var id: String { self.rawValue }
}

func toScheme(_ themeOption: ThemeOptions) -> ColorScheme {
  switch themeOption {
  case ThemeOptions.system:
    return UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark
      ? ColorScheme.dark : ColorScheme.light
  case ThemeOptions.light:
    return ColorScheme.light
  case ThemeOptions.dark:
    return ColorScheme.dark
  }
}

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("weekStart") private var weekStart = WeekStart.sunday
  @AppStorage("unitSystem") private var unitSystem = UnitSystem.imperial
  @AppStorage("themeOption") private var themeOption = ThemeOptions.system

  @State private var isVersionPresented = false
  @State private var isLicensePresented = false

  private let licenseText: String = {
    if let licensePath = Bundle.main.path(forResource: "LICENSE", ofType: ""),
      let content = try? String(contentsOfFile: licensePath, encoding: .utf8)
    {
      return content
    }
    return "License information not available"
  }()

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("App Settings")) {
          Picker("Theme", selection: $themeOption) {
            ForEach(ThemeOptions.allCases, id: \.self) { theme in
              Text(theme.rawValue).tag(theme)
            }
          }
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
          Button(action: { isVersionPresented = true }) {
            Label("Version", systemImage: "info.circle")
          }
          .navigationDestination(isPresented: $isVersionPresented) {
            VStack {
              Text("Version 1.0")
              Link(
                "https://github.com/thomanq/plainfit",
                destination: URL(string: "https://github.com/thomanq/plainfit")!)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, ).background(Color("Background"))
          }

          Button(action: { isLicensePresented = true }) {
            Label("View License", systemImage: "doc.text")
          }
          .navigationDestination(isPresented: $isLicensePresented) {
            ScrollView {
              Text(licenseText)
                .padding()
            }.background(Color("Background"))
              .navigationTitle("License")
              .navigationBarTitleDisplayMode(.inline)
          }
        }
      }.scrollContentBackground(.hidden)
        .background(Color("Background"))
        .navigationTitle("Settings")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
    }
    .preferredColorScheme(toScheme(themeOption))
  }
}
