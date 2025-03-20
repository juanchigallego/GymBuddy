import SwiftUI
import CoreData
import ActivityKit

@MainActor
class WorkoutViewModel: ObservableObject {
    // Logger for this class
    private let logger = Logger(category: "WorkoutViewModel")
    
    @Published var isTrackingWorkout = false
    @Published var showingWorkoutSheet = false
    @Published var currentRoutine: Routine?
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
        fetchCompletedWorkouts()
    }
    
    var currentBlock: Block? {
        guard let currentRoutine = currentRoutine,
              currentBlockIndex < currentRoutine.blockArray.count else {
            return nil
        }
        return currentRoutine.blockArray[currentBlockIndex]
    }
    
    func fetchCompletedWorkouts() {
        let request = NSFetchRequest<CompletedWorkout>(entityName: "CompletedWorkout")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CompletedWorkout.date, ascending: false)]
        
        do {
            completedWorkouts = try viewContext.fetch(request)
            logger.info("Fetched \(completedWorkouts.count) completed workouts")
        } catch {
            logger.error("Error fetching completed workouts: \(error.localizedDescription)")
        }
    }
    
    func startWorkout(routine: Routine) {
        logger.info("Starting workout with routine: \(routine.routineDay)")
        
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
        withAnimation(Constants.Animation.standard) {
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
        guard let currentBlock = currentBlock else {
            logger.warning("Cannot start new block: current block is nil")
            return
        }
        
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
        
        logger.info("Started new block: \(currentBlock.blockName)")
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
        
        logger.info("Block timer started")
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            logger.info("Background task ended")
        }
    }
    
    private func startLiveActivity(routine: Routine) {
        guard let currentBlock = currentBlock else {
            logger.warning("Cannot start live activity: current block is nil")
            return
        }
        
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
            logger.info("Live Activity started with ID: \(activity.id)")
        } catch {
            logger.error("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func minimizeWorkout() {
        // First set isMinimized to true, then after a short delay hide the full sheet
        isMinimized = true
        
        // Small delay to allow the animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingWorkoutSheet = false
        }
        
        logger.info("Workout view minimized")
    }
    
    func resumeWorkout() {
        // First show the full sheet, then after it's visible, set isMinimized to false
        showingWorkoutSheet = true
        
        // Small delay to allow the animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isMinimized = false
        }
        
        logger.info("Workout view resumed")
    }
    
    func pauseWorkout() {
        withAnimation(Constants.Animation.standard) {
            isMinimized = true
            showingWorkoutSheet = false
        }
        
        logger.info("Workout paused")
    }
    
    func completeBlock(skipped: Bool = false) {
        guard let blockStartTime = blockStartTime,
              let currentBlock = currentBlock,
              let activeBlock = activeBlock else {
            logger.warning("Cannot complete block: missing required data")
            return
        }
        
        let endTime = Date()
        activeBlock.endTime = endTime
        
        if skipped {
            skippedBlocks.insert(currentBlock.blockID)
            activeBlock.isSkipped = true
            logger.info("Block \(currentBlock.blockName) skipped")
        } else {
            logger.info("Block \(currentBlock.blockName) completed")
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
        logger.info("Ending workout")
        
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
            
            // Post notification that workout was completed
            NotificationCenter.default.post(
                name: Constants.NotificationNames.didCompleteWorkout,
                object: nil,
                userInfo: ["workout": workout]
            )
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
    
    func updateCurrentBlock(index: Int) {
        currentBlockIndex = index
        completedSets = 0  // Reset completed sets when starting a new block
        startNewBlock()
        startBlockTimer()
        
        if let currentBlock = currentBlock {
            logger.info("Updated current block to: \(currentBlock.blockName)")
        }
    }
    
    func logSet() {
        guard let currentBlock = currentBlock else {
            logger.warning("Cannot log set: current block is nil")
            return
        }
        
        if completedSets < currentBlock.sets {
            completedSets += 1
            logger.info("Logged set \(completedSets) of \(currentBlock.sets) for \(currentBlock.blockName)")
            
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
              let workoutStart = workoutStartTime else {
            return
        }
        
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
            logger.info("Live activity ended")
        }
    }
    
    func dismissWorkout() {
        logger.info("Dismissing workout without completion")
        
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
                    self.logger.info("Deleted incomplete workout")
                } catch {
                    self.logger.error("Error deleting workout: \(error.localizedDescription)")
                }
                
                // Clear the reference after successful deletion
                self.activeWorkout = nil
            }
        }
    }
    
    func saveCompletedWorkout() {
        guard let currentRoutine = currentRoutine else {
            logger.warning("Cannot save completed workout: current routine is nil")
            return
        }
        
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
            logger.info("Saved completed workout for routine: \(currentRoutine.routineDay)")
        } catch {
            logger.error("Error saving completed workout: \(error.localizedDescription)")
        }
    }
} 