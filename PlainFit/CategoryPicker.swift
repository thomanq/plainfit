import SwiftUI

struct CategoryPicker: View {
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool

  let selectedDate: Date
  @State private var categories: [Category] = []
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var searchText = ""
  @State private var selectedCategory: Category?
  @State private var showingDeleteConfirmation = false
  @State private var categoryToDelete: Category?

  init(selectedDate: Date, showCategoryPicker: Binding<Bool>, showEditExerciseSet: Binding<Bool>) {
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
    _showEditExerciseSet = showEditExerciseSet
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
            NavigationLink(
              destination: ExerciseTypePickerView(
                category: category,
                selectedDate: selectedDate,
                showCategoryPicker: $showCategoryPicker,
                showEditExerciseSet: $showEditExerciseSet
              )
            ) {
              Text(category.name)
            }
            .swipeActions(edge: .leading) {
              Button(action: {
                selectedCategory = category
              }) {
                Label("Edit", systemImage: "pencil")
              }
              .tint(.blue)
            }
          }
          .onDelete(perform: deleteCategory)
        } else {
          ForEach(filteredExercises, id: \.self) { exerciseType in
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
        }
      }
      .sheet(
        item: $selectedCategory,
        onDismiss: {
          selectedCategory = nil
        }
      ) { category in
        CategorySheet(
          category: category,
          onSave: { updatedCategory in
            _ = DatabaseHelper.shared.updateCategory(updatedCategory)
            categories = DatabaseHelper.shared.fetchCategories()
            selectedCategory = nil
          }
        )
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(searchText.isEmpty ? "Categories" : "Filtered Exercises")
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
        exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
      }
      .sheet(isPresented: $showingAddSheet) {
        AddExerciseTypeSheet()
      }
      .confirmationDialog(
        "Are you sure you want to delete the '\(categoryToDelete?.name ?? "???")' category?",
        isPresented: $showingDeleteConfirmation, titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let category = categoryToDelete {
            _ = DatabaseHelper.shared.deleteCategory(id: category.id)
            categories = DatabaseHelper.shared.fetchCategories()
          }
        }
        Button("Cancel", role: .cancel) {}
      }
    }
  }

  private func deleteCategory(at offsets: IndexSet) {
    for index in offsets {
      categoryToDelete = categories[index]
      showingDeleteConfirmation = true
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
