import SwiftUI

struct ExerciseTypePickerView: View {
  let category: Category?
  let isFavoritesView: Bool
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool
  @State private var selectedDate: Date
  @State private var exerciseTypes: [ExerciseType] = []
  @State private var showingAddSheet = false
  @State private var showingAddEntry = false
  @State private var selectedExerciseType: ExerciseType
  @State private var searchText = ""
  @State private var showingDeleteConfirmation = false
  @State private var exerciseTypeToDelete: ExerciseType?

  init(
    category: Category? = nil, isFavoritesView: Bool = false, selectedDate: Date, showCategoryPicker: Binding<Bool>,
    showEditExerciseSet: Binding<Bool>
  ) {
    self.category = category
    self.isFavoritesView = isFavoritesView
    self.selectedDate = selectedDate
    _showCategoryPicker = showCategoryPicker
    _showEditExerciseSet = showEditExerciseSet
    self.selectedExerciseType = ExerciseType(id: 0, name: "", type: "")
  }

  var filteredExerciseTypes: [ExerciseType] {
    let base = searchText.isEmpty
      ? exerciseTypes
      : exerciseTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    return base.sorted { lhs, rhs in
      if lhs.isFavorite != rhs.isFavorite {
        return lhs.isFavorite
      }
      return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
  }

  var body: some View {
    VStack {
      SearchBar(text: $searchText)
        .padding()

      List {
        ForEach(filteredExerciseTypes, id: \.self) { exerciseType in
          HStack {
            Text(exerciseType.name)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedExerciseType = exerciseType
                showingAddEntry = true
              }

            Button(action: {
              if let updatedExerciseType = DatabaseHelper.shared.toggleExerciseTypeFavorite(id: exerciseType.id) {
                if let index = exerciseTypes.firstIndex(where: { $0.id == exerciseType.id }) {
                  exerciseTypes[index] = updatedExerciseType
                }
              }
            }) {
              Image(systemName: exerciseType.isFavorite ? "star.fill" : "star")
                .foregroundColor(exerciseType.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
          }.listRowBackground(Color("Background"))
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
      }.listStyle(PlainListStyle())

        .navigationDestination(isPresented: $showingAddEntry) {
          AddExerciseEntryView(
            exerciseType: selectedExerciseType,
            selectedDate: selectedDate,
            showCategoryPicker: $showCategoryPicker,
            showEditExerciseSet: $showEditExerciseSet
          )
        }
        .navigationTitle(isFavoritesView ? "Favorites" : (category?.name ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !isFavoritesView {
              Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
              }
            }
          }
        }
        .onAppear {
          if isFavoritesView {
            exerciseTypes = DatabaseHelper.shared.getFavoriteExerciseTypes()
          } else if let category = category {
            exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
          }
        }
        .sheet(
          isPresented: $showingAddSheet,
          onDismiss: {
            if isFavoritesView {
              exerciseTypes = DatabaseHelper.shared.getFavoriteExerciseTypes()
            } else if let category = category {
              exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(
                categoryId: category.id)
            }
          }
        ) {
          let editCategory = category ?? DatabaseHelper.shared.getCategoriesForExerciseType(
            exerciseTypeId: selectedExerciseType.id
          ).first
          
          if let editCategory = editCategory {
            AddExerciseTypeSheet(
              category: editCategory,
              exerciseTypeToEdit: selectedExerciseType)
          }
        }
        .confirmationDialog(
          "Are you sure you want to delete the '\(exerciseTypeToDelete?.name ?? "???")' exercise type?",
          isPresented: $showingDeleteConfirmation, titleVisibility: .visible
        ) {
          Button("Delete", role: .destructive) {
            if let exerciseType = exerciseTypeToDelete {
              _ = DatabaseHelper.shared.deleteExerciseType(id: exerciseType.id)
              if isFavoritesView {
                exerciseTypes = DatabaseHelper.shared.getFavoriteExerciseTypes()
              } else if let category = category {
                exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(
                  categoryId: category.id)
              }
            }
          }
          Button("Cancel", role: .cancel) {}
        }
    }.background(Color("Background"))
  }

  private func deleteExerciseType(at offsets: IndexSet) {
    for index in offsets {
      exerciseTypeToDelete = filteredExerciseTypes[index]
      showingDeleteConfirmation = true
    }
  }
}
