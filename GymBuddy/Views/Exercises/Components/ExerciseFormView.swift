import SwiftUI

/// A view for creating and editing exercises in the library
struct ExerciseFormView: View {
    @Binding var isPresented: Bool
    @State private var name: String
    @State private var selectedMuscles: Set<Muscle>
    @State private var notes: String
    
    let onSave: (String, [Muscle], String) -> Void
    
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
            ExerciseDefinitionForm(
                name: $name,
                selectedMuscles: $selectedMuscles,
                notes: $notes
            )
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
                        // No need for focusedField here as it's handled in ExerciseDefinitionForm
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                     to: nil, 
                                                     from: nil, 
                                                     for: nil)
                    }
                }
            }
        }
    }
} 