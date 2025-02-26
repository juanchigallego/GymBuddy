import SwiftUI
import CoreData

class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var isAddingRoutine = false
    @Published var isEditingRoutine = false
    @Published var isTrackingWorkout = false {
        didSet {
            print("isTrackingWorkout changed from \(oldValue) to \(isTrackingWorkout)")
        }
    }
    @Published var showingWorkoutSheet = false {
        didSet {
            print("showingWorkoutSheet changed from \(oldValue) to \(showingWorkoutSheet)")
        }
    }
    @Published var currentRoutine: Routine? {
        didSet {
            print("currentRoutine changed to \(currentRoutine?.routineDay ?? "nil")")
        }
    }
    @Published var routineToEdit: Routine?
    @Published var isEditingBlock = false
    @Published var blockToEdit: Block?
    @Published var currentBlockIndex = 0
    @Published var isMinimized = false
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchRoutines()
    }
    
    func fetchRoutines() {
        let request = NSFetchRequest<Routine>(entityName: "Routine")
        
        do {
            routines = try viewContext.fetch(request)
        } catch {
            print("Error fetching routines: \(error)")
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
            } catch {
                print("Error saving routine: \(error)")
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
        } catch {
            print("Error adding block: \(error)")
        }
    }
    
    func addExercise(to block: Block, name: String, sets: Int16, reps: Int16, weight: Double) {
        let exercise = Exercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = name
        exercise.sets = sets
        exercise.repsPerSet = reps
        exercise.weight = weight
        exercise.block = block
        
        do {
            try viewContext.save()
            fetchRoutines()
        } catch {
            print("Error adding exercise: \(error)")
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        viewContext.delete(routine)
        do {
            try viewContext.save()
            fetchRoutines()
        } catch {
            print("Error deleting routine: \(error)")
        }
    }
    
    func startWorkout(routine: Routine) {
        print("Starting workout with routine: \(routine.routineDay)")
        
        // Reset completed sets for all exercises
        for block in routine.blockArray {
            for exercise in block.exerciseArray {
                exercise.completedSets = 0
            }
        }
        try? viewContext.save()
        
        // Set up the new workout
        withAnimation {
            currentBlockIndex = 0
            currentRoutine = routine
            isTrackingWorkout = true
            showingWorkoutSheet = true
        }
        isMinimized = false
    }
    
    func minimizeWorkout() {
        withAnimation(.spring()) {
            isMinimized = true
            showingWorkoutSheet = false
        }
    }
    
    func resumeWorkout() {
        withAnimation(.spring()) {
            isMinimized = false
            showingWorkoutSheet = true
        }
    }
    
    func pauseWorkout() {
        withAnimation(.spring()) {
            isMinimized = true
            showingWorkoutSheet = false
        }
    }
    
    func endWorkout() {
        print("Ending workout")
        isTrackingWorkout = false
        showingWorkoutSheet = false
        isMinimized = false
        currentRoutine = nil
        currentBlockIndex = 0
    }
    
    func updateRoutine(_ routine: Routine, day: String, muscleGroups: [String], blocks: [Block], notes: String?) {
        viewContext.perform {
            routine.day = day
            routine.targetMuscleGroups = muscleGroups as NSArray
            routine.notes = notes
            
            // Remove old blocks
            if let existingBlocks = routine.blocks {
                for case let block as Block in existingBlocks {
                    self.viewContext.delete(block)
                }
            }
            
            // Add new blocks
            let blockSet = NSSet(array: blocks)
            routine.blocks = blockSet
            
            // Update inverse relationships
            for block in blocks {
                block.routine = routine
            }
            
            do {
                try self.viewContext.save()
                self.fetchRoutines()
            } catch {
                print("Error updating routine: \(error)")
            }
        }
    }
    
    func updateBlock(_ block: Block, name: String, exercises: [Exercise]) {
        viewContext.perform {
            block.name = name
            
            // Remove old exercises
            if let existingExercises = block.exercises {
                for case let exercise as Exercise in existingExercises {
                    self.viewContext.delete(exercise)
                }
            }
            
            // Add new exercises
            let exerciseSet = NSSet(array: exercises)
            block.exercises = exerciseSet
            
            // Update inverse relationships
            for exercise in exercises {
                exercise.block = block
            }
            
            do {
                try self.viewContext.save()
                self.fetchRoutines()
            } catch {
                print("Error updating block: \(error)")
            }
        }
    }
    
    func updateCurrentBlock(index: Int) {
        currentBlockIndex = index
    }
} 