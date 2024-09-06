import SwiftUI
import Speech
import AVFoundation

class AudioViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcription = "Pressione o botão e comece a falar "
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Solicitando o acesso ao microfone
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Autorizado.")
            case .denied, .restricted, .notDetermined:
                print("Reconhecimento de fala não foi autorizado.")
            @unknown default:
                fatalError("Status de autorização inesperado.")
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Acesso ao microfone concedido.")
            } else {
                print("Acesso ao microfone negado.")
            }
        }
    }
    
    // Começar a gravar e reconhecer a fala
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
            print("Mecanismo de áudio não pode ser iniciado: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        transcription = "Gravação interrompida"
    }
    
    func saveTranscriptionToFile(text: String) {
        let fileName = "transcricao.txt"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    if let data = "\n\(text)".data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                } else {
                    try text.write(to: fileURL, atomically: true, encoding: .utf8)
                }
                print("Transcrição salva com sucesso!")
            } catch {
                print("Erro ao salvar a transcrição: \(error.localizedDescription)")
            }
        }
    }
    
    func loadTranscriptionFromFile() -> String? {
        let fileName = "transcricao.txt"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                let savedText = try String(contentsOf: fileURL, encoding: .utf8)
                return savedText
            } catch {
                print("Erro ao carregar a transcrição: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
}
