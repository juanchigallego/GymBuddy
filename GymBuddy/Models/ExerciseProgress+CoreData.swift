import CoreData

extension ExerciseProgress {
    var progressID: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var progressDate: Date {
        get { date ?? Date() }
        set { date = newValue }
    }
    
    var progressNotes: String? {
        get { notes }
        set { notes = newValue }
    }
    
    var progressExerciseName: String {
        get { exerciseName ?? "" }
        set { exerciseName = newValue }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseProgress> {
        return NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
    }
} 