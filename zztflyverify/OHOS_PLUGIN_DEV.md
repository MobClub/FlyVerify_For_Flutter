# flyverify_plugin 鸿蒙 Flutter 插件开发指南

本文档面向 `flyverify_plugin` 鸿蒙端的**插件维护者**，介绍：

- 鸿蒙插件目录结构与各文件职责
- 本地构建 / 调试 / 重打包 HAR 的步骤
- 依赖模式（HAR 依赖 vs 源码 module 依赖）
- 主题（ThemeConfig）字段映射与协议
- EventChannel 协议
- 与参考实现 `E:\HarmonyProject\secverifyforhosnext` 的对照方法
- 版本号规约、CHANGELOG 模板
- 常见问题与排查

> 用户层面的集成文档参考 [README.md](README.md)。

## 1. 插件目录结构

```
zztflyverify/                        ← pubspec name = flyverify_plugin
├── lib/                              ← Dart 侧入口
│   ├── flyverify.dart                ← MethodChannel 主入口
│   ├── flyverify_defines.dart        ← enum、typedef
│   ├── flyverify_UIConfig.dart       ← FlyVerifyUIConfig / Android / iOS / Ohos
│   └── flyverify_UIConfig.g.dart     ← build_runner 自动生成
├── ohos/                             ← 鸿蒙插件 HAR 源码
│   ├── Index.ets                     ← plugin 入口（@ohos/flutter_ohos 解析入口）
│   ├── oh-package.json5              ← modelVersion=5.0.0; deps: flutter_ohos, @zztsdk/zztcore, @zztsdk/flyverify
│   ├── build-profile.json5           ← apiType=stageMode; targets=default
│   ├── hvigorfile.ts                 ← HAR 构建脚本
│   ├── src/main/module.json5         ← plugin 元信息
│   └── src/main/ets/
│       └── FlyverifyPlugin.ets       ← 唯一实现：MethodChannel 路由、ThemeConfig 桥、UI 桥
└── pubspec.yaml                      ← name: flyverify_plugin; version: 1.0.5
```

### 各文件职责

| 文件 | 角色 | 注意事项 |
|---|---|---|
| `Index.ets` | plugin 入口（`main` 字段） | 必须 export `FlyverifyPlugin` 类 |
| `src/main/ets/FlyverifyPlugin.ets` | 全部业务逻辑 | **唯一实现文件**，修改均在此 |
| `oh-package.json5` | 依赖声明 | 必须有 `@ohos/flutter_ohos`、`@zztsdk/zztcore`、`@zztsdk/flyverify` |
| `build-profile.json5` | 构建配置 | `apiType: stageMode` |
| `src/main/module.json5` | 模块声明 | `type: har`，权限：`GET_NETWORK_INFO`、`INTERNET` |

## 2. 本地开发

### 2.1 工具链

| 工具 | 推荐版本 | 备注 |
|---|---|---|
| Flutter (ohos fork) | `flutter_flutter` 3.x | 含 ohos 支持 |
| DevEco Studio | 5.0+ | 内置 HarmonyOS SDK 5.0.0(12)、JDK 17 |
| HarmonyOS SDK | API 12+ | `ohos/Index.ets` 的 compatibility |
| JDK | 17 | hvigor 要求 |

### 2.2 校验 Dart 代码

```powershell
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat pub get
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat analyze lib example/lib
```

`analyze` 是纯静态检查；当前项目含若干历史 `info`，非阻塞，按错误优先级处理。

### 2.3 编译插件 HAR（推荐使用 example 工程触发）

直接 `cd ohos && hvigorw assembleHar` 会因为没装 `@ohos/flutter_ohos.har` 而失败。最稳的路径是走 example 工程：

```powershell
cd example
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat pub get
D:\Software\harmony_flutter\flutter_flutter\bin\flutter.bat build hap
```

产物：

```text
example/ohos/entry/build/default/outputs/default/entry-default-signed.hap
example/ohos/build/default/outputs/default/flyverify_plugin.har       ← 插件 HAR
example/ohos/har/flyverify_plugin.har                                 ← 拷贝到 entry 用
```

