import SwiftUI
import CoreData

struct EditBlockView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let block: Block
    @Environment(\.dismiss) var dismiss
    
    @State private var blockName: String
    @State private var exercises: [Exercise]
    @State private var showingAddExercise = false
    
    init(viewModel: RoutineViewModel, block: Block) {
        self.viewModel = viewModel
        self.block = block
        
        // Initialize state with current block values
        _blockName = State(initialValue: block.blockName)
        _exercises = State(initialValue: block.exerciseArray)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Block Name (e.g. Chest)", text: $blockName)
                
                Section("Exercises") {
                    ForEach(exercises, id: \.exerciseID) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Text("\(exercise.sets) sets × \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
                                .font(.subheadline)
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
            .navigationTitle("Edit Block")
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
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(exercises: $exercises)
            }
        }
    }
    
    private func saveBlock() {
        viewModel.updateBlock(
            block,
            name: blockName,
            exercises: exercises
        )
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Create a sample block
    let block = Block(context: context)
    block.id = UUID()
    block.name = "Chest"
    
    // Create some sample exercises
    let benchPress = Exercise(context: context)
    benchPress.id = UUID()
    benchPress.name = "Bench Press"
    benchPress.sets = 4
    benchPress.repsPerSet = 8
    benchPress.weight = 80.0
    benchPress.block = block
    
    let inclineDumbbell = Exercise(context: context)
    inclineDumbbell.id = UUID()
    inclineDumbbell.name = "Incline Dumbbell Press"
    inclineDumbbell.sets = 3
    inclineDumbbell.repsPerSet = 12
    inclineDumbbell.weight = 24.0
    inclineDumbbell.block = block
    
    let cableFly = Exercise(context: context)
    cableFly.id = UUID()
    cableFly.name = "Cable Fly"
    cableFly.sets = 3
    cableFly.repsPerSet = 15
    cableFly.weight = 15.0
    cableFly.block = block
    
    return EditBlockView(viewModel: RoutineViewModel(context: context), block: block)
        .environment(\.managedObjectContext, context)
} 