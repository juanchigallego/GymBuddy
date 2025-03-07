import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(exercise.repsPerSet) reps", systemImage: "repeat")
                Spacer()
                Label("\(String(format: "%.1f", exercise.weight))kg", systemImage: "scalemass.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
} 