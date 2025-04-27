import SwiftUI

struct ExerciseDetailView: View {
    let entry: FitnessEntry
    
    var body: some View {
        List {
            Section(header: Text("Exercise")) {
                Text(entry.exerciseName)
                Text(entry.date, style: .date)
            }
            
            if let distance = entry.distance, let unit = entry.distanceUnit {
                Section(header: Text("Distance")) {
                    Text("\(String(format: "%.2f", distance)) \(unit)")
                }
            }
            
            if let weight = entry.weight, let unit = entry.weightUnit {
                Section(header: Text("Weight")) {
                    Text("\(String(format: "%.2f", weight)) \(unit)")
                }
            }
        }
        .navigationTitle(entry.exerciseName)
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseDetailView(entry: FitnessEntry(
            id: 1,
            exerciseName: "Running",
            duration: "30 minutes",
            date: Date(),
            sets: 1,
            reps: 1,
            distance: 5.0,
            distanceUnit: "km",
            weight: nil,
            weightUnit: nil
        ))
    }
}