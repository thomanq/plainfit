import Foundation
import GRDB
import TabularData

typealias CategoryName = String
typealias ExerciseTypeName = String
typealias ExerciseAttributes = String
typealias FieldName = String
typealias FieldValue = String
typealias ExerciseDetails = [ExerciseTypeName: ExerciseAttributes]
typealias ExerciseCategory = [CategoryName: ExerciseDetails]

struct ExercisesData: Codable {
  let exercises: [ExerciseCategory]
  let tutorial: [[FieldName: FieldValue]]
}

// Partial Category for insertion
struct PartialCategory: Encodable, PersistableRecord {
  var name: String
  static let databaseTableName = "categories"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("name", .text).notNull().unique()
    }
  }
}

struct Category: Identifiable, Hashable, Codable, PersistableRecord, FetchableRecord {
  var id: Int64
  var name: String

  // Add the table name property to match PartialCategory
  static let databaseTableName = "categories"

  // Hashable conformance
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
  }

  static func == (lhs: Category, rhs: Category) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
  }

}

// Partial ExerciseType for insertion
struct PartialExerciseType: Encodable, PersistableRecord {
  var name: String
  var type: String
  // Define table name explicitly
  static let databaseTableName = "exercise_types"

  // Setup table definition
  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("name", .text).notNull()
      t.column("type", .text).notNull()
    }
  }
}

struct ExerciseType: Identifiable, Hashable, Codable, PersistableRecord, FetchableRecord {
  var id: Int64
  var name: String
  var type: String

  // Add the table name to match PartialExerciseType
  static let databaseTableName = "exercise_types"

  // Hashable conformance
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(type)
  }

  static func == (lhs: ExerciseType, rhs: ExerciseType) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
  }
}

// Partial FitnessEntry for insertion
struct PartialFitnessEntry: Encodable, PersistableRecord {
  let exerciseName: String
  let exerciseType: String
  let duration: Int32
  let date: Date
  let setId: Int64
  let reps: Int32
  let distance: Float?
  let distanceUnit: String?
  let weight: Float?
  let weightUnit: String?
  let description: String?

  static let databaseTableName = "fitness_entries"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("exerciseName", .text).notNull()
      t.column("exerciseType", .text).notNull()
      t.column("duration", .integer).notNull()
      t.column("date", .datetime).notNull()
      t.column("setId", .integer).notNull()
      t.column("reps", .integer).notNull()
      t.column("distance", .double)
      t.column("distanceUnit", .text)
      t.column("weight", .double)
      t.column("weightUnit", .text)
      t.column("description", .text)
    }
  }
}

struct FitnessEntry: Identifiable, Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "fitness_entries"
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  var id: Int64
  let exerciseName: String
  let exerciseType: String
  let duration: Int32  // Duration in milliseconds
  let date: Date
  let setId: Int64
  let reps: Int32
  let distance: Float?
  let distanceUnit: String?
  let weight: Float?
  let weightUnit: String?
  let description: String?

  func toCSVRow() -> String {
    let dateString = FitnessEntry.dateFormatter.string(from: date)
    let distance = distance != nil ? String(distance!) : "N/A"
    let distanceUnit = distanceUnit ?? "N/A"
    let weight = weight != nil ? String(weight!) : "N/A"
    let weightUnit = weightUnit ?? "N/A"
    let description = description ?? "N/A"

    return
      "\(id),\"\(exerciseName)\",\"\(exerciseType)\",\(duration),\"\(dateString)\",\(setId),\(reps),\(distance),\(distanceUnit),\(weight),\(weightUnit),\"\(description)\"\n"
  }
}

func getFitnessEntriesHeaders() -> [String] {
  let mirror = Mirror(
    reflecting: FitnessEntry(
      id: 0,
      exerciseName: "",
      exerciseType: "",
      duration: 0,
      date: Date(),
      setId: 0,
      reps: 0,
      distance: nil,
      distanceUnit: nil,
      weight: nil,
      weightUnit: nil,
      description: nil
    ))

  return mirror.children.compactMap { $0.label }
}

