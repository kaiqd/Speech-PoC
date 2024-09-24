import SwiftUI

struct RecordingAnimationView: View {
    @State private var isAnimating = false
    var audioLevel: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .scaleEffect(isAnimating ? CGFloat(1.0 + audioLevel/100) : 1.0)  // Aumenta de acordo com o nível de áudio
                .opacity(isAnimating ? 0.1 : 1.0)
                .frame(width: 150, height: 150)
                .animation(isAnimating ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isAnimating)

            Image(systemName: "mic.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}
