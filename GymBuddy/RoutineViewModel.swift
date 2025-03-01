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
    private var blockStartTime: Date?
    @Published var blockTimeElapsed: Int = 0
    private var blockTimer: Task<Void, Never>?
    @Published var blockCompletionTimes: [UUID: TimeInterval] = [:]
    @Published var totalWorkoutTime: TimeInterval = 0
    @Published var skippedBlocks: Set<UUID> = []
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var activeWorkout: CompletedWorkout?
    @Published private(set) var activeBlock: CompletedBlock?
    
    @Published var completedWorkouts: [CompletedWorkout] = []
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchRoutines()
        fetchCompletedWorkouts()
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
    
    func fetchCompletedWorkouts() {
        let request = NSFetchRequest<CompletedWorkout>(entityName: "CompletedWorkout")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CompletedWorkout.date, ascending: false)]
        
        do {
            completedWorkouts = try viewContext.fetch(request)
        } catch {
            print("Error fetching completed workouts: \(error)")
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
        
        // Create a new workout in CoreData
        let startTime = Date()
        let workout = CompletedWorkout(context: viewContext)
        workout.id = UUID()
        workout.date = startTime
        workout.routineName = routine.routineDay
        activeWorkout = workout
        
        // Reset timing properties
        workoutStartTime = startTime
        blockStartTime = startTime
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
        
        // Start the first block
        startNewBlock()
        
        // Start timers and live activity
        startBlockTimer()
        startLiveActivity(routine: routine)
    }
    
    private func startNewBlock() {
        guard let currentBlock = currentBlock else { return }
        
        // Create a new completed block
        let completedBlock = CompletedBlock(context: viewContext)
        completedBlock.id = UUID()
        completedBlock.blockName = currentBlock.blockName
        completedBlock.sets = currentBlock.sets
        completedBlock.startTime = Date()
        completedBlock.workout = activeWorkout
        
        // Add exercises
        for exercise in currentBlock.exerciseArray {
            let completedExercise = CompletedExercise(context: viewContext)
            completedExercise.id = UUID()
            completedExercise.exerciseName = exercise.exerciseName
            completedExercise.repsPerSet = exercise.repsPerSet
            completedExercise.weight = exercise.weight
            completedExercise.notes = exercise.notes
            completedExercise.block = completedBlock
        }
        
        activeBlock = completedBlock
        blockStartTime = completedBlock.startTime
    }
    
    private func startBlockTimer() {
        blockTimeElapsed = 0
        blockTimer?.cancel()
        
        // Begin background task
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            // End the task if the background task expires
            self.endBackgroundTask()
        }
        
        blockTimer = Task {
            while !Task.isCancelled {
                // Calculate elapsed time based on absolute time difference
                if let startTime = blockStartTime {
                    await MainActor.run {
                        blockTimeElapsed = Int(Date().timeIntervalSince(startTime))
                        updateLiveActivity()
                    }
                }
                try? await Task.sleep(for: .seconds(1))
            }
            // End background task when timer is cancelled
            await MainActor.run {
                self.endBackgroundTask()
            }
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func startLiveActivity(routine: Routine) {
        guard let currentBlock = currentBlock else { return }
        
        let attributes = WorkoutActivityAttributes(
            routineName: routine.routineDay,
            totalBlocks: routine.blockArray.count
        )
        
        let contentState = WorkoutActivityAttributes.ContentState(
            routineName: routine.routineDay,
            currentBlock: currentBlock.blockName,
            blockProgress: currentBlockIndex + 1,
            totalBlocks: routine.blockArray.count,
            currentSet: Int(completedSets),
            totalSets: Int(currentBlock.sets),
            exerciseProgress: Int(completedSets),
            totalExercises: Int(currentBlock.sets),
            startTime: Date(),
            exercises: currentBlock.exerciseArray.map { exercise in
                WorkoutActivityAttributes.ContentState.ExerciseInfo(
                    name: exercise.exerciseName,
                    reps: exercise.repsPerSet,
                    weight: exercise.weight
                )
            },
            blockTimeElapsed: blockTimeElapsed
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
            print("Live Activity started with ID: \(activity.id)")
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
              let currentBlock = currentBlock,
              let activeBlock = activeBlock else { return }
        
        let endTime = Date()
        activeBlock.endTime = endTime
        
        if skipped {
            skippedBlocks.insert(currentBlock.blockID)
            activeBlock.isSkipped = true
        }
        
        // Record the time taken for this block
        let blockTime = endTime.timeIntervalSince(blockStartTime)
        blockCompletionTimes[currentBlock.blockID] = blockTime
        activeBlock.completionTime = blockTime
        
        // Add block to completed blocks
        completedBlocks.insert(currentBlock.blockID)
        
        // Save the current state
        try? viewContext.save()
        
        // Reset for next block
        self.blockStartTime = Date()
        blockTimeElapsed = 0
        self.activeBlock = nil
    }
    
    func endWorkout() {
        print("Ending workout")
        
        if let startTime = workoutStartTime,
           let workout = activeWorkout {
            let endTime = Date()
            totalWorkoutTime = endTime.timeIntervalSince(startTime)
            
            // Update the workout
            workout.endDate = endTime
            workout.totalTime = totalWorkoutTime
            
            try? viewContext.save()
            fetchCompletedWorkouts()
            showingWorkoutSummary = true
        }
        
        endLiveActivity()
        endBackgroundTask()
        
        // Reset all state
        isTrackingWorkout = false
        showingWorkoutSheet = false
        isMinimized = false
        workoutStartTime = nil
        blockStartTime = nil
        blockTimer?.cancel()
        blockTimer = nil
        blockTimeElapsed = 0
        completedBlocks.removeAll()
        activeWorkout = nil
        activeBlock = nil
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
        startNewBlock()
        startBlockTimer()
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
              let activity = currentActivity,
              let workoutStart = workoutStartTime else { return }
        
        let contentState = WorkoutActivityAttributes.ContentState(
            routineName: currentRoutine.routineDay,
            currentBlock: currentBlock.blockName,
            blockProgress: currentBlockIndex + 1,
            totalBlocks: currentRoutine.blockArray.count,
            currentSet: Int(completedSets),
            totalSets: Int(currentBlock.sets),
            exerciseProgress: Int(completedSets),
            totalExercises: Int(currentBlock.sets),
            startTime: workoutStart,
            exercises: currentBlock.exerciseArray.map { exercise in
                WorkoutActivityAttributes.ContentState.ExerciseInfo(
                    name: exercise.exerciseName,
                    reps: exercise.repsPerSet,
                    weight: exercise.weight
                )
            },
            blockTimeElapsed: Int(Date().timeIntervalSince(blockStartTime ?? Date()))
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func endLiveActivity() {
        Task { @MainActor in
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
        }
    }
    
    func dismissWorkout() {
        print("Dismissing workout without completion")
        
        // First, end any active timers and activities
        blockTimer?.cancel()
        blockTimer = nil
        endLiveActivity()
        endBackgroundTask()
        
        // Reset all state before deleting to avoid any references
        isTrackingWorkout = false
        showingWorkoutSheet = false
        isMinimized = false
        workoutStartTime = nil
        blockStartTime = nil
        blockTimeElapsed = 0
        completedBlocks.removeAll()
        currentRoutine = nil
        currentBlockIndex = 0
        
        // Clear active block reference
        self.activeBlock = nil
        
        // Delete the active workout if it exists
        if let workout = activeWorkout {
            // Perform deletion on the main context
            viewContext.perform {
                self.viewContext.delete(workout)
                
                do {
                    try self.viewContext.save()
                } catch {
                    print("Error deleting workout: \(error)")
                }
                
                // Clear the reference after successful deletion
                self.activeWorkout = nil
            }
        }
    }
    
    func saveCompletedWorkout() {
        guard let currentRoutine = currentRoutine else { return }
        
        let completedWorkout = CompletedWorkout(context: viewContext)
        completedWorkout.id = UUID()
        completedWorkout.date = Date()
        completedWorkout.routineName = currentRoutine.routineDay
        completedWorkout.totalTime = totalWorkoutTime
        
        for block in currentRoutine.blockArray {
            let completedBlock = CompletedBlock(context: viewContext)
            completedBlock.id = UUID()
            completedBlock.blockName = block.blockName
            completedBlock.sets = block.sets
            completedBlock.isSkipped = skippedBlocks.contains(block.blockID)
            completedBlock.completionTime = blockCompletionTimes[block.blockID] ?? 0
            completedBlock.workout = completedWorkout
            
            for exercise in block.exerciseArray {
                let completedExercise = CompletedExercise(context: viewContext)
                completedExercise.id = UUID()
                completedExercise.exerciseName = exercise.exerciseName
                completedExercise.repsPerSet = exercise.repsPerSet
                completedExercise.weight = exercise.weight
                completedExercise.notes = exercise.notes
                completedExercise.block = completedBlock
            }
        }
        
        do {
            try viewContext.save()
            fetchCompletedWorkouts()
        } catch {
            print("Error saving completed workout: \(error)")
        }
    }
} 