import SwiftUI

struct CategoryPicker: View {
    let selectedDate: Date
    @State private var categories: [Category] = []
    @State private var exerciseTypes: [ExerciseType] = []
    @State private var showingAddSheet = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }
    
    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink(destination: ExerciseTypePickerView(category: category, selectedDate: selectedDate)) {
                    Text(category.name)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Select a category")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
            }
        }
        .onAppear {
            categories = DatabaseHelper.shared.fetchCategories()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExerciseTypeSheet(isPresented: $showingAddSheet)
        }
    }
}
