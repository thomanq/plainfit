import SwiftUI

struct ExerciseTypePickerView: View {
  let category: Category
  @Binding var showCategoryPicker: Bool
  @State private var selectedDate: Date
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var selectedExerciseType: ExerciseType?
  @State private var isEditMode = false

  init(category: Category,  selectedDate: Date, showCategoryPicker: Binding<Bool>) {
    self.category = category
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
  }

  var body: some View {
    List(exerciseTypes, id: \.self) { exerciseType in
      HStack {
        if !isEditMode {
          NavigationLink(
            destination: AddExerciseEntryView(
              exerciseType: exerciseType,
              selectedDate: selectedDate,
              showCategoryPicker: $showCategoryPicker
            )
          ) {
            Text(exerciseType.name)
          }
        } else {
          Text(exerciseType.name)
          Spacer()
          Button(action: {
            selectedExerciseType = exerciseType
            showingAddSheet = true
          }) {
            Image(systemName: "pencil")
          }
        }
      }
    }
    .navigationTitle(category.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button(action: { isEditMode.toggle() }) {
          Image(systemName: isEditMode ? "xmark" : "pencil")
        }
        Button(action: { showingAddSheet = true }) {
          Image(systemName: "plus")
        }
      }
    }
    .onAppear {
      exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
    }
    .sheet(
      isPresented: $showingAddSheet,
      onDismiss: {
        exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
        selectedExerciseType = nil
      }
    ) {
      AddExerciseTypeSheet(isPresented: $showingAddSheet, defaultCategoryId: category.id, exerciseTypeToEdit: selectedExerciseType)
    }
  }
}
