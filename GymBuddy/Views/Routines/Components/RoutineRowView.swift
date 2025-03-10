import SwiftUI
import CoreData

struct RoutineRowView: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.routineDay)
                .font(.headline)
            Text(routine.muscleGroupsArray.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.day = "Push Day"
    routine.muscleGroupsArray = ["Chest", "Shoulders", "Triceps"]
    
    try? context.save()
    
    return NavigationView {
        List {
            RoutineRowView(routine: routine)
                .environment(\.managedObjectContext, context)
        }
    }
} 