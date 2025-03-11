//
//  ContentView.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 11/12/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    let context: NSManagedObjectContext
    @StateObject private var viewModel: RoutineViewModel
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self._viewModel = StateObject(wrappedValue: RoutineViewModel(context: context))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    List {
                        if !viewModel.favoriteRoutines.isEmpty {
                            Section("Favorites") {
                                ForEach(viewModel.favoriteRoutines) { routine in
                                    NavigationLink {
                                        RoutineDetailView(routine: routine, viewModel: viewModel)
                                    } label: {
                                        RoutineRowView(routine: routine)
                                    }
                                }
                            }
                        }
                        
                        Section("Active Routines") {
                            ForEach(viewModel.activeRoutines.filter { !$0.isFavorite }) { routine in
                                NavigationLink {
                                    RoutineDetailView(routine: routine, viewModel: viewModel)
                                } label: {
                                    RoutineRowView(routine: routine)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteRoutine(viewModel.activeRoutines[index])
                                }
                            }
                        }
                        
                        if !viewModel.archivedRoutines.isEmpty {
                            Section("Archived") {
                                ForEach(viewModel.archivedRoutines) { routine in
                                    NavigationLink {
                                        RoutineDetailView(routine: routine, viewModel: viewModel)
                                    } label: {
                                        RoutineRowView(routine: routine)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Routines")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                viewModel.isAddingRoutine = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.isAddingRoutine) {
                        AddRoutineView(viewModel: viewModel)
                    }
                }
                .tabItem {
                    Label("Routines", systemImage: "dumbbell.fill")
                }
                
                ExercisesView(viewContext: context)
                    .tabItem {
                        Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                    }
                
                WorkoutHistoryView(viewModel: viewModel)
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
            }
            
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
                                .padding(.bottom, 49) // Standard tab bar height
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

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = RoutineViewModel(context: context)
    
    return ContentView(context: context)
        .environment(\.managedObjectContext, context)
        .environmentObject(viewModel)
}
