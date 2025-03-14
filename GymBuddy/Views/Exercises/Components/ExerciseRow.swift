import SwiftUI

/// A row view for displaying exercise information in lists
struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if !exercise.exerciseTargetMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Muscles:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ExerciseMuscleTagsView(muscles: exercise.exerciseTargetMuscles)
                }
            }
            
            if let notes = exercise.exerciseNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let exercise = Exercise(context: context)
    exercise.exerciseName = "Bench Press"
    exercise.exerciseTargetMuscles = ["Chest", "Biceps"]
    exercise.notes = "Focus on form."
    exercise.repsPerSet = 15
    exercise.weight = 80.0
    
    // Save context
    try? context.save()
    
    return NavigationStack {
        ExerciseRow(exercise: exercise)
            .environment(\.managedObjectContext, context)
    }
}
