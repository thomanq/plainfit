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
          .listRowBackground(Color("FieldBackground"))
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
        }.listRowBackground(Color("FieldBackground"))

        Button("Save") {
          if !category.name.isEmpty {
            let updatedCategory = Category(
              id: category.id, name: category.name, iconName: selectedIcon,
              iconColor: selectedColor)
            onSave(updatedCategory)
          }
        }.listRowBackground(Color("FieldBackground"))
      }.scrollContentBackground(.hidden)
        .background(Color("Background"))
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
