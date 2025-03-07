import SwiftUI

/// A reusable view for displaying muscle tags in a flowing layout
struct ExerciseMuscleTagsView: View {
    let muscles: [String]
    var tagColor: Color = .blue
    var fontSize: Font = .caption
    
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(muscles, id: \.self) { muscle in
                Text(muscle)
                    .font(fontSize)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tagColor.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
} 