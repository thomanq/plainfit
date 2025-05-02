//
//  ContentView.swift
//  PlainFit
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
  @State private var showCategoryPicker: Bool = false
  @State private var showEditExerciseSet: Bool = false
  @State private var editExerciseSetID: Int32 = 0
  @State private var showingCalendar = false
  @State private var showingSettings = false

  private func export() {
    let csvString = DatabaseHelper.shared.exportToCSV()
    let activityViewController = UIActivityViewController(
      activityItems: [csvString],
      applicationActivities: nil
    )
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first,
      let rootViewController = window.rootViewController
    {
      rootViewController.present(activityViewController, animated: true)
    }
  }

  var body: some View {
    NavigationView {
      ZStack {

        VStack(spacing: 16) {
          HStack {
            Button(action: {
              currentDate =
                Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }) {
              Image(systemName: "chevron.left")
                .foregroundColor(.blue)
            }

            Spacer()

            Button(action: {
              showingCalendar = true
            }) {
              Image(systemName: "calendar")
            }
            .padding(.trailing, 8)

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
              currentDate =
                Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }) {
              Image(systemName: "chevron.right")
                .foregroundColor(.blue)
            }

          }
          .padding(.horizontal)

          let groupedEntries = Dictionary(grouping: fitnessEntries, by: { $0.set_id })
          List {
            ForEach(groupedEntries.keys.sorted(), id: \.self) { setId in
              VStack(alignment: .leading) {

                if let entries: [FitnessEntry] = groupedEntries[setId] {
                  let hasDuration = entries.contains { $0.duration > 0 }
                  let hasReps = entries.contains { $0.reps > 0 }
                  let hasDistance = entries.contains { $0.distance != nil }
                  let hasWeight = entries.contains { $0.weight != nil }

                  VStack(spacing: 0) {

                    if let firstEntry = entries.first {
                      Text(firstEntry.exerciseName)
                        .font(.headline)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // Header row
                    HStack {
                      Text("#")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .frame(width: 20, alignment: .leading)
                        .foregroundColor(.secondary)
                      if hasDuration {
                        Text("Duration")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                      }
                      if hasReps {
                        Text("Reps")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                      if hasDistance {
                        Text("Distance")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                      if hasWeight {
                        Text("Weight")
                          .font(.system(.subheadline, design: .rounded, weight: .medium))
                          .frame(maxWidth: .infinity, alignment: .leading)
                      }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Data rows
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                      HStack {
                        Text("\(index + 1)")
                          .font(.system(.body, design: .rounded))
                          .foregroundColor(.secondary)
                          .frame(width: 20, alignment: .leading)

                        if hasDuration {
                          Text(formatDuration(entry.duration))
                            .font(.system(.body, design: .rounded))
                            .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                        }
                        if hasReps {
                          Text(entry.reps > 0 ? "\(entry.reps)" : "-")
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if hasDistance {
                          Text(entry.distance.map { String(format: "%.1f", $0) } ?? "-")
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if hasWeight {
                          Text(entry.weight.map { String(format: "%.1f", $0) } ?? "-")
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                      }
                      .padding(.vertical, 12)
                      .padding(.horizontal, 8)
                      .background(
                        RoundedRectangle(cornerRadius: 8)
                          .fill(Color.white)
                          .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                      )
                      .padding(.vertical, 2)
                    }
                  }
                  .padding(.horizontal)
                }
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                  deleteSet(setId: setId)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .swipeActions(edge: .leading, allowsFullSwipe: true) {

                Button(action: {
                  editExerciseSetID = setId
                  showEditExerciseSet = true
                }) {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)

              }
            }
          }
          .listStyle(PlainListStyle())
        }
        NavigationLink(
          destination: AddExerciseEntryView(
            exerciseType: nil,
            selectedDate: currentDate,
            showCategoryPicker: $showCategoryPicker,
            showEditExerciseSet: $showEditExerciseSet,
            setID: editExerciseSetID),
          isActive: $showEditExerciseSet
        ) {
          EmptyView()
        }
        VStack {
          Spacer()
          NavigationLink(
            destination: CategoryPicker(
              selectedDate: currentDate, showCategoryPicker: $showCategoryPicker, showEditExerciseSet: $showEditExerciseSet,),
            isActive: $showCategoryPicker
          ) {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 50))
              .foregroundColor(.blue)
              .background(Color.white.clipShape(Circle()))
              .onTapGesture {
                showCategoryPicker = true
              }
          }
          .padding(.bottom, 16)
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("PlainFit Fitness Tracker")
            .font(.headline)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button(action: { showingSettings = true }) {
              Label("Settings", systemImage: "gear")
            }
            Button(action: export) {
              Label("Export to CSV", systemImage: "square.and.arrow.up")
            }
          } label: {
            Image(systemName: "line.horizontal.3")
          }
        }
      }
      .onChange(of: currentDate) { oldValue, newValue in
        fitnessEntries = DatabaseHelper.shared.fetchEntries(for: newValue)
      }
      .onAppear {
        fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
        categories = DatabaseHelper.shared.fetchCategories()
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .sheet(isPresented: $showingCalendar) {
      CalendarView(selectedDate: $currentDate)
    }
    .sheet(isPresented: $showingSettings) {
      NavigationView {
        SettingsView()
      }
    }
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  private func deleteSet(setId: Int32) {
    DatabaseHelper.shared.deleteEntriesBySetId(setId: setId)
    fitnessEntries = DatabaseHelper.shared.fetchEntries(for: currentDate)
  }
}
