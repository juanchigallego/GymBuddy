import ActivityKit
import SwiftUI

struct WorkoutActivityAttributes: ActivityAttributes {
    public typealias WorkoutStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var routineName: String
        var currentBlock: String
        var blockProgress: Int
        var totalBlocks: Int
        var exerciseProgress: Int
        var totalExercises: Int
        var startTime: Date
    }
    
    var routineName: String
    var totalBlocks: Int
} 