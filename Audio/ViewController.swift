//
//  ViewController.swift
//  Audio
//
//  Created by Nam on 2024/07/03.
//

import UIKit
import AVFoundation // 오디오 재생 헤더 파일

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate { // 오디오 재생을 위한 델리게이트
    
    var audioPlayer: AVAudioPlayer! // 오디오 플레이어 인스턴스 변수
    var audioFile: URL! // 재생할 오디오 파일
    let MAX_VOLUME: Float = 10.0    // 최대 볼륨
    var progressTimer: Timer!   // 타이머를 위한 변수
    
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime) // 재생 타이머를 위한 상수
    let timeRecordSelector: Selector = #selector(ViewController.updatePlayTime) // 녹음 타이머를 위한 상수
        
    @IBOutlet var pvProgressPlay: UIProgressView!
    
    @IBOutlet var lblCurrentTime: UILabel!
    
    @IBOutlet var lblEndTime: UILabel!
    
    @IBOutlet var stateImgView: UIImageView!    // 이미지 뷰 아웃렛 변수
    var stateImgArr = [UIImage?]()
    var stateImgFile = ["play.png","pause.png","stop.png","record.png"]
    
    
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var slVolume: UISlider!
    
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!
    
    var audioRecorder: AVAudioRecorder!
    var isRecordMode = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        for i in 0 ... 3 {
            let image = UIImage(named: stateImgFile[i])
            stateImgArr.append(image)
        }
        selectAudioFile()
        if !isRecordMode {  // 녹음모드 아닐 때 재생모드 실행
            initPlay()
            btnRecord.isEnabled = false // 녹음 버튼 비활성화
            lblRecordTime.isEnabled = false
        } else {
            initRecord()    // 녹음모드일 때 녹음모드로 초기화
        }
    }
    
    // 녹음모드와 재생모드 때의 파일을 구분하기 위한 함수
    func selectAudioFile() {
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "DEMO", withExtension: "mp3")
        } else {    // 녹음모드일때 파일 생성
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
    }
    
    // 오디오 재생 초기화 함수
    func initPlay() {
        do{ // 오디오 파일이 없을 경우 오류처리를 대비해 do-try-catch문 사용
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay: \(error)")
        }
        
        slVolume.maximumValue = MAX_VOLUME  // 슬라이더 최대 볼륨 초기화
        slVolume.value = 1.0    // 슬라이더 볼륨 초기화
        pvProgressPlay.progress = 0 // 진행도 0으로 초기화
        
        audioPlayer.delegate = self // 델리게이트 self 설정
        audioPlayer.prepareToPlay() // prepare to play 설정
        audioPlayer.volume = slVolume.value // audioPlayer 볼륨을 슬라이더 볼륨으로 초기화
        
        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)    // 총 재생 시간
        lblCurrentTime.text = convertNSTimeInterval2String(0)   // 0을 대입해 00:00가 출력되게 함
        
        setPlayButtons(true, pause: false, stop: false)
        
    }
    
    // 녹음을 위한 초기화
    func initRecord() {
        let recordSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0] as [String: Any]
        
        do {    // 에러 발생시 중단
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self
        
        slVolume.value = 1.0    // 슬라이더 볼륨 초기화
        
        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)    // 총 재생 시간
        lblCurrentTime.text = convertNSTimeInterval2String(0)   // 0을 대입해 00:00가 출력되게 함
        
        setPlayButtons(false, pause: false, stop: false)    // 재생버튼도 false 처리
        
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error-setCaegory: \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive: \(error)")
        }
    }
    
    
    // Time Interval 값을 받아 문자열로 돌려보내는 함수
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String{
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) // time 을 60으로 나눈 나머지 값을 정수로 변환
        let strTime = String(format: "%02d:%02d", min, sec)     // 00:00 형태로 문자열로 변환
        return strTime
    }
    
    // 0.1초 단위로 함수 실행 -> 재생시간 표시
    @objc func updatePlayTime(){
        lblCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime) // 재싱시간 표시
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)   // 진행상황 바에 표시
    }
    
    // 버튼 제어 함수
    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool){
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
        stateImgView.image = stateImgArr[0] // 재생 이미지 띄우기
    }
    
    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
        stateImgView.image = stateImgArr[1] // 일시정지 이미지 띄우기

    }
    
    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0 // 처음부터 다시 재생이므로 0
        lblCurrentTime.text = convertNSTimeInterval2String(0)   // 재생시간도 0으로 초기화
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate()  // 타이머 무효화
        stateImgView.image = stateImgArr[2] // 정지 이미지 띄우기

    }
    
    // 슬라이더 볼륨 오디오에 대입
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
    }
    
    // 녹음모드 스위치
    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn {    // 스위치 on -> 녹음모드
            audioPlayer.stop()  // 재생을 멈춘다
            audioPlayer.currentTime = 0
            lblRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else {    // 스위치 off -> 재생모드
            isRecordMode = false    // 녹음 관련 인자 비활성화
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }
    
    // 녹음 버튼
    @IBAction func btnRecord(_ sender: UIButton) {
        if (sender as AnyObject).titleLabel!.text == "Record" { // record인 경우 녹음시작
            audioRecorder.record()
            (sender as AnyObject).setTitle("Stop", for: UIControl.State())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)   // 녹음할 때 타이머 작동
            stateImgView.image = stateImgArr[3] // 녹음중 이미지 띄우기

        } else {    // stop을 누르면 녹음 중단하고 play 버튼 활성화 , 재생모드 초기화
            audioRecorder.stop()
            (sender as AnyObject).setTitle("Record", for: UIControl.State())
            btnPlay.isEnabled = true
            initPlay()
            stateImgView.image = nil    // 녹음이 끝나면 화면을 비움
        }
    }
    
    @objc func updateRecordTime() {
        lblRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
    
}

