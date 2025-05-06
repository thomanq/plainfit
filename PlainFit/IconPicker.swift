import SwiftUI

struct IconPicker: View {
  @Binding var selectedIcon: String
  @Binding var selectedColor: String
  @Environment(\.dismiss) var dismiss

  @State private var icons: [String] = []
  @State private var tempSelectedIcon: String
  @State private var tempSelectedColor: Color

  init(
    selectedIcon: Binding<String>,
    selectedColor: Binding<String>
  ) {
    _tempSelectedIcon = State(initialValue: selectedIcon.wrappedValue)
    _tempSelectedColor = State(initialValue: Color(hex: selectedColor.wrappedValue))
    _selectedIcon = selectedIcon
    _selectedColor = selectedColor
  }

  let columns = [GridItem(.adaptive(minimum: 50))]

  var body: some View {
    NavigationView {
      VStack {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 20) {
            ForEach(icons, id: \.self) { icon in
              ZStack {
                if tempSelectedIcon == icon {
                  Circle()
                    .stroke(tempSelectedColor, lineWidth: 3)
                    .frame(width: 50, height: 50)
                }
                Button(action: {
                  tempSelectedIcon = icon
                }) {
                  Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding()
                    .foregroundColor(tempSelectedColor)
                }
              }
            }
          }
          .padding()
        }

        ColorPicker("Pick a Color", selection: $tempSelectedColor)
          .padding()

        Spacer()
      }
      .navigationTitle("Pick an Icon")
      .navigationBarItems(
        leading: Button("Cancel") {
          dismiss()
        },
        trailing: Button("Select") {
          selectedIcon = tempSelectedIcon
          selectedColor = tempSelectedColor.toHex()
          dismiss()
        }
        .disabled(tempSelectedIcon == nil)
      )
      .onAppear {
        loadIcons()
      }
    }
  }

  private func loadIcons() {
    if let url = Bundle.main.url(forResource: "icons", withExtension: "txt"),
      let content = try? String(contentsOf: url)
    {
      icons = content.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
  }
}

extension Color {
  init(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgba: UInt64 = 0

    if !Scanner(string: hexSanitized).scanHexInt64(&rgba) {
      self = .black
      return
    }

    let red = Double((rgba >> 24) & 0xFF) / 255.0
    let green = Double((rgba >> 16) & 0xFF) / 255.0
    let blue = Double((rgba >> 8) & 0xFF) / 255.0
    let opacity = Double(rgba & 0xFF) / 255.0

    self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }

  func toHex() -> String {
    let uiColor = UIColor(self)
    guard let components = uiColor.cgColor.components, components.count >= 4 else {
      return "#000000FF"
    }
    let red = Int(components[0] * 255.0)
    let green = Int(components[1] * 255.0)
    let blue = Int(components[2] * 255.0)
    let opacity = Int(components[3] * 255.0)
    return String(format: "#%02X%02X%02X%02X", red, green, blue, opacity)
  }
}
