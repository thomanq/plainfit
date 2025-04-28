import SwiftUI

struct CategoryExercisesView: View {
    let category: Category
    let selectedDate: Date
    @State private var exerciseTypes: [ExerciseType] = []
    @State private var showingAddSheet = false
    
    init(category: Category, selectedDate: Date) {
        self.category = category
        self.selectedDate = selectedDate
    }

    var body: some View {
        List(exerciseTypes, id: \.self) { exerciseType in
            NavigationLink(destination: AddExerciseView(exerciseType: exerciseType, selectedDate: selectedDate)) {
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
        .sheet(isPresented: $showingAddSheet) {
            AddExerciseTypeSheet(isPresented: $showingAddSheet)
        }
    }
}