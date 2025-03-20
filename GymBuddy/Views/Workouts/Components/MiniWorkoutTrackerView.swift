import SwiftUI

struct MiniWorkoutTrackerView: View {
    let routine: Routine
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var isResting = false
    @State private var timeRemaining: Int16 = 0
    @State private var restTimer: Timer?
    
    private func formatBlockTime() -> String {
        let minutes = workoutViewModel.blockTimeElapsed / 60
        let seconds = workoutViewModel.blockTimeElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatRestTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var isLastBlock: Bool {
        workoutViewModel.currentBlockIndex == routine.blockArray.count - 1
    }
    
    private func moveToNextBlock() {
        if !isLastBlock {
            workoutViewModel.updateCurrentBlock(index: workoutViewModel.currentBlockIndex + 1)
            isResting = false
            restTimer?.invalidate()
        } else {
            workoutViewModel.endWorkout()
        }
    }
    
    private func startRestTimer(seconds: Int16) {
        timeRemaining = seconds
        isResting = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                restTimer?.invalidate()
                moveToNextBlock()
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isResting {
                withAnimation(.spring()) {
                    workoutViewModel.resumeWorkout()
                }
            }
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Left side - Block info
                    HStack(spacing: 12) {
                        // Block icon/indicator
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isResting ? Color.orange : Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: isResting ? "timer" : "dumbbell.fill")
                                    .foregroundColor(.white)
                            )
                        
                        // Block details
                        VStack(alignment: .leading, spacing: 2) {
                            if let currentBlock = workoutViewModel.currentBlock {
                                if isResting {
                                    Text("Rest Time")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack(spacing: 12) {
                                        Label(formatRestTime(), systemImage: "timer")
                                            .foregroundColor(.orange)
                                        
                                        if let nextBlockIndex = routine.blockArray.firstIndex(where: { $0.blockID == currentBlock.blockID }),
                                           let nextBlock = routine.blockArray[safe: nextBlockIndex + 1] {
                                            Text("Next: \(nextBlock.blockName)")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .font(.caption)
                                } else {
                                    Text(currentBlock.blockName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack(spacing: 12) {
                                        Label(formatBlockTime(), systemImage: "clock")
                                        Label("\(workoutViewModel.completedSets)/\(currentBlock.sets) sets", systemImage: "number")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action button (Log set or Skip rest)
                    if isResting {
                        Button(action: {
                            moveToNextBlock()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button(action: {
                            if let currentBlock = workoutViewModel.currentBlock {
                                workoutViewModel.logSet()
                                if workoutViewModel.completedSets == currentBlock.sets {
                                    if !isLastBlock && currentBlock.restSeconds > 0 {
                                        startRestTimer(seconds: currentBlock.restSeconds)
                                    } else {
                                        moveToNextBlock()
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onDisappear {
            restTimer?.invalidate()
        }
    }
} 