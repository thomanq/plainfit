import SwiftUI

struct AddExerciseTypeSheet: View {
  @Environment(\.dismiss) var dismiss
  @State private var newName = ""
  @State private var newType = ""
  @State private var category: Category?
  @State private var categories: [Category] = []
  @State private var selectedTypes: Set<String> = []
  @State private var showingNewCategorySheet = false
  @State private var newCategoryName = ""
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var showingDeleteConfirmation = false
  @State private var iconType: String
  @State private var selectedIcon: String
  @State private var selectedColor: String
  @State private var isIconPickerPresented: Bool = false

  private let availableTypes = ["weight", "reps", "distance", "time"]
  let exerciseTypeToEdit: ExerciseType?

  init(
    category: Category? = nil,
    exerciseTypeToEdit: ExerciseType? = nil
  ) {
    _category = State(initialValue: category)
    self.exerciseTypeToEdit = exerciseTypeToEdit

    if exerciseTypeToEdit == nil || exerciseTypeToEdit?.iconName == nil
      || exerciseTypeToEdit?.iconColor == nil
    {
      _iconType = State(initialValue: "default")
      _selectedIcon = State(initialValue: "circle.fill")
      _selectedColor = State(initialValue: Color(.blue).toHex())
    } else {
      _iconType = State(initialValue: "custom")
      _selectedIcon = State(initialValue: exerciseTypeToEdit?.iconName ?? "circle.fill")
      _selectedColor = State(initialValue: exerciseTypeToEdit?.iconColor ?? Color(.blue).toHex())
    }

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

        Section(header: Text("Category")) {
          HStack {
            Picker("Category", selection: $category) {
              Text("No Category").tag(nil as Category?)
              ForEach(categories) { category in
                Text(category.name).tag(category as Category?)
              }
            }
            .pickerStyle(.menu)

            Button(action: { showingNewCategorySheet = true }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
            }
          }
        }

        Section(header: Text("Icon")) {
          Picker("Icon", selection: $iconType) {
            Text("From category").tag("default")
            Text("Custom").tag("custom")
          }
          .pickerStyle(.menu)

          if iconType == "custom" {
            HStack {
              Text("Selected Icon:")

              Image(systemName: selectedIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(Color(hex: selectedColor))
              Spacer()
              Button("Pick Icon") {
                isIconPickerPresented = true
              }
            }
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
            } else if category == nil {
              errorMessage = "Please select a category"
              showError = true
            } else {
              if let exerciseType = exerciseTypeToEdit {
                let updatedExerciseType = ExerciseType(
                  id: exerciseType.id,
                  name: newName,
                  type: newType,
                  iconName: iconType == "default" ? nil : selectedIcon,
                  iconColor: iconType == "default" ? nil : selectedColor
                )
                _ = DatabaseHelper.shared.updateExerciseType(updatedExerciseType)
                if let category = category {
                  _ = DatabaseHelper.shared.updateExerciseTypeCategory(
                    exerciseTypeId: exerciseType.id, categoryId: category.id
                  )
                }
              } else {
                if let exerciseType = DatabaseHelper.shared.insertExerciseType(
                  PartialExerciseType(
                    name: newName,
                    type: newType,
                    iconName: iconType == "default" ? nil : selectedIcon,
                    iconColor: iconType == "default" ? nil : selectedColor
                  )
                ) {
                  if let category = category {
                    _ = DatabaseHelper.shared.linkExerciseTypeToCategory(
                      exerciseTypeId: exerciseType.id, categoryId: category.id
                    )
                  }
                }
              }
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
      }.scrollContentBackground(.hidden)
        .background(Color("Background"))
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
            category: Category(
              id: 0, name: newCategoryName, iconName: "circle.fill", iconColor: Color(.blue).toHex()
            ),
            onSave: { category in
              let partialCategory = PartialCategory(
                name: category.name,
                iconName: category.iconName,
                iconColor: category.iconColor
              )
              if DatabaseHelper.shared.insertCategory(partialCategory) != nil {
                categories = DatabaseHelper.shared.fetchCategories()
                newCategoryName = ""
                showingNewCategorySheet = false
              }
            }
          )
        }
        .sheet(isPresented: $isIconPickerPresented) {
          IconPicker(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
        }
        .onAppear {
          categories = DatabaseHelper.shared.fetchCategories()
        }
    }
  }
}
