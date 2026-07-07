# FlyVerify Flutter 插件

秒验 Flutter 插件，支持 Android、iOS、HarmonyOS。

## 安装

发布版本：

```yaml
dependencies:
  flyverify_plugin: ^1.1.9
```

本地调试：

```yaml
dependencies:
  flyverify_plugin:
    path: ../zztflyverify
```

## 初始化

```dart
import 'dart:io';
import 'package:flyverify_plugin/flyverify.dart';

Future<void> initFlyVerify() async {
  await Flyverify.registerSDK(
    appKey: '你的 appKey',
    appSecret: Platform.isIOS ? '你的 iOS appSecret' : '你的 Android/HarmonyOS appSecret',
  );
  await Flyverify.submitPrivacyGrantResult(true, null);
}
```

## HarmonyOS 鸿蒙使用

鸿蒙平台需要使用支持 HarmonyOS 的 Flutter SDK，例如 `flutter_flutter`。鸿蒙主题配置独立使用 `FlyVerifyUIConfigOhos`，字段按鸿蒙原生 `ThemeConfig` 命名，不复用 Android 的 `FlyVerifyUIConfigAndroid`。

### 鸿蒙 Flutter 环境

| 工具 | 推荐版本 | 备注 |
|---|---|---|
| Flutter (ohos fork) | `flutter_flutter` 3.x（含 ohos 支持） | DevEco Studio 内部署 |
| HarmonyOS SDK | `5.0.0(12)` 及以上 | `compatibleSdkVersion: 5.0.0(12)` |
| DevEco Studio | 5.0+ | 调试与签名 |
| JDK | 17 | hvigor 要求 |

环境变量准备：

```powershell
# 示例：harmony_flutter 工具链
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat --version
```

> 用户侧的 Flutter SDK 路径需在 `PATH` 或脚本中明确，DevEco Studio 默认集成。

### 在鸿蒙工程中集成 flyverify_plugin

#### 1. 在 `pubspec.yaml` 中声明

```yaml
dependencies:
  flyverify_plugin:
    path: ../zztflyverify
```

#### 2. 在鸿蒙 entry 中引入插件 HAR

源码 module 集成（开发态）：

```jsonc
{
  "dependencies": {
    "flyverify_plugin": "file:../../../zztflyverify/ohos"
  }
}
```

`example/ohos/build-profile.json5` 注册 module：

```jsonc
{
  "modules": [
    { "name": "entry", "srcPath": "./entry", "targets": [{ "name": "default", "applyToProducts": ["default"] }] },
    { "name": "flyverify_plugin", "srcPath": "../../../zztflyverify/ohos", "targets": [{ "name": "default", "applyToProducts": ["default"] }] }
  ]
}
```

#### 3. 修改 `Index.ets`，确保 `eventHub` 监听返回事件

鸿蒙侧默认会把"返回键"事件转发到 Flutter：

```ets
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = ''

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
```

> Flutter 端消费 `EVENT_BACK_PRESS` 时请调用 `Navigator.pop`；不消费则本事件被吞，不会触发 OS 默认 back。

#### 4. 权限

`example/ohos/entry/src/main/module.json5` 中已声明：

```jsonc
"requestPermissions": [
  { "name": "ohos.permission.GET_NETWORK_INFO" },
  { "name": "ohos.permission.INTERNET" }
]
```

### 设置鸿蒙主题

```dart
import 'package:flyverify_plugin/flyverify.dart';
import 'package:flyverify_plugin/flyverify_UIConfig.dart';

FlyVerifyUIConfigOhos buildOhosTheme() {
  final theme = FlyVerifyUIConfigOhos();
  theme.navColor = '#0B6B61';
  theme.navTextColor = '#FFFFFF';
  theme.navTextSize = 16;

  theme.numberColor = '#111827';
  theme.numberSize = 42;
  theme.numberMargin = {'top': 120};

  theme.logBtnText = '本机号码一键登录';
  theme.loginBtnTextColor = '#FFFFFF';
  theme.loginBtnTextSize = 46;
  theme.loginBtnColor = '#0EA5A4';
  theme.loginBtnWidth = 320;
  theme.loginBtnHeight = 48;
  theme.loginBtnMargin = {'top': 220};

  theme.checkBoxWidth = 18;
  theme.checkBoxHeight = 18;
  theme.checkBoxMargin = {'left': 24, 'bottom': 36};
  theme.clauses = [
    FlyVerifyOhosClauseSpan(
      text: '登录即同意',
      type: FlyVerifyOhosClauseSpan.normal,
      fontColor: '#6B7280',
      fontSize: 12,
    ),
    FlyVerifyOhosClauseSpan(
      type: FlyVerifyOhosClauseSpan.operatorProtocol,
      fontColor: '#0EA5A4',
      fontSize: 12,
    ),
    FlyVerifyOhosClauseSpan(
      text: '和',
      type: FlyVerifyOhosClauseSpan.normal,
      fontColor: '#6B7280',
      fontSize: 12,
    ),
    FlyVerifyOhosClauseSpan(
      text: 'Mob服务协议',
      type: FlyVerifyOhosClauseSpan.customProtocol,
      fontColor: '#0EA5A4',
      fontSize: 12,
      url: 'https://www.mob.com/about/policy',
    ),
  ];
  return theme;
}
```

拉起登录验证时传入主题：

```dart
final config = FlyVerifyUIConfig();
config.ohosThemeConfig = buildOhosTheme();

Flyverify.autoFinishOAuthPage(flag: true);
Flyverify.verify(
  config,
  null,
  null,
  (ret, err) {
    if (ret != null) {
      print('verify success: $ret');
    } else {
      print('verify failed: $err');
    }
  },
  null,
  null,
);
```

### 鸿蒙主题回调

原生鸿蒙 `ThemeConfig` 中的部分 listener 已通过事件桥转给 Dart：

```dart
Flyverify.setOhosThemeEventListener((event, data) {
  print('Ohos theme event: $event, data: $data');
});
```

当前事件名：

```text
checkedLoginStart
checkedLoginComplete
uncheckedLogin
checkBoxChanged
backPressed
```

其中 `uncheckedLoginListener` 和 `backPressedListener` 需要原生侧同步返回处理结果，Flutter 通过配置项控制默认行为：

```dart
theme.uncheckedLoginListener = true;
theme.uncheckedLoginAutoCheck = true;
theme.backPressedListener = true;
theme.backPressedAutoClose = true;
```

### 拉起授权页模式

鸿蒙 SDK 内部根据 `theme.useDialogMode` 决定是走 `router.pushNamedRoute` 跳 `opAuthPage`，还是走 `OpenCustomAuthDialog.openDialog()` 弹窗。**`flyverify_plugin` 在 dart 层自动将 `config.ohosThemeConfig!.useDialogMode = true`**——这是为了避免 demo 工程未在 `pages/main_pages.json` 注册 `opAuthPage` 路由时，按返回键系统直接退到桌面。

如果你已显式注册授权页路由，希望回到 router 模式，可以：

```dart
config.ohosThemeConfig!.useDialogMode = false;
```

> 此时务必在你的鸿蒙工程的 `pages/main_pages.json` 与 `module.json5.pages` 中注册名为 `opAuthPage` 的 `@Entry` Page，否则按返回键会被系统当作"无路由可退，回到桌面"。

### 构建 HAP

```powershell
cd example
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat pub get
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat build hap
```

构建产物位于 `example/ohos/build/default/outputs/default/`。

## 技术支持

```text
服务电话: 400-685-2216
QQ: 4006852216
电子邮箱: support@mob.com
市场合作: 021-54623100
```
