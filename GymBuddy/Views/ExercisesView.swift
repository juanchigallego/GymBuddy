import SwiftUI
import CoreData

struct ExercisesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ExerciseLibraryViewModel
    @State private var showingAddExercise = false
    @State private var exerciseToDelete: Exercise?
    @State private var showingDeleteConfirmation = false
    
    init(viewContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search exercises", text: $viewModel.searchText)
                            .autocorrectionDisabled()
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All Muscles",
                                isSelected: viewModel.selectedMuscleFilter == nil,
                                action: { viewModel.selectedMuscleFilter = nil }
                            )
                            
                            ForEach(Muscle.allCases) { muscle in
                                FilterChip(
                                    title: muscle.rawValue,
                                    isSelected: viewModel.selectedMuscleFilter == muscle,
                                    action: { viewModel.selectedMuscleFilter = muscle }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Exercise list
                if viewModel.filteredExercises.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text(viewModel.searchText.isEmpty && viewModel.selectedMuscleFilter == nil
                             ? "No exercises found\nTap + to add your first exercise"
                             : "No matching exercises found")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise, viewContext: viewContext)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    exerciseToDelete = exercise
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Exercise Library")
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise, viewContext: viewContext)
            }
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
                    name: "",
                    selectedMuscles: [],
                    notes: "",
                    isPresented: $showingAddExercise,
                    onSave: { name, muscles, notes in
                        viewModel.addExercise(
                            name: name,
                            targetMuscles: muscles,
                            notes: notes
                        )
                    }
                )
            }
            .confirmationDialog(
                "Delete Exercise",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        viewModel.deleteExercise(exercise)
                        exerciseToDelete = nil
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    exerciseToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete '\(exerciseToDelete?.exerciseName ?? "")'? This action cannot be undone.")
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
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if !exercise.exerciseTargetMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Muscles:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 6) {
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
            
            if let notes = exercise.exerciseNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// FlowLayout to display muscle tags in a flowing manner
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        let width = bounds.width
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > width + bounds.minX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

struct ExerciseFormView: View {
    @Binding var isPresented: Bool
    @State private var name: String
    @State private var selectedMuscles: Set<Muscle>
    @State private var notes: String
    @FocusState private var focusedField: Field?
    
    let onSave: (String, [Muscle], String) -> Void
    
    enum Field {
        case name, notes
    }
    
    init(
        name: String,
        selectedMuscles: Set<Muscle>,
        notes: String,
        isPresented: Binding<Bool>,
        onSave: @escaping (String, [Muscle], String) -> Void
    ) {
        self._name = State(initialValue: name)
        self._selectedMuscles = State(initialValue: selectedMuscles)
        self._notes = State(initialValue: notes)
        self._isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .notes
                        }
                }
                
                Section(header: Text("Target Muscles")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select all that apply:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 8)
                        ], spacing: 8) {
                            ForEach(Muscle.allCases, id: \.self) { muscle in
                                MuscleToggleButton(
                                    muscle: muscle,
                                    isSelected: selectedMuscles.contains(muscle),
                                    onToggle: { isSelected in
                                        if isSelected {
                                            selectedMuscles.insert(muscle)
                                        } else {
                                            selectedMuscles.remove(muscle)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .focused($focusedField, equals: .notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(name.isEmpty ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, Array(selectedMuscles), notes)
                        isPresented = false
                    }
                    .disabled(name.isEmpty || selectedMuscles.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                // Focus on name field when form appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .name
                }
            }
        }
    }
}

struct MuscleToggleButton: View {
    let muscle: Muscle
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack {
                Text(muscle.rawValue)
                    .font(.subheadline)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var routineViewModel: RoutineViewModel
    
    init(exercise: Exercise, viewContext: NSManagedObjectContext) {
        self.exercise = exercise
        self._routineViewModel = StateObject(wrappedValue: RoutineViewModel(context: viewContext))
    }
    
    var routinesUsingExercise: [(routine: Routine, block: Block)] {
        let fetchRequest = NSFetchRequest<Block>(entityName: "Block")
        fetchRequest.predicate = NSPredicate(format: "ANY exercises.name == %@", exercise.exerciseName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Block.name, ascending: true)]
        
        do {
            let blocks = try viewContext.fetch(fetchRequest)
            return blocks.compactMap { block -> (routine: Routine, block: Block)? in
                guard let routine = block.routine else { return nil }
                return (routine: routine, block: block)
            }
        } catch {
            print("Error fetching blocks: \(error)")
            return []
        }
    }
    
    var body: some View {
        List {
            // Exercise Information
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Target Muscles
                    if !exercise.exerciseTargetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Muscles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 6) {
                                ForEach(exercise.exerciseTargetMuscles, id: \.self) { muscle in
                                    Text(muscle)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = exercise.exerciseNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(notes)
                                .font(.body)
                        }
                    }
                }
            }
            
            // Routines containing this exercise
            Section(header: Text("Used in Routines")) {
                if !routinesUsingExercise.isEmpty {
                    ForEach(routinesUsingExercise, id: \.routine.id) { routineInfo in
                        NavigationLink {
                            RoutineDetailView(routine: routineInfo.routine, viewModel: routineViewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routineInfo.routine.routineDay)
                                    .font(.body)
                                Text("In \(routineInfo.block.blockName) block")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Not used in any routines")
                        .foregroundColor(.secondary)
                }
            }
            
            // Exercise History
            Section(header: Text("Exercise History")) {
                // TODO: Add chart showing weight progression
                Text("Coming soon: Weight progression chart")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(exercise.exerciseName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseFormView(
                name: exercise.exerciseName,
                selectedMuscles: Set(exercise.exerciseTargetMuscles.compactMap { muscleName in
                    Muscle.allCases.first { $0.rawValue == muscleName }
                }),
                notes: exercise.exerciseNotes ?? "",
                isPresented: $showingEditSheet,
                onSave: { name, muscles, notes in
                    // Update exercise
                    exercise.name = name
                    exercise.exerciseTargetMuscles = muscles.map { $0.rawValue }
                    exercise.notes = notes
                    
                    // Save context
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving context: \(error)")
                    }
                }
            )
        }
    }
}
