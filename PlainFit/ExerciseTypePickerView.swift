import SwiftUI

struct ExerciseTypePickerView: View {
  let category: Category
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool
  @State private var selectedDate: Date
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var selectedExerciseType: ExerciseType?
  @State private var isEditMode = false
  @State private var searchText = ""

  init(category: Category,  selectedDate: Date, showCategoryPicker: Binding<Bool>, showEditExerciseSet: Binding<Bool>) {
    self.category = category
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
    _showEditExerciseSet = showEditExerciseSet
  }

  var filteredExerciseTypes: [ExerciseType] {
    if searchText.isEmpty {
      return exerciseTypes
    }
    return exerciseTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    VStack {
      SearchBar(text: $searchText)
        .padding()
      
      List(filteredExerciseTypes, id: \.self) { exerciseType in
        HStack {
          if !isEditMode {
            NavigationLink(
              destination: AddExerciseEntryView(
                exerciseType: exerciseType,
                selectedDate: selectedDate,
                showCategoryPicker: $showCategoryPicker,
                showEditExerciseSet: $showEditExerciseSet
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
}
