import Foundation
import SQLite3

typealias CategoryName = String
typealias ExerciseTypeName = String
typealias ExerciseAttributes = String
typealias ExerciseDetails = [ExerciseTypeName: ExerciseAttributes]
typealias ExerciseCategory = [CategoryName: ExerciseDetails]

struct ExercisesData: Codable {
  let exercises: [ExerciseCategory]
}

struct Category: Identifiable, Hashable {
  let id: Int32
  let name: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)

  }
  static func == (lhs: Category, rhs: Category) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
  }
}

struct FitnessEntry: Identifiable {
  let id: Int32
  let exerciseName: String
  let exerciseType: String
  let duration: Int32  // Duration in milliseconds
  let date: Date
  let set_id: Int32
  let reps: Int32
  let distance: Float?
  let distanceUnit: String?
  let weight: Float?
  let weightUnit: String?
}

struct ExerciseType: Identifiable, Hashable {
  let id: Int32
  let name: String
  let type: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(type)
  }

  static func == (lhs: ExerciseType, rhs: ExerciseType) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
  }
}

class DatabaseHelper {
  static let shared = DatabaseHelper()
  private var db: OpaquePointer?

  private init() {
    if let dbPath = try? FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    ).appendingPathComponent("fitness.db").path {
      if sqlite3_open(dbPath, &db) == SQLITE_OK {
        if sqlite3_exec(
          db,
          """
          CREATE TABLE IF NOT EXISTS fitness_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              exercise_name TEXT,
              exercise_type TEXT,
              duration INTEGER,
              date INTEGER,
              set_id INTEGER,
              reps INTEGER,
              distance REAL,
              distance_unit TEXT,
              weight REAL,
              weight_unit TEXT
          )
          """, nil, nil, nil) != SQLITE_OK
        {
          print("Error creating fitness_entries table")
        }

        // Create categories table
        if sqlite3_exec(
          db,
          """
          CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE
          )
          """, nil, nil, nil) != SQLITE_OK
        {
          print("Error creating categories table")
        }

        // Create entry_categories table for many-to-many relationship
        if sqlite3_exec(
          db,
          """
          CREATE TABLE IF NOT EXISTS entry_categories (
              entry_id INTEGER,
              category_id INTEGER,
              PRIMARY KEY (entry_id, category_id),
              FOREIGN KEY (entry_id) REFERENCES fitness_entries(id) ON DELETE CASCADE,
              FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
          )
          """, nil, nil, nil) != SQLITE_OK
        {
          print("Error creating entry_categories table")
        }

        // Create exercise_types table
        if sqlite3_exec(
          db,
          """
          CREATE TABLE IF NOT EXISTS exercise_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL
          )
          """, nil, nil, nil) != SQLITE_OK
        {
          print("Error creating exercise_types table")
        }

        // Create exercise_type_categories table for many-to-many relationship
        if sqlite3_exec(
          db,
          """
          CREATE TABLE IF NOT EXISTS exercise_type_categories (
              exercise_type_id INTEGER,
              category_id INTEGER,
              PRIMARY KEY (exercise_type_id, category_id),
              FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id) ON DELETE CASCADE,
              FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
          )
          """, nil, nil, nil) != SQLITE_OK
        {
          print("Error creating exercise_type_categories table")
        }

        // Insert categories from exercises.json if none exist
        let existingCategories = fetchCategories()
        let existingExerciseTypes = fetchExerciseTypes()

        if let exercises = loadExercisesFromJSON() {
          for exerciseCategory in exercises.exercises {
            for (categoryName, exerciseTypes) in exerciseCategory {
              let categoryId =
                if !existingCategories.contains(where: { $0.name == categoryName }) {
                  insertCategory(name: categoryName)
                } else {
                  existingCategories.first(where: { $0.name == categoryName })?.id
                }

              if let categoryId = categoryId {
                for (exerciseName, attributes) in exerciseTypes {
                  if !existingExerciseTypes.contains(where: { $0.name == exerciseName }) {
                    if let exerciseTypeId = insertExerciseType(name: exerciseName, type: attributes)
                    {
                      _ = linkExerciseTypeToCategory(
                        exerciseTypeId: exerciseTypeId, categoryId: categoryId)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  func generateSetID() -> Int32 {
    let query = "SELECT MAX(set_id) FROM fitness_entries"
    var queryStatement: OpaquePointer?
    var maxSetID: Int32 = 0

    if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
      if sqlite3_step(queryStatement) == SQLITE_ROW {
        maxSetID = sqlite3_column_int(queryStatement, 0)
      }
    }
    sqlite3_finalize(queryStatement)

    return maxSetID + 1
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

  func insertEntry(
    exerciseName: String, exerciseType: String, duration: Int32, date: Date, set_id: Int32,
    reps: Int32, distance: Float? = nil, distanceUnit: String? = nil, weight: Float? = nil,
    weightUnit: String? = nil
  ) -> Int32? {
    let insertStatementString =
      "INSERT INTO fitness_entries (exercise_name, exercise_type, duration, date, set_id, reps, distance, distance_unit, weight, weight_unit) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    var insertStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      let timestamp = Int32(date.timeIntervalSince1970)

      sqlite3_bind_text(insertStatement, 1, (exerciseName as NSString).utf8String, -1, nil)
      sqlite3_bind_text(insertStatement, 2, (exerciseType as NSString).utf8String, -1, nil)
      sqlite3_bind_int(insertStatement, 3, duration)
      sqlite3_bind_int(insertStatement, 4, timestamp)
      sqlite3_bind_int(insertStatement, 5, set_id)
      sqlite3_bind_int(insertStatement, 6, reps)

      if let distance = distance {
        sqlite3_bind_double(insertStatement, 7, Double(distance))
      } else {
        sqlite3_bind_null(insertStatement, 7)
      }

      if let distanceUnit = distanceUnit {
        sqlite3_bind_text(insertStatement, 8, (distanceUnit as NSString).utf8String, -1, nil)
      } else {
        sqlite3_bind_null(insertStatement, 8)
      }

      if let weight = weight {
        sqlite3_bind_double(insertStatement, 9, Double(weight))
      } else {
        sqlite3_bind_null(insertStatement, 9)
      }

      if let weightUnit = weightUnit {
        sqlite3_bind_text(insertStatement, 10, (weightUnit as NSString).utf8String, -1, nil)
      } else {
        sqlite3_bind_null(insertStatement, 10)
      }

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        let entryId = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(insertStatement)
        return Int32(entryId)
      }
    }
    sqlite3_finalize(insertStatement)
    return nil
  }

  func fetchEntries(for date: Date) -> [FitnessEntry] {
    var entries: [FitnessEntry] = []
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    let startTimestamp = Int32(startOfDay.timeIntervalSince1970)
    let endTimestamp = Int32(endOfDay.timeIntervalSince1970)

    let queryStatementString =
      "SELECT * FROM fitness_entries WHERE date >= ? AND date < ? ORDER BY date DESC"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(queryStatement, 1, startTimestamp)
      sqlite3_bind_int(queryStatement, 2, endTimestamp)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let exerciseName = String(cString: sqlite3_column_text(queryStatement, 1))
        let exerciseType = String(cString: sqlite3_column_text(queryStatement, 2))
        let duration = sqlite3_column_int(queryStatement, 3)
        let timestamp = sqlite3_column_int(queryStatement, 4)
        let set_id = sqlite3_column_int(queryStatement, 5)
        let reps = sqlite3_column_int(queryStatement, 6)
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        var distance: Float?
        var distanceUnit: String?
        var weight: Float?
        var weightUnit: String?

        if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
          distance = Float(sqlite3_column_double(queryStatement, 7))
        }
        if sqlite3_column_type(queryStatement, 8) != SQLITE_NULL {
          distanceUnit = String(cString: sqlite3_column_text(queryStatement, 8))
        }
        if sqlite3_column_type(queryStatement, 9) != SQLITE_NULL {
          weight = Float(sqlite3_column_double(queryStatement, 9))
        }
        if sqlite3_column_type(queryStatement, 10) != SQLITE_NULL {
          weightUnit = String(cString: sqlite3_column_text(queryStatement, 10))
        }

        entries.append(
          FitnessEntry(
            id: id, exerciseName: exerciseName, exerciseType: exerciseType, duration: duration,
            date: date, set_id: set_id, reps: reps, distance: distance, distanceUnit: distanceUnit,
            weight: weight, weightUnit: weightUnit))
      }
    }
    sqlite3_finalize(queryStatement)
    return entries
  }

  // Add category methods
  func insertCategory(name: String) -> Int32? {
    let insertStatementString = "INSERT INTO categories (name) VALUES (?)"
    var insertStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        let categoryId = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(insertStatement)
        return Int32(categoryId)
      }
    }
    sqlite3_finalize(insertStatement)
    return nil
  }

  func fetchCategories() -> [Category] {
    var categories: [Category] = []
    let queryStatementString = "SELECT * FROM categories ORDER BY name"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        categories.append(Category(id: id, name: name))
      }
    }
    sqlite3_finalize(queryStatement)
    return categories
  }

