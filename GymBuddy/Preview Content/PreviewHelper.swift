import CoreData
import Foundation

/// Helper class for creating preview data safely
class PreviewHelper {
    static let shared = PreviewHelper()
    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    
    init() {
        container = NSPersistentContainer(name: "GymBuddy")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load preview store: \(error)")
            }
        }
    }
    
    /// Creates sample exercise with progress data
    func createSampleExercise() -> Exercise {
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = "Bench Press"
        exercise.weight = 100.0
        exercise.repsPerSet = 8
        exercise.notes = "Focus on form and controlled descent"
        exercise.targetMuscles = ["Chest", "Triceps", "Shoulders"] as NSArray
        
        // Create sample progress entries over the last 2 months
        let calendar = Calendar.current
        let today = Date()
        
        let progressions: [(daysAgo: Int, weight: Double)] = [
            (60, 85.0),  // Starting weight
            (45, 87.5),  // Small increase
            (30, 90.0),  // Regular progression
            (21, 92.5),  // Good progress
            (14, 95.0),  // Consistent gains
            (7, 97.5),   // Recent progress
            (0, 100.0)   // Current weight
        ]
        
        for progression in progressions {
            let entry = ExerciseProgress(context: context)
            entry.id = UUID()
            entry.date = calendar.date(byAdding: .day, value: -progression.daysAgo, to: today)
            entry.weight = progression.weight
            entry.reps = 8
            entry.exerciseName = exercise.name
            entry.exercise = exercise
            entry.notes = "Good form, felt strong"
        }
        
        // Create a sample routine and block
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.day = "Push Day"
        routine.targetMuscleGroups = ["Chest", "Shoulders", "Triceps"] as NSArray
        
        let block = Block(context: context)
        block.id = UUID()
        block.name = "Chest"
        block.sets = 4
        block.routine = routine
        
        exercise.block = block
        
        try? context.save()
        return exercise
    }
    
    /// Creates sample progress entries
    func createSampleProgressEntries() -> [ExerciseProgress] {
        let calendar = Calendar.current
        let today = Date()
        var entries: [ExerciseProgress] = []
        
        let progressions: [(daysAgo: Int, weight: Double)] = [
            (60, 85.0),
            (45, 87.5),
            (30, 90.0),
            (21, 92.5),
            (14, 95.0),
            (7, 97.5),
            (0, 100.0)
        ]
        
        for progression in progressions {
            let entry = ExerciseProgress(context: context)
            entry.id = UUID()
            entry.date = calendar.date(byAdding: .day, value: -progression.daysAgo, to: today)
            entry.weight = progression.weight
            entry.reps = 8
            entry.exerciseName = "Bench Press"
            entry.notes = "Good form, felt strong"
            entries.append(entry)
        }
        
        try? context.save()
        return entries
    }
} 