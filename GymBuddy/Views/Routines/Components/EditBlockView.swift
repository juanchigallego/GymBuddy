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
                Section("Details") {
                    TextField("Name", text: $blockName)
                    Stepper("Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
                    Stepper("Rest: \(restSeconds) seconds", value: $restSeconds, in: 0...300, step: 30)
                        .foregroundColor(restSeconds > 0 ? .primary : .secondary)
                }
                
                Section("Exercises") {
                    ForEach(exercises, id: \.id) { exercise in
                        HStack(alignment: .top) {
                            Text(exercise.exerciseName)
                                .font(.body)
                            Spacer()
                            Button {
                                
                            } label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Image(systemName: "repeat")
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .font(.system(size: 12))
                                    Text("\(exercise.repsPerSet) reps")
                                }
                            }
                            .buttonStyle(.label)
                            Button {
                                
                            } label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Image(systemName: "scalemass")
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .font(.system(size: 12))
                                    Text("\(String(format: "%.1f", exercise.weight))kg")
                                }
                            }
                            .buttonStyle(.label)
                        }
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }
                }
                
                Button {
                    showingAddExercise = true
                } label: {
                    Text("Add Exercise")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button() {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.circle)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