### 2.4 源码 module 模式（开发态）

修改 `ohos/src/main/ets/FlyverifyPlugin.ets` 后希望跳过 HAR 重建，直接热更新：

1. `example/ohos/entry/oh-package.json5`：

   ```jsonc
   {
     "dependencies": {
       "flyverify_plugin": "file:../../../zztflyverify/ohos"
     }
   }
   ```

2. `example/ohos/build-profile.json5`：

   ```jsonc
   {
     "modules": [
       { "name": "entry", "srcPath": "./entry", "targets": [{ "name": "default", "applyToProducts": ["default"] }] },
       { "name": "flyverify_plugin", "srcPath": "../../../zztflyverify/ohos", "targets": [{ "name": "default", "applyToProducts": ["default"] }] }
     ]
   }
   ```

3. `example/ohos/oh-package.json5` 同步 `overrides`：

   ```jsonc
   {
     "overrides": {
       "@ohos/flutter_ohos": "file:./har/flutter.har",
       "flyverify_plugin": "file:../../../zztflyverify/ohos",
       "@ohos/flutter_module": "file:./entry"
     }
   }
   ```

4. 删除 `example/ohos/har/flyverify_plugin.har`（避免覆盖源码 module）。

发布形态（HAR）：

- 用户侧 `entry/oh-package.json5` 改回 `"file:../har/flyverify_plugin.har"`；
- 同步 `overrides` 指 `file:./har/flyverify_plugin.har`；
- build 后产物 `cp` 到 `example/ohos/har/`。

## 3. MethodChannel 协议

插件唯一 channel 名：`plugins.zzt.flyverify/flyverify_plugin`（见 `FlyverifyPlugin.ets`）。

### 3.1 Method name 列表

```
verify
preVerify
submitPrivacyGrantResult
setAndroidPortraitLayout
setAndroidLandscapeLayout
setOhosTheme
finishOAuthPage / finishLoginVC
autoFinishOAuthPage
OtherOAuthPageCallBack
registerSDK
isVerifySupport
mobileAuthToken
mobileVerify
manualDismissLoginVC
manualDismissLoading
otherOAuthPageCallBack
```

> `setOhosTheme` 是 ohos 专属：上层业务用 `Flyverify.setOhosTheme(themeMap)` 单独下发主题，避免嵌套 HashMap 在 codec 中丢失。

### 3.2 参数协议（ohos 端 `verify` 通道）

```text
verify(name, { ohosThemeConfigJson: string })
ohosThemeConfigJson 是扁平主题 JSON 字符串（json.encode(themeMap)）
```

### 3.3 参数协议（ohos 端 `setOhosTheme` 通道）

```text
setOhosTheme(name, { ohosThemeConfigJson: string })
```

> 早期使用嵌套 `{'ohosThemeConfig': themeMap}`；**当前** 统一改为字符串 `ohosThemeConfigJson`，避开鸿蒙 MethodChannel codec 对嵌套 map 多类型混合的丢失问题。

## 4. 主题（ThemeConfig）字段映射

