import Foundation

struct DateUtils {
    static let shared = DateUtils()
    
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let relativeDateFormatter: RelativeDateTimeFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        relativeDateFormatter = RelativeDateTimeFormatter()
        relativeDateFormatter.dateTimeStyle = .named
    }
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    func formatRelative(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: seconds) ?? "0s"
    }
    
    func formatShortDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: seconds) ?? "00:00"
    }
} 