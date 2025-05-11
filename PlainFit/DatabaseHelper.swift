import Foundation
import GRDB
import TabularData

struct ExerciseAttributes: Codable {
  let type: String
  let iconName: String?
  let iconColor: String?
}

struct Icon: Codable {
  let name: String
  let color: String

}
typealias ExerciseTypeName = String
struct CategoryDetails: Codable {
  let icon: Icon
  let exercises: [ExerciseTypeName: ExerciseAttributes]
}
typealias CategoryName = String
typealias ExerciseCategory = [CategoryName: CategoryDetails]

typealias FieldName = String
typealias FieldValue = String

struct ExercisesData: Codable {
  let categories: ExerciseCategory
  let tutorial: [[FieldName: FieldValue]]
}

struct PartialCategory: Encodable, PersistableRecord {
  var name: String
  var iconName: String
  var iconColor: String

  static let databaseTableName = "categories"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("name", .text).notNull().unique()
      t.column("iconName", .text).notNull()
      t.column("iconColor", .text).notNull()
    }
  }
}

struct Category: Identifiable, Hashable, Codable, PersistableRecord, FetchableRecord {
  var id: Int64
  var name: String
  var iconName: String
  var iconColor: String

  static let databaseTableName = "categories"

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(iconName)
    hasher.combine(iconColor)
  }

  static func == (lhs: Category, rhs: Category) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.iconName == rhs.iconName
      && lhs.iconColor == rhs.iconColor
  }

}

struct PartialExerciseType: Encodable, PersistableRecord {
  var name: String
  var type: String
  var iconName: String?
  var iconColor: String?

  static let databaseTableName = "exercise_types"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("name", .text).notNull()
      t.column("type", .text).notNull()
      t.column("iconName", .text)
      t.column("iconColor", .text)
    }
  }
}

struct ExerciseType: Identifiable, Hashable, Codable, PersistableRecord, FetchableRecord {
  var id: Int64
  var name: String
  var type: String
  var iconName: String?
  var iconColor: String?

  static let databaseTableName = "exercise_types"

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(type)
    hasher.combine(iconName)
    hasher.combine(iconColor)
  }

  static func == (lhs: ExerciseType, rhs: ExerciseType) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
      && lhs.iconName == rhs.iconName && lhs.iconColor == rhs.iconColor
  }
}

struct PartialFitnessEntry: Encodable, PersistableRecord {
  let duration: Int32
  let date: Date
  let setId: Int64
  let reps: Int32
  let distance: Float?
  let distanceUnit: String?
  let weight: Float?
  let weightUnit: String?
  let description: String?
  let exerciseTypeId: Int64

  static let databaseTableName = "fitness_entries"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.autoIncrementedPrimaryKey("id")
      t.column("duration", .integer).notNull()
      t.column("date", .datetime).notNull()
      t.column("setId", .integer).notNull()
      t.column("reps", .integer).notNull()
      t.column("distance", .double)
      t.column("distanceUnit", .text)
      t.column("weight", .double)
      t.column("weightUnit", .text)
      t.column("description", .text)
      t.column("exerciseTypeId", .integer).notNull().references("exercise_types")
    }
  }
}

struct FitnessActivity: Hashable {
  let category: Category
  let exerciseType: ExerciseType

  func hash(into hasher: inout Hasher) {
    hasher.combine(exerciseType.id)
  }
}
typealias DayNumber = Int
struct FitnessActivitySummary {
  let activity: [DayNumber: Set<FitnessActivity>]
}

struct FitnessEntry: Identifiable, Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "fitness_entries"
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  var id: Int64
  let duration: Int32  // Duration in milliseconds
  let date: Date
  let setId: Int64
  let reps: Int32
  let distance: Float?
  let distanceUnit: String?
  let weight: Float?
  let weightUnit: String?
  let description: String?
  let exerciseTypeId: Int64

  func toCSVRow() -> String {
    let dateString = FitnessEntry.dateFormatter.string(from: date)
    let distance = distance != nil ? String(distance!) : "N/A"
    let distanceUnit = distanceUnit ?? "N/A"
    let weight = weight != nil ? String(weight!) : "N/A"
    let weightUnit = weightUnit ?? "N/A"
    let description = description ?? "N/A"

    let exerciseType = DatabaseHelper.shared.fetchExerciseTypeBySetId(setId: setId)
    let exerciseTypeName = exerciseType?.name ?? "N/A"
    let exerciseTypeType = exerciseType?.type ?? "N/A"

    return
      "\(id),\"\(exerciseTypeName)\",\"\(exerciseTypeType)\",\(duration),\"\(dateString)\",\(setId),\(reps),\(distance),\(distanceUnit),\(weight),\(weightUnit),\"\(description)\"\n"
  }
}

