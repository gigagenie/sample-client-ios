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

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextView *tvLogText;
@property (nonatomic, weak) IBOutlet UITextField *tfSendText;

@property (nonatomic, weak) IBOutlet UIView *infoView;
@property (nonatomic, weak) IBOutlet UILabel *infoViewLabel1;
@property (nonatomic, weak) IBOutlet UILabel *infoViewLabel2;
@property (nonatomic, weak) IBOutlet UILabel *infoViewLabel3;
@property (nonatomic, weak) IBOutlet UITextField *infoViewTextField1;
@property (nonatomic, weak) IBOutlet UITextField *infoViewTextField2;
@property (nonatomic, weak) IBOutlet UITextField *infoViewTextField3;

@property (nonatomic, weak) IBOutlet UIButton *kwsSetKeywordBtn1;
@property (nonatomic, weak) IBOutlet UIButton *kwsSetKeywordBtn2;
@property (nonatomic, weak) IBOutlet UIButton *kwsSetKeywordBtn3;
@property (nonatomic, weak) IBOutlet UIButton *kwsSetKeywordBtn4;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    tag = @"SAMPLE APP : ";
    clientId = @"YOUR-CLIENT-ID";
    clientKey = @"YOUR-CLIENT-KEY";
    clientSecret = @"YOUR-CLIENT-SECRET";
    userId = nil;
    uuid = nil;

    curPlayer = nil;

    player = [[NSMutableArray alloc] init];
    m3u8player = [[NSMutableArray alloc] init];
    [self initPlayer];
    
    audioSession = AVAudioSession.sharedInstance;
    curChannel = 0;
    curVolume = 0.0;
    radioCh = -1;
    
    userId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    test = false;
    notificationCenter = NSNotificationCenter.defaultCenter;
    
    // for timer
    dicTimer = [[NSMutableDictionary alloc] init];//: [String: Timer] = [:]
    
    // Utterance Wave for STT
    ktWaveView = nil;
    
    serverAddr = @"inside-dev.gigagenie.ai";
    serverGrpcPort = @"50109";
    serverRestPort = @"30109";
    
    locationLng = @"127.029000";
    locationLat = @"37.4713370";
    locationAddr = @"서울특별시 서초구 태봉로";
    ReqVOTXLang = @"kr"; // now support kr, en. if not set, default is kr.
        
    arrWord = [[NSMutableArray alloc] initWithObjects:@"지니뮤직 틀어줘", @"지니뮤직 종료해줘", @"라디오 틀어줘", @"라디오 종료해줘", @"가산동 날씨 가르쳐줘", @"5초 타이머 설정해줘", @"볼륨 크게 해줘", @"볼륨 작게 해줘", nil];
    arrWordIdx = 0;
    infoType = -1;
    
    bKwsInit = false;
    kwsKeyword = 1;
    
    insideSDK = [[InsideSDK alloc] init];
    [insideSDK setDelegate:self];
    [self writeLog:@"agent_getVersion" :[NSString stringWithFormat: @"%@", [insideSDK agent_getVersion]]];
    
    [insideSDK agent_setServerInfo:serverAddr :serverGrpcPort :serverRestPort];
    [self writeLog:@"agent_setServerInfo" :[NSString stringWithFormat: @"%@, %@, %@", serverAddr, serverGrpcPort, serverRestPort]];
    
    _tfSendText.text = arrWord[0];
    
    // volume change event 수신하기 위해 추가
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self setAudioSession];
    [self setVolumeViewSlider];
    
    // 저장된 UUID 가 있다면 agent_register 를 실행하지 않기 위해 값을 세팅한다.
    NSString *_uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"InsideSDKUUID"];
    if(_uuid != nil) {
        uuid = _uuid;
    }
    
    if(test) {
        [self onClickAgentRegister];
    }
}

- (void) initPlayer {
    for (int i=0; i<1000; i++){
        [player addObject: [NSNull null]];
        [m3u8player addObject: [NSNull null]];
    }
}

