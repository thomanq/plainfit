import SwiftUI

struct CalendarView: View {
  @Environment(\.dismiss) var dismiss
  @Binding var selectedDate: Date
  @State private var currentMonth: Date = Date()
  @State private var currentScrollMonth: Date = Date()

  private let calendar = Calendar.current
  private let cellWidth: CGFloat = 40

  private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  private func monthsArray() -> [Date] {
    (-12...12).compactMap { offset in
      calendar.date(byAdding: .month, value: offset, to: Date())
    }
  }

  private func weeksForMonth(date: Date) -> [[Date]] {
    let monthInterval = calendar.dateInterval(of: .month, for: date)!
    let firstDateOfMonth = monthInterval.start

    var weekStart = calendar.date(
      from:
        calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDateOfMonth))!

    if weekStart > firstDateOfMonth {
      weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
    }

    var weeks: [[Date]] = []
    var currentDate = weekStart

    for _ in 0..<6 {
      var week: [Date] = []
      for _ in 0..<7 {
        week.append(currentDate)
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
      }
      weeks.append(week)
    }

    return weeks
  }

  var body: some View {
    NavigationView {
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: 20) {
            ForEach(monthsArray(), id: \.self) { month in
              VStack {
                Text(monthFormatter.string(from: month))
                  .font(.title2)
                  .bold()
                  .padding(.top)

                // Week day header
                HStack {
                  ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                      .frame(width: cellWidth)
                      .foregroundColor(day == "Mon" ? .red : .primary)
                  }
                }
                .padding(.horizontal)

                // Calendar grid
                VStack {
                  ForEach(weeksForMonth(date: month), id: \.self) { week in
                    HStack {
                      ForEach(week, id: \.self) { date in
                        DayCell(
                          date: date,
                          isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                          isMonday: calendar.component(.weekday, from: date) == 2,
                          isCurrentMonth: calendar.isDate(
                            date, equalTo: month, toGranularity: .month),
                          cellWidth: cellWidth
                        )
                        .onTapGesture {
                          selectedDate = date
                        }
                      }
                    }
                  }
                }
                .padding()
              }
              .id(monthFormatter.string(from: month))
            }
          }
        }
        .onAppear {
          withAnimation {
            proxy.scrollTo(monthFormatter.string(from: selectedDate), anchor: .center)
          }
        }
      }
      .navigationTitle("Calendar")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

struct DayCell: View {
  let date: Date
  let isSelected: Bool
  let isMonday: Bool
  let isCurrentMonth: Bool
  let cellWidth: CGFloat

  private let calendar = Calendar.current
  private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
  }()

  var body: some View {
    Text(dayFormatter.string(from: date))
      .frame(width: cellWidth)
      .aspectRatio(1, contentMode: .fit)
      .foregroundColor(isCurrentMonth ? .primary : .gray.opacity(0.5))
      .background(isMonday && isCurrentMonth ? Color.red.opacity(0.3) : Color.clear)
      .clipShape(Circle())
      .overlay(
        Circle()
          .stroke(isSelected && isCurrentMonth ? Color.blue : Color.clear, lineWidth: 2)
      )
  }
}
