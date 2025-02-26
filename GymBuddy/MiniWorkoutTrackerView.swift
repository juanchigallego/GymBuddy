import SwiftUI

struct MiniWorkoutTrackerView: View {
    @ObservedObject var viewModel: RoutineViewModel
    
    var body: some View {
        if let routine = viewModel.currentRoutine {
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.routineDay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let currentBlock = routine.blockArray[safe: viewModel.currentBlockIndex] {
                            Text(currentBlock.blockName)
                                .font(.headline)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.resumeWorkout() }) {
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
                .background(Color(UIColor.systemBackground))
            }
        }
    }
} 