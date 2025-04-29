import SwiftUI

struct CategoryPicker: View {
    @Environment(\.presentationMode) var presentationMode
    let selectedDate: Date
    @State private var categories: [Category] = []
    @State private var exerciseTypes: [ExerciseType] = []
    @State private var showingAddSheet = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }
    
    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink(destination: ExerciseTypePickerView(
                    category: category,
                    categoryPickerPresentationMode: presentationMode
                )) {
                    Text(category.name)
                        .font(.headline)
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
}
