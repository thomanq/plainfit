import SwiftUI

struct ExerciseTypePickerView: View {
  let category: Category
  @Binding var showCategoryPicker: Bool
  @State private var selectedDate: Date
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false

  init(category: Category,  selectedDate: Date, showCategoryPicker: Binding<Bool>) {
    self.category = category
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
  }

  var body: some View {
    List(exerciseTypes, id: \.self) { exerciseType in
      NavigationLink(
        destination: AddExerciseEntryView(
          exerciseType: exerciseType,
          selectedDate: selectedDate,
          showCategoryPicker: $showCategoryPicker
        )
      ) {
        Text(exerciseType.name)
      }
    }
    .navigationTitle(category.name)
    .toolbar {
      Button(action: { showingAddSheet = true }) {
        Image(systemName: "plus")
      }
    }
    .onAppear {
      exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
    }
    .sheet(
      isPresented: $showingAddSheet,
      onDismiss: {
        exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
      }
    ) {
      AddExerciseTypeSheet(isPresented: $showingAddSheet)
    }
  }
}
