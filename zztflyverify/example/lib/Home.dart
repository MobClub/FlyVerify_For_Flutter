import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flyverify_plugin/flyverify.dart';
import 'package:flyverify_plugin/flyverify_UIConfig.dart';

class Home extends StatefulWidget {
  const Home({Key? key}): super(key: key);

  @override
  _HomeState createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  // Properties
  bool _isSupport = false;
  late Map<String, String> _mobileAuthToken;

  @override
  void initState() {
    super.initState();
                Flyverify.toast('initState');
    //隐私协议
    if (Platform.isIOS){
        Flyverify.registerSDK(
            appKey: "moba6b6c6d6", appSecret: "b89d2427a3bc7ad1aea1e1e8c1d36bf3");
    }else{
     Flyverify.registerSDK(
                appKey: "3a2c2a977d3d2", appSecret: "b89d2427a3bc7ad1aea1e1e8c1d36bf3");
                Flyverify.toast('register');
    }
    _submitPrivacyStatus(true);
    Flyverify.preVerify(result: (Map? ret, Map? err) {
      if (err != null) {
        print('InitState PreVerify Failed: ${err.toString()}');
      }
    });
  }

  List<Widget> getWidgetList() {
    List<GridViewWidget> list = [
      GridViewWidget(GridViewWidgetMethodType.preVerify, '预登录请求'),
      GridViewWidget(GridViewWidgetMethodType.autoVerify, '登录验证_自动关闭'),
      GridViewWidget(GridViewWidgetMethodType.manualVerify, '登录验证_手动关闭'),
      GridViewWidget(GridViewWidgetMethodType.preMobileAuth, '本机认证_预请求'),
      GridViewWidget(GridViewWidgetMethodType.mobileAuthVerify, '本机认证'),
    ];
    return list.map((item) => getItemContainer(item)).toList();
  }

