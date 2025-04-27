import SwiftUI

struct ExerciseTypeView: View {
    @State private var exerciseTypes: [ExerciseType] = []
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newType = ""
    @State private var selectedCategoryId: Int32?
    @State private var categories: [Category] = []
    
    var body: some View {
        List {
            ForEach(exerciseTypes) { exerciseType in
                VStack(alignment: .leading) {
                    Text(exerciseType.name)
                        .font(.headline)
                    Text(exerciseType.type)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    let categoriesForExerciceType = DatabaseHelper.shared.getCategoriesForExerciseType(exerciseTypeId: exerciseType.id)
                    if !categoriesForExerciceType.isEmpty {
                        Text("Categories: \(categoriesForExerciceType.map { $0.name }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Exercise Types")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                Form {
                    TextField("Exercise Name", text: $newName)
                    TextField("Exercise Type", text: $newType)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("No Category").tag(nil as Int32?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as Int32?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button("Add Exercise Type") {
                        if !newName.isEmpty && !newType.isEmpty {
                            if let typeId = DatabaseHelper.shared.insertExerciseType(name: newName, type: newType) {
                                if let categoryId = selectedCategoryId {
                                    _ = DatabaseHelper.shared.linkExerciseTypeToCategory(exerciseTypeId: typeId, categoryId: categoryId)
                                }
                                exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
                                newName = ""
                                newType = ""
                                selectedCategoryId = nil
                                showingAddSheet = false
                            }
                        }
                    }
                }
                .navigationTitle("New Exercise Type")
                .navigationBarItems(trailing: Button("Cancel") {
                    showingAddSheet = false
                })
                .onAppear {
                    categories = DatabaseHelper.shared.fetchCategories()
                    exerciseTypes = DatabaseHelper.shared.fetchExerciseTypes()
                }
            }
        }

    }
    

}