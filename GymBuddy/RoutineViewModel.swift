import SwiftUI
import CoreData
import ActivityKit

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
    @Published var currentActivity: Activity<WorkoutActivityAttributes>?
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchRoutines()
    }
    
    var currentBlock: Block? {
        guard let currentRoutine = currentRoutine,
              currentBlockIndex < currentRoutine.blockArray.count else {
            return nil
        }
        return currentRoutine.blockArray[currentBlockIndex]
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
        
        // Start Live Activity
        startLiveActivity(routine: routine)
    }
    
    private func startLiveActivity(routine: Routine) {
        let attributes = WorkoutActivityAttributes(
            routineName: routine.routineDay,
            totalBlocks: routine.blockArray.count
        )
        
        let contentState = WorkoutActivityAttributes.ContentState(
            routineName: routine.routineDay,
            currentBlock: routine.blockArray[0].blockName,
            blockProgress: 1,
            totalBlocks: routine.blockArray.count,
            exerciseProgress: 0,
            totalExercises: routine.blockArray[0].exerciseArray.count,
            startTime: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Error starting live activity: \(error)")
        }
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
    
    func updateLiveActivity() {
        guard let currentRoutine = currentRoutine,
              let currentBlock = currentBlock,
              let activity = currentActivity else { return }
        
        let contentState = WorkoutActivityAttributes.ContentState(
            routineName: currentRoutine.routineDay,
            currentBlock: currentBlock.blockName,
            blockProgress: currentBlockIndex + 1,
            totalBlocks: currentRoutine.blockArray.count,
            exerciseProgress: currentBlock.exerciseArray.filter { $0.completedSets >= $0.sets }.count,
            totalExercises: currentBlock.exerciseArray.count,
            startTime: Date()
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func endLiveActivity() {
        Task {
            await currentActivity?.end(using: currentActivity?.contentState, dismissalPolicy: .immediate)
        }
    }
    
    func testLiveActivity() {
        if #available(iOS 16.1, *) {
            let attributes = WorkoutActivityAttributes(
                routineName: "Test Workout",
                totalBlocks: 3
            )
            
            let initialState = WorkoutActivityAttributes.ContentState(
                routineName: "Test Workout",
                currentBlock: "Block 1",
                blockProgress: 1,
                totalBlocks: 3,
                exerciseProgress: 0,
                totalExercises: 4,
                startTime: Date()
            )
            
            Task {
                let activity = try? await Activity.request(
                    attributes: attributes,
                    contentState: initialState
                )
                
                // Simulate progress after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                
                let updatedState = WorkoutActivityAttributes.ContentState(
                    routineName: "Test Workout",
                    currentBlock: "Block 2",
                    blockProgress: 2,
                    totalBlocks: 3,
                    exerciseProgress: 2,
                    totalExercises: 4,
                    startTime: Date()
                )
                
                await activity?.update(using: updatedState)
            }
        }
    }
} 