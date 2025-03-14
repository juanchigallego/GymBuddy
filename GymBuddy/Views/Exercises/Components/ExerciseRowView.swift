import SwiftUI
import CoreData

struct ExerciseRowView: View {
    let exercise: Exercise
    var backgroundColor: Color? = nil
    var paddingBottom: CGFloat? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.body)
            Spacer()
            HStack {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "repeat")
                        .foregroundStyle(Color(.secondaryLabel))
                        .font(.system(size: 12))
                    Text("\(exercise.repsPerSet) reps")
                }
                if exercise.weight > 0 {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(Color(.secondaryLabel))
                            .font(.system(size: 12))
                        Text("\(exercise.weight, specifier: "%.1f")kg")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, (paddingBottom != nil) ? paddingBottom! : 6)
        .foregroundStyle(.secondary)
        .background(backgroundColor)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.repsPerSet = 12
    exercise.weight = 60
    
    let exercise2 = Exercise(context: context)
    exercise2.id = UUID()
    exercise2.name = "Squats"
    exercise2.repsPerSet = 8
    exercise2.weight = 100
    
    try? context.save()
    
    return VStack(spacing: 0) {
        ExerciseRowView(exercise: exercise)
            .environment(\.managedObjectContext, context)
        ExerciseRowView(exercise: exercise2, backgroundColor: Color(.tertiarySystemBackground))
            .environment(\.managedObjectContext, context)
        ExerciseRowView(exercise: exercise)
            .environment(\.managedObjectContext, context)
        ExerciseRowView(exercise: exercise2, backgroundColor: Color(.tertiarySystemBackground), paddingBottom: 16)
            .environment(\.managedObjectContext, context)
    }
} 
