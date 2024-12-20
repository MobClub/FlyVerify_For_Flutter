import 'dart:io';
import 'dart:async';
import 'flyverify_defines.dart';
import 'flyverify_UIConfig.dart';
import 'package:flutter/services.dart';

class Flyverify {
  static const MethodChannel _channel =
      const MethodChannel('com.fly.flyverify.methodChannel');
  static const EventChannel _channelReceiver =
      const EventChannel('com.fly.flyverify.verifyEventChannel');

  static Future<void> registerSDK({String appKey = "", String appSecret = ""}) {
    final Map params = {'appKey': appKey, 'appSecret': appSecret};
    return _channel.invokeMethod(FlyVerifySDKMethods.register.name, params);
  }

  static Future<String?> get getVersion async {
    final String? version =
        await _channel.invokeMethod(FlyVerifySDKMethods.getVersion.name);
    return version;
  }

  static Future<String?> get platformVersion async {
    return await _channel
        .invokeMethod(FlyVerifySDKMethods.platformVersion.name);
  }

  static Future<dynamic> submitPrivacyGrantResult(
      bool status, Function(bool)? result) async {
    final Map<String, bool?> params = {'status': status};
    Future<dynamic> callBack = _channel.invokeMethod(
        FlyVerifySDKMethods.uploadPrivacyStatus.name, params);
    callBack.then((dynamic response) {
      // if (response != null && response is bool) {
      //   result(response);
      // }
    });
    return callBack;
  }

  static Future<dynamic> get currentOperatorType async {
    return await _channel
        .invokeMethod(FlyVerifySDKMethods.currentOperatorType.name);
  }

  static Future<dynamic> enableDebug({bool enable = false}) {
    final Map args = {'enable': enable};
    return _channel.invokeMethod(FlyVerifySDKMethods.enableDebug.name, args);
  }

  static Future<dynamic> clearPhoneScripCache() {
    return _channel.invokeMethod(FlyVerifySDKMethods.clearPhoneScripCache.name);
  }

  static Future<bool?> get isVerifySupport async {
    final bool? isSupport =
        await _channel.invokeMethod(FlyVerifySDKMethods.flyVerifyEnable.name);
    return isSupport;
  }

  static Future<dynamic> preVerify(
      {double timeout = 4.0, required FlyVerifyResultListener result}) {
    final Map<String, dynamic> params = {'timeout': timeout};
    Future<dynamic> callBack =
        _channel.invokeMethod(FlyVerifySDKMethods.preVerify.name, params);

    callBack.then((dynamic response) {
      if (response != null && response is Map) {
        result(response['ret'], response['err']);
      } else {
        result(null, null);
      }
    });

    return callBack;
  }

  static Future<dynamic> otherOAuthPageCallBack(
      FlyVerifyResultListener result) {
    Future<dynamic> callBack =
        _channel.invokeMethod(FlyVerifySDKMethods.otherOAuthPage.name);
    _channelReceiver.receiveBroadcastStream().listen((event) {
      if (event != null && event is Map) {
        result(event, null);
      } else {
        result(null, null);
      }
    });
    return callBack;
  }

  static Future<dynamic> setAndroidPortraitLayout(
      Map<String, Object> uiSettings) {
    final Map<String, Object> params = {'androidPortraitConfig': uiSettings};
    Future<dynamic> callback = _channel.invokeMethod(
        FlyVerifySDKMethods.setAndroidPortraitLayout.name, params);
    return callback;
  }

  static Future<dynamic> setAndroidLandscapeLayout(
      Map<String, Object> landUiSettings) {
    final Map<String, Object> params = {
      'androidLandscapeConfig': landUiSettings
    };
    Future<dynamic> callback = _channel.invokeMethod(
        FlyVerifySDKMethods.setAndroidLandscapeLayout.name, params);
    return callback;
  }

