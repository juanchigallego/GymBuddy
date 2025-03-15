import SwiftUI
import CoreData

enum ExerciseProperty {
    case reps
    case weight
    
    var title: String {
        switch self {
        case .reps: return "reps"
        case .weight: return "kg"
        }
    }
    
    var label: String {
        switch self {
        case .reps: return "Reps"
        case .weight: return "Weight"
        }
    }
    
    var icon: String {
        switch self {
        case .reps: return "repeat"
        case .weight: return "scalemass"
        }
    }
    
    var range: ClosedRange<Double> {
        switch self {
        case .reps: return 1...30
        case .weight: return 0...200
        }
    }
    
    var step: Double {
        switch self {
        case .reps: return 1
        case .weight: return 0.5
        }
    }
    
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = self == .weight
        formatter.minimumFractionDigits = self == .weight ? 1 : 0
        formatter.maximumFractionDigits = self == .weight ? 1 : 0
        return formatter
    }
}

struct ExercisePropertyEditor: View {
    let exercise: Exercise
    let property: ExerciseProperty
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var value: Double
    @State private var lastSteppedValue: Double = 0
    @State private var isSliderActive: Bool = false
    
    // Add haptic feedback generator
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(exercise: Exercise, property: ExerciseProperty) {
        self.exercise = exercise
        self.property = property
        
        // Initialize state with current value
        _value = State(initialValue: property == .reps ? Double(exercise.repsPerSet) : exercise.weight)
        _lastSteppedValue = State(initialValue: property == .reps ? Double(exercise.repsPerSet) : exercise.weight)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header with icon and exercise name
                VStack {
                    Text(exercise.exerciseName)
                        .font(.title)
                        .foregroundStyle(.secondary)
                    
                    // Current value display
                    Text("\(formattedValue) \(property.title.lowercased())")
                        .font(.system(size: 72))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: value)
                }
                
                Spacer()
                
                // Slider
                VStack(spacing: 4) {
                    // Custom slider track with filled portion
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 999)
                            .fill(.tertiary)
                            .frame(height: isSliderActive ? 48 : 36)
                            .animation(.spring(duration: 0.2), value: isSliderActive)
                        
                        // Filled portion
                        RoundedRectangle(cornerRadius: 999)
                            .fill(.secondary)
                            .frame(width: sliderWidth, height: isSliderActive ? 44 : 32)
                            .padding(.leading, 2) // Adjust for proper alignment
                            .animation(.spring(duration: 0.2), value: isSliderActive)
                    }
                    .frame(maxWidth: .infinity) // Ensure the ZStack takes full width
                    .overlay(
                        // Thumb
                        Circle()
                            .fill(Color.primary)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .frame(width: isSliderActive ? 40 : 28, height: isSliderActive ? 40 : 28)
                            .position(x: sliderThumbPosition, y: isSliderActive ? 24 : 18) // Position at center of track height
                            .animation(.spring(duration: 0.2), value: isSliderActive)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        if !isSliderActive {
                                            isSliderActive = true
                                            hapticFeedback.prepare() // Prepare haptic for better responsiveness
                                        }
                                        updateValueFromDrag(gesture: gesture)
                                    }
                                    .onEnded { _ in
                                        isSliderActive = false
                                    }
                            )
                    )
                    
                    // Min and max labels with current value
                    HStack {
                        Text(formatNumber(property.range.lowerBound))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(formatNumber(property.range.upperBound))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Spacer()
                
                // Save button
                Button(action: saveChanges) {
                    Label("Update \(property.label.lowercased())", systemImage: property.icon)
                }
                .buttonStyle(.primaryPill)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.circle)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private var formattedValue: String {
        formatNumber(value)
    }
    
    private func formatNumber(_ number: Double) -> String {
        return property.formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func saveChanges() {
        viewContext.perform {
            if self.property == .reps {
                self.exercise.repsPerSet = Int16(self.value)
            } else {
                self.exercise.weight = self.value
            }
            
            do {
                try self.viewContext.save()
                DispatchQueue.main.async {
                    self.dismiss()
                }
            } catch {
                print("Error saving changes: \(error)")
            }
        }
    }
    
    private var sliderWidth: CGFloat {
        sliderThumbPosition + (isSliderActive ? 20 : 14)
    }
    
    private var sliderThumbPosition: CGFloat {
        // Get the total available width for the slider
        let totalWidth = UIScreen.main.bounds.width - 48
        
        // Calculate the normalized value (0 to 1)
        let range = property.range.upperBound - property.range.lowerBound
        let normalizedValue = (value - property.range.lowerBound) / range
        
        // Calculate the position of the thumb
        let thumbRadius = isSliderActive ? 20.0 : 14.0 // Half of thumb width
        
        // Calculate the minimum and maximum positions for the thumb center
        // At minimum value, the thumb center should be at thumbRadius
        // At maximum value, the thumb center should be at (totalWidth - thumbRadius)
        let minPosition = thumbRadius + 4
        let maxPosition = totalWidth - minPosition - 4 - (thumbRadius * 2)
        
        // Calculate the position, ensuring it stays within bounds
        let position = minPosition + (maxPosition - minPosition) * CGFloat(normalizedValue)
        
        // Add extra safety check to ensure the thumb stays within the track
        return min(maxPosition, max(minPosition, position))
    }
    
    private func updateValueFromDrag(gesture: DragGesture.Value) {
        // Get the total available width for the slider
        let totalWidth = UIScreen.main.bounds.width - 48
        
        // Get the thumb radius
        let thumbRadius = isSliderActive ? 20.0 : 14.0
        
        // Calculate the effective track width (accounting for thumb radius on both ends)
        let effectiveTrackWidth = totalWidth - (thumbRadius * 2)
        
        // Adjust the drag location to account for the thumb radius
        let adjustedLocation = gesture.location.x - thumbRadius
        
        // Constrain the adjusted location to the effective track width
        let constrainedLocation = max(0, min(effectiveTrackWidth, adjustedLocation))
        
        // Calculate normalized position (0 to 1)
        let normalizedPosition = constrainedLocation / effectiveTrackWidth
        
        // Convert to value in range
        let range = property.range.upperBound - property.range.lowerBound
        let newValue = property.range.lowerBound + (range * Double(normalizedPosition))
        
        // Round to nearest step
        let steps = round(newValue / property.step)
        let steppedValue = steps * property.step
        
        // Check if we've moved to a new stepped value
        if steppedValue != lastSteppedValue {
            // Trigger haptic feedback
            hapticFeedback.impactOccurred()
            lastSteppedValue = steppedValue
        }
        
        value = steppedValue
        
        // Ensure value stays within bounds
        value = max(property.range.lowerBound, min(property.range.upperBound, value))
    }
    
    private func incrementValue() {
        let newValue = value + property.step
        if newValue <= property.range.upperBound {
            // Trigger haptic feedback
            hapticFeedback.impactOccurred()
            value = newValue
            lastSteppedValue = newValue
        }
    }
    
    private func decrementValue() {
        let newValue = value - property.step
        if newValue >= property.range.lowerBound {
            // Trigger haptic feedback
            hapticFeedback.impactOccurred()
            value = newValue
            lastSteppedValue = newValue
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let exercise = Exercise(context: context)
    exercise.id = UUID()
    exercise.name = "Bench Press"
    exercise.repsPerSet = 12
    exercise.weight = 60
    
    return ExercisePropertyEditor(exercise: exercise, property: .reps)
        .environment(\.managedObjectContext, context)
} 
