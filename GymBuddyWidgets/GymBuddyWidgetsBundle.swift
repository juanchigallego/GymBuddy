//
//  GymBuddyWidgetsBundle.swift
//  GymBuddyWidgets
//
//  Created by Juanchi Gallego on 26/02/2025.
//

import WidgetKit
import SwiftUI

@main
struct GymBuddyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            WorkoutLiveActivity()
        }
    }
}
