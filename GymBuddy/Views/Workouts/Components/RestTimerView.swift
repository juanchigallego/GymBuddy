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
                
                VStack(spacing: 32) {
                    Text("Rest Time")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("\(timeRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    VStack(spacing: 8) {
                        Text("Next Block:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(nextBlock.blockName)
                            .font(.title2)
                            .bold()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        timer?.invalidate()
                        timer = nil
                        isPresented = false
                        onComplete()
                    }
                }
            }
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timer?.invalidate()
                        timer = nil
                        isPresented = false
                        onComplete()
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
} 