- (IBAction) onClickAgentRegister {
    if([self isNull:insideSDK] == NO) {
        if(uuid != nil) {
            [self writeLog:@"agent_register" :[NSString stringWithFormat: @"UUID already registerd. uuid : %@", uuid]];
            [self writeLog:@"agent_register" :@"if want remove UUID, try call agent_unregister"];
            
            if(test) {
                [self onClickAgentInit];
            }
        } else {
            NSDictionary *ret = [insideSDK agent_register:clientId :clientKey :clientSecret :userId];
            if([self isNull:ret] == NO) {
                [self writeLogForDic:@"agent_register" :ret];
                int rc = [ret[@"rc"] intValue];
                if(rc == 200) {
                    uuid = ret[@"uuid"];
                    
                    // store uuid
                    [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:@"InsideSDKUUID"];
                    
                    [self writeLog:@"agent_register" :@"success!"];
                    if(test) {
                        [self onClickAgentInit];
                    }
                } else {
                    [self writeLog:@"agent_register" :@"fail! check rcmsg"];
                }
            } else {
                [self writeLog:@"agent_register" :@"fail! return null."];
            }
        }        
    } else {
        [self writeLog:@"agent_register" :@"fail! maybe not initialized!"];
    }
    
}
- (IBAction) onClickAgentInit {
    if([self isNull:insideSDK] == NO) {
        if([self isNull:uuid] == NO) {
            NSDictionary *ret = [insideSDK agent_init:clientId :clientKey :clientSecret :uuid];
            if([self isNull:ret] == NO) {
                [self writeLogForDic:@"agent_init" :ret];
                int rc = [ret[@"rc"] intValue];
                if(rc == 200) {
                    [self writeLog:@"agent_init" :@"success!"];
                    [insideSDK agent_setLocation:locationLng :locationLat :locationAddr];
                } else {
                    [self writeLog:@"agent_init" :@"fail! check rcmsg"];
                }
            } else {
                [self writeLog:@"agent_init" :@"fail! uuid is not registed!"];
            }
        } else {
            [self writeLog:@"agent_init" :@"fail! return null."];
        }
    } else {
        [self writeLog:@"agent_init" :@"fail! maybe not initialized!"];
    }
    
}
- (IBAction) onClickAgentUnregister {
    if([self isNull:insideSDK] == NO) {
        if([self isNull:uuid] == NO) {
            NSDictionary *ret = [insideSDK agent_register:clientId :clientKey :clientSecret :userId];
            if([self isNull:ret] == NO) {
                [insideSDK kws_reset];
                [self writeLogForDic:@"agent_unregister" :ret];
                
                // remove UUID
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"InsideSDKUUID"];
                uuid = nil;
            } else {
                [self writeLog:@"agent_unregister" :@"fail! return null."];
            }
        } else {
            [self writeLog:@"agent_unregister" :@"fail! uuid is not registed!"];
        }
    } else {
        [self writeLog:@"agent_unregister" :@"fail! maybe not initialized!"];
    }
}
- (IBAction) onClickAgentStartVoice {
    [self micOff];
    [insideSDK agent_startVoice];
}
- (IBAction) onClickAgentStartVoiceToText {
    [self micOff];
    [insideSDK agent_startVoiceToText];
}
- (IBAction) onClickAgentStopVoice {
    [insideSDK agent_stopVoice];
    [self showUtteranceWave:false :true];
    [self micOffAndCheckKws];
}
- (IBAction) onClickAgentSendText {
    NSString *text = _tfSendText.text;
    if([self isNull:text] == NO && text.length > 0) {
        [self micOffAndCheckKws];
        [insideSDK agent_sendText:text];
    }
}
- (IBAction) onClickAgentGetTTS {
    if([self isNull:insideSDK] == NO) {
        NSString *text = _tfSendText.text;
        if([self isNull:text] == NO && text.length > 0) {
            [self micOffAndCheckKws];
            NSDictionary *ret = [insideSDK agent_getTTS:text];
            if([self isNull:ret] == NO) {
                int rc = [ret[@"rc"] intValue];
                if(rc == 200) {
                    curChannel = 0;
                    [self playSoundForTTS:ret[@"rcmsg"]];
                } else {
                    [self writeLogForDic:@"agent_getTTS" :ret];
                }
            } else {
                [self writeLog:@"agent_getTTS" :@"fail! return null."];
            }
        }
    } else {
        [self writeLog:@"agent_getTTS" :@"fail! maybe not initialized!"];
    }
}
- (IBAction) onClickAgentServiceLogin {
    if([self isNull:insideSDK] == NO) {
        NSDictionary *ret = [insideSDK agent_serviceLogin:@"geniemusic" :nil];
        if([self isNull:ret] == NO) {
            int rc = [ret[@"rc"] intValue];
            if(rc == 200) {
                if(ret[@"oauth_url"]) {
                    [self startWebView:ret[@"oauth_url"]];
                } else {
                    [self writeLog:@"agent_serviceLogin" :@"fail! check oauth_url!"];
                }
            } else {
                [self writeLog:@"agent_serviceLogin" :@"fail! check rcmsg!"];
            }
        } else {
            [self writeLog:@"agent_serviceLogin" :@"fail! return null."];
        }
    } else {
        [self writeLog:@"agent_serviceLogin" :@"fail! maybe not initialized!"];
    }
}
- (IBAction) onClickAgentServiceLogout {
    if([self isNull:insideSDK] == NO) {
        NSDictionary *ret = [insideSDK agent_serviceLogout:@"geniemusic"];
        if([self isNull:ret] == NO) {
            [self writeLogForDic:@"agent_serviceLogout" :ret];
        } else {
            [self writeLog:@"agent_serviceLogout" :@"fail! return null."];
        }
    } else {
        [self writeLog:@"agent_serviceLogout" :@"fail! maybe not initialized!"];
    }
}
- (IBAction) onClickAgentServiceStatus {
    if([self isNull:insideSDK] == NO) {
        NSDictionary *ret = [insideSDK agent_serviceLoginStatus:@"geniemusic"];
        if([self isNull:ret] == NO) {
            [self writeLogForDic:@"agent_serviceLoginStatus" :ret];
        } else {
            [self writeLog:@"agent_serviceLoginStatus" :@"fail! return null."];
        }
    } else {
        [self writeLog:@"agent_serviceLoginStatus" :@"fail! maybe not initialized!"];
    }
}
- (IBAction) onClickPlayPause {
    if([self isNull:insideSDK] == NO) {
        [insideSDK agent_sendCommand:[self makeSndHWEV:@"button" :@"Btn_PU" :nil]];
    }
}
- (IBAction) onClickPrev {
    if([self isNull:insideSDK] == NO) {
        [insideSDK agent_sendCommand:[self makeSndHWEV:@"button" :@"Btn_PV" :nil]];
    }
}
- (IBAction) onClickNext {
    if([self isNull:insideSDK] == NO) {
        [insideSDK agent_sendCommand:[self makeSndHWEV:@"button" :@"Btn_NX" :nil]];
    }
}
- (IBAction) onClickAgentSetConfig {
    // 아래 값은 샘플이터 입니다. 아래 URL 참조
    // https://github.com/gigagenie/ginside-sdk/wiki/6.23-agent_setConfig
    
    NSMutableDictionary *cmd = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *cmdOpt = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *sttOpt = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *devOpt = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *ttsOpt = [[NSMutableDictionary alloc] init];
    [cmd setObject:@"Req_CONF" forKey:@"cmdType"];
    [sttOpt setObject:@"GGenieM" forKey:@"profile"];
    [devOpt setObject:@50 forKey:@"volume"];
    [ttsOpt setObject:@"directWavFile" forKey:@"receivingMethod"];
    
    [cmdOpt setObject:sttOpt forKey:@"sttOpt"];
    [cmdOpt setObject:devOpt forKey:@"devOpt"];
    [cmdOpt setObject:ttsOpt forKey:@"ttsOpt"];
    
    [payload setObject:cmdOpt forKey:@"cmdOpt"];
    [cmd setObject:payload forKey:@"payload"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [insideSDK agent_setConfig:json];
    [self writeLog:@"agent_setConfig" :[NSString stringWithFormat: @"called! %@", json]];
}
- (IBAction) onClickAgentSetCustomVersion {
    // 아래 값은 샘플임
    [insideSDK agent_setCustomVersion:@"test" :@"0.1"];
    [self writeLog:@"agent_setCustomVersion" :@"called! test, 0.1"];
}
- (IBAction) onClickAgentDebugMode {
    [insideSDK agent_debugmode];
}
- (IBAction) onClickAgentSetServerInfo {
    infoType = 1;
    _infoViewLabel1.text = @"Addr";
    _infoViewLabel2.text = @"gRPC";
    _infoViewLabel3.text = @"Rest";
    _infoViewTextField1.text = serverAddr;
    _infoViewTextField2.text = serverGrpcPort;
    _infoViewTextField3.text = serverRestPort;
    [_infoView setHidden:false];
}
- (IBAction) onClickAgentSetLocation {
    infoType = 2;
    _infoViewLabel1.text = @"Lng";
    _infoViewLabel2.text = @"Lat";
    _infoViewLabel3.text = @"Addr";
    _infoViewTextField1.text = locationLng;
    _infoViewTextField2.text = locationLat;
    _infoViewTextField3.text = locationAddr;
    [_infoView setHidden:false];
}
- (IBAction) onClickClearLog {
    _tvLogText.text = @"";
}
- (IBAction) onClickKwsSetKeyword:(id)sender {
    int kwsId = -1;
    if(sender == _kwsSetKeywordBtn1) {
        kwsId = 0;
    } else if(sender == _kwsSetKeywordBtn2) {
        kwsId = 1;
    } else if(sender == _kwsSetKeywordBtn3) {
        kwsId = 2;
    } else if(sender == _kwsSetKeywordBtn4) {
        kwsId = 3;
    }
    
    if(kwsId > -1) {
        if([self isNull:insideSDK] == NO) {
            int ret = [insideSDK kws_setKeyword:kwsId];
            
            if(ret == 0) {
                kwsKeyword = kwsId;
                [self writeLog:@"kwsSetKeyword" :@"호출어 변경에 성공하였습니다."];
            } else if(ret == -1) {
                [self writeLog:@"kwsSetKeyword" :@"호출어 변경에 실패하였습니다. 해당 호출어 파일이 존재하지 않습니다. kws_init 이 실행되지 않은 경우에도 이 에러가 발생합니다."];
            } else if(ret == -2) {
                [self writeLog:@"kwsSetKeyword" :@"호출어 변경에 실패하였습니다. agent_init 호출을 먼저 시도해주세요."];
            }
        }
    }
}
- (IBAction) onClickKwsGetKeyword {
    if([self isNull:insideSDK] == NO) {
        int keyword = [insideSDK kws_getKeyword];
        NSString *msg;
        if(keyword == 0) { msg = @"기가지니"; }
        else if(keyword == 1) { msg = @"지니야"; }
        else if(keyword == 2) { msg = @"친구야"; }
        else if(keyword == 3) { msg = @"자기야"; }
        else { msg = @"please kws_init first!"; }
        [self writeLog:@"kwsGetKeyword" :msg];
    }
}
- (IBAction) onClickKwsInit {
    if([self isNull:insideSDK] == NO) {
        int ret = [insideSDK kws_init:1];
        if(ret == 0) {
            [self micOn:1];
            bKwsInit = true;
            [self writeLog:@"kwsInit" :@"success."];
        } else {
            [self writeLog:@"kwsInit" :[NSString stringWithFormat: @"fail. %d", ret]];
        }
        
    }
}
- (IBAction) onClickKwsReset {
    if([self isNull:insideSDK] == NO) {
        [insideSDK kws_reset];
        [self micOff];
        [self writeLog:@"kwsReset" :@"called"];
        bKwsInit = false;
    }
}
- (IBAction) onClickKwsError {
    if([self isNull:insideSDK] == NO) {
        int err = [insideSDK kws_error];
        [self writeLog:@"kwsError" :@"called. not supported now."];
    }
    
}
- (IBAction) onClickKwsVersion {
    if([self isNull:insideSDK] == NO) {
        NSString *version = [insideSDK kws_getVersion];
        [self writeLog:@"kwsVersion" :version];
    }
}
- (IBAction) onClickVolumeUp {
    int volume = [AVAudioSession.sharedInstance outputVolume];
    NSString *strVolume = [NSString stringWithFormat:@"%d", volume];
    NSString *str = [self makeSndHWEV:@"volume" :@"setVolume" :strVolume];
    [insideSDK agent_sendCommand:str];
}
- (IBAction) onClickVolumeDown {
    
}
- (IBAction) onClickInfoViewConfirm {
    if(infoType == 1) {
        serverAddr = _infoViewTextField1.text;
        serverGrpcPort = _infoViewTextField2.text;
        serverRestPort = _infoViewTextField3.text;
        [self writeLog:@"agent_setServerInfo" :@"success!"];
    } else if(infoType == 2) {
        locationLng = _infoViewTextField1.text;
        locationLat = _infoViewTextField2.text;
        locationAddr = _infoViewTextField3.text;
        [self writeLog:@"agent_setLocation" :@"success!"];
    }
    [_infoView setHidden:true];
}
- (IBAction) onClickInfoViewClose {
    [_infoView setHidden:true];
}
- (IBAction) onChangeSendTextWord {
    arrWordIdx = arrWordIdx == arrWord.count-1 ? 0 : arrWordIdx + 1;
    _tfSendText.text = arrWord[arrWordIdx];
}
- (NSString *) makeSndHWEV:(NSString *)target:(NSString *)hwEvent:(NSString *)hwEventValue {
    NSMutableDictionary *cmd = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *cmdOpt = [[NSMutableDictionary alloc] init];
    [cmd setObject:@"Snd_HWEV" forKey:@"cmdType"];
    [cmdOpt setObject:target forKey:@"target"];
    [cmdOpt setObject:hwEvent forKey:@"hwEvent"];
    if([self isNull:hwEventValue] == NO) {
        NSMutableDictionary *hwEventOpt = [[NSMutableDictionary alloc] init];
        [hwEventOpt setObject:hwEventValue forKey:@"value"];
        [cmdOpt setObject:hwEventOpt forKey:@"hwEventOpt"];
    }
    [payload setObject:cmdOpt forKey:@"cmdOpt"];
    [cmd setObject:payload forKey:@"payload"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return json;
}
- (void) agent_onCommand:(NSString *)actionType :(NSDictionary *)payload {
    if([actionType isEqualToString:@"media_data"]) {
        [self writeLogForDic:@"SampleApp agent_onCommand called : actionType:media_data" :nil];
        NSLog(@"SampleApp agent_onCommand called actionType:%@)", actionType);
    } else {
        NSString *msg = [NSString stringWithFormat:@"SampleApp agent_onCommand called : actionType:%@", actionType];
        [self writeLogForDic:msg :payload];
        
        if([self isNull:payload] == YES) {
            NSLog(@"SampleApp agent_onCommand called actionType:%@ payload:%@)", actionType, payload.description);
        } else {
            NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:nil];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"SampleApp agent_onCommand called actionType:%@ payload:%@)", actionType, str);
        }
    }
    NSArray *arrActionType = @[@"start_voice", @"stop_voice", @"media_data", @"play_media", @"control_media", @"control_hardware", @"webview_url", @"set_timer"];
    NSInteger idx = [arrActionType indexOfObject:actionType];
    switch (idx) {
        case 0: { // start_voice
            dispatch_async(dispatch_get_main_queue(), ^{
                [self micOn:0];
                [self showUtteranceWave:true :true];
            });
            break;
        }
        case 1: { // "stop_voice"
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showUtteranceWave:false :true];
                [self micOffAndCheckKws];
            });
            break;
        }
        case 2: { // "media_data"
            [self playSoundForTTS:payload[@"voice"]];
            break;
        }
        case 3: { // "play_media"
            if(payload[@"cmdOpt"]) {
                NSDictionary *cmdOpt = payload[@"cmdOpt"];
                if(cmdOpt[@"channel"] && cmdOpt[@"actOnOther"]) {
                    int channel = [cmdOpt[@"channel"] intValue];
                    NSString *actOnOther = cmdOpt[@"actOnOther"];
                    // actOnOther 값이 다음과 같다면, 일단 현재 채널을 actOnOther 에 맞게 처리해준다.
                    if([actOnOther isEqualToString:@"pause"] || [actOnOther isEqualToString:@"pauseR"] || [actOnOther isEqualToString:@"stop"]) {
                        [self controlPlayer:actOnOther:channel:false:-1];
                    }
                    
                    curChannel = channel;
                    if(curChannel == 10) {
                        // 타이머는 분기 처리 필요
                        // 아래는 타이머 효과음 처리를 생략하고 agent_updateMediatatus 만 임의로 호출하는 예제
                        [self writeLogForDic:@"TimerEvent" :nil];
                        [self updateMediaStatus:curChannel :@"started" :0];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self updateMediaStatus:10 :@"complete" :1000];
                        });
                    } else {
                        if(cmdOpt[@"url"]) {
                            [self playSound:cmdOpt[@"url"]];
                        }
                    }
                }
            }
            break;
        }
        case 4: { // "control_media"
            if(payload[@"cmdOpt"]) {
                NSDictionary *cmdOpt = payload[@"cmdOpt"];
                if(cmdOpt[@"channel"] && cmdOpt[@"act"]) {
                    int channel = [cmdOpt[@"channel"] intValue];
                    NSString *act = cmdOpt[@"act"];
                    
                    double playTime = -1;
                    if(cmdOpt[@"playTime"]) {
                        playTime = [cmdOpt[@"playTime"] doubleValue];
                    }
                    NSLog(@"InsideSDKSample control_media %@ %d", act, channel);
                    [self controlPlayer:act:channel:true:playTime];
                }
            }
            break;
        }
        case 5: { // "control_hardware"
            if(payload[@"cmdOpt"]) {
                NSDictionary *cmdOpt = payload[@"cmdOpt"];
                if(cmdOpt[@"hwCmd"]) {
                    NSString *hwCmd = cmdOpt[@"hwCmd"];
                    if([hwCmd isEqualToString:@"setVolume"]) {
                        if(cmdOpt[@"hwCmdOpt"]) {
                            NSDictionary *hwCmdOpt = cmdOpt[@"hwCmdOpt"];
                            if(hwCmdOpt[@"control"] && hwCmdOpt[@"value"]) {
                                NSString *control = hwCmdOpt[@"control"];
                                NSString *value = hwCmdOpt[@"value"];
                                
                                float volume = [AVAudioSession.sharedInstance outputVolume];
                                if([control isEqualToString:@"UP"]) {
                                    volume = volume + ([value isEqualToString:@"LE"] ? 0.1 : [value isEqualToString:@"GN"] ? 0.2 : 0.3);
                                } else if([control isEqualToString:@"DN"]) {
                                    volume = volume - ([value isEqualToString:@"LE"] ? 0.1 : [value isEqualToString:@"GN"] ? 0.2 : 0.3);
                                } else {
                                    NSLog(@"%@ onCommand control_hardware called control : %@", tag, control);
                                }
                                volume = volume > 1.0 ? 1.0 : volume < 0.0 ? 0.0 : volume;
                                volume = floor(volume * 10) / 10;
                                [self setVolume:volume];
                            }
                        }
                    }
                }
            }
            break;
        }
        case 6: { // "webview_url"
            if(payload[@"cmdOpt"]) {
                NSDictionary *cmdOpt = payload[@"cmdOpt"];
                if(cmdOpt[@"oauth_url"]) {
                    [self startWebView:cmdOpt[@"oauth_url"]];
                }
            }
            break;
        }
        case 7: { // "set_timer"
            if(payload[@"cmdOpt"]) {
                NSDictionary *cmdOpt = payload[@"cmdOpt"];
                if(cmdOpt[@"setOpt"] && cmdOpt[@"actionTrx"] && cmdOpt[@"setTime"] && cmdOpt[@"reqAct"]) {
                    NSString *setOpt = cmdOpt[@"setOpt"];
                    NSString *actionTrx = cmdOpt[@"actionTrx"];
                    NSString *setTime = cmdOpt[@"setTime"];
                    NSString *reqAct = cmdOpt[@"reqAct"];
                    if([setOpt isEqualToString:@"set"]) {
                        [self timerClear:actionTrx];
                        double time = [setTime doubleValue];
                        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                  actionTrx, @"actionTrx",
                                                  reqAct, @"reqAct", nil];
                        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(timerCallback:) userInfo:userInfo repeats:false];
                        [dicTimer setObject:timer forKey:actionTrx];
                    } else if([setOpt isEqualToString:@"clear"]) {
                        [self timerClear:actionTrx];
                    }
                }
            }
            break;
        }
        default: {
            NSLog(@"agent_onCommand default : %@)", actionType);
            break;
        }
    }
}
- (void) agent_onEvent:(int)evt :(NSDictionary *)opt {
    switch(evt) {
        case GRPC_INIT_SUCCESS: {
            NSLog(@"GRPC_INIT_SUCCESS");
            [self writeLogForDic:@"agent_onEvent GRPC_INIT_SUCCESS" :opt];
            break;
        }
        case GRPC_INIT_FAIL: {
            NSLog(@"GRPC_INIT_FAIL");
            [self writeLogForDic:@"agent_onEvent GRPC_INIT_FAIL" :opt];
            [insideSDK kws_reset];
            break;
        }
        case GRPC_DISCONNECTED: {
            NSLog(@"GRPC_DISCONNECTED");
            [self writeLogForDic:@"agent_onEvent GRPC_DISCONNECTED" :opt];
            break;
        }
        case GO_TO_STANDBY: {
            NSLog(@"GO_TO_STANDBY");
            [self writeLogForDic:@"agent_onEvent GO_TO_STANDBY" :opt];
            break;
        }
        case SET_CONFIG_SUCCESS: {
            NSLog(@"SET_CONFIG_SUCCESS");
            [self writeLogForDic:@"agent_onEvent SET_CONFIG_SUCCESS" :opt];
            break;
        }
        case SET_CONFIG_FAIL: {
            NSLog(@"SET_CONFIG_FAIL");
            [self writeLogForDic:@"agent_onEvent SET_CONFIG_FAIL" :opt];
            break;
        }
        case SERVER_ERROR: {
            if([self isNull:opt] == NO) {
                NSLog(@"SERVER_ERROR %@", opt.description);
                [self writeLogForDic:@"agent_onEvent SERVER_ERROR" :opt];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showUtteranceWave:false :true];
                [self micOffAndCheckKws];
            });
            break;
        }
        default: {
            NSLog(@"agent_onEvent default : %d", evt);
            break;
        }
    }
}
- (void) timerClear:(NSString *)actionTrx {
    NSTimer *timer = dicTimer[actionTrx];
    if([self isNull:timer] == NO) {
        [timer invalidate];
        [dicTimer removeObjectForKey:actionTrx];
    }
}
- (void) timerCallback:(NSTimer *)timer {
    NSLog(@"timerCallback..........");
    NSDictionary *userInfo = timer.userInfo;
    if(userInfo[@"actionTrx"] && userInfo[@"reqAct"]) {
        NSString *actionTrx = userInfo[@"actionTrx"];
        NSString *reqAct = userInfo[@"reqAct"];
        
        [self timerClear:actionTrx];
        
        NSMutableDictionary *cmd = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *cmdOpt = [[NSMutableDictionary alloc] init];
        [cmd setObject:@"Snd_TMEV" forKey:@"cmdType"];
        
        [cmdOpt setObject:reqAct forKey:@"reqAct"];
        [cmdOpt setObject:actionTrx forKey:@"actionTrx"];
        [cmdOpt setObject:[self getTodayString] forKey:@"localTime"];
        [payload setObject:cmdOpt forKey:@"cmdOpt"];
        [cmd setObject:payload forKey:@"payload"];
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:nil];
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [insideSDK agent_sendCommand:json];
        [self writeLog:@"agent_sendCommand" :[NSString stringWithFormat: @"called! %@", json]];
    }
}
- (void) playSoundForTTS:(NSData *)voice {
    [self releasePlayer];
    
    @try {
        NSError *error;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithData:voice error:&error];
        p.delegate = self;
        [p prepareToPlay];
        
        double duration = [p duration];
        if(duration > 0) {
            [p play];
            curPlayer = p;
            [self updateMediaStatus:curChannel :@"started" :0];
        } else {
            NSLog(@"playSoundForTTS duration : %f", duration);
        }
        
        player[curChannel] = p;
        
    } @catch (NSException *exception) {
        NSLog(@"playSoundForTTS exception : %@", exception.description);
    }
}
- (void) playSound:(NSString *)url {
    [self releasePlayer];
    
    if([url containsString:@"m3u8"]) {
        // radio
        NSURL *fileURL = [NSURL URLWithString:url];
        if([self isNull:fileURL] == NO) {
            AVPlayer *p = [[AVPlayer alloc] initWithURL:fileURL];
            [p play];
            radioCh = curChannel;
            
            curPlayer = p;
            m3u8player[curChannel] = p;
            
            [self updateMediaStatus:curChannel :@"started" :0];
        }
    } else {
        @try {
            NSError *error;
            NSData *fileURL = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithData:fileURL error:&error];
            p.delegate = self;
            [p prepareToPlay];
            [p play];
                        
            if(radioCh == curChannel) {
                radioCh = -1;
            }
            
            player[curChannel] = p;
            curPlayer = p;
            
            [self updateMediaStatus:curChannel :@"started" :0];
        } @catch (NSException *exception) {
            NSLog(@"playSoundForTTS exception : %@", exception.description);
        }
    }
}
- (void) releasePlayer {
    if([self isNull:player[curChannel]] == NO) {
        AVAudioPlayer *p = player[curChannel];
        [p stop];
        player[curChannel] = [NSNull null];
    }
}
- (void) updateMediaStatus:(int)channel:(NSString *)state:(int)duration {
    [self writeLog:@"agent_updateMediaStatus" :[NSString stringWithFormat: @"%d, %@, %d", channel, state, duration]];
    [insideSDK agent_updateMediaStatus:channel :state :duration];
}

