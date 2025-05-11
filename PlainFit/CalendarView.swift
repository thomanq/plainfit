import SwiftUI

struct CalendarView: View {
  @Environment(\.dismiss) var dismiss
  @Binding var selectedDate: Date
  @State private var months: [Date] = []
  @State private var scrollOffset: CGFloat = 0
  @AppStorage("weekStart") private var weekStart = WeekStart.sunday

  private let calendar = Calendar.current
  private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  init(selectedDate: Binding<Date>) {
    self._selectedDate = selectedDate
    let initialMonths = (-2...2).compactMap { offset in
      calendar.date(byAdding: .month, value: offset, to: selectedDate.wrappedValue)
    }
    _months = State(initialValue: initialMonths)
  }

  private func loadMoreMonths(direction: ScrollDirection) {
    switch direction {
    case .up:
      guard let firstMonth = months.first else { return }
      let newMonths = (-2...(-1)).compactMap { offset in
        calendar.date(byAdding: .month, value: offset, to: firstMonth)
      }
      months.insert(contentsOf: newMonths, at: 0)
    case .down:
      guard let lastMonth = months.last else { return }
      let newMonths = (1...2).compactMap { offset in
        calendar.date(byAdding: .month, value: offset, to: lastMonth)
      }
      months.append(contentsOf: newMonths)
    }
  }

  func weekDays() -> [String] {
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    switch weekStart {
    case .sunday:
      return days
    case .monday:
      return Array(days[1...]) + [days[0]]
    case .saturday:
      return [days.last!] + Array(days[..<6])
    }
  }

  var body: some View {
    NavigationView {
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: 20) {
            ForEach(months, id: \.self) { month in
              MonthView(
                month: month, selectedDate: $selectedDate, weekStart: weekStart
              )
              .id(monthFormatter.string(from: month))
              .onAppear {
                if month == months.last {
                  loadMoreMonths(direction: .down)
                } else if month == months.first {
                  loadMoreMonths(direction: .up)
                }
              }
            }
          }
        }
        .onAppear {
          if let scrollToDate = calendar.date(
            byAdding: .month, value: 2, to: selectedDate)
          {
            proxy.scrollTo(monthFormatter.string(from: scrollToDate), anchor: .center)
          }
        }
        .navigationBarItems(
          trailing: Button("Done") {
            dismiss()
          })
      }
    }
  }
}

private enum ScrollDirection {
  case up, down
}

struct MonthView: View {
  let month: Date
  @Binding var selectedDate: Date
  let weekStart: WeekStart
  @State private var activitySummary: FitnessActivitySummary? = nil

  private let calendar = Calendar.current
  private let cellWidth: CGFloat = 50
  private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  private func weeksForMonth(date: Date) -> [[Date]] {
    var weeks: [[Date]] = []
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!

    let weekday = calendar.component(.weekday, from: monthStart) - 1
    // Sunday = 0, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6
    let daysToSubtract: Int

    switch weekStart {
    case .saturday:
      daysToSubtract = weekday + 1
    case .sunday:
      daysToSubtract = weekday
    case .monday:
      daysToSubtract = weekday == 0 ? 6 : weekday - 1
    }

    let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthStart)!

    var week: [Date] = []
    var currentDate = startDate

    while weeks.count < 6 {
      week.append(currentDate)

      if week.count == 7 {
        weeks.append(week)
        week = []
      }

      currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }

    return weeks
  }

  var body: some View {
    VStack {
      Text(monthFormatter.string(from: month))
        .font(.title2)
        .bold()
        .padding(.bottom)

      HStack {
        ForEach(CalendarView(selectedDate: $selectedDate).weekDays(), id: \.self) { day in
          Text(day)
            .frame(width: cellWidth).padding(.bottom, 10)
        }
      }
      .padding(.horizontal)

      VStack {
        ForEach(weeksForMonth(date: month), id: \.self) { week in
          HStack {
            ForEach(week, id: \.self) { date in
              let dayNumber = Calendar.current.component(.day, from: date)
              let activities = activitySummary?.activity[dayNumber] ?? Set<FitnessActivity>()
              DayCell(
                date: date,
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                isMonday: calendar.component(.weekday, from: date) == 2,
                isCurrentMonth: calendar.isDate(
                  date, equalTo: month, toGranularity: .month),
                cellWidth: cellWidth,
                activities: activities
              )
              .onTapGesture {
                selectedDate = date
              }
            }
          }
        }
      }
      .padding(.bottom)
    }
    .onAppear {
      activitySummary = DatabaseHelper.shared.getFitnessActivityForMonth(date: month)
    }
  }
}

struct DayCell: View {
  let date: Date
  let isSelected: Bool
  let isMonday: Bool
  let isCurrentMonth: Bool
  let cellWidth: CGFloat
  let activities: Set<FitnessActivity>

  private let calendar = Calendar.current
  private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
  }()

  var body: some View {
    VStack(spacing: 4) {
      Text(dayFormatter.string(from: date))
        .frame(width: cellWidth, height: cellWidth - 10)
        .foregroundColor(isCurrentMonth ? .primary : .gray.opacity(0.5))
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(isSelected && isCurrentMonth ? Color.blue : Color.clear, lineWidth: 3)
        )
        .offset(y: -10)

      if isCurrentMonth {

        let activityChunks = Array(activities).chunked(into: 2)
        ForEach(activityChunks, id: \.self) { chunk in
          HStack(spacing: 0) {
            ForEach(chunk, id: \.self) { activity in
              Image(systemName: activity.exerciseType.iconName ?? activity.category.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(
                  Color(hex: activity.exerciseType.iconColor ?? activity.category.iconColor)
                )
            }.offset(y: -10)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.leading, 6)
          }
        }
      }
      Spacer(minLength: 0)
    }.frame(width: cellWidth)
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}
