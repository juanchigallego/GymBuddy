//
//  ContentView.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 11/12/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var viewModel: RoutineViewModel
    
    init(context: NSManagedObjectContext) {
        // No need to create viewModel here anymore
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            NavigationStack {
                List {
                    ForEach(viewModel.routines, id: \.routineID) { routine in
                        NavigationLink(destination: RoutineDetailView(routine: routine, viewModel: viewModel)) {
                            RoutineRowView(routine: routine)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteRoutine(viewModel.routines[index])
                        }
                    }
                }
                .navigationTitle("My Routines")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { viewModel.isAddingRoutine = true }) {
                            Image(systemName: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Test Live Activity") {
                            viewModel.testLiveActivity()
                        }
                    }
                }
                .sheet(isPresented: $viewModel.isAddingRoutine) {
                    AddRoutineView(viewModel: viewModel)
                }
            }
            .padding(.bottom, viewModel.isMinimized ? 64 : 0)
            
            // Workout view container - this stays in place during transitions
            if let currentRoutine = viewModel.currentRoutine {
                ZStack {
                    // Background overlay
                    if viewModel.showingWorkoutSheet {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .zIndex(1)
                    }
                    
                    // The view that transforms between full and mini
                    Group {
                        if viewModel.showingWorkoutSheet {
                            // Full workout view
                            WorkoutTrackingView(routine: currentRoutine, viewModel: viewModel)
                                .transition(.identity)
                        } else if viewModel.isMinimized {
                            // Mini tracker
                            MiniWorkoutTrackerView(routine: currentRoutine, viewModel: viewModel)
                                .transition(.identity)
                        }
                    }
                    .zIndex(2)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showingWorkoutSheet)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isMinimized)
                
                // Workout Summary Sheet
                .sheet(isPresented: $viewModel.showingWorkoutSummary) {
                    WorkoutSummaryView(routine: currentRoutine, viewModel: viewModel)
                }
            }
        }
    }
}

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
                Section(header: HStack {
                    Text(block.blockName)
                    Spacer()
                    Button("Edit") {
                        viewModel.blockToEdit = block
                        viewModel.isEditingBlock = true
                    }
                }) {
                    ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                }
            }
        }
        .navigationTitle(routine.routineDay)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    viewModel.routineToEdit = routine
                    viewModel.isEditingRoutine = true
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Start Workout") {
                    viewModel.startWorkout(routine: routine)
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditingRoutine) {
            if let routineToEdit = viewModel.routineToEdit {
                EditRoutineView(viewModel: viewModel, routine: routineToEdit)
            }
        }
        .sheet(isPresented: $viewModel.isEditingBlock) {
            if let blockToEdit = viewModel.blockToEdit {
                EditBlockView(viewModel: viewModel, block: blockToEdit)
            }
        }
    }
}

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
    let viewModel = RoutineViewModel(context: context)
    
    return ContentView(context: context)
        .environment(\.managedObjectContext, context)
        .environmentObject(viewModel)
}
