import SwiftUI

/// A reusable form for editing core exercise definition data
struct ExerciseDefinitionForm: View {
    @Binding var name: String
    @Binding var selectedMuscles: Set<Muscle>
    @Binding var notes: String
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, notes
    }
    
    var body: some View {
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
                ExerciseMuscleSelector(selectedMuscles: $selectedMuscles)
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .focused($focusedField, equals: .notes)
                    .frame(minHeight: 100)
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