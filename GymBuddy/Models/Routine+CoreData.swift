import CoreData

extension Routine {
    var routineID: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var routineDay: String {
        get { day ?? "" }
        set { day = newValue }
    }
    
    var routineNotes: String? {
        get { notes }
        set { notes = newValue }
    }
    
    var muscleGroupsArray: [String] {
        get { targetMuscleGroups as? [String] ?? [] }
        set { targetMuscleGroups = newValue as NSArray }
    }
    
    var blockArray: [Block] {
        let set = blocks as? Set<Block> ?? []
        return Array(set).sorted { $0.blockName < $1.blockName }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Routine> {
        return NSFetchRequest<Routine>(entityName: "Routine")
    }
} 
