import SwiftUI
import CoreData

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.exerciseName)
                .font(.headline)
            Text("\(exercise.repsPerSet) reps")
            if exercise.weight > 0 {
                Text("Weight: \(exercise.weight, specifier: "%.1f")kg")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.repsPerSet = 12
    exercise.weight = 60.0
    
    try? context.save()
    
    return NavigationView {
        List {
            ExerciseRowView(exercise: exercise)
                .environment(\.managedObjectContext, context)
        }
    }
} 