参考实现：[`E:\HarmonyProject\secverifyforhosnext\verifyhos\src\main\ets\verify\out\ui\ThemeConfig.ets`](file:///E:/HarmonyProject/secverifyforhosnext/verifyhos/src/main/ets/verify/out/ui/ThemeConfig.ets)。

`FlyverifyPlugin.ets#buildTheme` 是字段映射的唯一实现。字段对照：

| Dart 字段 | ohos ThemeConfig 方法 | ohs keys（flat） | 备注 |
|---|---|---|---|
| `navColor` | `setNavColor` | `navColor` | |
| `navTextColor` | `setNavTextColor` | `navTextColor` | |
| `navTextSize` | `setNavTextSize` | `navTextSize` | |
| `numberColor` | `setNumberColor` | `numberColor` | |
| `numberSize` | `setNumberSize` | `numberSize` | |
| `numberMargin` | `setNumberMargin` | `numberMargin` (`{top,left,right,bottom}`) | |
| `logBtnText` | `setLogBtnText` | `logBtnText` | 别名 `loginBtnText` 暂未支持 |
| `loginBtnTextColor` | `setLoginBtnTextColor` | `loginBtnTextColor` | |
| `loginBtnTextSize` | `setLoginBtnTextSize` | `loginBtnTextSize` | |
| `loginBtnColor` | `setLoginBtnColor` | `loginBtnColor` | |
| `loginBtnWidth` | `setLoginBtnWidth` | `loginBtnWidth` | |
| `loginBtnHeight` | `setLoginBtnHeight` | `loginBtnHeight` | |
| `loginBtnMargin` | `setLoginBtnMargin` | `loginBtnMargin` | |
| `checkBoxWidth` | `setCheckBox(checkBoxWidth, checkBoxHeight)` | `checkBoxWidth`、`checkBoxHeight` | |
| `clauses` | `setClauses` | `clauses: [ {text,type,fontColor,fontSize,url} ]` | type: 0 normal / 1 operatorProtocol / 2 customProtocol |
| `useDialogMode` | `useDialogMode` | `useDialogMode` | dart 层会在 verify 入口强制设为 true |
| `dialogOptions` | `setDialogOptions` | `dialogOptions` | |
| `systemBarProperties` | `setSystemBarProperties` | `systemBarProperties` | 内含 `statusBarColor, statusBarContentColor, navigationBarColor, navigationBarContentColor` |

### 4.1 主题传参坑点

- **嵌套 map 丢失**：ohos 端 MethodChannel codec 在多重嵌套 + 多类型混合时会丢字段，**务必**走 `ohosThemeConfigJson` 字符串。
- **未实现字段**：`setLoginPageComponent`、`setClauseComponent` 这两个 builder 类未实现（ArkUI builder 难以 MethodChannel 传递）。
- **未对齐字段名**：`systemBarProperties.statusBarContentColor` 应改为 ArkUI 标准（当前是自定义 `isStatusBarLightIcon`），参考实现已统一。

## 5. EventChannel 协议

channel 名：`plugins.zzt.flyverify/flyverify_plugin_event`。

事件名：

```
checkedLoginStart
checkedLoginComplete
uncheckedLogin
checkBoxChanged
backPressed
```

`uncheckedLoginListener` 和 `backPressedListener` 在原生侧同步调用，返回结果由 dart 端配置决定：

- `theme.uncheckedLoginAutoCheck = true`（默认）：自动放行
- `theme.uncheckedLoginAutoCheck = false`：等待 dart 端返回 `autoCheck` 数据
- `theme.backPressedAutoClose = true`（默认）：自动关闭
- `theme.backPressedAutoClose = false`：等待 dart 端返回 `autoClose` 数据

## 6. 路由 / 页面返回行为

参考实现 `AbstractOpeUI` 通过 `theme.getWindowMode()` 决定：

- `true` → 走 `OpenCustomAuthDialog.openDialog()` 弹窗
- `false`（默认）→ `router.pushNamedRoute({ name: 'opAuthPage', ... })`

**当前维护者注意**：flyverify_plugin HAR 不持有 page 注册表（pages 由 entry 拥有），所以**插件 dart 层在 verify 入口强制 `useDialogMode = true`**（参考 [flyverify.dart L183-L189](file:///e:/flutterProject/flyverify_normal_flutter/zztflyverify/lib/flyverify.dart#L183-L189)）。

如果用户希望走 router 路径，需在自己鸿蒙工程的 `entry/src/main/ets/pages/OpAuthPage.ets` 注册路由，并在 `main_pages.json` 与 `module.json5.pages` 中登记，然后调：

```dart
config.ohosThemeConfig!.useDialogMode = false;
Flyverify.verify(config, ...);
```

否则按返回键会被 OS 当作"无路由可退，回到桌面"。

## 7. 与参考实现的差异 / 待办

参考实现路径：`E:\HarmonyProject\secverifyforhosnext\verifyhos/src/main/ets/`。

未实现项：

1. `setLoginPageComponent`（自定义授权页组件）
2. `setClauseComponent`（自定义服务条款标题栏 view）
3. `systemBarProperties` 字段名与 ArkUI 标准对齐
4. `logBtnText` 缺 `loginBtnText` 别名
5. `checkBoxWidth / checkedWidth` 双键名别名

字段差异：参考实现的 ThemeConfig 提供更多 `setXxx`，构建 `authPage` 时这些 builder 全部加上。

## 8. 版本号规约

跟随 pub.dev 上的 semver。

- 当前 `pub.dev` 线上版本：`1.0.4`（2025-11 更新）
- 本地仓库当前版本：`1.0.5`（pubspec.yaml）

升级建议：

- bug 修复 → patch `+1`
- 新增字段 / 新增方法（向后兼容）→ minor `+1`
- 大改动或不兼容改动 → major `+1`

发版前务必：

1. 更新 `pubspec.yaml` 的 `version`
2. 同步 `ohos/oh-package.json5` 的 `version`
3. 在 `CHANGELOG.md` 加条目
4. `flutter analyze` 通过

## 9. CHANGELOG 模板

```markdown
## <version>

[<channel> 同步]

### Breaking
- _None_

### Added
- 新增 xxx（OOXXXX）：说明
- ohOs：新增 setXxx（OOXXXX）

### Fixed
- ohOs：xxx 在某场景下行为异常（OOXXXX）

### Removed
- _None_

### Notes
- 兼容老版本说明
```

OOXXXX 是 mob 内部 issue 号。

## 10. 常见问题

### 10.1 buildTheme keys= 空

鸿蒙端 MethodChannel codec 把嵌套 `Map<String, dynamic>` 吃了。解法：

- 走 `Flyverify.setOhosTheme(json)` 单独通道
- 字符串形式 `ohosThemeConfigJson` 下发
- ohos 端 `applyTheme` 已三段兼容：ohosThemeConfigJson 字符串 / 嵌套 ohosThemeConfig / 平铺

### 10.2 call.args={}

整个 args 被 codec 吞。检查：

1. 是否还在用嵌套 map？切到 `ohosThemeConfigJson` 字符串通道
2. 顶层是否混入多种类型 + 多 keys？尽量扁平化
3. 是否在 `setTheme` 之前 `setOhosTheme` 单独下发？入口已经处理

### 10.3 授权页无法显示 / 显示主题未生效

- 确认 `ohosThemeConfigJson` 进入 `applyTheme` 没有空（看日志）
- `setOhosTheme` 必须在 `verify` 之前调用
- 检查 `config.ohosThemeConfig.toJson()` keys 是否非空

### 10.4 按返回键回到桌面

- `useDialogMode` 是否被强制为 `true`？可在 dart 层覆盖
- 没有覆盖则不会走 router 模式，避免路径未注册问题
- 用户工程自己注册 `opAuthPage` 可切换回 router

### 10.5 编译报错 `Object/JSON.parse` ArkTS 严控

ArkTS 10505001 / 10605008：

- 不要写 `value as Array<Object>` 直接跨界
- 用 `e instanceof Error` 替代 `e as Error`
- `JSON.parse(str) as Object` 改成 `JSON.parse(str)`（编译器已推断返回 any）
- 私有字段访问用 `Record<string, Object>` 替代 `Map<string, Object>` 减少警告

## 11. 调试小技巧

- `console.log('FlyVerify', 'foo=' + x)` 是 ArkTS 默认打 tag 方式
- 调试期可在 `buildTheme` 起点打印 `Object.keys(config)` 查看实际 keys
- `applyTheme` 内已经做了三段兼容与 print 日志

## 12. 提交 / 发版 checklist

- [ ] `flutter analyze lib example/lib` 0 error
- [ ] `flutter build hap` 构建成功
- [ ] example demo 点登录按钮正常弹授权页 + 主题生效
- [ ] example demo 按返回键回到主页面（不是桌面）
- [ ] pubspec.yaml / oh-package.json5 / CHANGELOG.md 三处版本号对齐
- [ ] 与参考实现 `ThemeConfig` 字段对照完无遗漏（除已在"未实现项"列出的）
