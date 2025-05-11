import SwiftUI

struct AddExerciseEntryView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("unitSystem") private var unitSystem = UnitSystem.imperial
  @Binding var showCategoryPicker: Bool
  @Binding var showEditExerciseSet: Bool

  let exerciseType: ExerciseType
  @State private var nextId: Int64 = 0
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
  @State private var description: String = ""

  private var distanceUnits: [String] = []
  private var weightUnits: [String] = []

  @State private var exercises: [FitnessEntry] = []
  @State private var isEditing: Bool = false
  @State private var editingExerciseId: Int64 = 0
  @State private var setId: Int64
  @State private var showErrorModal: Bool = false
  @State private var errorMessage: String = ""
  @State private var showingDeleteConfirmation: Bool = false

  init(
    exerciseType: ExerciseType, selectedDate: Date, showCategoryPicker: Binding<Bool>,
    showEditExerciseSet: Binding<Bool>, setId: Int64? = nil
  ) {
    let selectedDateWithCurrentTime =
      Calendar.current.date(
        bySettingHour: Calendar.current.component(.hour, from: Date()),
        minute: Calendar.current.component(.minute, from: Date()),
        second: Calendar.current.component(.second, from: Date()), of: selectedDate) ?? selectedDate

    _exerciseDate = State(initialValue: selectedDateWithCurrentTime)

    if let setId = setId {
      _setId = State(initialValue: setId)
      _exercises = State(initialValue: DatabaseHelper.shared.fetchEntriesBySetId(setId: setId))
      if let firstExercise = _exercises.wrappedValue.last {
        _exerciseDate = State(initialValue: firstExercise.date)
      }
    } else {
      _setId = State(initialValue: DatabaseHelper.shared.generateSetId())
    }

    self.exerciseType = exerciseType

    _showCategoryPicker = showCategoryPicker
    _showEditExerciseSet = showEditExerciseSet

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

      Section(header: Text("Description (Optional)")) {
        TextField("Description", text: $description)
      }

      Button(action: {
        if weight.isEmpty && reps.isEmpty && distance.isEmpty && hours.isEmpty && minutes.isEmpty
          && seconds.isEmpty && milliseconds.isEmpty
        {
          errorMessage =
            "Please fill in at least one field (weight, reps, distance, or duration) to add an exercise."
          showErrorModal = true
        } else {
          isEditing ? saveEditedExercise() : addExercise()
        }
      }) {
        Text(isEditing ? "Edit Exercise" : "Add Exercise to Set")
      }
      if isEditing {
        Button(action: cancelEdit) {
          Text("Cancel")
            .foregroundColor(.red)
        }
      }
      Section(header: Text("Exercises in Set")) {
        List {
          ForEach(exercises) { exercise in
            VStack(alignment: .leading) {
              Text(exerciseType.name)
              if exercise.duration > 0 {
                Text("Duration: \(formatDuration(exercise.duration))")
              }
              if exercise.reps > 0 {
                Text("Reps: \(exercise.reps)")
              }
              if let distance = exercise.distance, let unit = exercise.distanceUnit {
                Text("Distance: \(formatValue(distance)) \(unit)")
              }
              if let weight = exercise.weight, let unit = exercise.weightUnit {
                Text("Weight: \(formatValue(weight)) \(unit)")
              }
              if let description = exercise.description, !description.isEmpty {
                Text("Description: \(description)")
                  .foregroundColor(.secondary)
              }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
              Button(action: {
                editExercise(exercise)
              }) {
                Label("Edit", systemImage: "pencil")
              }
              .tint(.blue)
            }
          }
          .onDelete(perform: deleteExercise)
          .onMove(perform: moveExercise)
        }
        .environment(
          \.editMode,
          .constant(EditMode.active)
        )
      }

      Button(action: {
        if !reps.isEmpty || !weight.isEmpty || !hours.isEmpty || !minutes.isEmpty
          || !seconds.isEmpty || !milliseconds.isEmpty || !distance.isEmpty
        {
          errorMessage = "Cannot save set. Ensure no fields are filled."
          showErrorModal = true
        } else if exercises.isEmpty {
          errorMessage = "Cannot save set. Ensure at least one exercise is added."
          showErrorModal = true
        } else {
          saveExercise()
        }
      }) {
        Text(showEditExerciseSet ? "Edit Set" : "Save Set")
      }
      if showEditExerciseSet {
        Section {
          Button("Delete Set", role: .destructive) {
            showingDeleteConfirmation = true
          }
          .confirmationDialog(
            "Are you sure you want to delete this set?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
          ) {
            Button("Delete", role: .destructive) {
              DatabaseHelper.shared.deleteEntriesBySetId(setId: setId)
              dismiss()
            }
            Button("Cancel", role: .cancel) {}
          }
        }
      }
    }.scrollContentBackground(.hidden)
      .background(Color("Background"))
      .alert(isPresented: $showErrorModal) {
        Alert(
          title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
      }
      .navigationTitle(showEditExerciseSet ? "Edit Exercise" : "Add Exercise")
  }

  private func addExercise() {
    let hoursMs = (Int32(hours) ?? 0) * 3_600_000
    let minutesMs = (Int32(minutes) ?? 0) * 60000
    let secondsMs = (Int32(seconds) ?? 0) * 1000
    let ms = Int32(milliseconds) ?? 0
    let totalDurationMs = hoursMs + minutesMs + secondsMs + ms

    let distanceValue = Float(distance.replacingOccurrences(of: ",", with: "."))
    let weightValue = Float(weight.replacingOccurrences(of: ",", with: "."))

    let newExercise = FitnessEntry(
      id: nextId,
      duration: totalDurationMs,
      date: exerciseDate,
      setId: setId,
      reps: Int32(reps) ?? 0,
      distance: distanceValue,
      distanceUnit: !distance.isEmpty ? distanceUnit : nil,
      weight: weightValue,
      weightUnit: !weight.isEmpty ? weightUnit : nil,
      description: !description.isEmpty ? description : nil,
      exerciseTypeId: exerciseType.id
    )
    nextId += 1

    exercises.append(newExercise)

    clearFields()
  }

  private func saveExercise() {
    guard !exercises.isEmpty else { return }

    DatabaseHelper.shared.deleteEntriesBySetId(setId: setId)

    for exercise in exercises {
      let partialEntry = PartialFitnessEntry(
        duration: exercise.duration,
        date: exercise.date,
        setId: exercise.setId,
        reps: exercise.reps,
        distance: exercise.distance,
        distanceUnit: exercise.distanceUnit,
        weight: exercise.weight,
        weightUnit: exercise.weightUnit,
        description: exercise.description,
        exerciseTypeId: exerciseType.id
      )
      _ = DatabaseHelper.shared.insertEntry(partialEntry)
    }

    showCategoryPicker = false
    showEditExerciseSet = false
  }

  private func deleteExercise(at offsets: IndexSet) {
    exercises.remove(atOffsets: offsets)
  }

  private func editExercise(_ exercise: FitnessEntry) {
    isEditing = true
    editingExerciseId = exercise.id

    // Restore values to fields
    hours = String(exercise.duration / 3_600_000)
    hours = hours != "0" ? hours : ""
    minutes = String((exercise.duration % 3_600_000) / 60000)
    minutes = minutes != "0" ? minutes : ""
    seconds = String((exercise.duration % 60000) / 1000)
    seconds = seconds != "0" ? seconds : ""
    milliseconds = String(exercise.duration % 1000)
    milliseconds = milliseconds != "0" ? milliseconds : ""

    reps = exercise.reps > 0 ? String(exercise.reps) : ""
    distance = exercise.distance != nil ? String(exercise.distance!) : ""
    distanceUnit = exercise.distanceUnit ?? (unitSystem == .imperial ? "mi" : "km")
    weight = exercise.weight != nil ? String(exercise.weight!) : ""
    weightUnit = exercise.weightUnit ?? (unitSystem == .imperial ? "lbs" : "kg")
    exerciseDate = exercise.date
    description = exercise.description ?? ""
  }

  private func saveEditedExercise() {

    if let index = exercises.firstIndex(where: { $0.id == editingExerciseId }) {
      let existingExercise = exercises[index]
      exercises[index] = FitnessEntry(
        id: existingExercise.id,
        duration: calculateDuration(),
        date: exerciseDate,
        setId: existingExercise.setId,
        reps: Int32(reps) ?? 0,
        distance: Float(distance.replacingOccurrences(of: ",", with: ".")),
        distanceUnit: !distance.isEmpty ? distanceUnit : nil,
        weight: Float(weight.replacingOccurrences(of: ",", with: ".")),
        weightUnit: !weight.isEmpty ? weightUnit : nil,
        description: !description.isEmpty ? description : nil,
        exerciseTypeId: exerciseType.id
      )
    }

    cancelEdit()
  }

  private func cancelEdit() {
    isEditing = false
    clearFields()
  }

  private func clearFields() {
    hours = ""
    minutes = ""
    seconds = ""
    milliseconds = ""
    reps = ""
    distance = ""
    weight = ""
    description = ""
  }

  private func calculateDuration() -> Int32 {
    let hoursMs = (Int32(hours) ?? 0) * 3_600_000
    let minutesMs = (Int32(minutes) ?? 0) * 60000
    let secondsMs = (Int32(seconds) ?? 0) * 1000
    let ms = Int32(milliseconds) ?? 0
    return hoursMs + minutesMs + secondsMs + ms
  }

  private func moveExercise(from source: IndexSet, to destination: Int) {
    exercises.move(fromOffsets: source, toOffset: destination)
  }

}
