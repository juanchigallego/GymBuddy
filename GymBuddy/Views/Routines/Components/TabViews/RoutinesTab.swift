import SwiftUI

struct RoutinesTab: View {
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // Favorites section
                if !routineViewModel.favoriteRoutines.isEmpty {
                    FavoritesSection(
                        routines: routineViewModel.favoriteRoutines,
                        routineViewModel: routineViewModel,
                        workoutViewModel: workoutViewModel
                    )
                }
                
                // Active routines section
                ActiveRoutinesSection(
                    routines: routineViewModel.activeRoutines.filter { !$0.isFavorite },
                    routineViewModel: routineViewModel,
                    workoutViewModel: workoutViewModel
                )
                
                // Archived section
                if !routineViewModel.archivedRoutines.isEmpty {
                    ArchivedSection(
                        routines: routineViewModel.archivedRoutines,
                        routineViewModel: routineViewModel,
                        workoutViewModel: workoutViewModel
                    )
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        routineViewModel.isAddingRoutine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    DebugMenu()
                }
                #endif
            }
            .sheet(isPresented: $routineViewModel.isAddingRoutine) {
                AddRoutineView(viewModel: routineViewModel)
            }
        }
    }
} 
