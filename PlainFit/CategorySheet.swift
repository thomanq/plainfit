import SwiftUI

struct CategorySheet: View {
  @Environment(\.dismiss) var dismiss
  @State var category: Category
  @State private var selectedIcon: String
  @State private var selectedColor: String
  @State private var isIconPickerPresented: Bool = false
  let onSave: (Category) -> Void

  init(category: Category, onSave: @escaping (Category) -> Void) {
    self._category = State(initialValue: category)
    self._selectedIcon = State(initialValue: category.iconName)
    self._selectedColor = State(initialValue: category.iconColor)
    self.onSave = onSave
  }

  var body: some View {
    NavigationView {
      Form {
        TextField("Category Name", text: $category.name)
        HStack {
          Text("Icon:")
          Image(systemName: selectedIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(Color(hex: selectedColor))
          Spacer()
          Button("Pick Icon") {
            isIconPickerPresented = true
          }
        }

        Button("Save") {
          if !category.name.isEmpty {
            let updatedCategory = Category(
              id: category.id, name: category.name, iconName: selectedIcon,
              iconColor: selectedColor)
            onSave(updatedCategory)
          }
        }
      }
      .navigationTitle("Category")
      .navigationBarItems(
        trailing: Button("Cancel") {
          dismiss()
        }
      )
      .sheet(isPresented: $isIconPickerPresented) {
        IconPicker(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
      }
    }
  }
}
