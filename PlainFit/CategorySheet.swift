import SwiftUI

struct CategorySheet: View {
  @Environment(\.dismiss) var dismiss
  @State var categoryName: String
  let onSave: (String) -> Void

  var body: some View {
    NavigationView {
      Form {
        TextField("Category Name", text: $categoryName)

        Button("Save") {
          if !categoryName.isEmpty {
            onSave(categoryName)
          }
        }
      }
      .navigationTitle("Category")
      .navigationBarItems(
        trailing: Button("Cancel") {
          dismiss()
        })
    }
  }
}
