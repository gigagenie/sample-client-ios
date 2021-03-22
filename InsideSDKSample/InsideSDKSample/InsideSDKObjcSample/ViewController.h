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

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <SafariServices/SafariServices.h>
#import "AudioController.h"
#import <InsideSDK/InsideSDK.h>
#import "SCSiriWaveformView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate, InsideSDKDelegate, AudioControllerDelegate> {
    NSString *tag;
    //gplug 2.0 사용설정
    NSString *clientId;
    NSString *clientKey;
    NSString *clientSecret;
    NSString *userId;
    NSString *uuid;

    id curPlayer;

    NSMutableArray *player;
    NSMutableArray *m3u8player;
    
    AVAudioSession *audioSession;
    int curChannel;
    float curVolume;
    int radioCh;
    
    InsideSDK *insideSDK;
    bool test;
    NSNotificationCenter *notificationCenter;
    NSMutableDictionary *dicTimer;
    
    SCSiriWaveformView *ktWaveView;
    
    NSString *serverAddr;
    NSString *serverGrpcPort;
    NSString *serverRestPort;
    
    NSString *locationLng;
    NSString *locationLat;
    NSString *locationAddr;
    NSString *ReqVOTXLang;

    NSMutableArray *arrWord;
    int arrWordIdx;
    int infoType;
    
    UISlider *slider;
    
    bool bKwsInit;
    int kwsKeyword;
}

@end
