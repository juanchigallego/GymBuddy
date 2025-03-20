import SwiftUI

struct WorkoutOverlayView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var body: some View {
        Group {
            if let currentRoutine = workoutViewModel.currentRoutine {
                ZStack {
                    // Background overlay
                    if workoutViewModel.showingWorkoutSheet {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .zIndex(1)
                    }
                    
                    // The view that transforms between full and mini
                    Group {
                        if workoutViewModel.showingWorkoutSheet {
                            // Full workout view
                            WorkoutTrackingView(
                                routine: currentRoutine, 
                                workoutViewModel: workoutViewModel,
                                progressViewModel: progressViewModel
                            )
                            .transition(.identity)
                        } else if workoutViewModel.isMinimized {
                            // Mini tracker
                            MiniWorkoutTrackerView(
                                routine: currentRoutine, 
                                workoutViewModel: workoutViewModel
                            )
                            .transition(.identity)
                            .padding(.bottom, Constants.Layout.tabBarHeight) // Standard tab bar height
                        }
                    }
                    .zIndex(2)
                }
                .animation(Constants.Animation.standard, value: workoutViewModel.showingWorkoutSheet)
                .animation(Constants.Animation.standard, value: workoutViewModel.isMinimized)
                
                // Workout Summary Sheet
                .sheet(isPresented: $workoutViewModel.showingWorkoutSummary) {
                    WorkoutSummaryView(
                        routine: currentRoutine, 
                        viewModel: workoutViewModel
                    )
                }
            }
        }
    }
} 