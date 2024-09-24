import SwiftUI

//struct RecordingAnimationView: View {
//    @State private var isAnimating = false
//    var audioLevel: Float
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(lineWidth: 4)
//                .scaleEffect(isAnimating ? CGFloat(1.0 + audioLevel/100) : 1.0)  // Aumenta de acordo com o nível de áudio
//                .opacity(isAnimating ? 0.1 : 1.0)
//                .frame(width: 150, height: 150)
//                .animation(isAnimating ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isAnimating)
//
//            Image(systemName: "mic.fill")
//                .resizable()
//                .frame(width: 50, height: 50)
//                .foregroundColor(.red)
//        }
//        .onAppear {
//            isAnimating = true
//        }
//        .onDisappear {
//            isAnimating = false
//        }
//    }
//}

struct RecordingAnimationView: View {
    var audioLevel: Float // Valor entre 0.0 e 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                WaveformBar(index: index, audioLevel: CGFloat(audioLevel))
            }
        }
        .frame(height: 100)
        // Remove animação global daqui e adicione-a nas barras individuais.
    }
}

struct WaveformBar: View {
    let index: Int
    var audioLevel: CGFloat
    
    var body: some View {
        let maxHeight: CGFloat = 100
        let minHeight: CGFloat = 10
        let barHeight = max(minHeight, maxHeight * audioLevel * CGFloat.random(in: 0.5...1.0))
        
        return Capsule()
            .fill(Color.blue)
            .frame(width: 5, height: barHeight)
            .animation(.easeInOut(duration: 0.2), value: barHeight) // Anima cada barra individualmente com base no valor.
    }
}
