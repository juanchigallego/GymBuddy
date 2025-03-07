import SwiftUI

/// A reusable view for selecting target muscles using a grid layout
struct ExerciseMuscleSelector: View {
    @Binding var selectedMuscles: Set<Muscle>
    
    var body: some View {
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
} 