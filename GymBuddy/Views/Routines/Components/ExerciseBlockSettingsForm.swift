import SwiftUI

/// A form for configuring exercise-specific settings within a block
struct ExerciseBlockSettingsForm: View {
    let exercise: Exercise
    @Binding var reps: Int16
    @Binding var weight: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if !exercise.exerciseTargetMuscles.isEmpty {
                Text("Target Muscles: \(exercise.exerciseTargetMuscles.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Stepper("Reps: \(reps)", value: $reps, in: 1...30)
            
            HStack {
                Text("Weight:")
                TextField("Weight (kg)", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                Text("kg")
            }
        }
    }
} 