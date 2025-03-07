import SwiftUI
import CoreData

struct BlockRowView: View {
    let block: Block
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(block.blockName)
                .font(.headline)
            ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                Text("• \(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
                    .font(.subheadline)
            }
        }
    }
} 