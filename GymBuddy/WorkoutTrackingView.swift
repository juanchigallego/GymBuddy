import SwiftUI
import CoreData

struct WorkoutTrackingView: View {
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingBlockRestTimer = false
    @State private var blockRestComplete = false
    @State private var showingDismissConfirmation = false
    
    private var blocks: [Block] {
        routine.blockArray
    }
    
    private var currentBlock: Block? {
        guard viewModel.currentBlockIndex < blocks.count else { return nil }
        return blocks[viewModel.currentBlockIndex]
    }
    
    private var isWorkoutComplete: Bool {
        viewModel.completedBlocks.count == blocks.count
    }
    
    private var isLastBlock: Bool {
        viewModel.currentBlockIndex == blocks.count - 1
    }
    
    private func formatBlockTime() -> String {
        let minutes = viewModel.blockTimeElapsed / 60
        let seconds = viewModel.blockTimeElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed header section
                    VStack(spacing: 16) {
                        // Progress bar
                        ProgressView(value: Double(viewModel.completedBlocks.count), total: Double(blocks.count))
                            .tint(.blue)
                        
                        if let currentBlock = currentBlock {
                            // Block header
                            VStack(spacing: 8) {
                                Text(currentBlock.blockName)
                                    .font(.title2)
                                    .bold()
                                
                                HStack(spacing: 16) {
                                    Label("\(viewModel.completedSets)/\(currentBlock.sets) sets", systemImage: "number.circle.fill")
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Label(formatBlockTime(), systemImage: "clock.fill")
                                        .foregroundColor(.secondary)
                                }
                                .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            if let currentBlock = currentBlock {
                                // Exercises
                                VStack(spacing: 16) {
                                    ForEach(currentBlock.exerciseArray) { exercise in
                                        ExerciseCard(exercise: exercise)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Bottom pinned action buttons
                    if let currentBlock = currentBlock {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // Complete Set button
                                Button(action: {
                                    viewModel.logSet()
                                }) {
                                    Label("Complete Set", systemImage: "checkmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(viewModel.completedSets >= currentBlock.sets ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.completedSets >= currentBlock.sets)
                                
                                // Skip Block button
                                Button(action: {
                                    skipCurrentBlock()
                                    if !isLastBlock {
                                        moveToNextBlock()
                                    } else {
                                        viewModel.endWorkout()
                                        dismiss()
                                    }
                                }) {
                                    Label("Skip", systemImage: "forward.fill")
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundColor(.orange)
                                        .cornerRadius(10)
                                }
                            }
                            
                            if viewModel.completedSets == currentBlock.sets {
                                Button(action: {
                                    if !isLastBlock && currentBlock.restSeconds > 0 {
                                        showingBlockRestTimer = true
                                    } else {
                                        moveToNextBlock()
                                    }
                                }) {
                                    Label(
                                        isLastBlock ? "Finish Workout" : "Next Block",
                                        systemImage: isLastBlock ? "flag.checkered.circle.fill" : "arrow.right.circle.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(routine.routineDay)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingDismissConfirmation = true
                    }) {
                        Label("Dismiss Workout", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if !isWorkoutComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.pauseWorkout()
                            dismiss()
                        }) {
                            Label("Minimize", systemImage: "minus.circle.fill")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Are you sure you want to dismiss this workout?",
                isPresented: $showingDismissConfirmation,
                titleVisibility: .visible
            ) {
                Button("Dismiss Workout", role: .destructive) {
                    viewModel.dismissWorkout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This workout will not be saved and all progress will be lost.")
            }
        }
        .sheet(isPresented: $showingBlockRestTimer) {
            if let currentBlock = currentBlock {
                let nextBlockIndex = viewModel.currentBlockIndex + 1
                if nextBlockIndex < blocks.count {
                    RestTimerView(
                        isPresented: $showingBlockRestTimer,
                        seconds: currentBlock.restSeconds,
                        nextBlock: blocks[nextBlockIndex],
                        onComplete: {
                            moveToNextBlock()
                        }
                    )
                }
            }
        }
    }
    
    private func completeCurrentBlock() {
        if let currentBlock = currentBlock {
            viewModel.completeBlock()
        }
    }
    
    private func skipCurrentBlock() {
        if let currentBlock = currentBlock {
            viewModel.completeBlock(skipped: true)
        }
    }
    
    private func moveToNextBlock() {
        if !isLastBlock {
            viewModel.updateCurrentBlock(index: viewModel.currentBlockIndex + 1)
            showingBlockRestTimer = false
        } else {
            viewModel.endWorkout()
            dismiss()
        }
    }
}

struct RestTimerView: View {
    @Binding var isPresented: Bool
    let seconds: Int16
    let onComplete: () -> Void
    @State private var timeRemaining: Int16
    @State private var timer: Timer?
    let nextBlock: Block
    
    init(isPresented: Binding<Bool>, seconds: Int16, nextBlock: Block, onComplete: @escaping () -> Void) {
        self._isPresented = isPresented
        self.seconds = seconds
        self.nextBlock = nextBlock
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: seconds)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            Text("Rest Time")
                                .font(.title)
                                .bold()
                            
                            VStack(spacing: 8) {
                                Text(formatTime(seconds: timeRemaining))
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                
                                Text("remaining")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Next block preview
                            VStack(spacing: 16) {
                                Text("Get Ready For")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(nextBlock.blockName)
                                            .font(.title3)
                                            .bold()
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(nextBlock.sets) sets")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        ForEach(nextBlock.exerciseArray) { exercise in
                                            HStack {
                                                Text(exercise.exerciseName)
                                                Spacer()
                                                Text("\(exercise.repsPerSet) reps @ \(String(format: "%.1f", exercise.weight))kg")
                                                    .foregroundColor(.secondary)
                                            }
                                            .font(.subheadline)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    
                    // Fixed bottom button
                    VStack {
                        Button(action: {
                            timer?.invalidate()
                            isPresented = false
                            onComplete()
                        }) {
                            Label("Skip Rest", systemImage: "forward.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    isPresented = false
                    onComplete()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func formatTime(seconds: Int16) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(exercise.repsPerSet) reps", systemImage: "repeat.circle.fill")
                Spacer()
                Label("\(String(format: "%.1f", exercise.weight))kg", systemImage: "scalemass.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = RoutineViewModel(context: context)
    
    // Create a sample routine
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.day = "Monday"
    routine.targetMuscleGroups = ["Chest", "Triceps"] as NSArray
    routine.notes = "Focus on form and controlled negatives"
    
    // Create Chest Block
    let chestBlock = Block(context: context)
    chestBlock.id = UUID()
    chestBlock.name = "Chest"
    chestBlock.sets = 4
    chestBlock.restSeconds = 180 // 3 minutes rest after compound chest exercises
    chestBlock.routine = routine
    
    // Chest exercises
    let benchPress = Exercise(context: context)
    benchPress.id = UUID()
    benchPress.name = "Bench Press"
    benchPress.repsPerSet = 8
    benchPress.weight = 80.0
    benchPress.block = chestBlock
    
    let inclineDumbbell = Exercise(context: context)
    inclineDumbbell.id = UUID()
    inclineDumbbell.name = "Incline Dumbbell Press"
    inclineDumbbell.repsPerSet = 10
    inclineDumbbell.weight = 30.0
    inclineDumbbell.block = chestBlock
    
    let cableFly = Exercise(context: context)
    cableFly.id = UUID()
    cableFly.name = "Cable Fly"
    cableFly.repsPerSet = 12
    cableFly.weight = 15.0
    cableFly.block = chestBlock
    
    // Create Triceps Block
    let tricepsBlock = Block(context: context)
    tricepsBlock.id = UUID()
    tricepsBlock.name = "Triceps"
    tricepsBlock.sets = 3
    tricepsBlock.restSeconds = 120 // 2 minutes rest after triceps exercises
    tricepsBlock.routine = routine
    
    // Triceps exercises
    let pushdowns = Exercise(context: context)
    pushdowns.id = UUID()
    pushdowns.name = "Rope Pushdowns"
    pushdowns.repsPerSet = 12
    pushdowns.weight = 25.0
    pushdowns.block = tricepsBlock
    
    let skullcrushers = Exercise(context: context)
    skullcrushers.id = UUID()
    skullcrushers.name = "EZ Bar Skullcrushers"
    skullcrushers.repsPerSet = 10
    skullcrushers.weight = 20.0
    skullcrushers.block = tricepsBlock
    
    let diamondPushups = Exercise(context: context)
    diamondPushups.id = UUID()
    diamondPushups.name = "Diamond Push-ups"
    diamondPushups.repsPerSet = 15
    diamondPushups.weight = 0.0
    diamondPushups.block = tricepsBlock
    
    // Create Finisher Block
    let finisherBlock = Block(context: context)
    finisherBlock.id = UUID()
    finisherBlock.name = "Finisher"
    finisherBlock.sets = 2
    finisherBlock.restSeconds = 60 // 1 minute rest for the finisher
    finisherBlock.routine = routine
    
    // Finisher exercises
    let pushupDropset = Exercise(context: context)
    pushupDropset.id = UUID()
    pushupDropset.name = "Push-up Dropset"
    pushupDropset.repsPerSet = 20
    pushupDropset.weight = 0.0
    pushupDropset.notes = "Do as many reps as possible until failure"
    pushupDropset.block = finisherBlock
    
    do {
        try context.save()
        return WorkoutTrackingView(routine: routine, viewModel: viewModel)
            .environment(\.managedObjectContext, context)
    } catch {
        return Text("Failed to create preview")
    }
} 
