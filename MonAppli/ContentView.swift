//
//  ContentView.swift
//  MonAppli
//
//  Created by Thomas on 27/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var exerciseName: String = ""
    @State private var duration: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var fitnessEntries: [FitnessEntry] = []
    @State private var currentDate: Date = Date()
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: Int32?
    @State private var showingCategorySheet = false
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(currentDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                        
                        
                        
                        Button(action: {
                            currentDate = Date()
                        }) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        }
                        .padding(.leading, 8)
                        Spacer()
                        Button(action: {
                            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                        
                    }
                    .padding(.horizontal)
                    
                    TextField("Enter Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    TextField("Enter Duration (in minutes)", text: $duration)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                        
                    TextField("Number of Sets", text: $sets)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                        
                    TextField("Number of Reps", text: $reps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("No Category").tag(nil as Int32?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as Int32?)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        showingCategorySheet = true
                    }) {
                        Text("Add New Category")
                            .font(.subheadline)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        if !exerciseName.isEmpty && !duration.isEmpty {
                            if let entryId = DatabaseHelper.shared.insertEntry(
                                exerciseName: exerciseName,
                                duration: duration,
                                date: currentDate,
                                sets: Int32(sets) ?? 0,
                                reps: Int32(reps) ?? 0
                            ) {
                                if let categoryId = selectedCategoryId {
                                    _ = DatabaseHelper.shared.linkEntryToCategory(entryId: entryId, categoryId: categoryId)
                                }
                                fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
                                exerciseName = ""
                                duration = ""
                                sets = ""
                                reps = ""
                                hideKeyboard()
                            }
                        }
                    }) {
                        Text("Add Fitness Entry")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: ExerciseTypeView()) {
                        Text("Manage Exercise Types")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    ForEach(fitnessEntries) { entry in
                        VStack(alignment: .leading) {
                            Text("Exercise: \(entry.exerciseName)")
                                .font(.headline)
                            Text("Duration: \(entry.duration) minutes")
                                .font(.subheadline)
                            Text("Sets: \(entry.sets) | Reps: \(entry.reps)")
                                .font(.subheadline)
                            let categories = DatabaseHelper.shared.getCategoriesForEntry(entryId: entry.id)
                            if !categories.isEmpty {
                                Text("Categories: \(categories.map { $0.name }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showingCategorySheet) {
                NavigationView {
                    Form {
                        TextField("Category Name", text: $newCategoryName)
                        Button("Add Category") {
                            if !newCategoryName.isEmpty {
                                _ = DatabaseHelper.shared.insertCategory(name: newCategoryName)
                                categories = DatabaseHelper.shared.fetchCategories()
                                newCategoryName = ""
                                showingCategorySheet = false
                            }
                        }
                    }
                    .navigationTitle("New Category")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingCategorySheet = false
                    })
                }
            }
            .onChange(of: currentDate) { _ in
                fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
            }
            .onAppear {
                fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
                categories = DatabaseHelper.shared.fetchCategories()
            }
            .navigationTitle("Fitness Tracker")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ContentView()
}
