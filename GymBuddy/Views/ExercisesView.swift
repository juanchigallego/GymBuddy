import SwiftUI
import CoreData

struct ExercisesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ExerciseLibraryViewModel
    @State private var showingAddExercise = false
    @State private var showingEditExercise = false
    @State private var selectedExercise: Exercise?
    
    init(viewContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search and filter bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search exercises", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Menu {
                        Button("All Muscles") {
                            viewModel.selectedMuscleFilter = nil
                        }
                        
                        Divider()
                        
                        ForEach(Muscle.allCases) { muscle in
                            Button(muscle.rawValue) {
                                viewModel.selectedMuscleFilter = muscle
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedMuscleFilter?.rawValue ?? "All Muscles")
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Exercise list
                List {
                    ForEach(viewModel.filteredExercises) { exercise in
                        ExerciseRow(exercise: exercise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExercise = exercise
                                showingEditExercise = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                ExerciseFormView(
                    isPresented: $showingAddExercise,
                    onSave: { name, muscles, reps, weight, notes in
                        viewModel.addExercise(
                            name: name,
                            targetMuscles: muscles,
                            repsPerSet: Int16(reps),
                            weight: weight,
                            notes: notes
                        )
                    }
                )
            }
            .sheet(isPresented: $showingEditExercise, onDismiss: {
                selectedExercise = nil
            }) {
                if let exercise = selectedExercise {
                    ExerciseFormView(
                        isPresented: $showingEditExercise,
                        exercise: exercise,
                        onSave: { name, muscles, reps, weight, notes in
                            viewModel.updateExercise(
                                exercise,
                                name: name,
                                targetMuscles: muscles,
                                repsPerSet: Int16(reps),
                                weight: weight,
                                notes: notes
                            )
                        }
                    )
                }
            }
            .onAppear {
                viewModel.fetchExercises()
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if !exercise.exerciseTargetMuscles.isEmpty {
                HStack {
                    Text("Muscles:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(exercise.exerciseTargetMuscles, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExerciseFormView: View {
    @Binding var isPresented: Bool
    var exercise: Exercise?
    var onSave: (String, [Muscle], Int, Double, String) -> Void
    
    @State private var name: String = ""
    @State private var selectedMuscles: Set<Muscle> = []
    @State private var repsPerSet: Int = 0
    @State private var weight: Double = 0.0
    @State private var notes: String = ""
    
    var isEditing: Bool {
        exercise != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Name", text: $name)
                    
                    Stepper("Reps per set: \(repsPerSet)", value: $repsPerSet, in: 0...100)
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                    }
                }
                
                Section(header: Text("Target Muscles")) {
                    ForEach(Muscle.allCases) { muscle in
                        Button {
                            if selectedMuscles.contains(muscle) {
                                selectedMuscles.remove(muscle)
                            } else {
                                selectedMuscles.insert(muscle)
                            }
                        } label: {
                            HStack {
                                Text(muscle.rawValue)
                                Spacer()
                                if selectedMuscles.contains(muscle) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, Array(selectedMuscles), repsPerSet, weight, notes)
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let exercise = exercise {
                    name = exercise.exerciseName
                    repsPerSet = Int(exercise.repsPerSet)
                    weight = exercise.weight
                    notes = exercise.exerciseNotes ?? ""
                    
                    // Convert string muscle names to Muscle enum values
                    selectedMuscles = Set(exercise.exerciseTargetMuscles.compactMap { muscleName in
                        Muscle.allCases.first { $0.rawValue == muscleName }
                    })
                }
            }
        }
    }
} 