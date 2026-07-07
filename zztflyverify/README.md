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

### 插件开发者本地验证

在当前插件项目根目录执行：

```powershell
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat pub get
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat analyze lib example/lib
```

`analyze` 用于检查 Dart 层 API 和 example 是否有语法错误。当前项目存在一些历史 lint/info，非鸿蒙主题功能错误。

### 编译鸿蒙插件 HAR

当前插件的 `ohos` 目录不是完整 hvigor workspace，没有内置 `hvigorw.bat`。本地验证时通过 example 的鸿蒙工程构建，Flutter 会解析本地 path 插件并自动编译 HAR：

```powershell
cd example
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat build hap
```

产物位置：

```text
ohos\build\default\outputs\default\flyverify_plugin.har
example\ohos\har\flyverify_plugin.har
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

### 构建 HAP

```powershell
cd example
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat pub get
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat build hap
```


## 技术支持

```text
服务电话: 400-685-2216
QQ: 4006852216
电子邮箱: support@mob.com
市场合作: 021-54623100
```