  static Future<dynamic>? verify(
      FlyVerifyUIConfig config,
      FlyVerifyResultListener openAuthListener,
      FlyVerifyResultListener cancelAuthPageListener,
      FlyVerifyResultListener oneKeyLoginListener,
      FlyVerifyResultListener customEventListener,
      FlyVerifyResultListener androidEventListener) {
    final Map<String, dynamic> params = config.toJson();

    Future<dynamic>? callBack;
    if (Platform.isIOS) {
      callBack = _channel.invokeMethod(FlyVerifySDKMethods.verify.name, params);
      _channelReceiver.receiveBroadcastStream().listen((event) {
        if (event != null && event is Map) {
          verifyListenerType type =
              verifyListenerType.values[event['ListenerType']];
          switch (type) {
            case verifyListenerType.openAuthPage:
              if (openAuthListener != null) {
                openAuthListener(event['ret'], event['err']);
              }
              break;
            case verifyListenerType.cancelAuth:
              if (cancelAuthPageListener != null) {
                cancelAuthPageListener(event['ret'], event['err']);
              }
              break;
            case verifyListenerType.onLoginEvent:
              if (oneKeyLoginListener != null) {
                oneKeyLoginListener(event['ret'], event['err']);
              }
              break;
            case verifyListenerType.customBtnEvent:
              if (customEventListener != null) {
                customEventListener(event['ret'], event['err']);
              }
              break;
          }
        }
      }, onError: (event) {
        if (oneKeyLoginListener != null) {
          oneKeyLoginListener(null, null);
        }
      });
    } else if (Platform.isAndroid) {
      _channel.invokeMethod(
          FlyVerifySDKMethods.setAndroidLandscapeLayout.name, params);
      _channel.invokeMethod(
          FlyVerifySDKMethods.setAndroidPortraitLayout.name, params);
      callBack = _channel.invokeMethod(FlyVerifySDKMethods.verify.name);
      _channelReceiver.receiveBroadcastStream().listen((event) {
        if (event != null && event is Map) {
          if (event['ret'] != null) {
            if (androidEventListener != null) {
              androidEventListener(event, null);
            }
          } else if (event['err'] != null) {
            if (androidEventListener != null) {
              androidEventListener(null, event);
            }
          }
          if (event['customViewClick'] != null) {
            if (customEventListener != null) {
              //value为点击的控件tag
              customEventListener(event, null);
            }
          }
        }
      });
    }
    return callBack;
  }

  static Future<dynamic> mobileAuthToken(
      {double? timeout, required FlyVerifyResultListener result}) {
    final Map<String, dynamic> args = {'timeout': timeout};
    Future<dynamic> callBack =
        _channel.invokeMethod(FlyVerifySDKMethods.mobileAuthToken.name, args);

    if (Platform.isAndroid) {
      _channelReceiver.receiveBroadcastStream().listen((event) {
        print('flutter:dart:received mobileAuthToken');
        if (event != null && event is Map) {
          if (event['ret'] != null) {
            result(event['ret'], null);
          } else if (event['err'] != null) {
            result(null, event);
          }
        }
      });
    } else if (Platform.isIOS) {
      callBack.then((dynamic response) {
        if (response != null && response is Map) {
          result(response['ret'], response['err']);
        } else {
          result(null, null);
        }
      });
    }
    return callBack;
  }

  static Future<dynamic> mobileVerify(
      {required String phoneNum,
      required Map<String, dynamic> tokenInfo,
      double? timeout,
      required FlyVerifyResultListener result}) {
    final Map<String, dynamic> args = {
      'phoneNum': phoneNum,
      'tokenInfo': tokenInfo,
      'timeout': timeout
    };
    Future<dynamic> callBack =
        _channel.invokeMethod(FlyVerifySDKMethods.mobileVerify.name, args);

    callBack.then((dynamic response) {
      if (response != null && response is Map) {
        result(response['ret'], response['err']);
      } else {
        result(null, null);
      }
    });

    return callBack;
  }

  static Future<dynamic> manualDismissLoginVC({bool flag = false}) async {
    final Map<String, bool> args = {'flag': flag};
    return await _channel.invokeMethod(
        FlyVerifySDKMethods.finishLoginVC.name, args);
  }

  static Future<dynamic> finishOAuthPage() {
    return _channel.invokeMethod(FlyVerifySDKMethods.finishOAuthPage.name);
  }

  static Future<dynamic> autoFinishOAuthPage({bool flag = false}) {
    final Map<String, bool> args = {'autoFinish': flag};
    return _channel.invokeMethod(
        FlyVerifySDKMethods.autoFinishOAuthPage.name, args);
  }

  static Future<dynamic> manualDismissLoading() {
    return _channel.invokeMethod(FlyVerifySDKMethods.hideLoading.name);
  }

  static Future<dynamic> toast(String content) {
    final Map<String, String> args = {'content': content};
    return _channel.invokeMethod(FlyVerifySDKMethods.toast.name, args);
  }

  static void addListener(FlyVerifyResultListener result) {
    _channelReceiver
        .receiveBroadcastStream()
        .listen((event) {}, onError: (event) {});
  }
}
