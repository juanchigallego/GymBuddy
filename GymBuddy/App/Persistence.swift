import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GymBuddy")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable automatic lightweight migrations
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Clears all data from the Core Data store
    func resetAllData() {
        let entities = container.managedObjectModel.entities
        let context = container.viewContext
        
        // Clear each entity type
        entities.compactMap({ $0.name }).forEach { entityName in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.persistentStoreCoordinator.execute(batchDeleteRequest, with: context)
            } catch {
                print("Error clearing \(entityName) data: \(error)")
            }
        }
        
        // Save changes
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Error saving after reset: \(nsError), \(nsError.userInfo)")
        }
    }
} 