- (void) micOn:(int)type {
    [self micOff];
    AudioController.sharedInstance.delegate = self;
    [AudioController.sharedInstance prepareWithSampleRate:16000.0];
    [AudioController.sharedInstance start:type];
}
- (void) micOff {
    [AudioController.sharedInstance stop];
}
- (void) micOffAndCheckKws {
    [self micOff];
    if(bKwsInit) {
        [self micOn:1];
    }
}
- (void) sendRms:(NSNumber *)rmsdB {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->ktWaveView updateWithLevel:[rmsdB doubleValue]];
    });
}
- (void) setVolumeViewSlider{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    slider = nil;
    for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            slider = (UISlider *)view;
            break;
        }
    }
}
- (void) setVolume:(float)volume {
    if(slider != nil) {
        NSString *fVolume = [[NSNumber numberWithFloat:volume] stringValue];
        [self writeLog:@"control_hardware" :[NSString stringWithFormat:@"setVolume called. target volume : %@", fVolume]];
        slider.value = volume;
    }
}
- (void)sendVoice:(NSData *)data {
    if([self isNull:insideSDK] == NO) {
        [insideSDK agent_sendVoice:data];
    }    
}

- (void)sendVoiceForKws:(NSData *)data {
    if([self isNull:insideSDK] == NO) {
        int status = [insideSDK kws_detect:data.bytes :data.length/2];
        if(status == 4) {
            [insideSDK kws_init:kwsKeyword];
            [self onClickAgentStartVoice];
        }
    }
}

