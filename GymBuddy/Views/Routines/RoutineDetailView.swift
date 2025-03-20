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
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingActionPopover = false
    @State private var actionAnchor: CGPoint = .zero
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Custom navigation title with buttons
                    HStack(spacing: 12) {
                        Text(routine.routineDay)
                            .font(.largeTitle)
                        
                        Spacer()
                        
                        // Favorite button
                        Button {
                            routineViewModel.toggleFavorite(routine)
                        } label: {
                            Image(systemName: routine.isFavorite ? "star.fill" : "star")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.circle)
                        
                        // More actions button with popover
                        Button {
                            showingActionPopover = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(CircleButtonStyle())
                        .popover(isPresented: $showingActionPopover) {
                            VStack(spacing: 0) {
                                // Archive/Unarchive button
                                Button {
                                    routineViewModel.toggleArchived(routine)
                                    showingActionPopover = false
                                } label: {
                                    HStack {
                                        Label(
                                            routine.isArchived ? "Unarchive" : "Archive",
                                            systemImage: routine.isArchived ? "archivebox.fill" : "archivebox"
                                        )
                                        Spacer()
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                
                                // Edit button
                                Button {
                                    routineViewModel.routineToEdit = routine
                                    routineViewModel.isEditingRoutine = true
                                    showingActionPopover = false
                                } label: {
                                    HStack {
                                        Label("Edit", systemImage: "pencil")
                                        Spacer()
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Header section with muscle groups and notes
                    VStack(alignment: .leading, spacing: 12) {
                        // Muscle groups tags
                        VStack(alignment: .leading, spacing: 8) {
                            FlowLayout(spacing: 8) {
                                ForEach(routine.muscleGroupsArray, id: \.self) { muscle in
                                    Tag(label: muscle)
                                }
                            }
                        }
                        
                        // Notes section
                        if let notes = routine.routineNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Blocks section
                    VStack(spacing: 8) {
                        ForEach(routine.blockArray, id: \.blockID) { block in
                            BlockCard(block: block, viewModel: routineViewModel)
                        }
                        Button {
                            
                        } label: {
                            Text("Add block")
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .padding(.bottom, 80) // Add padding at the bottom for the fixed button
            }
            
            // Fixed Start Workout button at the bottom
            VStack {
                Spacer()
                
                Button {
                    workoutViewModel.startWorkout(routine: routine)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                }
                .buttonStyle(.primaryPill)
                .disabled(routine.isArchived)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom)
                .background(Material.ultraThin)
            }
        }
        .navigationTitle(routine.routineDay)
        .toolbar {
            
        }
        .sheet(isPresented: $routineViewModel.isEditingRoutine) {
            if let routineToEdit = routineViewModel.routineToEdit {
                EditRoutineView(viewModel: routineViewModel, routine: routineToEdit)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Create a sample routine
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.routineDay = "Push Day"
    routine.muscleGroupsArray = ["Chest", "Shoulders", "Triceps"]
    routine.routineNotes = "Focus on progressive overload. Increase weight by 5% from last week."
    routine.isFavorite = true
    routine.isArchived = false
    
    // Create a sample block
    let block1 = Block(context: context)
    block1.id = UUID()
    block1.blockName = "Chest Focus"
    block1.sets = 4
    block1.restSeconds = 90
    block1.routine = routine
    
    // Create sample exercises for the block
    let exercise1 = Exercise(context: context)
    exercise1.id = UUID()
    exercise1.name = "Bench Press"
    exercise1.repsPerSet = 8
    exercise1.weight = 80.0
    exercise1.block = block1
    
    let exercise2 = Exercise(context: context)
    exercise2.id = UUID()
    exercise2.name = "Incline Dumbbell Press"
    exercise2.repsPerSet = 10
    exercise2.weight = 30.0
    exercise2.block = block1
    
    // Create a second block
    let block2 = Block(context: context)
    block2.id = UUID()
    block2.blockName = "Shoulder Work"
    block2.sets = 3
    block2.restSeconds = 60
    block2.routine = routine
    
    // Create sample exercises for the second block
    let exercise3 = Exercise(context: context)
    exercise3.id = UUID()
    exercise3.name = "Overhead Press"
    exercise3.repsPerSet = 8
    exercise3.weight = 50.0
    exercise3.block = block2
    
    // Save context
    try? context.save()
    
    // Create a view model
    let viewModel = RoutineViewModel(context: context)
    
    return NavigationStack {
        RoutineDetailView(routine: routine, routineViewModel: viewModel, workoutViewModel: WorkoutViewModel(context: context))
            .environment(\.managedObjectContext, context)
    }
}
