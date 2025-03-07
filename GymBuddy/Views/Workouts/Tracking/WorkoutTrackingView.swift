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
                                    Label("\(viewModel.completedSets)/\(currentBlock.sets) sets", systemImage: "number")
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
                        Label("Dismiss Workout", systemImage: "xmark")
                            .foregroundColor(.red)
                    }
                }
                
                if !isWorkoutComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.pauseWorkout()
                            dismiss()
                        }) {
                            Label("Minimize", systemImage: "minus")
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
    
    return WorkoutTrackingView(routine: routine, viewModel: viewModel)
        .environment(\.managedObjectContext, context)
} 