- (void) startWebView:(NSString *)strUrl {
    NSURL *url = [NSURL URLWithString:strUrl];
    if([self isNull:url] == NO) {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:svc animated:YES completion:nil];
    } else {
        NSLog(@"%@start webView fail....", tag);
    }
}
// play_media, control_media 일 때 여기로 온다.
- (void) controlPlayer:(NSString *)act:(int)channel:(BOOL)isControlMedia:(double)playTime {
    [self checkPlayer:channel];
    double currentTime = 0;
    if([curPlayer isKindOfClass:[AVAudioPlayer class]]) {
        curPlayer = player[channel];
        
        if([self isNull:curPlayer] == NO) {
            currentTime = [((AVAudioPlayer *)curPlayer) currentTime];
            
            if([act isEqualToString:@"pause"]) {
                [((AVAudioPlayer *)curPlayer) pause];
            } else if([act isEqualToString:@"stop"]) {
                [((AVAudioPlayer *)curPlayer) stop];
            } else if([act isEqualToString:@"resume"]) {
                [((AVAudioPlayer *)curPlayer) play];
            } else if([act isEqualToString:@"seek"]) {
                if(playTime > 0) {
                    [((AVAudioPlayer *)curPlayer) pause];
                    [((AVAudioPlayer *)curPlayer) setCurrentTime:(currentTime+playTime)];
                    [((AVAudioPlayer *)curPlayer) play];
                }
            }
        }
    } else {
        curPlayer = m3u8player[channel];
        if([self isNull:curPlayer] == NO) {
            currentTime = CMTimeGetSeconds([((AVPlayer *)curPlayer) currentTime]);
            
            if([act isEqualToString:@"pause"] || [act isEqualToString:@"stop"]) {
                [((AVPlayer *)curPlayer) pause];
            } else if([act isEqualToString:@"resume"]) {
                [((AVPlayer *)curPlayer) play];
            } else if([act isEqualToString:@"seek"]) {
                if(playTime > 0) {
                    CMTime cmTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(((AVPlayer *)curPlayer).currentTime) + playTime, ((AVPlayer *)curPlayer).currentTime.timescale);
                    
                    [((AVPlayer *)curPlayer) pause];
                    [((AVPlayer *)curPlayer) seekToTime:cmTime];
                    [((AVPlayer *)curPlayer) play];
                }
            }
        }
    }
    
    // control_media 로 왔을 땐 다음 처리를 하고, updateMediaStatus 처리를 한다.
    if(isControlMedia) {
        NSString *state = @"";
        if([act isEqualToString:@"pause"]) {
            state = @"paused";
        } else if([act isEqualToString:@"stop"]) {
            state = @"stopped";
        } else if([act isEqualToString:@"resume"]) {
            state = @"resumed";
        } else {
            state = @"";
        }
        
        if(![state isEqualToString:@""]) {
            [self updateMediaStatus:channel :state :currentTime*1000];
        }
        if([act isEqualToString:@"resume"]) {
            curChannel = channel;
        }
    }
}
// 재생해야 할 채널이 라디오인지 아닌지 체크한다.
- (void) checkPlayer:(int)channel {
    if(radioCh == channel) {
        curPlayer = m3u8player[channel];
    } else {
        curPlayer = player[channel];
    }
}
- (void) showUtteranceWave:(bool)animated :(bool)startStopRecord {
    NSPredicate *isKeyWindow = [NSPredicate predicateWithFormat:@"isKeyWindow == YES"];
    UIWindow *window = [[[UIApplication sharedApplication] windows] filteredArrayUsingPredicate:isKeyWindow].firstObject;
    if(animated) {
        if([self isNull:ktWaveView] == YES) {
            CGRect frame = CGRectMake(0, window.bounds.size.height * 4 / 5, window.bounds.size.width, window.bounds.size.height / 5);
            ktWaveView = [[SCSiriWaveformView alloc] init];
            ktWaveView.frame = frame;
            ktWaveView.clipsToBounds = false;
        }
        if([self isNull:ktWaveView.superview] == YES) {
            [window addSubview:ktWaveView];
            [window bringSubviewToFront:ktWaveView];
        }
        if(startStopRecord) {
            [AudioController.sharedInstance startRecorder];
        }
    } else {
        if(startStopRecord) {
            [AudioController.sharedInstance stopRecorder];
        }
        if([self isNull:ktWaveView] == NO) {
            [ktWaveView removeFromSuperview];
        }
    }
}
// 볼륨 버튼으로 조절하였을 때 해당 볼륨값을 서버로 전송한다.
- (void) volumeDidChange:(NSNotification *)notification {
    if([[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
        float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
        curVolume = volume;
        NSString *str = [self makeSndHWEV:@"volume" :@"setVolume" :[[NSNumber numberWithFloat:curVolume] stringValue]];
        [self writeLog:@"agent_sendCommand" :[NSString stringWithFormat:@"volume changed. command : %@", str]];
        [insideSDK agent_sendCommand:str];
    }
}
- (void) writeLogForDic:(NSString * _Nonnull)apiName:(NSDictionary * _Nullable)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self isNull:log] == YES) {
            self->_tvLogText.text = [NSString stringWithFormat:@"%@%@%@", self->_tvLogText.text, @"\n", apiName];
        } else {
            NSData *data = [NSJSONSerialization dataWithJSONObject:log options:NSJSONWritingPrettyPrinted error:nil];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            self->_tvLogText.text = [NSString stringWithFormat:@"%@%@%@%@%@", self->_tvLogText.text, @"\n", apiName, @" ", str];
        }
        [self scrollToBottom];
    });
}
- (void) writeLog:(NSString * _Nonnull)apiName:(NSString * _Nonnull)str {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_tvLogText.text = [NSString stringWithFormat:@"%@%@%@%@%@", self->_tvLogText.text, @"\n", apiName, @" ", str];
        [self scrollToBottom];
    });
}
- (void) scrollToBottom {
    NSRange bottom = NSMakeRange(_tvLogText.text.length, 1);
    [_tvLogText scrollRangeToVisible:bottom];
    [_tvLogText setScrollEnabled:NO];
    [_tvLogText setScrollEnabled:YES];
}
// 현재 시간을 가져온다 yyyymmddhhmmss
- (NSString *) getTodayString {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    return [dateFormatter stringFromDate:date];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}
- (BOOL) isNull:(id)obj {
    if (obj == nil || obj == NULL) { return YES; }
    if ([obj isEqual:[NSNull null]]) { return YES; }
    return NO;
}
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSTimeInterval duration = player.duration;
    [self updateMediaStatus:curChannel :@"complete" :duration*1000];
}
- (void) setAudioSession {
    NSError *error = nil;
    if (@available(iOS 10, *)) {
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
                                        withOptions: AVAudioSessionCategoryOptionMixWithOthers | //필수 옵션
                                        AVAudioSessionCategoryOptionDefaultToSpeaker |
                                        AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                        error:&error];
    } else {
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
                                        withOptions: AVAudioSessionCategoryOptionMixWithOthers | //필수 옵션
                                        AVAudioSessionCategoryOptionDefaultToSpeaker
                                        error:&error];
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
}
- (void) viewWillAppear:(BOOL)animated {
    [notificationCenter addObserver:self selector:@selector(volumeDidChange:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [self setAudioSession];
}
- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}
@end
