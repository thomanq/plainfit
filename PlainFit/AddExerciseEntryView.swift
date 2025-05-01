import SwiftUI

struct AddExerciseEntryView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("unitSystem") private var unitSystem = UnitSystem.imperial
    @Binding var showCategoryPicker: Bool

    let exerciseType: ExerciseType
    @State private var exerciseDate: Date
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    @State private var milliseconds: String = ""
    @State private var reps: String = ""
    @State private var distance: String = ""
    @State private var distanceUnit: String = ""
    @State private var weight: String = ""
    @State private var weightUnit: String = ""

    private var distanceUnits: [String] = []
    private var weightUnits: [String] = []

    init(exerciseType: ExerciseType, selectedDate: Date, showCategoryPicker: Binding<Bool>) {
        self.exerciseType = exerciseType
        _showCategoryPicker = showCategoryPicker

        _exerciseDate = State(initialValue: selectedDate)
        _distanceUnit = State(initialValue: unitSystem == .imperial ? "mi" : "km")
        _weightUnit = State(initialValue: unitSystem == .imperial ? "lbs" : "kg")

        if unitSystem == .imperial {
            distanceUnits = ["mi"]
            weightUnits = ["lbs"]
        } else {
            distanceUnits = ["km", "m"]
            weightUnits = ["kg"]
        }
    }

    var body: some View {
        Form {
            TextField("Exercise Name", text: .constant(exerciseType.name))
                .disabled(true)
            DatePicker("Date and Time", selection: $exerciseDate)
            
            if exerciseType.type.contains("time") {
                Section(header: Text("Duration")) {
                    HStack {
                        TextField("HH", text: $hours)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 50)
                        Text(":")
                        TextField("MM", text: $minutes)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 50)
                        Text(":")
                        TextField("SS", text: $seconds)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 50)
                        Text(":")
                        TextField("MS", text: $milliseconds)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 50)
                    }
                }
            }

            if exerciseType.type.contains("reps") {
                Section(header: Text("Reps")) {
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                }
            }

            if exerciseType.type.contains("distance") {
                Section(header: Text("Distance")) {
                    HStack {
                        TextField("Distance", text: $distance)
                            .keyboardType(.decimalPad)
                        if distanceUnits.count > 1 {
                            Picker("", selection: $distanceUnit) {
                                ForEach(distanceUnits, id: \.self) {
                                    Text($0)
                                }
                            }
                        } else {
                            Text(distanceUnit)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            if exerciseType.type.contains("weight") {
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        if weightUnits.count > 1 {
                            Picker("", selection: $weightUnit) {
                                ForEach(weightUnits, id: \.self) {
                                    Text($0)
                                }
                            }
                        } else {
                            Text(weightUnit)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Button(action: saveExercise) {
                Text("Save Exercise")
            }
        }
        .navigationTitle("Add Exercise")
    }

    private func saveExercise() {
        guard !exerciseType.name.isEmpty else { return }

        // Convert HH:MM:SS:MS to milliseconds
        let hoursMs = (Int32(hours) ?? 0) * 3_600_000
        let minutesMs = (Int32(minutes) ?? 0) * 60000
        let secondsMs = (Int32(seconds) ?? 0) * 1000
        let ms = Int32(milliseconds) ?? 0
        let totalDurationMs = hoursMs + minutesMs + secondsMs + ms

        let distanceValue = Float(distance)
        let weightValue = Float(weight)

        if let entryId = DatabaseHelper.shared.insertEntry(
            exerciseName: exerciseType.name,
            duration: totalDurationMs,
            date: exerciseDate,
            sets: 0,
            reps: Int32(reps) ?? 0,
            distance: distanceValue,
            distanceUnit: !distance.isEmpty ? distanceUnit : nil,
            weight: weightValue,
            weightUnit: !weight.isEmpty ? weightUnit : nil
        ) {
            // Handle successful save
        }
        showCategoryPicker = false
    }
}
