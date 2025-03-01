import CoreData

@objc(CompletedWorkout)
public class CompletedWorkout: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var routineName: String?
    @NSManaged public var totalTime: Double
    @NSManaged public var blocks: NSSet?
    
    public var blockArray: [CompletedBlock] {
        let set = blocks as? Set<CompletedBlock> ?? []
        return set.sorted { $0.blockName ?? "" < $1.blockName ?? "" }
    }
    
    public var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public var formattedTotalTime: String {
        let totalSeconds = endDate?.timeIntervalSince(date ?? Date()) ?? totalTime
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) / 60 % 60
        let seconds = Int(totalSeconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
} 