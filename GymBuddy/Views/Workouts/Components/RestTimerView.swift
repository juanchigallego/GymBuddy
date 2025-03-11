import SwiftUI

struct RestTimerView: View {
     @Binding var isPresented: Bool
     let seconds: Int16
     let onComplete: () -> Void
     @State private var timeRemaining: Int16
     @State private var timer: Timer?
     let nextBlock: Block
     
     init(isPresented: Binding<Bool>, seconds: Int16, nextBlock: Block, onComplete: @escaping () -> Void) {
         self._isPresented = isPresented
         self.seconds = seconds
         self.nextBlock = nextBlock
         self.onComplete = onComplete
         self._timeRemaining = State(initialValue: seconds)
     }
     
     var body: some View {
         NavigationStack {
             ZStack {
                 Color(.systemBackground)
                     .ignoresSafeArea()
                 
                 VStack(spacing: 0) {
                     ScrollView {
                         VStack(spacing: 32) {
                             Text("Rest Time")
                                 .font(.title)
                                 .bold()
                             
                             VStack(spacing: 8) {
                                 Text(formatTime(seconds: timeRemaining))
                                     .font(.system(size: 64, weight: .bold, design: .rounded))
                                     .monospacedDigit()
                                 
                                 Text("remaining")
                                     .font(.subheadline)
                                     .foregroundColor(.secondary)
                             }
                             
                             // Next block preview
                             VStack(spacing: 16) {
                                 Text("Get Ready For")
                                     .font(.headline)
                                     .foregroundColor(.secondary)
                                 
                                 VStack(spacing: 8) {
                                     HStack {
                                         Text(nextBlock.blockName)
                                             .font(.title3)
                                             .bold()
                                         
                                         Text("•")
                                             .foregroundColor(.secondary)
                                         
                                         Text("\(nextBlock.sets) sets")
                                             .foregroundColor(.blue)
                                     }
                                     
                                     VStack(spacing: 4) {
                                         ForEach(nextBlock.exerciseArray) { exercise in
                                             HStack {
                                                 Text(exercise.exerciseName)
                                                 Spacer()
                                                 Text("\(exercise.repsPerSet) reps @ \(String(format: "%.1f", exercise.weight))kg")
                                                     .foregroundColor(.secondary)
                                             }
                                             .font(.subheadline)
                                         }
                                     }
                                     .padding()
                                     .background(Color(.secondarySystemBackground))
                                     .cornerRadius(10)
                                 }
                             }
                         }
                         .padding(.vertical, 24)
                     }
                     
                     // Fixed bottom button
                     VStack {
                         Button(action: {
                             timer?.invalidate()
                             isPresented = false
                             onComplete()
                         }) {
                             Label("Skip Rest", systemImage: "forward.fill")
                                 .frame(maxWidth: .infinity)
                                 .padding()
                                 .background(Color.blue)
                                 .foregroundColor(.white)
                                 .cornerRadius(10)
                         }
                     }
                     .padding()
                     .background(Color(.systemBackground))
                     .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                 }
             }
             .navigationBarTitleDisplayMode(.inline)
         }
         .onAppear {
             timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                 if timeRemaining > 0 {
                     timeRemaining -= 1
                 } else {
                     timer?.invalidate()
                     isPresented = false
                     onComplete()
                 }
             }
         }
         .onDisappear {
             timer?.invalidate()
         }
     }
     
     private func formatTime(seconds: Int16) -> String {
         let minutes = seconds / 60
         let remainingSeconds = seconds % 60
         return String(format: "%d:%02d", minutes, remainingSeconds)
     }
 }
