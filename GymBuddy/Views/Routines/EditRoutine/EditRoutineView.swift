import SwiftUI
import CoreData

struct EditRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = blocks.firstIndex(where: { $0.id == block.id }) {
                                    blocks.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                    
                    Button("Add Block") {
                        showingAddBlock = true
                    }
                }
            }
            .navigationTitle("Edit Routine")
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

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Create a sample routine
    let routine = Routine(context: context)
    routine.id = UUID()
    routine.day = "Push Day"
    routine.muscleGroupsArray = ["Chest", "Shoulders", "Triceps"]
    routine.notes = "Focus on form"
    
    // Create a sample block
    let block = Block(context: context)
    block.id = UUID()
    block.name = "Chest Press"
    block.sets = 3
    block.restSeconds = 90
    block.routine = routine
    
    // Create a sample exercise
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.repsPerSet = 10
    exercise.weight = 60.0
    exercise.block = block
    
    // Save context
    try? context.save()
    
    // Create view model
    let viewModel = RoutineViewModel(context: context)
    
    return NavigationStack {
        EditRoutineView(viewModel: viewModel, routine: routine)
            .environment(\.managedObjectContext, context)
    }
}
