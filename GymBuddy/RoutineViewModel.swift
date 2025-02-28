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
    @Published var showingWorkoutSummary = false
    @Published var completedSets: Int16 = 0
    @Published var completedBlocks: Set<UUID> = []
    
    // Workout timing properties
    private var workoutStartTime: Date?
    var blockStartTime: Date?
    @Published var blockTimeElapsed: Int = 0
    private var blockTimer: Timer?
    @Published var blockCompletionTimes: [UUID: TimeInterval] = [:]
    @Published var totalWorkoutTime: TimeInterval = 0
    @Published var skippedBlocks: Set<UUID> = []
    
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
        
        // Reset completed sets for all blocks
        for block in routine.blockArray {
            block.completedSets = 0
        }
        completedSets = 0
        completedBlocks.removeAll()
        try? viewContext.save()
        
        // Reset timing properties
        workoutStartTime = Date()
        blockStartTime = Date()
        startBlockTimer()
        blockCompletionTimes.removeAll()
        skippedBlocks.removeAll()
        totalWorkoutTime = 0
        
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
    
    private func startBlockTimer() {
        blockTimeElapsed = 0
        blockTimer?.invalidate()
        blockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.blockTimeElapsed += 1
        }
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
        // First set isMinimized to true, then after a short delay hide the full sheet
        isMinimized = true
        
        // Small delay to allow the animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingWorkoutSheet = false
        }
    }
    
    func resumeWorkout() {
        // First show the full sheet, then after it's visible, set isMinimized to false
        showingWorkoutSheet = true
        
        // Small delay to allow the animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isMinimized = false
        }
    }
    
    func pauseWorkout() {
        withAnimation(.spring()) {
            isMinimized = true
            showingWorkoutSheet = false
        }
    }
    
    func completeBlock(skipped: Bool = false) {
        guard let blockStartTime = blockStartTime,
              let currentBlock = currentBlock else { return }
        
        if skipped {
            skippedBlocks.insert(currentBlock.blockID)
        } else {
            // Record the time taken for this block only if not skipped
            let blockTime = Date().timeIntervalSince(blockStartTime)
            blockCompletionTimes[currentBlock.blockID] = blockTime
        }
        
        // Add block to completed blocks
        completedBlocks.insert(currentBlock.blockID)
        
        // Reset block start time for next block
        self.blockStartTime = Date()
        blockTimeElapsed = 0
    }
    
    func endWorkout() {
        print("Ending workout")
        
        if let startTime = workoutStartTime {
            totalWorkoutTime = Date().timeIntervalSince(startTime)
            showingWorkoutSummary = true
        }
        
        isTrackingWorkout = false
        showingWorkoutSheet = false
        isMinimized = false
        workoutStartTime = nil
        blockStartTime = nil
        blockTimer?.invalidate()
        blockTimer = nil
        blockTimeElapsed = 0
        completedBlocks.removeAll()
    }
    
    func updateRoutine(_ routine: Routine, day: String, muscleGroups: [String], blocks: [Block], notes: String?) {
        viewContext.perform {
            routine.day = day
            routine.targetMuscleGroups = muscleGroups as NSArray
            routine.notes = notes
            
            // Create a set of block IDs that should be kept
            let blockIdsToKeep = Set(blocks.compactMap { $0.id })
            
            // Remove blocks that are no longer in the updated list
            if let existingBlocks = routine.blocks as? Set<Block> {
                for block in existingBlocks {
                    if !blockIdsToKeep.contains(block.id ?? UUID()) {
                        self.viewContext.delete(block)
                    }
                }
            }
            
            // Update the blocks relationship
            routine.blocks = NSSet(array: blocks)
            
            // Update the inverse relationships
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
    
    func updateBlock(_ block: Block, name: String, exercises: [Exercise], sets: Int16, restSeconds: Int16) {
        viewContext.perform {
            block.name = name
            block.sets = sets
            block.restSeconds = restSeconds
            
            // Create a set of exercise IDs that should be kept
            let exerciseIdsToKeep = Set(exercises.compactMap { $0.id })
            
            // Remove exercises that are no longer in the updated list
            if let existingExercises = block.exercises as? Set<Exercise> {
                for exercise in existingExercises {
                    if !exerciseIdsToKeep.contains(exercise.id ?? UUID()) {
                        self.viewContext.delete(exercise)
                    }
                }
            }
            
            // Update the exercises relationship
            block.exercises = NSSet(array: exercises)
            
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
        blockStartTime = Date()
        blockTimeElapsed = 0
        completedSets = 0
    }
    
    func logSet() {
        guard let currentBlock = currentBlock else { return }
        if completedSets < currentBlock.sets {
            completedSets += 1
            if completedSets == currentBlock.sets {
                completeBlock()
            }
            updateLiveActivity()
        }
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
            exerciseProgress: Int(currentBlock.completedSets),
            totalExercises: Int(currentBlock.sets),
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
        guard #available(iOS 16.1, *) else {
            print("Live Activities require iOS 16.1 or later")
            return
        }
        
        print("Testing Live Activity...")
        
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
            do {
                print("Requesting Live Activity...")
                let activity = try await Activity<WorkoutActivityAttributes>.request(
                    attributes: attributes,
                    contentState: initialState
                )
                print("Live Activity started with ID: \(activity.id)")
                
                // Simulate progress after 3 seconds
                try await Task.sleep(for: .seconds(3))
                
                let updatedState = WorkoutActivityAttributes.ContentState(
                    routineName: "Test Workout",
                    currentBlock: "Block 2",
                    blockProgress: 2,
                    totalBlocks: 3,
                    exerciseProgress: 2,
                    totalExercises: 4,
                    startTime: Date()
                )
                
                await activity.update(using: updatedState)
                print("Live Activity updated")
            } catch {
                print("Error starting Live Activity: \(error)")
                print("Detailed error: \(error.localizedDescription)")
            }
        }
    }
    
    func dismissWorkout() {
        print("Dismissing workout without completion")
        
        isTrackingWorkout = false
        showingWorkoutSheet = false
        isMinimized = false
        workoutStartTime = nil
        blockStartTime = nil
        blockTimer?.invalidate()
        blockTimer = nil
        blockTimeElapsed = 0
        completedBlocks.removeAll()
        
        // Reset the current routine and block index
        currentRoutine = nil
        currentBlockIndex = 0
    }
} 