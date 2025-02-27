import SwiftUI
import CoreData

struct WorkoutTrackingView: View {
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    @State private var completedBlocks: Set<UUID> = []
    @State private var showingBlockRestTimer = false
    @State private var blockRestSeconds = 180 // 3 minutes default rest between blocks
    @State private var blockRestComplete = false
    
    private var blocks: [Block] {
        routine.blockArray
    }
    
    private var currentBlock: Block? {
        guard viewModel.currentBlockIndex < blocks.count else { return nil }
        return blocks[viewModel.currentBlockIndex]
    }
    
    private var isWorkoutComplete: Bool {
        completedBlocks.count == blocks.count
    }
    
    private var isLastBlock: Bool {
        viewModel.currentBlockIndex == blocks.count - 1
    }
    
    var body: some View {
        if viewModel.isMinimized {
            // Mini tracker
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.routineDay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let currentBlock = currentBlock {
                            Text(currentBlock.blockName)
                                .font(.headline)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { 
                        withAnimation(.spring()) {
                            viewModel.resumeWorkout()
                            viewModel.showingWorkoutSheet = true
                        }
                    }) {
                        HStack {
                            Text("Resume")
                            Image(systemName: "play.fill")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 5)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
            .transition(.move(edge: .bottom))
        } else {
            // Full workout view
            NavigationStack {
                Group {
                    if let block = currentBlock {
                        VStack(spacing: 16) {
                            // Progress indicator
                            HStack {
                                ForEach(blocks, id: \.blockID) { block in
                                    Circle()
                                        .fill(circleColor(for: block))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .padding()
                            
                            // Current block info
                            Text(block.blockName)
                                .font(.title)
                                .bold()
                            
                            List {
                                ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                                    ExerciseTrackingRow(
                                        exercise: exercise,
                                        viewModel: viewModel,
                                        isComplete: { completedSets in
                                            completedSets >= exercise.sets
                                        },
                                        onComplete: {
                                            checkBlockCompletion(block)
                                        }
                                    )
                                }
                            }
                            
                            if completedBlocks.contains(block.blockID) {
                                HStack {
                                    Button(action: { showingBlockRestTimer = true }) {
                                        Label("Rest", systemImage: "timer")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                    
                                    if isLastBlock {
                                        Button(action: { 
                                            viewModel.endWorkout()
                                        }) {
                                            Text("End Workout")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    } else {
                                        Button(action: nextBlock) {
                                            Text(blockRestComplete ? "Next Block" : "Skip Rest")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else if isWorkoutComplete {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Workout Complete! 💪")
                                .font(.title)
                                .bold()
                            
                            Button("Finish") {
                                viewModel.endWorkout()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .navigationTitle("Tracking: \(routine.routineDay)")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Minimize") {
                            withAnimation(.spring()) {
                                viewModel.minimizeWorkout()
                                viewModel.showingWorkoutSheet = false
                            }
                        }
                    }
                    ToolbarItem(placement: .destructiveAction) {
                        Button("End Workout", role: .destructive) {
                            viewModel.endWorkout()
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingBlockRestTimer) {
                    if isLastBlock {
                        BlockRestTimerView(
                            seconds: $blockRestSeconds,
                            isPresented: $showingBlockRestTimer,
                            onComplete: {
                                blockRestComplete = true
                                dismiss()  // Dismiss the entire workout view
                            }
                        )
                    } else {
                        BlockRestTimerView(
                            seconds: $blockRestSeconds,
                            isPresented: $showingBlockRestTimer,
                            onComplete: {
                                blockRestComplete = true
                                nextBlock()
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea()
            .transition(.move(edge: .bottom))
        }
    }
    
    private func circleColor(for block: Block) -> Color {
        if completedBlocks.contains(block.blockID) {
            return .green
        } else if block.blockID == currentBlock?.blockID {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func checkBlockCompletion(_ block: Block) {
        let allExercisesComplete = block.exerciseArray.allSatisfy { exercise in
            exercise.completedSets >= exercise.sets
        }
        
        if allExercisesComplete {
            completedBlocks.insert(block.blockID)
            viewModel.updateLiveActivity()  // Update when block is completed
        }
    }
    
    private func nextBlock() {
        if viewModel.currentBlockIndex < blocks.count - 1 {
            viewModel.updateCurrentBlock(index: viewModel.currentBlockIndex + 1)
        }
    }
}

struct ExerciseTrackingRow: View {
    @ObservedObject var exercise: Exercise
    let viewModel: RoutineViewModel
    let isComplete: (Int16) -> Bool
    let onComplete: () -> Void
    
    @State private var showingTimer = false
    @State private var timerSeconds = 90 // Default rest timer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            HStack {
                Text("\(exercise.completedSets)/\(exercise.sets) sets")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(exercise.repsPerSet) reps @ \(exercise.weight, specifier: "%.1f")kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(action: completeSet) {
                    Text("Complete Set")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(exercise.completedSets >= exercise.sets)
                
                Button(action: { showingTimer = true }) {
                    Image(systemName: "timer")
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingTimer) {
            RestTimerView(seconds: $timerSeconds, isPresented: $showingTimer)
        }
    }
    
    private func completeSet() {
        guard exercise.completedSets < exercise.sets else { return }
        exercise.completedSets += 1
        try? exercise.managedObjectContext?.save()
        
        if isComplete(exercise.completedSets) {
            onComplete()
            viewModel.updateLiveActivity()
        }
    }
}

struct RestTimerView: View {
    @Binding var seconds: Int
    @Binding var isPresented: Bool
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(seconds: Binding<Int>, isPresented: Binding<Bool>) {
        self._seconds = seconds
        self._isPresented = isPresented
        self._timeRemaining = State(initialValue: seconds.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 60, design: .monospaced))
                    .bold()
                
                HStack(spacing: 20) {
                    Button("-30s") {
                        timeRemaining = max(0, timeRemaining - 30)
                        seconds = timeRemaining
                    }
                    .buttonStyle(.bordered)
                    
                    Button(timer == nil ? "Start" : "Pause") {
                        toggleTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("+30s") {
                        timeRemaining += 30
                        seconds = timeRemaining
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Rest Timer")
            .toolbar {
                Button("Done") {
                    timer?.invalidate()
                    timer = nil
                    isPresented = false
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func toggleTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct BlockRestTimerView: View {
    @Binding var seconds: Int
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(seconds: Binding<Int>, isPresented: Binding<Bool>, onComplete: @escaping () -> Void) {
        self._seconds = seconds
        self._isPresented = isPresented
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: seconds.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 60, design: .monospaced))
                    .bold()
                
                HStack(spacing: 20) {
                    Button("-30s") {
                        timeRemaining = max(0, timeRemaining - 30)
                        seconds = timeRemaining
                    }
                    .buttonStyle(.bordered)
                    
                    Button(timer == nil ? "Start" : "Pause") {
                        toggleTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("+30s") {
                        timeRemaining += 30
                        seconds = timeRemaining
                    }
                    .buttonStyle(.bordered)
                }
                
                if timeRemaining == 0 {
                    Button("Continue to Next Block") {
                        onComplete()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Block Rest Timer")
            .toolbar {
                Button("Skip") {
                    timer?.invalidate()
                    timer = nil
                    onComplete()
                    isPresented = false
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func toggleTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    if timeRemaining == 0 {
                        timer?.invalidate()
                        timer = nil
                    }
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    do {
        let context = PersistenceController.shared.container.viewContext
        let viewModel = RoutineViewModel(context: context)
        
        // Create a sample routine
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.day = "Monday"
        
        // Create blocks
        let chestBlock = Block(context: context)
        chestBlock.id = UUID()
        chestBlock.name = "Chest"
        chestBlock.routine = routine
        
        let shoulderBlock = Block(context: context)
        shoulderBlock.id = UUID()
        shoulderBlock.name = "Shoulders"
        shoulderBlock.routine = routine
        
        // Create exercises
        let benchPress = Exercise(context: context)
        benchPress.id = UUID()
        benchPress.name = "Bench Press"
        benchPress.sets = 4
        benchPress.repsPerSet = 8
        benchPress.weight = 80.0
        benchPress.block = chestBlock
        
        let shoulderPress = Exercise(context: context)
        shoulderPress.id = UUID()
        shoulderPress.name = "Shoulder Press"
        shoulderPress.sets = 3
        shoulderPress.repsPerSet = 12
        shoulderPress.weight = 20.0
        shoulderPress.block = shoulderBlock
        
        try context.save()
        
        return WorkoutTrackingView(routine: routine, viewModel: viewModel)
            .environment(\.managedObjectContext, context)
    } catch {
        return Text("Failed to create preview")
    }
} 