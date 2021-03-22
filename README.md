# sample-client-ios
iOS Device SDK를 이용한 샘플 클라이언트

본 프로젝트는 iOS기반으로 동작하는 GiGA Genie Inside(이하, G-INSIDE) SDK sample app을 포함합니다. 

## GiGA Genie Inside
GiGA Genie Inside(이하, G-INSIDE)는 3rd party 개발자가 자신들의 제품(단말 장치, 서비스, 앱 등)에 KT의 AI Platform인 
'기가지니'를 올려서 음성인식과 자연어로 제어하고 기가지니가 제공하는 서비스(생활비서, 뮤직, 라디오 등)를 사용할 수 있도록 해줍니다.
G-INSIDE는 기가지니가 탑재된 제품을 개발자들이 쉽게 만들 수 있도록 개발 도구와 문서, 샘플 소스 등 개발에 필요한 리소스를 제공합니다.

## Prerequisites
* Build Tool: [Xcode](http://developer.apple.com/download/more) (12.4 또는 이후 버전 권장)
* [G-INSIDE iOS Device SDK](https://github.com/gigagenie/ginside-sdk/tree/master/g-sdk-ios)

## 인사이드 디바이스 키 발급
  1. [API Link](https://apilink.kt.co.kr) 에서 회원가입 
  2. 사업 제휴 신청 및 디바이스 등록 (Console > GiGA Genie > 인사이드 디바이스 등록)
  3. 디바이스 등록 완료 후 My Device에서 등록한 디바이스 정보 및 개발키 발급 확인 (Console > GiGA Genie > My Device)

## iOS용 Sample 빌드
- sample-client-ios를 다운로드 받고 디렉토리로 이동하여 InsideSDKSample.xcworkspace를 Xcode로 오픈한다.
    
- Xcode에서 [G-INSIDE iOS Device SDK](https://github.com/gigagenie/ginside-sdk/tree/master/g-sdk-ios) Framework 를 추가한다.
    
- 사용자 환경에 맞게 Bundle Identifier 등을 수정한다.
    
- Application 실행 전 인사이드 디바이스 키를 설정한다. 아래 내용을 실제 발급받은 키값으로 입력하여 빌드한다.
    
    ```
    YOUR-CLIENT-ID
    YOUR-CLIENT-KEY
    YOUR-CLIENT-SECRET
    ```

## License

sample-client-ios is licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)