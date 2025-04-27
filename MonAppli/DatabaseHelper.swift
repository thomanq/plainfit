import Foundation
import SQLite3

struct Category: Identifiable {
    let id: Int32
    let name: String
    let isSelected: Bool
}

struct FitnessEntry: Identifiable {
    let id: Int32
    let exerciseName: String
    let duration: String
    let date: Date
    let sets: Int32
    let reps: Int32
    let distance: Float?
    let distanceUnit: String?
    let weight: Float?
    let weightUnit: String?
}

struct ExerciseType: Identifiable {
    let id: Int32
    let name: String
    let type: String
}

class DatabaseHelper {
    static let shared = DatabaseHelper()
    private var db: OpaquePointer?

    private init() {
        if let dbPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("fitness.db").path {
            if sqlite3_open(dbPath, &db) == SQLITE_OK {
                // Create fitness_entries table
                if sqlite3_exec(db, """
                    CREATE TABLE IF NOT EXISTS fitness_entries (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        exercise_name TEXT,
                        duration TEXT,
                        date INTEGER,
                        sets INTEGER,
                        reps INTEGER,
                        distance REAL,
                        distance_unit TEXT,
                        weight REAL,
                        weight_unit TEXT
                    )
                    """, nil, nil, nil) != SQLITE_OK {
                    print("Error creating fitness_entries table")
                }
                
                // Create categories table
                if sqlite3_exec(db, """
                    CREATE TABLE IF NOT EXISTS categories (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT UNIQUE
                    )
                    """, nil, nil, nil) != SQLITE_OK {
                    print("Error creating categories table")
                }
                
                // Create entry_categories table for many-to-many relationship
                if sqlite3_exec(db, """
                    CREATE TABLE IF NOT EXISTS entry_categories (
                        entry_id INTEGER,
                        category_id INTEGER,
                        PRIMARY KEY (entry_id, category_id),
                        FOREIGN KEY (entry_id) REFERENCES fitness_entries(id) ON DELETE CASCADE,
                        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
                    )
                    """, nil, nil, nil) != SQLITE_OK {
                    print("Error creating entry_categories table")
                }
                
                // Create exercise_types table
                if sqlite3_exec(db, """
                    CREATE TABLE IF NOT EXISTS exercise_types (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        type TEXT NOT NULL
                    )
                    """, nil, nil, nil) != SQLITE_OK {
                    print("Error creating exercise_types table")
                }
                
                // Create exercise_type_categories table for many-to-many relationship
                if sqlite3_exec(db, """
                    CREATE TABLE IF NOT EXISTS exercise_type_categories (
                        exercise_type_id INTEGER,
                        category_id INTEGER,
                        PRIMARY KEY (exercise_type_id, category_id),
                        FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id) ON DELETE CASCADE,
                        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
                    )
                    """, nil, nil, nil) != SQLITE_OK {
                    print("Error creating exercise_type_categories table")
                }
                
                // Insert a test category if none exist
                let checkCategoriesQuery = "SELECT COUNT(*) FROM categories"
                var queryStatement: OpaquePointer?
                if sqlite3_prepare_v2(db, checkCategoriesQuery, -1, &queryStatement, nil) == SQLITE_OK {
                    if sqlite3_step(queryStatement) == SQLITE_ROW {
                        let count = sqlite3_column_int(queryStatement, 0)
                        if count == 0 {
                            _ = insertCategory(name: "Cardio")
                            _ = insertCategory(name: "Strength")
                            _ = insertCategory(name: "Flexibility")
                        }
                    }
                }
                sqlite3_finalize(queryStatement)
            }
        }
    }

    func insertEntry(exerciseName: String, duration: String, date: Date, sets: Int32, reps: Int32, distance: Float? = nil, distanceUnit: String? = nil, weight: Float? = nil, weightUnit: String? = nil) -> Int32? {
        let insertStatementString = "INSERT INTO fitness_entries (exercise_name, duration, date, sets, reps, distance, distance_unit, weight, weight_unit) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let timestamp = Int32(date.timeIntervalSince1970)
            
            sqlite3_bind_text(insertStatement, 1, (exerciseName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (duration as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 3, timestamp)
            sqlite3_bind_int(insertStatement, 4, sets)
            sqlite3_bind_int(insertStatement, 5, reps)
            
            if let distance = distance {
                sqlite3_bind_double(insertStatement, 6, Double(distance))
            } else {
                sqlite3_bind_null(insertStatement, 6)
            }
            
            if let distanceUnit = distanceUnit {
                sqlite3_bind_text(insertStatement, 7, (distanceUnit as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 7)
            }
            
            if let weight = weight {
                sqlite3_bind_double(insertStatement, 8, Double(weight))
            } else {
                sqlite3_bind_null(insertStatement, 8)
            }
            
            if let weightUnit = weightUnit {
                sqlite3_bind_text(insertStatement, 9, (weightUnit as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 9)
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

        let queryStatementString = "SELECT * FROM fitness_entries WHERE date >= ? AND date < ? ORDER BY date DESC"
        var queryStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, startTimestamp)
            sqlite3_bind_int(queryStatement, 2, endTimestamp)

            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let exerciseName = String(cString: sqlite3_column_text(queryStatement, 1))
                let duration = String(cString: sqlite3_column_text(queryStatement, 2))
                let timestamp = sqlite3_column_int(queryStatement, 3)
                let sets = sqlite3_column_int(queryStatement, 4)
                let reps = sqlite3_column_int(queryStatement, 5)
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                
                var distance: Float?
                var distanceUnit: String?
                var weight: Float?
                var weightUnit: String?
                
                if sqlite3_column_type(queryStatement, 6) != SQLITE_NULL {
                    distance = Float(sqlite3_column_double(queryStatement, 6))
                }
                if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
                    distanceUnit = String(cString: sqlite3_column_text(queryStatement, 7))
                }
                if sqlite3_column_type(queryStatement, 8) != SQLITE_NULL {
                    weight = Float(sqlite3_column_double(queryStatement, 8))
                }
                if sqlite3_column_type(queryStatement, 9) != SQLITE_NULL {
                    weightUnit = String(cString: sqlite3_column_text(queryStatement, 9))
                }

                entries.append(FitnessEntry(id: id, exerciseName: exerciseName, duration: duration, date: date, sets: sets, reps: reps, distance: distance, distanceUnit: distanceUnit, weight: weight, weightUnit: weightUnit))
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
                categories.append(Category(id: id, name: name, isSelected: false))
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
                categories.append(Category(id: id, name: name, isSelected: false))
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
        let insertStatementString = "INSERT INTO exercise_type_categories (exercise_type_id, category_id) VALUES (?, ?)"
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
                categories.append(Category(id: id, name: name, isSelected: false))
            }
        }
        sqlite3_finalize(queryStatement)
        return categories
    }

}