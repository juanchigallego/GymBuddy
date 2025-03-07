import SwiftUI
import CoreData

struct EditExercisesView: View {
    let block: Block
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
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
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(exercises: $exercises, viewContext: viewContext)
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