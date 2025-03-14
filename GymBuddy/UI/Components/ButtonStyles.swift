//
//  ButtonStyles.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 13/03/2025
//

import SwiftUI

/// A circular button style with a subtle background and press animation
public struct CircleButtonStyle: ButtonStyle {
    public init() {} // Add explicit initializer to make it easier to use
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
            .frame(width: 30, height: 30)
    }
}

public struct LabelButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
    }
}

public extension ButtonStyle where Self == CircleButtonStyle {
    static var circle: CircleButtonStyle { CircleButtonStyle() }
}
public extension ButtonStyle where Self == LabelButtonStyle {
    static var label: LabelButtonStyle { LabelButtonStyle() }
}
