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
  @State private var showCategoryPicker : Bool = false
  @State private var showingLicense = false
  @State private var licenseText: String = {
    if let licensePath = Bundle.main.path(forResource: "LICENSE", ofType: ""),
       let content = try? String(contentsOfFile: licensePath, encoding: .utf8) {
        return content
    }
    return "License information not available"
  }()
  @State private var showingCalendar = false

  private func formatDuration(_ milliseconds: Int32) -> String {
    let totalSeconds = milliseconds / 1000
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  private func export() {
    let csvString = DatabaseHelper.shared.exportToCSV()
    let activityViewController = UIActivityViewController(
      activityItems: [csvString],
      applicationActivities: nil
    )
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first,
       let rootViewController = window.rootViewController {
      rootViewController.present(activityViewController, animated: true)
    }
  }

  var body: some View {
    NavigationView {
      ZStack {
        ScrollView {
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

            ForEach(fitnessEntries) { entry in
              VStack(alignment: .leading) {
                Text("Exercise: \(entry.exerciseName)")
                  .font(.headline)
                Text("Duration: \(formatDuration(entry.duration))")
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
          NavigationLink(destination: CategoryPicker(selectedDate: currentDate, showCategoryPicker: $showCategoryPicker), isActive: $showCategoryPicker) {
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
            Button(action: export) {
              Label("Export to CSV", systemImage: "square.and.arrow.up")
            }
            Button(action: { showingLicense.toggle() }) {
              Label("View License", systemImage: "doc.text")
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
    .sheet(isPresented: $showingLicense) {
      NavigationView {
        ScrollView {
          Text(licenseText)
            .padding()
        }
        .navigationTitle("License")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              showingLicense = false
            }
          }
        }
      }
    }
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
