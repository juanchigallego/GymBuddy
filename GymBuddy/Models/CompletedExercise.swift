import CoreData

@objc(CompletedExercise)
public class CompletedExercise: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var exerciseName: String?
    @NSManaged public var repsPerSet: Int16
    @NSManaged public var weight: Double
    @NSManaged public var notes: String?
    @NSManaged public var block: CompletedBlock?
    @NSManaged public var progress: ExerciseProgress?  // Link to progress entry
    
    public var completedExerciseName: String {
        get { exerciseName ?? "" }
        set { exerciseName = newValue }
    }
    
    // Create progress entry when weight is logged
    public func logProgress() {
        let context = self.managedObjectContext!
        let progress = ExerciseProgress(context: context)
        progress.id = UUID()
        progress.date = block?.workout?.date
        progress.weight = weight
        progress.reps = repsPerSet
        progress.exerciseName = exerciseName
        progress.notes = notes
        self.progress = progress
        
        try? context.save()
    }
} 