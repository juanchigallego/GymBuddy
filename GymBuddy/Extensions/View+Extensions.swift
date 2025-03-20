import SwiftUI

extension View {
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.Layout.cornerRadius)
            .standardShadow()
    }
    
    func primaryButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Constants.Colors.primary)
            .cornerRadius(Constants.Layout.cornerRadius)
            .standardShadow()
    }
    
    func secondaryButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(Constants.Colors.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(Constants.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                    .stroke(Constants.Colors.primary, lineWidth: 2)
            )
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
} 