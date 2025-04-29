//
//  ContentView.swift
//  MonAppli
//
//  Created by Thomas on 27/04/2025.
//

import SwiftUI

struct HomeView: View {
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
            ZStack {
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
                
                VStack {
                    Spacer()
                    NavigationLink(destination: CategoryPicker(selectedDate: currentDate)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .padding(.bottom, 16)
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

