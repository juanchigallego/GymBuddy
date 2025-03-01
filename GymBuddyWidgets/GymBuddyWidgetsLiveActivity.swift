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
                // Header with routine name and timer
                HStack {
                    Text(context.state.routineName)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(timerInterval: context.state.startTime...Date.now, countsDown: false)
                        .font(.caption.monospacedDigit())
                        .frame(width: 50)
                }
                
                // Overall progress bar
                ProgressView(value: Double(context.state.blockProgress), total: Double(context.state.totalBlocks))
                    .tint(.blue)
                
                // Current block info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(context.state.currentBlock)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(context.state.currentSet)/\(context.state.totalSets) sets")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    // Exercise list
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(context.state.exercises, id: \.name) { exercise in
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(exercise.reps) × \(String(format: "%.1f", exercise.weight))kg")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                        Text("\(context.state.blockTimeElapsed / 60):\(String(format: "%02d", context.state.blockTimeElapsed % 60))")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.headline)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentBlock)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Overall progress bar
                    ProgressView(value: Double(context.state.blockProgress), total: Double(context.state.totalBlocks))
                        .tint(.blue)
                }
            } compactLeading: {
                // Small circular progress with set counter
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.blockProgress) / CGFloat(context.state.totalBlocks))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 20, height: 20)
                    
                    Text("\(context.state.currentSet)")
                        .font(.system(size: 12, weight: .medium))
                }
            } compactTrailing: {
                Text("\(context.state.totalSets)")
                    .font(.system(size: 12, weight: .medium))
            } minimal: {
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.blockProgress) / CGFloat(context.state.totalBlocks))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 20, height: 20)
                    
                    Text("\(context.state.currentSet)")
                        .font(.system(size: 12, weight: .medium))
                }
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
        currentSet: 2,
        totalSets: 4,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now,
        exercises: [
            .init(name: "Bench Press", reps: 8, weight: 80.0),
            .init(name: "Incline Press", reps: 10, weight: 60.0)
        ],
        blockTimeElapsed: 180
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
        currentSet: 2,
        totalSets: 4,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now,
        exercises: [
            .init(name: "Bench Press", reps: 8, weight: 80.0),
            .init(name: "Incline Press", reps: 10, weight: 60.0)
        ],
        blockTimeElapsed: 180
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
        currentSet: 2,
        totalSets: 4,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now,
        exercises: [
            .init(name: "Bench Press", reps: 8, weight: 80.0),
            .init(name: "Incline Press", reps: 10, weight: 60.0)
        ],
        blockTimeElapsed: 180
    )
}

#Preview("Lock Screen Live Activity", as: .content, using: WorkoutActivityAttributes(routineName: "Monday", totalBlocks: 3)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        routineName: "Monday",
        currentBlock: "Chest",
        blockProgress: 1,
        totalBlocks: 3,
        currentSet: 2,
        totalSets: 4,
        exerciseProgress: 2,
        totalExercises: 4,
        startTime: .now,
        exercises: [
            .init(name: "Bench Press", reps: 8, weight: 80.0),
            .init(name: "Incline Press", reps: 10, weight: 60.0)
        ],
        blockTimeElapsed: 180
    )
}
