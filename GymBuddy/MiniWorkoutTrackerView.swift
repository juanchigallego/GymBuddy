import SwiftUI

struct MiniWorkoutTrackerView: View {
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                // Left side - Block info
                HStack(spacing: 12) {
                    // Block icon/indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.white)
                        )
                    
                    // Block details
                    VStack(alignment: .leading, spacing: 2) {
                        if let currentBlock = routine.blockArray[safe: viewModel.currentBlockIndex] {
                            Text(currentBlock.blockName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(routine.routineDay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right side - Controls
                HStack(spacing: 20) {
                    // Progress indicator
                    Text("\(viewModel.currentBlockIndex + 1)/\(routine.blockArray.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Resume button
                    Button(action: { 
                        withAnimation(.spring()) {
                            viewModel.resumeWorkout()
                        }
                    }) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // End workout button
                    Button(action: { viewModel.endWorkout() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 64)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .shadow(radius: 8, y: 4)
        )
    }
} 