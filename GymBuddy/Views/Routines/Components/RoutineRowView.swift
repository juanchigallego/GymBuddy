import SwiftUI
import CoreData

struct RoutineRowView: View {
    let routine: Routine
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(routine.routineDay)
                        .font(.headline)
                    
                    if routine.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(routine.muscleGroupsArray.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if routine.isArchived {
                Spacer()
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.gray)
            }
        }
        .opacity(routine.isArchived ? 0.7 : 1.0)
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