import SwiftUI

struct CategoryPicker: View {
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool

  let selectedDate: Date
  @State private var categories: [Category] = []
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var searchText = ""

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
          ForEach(categories) { category in
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
          }
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
        exerciseTypes = DatabaseHelper.shared.fetchAllExerciseTypes()
      }
      .sheet(isPresented: $showingAddSheet) {
        AddExerciseTypeSheet(isPresented: $showingAddSheet)
      }
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
