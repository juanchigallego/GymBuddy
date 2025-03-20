import SwiftUI
import CoreData

@MainActor
class RoutineViewModel: ObservableObject {
    // Logger for this class
    private let logger = Logger(category: "RoutineViewModel")
    
    @Published var routines: [Routine] = []
    @Published var isAddingRoutine = false
    @Published var isEditingRoutine = false
    @Published var routineToEdit: Routine?
    @Published var isEditingBlock = false
    @Published var blockToEdit: Block?
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchRoutines()
    }
    
    var favoriteRoutines: [Routine] {
        routines.filter { $0.isFavorite && !$0.isArchived }
    }
    
    var activeRoutines: [Routine] {
        routines.filter { !$0.isArchived }
    }
    
    var archivedRoutines: [Routine] {
        routines.filter { $0.isArchived }
    }
    
    func fetchRoutines() {
        let request = NSFetchRequest<Routine>(entityName: "Routine")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Routine.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \Routine.day, ascending: true)
        ]
        
        do {
            routines = try viewContext.fetch(request)
            logger.info("Fetched \(routines.count) routines")
        } catch {
            logger.error("Error fetching routines: \(error.localizedDescription)")
        }
    }
    
    func addRoutine(day: String, muscleGroups: [String], blocks: [Block], notes: String?) {
        viewContext.perform {
            let newRoutine = Routine(context: self.viewContext)
            newRoutine.id = UUID()
            newRoutine.day = day
            newRoutine.targetMuscleGroups = muscleGroups as NSArray
            newRoutine.notes = notes
            
            // Set up relationships with existing blocks
            let blockSet = NSSet(array: blocks)
            newRoutine.blocks = blockSet
            
            // Update the inverse relationships
            for block in blocks {
                block.routine = newRoutine
            }
            
            do {
                try self.viewContext.save()
                self.fetchRoutines()
                self.logger.info("Added new routine: \(day)")
            } catch {
                self.logger.error("Error saving routine: \(error.localizedDescription)")
            }
        }
    }
    
    func addBlock(to routine: Routine, name: String) {
        let block = Block(context: viewContext)
        block.id = UUID()
        block.name = name
        block.routine = routine
        
        do {
            try viewContext.save()
            fetchRoutines()
            logger.info("Added block '\(name)' to routine '\(routine.routineDay)'")
        } catch {
            logger.error("Error adding block: \(error.localizedDescription)")
        }
    }
    
    func addExercise(to block: Block, name: String, reps: Int16, weight: Double) {
        let exercise = Exercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = name
        exercise.repsPerSet = reps
        exercise.weight = weight
        exercise.block = block
        
        do {
            try viewContext.save()
            fetchRoutines()
            logger.info("Added exercise '\(name)' to block '\(block.blockName)'")
        } catch {
            logger.error("Error adding exercise: \(error.localizedDescription)")
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        viewContext.delete(routine)
        do {
            try viewContext.save()
            fetchRoutines()
            logger.info("Deleted routine: \(routine.routineDay)")
        } catch {
            logger.error("Error deleting routine: \(error.localizedDescription)")
        }
    }
    
    func deleteBlock(_ block: Block) {
        viewContext.delete(block)
        do {
            try viewContext.save()
            fetchRoutines()
            logger.info("Deleted block: \(block.blockName)")
        } catch {
            logger.error("Error deleting block: \(error.localizedDescription)")
        }
    }
    
    func deleteExercise(_ exercise: Exercise) {
        viewContext.delete(exercise)
        do {
            try viewContext.save()
            fetchRoutines()
            logger.info("Deleted exercise: \(exercise.exerciseName)")
        } catch {
            logger.error("Error deleting exercise: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(_ routine: Routine) {
        routine.isFavorite.toggle()
        saveContext()
        logger.info("Toggled favorite status for routine: \(routine.routineDay) (\(routine.isFavorite ? "favorite" : "not favorite"))")
    }
    
    func toggleArchived(_ routine: Routine) {
        routine.isArchived.toggle()
        saveContext()
        logger.info("Toggled archived status for routine: \(routine.routineDay) (\(routine.isArchived ? "archived" : "active"))")
    }
    
    func updateRoutine(_ routine: Routine, day: String, muscleGroups: [String], notes: String?) {
        routine.day = day
        routine.targetMuscleGroups = muscleGroups as NSArray
        routine.notes = notes
        
        saveContext()
        logger.info("Updated routine: \(day)")
    }
    
    func updateBlock(_ block: Block, name: String, sets: Int16, restSeconds: Int16) {
        block.name = name
        block.sets = sets
        block.restSeconds = restSeconds
        
        saveContext()
        logger.info("Updated block: \(name)")
    }
    
    func updateExercise(_ exercise: Exercise, name: String, reps: Int16, weight: Double, targetMuscles: [String], notes: String?) {
        exercise.name = name
        exercise.repsPerSet = reps
        exercise.weight = weight
        exercise.targetMuscles = targetMuscles as NSArray
        exercise.notes = notes
        
        saveContext()
        logger.info("Updated exercise: \(name)")
        
        // Post notification that exercise was updated
        NotificationCenter.default.post(
            name: Constants.NotificationNames.didUpdateExercise,
            object: nil,
            userInfo: ["exercise": exercise]
        )
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            fetchRoutines()
        } catch {
            logger.error("Error saving context: \(error.localizedDescription)")
        }
    }
} 