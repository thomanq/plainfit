import SwiftUI

struct AddExerciseTypeSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    @State private var newName = ""
    @State private var newType = ""
    @State private var selectedCategoryId: Int32?
    @State private var categories: [Category] = []
    @State private var selectedTypes: Set<String> = []
    @State private var showingNewCategorySheet = false
    @State private var newCategoryName = ""
    
    private let availableTypes = ["weight", "reps", "distance", "time"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Exercise Name", text: $newName)
                
                Section(header: Text("Exercise Type")) {
                    ForEach(availableTypes, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { selectedTypes.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTypes.insert(type)
                                } else {
                                    selectedTypes.remove(type)
                                }
                                newType = selectedTypes.sorted().joined(separator: ",")
                            }
                        )) {
                            Text(type.capitalized)
                        }
                    }
                }
                
                HStack {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("No Category").tag(nil as Int32?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as Int32?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: { showingNewCategorySheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Button("Add Exercise Type") {
                    if !newName.isEmpty && !selectedTypes.isEmpty {
                        if let typeId = DatabaseHelper.shared.insertExerciseType(name: newName, type: newType) {
                            if let categoryId = selectedCategoryId {
                                _ = DatabaseHelper.shared.linkExerciseTypeToCategory(exerciseTypeId: typeId, categoryId: categoryId)
                            }
                            newName = ""
                            newType = ""
                            selectedCategoryId = nil
                            selectedTypes.removeAll()
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("New Exercise Type")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .sheet(isPresented: $showingNewCategorySheet) {
                NavigationView {
                    Form {
                        TextField("Category Name", text: $newCategoryName)
                        
                        Button("Add Category") {
                            if !newCategoryName.isEmpty {
                                if let _ = DatabaseHelper.shared.insertCategory(name: newCategoryName) {
                                    categories = DatabaseHelper.shared.fetchCategories()
                                    newCategoryName = ""
                                    showingNewCategorySheet = false
                                }
                            }
                        }
                    }
                    .navigationTitle("New Category")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingNewCategorySheet = false
                    })
                }
            }
            .onAppear {
                categories = DatabaseHelper.shared.fetchCategories()
            }
        }
    }
}