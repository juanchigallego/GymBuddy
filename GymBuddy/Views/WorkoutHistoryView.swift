import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: RoutineViewModel
    @State private var selectedWorkout: CompletedWorkout?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.completedWorkouts) { workout in
                    Button {
                        selectedWorkout = workout
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workout.routineName ?? "")
                                .font(.headline)
                            
                            HStack {
                                Text(workout.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(workout.formattedTotalTime)
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Workout History")
            .sheet(item: $selectedWorkout) { workout in
                NavigationStack {
                    CompletedWorkoutDetailView(workout: workout)
                }
            }
        }
    }
}

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with total time
                VStack(spacing: 8) {
                    Text(workout.routineName ?? "")
                        .font(.title)
                        .bold()
                    
                    Text(workout.formattedDate)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Total Time: \(workout.formattedTotalTime)")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.vertical)
                
                // Blocks summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Block Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(workout.blockArray) { block in
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(block.blockName ?? "")
                                        .font(.title3)
                                        .bold()
                                    
                                    if block.isSkipped {
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
                                
                                if !block.isSkipped {
                                    Text(block.formattedCompletionTime)
                                        .font(.headline)
                                        .monospacedDigit()
                                }
                            }
                            
                            if !block.isSkipped {
                                Divider()
                                
                                // Exercise list
                                ForEach(block.exerciseArray) { exercise in
                                    HStack {
                                        Text(exercise.exerciseName ?? "")
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
                    dismiss()
                }
            }
        }
    }
} 