# 鸿蒙 Flutter 插件验证与打包

## 环境要求

- 鸿蒙 Flutter SDK：`D:\Software\harmony_flutter\flutter_flutter`
- DevEco Studio / HarmonyOS SDK：本机验证使用 `C:\Program Files\Huawei\DevEco Studio\sdk`
- DevEco 工具链：需要能访问 `ohpm` 和 `hvigorw`

普通 Flutter SDK 可以继续用于 Android/iOS 和 Dart 层检查，但不能构建 HAP。构建鸿蒙产物必须使用鸿蒙 Flutter SDK。

## 当前会话环境变量

如果没有配置全局环境变量，可以在当前 PowerShell 窗口临时设置：

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:HOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:PATH='C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin;C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin;' + $env:PATH
```

如果构建报 `Invalid value of 'DEVECO_SDK_HOME'`，修正变量后先停止 hvigor daemon：

```powershell
hvigorw --stop-daemon
```

## 插件验证

在插件根目录执行：

```powershell
cd E:\flutterProject\flyverify_normal_flutter\zztflyverify
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' pub get
```

Dart 层检查可以使用普通 Flutter：

```powershell
flutter analyze lib test
flutter test
```

`flutter pub publish --dry-run` 需要在准备发布、工作区干净时执行。当前分支有迁移改动时，dry-run 会提示 git dirty，这是正常的发布前检查提示。

## 插件 HAR 构建流程

作为 Flutter 插件开发者，鸿蒙侧插件代码放在插件根目录的 `ohos` 目录下。当前插件 HAR 不需要手动拷到 example，执行 example 的 HAP 构建时，鸿蒙 Flutter SDK 会自动构建插件 HAR，并把它放到 example 宿主可消费的位置。

执行：

```powershell
cd E:\flutterProject\flyverify_normal_flutter\zztflyverify\example
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' pub get
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' build hap
```

构建过程中会产出插件 HAR：

```text
E:\flutterProject\flyverify_normal_flutter\zztflyverify\ohos\build\default\outputs\default\flyverify_plugin.har
```

同时会复制到 example 鸿蒙宿主的依赖目录：

```text
E:\flutterProject\flyverify_normal_flutter\zztflyverify\example\ohos\har\flyverify_plugin.har
```

`example\ohos\oh-package.json5` 里通过 overrides 使用这个本地插件 HAR：

```json5
"flyverify_plugin": "file:./har/flyverify_plugin.har"
```

因此插件开发调试的主流程是：修改 `ohos` 插件桥接代码，重新执行 `example` 的 `flutter build hap`，然后安装生成的 HAP 验证插件行为。

## Example HAP 构建

当前仓库已经包含 `example\ohos`，正常情况下不需要每次重新创建。直接执行：

```powershell
cd E:\flutterProject\flyverify_normal_flutter\zztflyverify\example
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' pub get
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' build hap
```

如果以后重新生成 example 鸿蒙宿主，需要带上 `--org`，否则当前 example 里 Android/iOS 历史包名不一致会导致 `Ambiguous organization`：

```powershell
cd E:\flutterProject\flyverify_normal_flutter\zztflyverify\example
& 'D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat' create --platforms=ohos --org cn.fly.verify .
```

## 构建产物与签名

`example\ohos\build-profile.json5` 已配置 `signingConfigs.debug`，证书文件位于：

```text
example\ohos\DebugSigning
```

本机已验证可以使用 debug 签名配置构建 HAP。构建产物位于：

```text
example\ohos\entry\build\default\outputs\default
```

签名后的 HAP 文件是：

```text
example\ohos\entry\build\default\outputs\default\entry-default-signed.hap
```

当前 debug profile 绑定的包名是 `cn.open.org.hosnext.demo`，因此 `example\ohos\AppScope\app.json5` 的 `bundleName` 需要与它保持一致。若换用新的 profile，需要同步调整 `bundleName` 或重新生成匹配该包名的签名 profile。

如果需要切换正式签名，请在 `signingConfigs` 中增加 release 配置，并把 product 的 `signingConfig` 改为对应名称。

## 依赖策略

当前处于本地调试阶段，插件鸿蒙侧依赖配置为：

```json5
"@zztsdk/zztcore": "*",
"@zztsdk/flyverify": "file:verifyhos-signed.har"
```

其中 `verifyhos-signed.har` 放在插件根目录的 `ohos` 下，供本地调试使用。

如果后续切到线上依赖，把 `ohos\oh-package.json5` 中的 `@zztsdk/flyverify` 改为：

```json5
"@zztsdk/flyverify": "*"
```

`*` 表示安装依赖时让 OHPM 解析线上可用版本。为了保持“每次取最新”的策略，不提交 `oh-package-lock.json5` 和 `oh_modules`。

当前线上解析结果中，`@zztsdk/flyverify` 解析到 `1.1.9`，`@zztsdk/zztcore` 解析到 `2026.5.6`。

## 注意事项

- `example\ohos\build-profile.json5` 已开启 `useNormalizedOHMUrl`，否则在线依赖中的 Bytecode HAR 会报 `Bytecode HARs ... not supported when useNormalizedOHMUrl is not true`。
- 当前鸿蒙 Flutter SDK 是 `Flutter 3.7.12-ohos-1.0.4 / Dart 2.19.6`，因此主包 Dart 依赖使用范围约束来兼容鸿蒙 SDK 和 pub.dev Flutter SDK。
