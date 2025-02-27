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
            // Lock screen/banner UI goes here
            HStack {
                VStack(alignment: .leading) {
                    Text(context.state.routineName)
                        .font(.headline)
                    Text(context.state.currentBlock)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(context.state.blockProgress)/\(context.state.totalBlocks)")
                        .font(.caption)
                    ProgressView(value: Double(context.state.exerciseProgress),
                               total: Double(context.state.totalExercises))
                        .frame(width: 50)
                }
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

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
