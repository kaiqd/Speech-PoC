import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var viewModel = AudioViewModel()
    
    var body: some View {
        VStack {
            Spacer()
         
            Text(viewModel.transcription)
                .padding()
                .multilineTextAlignment(.center)
            
            Spacer()
            Button(action: {
                viewModel.isRecording.toggle()
                if viewModel.isRecording {
                    viewModel.startRecording()
                } else {
                    viewModel.stopRecording()
                    viewModel.saveTranscriptionToFile(text: viewModel.transcription)
                }
            }) {
                Image(systemName: viewModel.isRecording ? "mic.fill" : "mic.slash.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .padding()
            }
            .padding(.bottom, 40)
            
            Button(action: {
                if let savedText = viewModel.loadTranscriptionFromFile() {
                    viewModel.transcription = savedText
                }
            }) {
                Text("Carregar transcrição salva")
                    .padding()
            }
        }
        .padding()
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
