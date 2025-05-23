func formatDuration(_ milliseconds: Int32) -> String {
  let totalSeconds = milliseconds / 1000
  let hours = totalSeconds / 3600
  let minutes = (totalSeconds % 3600) / 60
  let seconds = totalSeconds % 60
  return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func formatValue(_ value: Float?) -> String {
  guard let value = value else { return "" }
  var formattedValue = String(value)
  formattedValue = formattedValue.replacingOccurrences(
    of: "0+$", with: "", options: .regularExpression)
  formattedValue = formattedValue.replacingOccurrences(
    of: "\\.$", with: "", options: .regularExpression)
  return formattedValue
}
