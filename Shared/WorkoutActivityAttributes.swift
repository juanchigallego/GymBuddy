import ActivityKit
import SwiftUI

struct WorkoutActivityAttributes: ActivityAttributes {
    public typealias WorkoutStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var routineName: String
        var currentBlock: String
        var blockProgress: Int
        var totalBlocks: Int
        var currentSet: Int
        var totalSets: Int
        var exerciseProgress: Int
        var totalExercises: Int
        var startTime: Date
        var exercises: [ExerciseInfo]
        var blockTimeElapsed: Int
        
        struct ExerciseInfo: Codable, Hashable {
            var name: String
            var reps: Int16
            var weight: Double
        }
    }
    
    var routineName: String
    var totalBlocks: Int
} 