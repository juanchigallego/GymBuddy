import SwiftUI
import CoreData

struct EditRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @State private var editMode = EditMode.active // Start in edit mode
    
    @State private var day: String
    @State private var muscleGroups: String
    @State private var notes: String
    @State private var blocks: [Block]
    @State private var showingAddBlock = false
    
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
                    ForEach(blocks, id: \.blockID) { block in
                        BlockDetailView(block: block)
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
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockView(blocks: $blocks)
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

struct BlockDetailView: View {
    let block: Block
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(block.blockName)
                .font(.headline)
            Text("\(block.sets) sets")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if block.restSeconds > 0 {
                Text("Rest: \(block.restSeconds) seconds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ForEach(block.exerciseArray, id: \.exerciseID) { exercise in
                Text("• \(exercise.exerciseName): \(exercise.repsPerSet) reps @ \(exercise.weight)kg")
                    .font(.subheadline)
            }
        }
    }
} 