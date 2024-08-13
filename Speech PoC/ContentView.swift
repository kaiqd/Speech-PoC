import SwiftUI
import Speech

class ContentViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcription = "Pressione o botao e comece a falar"
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Request permission to use Speech and Microphone
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Autorizado.")
            case .denied, .restricted, .notDetermined:
                print("Reconhecimento de fala nao foi autorizado.")
            @unknown default:
                fatalError("Status de autorizacao inesperado.")
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Acesso ao microfone negado.")
            }
        }
    }
    
    // Start recording and recognizing speech
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        guard let request = request else { return }
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcription = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                self?.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            transcription = "Ouvindo..."
        } catch {
            print("Mecanismo de audio nao pode ser iniciado: \(error.localizedDescription)")
        }
    }
    
    // Stop recording
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        transcription = "gravacao interrompida."
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.transcription)
                .padding()
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.isRecording.toggle()
                if viewModel.isRecording {
                    viewModel.startRecording()
                } else {
                    viewModel.stopRecording()
                }
            }) {
                Image(systemName: viewModel.isRecording ? "mic.fill" : "mic.slash.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}

//#Preview {
//    ContentView()
//}
