import SwiftUI
import CoreData

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