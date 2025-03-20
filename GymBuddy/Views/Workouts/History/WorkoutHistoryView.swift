import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
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
