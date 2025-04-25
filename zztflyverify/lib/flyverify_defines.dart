enum verifyListenerType {
  openAuthPage,
  cancelAuth,
  onLoginEvent,
  customBtnEvent
}

typedef void FlyVerifyResultListener(Map? rt, Map? err);

class FlyVerifySDKMethod {
  final String name;
  final int id;

  FlyVerifySDKMethod({required this.name, required this.id}) : super();
}

class FlyVerifySDKMethods {
  static final FlyVerifySDKMethod getVersion =
      FlyVerifySDKMethod(name: 'getVersion', id: 0);
  static final FlyVerifySDKMethod flyVerifyEnable =
      FlyVerifySDKMethod(name: 'flyVerifyEnable', id: 1);
  static final FlyVerifySDKMethod currentOperatorType =
      FlyVerifySDKMethod(name: 'currentOperatorType', id: 2);
  static final FlyVerifySDKMethod clearPhoneScripCache =
      FlyVerifySDKMethod(name: 'clearPhoneScripCache', id: 3);
  static final FlyVerifySDKMethod enableDebug =
      FlyVerifySDKMethod(name: 'enableDebug', id: 4);
  static final FlyVerifySDKMethod uploadPrivacyStatus =
      FlyVerifySDKMethod(name: 'uploadPrivacyStatus', id: 5);
  static final FlyVerifySDKMethod finishLoginVC =
      FlyVerifySDKMethod(name: 'finishLoginVC', id: 6);
  static final FlyVerifySDKMethod hideLoading =
      FlyVerifySDKMethod(name: 'hideLoading', id: 7);
  static final FlyVerifySDKMethod preVerify =
      FlyVerifySDKMethod(name: 'preVerify', id: 8);
  static final FlyVerifySDKMethod verify =
      FlyVerifySDKMethod(name: 'verify', id: 9);
  static final FlyVerifySDKMethod mobileAuthToken =
      FlyVerifySDKMethod(name: 'mobileAuthToken', id: 10);
  static final FlyVerifySDKMethod mobileVerify =
      FlyVerifySDKMethod(name: 'mobileVerify', id: 11);
  static final FlyVerifySDKMethod platformVersion =
      FlyVerifySDKMethod(name: 'platformVersion', id: 12);
  static final FlyVerifySDKMethod otherOAuthPage =
      FlyVerifySDKMethod(name: 'OtherOAuthPageCallBack', id: 13);
  static final FlyVerifySDKMethod setAndroidPortraitLayout =
      FlyVerifySDKMethod(name: 'setAndroidPortraitLayout', id: 14);
  static final FlyVerifySDKMethod setAndroidLandscapeLayout =
      FlyVerifySDKMethod(name: 'setAndroidLandscapeLayout', id: 15);
  static final FlyVerifySDKMethod finishOAuthPage =
      FlyVerifySDKMethod(name: 'finishOAuthPage', id: 16);
  static final FlyVerifySDKMethod autoFinishOAuthPage =
      FlyVerifySDKMethod(name: 'autoFinishOAuthPage', id: 17);
  static final FlyVerifySDKMethod toast =
      FlyVerifySDKMethod(name: 'toast', id: 18);
  static final FlyVerifySDKMethod register = FlyVerifySDKMethod(name: 'register', id: 19);
}