  func linkEntryToCategory(entryId: Int32, categoryId: Int32) -> Bool {
    let insertStatementString = "INSERT INTO entry_categories (entry_id, category_id) VALUES (?, ?)"
    var insertStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(insertStatement, 1, entryId)
      sqlite3_bind_int(insertStatement, 2, categoryId)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        sqlite3_finalize(insertStatement)
        return true
      }
    }
    sqlite3_finalize(insertStatement)
    return false
  }

  func getCategoriesForEntry(entryId: Int32) -> [Category] {
    var categories: [Category] = []
    let queryStatementString = """
          SELECT c.id, c.name FROM categories c
          INNER JOIN entry_categories ec ON c.id = ec.category_id
          WHERE ec.entry_id = ?
          ORDER BY c.name
      """
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(queryStatement, 1, entryId)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        categories.append(Category(id: id, name: name))
      }
    }
    sqlite3_finalize(queryStatement)
    return categories
  }

  // Add exercise type methods
  func insertExerciseType(name: String, type: String) -> Int32? {
    let insertStatementString = "INSERT INTO exercise_types (name, type) VALUES (?, ?)"
    var insertStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
      sqlite3_bind_text(insertStatement, 2, (type as NSString).utf8String, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        let typeId = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(insertStatement)
        return Int32(typeId)
      }
    }
    sqlite3_finalize(insertStatement)
    return nil
  }

  func fetchExerciseTypes() -> [ExerciseType] {
    var types: [ExerciseType] = []
    let queryStatementString = "SELECT * FROM exercise_types ORDER BY name"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        let type = String(cString: sqlite3_column_text(queryStatement, 2))
        types.append(ExerciseType(id: id, name: name, type: type))
      }
    }
    sqlite3_finalize(queryStatement)
    return types
  }

  func linkExerciseTypeToCategory(exerciseTypeId: Int32, categoryId: Int32) -> Bool {
    let insertStatementString =
      "INSERT INTO exercise_type_categories (exercise_type_id, category_id) VALUES (?, ?)"
    var insertStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(insertStatement, 1, exerciseTypeId)
      sqlite3_bind_int(insertStatement, 2, categoryId)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        sqlite3_finalize(insertStatement)
        return true
      }
    }
    sqlite3_finalize(insertStatement)
    return false
  }

  func getCategoriesForExerciseType(exerciseTypeId: Int32) -> [Category] {
    var categories: [Category] = []
    let queryStatementString = """
          SELECT c.id, c.name
          FROM categories c
          INNER JOIN exercise_type_categories etc ON c.id = etc.category_id
          WHERE etc.exercise_type_id = ?
          ORDER BY c.name
      """
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(queryStatement, 1, exerciseTypeId)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        categories.append(Category(id: id, name: name))
      }
    }
    sqlite3_finalize(queryStatement)
    return categories
  }

  func getExerciseTypesForCategory(categoryId: Int32) -> [ExerciseType] {
    var exerciseTypes: [ExerciseType] = []

    let query = """
          SELECT et.* FROM exercise_types et
          JOIN exercise_type_categories etc ON et.id = etc.exercise_type_id
          WHERE etc.category_id = ?
          ORDER BY et.name
      """

    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(queryStatement, 1, categoryId)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        let type = String(cString: sqlite3_column_text(queryStatement, 2))
        exerciseTypes.append(ExerciseType(id: id, name: name, type: type))
      }
    }
    sqlite3_finalize(queryStatement)
    return exerciseTypes
  }

  func updateExerciseType(id: Int32, name: String, type: String) -> Bool {
    let updateStatementString = "UPDATE exercise_types SET name = ?, type = ? WHERE id = ?"
    var updateStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
      sqlite3_bind_text(updateStatement, 2, (type as NSString).utf8String, -1, nil)
      sqlite3_bind_int(updateStatement, 3, id)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        sqlite3_finalize(updateStatement)
        return true
      }
    }
    sqlite3_finalize(updateStatement)
    return false
  }

  func updateExerciseTypeCategory(exerciseTypeId: Int32, categoryId: Int32) -> Bool {
    // First delete existing category link
    let deleteStatementString = "DELETE FROM exercise_type_categories WHERE exercise_type_id = ?"
    var deleteStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(deleteStatement, 1, exerciseTypeId)

      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        sqlite3_finalize(deleteStatement)
        // Then add new category link
        return linkExerciseTypeToCategory(exerciseTypeId: exerciseTypeId, categoryId: categoryId)
      }
    }
    sqlite3_finalize(deleteStatement)
    return false
  }

  func deleteEntriesBySetId(setId: Int32) {
    let deleteStatementString = "DELETE FROM fitness_entries WHERE set_id = ?"
    var deleteStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(deleteStatement, 1, setId)

      if sqlite3_step(deleteStatement) != SQLITE_DONE {
        print("Error deleting entries for set_id: \(setId)")
      }
    }
    sqlite3_finalize(deleteStatement)
  }

  func exportToCSV() -> String {
    var csvString =
      "ID,Exercise Name,Exercise Type,Duration,Date,set_id,Reps,Distance,Distance Unit,Weight,Weight Unit\n"
    let query = "SELECT * FROM fitness_entries ORDER BY date DESC"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let exerciseName = String(cString: sqlite3_column_text(queryStatement, 1))
        let exerciseType = String(cString: sqlite3_column_text(queryStatement, 2))
        let duration = sqlite3_column_int(queryStatement, 3)
        let timestamp = sqlite3_column_int(queryStatement, 4)
        let set_id = sqlite3_column_int(queryStatement, 5)
        let reps = sqlite3_column_int(queryStatement, 6)

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: date)

        var distance = "N/A"
        var distanceUnit = "N/A"
        var weight = "N/A"
        var weightUnit = "N/A"

        if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
          distance = String(Float(sqlite3_column_double(queryStatement, 7)))
        }
        if sqlite3_column_type(queryStatement, 8) != SQLITE_NULL {
          distanceUnit = String(cString: sqlite3_column_text(queryStatement, 8))
        }
        if sqlite3_column_type(queryStatement, 9) != SQLITE_NULL {
          weight = String(Float(sqlite3_column_double(queryStatement, 9)))
        }
        if sqlite3_column_type(queryStatement, 10) != SQLITE_NULL {
          weightUnit = String(cString: sqlite3_column_text(queryStatement, 10))
        }

        let row =
          "\(id),\"\(exerciseName)\",\"\(exerciseType)\",\(duration),\"\(dateString)\",\(set_id),\(reps),\(distance),\(distanceUnit),\(weight),\(weightUnit)\n"
        csvString.append(row)
      }
    }
    sqlite3_finalize(queryStatement)
    return csvString
  }

  func fetchAllExerciseTypes() -> [ExerciseType] {
    var exerciseTypes: [ExerciseType] = []
    let queryStatementString = "SELECT * FROM exercise_types ORDER BY name"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        let type = String(cString: sqlite3_column_text(queryStatement, 2))
        exerciseTypes.append(ExerciseType(id: id, name: name, type: type))
      }
    }
    sqlite3_finalize(queryStatement)
    return exerciseTypes
  }

  func fetchEntriesBySetId(setId: Int32) -> [FitnessEntry] {
    var entries: [FitnessEntry] = []
    let queryStatementString = "SELECT * FROM fitness_entries WHERE set_id = ?"
    var queryStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(queryStatement, 1, setId)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        let exerciseName = String(cString: sqlite3_column_text(queryStatement, 1))
        let exerciseType = String(cString: sqlite3_column_text(queryStatement, 2))
        let duration = sqlite3_column_int(queryStatement, 3)
        let timestamp = sqlite3_column_int(queryStatement, 4)
        let set_id = sqlite3_column_int(queryStatement, 5)
        let reps = sqlite3_column_int(queryStatement, 6)
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        var distance: Float?
        var distanceUnit: String?
        var weight: Float?
        var weightUnit: String?

        if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
          distance = Float(sqlite3_column_double(queryStatement, 7))
        }
        if sqlite3_column_type(queryStatement, 8) != SQLITE_NULL {
          distanceUnit = String(cString: sqlite3_column_text(queryStatement, 8))
        }
        if sqlite3_column_type(queryStatement, 9) != SQLITE_NULL {
          weight = Float(sqlite3_column_double(queryStatement, 9))
        }
        if sqlite3_column_type(queryStatement, 10) != SQLITE_NULL {
          weightUnit = String(cString: sqlite3_column_text(queryStatement, 10))
        }

        entries.append(
          FitnessEntry(
            id: id, exerciseName: exerciseName, exerciseType: exerciseType, duration: duration,
            date: date, set_id: set_id, reps: reps, distance: distance, distanceUnit: distanceUnit,
            weight: weight, weightUnit: weightUnit))
      }
    }
    sqlite3_finalize(queryStatement)
    return entries
  }
  func deleteExerciseType(id: Int32) -> Bool {
    let deleteStatementString = "DELETE FROM exercise_types WHERE id = ?"
    var deleteStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(deleteStatement, 1, id)

      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        sqlite3_finalize(deleteStatement)
        return true
      }
    }
    sqlite3_finalize(deleteStatement)
    return false
  }

  func deleteCategory(id: Int32) -> Bool {
    let deleteStatementString = "DELETE FROM categories WHERE id = ?"
    var deleteStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(deleteStatement, 1, id)

      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        sqlite3_finalize(deleteStatement)
        return true
      }
    }
    sqlite3_finalize(deleteStatement)
    return false
  }

  func updateCategory(id: Int32, name: String) -> Bool {
    let updateStatementString = "UPDATE categories SET name = ? WHERE id = ?"
    var updateStatement: OpaquePointer?

    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
      sqlite3_bind_int(updateStatement, 2, id)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        sqlite3_finalize(updateStatement)
        return true
      }
    }
    sqlite3_finalize(updateStatement)
    return false
  }
}