func getFitnessEntriesHeaders() -> [String] {
  return [
    "id",
    "exerciseName",
    "exerciseType",
    "duration",
    "date",
    "setId",
    "reps",
    "distance",
    "distanceUnit",
    "weight",
    "weightUnit",
    "description",
  ]
}

// Junction table for many-to-many relationship between exercise types and categories
struct ExerciseTypeCategory: Codable, FetchableRecord, PersistableRecord {
  let exercise_type_id: Int64
  let category_id: Int64

  static let databaseTableName = "exercise_type_categories"

  static func defineTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.column("exercise_type_id", .integer).notNull().references(
        "exercise_types", onDelete: .cascade)
      t.column("category_id", .integer).notNull().references("categories", onDelete: .cascade)
      t.primaryKey(["exercise_type_id", "category_id"])
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
      let databaseURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      ).appendingPathComponent("plainfit.sqlite")

      dbQueue = try DatabaseQueue(path: databaseURL.path)

      try dbQueue.write { db in
        try PartialCategory.defineTable(db)
        try PartialExerciseType.defineTable(db)
        try PartialFitnessEntry.defineTable(db)
        try ExerciseTypeCategory.defineTable(db)
      }

      populateInitialData()

    } catch {
      print("Database initialization error: \(error)")
    }
  }

  private func populateInitialData() {
    do {
      let categoriesExist = try dbQueue.read { db in
        try Category.fetchCount(db) > 0
      }

      if !categoriesExist, let exercisesData = loadExercisesFromJSON() {
        try dbQueue.write { db in
          for (categoryName, categoryDetails) in exercisesData.categories {
            let partialCategory = PartialCategory(
              name: categoryName,
              iconName: categoryDetails.icon.name,
              iconColor: categoryDetails.icon.color
            )
            let category = try partialCategory.insertAndFetch(db, as: Category.self)

            for (exerciseName, attributes) in categoryDetails.exercises {
              let partialExerciseType = PartialExerciseType(
                name: exerciseName,
                type: attributes.type,
                iconName: attributes.iconName,
                iconColor: attributes.iconColor
              )
              let exerciseType = try partialExerciseType.insertAndFetch(db, as: ExerciseType.self)

              let link = ExerciseTypeCategory(
                exercise_type_id: exerciseType.id,
                category_id: category.id
              )
              try link.insert(db)
            }
          }

          for tutorialEntry in exercisesData.tutorial {
            guard let exerciseName = tutorialEntry["exerciseName"],
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

            if let exerciseTypeId = try ExerciseType.filter(Column("name") == exerciseName)
              .fetchOne(db)?.id
            {
              let partialEntry = PartialFitnessEntry(
                duration: duration,
                date: Date(),
                setId: setId,
                reps: reps,
                distance: distance,
                distanceUnit: "mi",
                weight: weight,
                weightUnit: "lbs",
                description: description,
                exerciseTypeId: exerciseTypeId
              )
              let _ = try partialEntry.insertAndFetch(db, as: FitnessEntry.self)
            }
          }

          let populateFakeData: Bool = false
          if populateFakeData {
            var setId: Int64 = 10
            let calendar = Calendar.current
            let today = Date()
            let numMonths = 5

            let exerciseNames = exercisesData.categories.flatMap { $0.value.exercises.keys }

            for dayOffset in 1..<(30 * numMonths) {
              let day = calendar.date(byAdding: .day, value: -1 * dayOffset, to: today) ?? today
              let exerciseCount = Int.random(in: 0...5)

              for _ in 0..<exerciseCount {
                guard let randomExerciseName = exerciseNames.randomElement(),
                  let exerciseTypeId = try ExerciseType.filter(Column("name") == randomExerciseName)
                    .fetchOne(db)?.id
                else {
                  continue
                }

                let partialEntry = PartialFitnessEntry(
                  duration: Int32.random(in: 300...3600),
                  date: day,
                  setId: setId,
                  reps: Int32.random(in: 5...20),
                  distance: Float.random(in: 0.5...5.0),
                  distanceUnit: "mi",
                  weight: Float.random(in: 10.0...100.0),
                  weightUnit: "lbs",
                  description: nil,
                  exerciseTypeId: exerciseTypeId
                )
                let _ = try partialEntry.insertAndFetch(db, as: FitnessEntry.self)
                setId += 1
              }
            }
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

  func insertEntry(_ partialEntry: PartialFitnessEntry) -> FitnessEntry? {
    do {
      return try dbQueue.write { db in
        try partialEntry.insertAndFetch(db, as: FitnessEntry.self)
      }
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

  func fetchExerciseTypeBySetId(setId: Int64) -> ExerciseType? {
    do {
      return try dbQueue.read { db in
        let request = """
          SELECT et.*
          FROM exercise_types et
          JOIN fitness_entries fe ON et.id = fe.exerciseTypeId
          WHERE fe.setId = ?
          LIMIT 1
          """
        return try ExerciseType.fetchOne(db, sql: request, arguments: [setId])
      }
    } catch {
      print("Error fetching exercise type by setId: \(error)")
      return nil
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

  func insertCategory(_ partialCategory: PartialCategory) -> Category? {
    do {
      let category = try dbQueue.write { db in
        try partialCategory.insertAndFetch(db, as: Category.self)
      }
      return category
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

  func updateCategory(_ category: Category) -> Bool {
    do {
      _ = try dbQueue.write { db in
        try category.update(db)
        return true
      }
    } catch {
      print("Error updating category: \(error)")
      return false
    }
    return false
  }

  func deleteCategory(id: Int64) -> Bool {
    do {
      _ = try dbQueue.write { db in
        return try Category.deleteOne(db, key: id)
      }
    } catch {
      print("Error deleting category: \(error)")
      return false
    }
    return false
  }

  func insertExerciseType(_ partialExerciseType: PartialExerciseType) -> ExerciseType? {
    do {

      let insertedExerciseType = try dbQueue.write { db in
        try partialExerciseType.insertAndFetch(db, as: ExerciseType.self)
      }
      return insertedExerciseType
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

  func updateExerciseType(_ exerciseType: ExerciseType) -> Bool {
    do {
      _ = try dbQueue.write { db in
        try exerciseType.update(db)
        return true
      }
    } catch {
      print("Error updating exercise type: \(error)")
      return false
    }
    return false
  }

  func deleteExerciseType(id: Int64) -> Bool {
    do {
      _ = try dbQueue.write { db in
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

      _ = try dbQueue.write { db in
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
      _ = try dbQueue.write { db in
        _ =
          try ExerciseTypeCategory
          .filter(Column("exercise_type_id") == exerciseTypeId)
          .deleteAll(db)

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
          SELECT *
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
          SELECT *
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

      _ = try dbQueue.write { db in
        try FitnessEntry.deleteAll(db)

        for row in dataFrame.rows {
          guard let duration = row["duration"] as? Int,
            let setId = row["setId"] as? Int,
            let reps = row["reps"] as? Int,
            let exerciseName = row["exerciseName"] as? String,
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

          if let exerciseTypeId = try ExerciseType.filter(Column("name") == exerciseName).fetchOne(
            db)?.id
          {

            let partialEntry = PartialFitnessEntry(
              duration: Int32(duration),
              date: date,
              setId: Int64(setId),
              reps: Int32(reps),
              distance: distance,
              distanceUnit: distanceUnit,
              weight: weight,
              weightUnit: weightUnit,
              description: description,
              exerciseTypeId: exerciseTypeId
            )
            do {
              try partialEntry.insert(db)
            } catch {
              return false
            }
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

  func getFitnessEntriesForMonth(date: Date) -> [FitnessEntry] {
    do {
      let calendar = Calendar.current
      guard
        let startOfMonth = calendar.date(
          from: calendar.dateComponents([.year, .month], from: date)),
        let startNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
      else {
        return []
      }

      return try dbQueue.read { db in
        let request =
          FitnessEntry
          .filter(Column("date") >= startOfMonth)
          .filter(Column("date") < startNextMonth)
          .order(Column("date").asc)

        return try request.fetchAll(db)
      }
    } catch {
      print("Error fetching entries for month: \(error)")
      return []
    }
  }

  func getFitnessActivityForMonth(date: Date) -> FitnessActivitySummary {
    let entries = getFitnessEntriesForMonth(date: date)
    var activityByDay: [DayNumber: Set<FitnessActivity>] = [:]

    let calendar = Calendar.current

    for entry in entries {
      let day = calendar.component(.day, from: entry.date)

      if let exerciseType = fetchExerciseTypeBySetId(setId: entry.setId),
        let category = getCategoriesForExerciseType(exerciseTypeId: exerciseType.id).first
      {
        let activity = FitnessActivity(category: category, exerciseType: exerciseType)

        if activityByDay[day] != nil {
          activityByDay[day]?.insert(activity)
        } else {
          activityByDay[day] = Set([activity])
        }
      }
    }

    return FitnessActivitySummary(activity: activityByDay)
  }
}
