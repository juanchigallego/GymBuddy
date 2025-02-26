import CoreData

extension Block {
    var blockID: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var blockName: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var exerciseArray: [Exercise] {
        let set = exercises as? Set<Exercise> ?? []
        return Array(set).sorted { $0.exerciseName < $1.exerciseName }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Block> {
        return NSFetchRequest<Block>(entityName: "Block")
    }
} 
