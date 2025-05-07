import SwiftUI

struct CategoryPicker: View {
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool

  let selectedDate: Date
  @State private var searchText = ""
  @State private var categories: [Category] = []
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var categoryToDelete: Category?
  @State private var exerciseTypeToDelete: ExerciseType?
  @State private var selectedCategory: Category
  @State private var selectedExerciseType: ExerciseType
  @State private var showAddExerciseEntry = false
  @State private var showEditExerciseType = false
  @State private var showAddExerciseType = false
  @State private var showCategoryDeleteConfirmation = false
  @State private var showEditCategory = false
  @State private var showExerciseTypeDeleteConfirmation = false
  @State private var showExerciseTypePicker = false

  init(selectedDate: Date, showCategoryPicker: Binding<Bool>, showEditExerciseSet: Binding<Bool>) {
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
    _showEditExerciseSet = showEditExerciseSet
    self.selectedCategory = Category(id: 0, name: "", iconName: "", iconColor: "")
    self.selectedExerciseType = ExerciseType(id: 0, name: "", type: "")
  }

  var filteredExercises: [ExerciseType] {
    exerciseTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    VStack {
      SearchBar(text: $searchText)
        .padding()
      List {
        if searchText.isEmpty {
          ForEach(categories, id: \.self) { category in
            Text(category.name)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedCategory = category
                showExerciseTypePicker = true
              }
              .swipeActions(edge: .leading) {
                Button(action: {
                  selectedCategory = category
                  showEditCategory = true
                }) {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
              }
          }
          .onDelete(perform: deleteCategory)
        } else {
          ForEach(filteredExercises, id: \.self) { exerciseType in
            Text(exerciseType.name)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedExerciseType = exerciseType
                showAddExerciseEntry = true
              }
              .swipeActions(edge: .leading) {
                Button(action: {
                  selectedExerciseType = exerciseType
                  showEditExerciseType = true
                  if let firstCategory = DatabaseHelper.shared.getCategoriesForExerciseType(
                    exerciseTypeId: exerciseType.id
                  ).first {
                    selectedCategory = firstCategory
                  }
                }) {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
              }
          }.onDelete(perform: deleteExerciseType)
        }
      }
      .sheet(
        isPresented: $showEditCategory,
      ) {
        CategorySheet(
          category: selectedCategory,
          onSave: { updatedCategory in
            _ = DatabaseHelper.shared.updateCategory(updatedCategory)
            categories = DatabaseHelper.shared.fetchCategories()
            showEditCategory = false
          }
        )
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(searchText.isEmpty ? "Categories" : "Filtered Exercises")
            .font(.headline)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showAddExerciseType = true }) {
            Image(systemName: "plus")
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        categories = DatabaseHelper.shared.fetchCategories()
        exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
      }
      .sheet(isPresented: $showAddExerciseType) {
        AddExerciseTypeSheet()
      }
      .sheet(
        isPresented: $showEditExerciseType,
        onDismiss: {
          exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
        }
      ) {
        AddExerciseTypeSheet(
          category: selectedCategory,
          exerciseTypeToEdit: selectedExerciseType)
      }
      .confirmationDialog(
        "Are you sure you want to delete the '\(categoryToDelete?.name ?? "???")' category?",
        isPresented: $showCategoryDeleteConfirmation, titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let category = categoryToDelete {
            _ = DatabaseHelper.shared.deleteCategory(id: category.id)
            categories = DatabaseHelper.shared.fetchCategories()
          }
        }
        Button("Cancel", role: .cancel) {}
      }
      .confirmationDialog(
        "Are you sure you want to delete the '\(categoryToDelete?.name ?? "???")' exercise type?",
        isPresented: $showExerciseTypeDeleteConfirmation, titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let exerciseType = exerciseTypeToDelete {
            _ = DatabaseHelper.shared.deleteExerciseType(id: exerciseType.id)
            exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
          }
        }
        Button("Cancel", role: .cancel) {}
      }
    }
    .navigationDestination(isPresented: $showExerciseTypePicker) {
      ExerciseTypePickerView(
        category: selectedCategory,
        selectedDate: selectedDate,
        showCategoryPicker: $showCategoryPicker,
        showEditExerciseSet: $showEditExerciseSet
      )
    }
    .navigationDestination(isPresented: $showAddExerciseEntry) {
      AddExerciseEntryView(
        exerciseType: selectedExerciseType,
        selectedDate: selectedDate,
        showCategoryPicker: $showCategoryPicker,
        showEditExerciseSet: $showEditExerciseSet
      )
    }
  }

  private func deleteCategory(at offsets: IndexSet) {
    for index in offsets {
      categoryToDelete = categories[index]
      showCategoryDeleteConfirmation = true
    }
  }
  private func deleteExerciseType(at offsets: IndexSet) {
    for index in offsets {
      exerciseTypeToDelete = filteredExercises[index]
      showExerciseTypeDeleteConfirmation = true
    }
  }
}

struct SearchBar: View {
  @Binding var text: String

  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.gray)
      TextField("Search exercises...", text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
  }
}
