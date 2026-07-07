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

鸿蒙平台需要使用支持 HarmonyOS 的 Flutter SDK，例如 `flutter_flutter`。

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
// example/ohos/entry/oh-package.json5
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

#### 3. 入口能力与 Flutter Page

`EntryAbility.ets`：

```ets
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```

`pages/Index.ets` 用 `FlutterPage` 渲染 Flutter UI 即可：

```ets
import { FlutterPage } from '@ohos/flutter_ohos';

@Entry(storage)
@Component
struct Index {
  @LocalStorageLink('viewId') viewId: string = '';

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }
}
```

#### 4. 权限

`example/ohos/entry/src/main/module.json5` 中需声明：

```jsonc
"requestPermissions": [
  { "name": "ohos.permission.GET_NETWORK_INFO" },
  { "name": "ohos.permission.INTERNET" }
]
```

### 预取号与取号

秒验主要功能调用流程：

```dart
import 'package:flyverify_plugin/flyverify.dart';

// 1. 注册 SDK
await Flyverify.registerSDK(appKey: '你的 appKey', appSecret: '你的 appSecret');

// 2. 提交隐私协议授权
await Flyverify.submitPrivacyGrantResult(true, null);

// 3. 预取号（建议在拉起授权页之前调用，以提高登录成功率）
Flyverify.preVerify(result: (Map? ret, Map? err) {
  if (err == null && ret != null) {
    // 预取号成功，可继续拉起授权页
  }
});

// 4. 一键登录（拉起授权页 → 运营商取号 → 返回结果）
await Flyverify.verify(
  FlyVerifyUIConfig(),
  null,
  null,
  (ret, err) {
    if (ret != null) {
      // 取号成功，ret 中含手机号 / 运营商 / token
    } else if (err != null) {
      // 取号失败或用户取消
    }
  },
  null,
  null,
);

```

> 本版本专注于秒验主链路：预取号、取号。鸿蒙主题配置 API（`FlyVerifyUIConfigOhos` / 主题事件回调）将在后续版本提供。

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
