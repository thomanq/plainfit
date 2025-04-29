import SwiftUI

struct AddExerciseEntryView: View {
    @Environment(\.dismiss) var dismiss
    let categoryPickerPresentationMode: Binding<PresentationMode>

    let exerciseType: ExerciseType
    @State private var exerciseDate: Date
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var distance: String = ""
    @State private var distanceUnit: String = "km"
    @State private var weight: String = ""
    @State private var weightUnit: String = "kg"

    private let units = ["km", "mi", "m"]
    private let weightUnits = ["kg", "lbs"]
    
    init(exerciseType: ExerciseType, selectedDate: Date, categoryPickerPresentationMode: Binding<PresentationMode>) {
        self.exerciseType = exerciseType
        self.categoryPickerPresentationMode = categoryPickerPresentationMode
        _exerciseDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: .constant(exerciseType.name))
                        .disabled(true)
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
                    }
                    DatePicker("Date and Time", selection: $exerciseDate)
                }
                
                Section(header: Text("Sets and Reps")) {
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Distance (Optional)")) {
                    HStack {
                        TextField("Distance", text: $distance)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $distanceUnit) {
                            ForEach(units, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section(header: Text("Weight (Optional)")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $weightUnit) {
                            ForEach(weightUnits, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Button(action: saveExercise) {
                    Text("Save Exercise")
                }
            }
            .navigationTitle("Add Exercise")
        }
    }
    
    private func saveExercise() {
        guard !exerciseType.name.isEmpty else { return }
        
        // Convert HH:MM:SS to milliseconds
        let hoursMs = (Int32(hours) ?? 0) * 3600000
        let minutesMs = (Int32(minutes) ?? 0) * 60000
        let secondsMs = (Int32(seconds) ?? 0) * 1000
        let totalDurationMs = hoursMs + minutesMs + secondsMs
        
        let distanceValue = Float(distance)
        let weightValue = Float(weight)
        
        if let entryId = DatabaseHelper.shared.insertEntry(
            exerciseName: exerciseType.name,
            duration: totalDurationMs,
            date: exerciseDate,
            sets: Int32(sets) ?? 0,
            reps: Int32(reps) ?? 0,
            distance: distanceValue,
            distanceUnit: !distance.isEmpty ? distanceUnit : nil,
            weight: weightValue,
            weightUnit: !weight.isEmpty ? weightUnit : nil
        ) {
            // Handle successful save
        }
        categoryPickerPresentationMode.wrappedValue.dismiss()
    }
}
