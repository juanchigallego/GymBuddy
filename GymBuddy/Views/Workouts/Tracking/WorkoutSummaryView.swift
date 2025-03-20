import SwiftUI

struct WorkoutSummaryView: View {
    let routine: Routine
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with total time
                    VStack(spacing: 8) {
                        Text("Workout Complete! 💪")
                            .font(.title)
                            .bold()
                        
                        Text("Total Time: \(formatTime(viewModel.totalWorkoutTime))")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                    
                    // Blocks summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Block Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(routine.blockArray, id: \.blockID) { block in
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(block.blockName)
                                            .font(.title3)
                                            .bold()
                                        
                                        if viewModel.skippedBlocks.contains(block.blockID) {
                                            Text("Skipped")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("\(block.exerciseArray.count) exercises • \(block.sets) sets")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if !viewModel.skippedBlocks.contains(block.blockID) {
                                        Text(formatTime(viewModel.blockCompletionTimes[block.blockID] ?? 0))
                                            .font(.headline)
                                            .monospacedDigit()
                                    }
                                }
                                
                                if !viewModel.skippedBlocks.contains(block.blockID) {
                                    Divider()
                                    
                                    // Exercise list
                                    ForEach(block.exerciseArray) { exercise in
                                        HStack {
                                            Text(exercise.exerciseName)
                                            Spacer()
                                            Text("\(exercise.repsPerSet) reps @ \(String(format: "%.1f", exercise.weight))kg")
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showingWorkoutSummary = false
                        viewModel.currentRoutine = nil
                        viewModel.currentBlockIndex = 0
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let workoutViewModel = WorkoutViewModel(context: context)
    
    // Create a sample routine
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.day = "Monday"
    routine.targetMuscleGroups = ["Chest", "Triceps"] as NSArray
    
    // Create a block
    let block = Block(context: context)
    block.id = UUID()
    block.name = "Chest"
    block.sets = 4
    block.routine = routine
    
    // Create an exercise
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.repsPerSet = 8
    exercise.weight = 80.0
    exercise.block = block
    
    // Set up timing data
    workoutViewModel.blockCompletionTimes[block.id!] = 600 // 10 minutes
    workoutViewModel.totalWorkoutTime = 3600 // 1 hour
    
    return WorkoutSummaryView(routine: routine, viewModel: workoutViewModel)
        .environment(\.managedObjectContext, context)
} 