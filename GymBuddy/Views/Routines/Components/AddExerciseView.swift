import SwiftUI
import CoreData

/// A view for selecting exercises and configuring their settings for a block
struct AddExerciseView: View {
    @Binding var exercises: [Exercise]
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNewExerciseForm = false
    @State private var selectedExercise: Exercise?
    @State private var reps: Int16 = 8
    @State private var weight: Double = 0.0
    
    @StateObject private var libraryViewModel: ExerciseLibraryViewModel
    
    init(exercises: Binding<[Exercise]>, viewContext: NSManagedObjectContext) {
        self._exercises = exercises
        // Initialize StateObject using _StateObject directly
        self._libraryViewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Selected Exercise Settings
                if let exercise = selectedExercise {
                    Section {
                        ExerciseBlockSettingsForm(
                            exercise: exercise,
                            reps: $reps,
                            weight: $weight
                        )
                    }
                } else {
                    Section {
                        Text("Select an exercise below")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Exercise Library
                Section(header: Text("Exercise Library")) {
                    ForEach(libraryViewModel.filteredExercises) { exercise in
                        Button {
                            selectedExercise = exercise
                            // Set initial weight to the last used weight if available
                            weight = exercise.weight
                        } label: {
                            ExerciseSelectionRow(
                                exercise: exercise,
                                isSelected: selectedExercise?.id == exercise.id,
                                onSelect: {}
                            )
                        }
                    }
                    
                    Button("Create New Exercise") {
                        showingNewExerciseForm = true
                    }
                }
                
                if !libraryViewModel.searchText.isEmpty && libraryViewModel.filteredExercises.isEmpty {
                    Text("No matching exercises found")
                        .foregroundColor(.secondary)
                }
            }
            .searchable(text: $libraryViewModel.searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveExercise()
                    }
                    .disabled(selectedExercise == nil)
                }
            }
            .sheet(isPresented: $showingNewExerciseForm) {
                ExerciseFormView(
                    name: "",
                    selectedMuscles: [],
                    notes: "",
                    isPresented: $showingNewExerciseForm,
                    onSave: { name, muscles, notes in
                        libraryViewModel.addExercise(name: name, targetMuscles: muscles, notes: notes)
                        if let newExercise = libraryViewModel.exercises.first(where: { $0.exerciseName == name }) {
                            selectedExercise = newExercise
                        }
                    }
                )
            }
        }
    }
    
    private func saveExercise() {
        guard let selectedExercise = selectedExercise else { return }
        
        // Create a new exercise instance for this block
        let exercise = Exercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = selectedExercise.exerciseName
        exercise.targetMuscles = selectedExercise.exerciseTargetMuscles as NSArray
        exercise.notes = selectedExercise.exerciseNotes
        exercise.repsPerSet = reps
        exercise.weight = weight
        
        exercises.append(exercise)
        dismiss()
    }
} 