import SwiftUI
import CoreData

struct AddRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    
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
                AddBlockView(blocks: $blocks)
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
    
    @State private var blockName = ""
    @State private var numberOfSets: Int16 = 3
    @State private var exercises: [Exercise] = []
    @State private var showingAddExercise = false
    @State private var restSeconds: Int16 = 0
    
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
                        Text("\(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
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
                AddExerciseView(exercises: $exercises)
            }
        }
    }
    
    private func saveBlock() {
        let context = PersistenceController.shared.container.viewContext
        let newBlock = Block(context: context)
        newBlock.id = UUID()
        newBlock.name = blockName
        newBlock.sets = numberOfSets
        newBlock.restSeconds = restSeconds
        
        for exercise in exercises {
            let newExercise = Exercise(context: context)
            newExercise.id = UUID()
            newExercise.name = exercise.exerciseName
            newExercise.repsPerSet = exercise.repsPerSet
            newExercise.weight = exercise.weight
            newExercise.block = newBlock
        }
        
        blocks.append(newBlock)
        dismiss()
    }
}

struct AddExerciseView: View {
    @Binding var exercises: [Exercise]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var reps: Int16 = 8
    @State private var weight: Double = 0.0
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise Name", text: $name)
                Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                HStack {
                    Text("Weight:")
                    TextField("Weight (kg)", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                }
                TextField("Notes (optional)", text: $notes)
            }
            .navigationTitle("New Exercise")
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        let context = PersistenceController.shared.container.viewContext
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.repsPerSet = reps
        exercise.weight = weight
        exercise.notes = notes.isEmpty ? nil : notes
        
        exercises.append(exercise)
        dismiss()
    }
} 