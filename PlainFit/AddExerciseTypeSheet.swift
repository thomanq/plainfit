import SwiftUI

struct AddExerciseTypeSheet: View {
  @Environment(\.dismiss) var dismiss
  @State private var newName = ""
  @State private var newType = ""
  @State private var selectedCategoryId: Int64?
  @State private var categories: [Category] = []
  @State private var selectedTypes: Set<String> = []
  @State private var showingNewCategorySheet = false
  @State private var newCategoryName = ""
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var showingDeleteConfirmation = false

  private let availableTypes = ["weight", "reps", "distance", "time"]
  let exerciseTypeToEdit: ExerciseType?

  init(
    defaultCategoryId: Int64? = nil,
    exerciseTypeToEdit: ExerciseType? = nil
  ) {
    _selectedCategoryId = State(initialValue: defaultCategoryId)
    self.exerciseTypeToEdit = exerciseTypeToEdit

    if let editType = exerciseTypeToEdit {
      _newName = State(initialValue: editType.name)
      _selectedTypes = State(
        initialValue: Set(editType.type.split(separator: ",").map(String.init)))
      _newType = State(initialValue: editType.type)
    }
  }

  var body: some View {
    NavigationView {
      Form {
        TextField("Exercise Name", text: $newName)

        Section(header: Text("Exercise Type")) {
          ForEach(availableTypes, id: \.self) { type in
            Toggle(
              isOn: Binding(
                get: { selectedTypes.contains(type) },
                set: { isSelected in
                  if isSelected {
                    selectedTypes.insert(type)
                  } else {
                    selectedTypes.remove(type)
                  }
                  newType = selectedTypes.sorted().joined(separator: ",")
                }
              )
            ) {
              Text(type.capitalized)
            }
          }
        }

        HStack {
          Picker("Category", selection: $selectedCategoryId) {
            Text("No Category").tag(nil as Int64?)
            ForEach(categories) { category in
              Text(category.name).tag(category.id as Int64?)
            }
          }
          .pickerStyle(.menu)

          Button(action: { showingNewCategorySheet = true }) {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.blue)
          }
        }
        Section {
          Button(exerciseTypeToEdit == nil ? "Add Exercise Type" : "Edit Exercise Type") {
            if newName.isEmpty {
              errorMessage = "Please enter an exercise name"
              showError = true
            } else if selectedTypes.isEmpty {
              errorMessage = "Please select at least one exercise type"
              showError = true
            } else if selectedCategoryId == nil {
              errorMessage = "Please select a category"
              showError = true
            } else {
              if let exerciseType = exerciseTypeToEdit {
                _ = DatabaseHelper.shared.updateExerciseType(
                  id: exerciseType.id, name: newName, type: newType)
                if let categoryId = selectedCategoryId {
                  _ = DatabaseHelper.shared.updateExerciseTypeCategory(
                    exerciseTypeId: exerciseType.id, categoryId: categoryId)
                }
              } else {
                if let typeId = DatabaseHelper.shared.insertExerciseType(
                  name: newName, type: newType)
                {
                  _ = DatabaseHelper.shared.linkExerciseTypeToCategory(
                    exerciseTypeId: typeId, categoryId: selectedCategoryId!)
                }
              }
              newName = ""
              newType = ""
              selectedCategoryId = nil
              selectedTypes.removeAll()
              dismiss()
            }
          }
        }

        if let exerciseType = exerciseTypeToEdit {
          Section {
            Button("Delete Exercise Type", role: .destructive) {
              showingDeleteConfirmation = true
            }
            .confirmationDialog(
              "Are you sure you want to delete the '\(exerciseType.name)' exercise type",
              isPresented: $showingDeleteConfirmation, titleVisibility: .visible
            ) {
              Button("Delete", role: .destructive) {
                _ = DatabaseHelper.shared.deleteExerciseType(id: exerciseType.id)
                dismiss()
              }
              Button("Cancel", role: .cancel) {}
            }
          }
        }
      }
      .navigationTitle(exerciseTypeToEdit == nil ? "New Exercise Type" : "Edit Exercise Type")
      .alert("Error", isPresented: $showError) {
        Button("OK", role: .cancel) {
          showError = false
        }
      } message: {
        Text(errorMessage)
      }
      .navigationBarItems(
        trailing: Button("Cancel") {
          dismiss()
        }
      )
      .sheet(isPresented: $showingNewCategorySheet) {
        CategorySheet(
          categoryName: newCategoryName,
          onSave: { name in
            if DatabaseHelper.shared.insertCategory(name: name) != nil {
              categories = DatabaseHelper.shared.fetchCategories()
              newCategoryName = ""
              showingNewCategorySheet = false
            }
          }
        )
      }
      .onAppear {
        categories = DatabaseHelper.shared.fetchCategories()
      }
    }
  }
}
