import CoreData

extension Exercise {
    var exerciseID: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var exerciseName: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var exerciseNotes: String? {
        get { notes }
        set { notes = newValue }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }
} 
