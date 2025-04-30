import SwiftUI

struct CategoryPicker: View {
  @Binding var showCategoryPicker: Bool

  let selectedDate: Date
  @State private var categories: [Category] = []
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false

  init(selectedDate: Date, showCategoryPicker: Binding<Bool>) {
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
  }

  var body: some View {
    VStack {
      List(categories) { category in
        NavigationLink(
          destination: ExerciseTypePickerView(
            category: category,
            selectedDate: selectedDate,
            showCategoryPicker: $showCategoryPicker
          )
        ) {
          Text(category.name)
            .font(.headline)
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Select a category")
            .font(.headline)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showingAddSheet = true }) {
            Image(systemName: "plus")
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        categories = DatabaseHelper.shared.fetchCategories()
      }
      .sheet(isPresented: $showingAddSheet) {
        AddExerciseTypeSheet(isPresented: $showingAddSheet)
      }
    }
  }
}