// Junction table for many-to-many relationship between exercise types and categories
struct ExerciseTypeCategory: Codable, FetchableRecord, PersistableRecord {
  let exercise_type_id: Int64
  let category_id: Int64

  static let databaseTableName = "exercise_type_categories"

  // Setup table definition
  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.column("exercise_type_id", .integer).notNull().references(
        "exercise_types", onDelete: .cascade)
      t.column("category_id", .integer).notNull().references("categories", onDelete: .cascade)
      t.primaryKey(["exercise_type_id", "category_id"])
    }
  }
}

// Junction table for many-to-many relationship between entries and categories
struct EntryCategory: Codable, FetchableRecord, PersistableRecord {
  let entry_id: Int64
  let category_id: Int64

  static let databaseTableName = "entry_categories"

  // Setup table definition
  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.column("entry_id", .integer).notNull().references("fitness_entries", onDelete: .cascade)
      t.column("category_id", .integer).notNull().references("categories", onDelete: .cascade)
      t.primaryKey(["entry_id", "category_id"])
    }
  }
}

class DatabaseHelper {
  static let shared = DatabaseHelper()
  private var dbQueue: DatabaseQueue!

  private init() {
    setupDatabase()
  }

  private func setupDatabase() {
    do {
      // Get database path in documents directory
      let databaseURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      ).appendingPathComponent("plainfit.sqlite")

      // Open database connection
      dbQueue = try DatabaseQueue(path: databaseURL.path)

      // Create the database schema
      try dbQueue.write { db in
        try PartialCategory.defineTable(db)
        try PartialExerciseType.defineTable(db)
        try PartialFitnessEntry.defineTable(db)
        try ExerciseTypeCategory.defineTable(db)
        try EntryCategory.defineTable(db)
      }

      // Populate with initial data if needed
      populateInitialData()

    } catch {
      print("Database initialization error: \(error)")
    }
  }

  private func populateInitialData() {
    do {
      // Check if categories exist
      let categoriesExist = try dbQueue.read { db in
        try Category.fetchCount(db) > 0
      }

      if !categoriesExist, let exercises = loadExercisesFromJSON() {
        try dbQueue.write { db in
          for exerciseCategory in exercises.exercises {
            for (categoryName, exerciseTypes) in exerciseCategory {
              // Insert category
              let partialCategory = PartialCategory(name: categoryName)
              var category = try partialCategory.insertAndFetch(db, as: Category.self)

              // Insert exercise types and link to category
              for (exerciseName, attributes) in exerciseTypes {
                let partialExerciseType = PartialExerciseType(name: exerciseName, type: attributes)
                var exerciseType = try partialExerciseType.insertAndFetch(db, as: ExerciseType.self)

                let link = ExerciseTypeCategory(
                  exercise_type_id: exerciseType.id, category_id: category.id)
                try link.insert(db)
              }
            }
          }

          for tutorialEntry in exercises.tutorial {
            guard let exerciseName = tutorialEntry["exerciseName"],
              let exerciseType = tutorialEntry["exerciseType"],
              let setIdString = tutorialEntry["setId"],
              let setId = Int64(setIdString)
            else {
              continue
            }

            let duration = tutorialEntry["duration"].flatMap { Int32($0) } ?? 0
            let reps = tutorialEntry["reps"].flatMap { Int32($0) } ?? 0
            let weight = tutorialEntry["weight"].flatMap { Float($0) } 
            let distance = tutorialEntry["distance"].flatMap { Float($0) } 
            let description = tutorialEntry["description"]

            let partialEntry = PartialFitnessEntry(
              exerciseName: exerciseName,
              exerciseType: exerciseType,
              duration: duration,
              date: Date(),
              setId: setId,
              reps: reps ?? 0,
              distance: distance,
              distanceUnit: "mi",
              weight: weight,
              weightUnit: "lbs",
              description: description
            )
            try partialEntry.insert(db)
          }
        }
      }
    } catch {
      print("Error populating initial data: \(error)")
    }
  }

  private func loadExercisesFromJSON() -> ExercisesData? {
    guard let jsonPath = Bundle.main.path(forResource: "exercises", ofType: "json"),
      let jsonContent = try? String(contentsOfFile: jsonPath, encoding: .utf8),
      let jsonData = jsonContent.data(using: .utf8)
    else {
      return nil
    }

    do {
      return try JSONDecoder().decode(ExercisesData.self, from: jsonData)
    } catch {
      print("Error decoding JSON: \(error)")
      return nil
    }
  }

  func generateSetId() -> Int64 {
    do {
      let maxSetID = try dbQueue.read { db in
        let request = "SELECT MAX(setId) FROM fitness_entries"
        return try Int64.fetchOne(db, sql: request) ?? 0
      }
      return maxSetID + 1
    } catch {
      print("Error generating set Id: \(error)")
      return 1
    }
  }

  func insertEntry(
    exerciseName: String,
    exerciseType: String,
    duration: Int32,
    date: Date,
    setId: Int64,
    reps: Int32,
    distance: Float? = nil,
    distanceUnit: String? = nil,
    weight: Float? = nil,
    weightUnit: String? = nil,
    description: String? = nil
  ) -> Int64? {
    do {
      let partialEntry = PartialFitnessEntry(
        exerciseName: exerciseName,
        exerciseType: exerciseType,
        duration: duration,
        date: date,
        setId: setId,
        reps: reps,
        distance: distance,
        distanceUnit: distanceUnit,
        weight: weight,
        weightUnit: weightUnit,
        description: description
      )

      var entry = try dbQueue.write { db in
        try partialEntry.insertAndFetch(db, as: FitnessEntry.self)
      }

      return entry.id
    } catch {
      print("Error inserting entry: \(error)")
      return nil
    }
  }

  func fetchEntries(for date: Date) -> [FitnessEntry] {
    do {
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: date)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

      return try dbQueue.read { db in
        let request =
          FitnessEntry
          .filter(Column("date") >= startOfDay)
          .filter(Column("date") < endOfDay)
          .order(Column("date").desc)

        return try request.fetchAll(db)
      }
    } catch {
      print("Error fetching entries: \(error)")
      return []
    }
  }

  func fetchEntriesBySetId(setId: Int64) -> [FitnessEntry] {
    do {
      return try dbQueue.read { db in
        let request =
          FitnessEntry
          .filter(Column("setId") == setId)

        return try request.fetchAll(db)
      }
    } catch {
      print("Error fetching entries by set Id: \(error)")
      return []
    }
  }

  func deleteEntriesBySetId(setId: Int64) {
    do {
      try dbQueue.write { db in
        _ =
          try FitnessEntry
          .filter(Column("setId") == setId)
          .deleteAll(db)
      }
    } catch {
      print("Error deleting entries by set Id: \(error)")
    }
  }

  func insertCategory(name: String) -> Int64? {
    do {
      let partialCategory = PartialCategory(name: name)

      var category = try dbQueue.write { db in
        try partialCategory.insertAndFetch(db, as: Category.self)
      }

      return category.id
    } catch {
      print("Error inserting category: \(error)")
      return nil
    }
  }

  func fetchCategories() -> [Category] {
    do {
      return try dbQueue.read { db in
        try Category
          .order(Column("name"))
          .fetchAll(db)
      }
    } catch {
      print("Error fetching categories: \(error)")
      return []
    }
  }

  func updateCategory(id: Int64, name: String) -> Bool {
    do {
      try dbQueue.write { db in
        if let category = try Category.fetchOne(db, key: id) {
          var updatedCategory = category
          updatedCategory.name = name
          try updatedCategory.update(db)
          return true
        }
        return false
      }
    } catch {
      print("Error updating category: \(error)")
      return false
    }
    return false
  }

  func deleteCategory(id: Int64) -> Bool {
    do {
      try dbQueue.write { db in
        return try Category.deleteOne(db, key: id)
      }
    } catch {
      print("Error deleting category: \(error)")
      return false
    }
    return false
  }

  func linkEntryToCategory(entryId: Int64, categoryId: Int64) -> Bool {
    do {
      let link = EntryCategory(entry_id: entryId, category_id: categoryId)

      try dbQueue.write { db in
        try link.insert(db)
      }
      return true
    } catch {
      print("Error linking entry to category: \(error)")
      return false
    }
  }

  func getCategoriesForEntry(entryId: Int64) -> [Category] {
    do {
      return try dbQueue.read { db in
        let request = """
          SELECT c.id, c.name FROM categories c
          INNER JOIN entry_categories ec ON c.id = ec.category_id
          WHERE ec.entry_id = ?
          ORDER BY c.name
          """

        return try Category.fetchAll(db, sql: request, arguments: [entryId])
      }
    } catch {
      print("Error fetching categories for entry: \(error)")
      return []
    }
  }

  func insertExerciseType(name: String, type: String) -> Int64? {
    do {
      let partialExerciseType = PartialExerciseType(name: name, type: type)

      var exerciseType = try dbQueue.write { db in
        try partialExerciseType.insertAndFetch(db, as: ExerciseType.self)
      }

      return exerciseType.id
    } catch {
      print("Error inserting exercise type: \(error)")
      return nil
    }
  }

  func fetchExerciseTypes() -> [ExerciseType] {
    do {
      return try dbQueue.read { db in
        try ExerciseType
          .order(Column("name"))
          .fetchAll(db)
      }
    } catch {
      print("Error fetching exercise types: \(error)")
      return []
    }
  }

  func fetchAllExerciseTypes() -> [ExerciseType] {
    return fetchExerciseTypes()  // Same implementation in this case
  }

  func updateExerciseType(id: Int64, name: String, type: String) -> Bool {
    do {
      try dbQueue.write { db in
        if let exerciseType = try ExerciseType.fetchOne(db, key: id) {
          var updatedExerciseType = exerciseType
          updatedExerciseType.name = name
          updatedExerciseType.type = type
          try updatedExerciseType.update(db)
          return true
        }
        return false
      }
    } catch {
      print("Error updating exercise type: \(error)")
      return false
    }
    return false
  }

  func deleteExerciseType(id: Int64) -> Bool {
    do {
      try dbQueue.write { db in
        return try ExerciseType.deleteOne(db, key: id)
      }
    } catch {
      print("Error deleting exercise type: \(error)")
      return false
    }
    return false
  }

  func linkExerciseTypeToCategory(exerciseTypeId: Int64, categoryId: Int64) -> Bool {
    do {
      let link = ExerciseTypeCategory(
        exercise_type_id: exerciseTypeId,
        category_id: categoryId
      )

      try dbQueue.write { db in
        try link.insert(db)
      }
      return true
    } catch {
      print("Error linking exercise type to category: \(error)")
      return false
    }
  }

  func updateExerciseTypeCategory(exerciseTypeId: Int64, categoryId: Int64) -> Bool {
    do {
      try dbQueue.write { db in
        // Delete existing links
        _ =
          try ExerciseTypeCategory
          .filter(Column("exercise_type_id") == exerciseTypeId)
          .deleteAll(db)

        // Add new link
        let link = ExerciseTypeCategory(
          exercise_type_id: exerciseTypeId,
          category_id: categoryId
        )
        try link.insert(db)
        return true
      }
    } catch {
      print("Error updating exercise type category: \(error)")
      return false
    }
    return false
  }

  func getCategoriesForExerciseType(exerciseTypeId: Int64) -> [Category] {
    do {
      return try dbQueue.read { db in
        let request = """
          SELECT c.id, c.name
          FROM categories c
          INNER JOIN exercise_type_categories etc ON c.id = etc.category_id
          WHERE etc.exercise_type_id = ?
          ORDER BY c.name
          """

        return try Category.fetchAll(db, sql: request, arguments: [exerciseTypeId])
      }
    } catch {
      print("Error fetching categories for exercise type: \(error)")
      return []
    }
  }

  func getExerciseTypesForCategory(categoryId: Int64) -> [ExerciseType] {
    do {
      return try dbQueue.read { db in
        let request = """
          SELECT et.id, et.name, et.type
          FROM exercise_types et
          INNER JOIN exercise_type_categories etc ON et.id = etc.exercise_type_id
          WHERE etc.category_id = ?
          ORDER BY et.name
          """

        return try ExerciseType.fetchAll(db, sql: request, arguments: [categoryId])
      }
    } catch {
      print("Error fetching exercise types for category: \(error)")
      return []
    }
  }

  func exportToCSV() -> String {
    var csvString = ""
    do {
      let header = getFitnessEntriesHeaders().joined(separator: ",") + "\n"
      csvString.append(header)

      let entries = try dbQueue.read { db in
        try FitnessEntry
          .order(Column("date").asc)
          .fetchAll(db)
      }

      for entry in entries {
        csvString.append(entry.toCSVRow())
      }
    } catch {
      print("Error exporting to CSV: \(error)")
    }

    return csvString
  }

  func importFromCSV(csvString: String) -> Bool {
    do {
      let options = CSVReadingOptions(hasHeaderRow: true, delimiter: ",")
      guard let csvData = csvString.data(using: .utf8) else {
        return false
      }
      let dataFrame = try DataFrame(csvData: csvData, options: options)

      let expectedHeaders = getFitnessEntriesHeaders()
      let actualHeaders = dataFrame.columns.map { $0.name }

      guard Set(expectedHeaders) == Set(actualHeaders) else {
        return false
      }

      try dbQueue.write { db in
        try FitnessEntry.deleteAll(db)

        for row in dataFrame.rows {
          guard let duration = row["duration"] as? Int,
            let setId = row["setId"] as? Int,
            let reps = row["reps"] as? Int,
            let exerciseName = row["exerciseName"] as? String,
            let exerciseType = row["exerciseType"] as? String,
            let dateString = row["date"] as? String
          else {
            return false
          }

          guard let date = FitnessEntry.dateFormatter.date(from: dateString) else {
            return false
          }

          let distance: Float? = {
            if let val = row["distance"] as? Double {
              return Float(val)
            }
            if let val = row["distance"] as? String, val.lowercased() != "nil" {
              return Float(val)
            }
            return nil
          }()

          let distanceUnit: String? = {
            if let val = row["distanceUnit"] as? String, val.lowercased() != "nil" {
              return val
            }
            return nil
          }()

          let weight: Float? = {
            if let val = row["weight"] as? Double {
              return Float(val)
            }
            if let val = row["weight"] as? String, val.lowercased() != "nil" {
              return Float(val)
            }
            return nil
          }()

          let weightUnit: String? = {
            if let val = row["weightUnit"] as? String, val.lowercased() != "nil" {
              return val
            }
            return nil
          }()

          let description: String? = {
            if let val = row["description"] as? String, val.lowercased() != "nil" {
              return val
            }
            return nil
          }()

          let partialEntry = PartialFitnessEntry(
            exerciseName: exerciseName,
            exerciseType: exerciseType,
            duration: Int32(duration),
            date: date,
            setId: Int64(setId),
            reps: Int32(reps),
            distance: distance,
            distanceUnit: distanceUnit,
            weight: weight,
            weightUnit: weightUnit,
            description: description
          )

          do {
            try partialEntry.insert(db)
          } catch {
            return false
          }
        }
        return true
      }
      return true
    } catch {
      return false
    }
  }

  func restoreDatabase(from backupUrl: URL) -> Bool {
    do {
      let databaseURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      ).appendingPathComponent("plainfit.sqlite")

      if FileManager.default.fileExists(atPath: databaseURL.path) {
        try FileManager.default.removeItem(at: databaseURL)
      }

      try FileManager.default.copyItem(at: backupUrl, to: databaseURL)

      setupDatabase()
      return true
    } catch {
      print("Error restoring database: \(error)")
      return false
    }
  }
}
