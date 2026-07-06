import { AbilityAware, AbilityPluginBinding, FlutterPlugin, MethodCall, MethodChannel } from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';
import window from '@ohos.window';
import { ZztSDK } from '@zztsdk/zztcore';
import { ClauseSpan, DialogOptions, FlyVerify, OperationCallback, ThemeConfig, VerifyException, VerifyResult } from '@zztsdk/flyverify';

const CHANNEL = 'com.fly.flyverify.methodChannel';
type ConfigValue = Object | string | number | boolean | null;
type ConfigMap = Record<string, ConfigValue>;

interface OhosThemeEvent {
  event: string;
  data: ConfigMap | null;
}

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
    this.applyTheme(call);
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

  private applyTheme(call: MethodCall): void {
    const raw: string | null = call.argument('ohosThemeConfigJson') as string | null;
    const jsonStr: string = (typeof raw === 'string') ? raw : '';
    console.log('FlyVerify', 'ohs receive:' + jsonStr);
    if (jsonStr.length === 0) {
      console.log('FlyVerify', 'applyTheme skip: empty jsonStr');
      return;
    }
    // ArkTS 中 JSON.parse 返回 Object，直接 as ConfigMap 使用
    let config: ConfigMap = {};
    try {
      const parsed: Object = JSON.parse(jsonStr) as Object;
      if (parsed !== null && typeof parsed === 'object') {
        config = parsed as ConfigMap;
        const keys: string[] = Object.keys(config);
      }
    } catch (e) {
      console.log('FlyVerify', 'applyTheme JSON.parse error');
      return;
    }
    if (Object.keys(config).length === 0) {
      console.log('FlyVerify', 'applyTheme skip: empty config');
      return;
    }
    FlyVerify.setTheme(this.buildTheme(config));
  }

  private buildTheme(config: ConfigMap): ThemeConfig {
    let theme = new ThemeConfig();
    const systemBarProperties = this.mapSystemBarProperties(config);
    if (systemBarProperties !== null) {
      theme.setSystemBarProperties(systemBarProperties);
    }

    const numberSize = this.mapNumber(config, 'numberSize');
    if (numberSize !== null) {
      theme.setNumberSize(numberSize);
    }
    const numberColor = this.mapColor(config, 'numberColor');
    if (numberColor !== null) {
      theme.setNumberColor(numberColor);
    }
    const numberMargin = this.mapMargin(config, 'numberMargin');
    if (numberMargin !== null) {
      theme.setNumberMargin(numberMargin);
    }
    const numberAlign = this.mapAlignRuleOption(config, 'numberAlignRuleOption');
    if (numberAlign !== null) {
      theme.setNumberAlignRuleOption(numberAlign);
    }

    const logBtnText = this.mapString(config, 'logBtnText');
    if (logBtnText !== null) {
      theme.setLogBtnText(logBtnText);
    }
    const loginTextSize = this.mapNumber(config, 'loginBtnTextSize');
    if (loginTextSize !== null) {
      theme.setLoginBtnTextSize(loginTextSize);
    }
    const loginTextColor = this.mapColor(config, 'loginBtnTextColor');
    if (loginTextColor !== null) {
      theme.setLoginBtnTextColor(loginTextColor);
    }
    const loginColor = this.mapColor(config, 'loginBtnColor');
    if (loginColor !== null) {
      theme.setLoginBtnColor(loginColor);
    }
    const loginImgPath = this.mapString(config, 'loginBtnImgPath');
    if (loginImgPath !== null) {
      theme.setLoginBtnImgPath(loginImgPath);
    }
    const loginWidth = this.mapLength(config, 'loginBtnWidth');
    if (loginWidth !== null) {
      theme.setLoginBtnWidth(loginWidth);
    }
    const loginHeight = this.mapLength(config, 'loginBtnHeight');
    if (loginHeight !== null) {
      theme.setLoginBtnHeight(loginHeight);
    }
    const loginMargin = this.mapMargin(config, 'loginBtnMargin');
    if (loginMargin !== null) {
      theme.setLoginBtnMargin(loginMargin);
    }
    const loginAlign = this.mapAlignRuleOption(config, 'loginBtnAlignRuleOption');
    if (loginAlign !== null) {
      theme.setLoginBtnAlignRuleOption(loginAlign);
    }
    if (this.mapBool(config, 'checkedLoginListener') === true) {
      theme.setCheckedLoginListener({
        onLoginClickStart: (context: UIContext) => {
          this.emitOhosThemeEvent('checkedLoginStart', null);
        },
        onLoginClickComplete: (context: UIContext) => {
          this.emitOhosThemeEvent('checkedLoginComplete', null);
        }
      });
    }
    if (this.mapBool(config, 'uncheckedLoginListener') === true) {
      theme.setUncheckedLoginListener({
        onAuthLoginListener: (context: UIContext, callBack) => {
          const autoCheck = this.mapBool(config, 'uncheckedLoginAutoCheck') ?? true;
          let data: ConfigMap = {};
          data['autoCheck'] = autoCheck;
          this.emitOhosThemeEvent('uncheckedLogin', data);
          callBack.onAuthLoginCallBack(autoCheck);
        }
      });
    }
    const loginBorderRadius = this.mapLength(config, 'loginBtnBorderRadius');
    if (loginBorderRadius !== null) {
      theme.setLoginBtnBorderRadius(loginBorderRadius);
    }
    const loginBorderColor = this.mapColor(config, 'loginBtnBorderColor');
    if (loginBorderColor !== null) {
      theme.setLoginBtnBorderColor(loginBorderColor);
    }
    const loginBorderWidth = this.mapLength(config, 'loginBtnBorderWidth');
    if (loginBorderWidth !== null) {
      theme.setLoginBtnBorderWidth(loginBorderWidth);
    }
    const disabledTextColor = this.mapColor(config, 'loginBtnDisabledTextColor');
    if (disabledTextColor !== null) {
      theme.setLoginBtnDisabledTextColor(disabledTextColor);
    }
    const disabledColor = this.mapColor(config, 'loginBtnDisabledColor');
    if (disabledColor !== null) {
      theme.setLoginBtnDisabledColor(disabledColor);
    }
    const disabledBorderColor = this.mapColor(config, 'loginBtnDisabledBorderColor');
    if (disabledBorderColor !== null) {
      theme.setLoginBtnDisabledBorderColor(disabledBorderColor);
    }
    const disabledBorderWidth = this.mapLength(config, 'loginBtnDisabledBorderWidth');
    if (disabledBorderWidth !== null) {
      theme.setLoginBtnDisabledBorderWidth(disabledBorderWidth);
    }
    const disabledImgPath = this.mapString(config, 'loginBtnDisabledImgPath');
    if (disabledImgPath !== null) {
      theme.setLoginBtnDisabledImgPath(disabledImgPath);
    }

    const checkboxWidth = this.mapLength(config, 'checkBoxWidth');
    const checkboxHeight = this.mapLength(config, 'checkBoxHeight');
    if (checkboxWidth !== null && checkboxHeight !== null) {
      theme.setCheckBox(checkboxWidth, checkboxHeight);
    }
    const checkboxMargin = this.mapMargin(config, 'checkBoxMargin');
    if (checkboxMargin !== null) {
      theme.setCheckBoxMargin(checkboxMargin);
    }
    const checkboxAlign = this.mapAlignRuleOption(config, 'checkBoxAlignRuleOption');
    if (checkboxAlign !== null) {
      theme.setCheckBoxAlignRuleOption(checkboxAlign);
    }
    const checkboxShape = this.mapCheckBoxShape(config);
    if (checkboxShape !== null) {
      theme.setCheckBoxShape(checkboxShape);
    }
    if (this.mapBool(config, 'checkBoxChangeListener') === true) {
      theme.setCheckBoxChangeListener({
        onCheckedChanged: (checked: boolean) => {
          let data: ConfigMap = {};
          data['checked'] = checked;
          this.emitOhosThemeEvent('checkBoxChanged', data);
        }
      });
    }

    const clauseState = this.mapBool(config, 'clauseState');
    if (clauseState !== null) {
      theme.setClauseState(clauseState);
    }
    const clauses = this.buildClauses(config);
    if (clauses.length > 0) {
      theme.setClauses(clauses);
    }

    const clauseMargin = this.mapMargin(config, 'clauseMargin');
    if (clauseMargin !== null) {
      theme.setClauseMargin(clauseMargin);
    }
    const clauseAlign = this.mapAlignRuleOption(config, 'clauseAlignRuleOption');
    if (clauseAlign !== null) {
      theme.setClauseAlignRuleOption(clauseAlign);
    }

    const navTextSize = this.mapNumber(config, 'navTextSize');
    if (navTextSize !== null) {
      theme.setNavTextSize(navTextSize);
    }
    const navTextColor = this.mapColor(config, 'navTextColor');
    if (navTextColor !== null) {
      theme.setNavTextColor(navTextColor);
    }
    const navColor = this.mapColor(config, 'navColor');
    if (navColor !== null) {
      theme.setNavColor(navColor);
    }
    const clauseNavMarginTop = this.mapNumber(config, 'clauseNavMarginTop');
    if (clauseNavMarginTop !== null) {
      theme.setClauseNavMarginTop(clauseNavMarginTop);
    }
    const webDomStorage = this.mapBool(config, 'webDomStorage');
    if (webDomStorage !== null) {
      theme.setWebDomStorage(webDomStorage);
    }

    if (this.mapBool(config, 'useDialogMode') === true) {
      const options = this.mapDialogOptions(config) ?? {};
      theme.useDialogMode(options);
    }
    if (this.mapBool(config, 'backPressedListener') === true) {
      theme.setBackPressedListener({
        onBackPressed: () => {
          const autoClose = this.mapBool(config, 'backPressedAutoClose') ?? true;
          let data: ConfigMap = {};
          data['autoClose'] = autoClose;
          this.emitOhosThemeEvent('backPressed', data);
          if (autoClose) {
            FlyVerify.closeAuthLoginPage();
          }
        }
      });
    }

    const compatFullScreen = this.mapBool(config, 'compatFullScreen');
    if (compatFullScreen !== null) {
      theme.setCompatFullScreen(compatFullScreen);
    }

    return theme;
  }

  private buildClauses(config: ConfigMap): Array<ClauseSpan> {
    let clauses: Array<ClauseSpan> = [];
    const value = config['clauses'];
    if (!Array.isArray(value)) {
      return clauses;
    }
    const arr = value as Array<ConfigValue>;
    arr.forEach((item: ConfigValue) => {
      if (item === null || typeof item !== 'object') {
        return;
      }
      const spanMap = item as ConfigMap;
      const text: string = this.mapString(spanMap, 'text') ?? '';
      const type: number = this.mapClauseType(this.mapString(spanMap, 'type'));
      const color: ResourceColor = this.mapColor(spanMap, 'fontColor') ?? '#8A98AC';
      const fontSize: number = this.mapNumber(spanMap, 'fontSize') ?? 12;
      const span = this.createClause(text, type, color, fontSize);
      const url: string | null = this.mapString(spanMap, 'url');
      if (url !== null) {
        span.url = url;
      }
      clauses.push(span);
    });
    return clauses;
  }

  private mapClauseType(type: string | null): number {
    switch (type) {
      case 'operatorProtocol':
        return ClauseSpan.OPERATOR_PROTOCOL;
      case 'customProtocol':
        return ClauseSpan.CUSTOM_PROTOCOL;
      case 'normal':
      default:
        return ClauseSpan.NORMAL;
    }
  }

  private createClause(text: string, type: number, color: ResourceColor, fontSize: number): ClauseSpan {
    let span = new ClauseSpan();
    span.text = text;
    span.type = type;
    span.fontColor = color;
    span.fontSize = fontSize;
    return span;
  }

  private mapMargin(config: ConfigMap, key: string): Margin | null {
    const map = this.mapObject(config, key);
    return map === null ? null : map as Margin;
  }

  private mapAlignRuleOption(config: ConfigMap, key: string): AlignRuleOption | null {
    const map = this.mapObject(config, key);
    return map === null ? null : map as AlignRuleOption;
  }

  private mapSystemBarProperties(config: ConfigMap): window.SystemBarProperties | null {
    const map = this.mapObject(config, 'systemBarProperties');
    return map === null ? null : map as window.SystemBarProperties;
  }

  private mapDialogOptions(config: ConfigMap): DialogOptions | null {
    const map = this.mapObject(config, 'dialogOptions');
    return map === null ? null : map as DialogOptions;
  }

  private getMap(call: MethodCall, key: string): ConfigMap | null {
    const value: Object | null = call.argument(key) as Object | null;
    if (value !== null && typeof value === 'object') {
      return value as ConfigMap;
    }
    return null;
  }

  private mapObject(config: ConfigMap, key: string): ConfigMap | null {
    const value = config[key];
    if (value !== null && typeof value === 'object') {
      return value as ConfigMap;
    }
    return null;
  }

  private emitOhosThemeEvent(event: string, data: ConfigMap | null): void {
    if (this.channel === null) {
      return;
    }
    const payload: OhosThemeEvent = {
      event: event,
      data: data
    };
    this.channel.invokeMethod('onOhosThemeEvent', payload);
  }

  private mapString(config: ConfigMap, key: string): string | null {
    const value = config[key];
    if (typeof value === 'string' && value.length > 0) {
      return value;
    }
    return null;
  }

  private mapNumber(config: ConfigMap, key: string): number | null {
    const value = config[key];
    if (typeof value === 'number') {
      return value;
    }
    return null;
  }

  private mapLength(config: ConfigMap, key: string): Length | null {
    const value = this.mapNumber(config, key);
    return value !== null ? value : null;
  }

  private mapBool(config: ConfigMap, key: string): boolean | null {
    const value = config[key];
    if (typeof value === 'boolean') {
      return value;
    }
    return null;
  }

  private mapCheckBoxShape(config: ConfigMap): CheckBoxShape | null {
    const value = this.mapNumber(config, 'checkBoxShape') ?? this.mapNumber(config, 'checkboxShape');
    if (value === null) {
      return null;
    }
    switch (value) {
      case 0:
        return CheckBoxShape.CIRCLE;
      case 1:
        return CheckBoxShape.ROUNDED_SQUARE;
      default:
        return CheckBoxShape.CIRCLE;
    }
  }

  private mapColor(config: ConfigMap, key: string): ResourceColor | null {
    const value = this.mapString(config, key);
    if (value === null) {
      return null;
    }
    if (value.startsWith('#')) {
      return value;
    }
    if (/^[0-9a-fA-F]{6,8}$/.test(value)) {
      return `#${value}`;
    }
    switch (value) {
      case 'white':
        return '#FFFFFF';
      case 'black':
        return '#000000';
      case 'teal_200':
        return '#80CBC4';
      case 'teal_700':
        return '#00796B';
      case 'purple_200':
        return '#CE93D8';
      case 'purple_500':
        return '#9C27B0';
      case 'purple_700':
        return '#7B1FA2';
      default:
        return null;
    }
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
