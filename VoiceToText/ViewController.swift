//
//  ViewController.swift
//  training
//
//  Created by stag on 20/02/19.
//  Copyright © 2019 stag. All rights reserved.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController {
    
    // MARK:- Outlets
    
    @IBOutlet weak var searchField: UITextField!
    
    
    // MARK:- Variables
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let btnVoice = UIButton(type: .system)

    // MARK:- View Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        self.setupButtonVoice()
    }
    
    
    // MARK:- Action Methods
    
    @objc func btnStartSpeechToText(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            self.startRecording()
            self.btnVoice.setImage(UIImage(named: "icVoiceStop"), for: .normal)
        case.ended:
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.searchField.isEnabled = false
            self.btnVoice.setImage(UIImage(named: "icVoice"), for: .normal)
            audioEngine.inputNode.removeTap(onBus: 0)
        default:
            break
        }
        
    }
    

    // MARK:- Custom Methods
    
    func setupButtonVoice() {
        btnVoice.setImage(UIImage(named: "icVoice"), for: .normal)
        btnVoice.frame = CGRect(x: 0, y: 0, width: CGFloat(30), height: CGFloat(30))
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(self.btnStartSpeechToText(_:)))
        btnVoice.addGestureRecognizer(tap)
        searchField.rightView = btnVoice
        searchField.rightViewMode = .always
    }
    
    func setupSpeech() {
        
        self.searchField.isEnabled = false
        self.speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("Usuário negou acesso ao speech recognition.")
                
            case .restricted:
                isButtonEnabled = false
                print("speech recognition esta restrito no device.")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition ainda não foi autorizado.")
            }
            
            OperationQueue.main.addOperation() {
                self.searchField.isEnabled = isButtonEnabled
            }
        }
    }
    
    //------------------------------------------------------------------------------
    
    func startRecording() {
        
        // Limpar todos os dados da sessão anterior e cancela a tarefa
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Criar instância da sessão de áudio para gravar a voz
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Erro ao definir propriedades audioSession.")
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Não foi possivel criar o objeto SFSpeechAudioBufferRecognitionRequest.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.searchField.text = result?.bestTranscription.formattedString
                print(result?.bestTranscription.formattedString)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.searchField.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        self.audioEngine.prepare()
        
        do {
            try self.audioEngine.start()
        } catch {
            print("Erro ao iniciar o audioEngine.")
        }
        
    }
}


// MARK:- Extension

extension ViewController: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.btnVoice.isEnabled = true
        } else {
            self.btnVoice.isEnabled = false
        }
    }
}
