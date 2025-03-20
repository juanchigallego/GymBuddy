import SwiftUI
import CoreData

// Helper class to make exercise properties reactive
class ExerciseViewModel: ObservableObject, Identifiable {
    @Published var exercise: Exercise
    var id: UUID { exercise.id ?? UUID() }
    
    init(exercise: Exercise) {
        self.exercise = exercise
    }
    
    // Computed properties that directly reflect the underlying exercise
    var repsPerSet: Int16 {
        get { exercise.repsPerSet }
    }
    
    var weight: Double {
        get { exercise.weight }
    }
    
    var exerciseName: String {
        get { exercise.exerciseName }
    }
}

struct EditBlockView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let block: Block
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var blockName: String
    @State private var exerciseViewModels: [ExerciseViewModel] = []
    @State private var numberOfSets: Int16
    @State private var showingAddExercise = false
    @State private var restSeconds: Int16
    @State private var showingRepsEditor = false
    @State private var showingWeightEditor = false
    @State private var selectedExerciseVM: ExerciseViewModel?
    @State private var selectedProperty: ExerciseProperty = .reps
    
    // Add this to force UI updates
    @State private var updateCounter: Int = 0
    
    init(viewModel: RoutineViewModel, block: Block) {
        self.viewModel = viewModel
        self.block = block
        
        // Initialize state with current block values
        _blockName = State(initialValue: block.name ?? "")
        _numberOfSets = State(initialValue: block.sets)
        _restSeconds = State(initialValue: block.restSeconds)
        
        // Initialize exercise view models
        if let exercises = block.exercises?.allObjects as? [Exercise] {
            _exerciseViewModels = State(initialValue: exercises.map { ExerciseViewModel(exercise: $0) })
        }
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
                    ForEach(exerciseViewModels) { exerciseVM in
                        HStack(alignment: .top) {
                            Text(exerciseVM.exerciseName)
                                .font(.body)
                            Spacer()
                            Button {
                                selectedExerciseVM = exerciseVM
                                selectedProperty = .reps
                                showingRepsEditor = true
                            } label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Image(systemName: "repeat")
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .font(.system(size: 12))
                                    Text("\(exerciseVM.repsPerSet) reps")
                                        .contentTransition(.numericText())
                                }
                            }
                            .buttonStyle(.label)
                            .id("reps-\(exerciseVM.id)-\(updateCounter)")
                            
                            Button {
                                selectedExerciseVM = exerciseVM
                                selectedProperty = .weight
                                showingWeightEditor = true
                            } label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Image(systemName: "scalemass")
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .font(.system(size: 12))
                                    Text("\(String(format: "%.1f", exerciseVM.weight))kg")
                                        .contentTransition(.numericText())
                                }
                            }
                            .buttonStyle(.label)
                            .id("weight-\(exerciseVM.id)-\(updateCounter)")
                        }
                    }
                    .onDelete { indexSet in
                        exerciseViewModels.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        exerciseViewModels.move(fromOffsets: from, toOffset: to)
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
                    .disabled(blockName.isEmpty || exerciseViewModels.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise, onDismiss: {
                refreshExercises()
            }) {
                AddExerciseView(exercises: Binding(
                    get: { exerciseViewModels.map { $0.exercise } },
                    set: { _ in refreshExercises() }
                ), viewContext: viewContext)
            }
            .sheet(isPresented: $showingRepsEditor, onDismiss: {
                // Force UI to update by triggering state change
                updateCounter += 1
                refreshExercises()
            }) {
                if let exerciseVM = selectedExerciseVM {
                    ExercisePropertyEditor(exercise: exerciseVM.exercise, property: .reps)
                }
            }
            .sheet(isPresented: $showingWeightEditor, onDismiss: {
                // Force UI to update by triggering state change
                updateCounter += 1
                refreshExercises()
            }) {
                if let exerciseVM = selectedExerciseVM {
                    ExercisePropertyEditor(exercise: exerciseVM.exercise, property: .weight)
                }
            }
        }
    }
    
    private func refreshExercises() {
        if let exercises = block.exercises?.allObjects as? [Exercise] {
            // Re-create view models to ensure fresh data
            exerciseViewModels = exercises.map { ExerciseViewModel(exercise: $0) }
        }
    }
    
    private func saveBlock() {
        // Use view model to update the block
        viewModel.updateBlock(
            block, 
            name: blockName, 
            sets: numberOfSets, 
            restSeconds: restSeconds
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
