import SwiftUI
import CoreData

/// A detailed view for displaying and editing exercise information
struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var routineViewModel: RoutineViewModel
    
    init(exercise: Exercise, viewContext: NSManagedObjectContext) {
        self.exercise = exercise
        self._routineViewModel = StateObject(wrappedValue: RoutineViewModel(context: viewContext))
    }
    
    var routinesUsingExercise: [(routine: Routine, block: Block)] {
        let fetchRequest = NSFetchRequest<Block>(entityName: "Block")
        fetchRequest.predicate = NSPredicate(format: "ANY exercises.name == %@", exercise.exerciseName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Block.name, ascending: true)]
        
        do {
            let blocks = try viewContext.fetch(fetchRequest)
            return blocks.compactMap { block -> (routine: Routine, block: Block)? in
                guard let routine = block.routine else { return nil }
                return (routine: routine, block: block)
            }
        } catch {
            print("Error fetching blocks: \(error)")
            return []
        }
    }
    
    var body: some View {
        List {
            // Exercise Information
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Target Muscles
                    if !exercise.exerciseTargetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Muscles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ExerciseMuscleTagsView(
                                muscles: exercise.exerciseTargetMuscles,
                                fontSize: .subheadline
                            )
                        }
                    }
                    
                    // Notes
                    if let notes = exercise.exerciseNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(notes)
                                .font(.body)
                        }
                    }
                }
            }
            
            // Routines containing this exercise
            Section(header: Text("Used in Routines")) {
                if !routinesUsingExercise.isEmpty {
                    ForEach(routinesUsingExercise, id: \.routine.id) { routineInfo in
                        NavigationLink {
                            RoutineDetailView(routine: routineInfo.routine, viewModel: routineViewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routineInfo.routine.routineDay)
                                    .font(.body)
                                Text("In \(routineInfo.block.blockName) block")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Not used in any routines")
                        .foregroundColor(.secondary)
                }
            }
            
            // Exercise History
            Section(header: Text("Exercise History")) {
                // TODO: Add chart showing weight progression
                Text("Coming soon: Weight progression chart")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(exercise.exerciseName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseFormView(
                name: exercise.exerciseName,
                selectedMuscles: Set(exercise.exerciseTargetMuscles.compactMap { muscleName in
                    Muscle.allCases.first { $0.rawValue == muscleName }
                }),
                notes: exercise.exerciseNotes ?? "",
                isPresented: $showingEditSheet,
                onSave: { name, muscles, notes in
                    // Update exercise
                    exercise.name = name
                    exercise.exerciseTargetMuscles = muscles.map { $0.rawValue }
                    exercise.notes = notes
                    
                    // Save context
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving context: \(error)")
                    }
                }
            )
        }
    }
} 