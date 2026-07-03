import { AbilityAware, AbilityPluginBinding, FlutterPlugin, MethodCall, MethodChannel } from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';
import { ZztSDK } from '@zztsdk/zztcore';
import { FlyVerify, OperationCallback, VerifyException, VerifyResult } from '@zztsdk/flyverify';

const CHANNEL = 'com.fly.flyverify.methodChannel';

interface VerifyInfo {
  operator: string;
  opToken: string;
  token: string;
}

interface ErrorInfo {
  code: string;
  message: string;
  serialId?: string;
  extraDesc?: string;
}

export default class FlyverifyPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private appContext: Context | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'FlyverifyPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.appContext = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.appContext = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.abilityContext = null;
  }

  onReattachedToAbilityForConfigChanges(binding: AbilityPluginBinding): void {
    this.onAttachedToAbility(binding);
  }

  onDetachedFromAbilityForConfigChanges(): void {
    this.abilityContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'register':
        this.registerSDK(call, result);
        break;
      case 'getVersion':
        result.success(FlyVerify.getVersion());
        break;
      case 'platformVersion':
        result.success(deviceInfo.osFullName);
        break;
      case 'getAppSignature':
        result.success(this.getAppSignature());
        break;
      case 'uploadPrivacyStatus':
        this.submitPrivacyGrantResult(call, result);
        break;
      case 'preVerify':
        this.preVerify(call, result);
        break;
      case 'verify':
        this.verify(call, result);
        break;
      case 'mobileAuthToken':
      case 'mobileVerify':
        result.success({
          ret: null,
          err: {
            code: 'UNSUPPORTED',
            message: `${call.method} is not supported by the HarmonyOS FlyVerify SDK wrapper.`
          }
        });
        break;
      case 'finishOAuthPage':
      case 'finishLoginVC':
        FlyVerify.closeAuthLoginPage();
        result.success(true);
        break;
      case 'hideLoading':
        result.success(true);
        break;
      case 'autoFinishOAuthPage':
        FlyVerify.setAutoCloseAuthLoginPage(this.getBool(call, 'autoFinish', true));
        result.success(true);
        break;
      case 'toast':
      case 'OtherOAuthPageCallBack':
      case 'setAndroidPortraitLayout':
      case 'setAndroidLandscapeLayout':
        result.success(null);
        break;
      case 'flyVerifyEnable':
        result.success(true);
        break;
      case 'currentOperatorType':
      case 'clearPhoneScripCache':
      case 'enableDebug':
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private registerSDK(call: MethodCall, result: MethodResult): void {
    const context = this.getContext();
    if (context === null) {
      result.error('NO_CONTEXT', 'HarmonyOS context is not ready.', null);
      return;
    }

    const appKey = this.getString(call, 'appKey', '');
    const appSecret = this.getString(call, 'appSecret', '');
    ZztSDK.init(context, appKey, appSecret);
    result.success(null);
  }

  private submitPrivacyGrantResult(call: MethodCall, result: MethodResult): void {
    ZztSDK.submitPolicyGrantResult(this.getBool(call, 'status', false));
    result.success(true);
  }

  private preVerify(call: MethodCall, result: MethodResult): void {
    const timeout = this.getTimeoutMs(call);
    if (timeout > 0) {
      FlyVerify.setPreVerifyTimeout(timeout);
    }

    FlyVerify.preVerify().then(() => {
      result.success({
        ret: {
          status: true
        },
        err: null
      });
    }).catch((error: VerifyException) => {
      result.success({
        ret: null,
        err: this.errorToMap(error)
      });
    });
  }

  private verify(call: MethodCall, result: MethodResult): void {
    const timeout = this.getTimeoutMs(call);
    if (timeout > 0) {
      FlyVerify.setPreVerifyTimeout(timeout);
    }

    const uiContext = this.getUIContext();
    if (uiContext === null) {
      result.success({
        ret: null,
        err: {
          code: 'NO_UI_CONTEXT',
          message: 'HarmonyOS UIContext is not ready.'
        }
      });
      return;
    }

    const callback: OperationCallback<VerifyResult> = {
      onSuccess: (data: VerifyResult) => {
        result.success({
          ret: this.verifyResultToMap(data),
          err: null
        });
      },
      onFailure: (error: VerifyException) => {
        result.success({
          ret: null,
          err: this.errorToMap(error)
        });
      }
    };
    FlyVerify.verify(uiContext, callback);
  }

  private getContext(): Context | null {
    if (this.abilityContext !== null) {
      return this.abilityContext;
    }
    return this.appContext;
  }

  private getUIContext(): UIContext | null {
    try {
      return this.abilityContext?.windowStage?.getMainWindowSync().getUIContext() ?? null;
    } catch (e) {
      return null;
    }
  }

  private getAppSignature(): string {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO
      );
      return bundleInfo.signatureInfo.fingerprint.toLowerCase();
    } catch (e) {
      return '';
    }
  }

  private getTimeoutMs(call: MethodCall): number {
    const timeout = this.getNumber(call, 'timeout', 0);
    if (timeout <= 0) {
      return 0;
    }
    return timeout <= 60 ? Math.round(timeout * 1000) : Math.round(timeout);
  }

  private getString(call: MethodCall, key: string, fallback: string): string {
    const value: string | null = call.argument(key) as string | null;
    return typeof value === 'string' ? value : fallback;
  }

  private getBool(call: MethodCall, key: string, fallback: boolean): boolean {
    const value: boolean | null = call.argument(key) as boolean | null;
    return typeof value === 'boolean' ? value : fallback;
  }

  private getNumber(call: MethodCall, key: string, fallback: number): number {
    const value: number | null = call.argument(key) as number | null;
    return typeof value === 'number' ? value : fallback;
  }

  private verifyResultToMap(data: VerifyResult): VerifyInfo {
    return {
      operator: data.operator,
      opToken: data.opToken,
      token: data.token
    };
  }

  private errorToMap(error: VerifyException): ErrorInfo {
    return {
      code: `${error.code}`,
      message: error.message,
      serialId: error.serialId ?? '',
      extraDesc: error.extraDesc ?? ''
    };
  }
}
