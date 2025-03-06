import SwiftUI
import CoreData

struct AddRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var day = ""
    @State private var muscleGroups = ""
    @State private var notes = ""
    @State private var blocks: [Block] = []
    @State private var showingAddBlock = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Details") {
                    TextField("Day (e.g. Monday)", text: $day)
                    TextField("Muscle Groups (comma separated)", text: $muscleGroups)
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section("Blocks") {
                    ForEach(blocks, id: \.blockID) { block in
                        BlockRowView(block: block)
                    }
                    
                    Button("Add Block") {
                        showingAddBlock = true
                    }
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .disabled(day.isEmpty || blocks.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockView(blocks: $blocks, viewContext: viewContext)
            }
        }
    }
    
    private func saveRoutine() {
        let muscleGroupsArray = muscleGroups.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        viewModel.addRoutine(
            day: day,
            muscleGroups: muscleGroupsArray,
            blocks: blocks,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

struct BlockRowView: View {
    let block: Block
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(block.blockName)
                .font(.headline)
            ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                Text("• \(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
                    .font(.subheadline)
            }
        }
    }
}

struct AddBlockView: View {
    @Binding var blocks: [Block]
    @Environment(\.dismiss) var dismiss
    let viewContext: NSManagedObjectContext
    
    @State private var blockName = ""
    @State private var numberOfSets: Int16 = 3
    @State private var exercises: [Exercise] = []
    @State private var showingAddExercise = false
    @State private var restSeconds: Int16 = 0
    
    init(blocks: Binding<[Block]>, viewContext: NSManagedObjectContext) {
        self._blocks = blocks
        self.viewContext = viewContext
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Block Name (e.g. Chest)", text: $blockName)
                Stepper("Number of Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
                
                Section("Rest Timer") {
                    Stepper("Rest Time: \(restSeconds) seconds", value: $restSeconds, in: 0...300, step: 30)
                        .foregroundColor(restSeconds > 0 ? .primary : .secondary)
                }
                
                Section("Exercises") {
                    ForEach(exercises, id: \.exerciseID) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Text("\(exercise.repsPerSet) reps @ \(String(format: "%.1f", exercise.weight))kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !exercise.exerciseTargetMuscles.isEmpty {
                                Text(exercise.exerciseTargetMuscles.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
                    }
                    
                    Button("Add Exercise") {
                        showingAddExercise = true
                    }
                }
            }
            .navigationTitle("New Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveBlock()
                    }
                    .disabled(blockName.isEmpty || exercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(exercises: $exercises, viewContext: viewContext)
            }
        }
    }
    
    private func saveBlock() {
        let newBlock = Block(context: viewContext)
        newBlock.id = UUID()
        newBlock.name = blockName
        newBlock.sets = numberOfSets
        newBlock.restSeconds = restSeconds
        
        // Add exercises to the block
        let exerciseSet = NSSet(array: exercises)
        newBlock.exercises = exerciseSet
        
        blocks.append(newBlock)
        dismiss()
    }
}

struct AddExerciseView: View {
    @Binding var exercises: [Exercise]
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var libraryViewModel: ExerciseLibraryViewModel
    @State private var showingNewExerciseForm = false
    @State private var selectedExercise: Exercise?
    @State private var reps: Int16 = 8
    @State private var weight: Double = 0.0
    
    init(exercises: Binding<[Exercise]>, viewContext: NSManagedObjectContext) {
        self._exercises = exercises
        self._libraryViewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let exercise = selectedExercise {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            
                            if !exercise.exerciseTargetMuscles.isEmpty {
                                Text("Target Muscles: \(exercise.exerciseTargetMuscles.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                            
                            HStack {
                                Text("Weight:")
                                TextField("Weight (kg)", value: $weight, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("kg")
                            }
                        }
                    } else {
                        Text("Select an exercise below")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Exercise Library")) {
                    ForEach(libraryViewModel.filteredExercises) { exercise in
                        Button {
                            selectedExercise = exercise
                            // Set initial weight to the last used weight if available
                            weight = exercise.weight
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.exerciseName)
                                        .foregroundColor(.primary)
                                    if !exercise.exerciseTargetMuscles.isEmpty {
                                        Text(exercise.exerciseTargetMuscles.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedExercise?.id == exercise.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
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