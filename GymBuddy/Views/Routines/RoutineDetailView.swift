//
//  RoutineDetailView.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 06/03/2024.
//

import SwiftUI
import CoreData

struct RoutineDetailView: View {
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    
    var body: some View {
        List {
            Section {
                Text("Target Muscle Groups: \(routine.muscleGroupsArray.joined(separator: ", "))")
                if let notes = routine.routineNotes {
                    Text("Notes: \(notes)")
                }
            }
            
            ForEach(routine.blockArray, id: \.blockID) { block in
                Section(header: Text(block.blockName)) {
                    Text("Sets: \(block.sets)")
                    Text("Rest: \(block.restSeconds) seconds")
                    
                    ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                }
            }
        }
        .navigationTitle(routine.routineDay)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.toggleFavorite(routine)
                    } label: {
                        Label(
                            routine.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: routine.isFavorite ? "star.fill" : "star"
                        )
                    }
                    
                    Button {
                        viewModel.toggleArchived(routine)
                    } label: {
                        Label(
                            routine.isArchived ? "Unarchive" : "Archive",
                            systemImage: routine.isArchived ? "archivebox.fill" : "archivebox"
                        )
                    }
                    
                    Button("Edit") {
                        viewModel.routineToEdit = routine
                        viewModel.isEditingRoutine = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Start Workout") {
                    viewModel.startWorkout(routine: routine)
                }
                .disabled(routine.isArchived)
            }
        }
        .sheet(isPresented: $viewModel.isEditingRoutine) {
            if let routineToEdit = viewModel.routineToEdit {
                EditRoutineView(viewModel: viewModel, routine: routineToEdit)
            }
        }
    }
} 