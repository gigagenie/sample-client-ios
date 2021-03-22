/*
 * Copyright 2021 KT AI Lab.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import UIKit
import InsideSDK
import SafariServices
import MediaPlayer

class ViewController: UIViewController, InsideSDKDelegate, AVAudioPlayerDelegate, AudioControllerDelegate {
    let tag = "SAMPLE APP : "

    //gplug 2.0 사용설정
    let clientId = "YOUR-CLIENT-ID"
    let clientKey = "YOUR-CLIENT-KEY"
    let clientSecret = "YOUR-CLIENT-SECRET"
    let userId = (UIDevice.current.identifierForVendor?.uuidString)!
    var uuid: String? = nil
    
    var curPlayer: Any?
    var player: [AVAudioPlayer?] = [AVAudioPlayer?](repeating: nil, count:1000)
    var m3u8player: [AVPlayer?] = [AVPlayer?](repeating: nil, count:1000)
    let audioSession = AVAudioSession.sharedInstance()
    var curChannel = 0
    var prevChannel = -1 // not use now
    var curVolume: Float = 0.0
    var prevAct = ""
    var isRadio = false
    var radioCh = -1
    
    var insideSDK: InsideSDK? = nil
    @IBOutlet weak var tvLogText: UITextView!
    @IBOutlet weak var tfSendText: UITextField!
    var test = false
    let notificationCenter = NotificationCenter.default
    
    // for timer
    var dicTimer: [String: Timer] = [:]
    
    // Utterance Wave for STT
    var ktWaveView: SCSiriWaveformView?
    
    var serverAddr = "inside-dev.gigagenie.ai"
    var serverGrpcPort = "50109"
    var serverRestPort = "30109"
    
    var locationLng = "127.029000"
    var locationLat = "37.4713370"
    var locationAddr = "서울특별시 서초구 태봉로"
    var ReqVOTXLang = "kr" // now support kr, en. if not set, default is kr.
        
    var infoType = -1
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoViewLabel1: UILabel!
    @IBOutlet weak var infoViewLabel2: UILabel!
    @IBOutlet weak var infoViewLabel3: UILabel!
    @IBOutlet weak var infoViewTextField1: UITextField!
    @IBOutlet weak var infoViewTextField2: UITextField!
    @IBOutlet weak var infoViewTextField3: UITextField!
    
    @IBOutlet weak var kwsSetKeywordBtn1: UIButton!
    @IBOutlet weak var kwsSetKeywordBtn2: UIButton!
    @IBOutlet weak var kwsSetKeywordBtn3: UIButton!
    @IBOutlet weak var kwsSetKeywordBtn4: UIButton!
    
    var arrWord = ["지니뮤직 틀어줘", "지니뮤직 종료해줘", "라디오 틀어줘", "라디오 종료해줘", "가산동 날씨 가르쳐줘", "5초 타이머 설정해줘", "볼륨 크게 해줘", "볼륨 작게 해줘"]
    var arrWordIdx = 0
    
    var slider: UISlider?
    
    var bKwsInit = false
    var kwsKeyword = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        insideSDK = InsideSDK()
        insideSDK?.delegate = self
        writeLog("agent_getVersion", str: "\(insideSDK?.agent_getVersion())")
        
//        insideSDK?.agent_setServerInfo(serverAddr, serverGrpcPort, serverRestPort)
//        writeLog("agent_setServerInfo", str: "\(serverAddr), \(serverGrpcPort), \(serverRestPort)")
        
        tfSendText.text = arrWord[arrWordIdx]
        
        // volume change event 수신하기 위해 추가
        UIApplication.shared.beginReceivingRemoteControlEvents()
        setAudioSession()
        setVolumeViewSlider()
        
        // 저장된 UUID 가 있다면 agent_register 를 실행하지 않기 위해 값을 세팅한다.
        if let _uuid = UserDefaults.standard.value(forKey: "InsideSDKUUID") {
            uuid = _uuid as! String
        }
        
        if test {
            self.onClickAgentRegister()
        }
    }

    @IBAction func onClickAgentRegister() {
        if uuid != nil {
            writeLog("agent_register", str: "UUID already registerd. uuid : \(uuid)")
            writeLog("agent_register", str: "if want remove UUID, try call agent_unregister")
            
            if test {
                self.onClickAgentInit()
            }
        } else {
            if let ret = insideSDK?.agent_register(clientId, clientKey, clientSecret, userId) {
                writeLog("agent_register", ret)
                if let rc = ret["rc"] as? Int {
                    if rc == 200 {
                        uuid = ret["uuid"] as? String
                        if let uuid = ret["uuid"] as? String {
                            self.uuid = uuid
                            
                            // store uuid
                            UserDefaults.standard.setValue(uuid, forKey: "InsideSDKUUID")
                            
                            writeLog("agent_register", str: "success!")
                            
                            if test {
                                self.onClickAgentInit()
                            }
                        }
                    } else {
                        writeLog("agent_register", str: "fail! check rcmsg")
                    }
                } else {
                    writeLog("agent_register", str: "fail! rc is null. check result.")
                }
            }
        }
    }
    
    @IBAction func onClickAgentInit() {
        if let uuid = self.uuid {
            if let ret = insideSDK?.agent_init(clientId, clientKey, clientSecret, uuid) {
                writeLog("agent_init", ret)

                if let rc = ret["rc"] as? Int {
                    if rc == 200 {
                        writeLog("agent_init", str: "success!")
                        insideSDK?.agent_setLocation(locationLng, locationLat, locationAddr)
                    } else {
                        writeLog("agent_init", str: "fail! check rcmsg")
                    }
                } else {
                    writeLog("agent_init", str: "fail! rc is null. check result.")
                }
            }
        } else {
            writeLog("agent_init", str: "fail! uuid is not registed!")
        }
    }
    @IBAction func onClickAgentUnregister() {
        if uuid != nil {
            if let ret = insideSDK?.agent_unregister() {
                insideSDK?.kws_reset()
                writeLog("agent_unregister", ret)
                
                // remove UUID
                UserDefaults.standard.removeObject(forKey: "InsideSDKUUID")
                uuid = nil
            } else {
                writeLog("agent_unregister", str: "fail! maybe not initialized!")
            }
        } else {
            writeLog("agent_unregister", str: "fail! uuid is not registed!")
        }
    }
    
    @IBAction func onClickAgentStartVoice() {
        self.micOff()
        insideSDK?.agent_startVoice()
    }
    @IBAction func onClickAgentStartVoiceToText() {
        self.micOff()
        insideSDK?.agent_startVoiceToText()
    }
    
    @IBAction func onClickAgentStopVoice() {
        insideSDK?.agent_stopVoice()
        self.showUtteranceWave(false, true)
        self.micOffAndCheckKws()
    }
    
    @IBAction func onClickAgentSendText() {
        if let text = tfSendText.text {
            self.micOffAndCheckKws()
            insideSDK?.agent_sendText(text)
        }
    }
    @IBAction func onClickAgentGetTTS() {
        if let text = tfSendText.text {
            self.micOffAndCheckKws()
            if let ret = insideSDK?.agent_getTTS(text) {
                if let rc = ret["rc"] as? Int {
                    if rc == 200 {
                        curChannel = 0
                        self.playSound(ret["rcmsg"] as! Data)
                    } else {
                        writeLog("agent_getTTS", ret)
                        print("\(tag)onClickAgentGetTTS fail! check rcmsg!")
                    }
                } else {
                    print("\(tag)agent_getTTS fail! check rcmsg!")
                }
            } else {
                writeLog("agent_getTTS", str: "fail! maybe not initialized!")
            }
        }
    }
    
    @IBAction func onClickAgentServiceLogin() {
        if let ret = insideSDK?.agent_serviceLogin("geniemusic", nil) {
            writeLog("agent_serviceLogin", ret)
            if let rc = ret["rc"] as? Int {
                if rc == 200 {
                    if let url = ret["oauth_url"] as? String {
                        startWebView(strUrl: url)
                    } else {
                        print("\(tag)agent_serviceLogin fail! check oauth_url!")
                    }
                } else {
                    print("\(tag)agent_serviceLogin fail! check rcmsg!")
                }
            } else {
                print("\(tag)agent_serviceLogin fail! system error!")
            }
        } else {
            writeLog("agent_serviceLogin", str: "fail! maybe not initialized!")
        }
    }
    
    @IBAction func onClickAgentServiceLogout() {
        if let ret = insideSDK?.agent_serviceLogout("geniemusic") {
            writeLog("agent_serviceLogout", ret)
        } else {
            writeLog("agent_serviceLogout", str: "fail! maybe not initialized!")
        }
    }
    @IBAction func onClickAgentServiceStatus() {
        if let ret = insideSDK?.agent_serviceLoginStatus("geniemusic") {
            writeLog("agent_serviceStatus", ret)
        } else {
            writeLog("agent_serviceStatus", str: "fail! maybe not initialized!")
        }
    }

    func micOn(_ type:Int = 0) {
        micOff()
        AudioController.sharedInstance()?.delegate = self
        AudioController.sharedInstance()?.prepare(withSampleRate: 16000.0)
        AudioController.sharedInstance()?.start(Int32(type))
    }
    func micOff() {
        AudioController.sharedInstance()?.stop()
    }
    func micOffAndCheckKws() {
        self.micOff()
        if self.bKwsInit {
            self.micOn(1)
        }
    }
    
    func sendVoice(_ data: Data!) {
        insideSDK?.agent_sendVoice(data)
    }
    
    func sendVoice(forKws data: Data!) {
        var d = data;
        d?.withUnsafeMutableBytes({ (bytes: UnsafeMutablePointer<Int16>) -> Void in
                         //Use `bytes` inside this closure
            let status = insideSDK?.kws_detect(bytes, Int32(data.count/2))
            if(status == 4) {
                // 키워드 인식 성공
                insideSDK?.kws_init(Int32(kwsKeyword))
                onClickAgentStartVoice()
            }
        })
    }
    
    func agent_onCommand(_ actionType: String, _ payload: [AnyHashable : Any]) {
        if actionType == "media_data" {
            writeLog("SampleApp agent_onCommand called : actionType:media_data", nil)
            print("SampleApp agent_onCommand called actionType:\(actionType)")
        } else {
            writeLog("SampleApp agent_onCommand called actionType: \(actionType)", payload)
            print("SampleApp agent_onCommand called actionType:\(actionType) payload:\(self.koLog(payload.description))")
        }
        switch actionType {
            case "start_voice":
                DispatchQueue.main.async(execute: {
                    self.micOn(0)
                    self.showUtteranceWave(true, true)
                })
            case "stop_voice":
                DispatchQueue.main.async(execute: {
                    self.showUtteranceWave(false, true)
                    self.micOffAndCheckKws()
                })
            case "media_data":
                self.playSound(payload["voice"] as! Data)
            case "play_media":
                print("play_media....")
                if let cmdOpt = payload["cmdOpt"] as? [AnyHashable : Any] {
                    if let channel = cmdOpt["channel"] as? Int, let actOnOther = cmdOpt["actOnOther"] as? String {
                        // actOnOther 값이 다음과 같다면, 일단 현재 채널을 actOnOther 에 맞게 처리해준다.
                        if actOnOther == "pause" || actOnOther == "pauseR" || actOnOther == "stop" {
                            controlPlayer(actOnOther, channel)
                        }
                        
                        curChannel = channel
                        if curChannel == 10 {
                            // 타이머는 분기 처리 필요
                            // 아래는 타이머 효과음 처리를 생략하고 agent_updateMediatatus 만 임의로 호출하는 예제
                            writeLog("TimerEvent", nil)
                            updateMediaStatus(Int32(curChannel), "start", 0)
                            
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                                self.updateMediaStatus(10, "complete", 1000)
                            })
                        } else {
                            if let url = cmdOpt["url"] {
                                playSound(url: url as! String)
                            }
                        }
                    }
                }
            case "control_media":
                if let cmdOpt = payload["cmdOpt"] as? [AnyHashable : Any] {
                    if let act = cmdOpt["act"] as? String, let channel = cmdOpt["channel"] as? Int {
                        print("InsideSDKSample control_media \(act) \(channel)")
                        controlPlayer(act, channel, true, cmdOpt["playTime"] as? Double ?? -1)
                    }
                }
            case "control_hardware":
                if let cmdOpt = payload["cmdOpt"] as? [AnyHashable : Any] {
                    if let hwCmd = cmdOpt["hwCmd"] as? String {
                        if hwCmd == "setVolume" {
                            if let hwCmdOpt = cmdOpt["hwCmdOpt"] as? [AnyHashable : Any] {
                                if let control = hwCmdOpt["control"] as? String,
                                   let value = hwCmdOpt["value"] as? String {
                                    var volume = AVAudioSession.sharedInstance().outputVolume
                                    print("\(tag) onCommand control_hardware called curVolume : \(volume)")
                                    if control == "UP" {
                                        volume = volume + (value == "LE" ? 0.1 : value == "GN" ? 0.2 : 0.3)
                                    } else if control == "DN" {
                                        volume = volume - (value == "LE" ? 0.1 : value == "GN" ? 0.2 : 0.3)
                                    } else {
                                        print("\(tag) onCommand control_hardware called control : \(control)")
                                    }
                                    volume = volume > 1.0 ? 1.0 : volume < 0.0 ? 0.0 : volume
                                    volume = floor(volume * 10) / 10
                                    setVolume(volume)
                                }
                            }
                        }
                    }
                }
            case "webview_url":
                print("webview_url....")
                if let cmdOpt = payload["cmdOpt"] as? [AnyHashable : Any] {
                    if let oauth_url = cmdOpt["oauth_url"] {
                        startWebView(strUrl: oauth_url as? String)
                    }
                }
            case "set_timer":
                if let cmdOpt = payload["cmdOpt"] as? [AnyHashable : Any] {
                    if let setOpt = cmdOpt["setOpt"] as? String, let actionTrx = cmdOpt["actionTrx"] as? String, let setTime = cmdOpt["setTime"] as? String, let reqAct = cmdOpt["reqAct"] as? String {
                        if setOpt == "set" {
                            // clear timer
                            timerClear(actionTrx)
                            // timer setting
                            if let time = Double(setTime) {
                                dicTimer[actionTrx] = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(timerCallback), userInfo: [actionTrx, reqAct], repeats: false)
                            }
                        } else if setOpt == "clear" {
                            timerClear(actionTrx)
                        }
                    }
                }
            default:
                print("agent_onCommand default : \(actionType)")
        }
    }
    
    func agent_onEvent(_ evt: Int32, _ opt: [AnyHashable : Any]?) {
        switch evt {
            case GRPC_INIT_SUCCESS:
                print("GRPC_INIT_SUCCESS")
                writeLog("agent_onEvent GRPC_INIT_SUCCESS", opt)
            case GRPC_INIT_FAIL:
                print("GRPC_INIT_FAIL")
                writeLog("agent_onEvent GRPC_INIT_FAIL", opt)
                insideSDK?.kws_reset()
            case GRPC_DISCONNECTED:
                print("GRPC_DISCONNECTED")
                writeLog("agent_onEvent GRPC_DISCONNECTED", opt)
            case GO_TO_STANDBY:
                print("GO_TO_STANDBY")
                writeLog("agent_onEvent GO_TO_STANDBY", opt)
            case SET_CONFIG_SUCCESS:
                print("SET_CONFIG_SUCCESS")
                writeLog("agent_onEvent SET_CONFIG_SUCCESS", opt)
            case SET_CONFIG_FAIL:
                print("SET_CONFIG_FAIL")
                writeLog("agent_onEvent SET_CONFIG_FAIL", opt)
            case SERVER_ERROR:
                if let error = opt {
                    print("SERVER_ERROR \(error.description)")
                    writeLog("agent_onEvent SERVER_ERROR", opt)
                }
                DispatchQueue.main.async(execute: {
                    self.showUtteranceWave(false, true)
                    self.micOffAndCheckKws()
                })
            default:
                print("agent_onEvent default : \(evt)")
        }
    }
    
    func playSound(_ voice: Data) {
        releasePlayer()
        do {
            player[curChannel] = try AVAudioPlayer(data: voice)
            player[curChannel]?.delegate = self
            player[curChannel]?.prepareToPlay()
            
            let duration = (player[curChannel]?.duration)!
            if(duration > 0) {
                player[curChannel]?.play()
                curPlayer = player[curChannel]
                updateMediaStatus(Int32(curChannel), "started", 0)
            }
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    func playSound(url: String) {
        releasePlayer()
        if url.contains("m3u8") {
            //radio
            if let fileURL = URL(string: url) {
                m3u8player[curChannel] = AVPlayer(url: fileURL)
                m3u8player[curChannel]?.play()
                //isRadio = true
                radioCh = curChannel
                
                curPlayer = m3u8player[curChannel]
                updateMediaStatus(Int32(curChannel), "started", 0)
            }
        } else { //music or padcast, other media play
            do {
                let urlObj = URL(string: url)
                let data = try Data(contentsOf: urlObj!)
                
                player[curChannel] = try AVAudioPlayer(data: data)
                player[curChannel]?.delegate = self
                player[curChannel]?.prepareToPlay()
                player[curChannel]?.play()
                //isRadio = false
                if radioCh == curChannel {
                    radioCh = -1
                }
                
                curPlayer = player[curChannel]
                updateMediaStatus(Int32(curChannel), "started", 0)
            } catch let error as NSError {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    func releasePlayer() {
        if player[curChannel] != nil {
            player[curChannel]?.stop()
            player[curChannel] = nil
        }
    }
    @IBAction func onClickPlayPause() {
        if let str = makeSndHWEV(target: "button", hwEvent: "Btn_PU", hwEventValue: nil) {
            insideSDK?.agent_sendCommand(str)
        }
    }
    @IBAction func onClickPrev() {
        if let str = makeSndHWEV(target: "button", hwEvent: "Btn_PV", hwEventValue: nil) {
            insideSDK?.agent_sendCommand(str)
        }
    }
    @IBAction func onClickNext() {
        if let str = makeSndHWEV(target: "button", hwEvent: "Btn_NX", hwEventValue: nil) {
            insideSDK?.agent_sendCommand(str)
        }
    }
    @IBAction func onClickAgentSetConfig() {
        // 아래 값은 샘플이터 입니다. 아래 URL 참조
        // https://github.com/gigagenie/ginside-sdk/wiki/6.23-agent_setConfig
        var cmd = [String: Any]()
        cmd["cmdType"] = "Req_CONF"
        var payload = [String: Any]()
        var cmdOpt = [String: Any]()
        
        var sttOpt = [String: Any]()
        sttOpt["profile"] = "GGenieM"
        var devOpt = [String: Any]()
        devOpt["volume"] = 50
        var ttsOpt = [String: Any]()
        ttsOpt["receivingMethod"] = "directWavFile"
        
        cmdOpt["sttOpt"] = sttOpt
        cmdOpt["devOpt"] = devOpt
        cmdOpt["ttsOpt"] = ttsOpt

        payload["cmdOpt"] = cmdOpt;
        cmd["payload"] = payload
        
        if let str = dicToJsonString(cmd) {
            insideSDK?.agent_setConfig(str)
            writeLog("agent_setConfig", str: "called! \(cmd.description)")
        }
    }
    @IBAction func onClickAgentSetCustomVersion() {
        // 아래 값은 샘플임
        insideSDK?.agent_setCustomVersion("test", "0.1")
        writeLog("agent_setCustomVersion", str: "called! test, 0.1")
    }
    @IBAction func onClickAgentDebugMode() {
        insideSDK?.agent_debugmode()
    }
    @IBAction func onClickAgentSetServerInfo() {
        infoType = 1
        infoViewLabel1.text = "Addr"
        infoViewLabel2.text = "gRPC"
        infoViewLabel3.text = "Rest"
        infoViewTextField1.text = serverAddr
        infoViewTextField2.text = serverGrpcPort
        infoViewTextField3.text = serverRestPort
        infoView.isHidden = false
    }
    @IBAction func onClickAgentSetLocation() {
        infoType = 2
        infoViewLabel1.text = "Lng"
        infoViewLabel2.text = "Lat"
        infoViewLabel3.text = "Addr"
        infoViewTextField1.text = locationLng
        infoViewTextField2.text = locationLat
        infoViewTextField3.text = locationAddr
        infoView.isHidden = false
    }
    @IBAction func onClickClearLog() {
        tvLogText.text = ""
    }
    @IBAction func onClickKwsSetKeyword(_ sender: AnyObject?) {
        var kwsId = -1;
        if sender === kwsSetKeywordBtn1 {
            kwsId = 0
        } else if sender === kwsSetKeywordBtn2 {
            kwsId = 1
        } else if sender === kwsSetKeywordBtn3 {
            kwsId = 2
        } else if sender === kwsSetKeywordBtn4 {
            kwsId = 3
        }
        
        if(kwsId > -1) {
            if let ret = insideSDK?.kws_setKeyword(Int32(kwsId)) {
                
                if ret == 0 {
                    kwsKeyword = kwsId
                    writeLog("kwsSetKeyword", str: "호출어 변경에 성공하였습니다.")
                } else if ret == -1 {
                    writeLog("kwsSetKeyword", str: "호출어 변경에 실패하였습니다. 해당 호출어 파일이 존재하지 않습니다. kws_init 이 실행되지 않은 경우에도 이 에러가 발생합니다.")
                } else if ret == -2 {
                    writeLog("kwsSetKeyword", str: "호출어 변경에 실패하였습니다. agent_init 호출을 먼저 시도해주세요.")
                }
            }
        }
    }
    @IBAction func onClickKwsGetKeyword() {
        if let keyword = insideSDK?.kws_getKeyword() {
            var msg = ""
            if keyword == 0 { msg = "기가지니" }
            else if keyword == 1 { msg = "지니야" }
            else if keyword == 2 { msg = "친구야" }
            else if keyword == 3 { msg = "자기야" }
            else { msg = "please kws_init first!" }
            writeLog("kwsGetKeyword", str: "\(msg)")
        } else {
            writeLog("kwsGetKeyword", str: "kws_getKeyword nil.")
        }
    }
    @IBAction func onClickKwsInit() {
        let ret = insideSDK?.kws_init(Int32(kwsKeyword))
        if ret == 0 {
            micOn(1)
            bKwsInit = true
            writeLog("kwsInit", str: "success.")
        } else {
            writeLog("kwsInit", str: "fail. \(ret)")
        }
        
    }
    @IBAction func onClickKwsReset() {
        insideSDK?.kws_reset()
        micOff()
        writeLog("kwsReset", str: "called")
        bKwsInit = false
    }
    @IBAction func onClickKwsError() {
        let err = insideSDK?.kws_error()
        writeLog("kwsError", str: "called. not supported now.")
    }
    @IBAction func onClickKwsVersion() {
        if let version = insideSDK?.kws_getVersion() {
            writeLog("kwsVersion", str: version)
        }
    }
    @IBAction func onClickVolumeUp() {
        let volume = AVAudioSession.sharedInstance().outputVolume
        if let str = makeSndHWEV(target: "volume", hwEvent: "setVolume", hwEventValue: String(volume)) {
            insideSDK?.agent_sendCommand(str)
        }
    }
    @IBAction func onClickVolumeDown() {
        let volume = AVAudioSession.sharedInstance().outputVolume
        if let str = makeSndHWEV(target: "volume", hwEvent: "setVolume", hwEventValue: String(volume)) {
            insideSDK?.agent_sendCommand(str)
        }
    }
    // dictionary 를 JSON String 으로 형변환한다.
    func dicToJsonString(_ cmd: [String: Any]) -> String? {
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: cmd,
            options: []) {
            if let theJSONText = String(data: theJSONData, encoding: .ascii) {
                return theJSONText
            }
        }
        return nil
    }
    // Snd_HWEV 보내기 위해
    func makeSndHWEV(target: String, hwEvent: String, hwEventValue: String?) -> String? {
        var cmd = [String: Any]()
        cmd["cmdType"] = "Snd_HWEV"
        var payload = [String: Any]()
        var cmdOpt = [String: Any]()
        cmdOpt["target"] = target
        cmdOpt["hwEvent"] = hwEvent
        if hwEventValue != nil {
            var hwEventOpt = [String: Any]()
            hwEventOpt["value"] = hwEventValue
            cmdOpt["hwEventOpt"] = hwEventOpt
        }
        payload["cmdOpt"] = cmdOpt;
        cmd["payload"] = payload
        
        if let str = dicToJsonString(cmd) {
            return str
        }
        print("\(tag)makeSndHWEV fail...")
        return nil
    }
    func startWebView(strUrl: String!) {
        print("\(tag)start webView called...")
        if let url = URL(string: strUrl) {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)
        } else {
            print("\(tag)start webView Fail...")
        }
    }
    // onCommand actionType 값이 play_media, control_media 일 때 여기로 온다.
    func controlPlayer(_ act: String, _ channel: Int, _ isControlMedia: Bool = false, _ playTime: Double = 0) {
        checkPlayer(channel)
        var currentTime: Double = 0
        if curPlayer is AVAudioPlayer {
            curPlayer = player[channel]
            let p = (curPlayer as? AVAudioPlayer)
            currentTime = p?.currentTime ?? 0
            if act == "pause" {
                p?.pause()
            } else if act == "stop" {
                p?.stop()
            } else if act == "resume" {
                p?.play()
            } else if act == "seek" {
                if p != nil && playTime > 0 {
                    p!.pause()
                    p!.currentTime = currentTime + playTime
                    p!.play()
                }
            }
        } else {
            curPlayer = m3u8player[channel]
            let p = (curPlayer as? AVPlayer)
            currentTime = p == nil ? 0 : CMTimeGetSeconds(p!.currentTime())
            if act == "pause" || act == "stop" {
                p?.pause()
            } else if act == "resume" {
                p?.play()
            } else if act == "seek" {
                if p != nil && playTime > 0 {
                    let cmTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(p!.currentTime()) + playTime, preferredTimescale: p!.currentTime().timescale)
                    p!.pause()
                    p!.seek(to: cmTime)
                    p!.play()
                }
            }
        }
        
        // control_media 로 왔을 땐 다음 처리를 하고, updateMediaStatus 처리를 한다.
        if isControlMedia {
            let state: String = act == "pause" ? "paused" : (act == "stop" ? "stopped" : (act == "resume" ? "resumed" : ""))
            if state != "" {
                updateMediaStatus(Int32(channel), state, currentTime == 0 ? 0 : Int32(currentTime*1000))
            }
            if act == "resume" {
                curChannel = channel
            }
        }
    }
    // 재생해야 할 채널이 라디오인지 아닌지 체크한다.
    func checkPlayer(_ channel: Int) {
        if radioCh == channel {
            curPlayer = m3u8player[channel]
        } else {
            curPlayer = player[channel]
        }
    }
    /// MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let duration = player.duration
        updateMediaStatus(Int32(self.curChannel), "complete", Int32(duration*1000))
    }
    func updateMediaStatus(_ channel: Int32, _ state: String, _ duration: Int32) {
        writeLog("agent_updateMediaStatus", str: "channel : \(channel), state : \(state), duration : \(duration)")
        insideSDK?.agent_updateMediaStatus(channel, state, duration)
    }
    func setVolumeViewSlider() {
        let volumeView = MPVolumeView()
        slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    }
    // 서버에서 볼륨 조절을 내려주었을 때 볼륨을 조절한다.
    func setVolume(_ volume: Float) {
        if slider != nil {
            self.writeLog("control_hardware", str: "setVolume called. target volume : \(volume)")
            slider!.value = volume
        }
    }
    // 볼륨 버튼으로 조절하였을 때 해당 볼륨값을 서버로 전송한다.
    @objc func volumeDidChange(_ notification: NSNotification) {
        if let reason = notification.userInfo!["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
            if reason == "ExplicitVolumeChange" {
                if let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as? Float {
                    curVolume = volume
                    if let str = makeSndHWEV(target: "volume", hwEvent: "setVolume", hwEventValue: String(volume)) {
                        writeLog("agent_sendCommand", str: "volume changed. command : \(str.description)")
                        insideSDK?.agent_sendCommand(str)
                    }
                }
            }
        }
        
    }
    func timerClear(_ actionTrx: String) {
        if let timer = dicTimer[actionTrx] {
            timer.invalidate()
            dicTimer.removeValue(forKey: actionTrx)
        }
    }
    @objc func timerCallback(timer: Timer){
        if let strArr = timer.userInfo as? [String] {
            if strArr.count != 2 {
                return
            }
            let actionTrx = strArr[0]
            let reqAct = strArr[1]
            
            // clear timer
            timerClear(actionTrx)
            
            // sendEvent
            var cmd = [String: Any]()
            cmd["cmdType"] = "Snd_TMEV"
            var payload = [String: Any]()
            var cmdOpt = [String: Any]()
            cmdOpt["reqAct"] = reqAct
            cmdOpt["actionTrx"] = actionTrx
            cmdOpt["localTime"] = getTodayString()
            payload["cmdOpt"] = cmdOpt;
            cmd["payload"] = payload
            
            if let str = dicToJsonString(cmd) {
                insideSDK?.agent_sendCommand(str)
            }
        }
    }
    func showUtteranceWave(_ animated: Bool, _ startStopRecord: Bool) {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        if animated {
            if self.ktWaveView == nil {
                let frame = CGRect(x: 0, y: window.bounds.height * 4 / 5, width: window.bounds.width, height: window.bounds.height / 5)
                self.ktWaveView = SCSiriWaveformView(frame: frame)
                self.ktWaveView?.clipsToBounds = false
            }
            if self.ktWaveView?.superview == nil {
                window.addSubview(self.ktWaveView!)
                window.bringSubviewToFront(self.ktWaveView!)
            }
            if startStopRecord {
                AudioController.sharedInstance()?.startRecorder()
            }
        }
        else {
            if startStopRecord {
                AudioController.sharedInstance()?.stopRecorder()
            }
            if self.ktWaveView != nil {
                self.ktWaveView?.removeFromSuperview()
            }
        }
    }
    func sendRms(_ rmsdB: NSNumber!) {
        DispatchQueue.main.async(execute: {
            self.ktWaveView?.update(withLevel: CGFloat(truncating: rmsdB))
        })
    }
    // 현재 시간을 가져온다 yyyymmddhhmmss
    func getTodayString() -> String{
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss";
        return dateFormatter.string(from: date);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    @IBAction func onClickInfoViewConfirm() {
        if infoType == 1 {
            serverAddr = infoViewTextField1.text!
            serverGrpcPort = infoViewTextField2.text!
            serverRestPort = infoViewTextField3.text!
            writeLog("agent_setServerInfo", str: "success!")
        } else if infoType == 2 {
            locationLng = infoViewTextField1.text!
            locationLat = infoViewTextField2.text!
            locationAddr = infoViewTextField3.text!
            writeLog("agent_setLocation", str: "success!")
        }
        infoView.isHidden = true
    }
    @IBAction func onClickInfoViewClose() {
        infoView.isHidden = true
    }
    func writeLog(_ apiName: String!, _ log: [AnyHashable : Any]?) {
        DispatchQueue.main.async(execute: {
            if log == nil {
                self.tvLogText.text = self.tvLogText.text! + "\n" + apiName
            } else {
                let log = self.koLog(log!.description)
                self.tvLogText.text = self.tvLogText.text! + "\n" + apiName + " " + log
            }
            self.scrollToBottom()
        })
    }
    func writeLog(_ apiName: String!, str: String!) {
        DispatchQueue.main.async(execute: {
            self.tvLogText.text = self.tvLogText.text! + "\n" + apiName + " " + str
            self.scrollToBottom()
        })
    }
    func scrollToBottom() {
        let bottom = NSMakeRange(tvLogText.text.count - 1, 1)
        tvLogText.scrollRangeToVisible(bottom)
        tvLogText.isScrollEnabled = false
        tvLogText.isScrollEnabled = true
        
    }
    @IBAction func onChangeSendTextWord() {
        arrWordIdx = arrWordIdx == arrWord.count-1 ? 0 : arrWordIdx + 1
        tfSendText.text = arrWord[arrWordIdx]
    }
    func setAudioSession() {
        // audioSession
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP])
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError { print("error: \(error.localizedDescription)") }
    }
    override func viewWillAppear(_ animated: Bool) {
        notificationCenter.addObserver(self, selector: #selector(volumeDidChange(_:)), name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        setAudioSession()
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
    
    func koLog(_ string: String) -> String {
        let pattern = "\\\\U([a-z0-9]{4})"
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            debugPrint("\(error)")
            return ""
        }
        return replacingCharacters(with: string, regex: regex)
    }

    private func replacingCharacters(with string: String, regex: NSRegularExpression) -> String {
        let range = NSRange(location: 0, length: string.count)
        guard let firstMatch = regex.firstMatch(in: string, options: [], range: range) else {
            return string
        }
        let nsString = NSString(string: string)
        let substring = nsString.substring(with: firstMatch.range(at: 1))
        let unicodeValue = UInt32(substring, radix: 16)!
        guard let unicodeScalar = UnicodeScalar(unicodeValue) else {
            return string
        }
        let newString = nsString.replacingCharacters(in: firstMatch.range(at: 0), with: String(unicodeScalar))
        return replacingCharacters(with: newString, regex: regex)
    }
}
