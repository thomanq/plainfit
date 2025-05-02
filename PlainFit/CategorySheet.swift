import SwiftUI

struct CategorySheet: View {
  @Environment(\.dismiss) var dismiss
  @Binding var isPresented: Bool
  @State var categoryName: String
  let onSave: (String) -> Void

  var body: some View {
    NavigationView {
      Form {
        TextField("Category Name", text: $categoryName)

        Button("Save") {
          if !categoryName.isEmpty {
            onSave(categoryName)
            isPresented = false
          }
        }
      }
      .navigationTitle("Category")
      .navigationBarItems(
        trailing: Button("Cancel") {
          isPresented = false
        })
    }
  }
}
