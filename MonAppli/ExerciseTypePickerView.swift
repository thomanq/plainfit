import SwiftUI

struct ExerciseTypePickerView: View {
    let category: Category
    let categoryPickerPresentationMode: Binding<PresentationMode>
    @State private var selectedDate: Date = Date()
    @State private var exerciseTypes: [ExerciseType] = []
    @State private var showingAddSheet = false
    
    init(category: Category, categoryPickerPresentationMode: Binding<PresentationMode>) {
        self.category = category
        self.categoryPickerPresentationMode = categoryPickerPresentationMode
    }

    var body: some View {
        NavigationStack {
            List(exerciseTypes, id: \.self) { exerciseType in
                NavigationLink(destination: AddExerciseEntryView(
                    exerciseType: exerciseType,
                    selectedDate: selectedDate,
                    categoryPickerPresentationMode: categoryPickerPresentationMode
                )) {
                    Text(exerciseType.name)
                }
            }
            .navigationTitle(category.name)
            .toolbar {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                exerciseTypes = DatabaseHelper.shared.getExerciseTypesForCategory(categoryId: category.id)
            }) {
                AddExerciseTypeSheet(isPresented: $showingAddSheet)
            }
        }
    }
}
