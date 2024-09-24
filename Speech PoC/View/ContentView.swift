import SwiftUI
import Speech

class ContentViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcription = "Pressione o botao e comece a falar"
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
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
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        transcription = "gravacao interrompida."
    }
    
    func updateTranscription(_ newTranscription: String) {
        self.transcription = newTranscription
    }
}

struct ContentView: View {
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var audioViewModel = AudioViewModel()
    
    var body: some View {
        VStack {
            Text(contentViewModel.transcription)
                .padding()
                .multilineTextAlignment(.center)
            
            RecordingAnimationView(audioLevel: audioViewModel.audioLevel)
                .padding()
            
            Button(action: {
                contentViewModel.isRecording.toggle()
                if contentViewModel.isRecording {
                    audioViewModel.startRecording()
                } else {
                    audioViewModel.stopRecording()
                }
            }) {
                Text(contentViewModel.isRecording ? "Parar Gravação" : "Começar Gravação")
                    .font(.headline)
                    .padding()
                    .background(contentViewModel.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            contentViewModel.requestAuthorization()
            audioViewModel.requestAuthorization()
        }
        .onChange(of: audioViewModel.transcription) {
            contentViewModel.updateTranscription(audioViewModel.transcription)
        }
    }
}
