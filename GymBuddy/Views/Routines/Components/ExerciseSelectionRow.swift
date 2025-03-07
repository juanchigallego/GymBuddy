import SwiftUI

/// A row component for displaying and selecting exercises in a list
struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.exerciseName)
                    .font(.headline)
                if !exercise.exerciseTargetMuscles.isEmpty {
                    Text(exercise.exerciseTargetMuscles.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
} 