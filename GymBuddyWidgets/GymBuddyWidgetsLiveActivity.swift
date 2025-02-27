//
//  GymBuddyWidgetsLiveActivity.swift
//  GymBuddyWidgets
//
//  Created by Juanchi Gallego on 26/02/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                    
                    Text(context.state.routineName)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Elapsed time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(timerInterval: context.state.startTime...Date.now, countsDown: false)
                            .font(.caption.monospacedDigit())
                            .frame(width: 50)
                    }
                }
                
                // Current block info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Block")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(context.state.currentBlock)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Block progress
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Block")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(context.state.blockProgress)/\(context.state.totalBlocks)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                // Progress bars
                VStack(spacing: 8) {
                    // Block progress
                    ProgressView(value: Double(context.state.blockProgress), total: Double(context.state.totalBlocks))
                        .tint(.blue)
                    
                    // Exercise progress
                    HStack {
                        Text("Exercises")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(context.state.exerciseProgress)/\(context.state.totalExercises)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(context.state.exerciseProgress), total: Double(context.state.totalExercises))
                        .tint(.green)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.state.routineName)
                            .font(.headline)
                        Text(context.state.currentBlock)
                            .font(.subheadline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(context.state.blockProgress)/\(context.state.totalBlocks)")
                        ProgressView(value: Double(context.state.exerciseProgress),
                                   total: Double(context.state.totalExercises))
                            .frame(width: 50)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "clock")
                        Text(context.state.startTime, style: .timer)
                    }
                }
            } compactLeading: {
                Text("\(context.state.blockProgress)/\(context.state.totalBlocks)")
            } compactTrailing: {
                ProgressView(value: Double(context.state.exerciseProgress),
                           total: Double(context.state.totalExercises))
                    .frame(width: 30)
            } minimal: {
                Text("\(context.state.blockProgress)")
            }
        }
    }
}

#Preview("Live Activity", as: .dynamicIsland(.expanded), using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Chest",
        blockProgress: 1,
        totalBlocks: 3,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now
    )
}

#Preview("Live Activity Compact", as: .dynamicIsland(.compact), using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Chest",
        blockProgress: 1,
        totalBlocks: 3,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now
    )
}

#Preview("Live Activity Minimal", as: .dynamicIsland(.minimal), using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Chest",
        blockProgress: 1,
        totalBlocks: 3,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now
    )
}

// Add this preview for the lock screen
#Preview("Lock Screen Live Activity", as: .content, using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Chest",
        blockProgress: 1,
        totalBlocks: 3,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now
    )
}

// Replace the notification preview with a different lock screen state
#Preview("Lock Screen (Progress)", as: .content, using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Shoulders",
        blockProgress: 2,
        totalBlocks: 3,
        exerciseProgress: 1,
        totalExercises: 3,
        startTime: .now.addingTimeInterval(-1200) // 20 minutes ago
    )
}
