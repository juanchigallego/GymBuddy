import SwiftUI
import CoreData

/// The main view for browsing and managing exercises
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