  Widget getItemContainer(GridViewWidget item) {
    return Container(
      alignment: Alignment.center,
      child: TextButton(
        child: new Text(item.itemName),
        onPressed: () {
          GridViewWidgetMethodType type = item.type;
          switch (type) {
            case GridViewWidgetMethodType.preVerify: {
                _preVerify(context);
            }
              break;
            case GridViewWidgetMethodType.autoVerify: {
              if (Platform.isIOS){
                FlyVerifyUIConfig config = _configIOSUIConfig();
                _verify(config: config);
              } else if (Platform.isAndroid){
                FlyVerifyUIConfig config = _configAndroidUIConfig();
                Flyverify.autoFinishOAuthPage(flag: true);
                _verify(config: config);
              }
            }
              break;
            case GridViewWidgetMethodType.manualVerify: {
              FlyVerifyUIConfig config = _configAndroidUIConfig();
              config.iOSConfig?.manualDismiss = true;
              if (Platform.isIOS){
                _verify(config: config);
              } else if (Platform.isAndroid){
                Flyverify.autoFinishOAuthPage(flag: false);
                _verify(config: config);
              }
            }
              break;
            case GridViewWidgetMethodType.preMobileAuth: {
              _mobileAuth(context);
            }
              break;
            case GridViewWidgetMethodType.mobileAuthVerify: {
              _showMobileVerifyAlert();
            }
              break;
            break;
          }
        },
        // color: Colors.white,
      ),
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('FlyVerify Demo'),
      ),
      body: Center(
        child: GridView.count(
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 30.0,
          padding: EdgeInsets.all(10.0),
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          children: getWidgetList(),
        ),
      ),
    );
  }

  /// Private Methods
  Future<void> _FlyverifySupport() async {
    _isSupport = (await Flyverify.isVerifySupport)!;
  }

  void _submitPrivacyStatus(bool grantResult){
    Flyverify.submitPrivacyGrantResult(grantResult, null);
  }

  void _preVerify(BuildContext context) {
    Flyverify.preVerify(result: (Map? ret, Map? err) {
      if (ret != null && err == null) {
        // 显示预取号信息
        String retDetail = ret.toString();
        _showAlert(retDetail);
      } else if (err != null) {
        String errDetail = err.toString();
        _showAlert(errDetail);
      } else {
        _showAlert('预取号失败!');
      }
    });
  }

  ///android 授权页面监听
  void _otherOAuthPageCallBack(BuildContext context){
    Flyverify.otherOAuthPageCallBack((ret,err){
      if (ret !=  null && ret.containsKey("ret")){
        //其他登陆
      }
    });
  }

  void _mobileAuth(BuildContext context) {
    Flyverify.mobileAuthToken(timeout: 5.0, result: (Map? ret, Map? err) {
      if (ret != null && err == null) {
        // 显示本机认证Token信息
        String retDetail = ret.toString();
        if (retDetail.length != 0
            && retDetail.contains('token')
            && retDetail.contains('opToken')
            && retDetail.contains('operator')) {
          // 结果检验成功，进行本地设置
          _mobileAuthToken = Map.from(ret);
          _showAlert(_mobileAuthToken.toString());
        } else {
          _showAlert('请求本机认证Token失败 $retDetail');
        }

        print('Request Mobile Auth Token Info: $retDetail');
      } else if (err != null) {
        String errDetail = err.toString();
        _showAlert(errDetail);
      } else {
        _showAlert('请求本机认证Token失败');
      }
    });
  }

  void _verify({required FlyVerifyUIConfig config}) {
    Flyverify.verify(config,
            (rt, err) {
              if (err != null) {
                // 拉起授权页面失败
                _showAlert(err.toString());
              } else {
                print('Open Auth Page Result: ${rt.toString()}');
              }
            },
            (rt, err) {
              if (err != null) {
                _showAlert(err.toString());
              }
            },
            (rt, err) {
              if ((config.iOSConfig!.manualDismiss)) {
                Flyverify.manualDismissLoading();
                Flyverify.manualDismissLoginVC(flag: true).then((value) {
                  print('Manual Dismiss Loading VC Success');
                });
              }
              // 登录验证结果回调
              if (rt != null && err == null) {
                String resultStr = rt.toString();
                if (resultStr.length != 0
                    && resultStr.contains('token')
                    && resultStr.contains('opToken')
                    && resultStr.contains('operator')) {
                    login(rt);
                } else {
                  _showAlert('登录验证失败 $resultStr');
                }
              } else if (err != null) {
                _showAlert(err.toString());
              } else {
                _showAlert('登录验证失败');
              }
            },
            (rt, err) {
              if (rt != null && err == null) {
                // 自定义控件点击事件结果回调
                print("自定义控件点击事件结果回调:" + rt.toString() + err.toString());
                Flyverify.toast("点击"+rt.toString());
              }
            },
            (rt, err) {
              if (rt != null && err == null) {
                String resultStr = rt['ret'].toString();
                if (resultStr.length != 0) {
                  if (resultStr.contains('onOtherLogin')) {
                    _showAlert('其他方式登录');
                  } else if (resultStr.contains('onUserCanceled')) {
                    _showAlert('用户取消登录');
                  } else {
                    if (resultStr.contains('token')
                        && resultStr.contains('opToken')
                        && resultStr.contains('operator')) {
                        login(rt['ret']);
                    }
                  }
                }
              } else {
                if (err != null){
                  _showAlert('取号失败 ${err['err'].toString()}');
                }
              }
            });
  }

  void _mobileVerify(String phoneNum, BuildContext context) {
    if (phoneNum == null || phoneNum.length == 0) {
      _showAlert('本机认证手机号码不能为空');
      return;
    }

    if (_mobileAuthToken == null) {
      _showAlert('进行本机认证操作前，请先请求Token');
      return;
    }
    Flyverify.mobileVerify(phoneNum: phoneNum, tokenInfo: _mobileAuthToken, result: (Map? ret, Map? err) {
      // 本机认证结果处理
          if (ret != null && err == null) {
            String resultStr = ret.toString();
            if (resultStr.length != 0 &&
                resultStr.contains('isValid') &&
                resultStr.contains('valid')) {
              // 结果检验成功，进行网络请求
              _showAlert(resultStr);
            } else {
              _showAlert('本机认证失败 $resultStr');
            }
          } else if (err != null) {
            _showAlert(err.toString());
          } else {
            _showAlert('本机认证失败');
          }
    });
  }

  FlyVerifyUIConfig _configUIConfig() {
    FlyVerifyUIConfig config = FlyVerifyUIConfig();
    return config;
  }
  FlyVerifyUIConfig _configAndroidUIConfig() {
    FlyVerifyUIConfig config = FlyVerifyUIConfig();
     _customizeAndroidUiExample(config);
    return config;
  }

  void _customizeAndroidUiExample(FlyVerifyUIConfig config){
    //portrait
//标题栏
    config.androidPortraitConfig?.navColorIdName="teal_200";//this color resource should put in the colors.xml in android project
    config.androidPortraitConfig?.navTextIdName="one_key_login";//this string  should put in the strings.xml in android project
    config.androidPortraitConfig?.navTextColorIdName="white";
    config.androidPortraitConfig?.navHidden = false;
    config.androidPortraitConfig?.navTransparent = true;//默认是true
    config.androidPortraitConfig?.navCloseImgHidden = false;
    config.androidPortraitConfig?.navTextSize = 15;
    config.androidPortraitConfig?.navCloseImgPath='close.png';//this image should put in the assets package in android project
    // config.androidPortraitConfig.navCloseImgWidth=15;
    // config.androidPortraitConfig.navCloseImgHeight=15;//标题栏的高度是自适应这个图片的高度的
    // config.androidPortraitConfig.navCloseImgOffsetX=10;
    // config.androidPortraitConfig.navCloseImgOffsetRightX=10;
    // config.androidPortraitConfig.navCloseImgOffsetY=10;
    config.androidPortraitConfig?.navTextBold=false;
    // config.androidPortraitConfig.navCloseImgScaleType=ImageScaleType.CENTER_CROP;

//号码上方logo
    config.androidPortraitConfig?.logoImgPath = 'logo.png';
    config.androidPortraitConfig?.logoWidth = 80;
    config.androidPortraitConfig?.logoHeight = 80;
    // config.androidPortraitConfig.logoOffsetX = 20;
    // config.androidPortraitConfig.logoOffsetY = 60;
    // config.androidPortraitConfig.logoOffsetBottomY = 20;
    // config.androidPortraitConfig.logoOffsetRightX = 20;
    // config.androidPortraitConfig.logoAlignParentRight = true;
    // config.androidPortraitConfig.logoHidden = false;
//手机号码
    config.androidPortraitConfig?.numberColorIdName = 'teal_200';
    config.androidPortraitConfig?.numberSize = 20;
    // config.androidPortraitConfig.numberOffsetX = 20;
    // config.androidPortraitConfig.numberOffsetY = 20;
    // config.androidPortraitConfig.numberOffsetBottomY = 20;
    // config.androidPortraitConfig.numberOffsetRightX = 20;//seems like margin right
    // config.androidPortraitConfig.numberAlignParentRight = true;
    // config.androidPortraitConfig.numberOffsetX = 20;//seems like margin left
    // config.androidPortraitConfig.numberHidden = true;
    config.androidPortraitConfig?.numberBold = false;
//切换账号
    config.androidPortraitConfig?.switchAccColorIdName='teal_700';//textColor
    config.androidPortraitConfig?.switchAccTextSize=13;
    config.androidPortraitConfig?.switchAccHidden=false;
    // config.androidPortraitConfig.switchAccOffsetX=20;//控件位于屏幕最左侧 + marginleft值
    // config.androidPortraitConfig.switchAccOffsetY=20;//控件位于屏幕最上侧 + marginTop值
    // config.androidPortraitConfig.switchAccOffsetBottomY=20;//控件位于屏幕最下侧 + marginBottom值
    // config.androidPortraitConfig.switchAccOffsetRightX=20;//控件位于屏幕最右侧 + marginRight值
    // config.androidPortraitConfig.switchAccAlignParentRight=true;//控件是否位于屏幕最右侧
    config.androidPortraitConfig?.switchAccText='切换手机账号';
    // config.androidPortraitConfig.switchAccTextBold=true;//Bold

//登录按钮
    config.androidPortraitConfig?.loginBtnImgIdName="btn_bg";//this drawable resource should put in the drawable package in android project
//     config.androidPortraitConfig.loginImgPressedName="#FF6200EE";//loginImgPressedName和loginImgPressedName同时设置才会生效
//     config.androidPortraitConfig.loginImgPressedName="#FF000000";//loginImgPressedName和loginImgPressedName同时设置才会生效
    // config.androidPortraitConfig.loginBtnTextIdName="one_key_login";//receive an id,not a String
    config.androidPortraitConfig?.loginBtnTextColorIdName="teal_200";//receive a string,not an id
    config.androidPortraitConfig?.loginBtnTextSize=15;
    config.androidPortraitConfig?.loginBtnWidth=300;
    config.androidPortraitConfig?.loginBtnHeight=40;
    // config.androidPortraitConfig.loginBtnOffsetX=4;
    // config.androidPortraitConfig.loginBtnOffsetY=4;
    // config.androidPortraitConfig.loginBtnOffsetBottomY=4;
    // config.androidPortraitConfig.loginBtnOffsetRightX=40;
    // config.androidPortraitConfig.loginBtnAlignParentRight=true;
    // config.androidPortraitConfig.loginBtnHidden=true;
    // config.androidPortraitConfig.loginBtnTextBold=true;
    config.androidPortraitConfig?.loginBtnTextStringName='一键登录';

//复选框
    // config.androidPortraitConfig.checkboxDefaultState=true;
    // config.androidPortraitConfig.checkboxHidden=true;
    // config.androidPortraitConfig.checkboxOffsetX=20;
    // config.androidPortraitConfig.checkboxOffsetRightX=20;//距离右边隐私协议文字的距离
    // config.androidPortraitConfig.checkboxOffsetY=1;//默认同文字居中，该值为距离中线距离
    // config.androidPortraitConfig.checkboxOffsetBottomY=30;
    // config.androidPortraitConfig.checkboxScaleX=1;//复选框横向拉伸距离
    // config.androidPortraitConfig.checkboxScaleY=1;//复选框纵向拉伸距离
    // config.androidPortraitConfig.checkedImgName='close.png';//两个同事设置有效
    // config.androidPortraitConfig.uncheckedImgName='logo.png';//两个同事设置有效
    // config.androidPortraitConfig.checkboxWidth=100;//只有在包含checkedImgName设置的宽度和高度才会有效
    // config.androidPortraitConfig.checkboxHeight=50;//

//一键登录页面 隐私协议自定义
    // config.androidPortraitConfig.agreementColor='purple_200';//高亮显示字体颜色
    // config.androidPortraitConfig.agreementOffsetX=200;//包括checkbox一起距离左侧距离
    // config.androidPortraitConfig.agreementOffsetRightX=2;//包括checkbox一起距离右侧距离
    // config.androidPortraitConfig.agreementOffsetY=2;//包括checkbox一起距离屏幕最上侧距离
    // config.androidPortraitConfig.agreementOffsetBottomY=2;//包括checkbox一起距离屏幕最下侧距离
    // config.androidPortraitConfig.agreementGravityLeft=true;//隐私协议是否左对齐，默认居中
    // config.androidPortraitConfig.agreementBaseTextColor='black';
    // config.androidPortraitConfig.agreementTextSize=12;
    // config.androidPortraitConfig.agreementTextStartString='登录即同意';
    // config.androidPortraitConfig.agreementTextEndString='并使用本机号码登录';
    // config.androidPortraitConfig.agreementTextStartIdName='agreement_Start';//通过传入安卓原生项目中的资源id
    // config.androidPortraitConfig.agreementTextEndIdName='agreement_end';//通过传入安卓原生项目中的资源id
    // config.androidPortraitConfig.agreementAlignParentRight=true;
    // config.androidPortraitConfig.agreementHidden=false;
    // config.androidPortraitConfig.agreementCtccTextString="中国电信";
    // config.androidPortraitConfig.agreementCtccTextId="test_id";
    // config.androidPortraitConfig.agreementTextAndString1="test_id";//设置多个协议必须设置相应的url才会有效果
    // config.androidPortraitConfig.agreementTextAndString2="test_id";
    // config.androidPortraitConfig.agreementTextBold=false;
    // config.androidPortraitConfig.agreementTextWithUnderLine=true;//高亮部分下划线
    // config.androidPortraitConfig.cusAgreementNameId1='app_name';//cusAgreementNameId1与cusAgreementUrl1必须同时出现才会有效果
    // config.androidPortraitConfig.cusAgreementUrl1='https://www.baidu.com/';
    // config.androidPortraitConfig.cusAgreementNameId2='app_name';
    // config.androidPortraitConfig.cusAgreementColor1='purple_200';
    // config.androidPortraitConfig.cusAgreementNameText2='app_name';
    // config.androidPortraitConfig.agreementUncheckHintText='uncheck_tip';

//服务协议页面内容自定义
    config.androidPortraitConfig?.agreementPageTitleString='服务与隐私协议';//有缓存可能需要重装应用
    // config.androidPortraitConfig.cusAgreementPageOneTitleString='测试标题一';
    // config.androidPortraitConfig.cusAgreementPageTwoTitleString='测试标题二';//第二个隐私协议页面标题
    // config.androidPortraitConfig.cusAgreementPageThreeTitleString='测试标题三';//第三个隐私协议页面标题
    // config.androidPortraitConfig.cusAgreementPageOneTitleNameId='app_name';
    // config.androidPortraitConfig.cusAgreementPageTwoTitleNameId='app_name';
    // config.androidPortraitConfig.cusAgreementPageThreeTitleNameId='app_name';
    // config.androidPortraitConfig.agreementPageCloseImg='checked.png';//设置协议web页面的返回键
    // config.androidPortraitConfig.agreementPageCloseImgHidden=true;//设置一键登录的标题栏的
    // config.androidPortraitConfig.agreementPageCloseImgWidth=15;//返回图标宽度
    // config.androidPortraitConfig.agreementPageCloseImgHeight=15;//返回图标高度
    config.androidPortraitConfig?.agreementPageTitleTextSize=15;//标题字体大小
    config.androidPortraitConfig?.agreementPageTitleTextColor='#FFBB86FC';//rgb
    // config.androidPortraitConfig.agreementPageTitleTextBold=true;
    // config.androidPortraitConfig.agreementPageTitleHidden=true;

//slogan(中国电信提供认证服务)
    //config.androidPortraitConfig.sloganOffsetX=20;//左偏移
    //config.androidPortraitConfig.sloganOffsetY=20;
    //config.androidPortraitConfig.sloganOffsetBottomY=20;
    config.androidPortraitConfig?.sloganTextSize=10;
    config.androidPortraitConfig?.sloganTextColor='purple_200';
    // config.androidPortraitConfig.sloganOffsetRightX=20;//右偏移
    config.androidPortraitConfig?.sloganAlignParentRight=false;//右
    config.androidPortraitConfig?.sloganHidden=false;
    config.androidPortraitConfig?.sloganTextBold=false;//加粗

//弹框模式
    config.androidPortraitConfig?.dialogTheme=false;//一键登录页面是否采用弹框模式
    config.androidPortraitConfig?.dialogAlignBottom=false;
    // config.androidPortraitConfig.dialogOffsetX=200;//对dialogAlignBottom=falses时生效
    // config.androidPortraitConfig.dialogOffsetY=200;//对dialogAlignBottom=falses时生效
    // config.androidPortraitConfig.dialogWidth=300;//对dialogAlignBottom=falses时生效
    // config.androidPortraitConfig.dialogHeight=300;//对dialogAlignBottom=falses时生效
    config.androidPortraitConfig?.dialogBackground='bg.png';//弹框弹出后的背景板
    config.androidPortraitConfig?.dialogBackgroundClickClose=false;//弹框弹出后的背景板


//大背景
    config.androidPortraitConfig?.backgroundImgPath='bg_my.png';
    // config.androidPortraitConfig.fullScreen=true;

//自定义控件 新增一个textview

    AndroidCustomView customView = new AndroidCustomView();
    customView.viewTag = '自定义控件1';
    customView.viewClass='TextView';
    customView.viewText='自定义控件1';
    customView.viewTextFont=15;
    customView.viewTextBold=false;
    customView.viewAlignParentRight=false;
    customView.viewHorizontalCenter=true;
    customView.viewHorizontalCenterVertical=false;
    customView.viewOffsetX=20;
    customView.viewOffsetY=20;
    customView.viewOffsetRightX=20;
    customView.viewOffsetBottomY=60;
    customView.viewWidth=100;
    customView.viewHeight=20;
    var list0 = [customView];

    Map<String,List<AndroidCustomView>> customViewMap = new Map();
    customViewMap['customView'] = list0;

   config.androidPortraitConfig?.customView= customViewMap;//新增自定义控件
  }

  FlyVerifyUIConfig _configIOSUIConfig() {
    FlyVerifyUIConfig config = FlyVerifyUIConfig();
    config.iOSConfig?.manualDismiss = false;

    // config.iOSConfig?.navBarHidden = true;
    config.iOSConfig?.prefersStatusBarHidden = false;

    config.iOSConfig?.shouldAutorotate = true;
    config.iOSConfig?.supportedInterfaceOrientations = iOSInterfaceOrientationMask.all;
    config.iOSConfig?.preferredInterfaceOrientationForPresentation = iOSInterfaceOrientation.portrait;
    config.iOSConfig?.overrideUserInterfaceStyle = iOSUserInterfaceStyle.light;
    config.iOSConfig?.preferredStatusBarStyle = iOSStatusBarStyle.styleDarkContent;
    config.iOSConfig?.presentingWithAnimate = false;

    config.iOSConfig?.backBtnImageName = "assets/icons8-go_back.png";
    config.iOSConfig?.loginBtnText = "🐴一键登录🍺";
    config.iOSConfig?.loginBtnBgColor = "#c194ff";
    config.iOSConfig?.loginBtnTextColor = "bcc2cf";
    config.iOSConfig?.loginBtnBorderWidth = 3;
    config.iOSConfig?.loginBtnCornerRadius = 15;
    config.iOSConfig?.loginBtnBorderColor = "ff5f63";
    config.iOSConfig?.loginBtnBgImgNames = ["assets/icons8-x-file.png","assets/icons8-pacify.png","assets/icons8-active_directory.png",];
    // config.iOSConfig?.logoHidden = true;
    config.iOSConfig?.logoImageName = "assets/logo.png";
    config.iOSConfig?.logoCornerRadius = 20;
    config.iOSConfig?.numberColor = "6b3040";
    config.iOSConfig?.numberBgColor = "4fbf4a";
    config.iOSConfig?.numberTextAlignment = iOSTextAlignment.right;
    config.iOSConfig?.phoneCorner = 10;
    config.iOSConfig?.phoneBorderWidth = 2;
    config.iOSConfig?.phoneBorderColor = "cdffc9";
    config.iOSConfig?.checkHidden = false;
    config.iOSConfig?.checkDefaultState = true;
    config.iOSConfig?.checkedImgName = "assets/icons8-spell_check.png";
    config.iOSConfig?.uncheckedImgName = "assets/icons8-round.png";
    config.iOSConfig?.privacyLineSpacing = 5;
    config.iOSConfig?.privacyTextAlignment = iOSTextAlignment.left;
    config.iOSConfig?.sloganHidden = false;
    config.iOSConfig?.sloganBgColor = "ffb787";
    config.iOSConfig?.sloganTextColor = "ff87b0";
    config.iOSConfig?.sloganTextAlignment = iOSTextAlignment.right;
    config.iOSConfig?.sloganCorner = 5;
    // config.iOSConfig?.sloganBorderWidth = 0;
    // config.iOSConfig?.sloganBorderColor;


    //隐私文本自定义
    FlyVerifyUIConfigIOSPrivacyText privacyText0 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText1 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText2 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText3 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText4 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText5 = FlyVerifyUIConfigIOSPrivacyText();
    FlyVerifyUIConfigIOSPrivacyText privacyText6 = FlyVerifyUIConfigIOSPrivacyText();

    privacyText0.text = "登录即代表同意";
    privacyText0.textColor = "d5ffd1";
    privacyText0.textFont = 12;
    //运营商协议占位
    privacyText1.isOperatorPlaceHolder = true;
    privacyText1.textColor = "f1ff73";
    privacyText1.textFont = 12;
    privacyText2.text = "和";
    privacyText2.textColor = "d5ffd1";
    privacyText2.textFont = 12;
    privacyText3.text = "Mob服务协议";
    privacyText3.textLinkString = "http://www.mob.com/policy/zh";
    privacyText3.textColor = "ffa373";
    privacyText3.textFont = 12;
    privacyText4.text = "、";
    privacyText4.textColor = "ff73ab";
    privacyText4.textFont = 12;
    privacyText5.text = "百度服务协议";
    privacyText5.textLinkString = "http://www.baidu.com";
    privacyText5.textColor = "a259ff";
    privacyText5.textFont = 12;
    privacyText6.text = "并授权" + "appName" + "获取本机号码";
    privacyText6.textColor = "3f2e6b";
    privacyText6.textFont = 12;
    config.iOSConfig?.privacySettings = [privacyText0,privacyText1,privacyText2,privacyText3,privacyText4,privacyText5,privacyText6];
    config.iOSConfig?.privacyTextAlignment = iOSTextAlignment.center;
    config.iOSConfig?.privacyLineSpacing = 5;

    //授权页自带控件布局
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenheight = size.height;

    //logo布局
    FlyVerifyUIConfigIOSLayout logoImageViewLayout = FlyVerifyUIConfigIOSLayout();
    logoImageViewLayout.layoutTop = 120;
    logoImageViewLayout.layoutCenterX = -20;
    logoImageViewLayout.layoutWidth = 140;
    logoImageViewLayout.layoutHeight = 120;

    //手机号label布局
    FlyVerifyUIConfigIOSLayout phoneLabelLayout = FlyVerifyUIConfigIOSLayout();
    phoneLabelLayout.layoutCenterX = 0;
    phoneLabelLayout.layoutCenterY = -80;
    phoneLabelLayout.layoutWidth = screenWidth - 120;
    phoneLabelLayout.layoutHeight = 30;

    //一键登录按钮布局
    FlyVerifyUIConfigIOSLayout loginBtnLayout = FlyVerifyUIConfigIOSLayout();
    loginBtnLayout.layoutCenterX = 0;
    loginBtnLayout.layoutCenterY = 0;
    loginBtnLayout.layoutWidth = screenWidth - 80;
    loginBtnLayout.layoutHeight = 50;

    //slogan布局
    FlyVerifyUIConfigIOSLayout sloganLabelLayout = FlyVerifyUIConfigIOSLayout();
    sloganLabelLayout.layoutCenterX = 0;
    sloganLabelLayout.layoutBottom = -30;
    sloganLabelLayout.layoutTrailing = 0;
    sloganLabelLayout.layoutLeading = 0;

    //隐私协议布局
    FlyVerifyUIConfigIOSLayout privacyTextViewLayout = FlyVerifyUIConfigIOSLayout();
    privacyTextViewLayout.layoutLeading = 100;
    privacyTextViewLayout.layoutTrailing = -80;
    // phoneLabelLayout.layoutBottom = 50;
    // privacyTextViewLayout.layoutCenterX = 0;
    privacyTextViewLayout.layoutCenterY = 90;
    // privacyTextViewLayout.layoutWidth = screenWidth - 100;
    privacyTextViewLayout.layoutHeight = 80;

    //checkBox布局
    FlyVerifyUIConfigIOSPrivacyCheckBoxLayout checkBoxLayout = FlyVerifyUIConfigIOSPrivacyCheckBoxLayout();
    checkBoxLayout.layoutTop = 0;
    checkBoxLayout.layoutRightSpaceToPrivacyLeft = -8;
    // checkBoxLayout.layoutLeftSpaceToPrivacyRight = 8;
    // checkBoxLayout.layoutCenterY = 50;
    checkBoxLayout.layoutWidth = 40;
    checkBoxLayout.layoutHeight = 40;
    // checkBoxLayout.layoutToSuperView = true;

    // 自定义控件Label
    var iosTitleDesc = FlyVerifyUIConfigIOSCustomLabel(102);
    iosTitleDesc.text ='应国家网络实名制的要求，请绑定您的手机号，保障您的帐号安全，绑定后可通过微信一键登录。';
    iosTitleDesc.fontSize = 14;
    iosTitleDesc.textColor = '#C4C4C4';
    iosTitleDesc.textAlignment = iOSTextAlignment.left;
    var iosTitleDescLayout = FlyVerifyUIConfigIOSLayout();
    iosTitleDescLayout.layoutBottom = -80;
    iosTitleDescLayout.layoutCenterX = 0;
    iosTitleDescLayout.layoutWidth = screenWidth - 60;
    iosTitleDescLayout.layoutHeight = 50;
    iosTitleDesc.portraitLayout = iosTitleDescLayout;

    // 自定义控件Button
    var iosCustomButton = FlyVerifyUIConfigIOSCustomButton(103);
    iosCustomButton.backgroundColor = '#14F46E';
    iosCustomButton.title ='微信一键登录';
    iosCustomButton.titleFontSize = 14;
    iosCustomButton.titleColor = '#C4F4C4';
    iosCustomButton.isBodyFont = true;
    iosCustomButton.cornerRadius = 10;
    iosCustomButton.normalImage = "assets/checked.png";
    iosCustomButton.normalBackgroundImage = "assets/bg_my.png";
    var iosCustomButtonLayout = FlyVerifyUIConfigIOSLayout();
    iosCustomButtonLayout.layoutBottom = -150;
    iosCustomButtonLayout.layoutCenterX = 0;
    iosCustomButtonLayout.layoutWidth = screenWidth - 60;
    iosCustomButtonLayout.layoutHeight = 50;
    iosCustomButton.portraitLayout = iosCustomButtonLayout;

    // 自定义控件导航栏Button
    //navButton的大小根据title image backgroundImage的内容自适应
    var iosCustomNavButton = FlyVerifyUIConfigIOSCustomNavButton(104);
    iosCustomNavButton.navPosition = iOSCustomWidgetNavPosition.navRight;
    iosCustomNavButton.backgroundColor = '#44F56F';
    iosCustomNavButton.title ='帮助';
    iosCustomNavButton.titleFontSize = 14;
    iosCustomNavButton.titleColor = '#FE13AC';
    iosCustomNavButton.isBodyFont = true;
    iosCustomNavButton.cornerRadius = 5;
    iosCustomNavButton.normalImage = "assets/checked.png";
    // iosCustomNavButton.normalBackgroundImage = "assets/logo.png";

    config.iOSConfig?.widgets = [iosCustomButton, iosTitleDesc, iosCustomNavButton];

    //设置到授权页竖屏布局
    FlyVerifyUIConfigIOSCustomLayouts portraitLayouts = FlyVerifyUIConfigIOSCustomLayouts();
    portraitLayouts.phoneLabelLayout = phoneLabelLayout;
    portraitLayouts.loginBtnLayout = loginBtnLayout;
    portraitLayouts.logoImageViewLayout = logoImageViewLayout;
    portraitLayouts.sloganLabelLayout = sloganLabelLayout;
    portraitLayouts.privacyTextViewLayout = privacyTextViewLayout;
    portraitLayouts.checkBoxLayout = checkBoxLayout;

    config.iOSConfig?.portraitLayouts = portraitLayouts;

    return config;
  }

  void _showAlert(String text, {bool isError = false}) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: new Text('提示'),
          content: new Text(text),
          actions: <Widget>[
            new TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: new Text('OK')),
          ],
        )
    );
  }

  final _textEditVC = TextEditingController();
  void _showMobileVerifyAlert() {
    if (Platform.isAndroid){
      _showAlert('Android Flyverify not support mobileAuth now');
    } else {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: new Text('请输入手机号码:'),
          content: new TextField(
            controller: _textEditVC,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofocus: true,
            maxLength: 11,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
          actions: <Widget>[
            new TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final _phoneNum = _textEditVC.text;
                  if (_phoneNum.length == 11) {
                    _mobileVerify(_phoneNum, context);
                  } else {
                    _showAlert('输入的手机号非法,请确认后输入!');
                  }
                },
                child: new Text('OK')
            ),
            new TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: new Text('Cancel')
            ),
          ],
        )
    );
    }
  }
    void login(Map rt) async {
        if (Platform.isIOS){
            // 结果检验成功，进行网络请求
            _doLoginWith(rt);
        }else{
            rt['phoneOperator'] = rt['operator'];
            rt['appkey'] = '3a2c2a977d3d2';
            rt['md5'] = 'b89d2427a3bc7ad1aea1e1e8c1d36bf3';
            androidLogin(rt);
        }

    }

  void _doLoginWith(Map params) async {
    //因为在调用处已经添加了参数合法性判断，此处无需再进行合法性判断
    var header = Map<String, String>();
    header['Content-Type'] = 'application/json';
    final client = http.Client();
    final response = await client.post(Uri.http("demo.verify.mob.com", "/demo/sdkLogin"), headers: header, body: json.encode(params));
    print('Login Result: ${response.body.toString()}');
    Flyverify.manualDismissLoading();
    _showAlert(response.body.toString());
  }
  void androidLogin(Map params) async {
     //因为在调用处已经添加了参数合法性判断，此处无需再进行合法性判断
                      var header = Map<String, String>();
                      header['Content-Type'] = 'application/json';
                      final client = http.Client();
                      final response = await client.post(
                          Uri.http("demo.accuratead.cn", "/demo/sdkLogin"),
                          headers: header,
                          body: json.encode(params));
                      print('Login Result: ${response.body.toString()}');
                      _showAlert(response.body.toString());
      }
}

enum GridViewWidgetMethodType {
  preVerify,
  autoVerify,
  manualVerify,
  preMobileAuth,
  mobileAuthVerify,
  setCustomUi
}

class GridViewWidget {
  // Properties
  late String itemName;
  late GridViewWidgetMethodType type;

  GridViewWidget(GridViewWidgetMethodType type, String name) {
    this.type = type;
    this.itemName = name;
  }
}