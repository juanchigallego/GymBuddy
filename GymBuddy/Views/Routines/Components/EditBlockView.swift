import SwiftUI
import CoreData

struct EditBlockView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let block: Block
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var blockName: String
    @State private var exercises: [Exercise]
    @State private var numberOfSets: Int16
    @State private var showingAddExercise = false
    @State private var restSeconds: Int16
    
    init(viewModel: RoutineViewModel, block: Block) {
        self.viewModel = viewModel
        self.block = block
        
        // Initialize state with current block values
        _blockName = State(initialValue: block.name ?? "")
        _exercises = State(initialValue: (block.exercises?.allObjects as? [Exercise]) ?? [])
        _numberOfSets = State(initialValue: block.sets)
        _restSeconds = State(initialValue: block.restSeconds)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Block Name (e.g. Chest)", text: $blockName)
                    Stepper("Number of Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
                }
                
                Section("Rest Timer") {
                    Stepper("Rest Time: \(restSeconds) seconds", value: $restSeconds, in: 0...300, step: 30)
                        .foregroundColor(restSeconds > 0 ? .primary : .secondary)
                }
                
                Section("Exercises") {
                    ForEach(exercises, id: \.id) { exercise in
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
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }
                    
                    Button("Add Exercise") {
                        showingAddExercise = true
                    }
                }
                
                if !exercises.isEmpty {
                    Section("Summary") {
                        Text("This block consists of \(numberOfSets) sets of:")
                            .font(.subheadline)
                        ForEach(exercises, id: \.id) { exercise in
                            Text("• \(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(String(format: "%.1f", exercise.weight))kg")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBlock()
                    }
                    .disabled(blockName.isEmpty || exercises.isEmpty)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(exercises: $exercises, viewContext: viewContext)
            }
        }
    }
    
    private func saveBlock() {
        // Update block properties
        block.name = blockName
        block.sets = numberOfSets
        block.restSeconds = restSeconds
        
        // Update exercises
        block.exercises = NSSet(array: exercises)
        
        // Save context
        try? viewContext.save()
        
        // Update UI
        viewModel.fetchRoutines()
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Create a sample block
    let block = Block(context: context)
    block.id = UUID()
    block.name = "Chest"
    block.sets = 4
    
    // Create some sample exercises
    let benchPress = Exercise(context: context)
    benchPress.id = UUID()
    benchPress.name = "Bench Press"
    benchPress.repsPerSet = 8
    benchPress.weight = 80.0
    benchPress.block = block
    
    let inclineDumbbell = Exercise(context: context)
    inclineDumbbell.id = UUID()
    inclineDumbbell.name = "Incline Dumbbell Press"
    inclineDumbbell.repsPerSet = 12
    inclineDumbbell.weight = 24.0
    inclineDumbbell.block = block
    
    let cableFly = Exercise(context: context)
    cableFly.id = UUID()
    cableFly.name = "Cable Fly"
    cableFly.repsPerSet = 15
    cableFly.weight = 15.0
    cableFly.block = block
    
    return EditBlockView(viewModel: RoutineViewModel(context: context), block: block)
        .environment(\.managedObjectContext, context)
} 