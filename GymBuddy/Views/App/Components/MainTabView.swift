import SwiftUI
import CoreData

struct MainTabView: View {
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var progressViewModel: ProgressViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            RoutinesTab(
                routineViewModel: routineViewModel,
                workoutViewModel: workoutViewModel
            )
            .tabItem {
                Label("Routines", systemImage: "dumbbell.fill")
            }
            
            ExercisesView(viewContext: viewContext, progressViewModel: progressViewModel)
                .tabItem {
                    Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                }
            
            WorkoutHistoryView(viewModel: workoutViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
    }
} 
