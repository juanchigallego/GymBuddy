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
            // Mini tracker is now handled in MiniWorkoutTrackerView
            EmptyView()
        } else {
            NavigationStack {
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()
                    
                    if let block = currentBlock {
                        VStack(spacing: 16) {
                            // Progress bar
                            SegmentedProgressBar(
                                totalSegments: blocks.count,
                                currentSegment: viewModel.currentBlockIndex,
                                completedSegments: completedBlocks.map { id in
                                    blocks.firstIndex { $0.blockID == id } ?? -1
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Routine name and block
                            VStack(spacing: 4) {
                                Text(routine.routineDay)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(block.blockName)
                                    .font(.title)
                                    .bold()
                            }
                            .foregroundColor(.white)
                            
                            // Notes if any
                            if let notes = routine.routineNotes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            
                            // Exercise list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                                        ExerciseTrackingCard(
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
                                .padding()
                            }
                            
                            // Bottom buttons
                            if completedBlocks.contains(block.blockID) {
                                HStack(spacing: 16) {
                                    Button(action: { showingBlockRestTimer = true }) {
                                        Label("Rest", systemImage: "timer")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: isLastBlock ? { viewModel.endWorkout() } : nextBlock) {
                                        Text(isLastBlock ? "End Workout" : (blockRestComplete ? "Next Block" : "Skip Rest"))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Minimize") {
                            withAnimation(.spring()) {
                                viewModel.minimizeWorkout()
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("End", role: .destructive) {
                            viewModel.endWorkout()
                        }
                        .foregroundColor(.red)
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

// New exercise card design
struct ExerciseTrackingCard: View {
    @ObservedObject var exercise: Exercise
    let viewModel: RoutineViewModel
    let isComplete: (Int16) -> Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(exercise.completedSets)/\(exercise.sets)")
                    .font(.headline)
                    + Text(" sets")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("\(exercise.repsPerSet) reps • \(Int(exercise.weight))kg")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(exercise.repsPerSet * (exercise.sets - exercise.completedSets))) reps left")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                exercise.completedSets += 1
                if isComplete(exercise.completedSets) {
                    onComplete()
                }
                viewModel.updateLiveActivity()
            }) {
                Text("Complete set")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(exercise.completedSets >= exercise.sets)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
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

// New segmented progress bar component
struct SegmentedProgressBar: View {
    let totalSegments: Int
    let currentSegment: Int
    let completedSegments: [Int]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSegments, id: \.self) { index in
                Capsule()
                    .fill(segmentColor(for: index))
                    .frame(height: 8)
            }
        }
        .frame(height: 8)
    }
    
    private func segmentColor(for index: Int) -> Color {
        if completedSegments.contains(index) {
            return .green
        } else if index == currentSegment {
            return .blue
        } else {
            return Color.gray.opacity(0.3)
        }
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