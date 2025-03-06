import SwiftUI
import CoreData

struct EditRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @State private var editMode = EditMode.active
    
    @State private var day: String
    @State private var muscleGroups: String
    @State private var notes: String
    @State private var blocks: [Block]
    @State private var showingAddBlock = false
    @State private var selectedBlock: Block?
    @State private var showingEditExercises = false
    
    init(viewModel: RoutineViewModel, routine: Routine) {
        self.viewModel = viewModel
        self.routine = routine
        
        // Initialize state with current routine values
        _day = State(initialValue: routine.routineDay)
        _muscleGroups = State(initialValue: routine.muscleGroupsArray.joined(separator: ", "))
        _notes = State(initialValue: routine.routineNotes ?? "")
        _blocks = State(initialValue: routine.blockArray)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Details") {
                    TextField("Day (e.g. Monday)", text: $day)
                    TextField("Muscle Groups (comma separated)", text: $muscleGroups)
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section(header: Text("Blocks")) {
                    ForEach($blocks) { $block in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(block.blockName)
                                    .font(.headline)
                                Spacer()
                                Button("Edit Exercises") {
                                    selectedBlock = block
                                    showingEditExercises = true
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Stepper("Sets: \(block.sets)", value: .init(
                                    get: { block.sets },
                                    set: { block.sets = $0 }
                                ), in: 1...10)
                                
                                Stepper("Rest: \(block.restSeconds) seconds", value: .init(
                                    get: { block.restSeconds },
                                    set: { block.restSeconds = $0 }
                                ), in: 0...300, step: 30)
                            }
                            .padding(.vertical, 4)
                            
                            ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                                Text("• \(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        blocks.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        blocks.move(fromOffsets: from, toOffset: to)
                    }
                    
                    Button("Add Block") {
                        showingAddBlock = true
                    }
                }
            }
            .navigationTitle("Edit Routine")
            .environment(\.editMode, $editMode)
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
                
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockView(blocks: $blocks)
            }
            .sheet(isPresented: $showingEditExercises) {
                if let block = selectedBlock {
                    NavigationStack {
                        EditExercisesView(block: block)
                    }
                }
            }
        }
    }
    
    private func saveRoutine() {
        let muscleGroupsArray = muscleGroups.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        viewModel.updateRoutine(
            routine,
            day: day,
            muscleGroups: muscleGroupsArray,
            blocks: blocks,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

struct EditExercisesView: View {
    let block: Block
    @Environment(\.dismiss) var dismiss
    @State private var exercises: [Exercise]
    @State private var showingAddExercise = false
    
    init(block: Block) {
        self.block = block
        _exercises = State(initialValue: block.exerciseArray)
    }
    
    var body: some View {
        Form {
            ForEach($exercises) { $exercise in
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Exercise Name", text: .init(
                        get: { exercise.exerciseName },
                        set: { exercise.name = $0 }
                    ))
                    .font(.headline)
                    
                    Stepper("Reps: \(exercise.repsPerSet)", value: .init(
                        get: { exercise.repsPerSet },
                        set: { exercise.repsPerSet = $0 }
                    ), in: 1...30)
                    
                    HStack {
                        Text("Weight:")
                        TextField("Weight (kg)", value: .init(
                            get: { exercise.weight },
                            set: { exercise.weight = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        Text("kg")
                    }
                    
                    if let notes = exercise.notes {
                        TextField("Notes", text: .init(
                            get: { notes },
                            set: { exercise.notes = $0 }
                        ))
                    }
                }
            }
            .onDelete { indexSet in
                exercises.remove(atOffsets: indexSet)
            }
            .onMove { from, to in
                exercises.move(fromOffsets: from, toOffset: to)
            }
            
            Button("Add Exercise") {
                showingAddExercise = true
            }
        }
        .navigationTitle("Edit Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveExercises()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(exercises: $exercises)
        }
    }
    
    private func saveExercises() {
        // Update the block's exercises
        block.exercises = NSSet(array: exercises)
        
        // Save the context
        let context = block.managedObjectContext
        try? context?.save()
        
        dismiss()
    }
} 