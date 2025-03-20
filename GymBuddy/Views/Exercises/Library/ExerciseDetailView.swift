import SwiftUI
import CoreData
import Charts

/// A detailed view for displaying and editing exercise information
struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var routineViewModel: RoutineViewModel
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var progressEntries: [ExerciseProgress] = []
    
    init(exercise: Exercise, viewContext: NSManagedObjectContext, progressViewModel: ProgressViewModel) {
        self.exercise = exercise
        self.progressViewModel = progressViewModel
        self._routineViewModel = ObservedObject(wrappedValue: RoutineViewModel(context: viewContext))
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
    
    private func fetchProgressEntries() {
        progressEntries = progressViewModel.getProgressEntriesForExercise(exerciseName: exercise.exerciseName)
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
            
            // Exercise History
            Section(header: Text("Weight Progression")) {
                ExerciseProgressChart(progressEntries: progressEntries)
                    .listRowInsets(EdgeInsets())
            }
            
            // Routines containing this exercise
            Section(header: Text("Used in Routines")) {
                if !routinesUsingExercise.isEmpty {
                    ForEach(routinesUsingExercise, id: \.routine.id) { routineInfo in
                        NavigationLink {
                            RoutineDetailView(
                                routine: routineInfo.routine, 
                                routineViewModel: routineViewModel,
                                workoutViewModel: WorkoutViewModel(context: viewContext)
                            )
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
        .onAppear {
            fetchProgressEntries()
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Create a sample routine first
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.day = "Push Day"
    routine.targetMuscleGroups = ["Chest", "Shoulders", "Triceps"] as NSArray
    
    // Create a block
    let block = Block(context: context)
    block.id = UUID()
    block.name = "Chest"
    block.sets = 4
    block.routine = routine
    
    // Create a sample exercise
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.weight = 100.0
    exercise.repsPerSet = 8
    exercise.notes = "Focus on form and controlled descent"
    exercise.targetMuscles = ["Chest", "Triceps", "Shoulders"] as NSArray
    exercise.block = block
    
    // Create sample progress entries
    let calendar = Calendar.current
    let today = Date()
    let progressions: [(daysAgo: Int, weight: Double)] = [
        (60, 85.0),  // Starting weight
        (45, 87.5),  // Small increase
        (30, 90.0),  // Regular progression
        (21, 92.5),  // Good progress
        (14, 95.0),  // Consistent gains
        (7, 97.5),   // Recent progress
        (0, 100.0)   // Current weight
    ]
    
    for progression in progressions {
        let entry = ExerciseProgress(context: context)
        entry.id = UUID()
        entry.date = calendar.date(byAdding: .day, value: -progression.daysAgo, to: today)
        entry.weight = progression.weight
        entry.reps = 8
        entry.exerciseName = exercise.name
        entry.exercise = exercise
        entry.notes = "Good form, felt strong"
    }
    
    try? context.save()
    
    // Create view models
    let progressViewModel = ProgressViewModel(context: context)
    
    return NavigationStack {
        ExerciseDetailView(
            exercise: exercise, 
            viewContext: context,
            progressViewModel: progressViewModel
        )
        .environment(\.managedObjectContext, context)
    }
} 