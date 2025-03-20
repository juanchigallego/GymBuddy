import SwiftUI

// MARK: - Favorites Section
struct FavoritesSection: View {
    let routines: [Routine]
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        Section("Favorites") {
            ForEach(routines) { routine in
                NavigationLink {
                    RoutineDetailView(
                        routine: routine,
                        routineViewModel: routineViewModel,
                        workoutViewModel: workoutViewModel
                    )
                } label: {
                    RoutineRowView(routine: routine)
                }
            }
        }
    }
}

// MARK: - Active Routines Section
struct ActiveRoutinesSection: View {
    let routines: [Routine]
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        Section("Active Routines") {
            ForEach(routines) { routine in
                NavigationLink {
                    RoutineDetailView(
                        routine: routine,
                        routineViewModel: routineViewModel,
                        workoutViewModel: workoutViewModel
                    )
                } label: {
                    RoutineRowView(routine: routine)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    routineViewModel.deleteRoutine(routines[index])
                }
            }
        }
    }
}

// MARK: - Archived Section
struct ArchivedSection: View {
    let routines: [Routine]
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        Section("Archived") {
            ForEach(routines) { routine in
                NavigationLink {
                    RoutineDetailView(
                        routine: routine,
                        routineViewModel: routineViewModel,
                        workoutViewModel: workoutViewModel
                    )
                } label: {
                    RoutineRowView(routine: routine)
                }
            }
        }
    }
} 