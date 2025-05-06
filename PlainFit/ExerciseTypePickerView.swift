import SwiftUI

struct ExerciseTypePickerView: View {
  let category: Category
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool
  @State private var selectedDate: Date
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var selectedExerciseType: ExerciseType?
  @State private var searchText = ""
  @State private var showingDeleteConfirmation = false
  @State private var exerciseTypeToDelete: ExerciseType?

  init(
    category: Category, selectedDate: Date, showCategoryPicker: Binding<Bool>,
    showEditExerciseSet: Binding<Bool>
  ) {
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

      List {
        ForEach(filteredExerciseTypes, id: \.self) { exerciseType in
          HStack {
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
          }
          .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: {
              selectedExerciseType = exerciseType
              showingAddSheet = true
            }) {
              Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
          }
        }
        .onDelete(perform: deleteExerciseType)
      }
      .navigationTitle(category.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: { showingAddSheet = true }) {
            Image(systemName: "plus")
          }
        }
      }
      .onAppear {
        exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
      }
      .sheet(
        item: $selectedExerciseType,
        onDismiss: {
          exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
          selectedExerciseType = nil
        }
      ) { exerciseType in
        AddExerciseTypeSheet(
          category: category,
          exerciseTypeToEdit: exerciseType)
      }
      .confirmationDialog(
        "Are you sure you want to delete the '\(exerciseTypeToDelete?.name ?? "???")' exercise type?",
        isPresented: $showingDeleteConfirmation, titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let exerciseType = exerciseTypeToDelete {
            _ = DatabaseHelper.shared.deleteExerciseType(id: exerciseType.id)
            exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(
              categoryId: category.id)
          }
        }
        Button("Cancel", role: .cancel) {}
      }
    }
  }

  private func deleteExerciseType(at offsets: IndexSet) {
    for index in offsets {
      exerciseTypeToDelete = filteredExerciseTypes[index]
      showingDeleteConfirmation = true
    }
  }
}
