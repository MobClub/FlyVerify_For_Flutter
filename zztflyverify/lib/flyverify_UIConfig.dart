import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart' show IterableExtension;

part 'flyverify_UIConfig.g.dart';

enum ImageScaleType {
  MATRIX,
  FIT_XY,
  FIT_START,
  FIT_CENTER,
  FIT_END,
  CENTER,
  CENTER_CROP,
  CENTER_INSIDE
}

enum iOSCustomWidgetNavPosition { navLeft, navRight }

enum iOSCustomWidgetType { label, button, imageView }

enum iOSUserInterfaceStyle {
  // @JsonValue(0)
  unspecified,
  // @JsonValue(1)
  light,
  // @JsonValue(2)
  dark
}
enum iOSUIViewContentMode {
  // @JsonValue(0)
  scaleToFill,
  // @JsonValue(1)
  scaleAspectFit,
  // @JsonValue(2)
  scaleAspectFill
}
enum iOSModalPresentationStyle {
  // @JsonValue(0)
  fullScreen,
  // @JsonValue(1)
  pageSheet,
  // @JsonValue(2)
  forSheet,
  // @JsonValue(3)
  currentContext,
  // @JsonValue(4)
  custom,
  // @JsonValue(5)
  overFullScreen,
  // @JsonValue(6)
  overCurrentContext,
  // @JsonValue(7)
  popOver,
  // @JsonValue(8)
  blurOverFullScreen,
  // @JsonValue(-1)
  none,
  // @JsonValue(-2)
  automatic
}

enum iOSModalTransitionStyle {
  // @JsonValue(0)
  coverVertical,
  // @JsonValue(1)
  flipHorizontal,
  // @JsonValue(2)
  crossDissolve,
  // @JsonValue(3)
  partialCurl
}

enum iOSInterfaceOrientation {
  // @JsonValue(1)
  portrait,
  // @JsonValue(2)
  portraitUpsideDown,
  // @JsonValue(4)
  landscapeLeft,
  // @JsonValue(3)
  landscapeRight,
  // @JsonValue(0)
  unknown
}

enum iOSInterfaceOrientationMask {
  // @JsonValue(2)
  portrait,
  // @JsonValue(16)
  landscapeLeft,
  // @JsonValue(8)
  landscapeRight,
  // @JsonValue(4)
  portraitUpsideDown,
  // @JsonValue(24)
  landscape,
  // @JsonValue(30)
  all,
  // @JsonValue(26)
  allButUpsideDown
}

enum iOSTextAlignment {
  // @JsonValue(1)
  center,
  // @JsonValue(0)
  left,
  // @JsonValue(2)
  right,
  // @JsonValue(3)
  justified,
  // @JsonValue(4)
  natural
}

enum iOSStatusBarStyle {
  // @JsonValue(0)
  styleDefault,
  // @JsonValue(1)
  styleLightContent,
  // @JsonValue(3)
  styleDarkContent
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfig {
  FlyVerifyUIConfigIOS? _iOSConfig;
  FlyVerifyUIConfigAndroid? _androidPortraitConfig;
  FlyVerifyUIConfigAndroid? _androidLandscapeConfig;

  FlyVerifyUIConfig() {}
  set iOSConfig(FlyVerifyUIConfigIOS? config) {
    _iOSConfig = config;
  }

  FlyVerifyUIConfigIOS? get iOSConfig {
    if (_iOSConfig == null) {
      _iOSConfig = new FlyVerifyUIConfigIOS();
    }

    return _iOSConfig;
  }

  set androidPortraitConfig(FlyVerifyUIConfigAndroid? config) {
    _androidPortraitConfig = config;
  }

  FlyVerifyUIConfigAndroid? get androidPortraitConfig {
    if (_androidPortraitConfig == null) {
      _androidPortraitConfig = new FlyVerifyUIConfigAndroid();
    }
    return _androidPortraitConfig;
  }

  set androidLandscapeConfig(FlyVerifyUIConfigAndroid? config) {
    _androidLandscapeConfig = config;
  }

  FlyVerifyUIConfigAndroid? get androidLandscapeConfig {
    if (_androidLandscapeConfig == null) {
      _androidLandscapeConfig = new FlyVerifyUIConfigAndroid();
    }
    return _androidLandscapeConfig;
  }

  factory FlyVerifyUIConfig.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FlyVerifyUIConfigToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOS {
  bool? navBarHidden;
  bool manualDismiss = true;
  bool? prefersStatusBarHidden;

  /*
 *需先设置Info.plist: View controller-based status bar appearance = YES 方可生效
 *
 *UIStatusBarStyleDefault：状态栏显示 黑
 *UIStatusBarStyleLightContent：状态栏显示 白
 *UIStatusBarStyleDarkContent：状态栏显示 黑 API_AVAILABLE(ios(13.0)) = 3
 **eg. @(UIStatusBarStyleLightContent)
 */
  iOSStatusBarStyle? preferredStatusBarStyle;

  bool? shouldAutorotate;
  iOSInterfaceOrientationMask? supportedInterfaceOrientations;
  iOSInterfaceOrientation? preferredInterfaceOrientationForPresentation;
  bool? presentingWithAnimate;
  iOSModalTransitionStyle? modalTransitionStyle;
  iOSModalPresentationStyle? modalPresentationStyle;
  bool? showPrivacyWebVCByPresent;
  iOSStatusBarStyle? privacyWebVCPreferredStatusBarStyle;
  iOSModalPresentationStyle? privacyWebVCModalPresentationStyle;
  iOSUserInterfaceStyle? overrideUserInterfaceStyle;
  String? backBtnImageName;
  String? loginBtnText;
  String? loginBtnBgColor;
  String? loginBtnTextColor;
  double? loginBtnBorderWidth;
  double? loginBtnCornerRadius;
  String? loginBtnBorderColor;
  List<String>? loginBtnBgImgNames;
  bool? logoHidden;
  String? logoImageName;
  double? logoCornerRadius;
  // bool? phoneHidden;
  String? numberColor;
  String? numberBgColor;
  iOSTextAlignment? numberTextAlignment;
  double? phoneCorner;
  double? phoneBorderWidth;
  String? phoneBorderColor;
  bool? checkHidden;
  bool? checkDefaultState;
  String? checkedImgName;
  String? uncheckedImgName;
  double? privacyLineSpacing;
  iOSTextAlignment? privacyTextAlignment;
  List<FlyVerifyUIConfigIOSPrivacyText?>? privacySettings;
  bool? sloganHidden;
  // String? sloganText;
  String? sloganBgColor;
  String? sloganTextColor;
  iOSTextAlignment? sloganTextAlignment;
  double? sloganCorner;
  double? sloganBorderWidth;
  String? sloganBorderColor;
  List<FlyVerifyUIConfigIOSCustomView?>? widgets;
  FlyVerifyUIConfigIOSCustomLayouts? portraitLayouts;
  FlyVerifyUIConfigIOSCustomLayouts? landscapeLayouts;

  FlyVerifyUIConfigIOS() {}

  factory FlyVerifyUIConfigIOS.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSFromJson(json);
  Map<String, dynamic> toJson() => _$FlyVerifyUIConfigIOSToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSPrivacyText {
  String? text;
  double? textFont;
  String? textFontName;
  String? textColor;
  String? webTitleText; //隐私协议web页标题显示文字,默认取text
  String? textLinkString;
  bool? isOperatorPlaceHolder;
  Map<String, dynamic>? textAttribute;

  FlyVerifyUIConfigIOSPrivacyText() {}

  factory FlyVerifyUIConfigIOSPrivacyText.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSPrivacyTextFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSPrivacyTextToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomView {
  int? widgetID;

  double? cornerRadius;
  String? backgroundColor;
  double? borderWidth;
  String? borderColor;

  FlyVerifyUIConfigIOSLayout? portraitLayout;
  FlyVerifyUIConfigIOSLayout? landscapeLayout;

  FlyVerifyUIConfigIOSCustomView({required this.widgetID});

  factory FlyVerifyUIConfigIOSCustomView.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomViewFromJson(json);
  Map<String, dynamic> toJson() => _$FlyVerifyUIConfigIOSCustomViewToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomNavButton
    extends FlyVerifyUIConfigIOSCustomButton {
  iOSCustomWidgetNavPosition? navPosition;

  FlyVerifyUIConfigIOSCustomNavButton(int? widgetID) : super(widgetID);
  factory FlyVerifyUIConfigIOSCustomNavButton.fromJson(
          Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomNavButtonFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSCustomNavButtonToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomButton extends FlyVerifyUIConfigIOSCustomView {
  String? title; //标题(normal)
  String? titleColor; //标题文字颜色，HEX，eg. "c194ff"(normal)
  double? titleFontSize; //标题文字大小(normal)
  var isBodyFont = false; //标题文字是否粗体(normal)
  String? normalImage; //按钮图片(normal)
  String? normalBackgroundImage; //按钮背景图片(normal)

  String? highlightedImage; //按钮图片(highlighted)
  String? disabledImage; //按钮图片(disabled)
  String? selectedImage; //按钮图片(selected)

  String? highlightedBackgroundImage; //按钮背景图片(highlighted)
  String? disabledBackgroundImage; //按钮背景图片(disabled)
  String? selectedBackgroundImage; //按钮背景图片(selected)

  iOSCustomWidgetType? widgetType = iOSCustomWidgetType.button;
  FlyVerifyUIConfigIOSCustomButton(int? widgetID) : super(widgetID: widgetID);
  factory FlyVerifyUIConfigIOSCustomButton.fromJson(
          Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomButtonFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSCustomButtonToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomImageView
    extends FlyVerifyUIConfigIOSCustomView {
  String? image;
  iOSUIViewContentMode? contentMode;

  iOSCustomWidgetType? widgetType = iOSCustomWidgetType.imageView;
  FlyVerifyUIConfigIOSCustomImageView(int? widgetID)
      : super(widgetID: widgetID);
  factory FlyVerifyUIConfigIOSCustomImageView.fromJson(
          Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomImageViewFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSCustomImageViewToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomLabel extends FlyVerifyUIConfigIOSCustomView {
  String? text;
  String? textColor;
  double? fontSize;
  var isBodyFont = false;
  iOSTextAlignment? textAlignment;

  iOSCustomWidgetType? widgetType = iOSCustomWidgetType.label;
  FlyVerifyUIConfigIOSCustomLabel(int? widgetID) : super(widgetID: widgetID);
  factory FlyVerifyUIConfigIOSCustomLabel.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomLabelFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSCustomLabelToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSCustomLayouts {
  FlyVerifyUIConfigIOSLayout? loginBtnLayout;
  FlyVerifyUIConfigIOSLayout? phoneLabelLayout;
  FlyVerifyUIConfigIOSLayout? sloganLabelLayout;
  FlyVerifyUIConfigIOSLayout? logoImageViewLayout;
  FlyVerifyUIConfigIOSLayout? privacyTextViewLayout;
  FlyVerifyUIConfigIOSPrivacyCheckBoxLayout? checkBoxLayout;

  FlyVerifyUIConfigIOSCustomLayouts() {}

  factory FlyVerifyUIConfigIOSCustomLayouts.fromJson(
          Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSCustomLayoutsFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSCustomLayoutsToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSLayout {
  double? layoutTop;
  double? layoutLeading;
  double? layoutBottom;
  double? layoutTrailing;
  double? layoutCenterX;
  double? layoutCenterY;
  double? layoutWidth;
  double? layoutHeight;

  FlyVerifyUIConfigIOSLayout() {}

  factory FlyVerifyUIConfigIOSLayout.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSLayoutFromJson(json);
  Map<String, dynamic> toJson() => _$FlyVerifyUIConfigIOSLayoutToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigIOSPrivacyCheckBoxLayout {
/*注：因checkBox通常放置于隐私协议控件旁边，所以CheckBox布局时的相对控件默认为隐私协议控件。
  如需设置为相对于父视图(授权页)的布局，请设置layoutToSuperView=true*/
  double? layoutTop;
  double? layoutLeading;
  double? layoutBottom;
  double? layoutTrailing;
  double? layoutCenterX;
  double? layoutCenterY;
  double? layoutWidth;
  double? layoutHeight;

  /*上述8个约束是否相对于父视图(授权页)，默认相对于隐私协议控件*/
  bool? layoutToSuperView;

  /*额外常用的约束(相对于隐私协议控件)*/
  double? layoutRightSpaceToPrivacyLeft; //checkBox右边到隐私控件左边的距离
  double? layoutLeftSpaceToPrivacyRight; //checkBox左边边到隐私控件右边的距离

  FlyVerifyUIConfigIOSPrivacyCheckBoxLayout() {}

  factory FlyVerifyUIConfigIOSPrivacyCheckBoxLayout.fromJson(
          Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigIOSPrivacyCheckBoxLayoutFromJson(json);
  Map<String, dynamic> toJson() =>
      _$FlyVerifyUIConfigIOSPrivacyCheckBoxLayoutToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class FlyVerifyUIConfigAndroid {
  String? loginBtnImgIdName;
  String? loginImgPressedName;
  String? loginImgNormalName;
  String? loginBtnTextIdName;
  String? loginBtnTextColorIdName;
  int? loginBtnTextSize;
  int? loginBtnWidth;
  int? loginBtnHeight;
  int? loginBtnOffsetX;
  int? loginBtnOffsetY;
  int? loginBtnOffsetBottomY;
  int? loginBtnOffsetRightX;
  bool? loginBtnAlignParentRight;
  bool? loginBtnHidden;
  String? loginBtnTextStringName;
  bool? loginBtnTextBold;
  String? backgroundImgPath;
  bool? backgroundClickClose;
  bool? fullScreen;
  bool? virtualButtonTransparent;
  bool? immersiveTheme;
  bool? immersiveStatusTextColorBlack;
  String? navColorIdName;
  String? navTextIdName;
  String? navTextColorIdName;
  bool? navHidden;
  bool? navTransparent;
  bool? navCloseImgHidden;
  int? navTextSize;
  String? navCloseImgPath;
  int? navCloseImgWidth;
  int? navCloseImgHeight;
  int? navCloseImgOffsetX;
  int? navCloseImgOffsetRightX;
  int? navCloseImgOffsetY;
  bool? navTextBold;
  ImageScaleType? navCloseImgScaleType;
  String? numberColorIdName;
  int? numberSize;
  int? numberOffsetX;
  int? numberOffsetY;
  int? numberOffsetBottomY;
  int? numberOffsetRightX;
  bool? numberAlignParentRight;
  bool? numberHidden;
  bool? numberBold;
  String? switchAccColorIdName;
  int? switchAccTextSize;
  bool? switchAccHidden;
  int? switchAccOffsetX;
  int? switchAccOffsetY;
  int? switchAccOffsetBottomY;
  int? switchAccOffsetRightX;
  bool? switchAccAlignParentRight;
  String? switchAccText;
  bool? switchAccTextBold;
  bool? checkboxDefaultState;
  bool? checkboxHidden;
  int? checkboxOffsetX;
  int? checkboxOffsetRightX;
  int? checkboxOffsetY;
  int? checkboxOffsetBottomY;
  double? checkboxScaleX;
  double? checkboxScaleY;
  String? checkedImgName;
  String? uncheckedImgName;
  int? checkboxWidth;
  int? checkboxHeight;
  String? agreementColor;
  int? agreementOffsetX;
  int? agreementOffsetRightX;
  int? agreementOffsetY;
  int? agreementOffsetBottomY;
  bool? agreementGravityLeft;
  String? agreementBaseTextColor;
  int? agreementTextSize;
  String? agreementTextStartIdName;
  String? agreementTextEndIdName;
  bool? agreementAlignParentRight;
  bool? agreementHidden;
  String? agreementCmccTextString;
  String? agreementCuccTextString;
  String? agreementCtccTextString;
  String? agreementCtccTextId;
  String? agreementTextStartString;
  String? agreementTextAndString1;
  String? agreementTextAndString2;
  String? agreementTextAndString3;
  String? agreementTextEndString;
  bool? agreementTextBold;
  bool? agreementTextWithUnderLine;
  String? cusAgreementNameId1;
  String? cusAgreementUrl1;
  String? cusAgreementColor1;
  String? cusAgreementNameId2;
  String? cusAgreementUrl2;
  String? cusAgreementColor2;
  String? cusAgreementNameId3;
  String? cusAgreementUrl3;
  String? cusAgreementColor3;
  String? cusAgreementNameText1;
  String? cusAgreementNameText2;
  String? cusAgreementNameText3;
  int? agreementUncheckHintType;
  String? agreementUncheckHintText;
  String? agreementPageTitleString;
  String? cusAgreementPageOneTitleString;
  String? cusAgreementPageTwoTitleString;
  String? cusAgreementPageThreeTitleString;
  String? agreementPageTitleStringId;
  String? cusAgreementPageOneTitleNameId;
  String? cusAgreementPageTwoTitleNameId;
  String? cusAgreementPageThreeTitleNameId;
  String? agreementPageCloseImg;
  bool? agreementPageCloseImgHidden;
  int? agreementPageCloseImgWidth;
  int? agreementPageCloseImgHeight;
  int? agreementPageTitleTextSize;
  String? agreementPageTitleTextColor;
  bool? agreementPageTitleTextBold;
  bool? agreementPageTitleHidden;
  int? sloganOffsetX;
  int? sloganOffsetY;
  int? sloganOffsetBottomY;
  int? sloganTextSize;
  String? sloganTextColor;
  int? sloganOffsetRightX;
  bool? sloganAlignParentRight;
  bool? sloganHidden;
  bool? sloganTextBold;
  bool? dialogTheme;
  bool? dialogAlignBottom;
  int? dialogOffsetX;
  int? dialogOffsetY;
  int? dialogWidth;
  int? dialogHeight;
  String? dialogBackground;
  bool? dialogBackgroundClickClose;
  Map<String, List<AndroidCustomView?>?>? customView;
  String? logoImgPath;
  int? logoWidth;
  int? logoHeight;
  int? logoOffsetX;
  int? logoOffsetY;
  int? logoOffsetBottomY;
  int? logoOffsetRightX;
  bool? logoAlignParentRight;
  bool? logoHidden;

  FlyVerifyUIConfigAndroid() {}

  factory FlyVerifyUIConfigAndroid.fromJson(Map<String, dynamic> json) =>
      _$FlyVerifyUIConfigAndroidFromJson(json);
  Map<String, dynamic> toJson() => _$FlyVerifyUIConfigAndroidToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomLoginBtn {
  String? loginBtnImgIdName;
  String? loginImgPressedName;
  String? loginImgNormalName;
  String? loginBtnTextIdName;
  String? loginBtnTextColorIdName;
  int? loginBtnTextSize;
  int? loginBtnWidth;
  int? loginBtnHeight;
  int? loginBtnOffsetX;
  int? loginBtnOffsetY;
  int? loginBtnOffsetBottomY;
  int? loginBtnOffsetRightX;
  bool? loginBtnAlignParentRight;
  bool? loginBtnHidden;
  String? loginBtnText;
  bool? loginBtnTextBold;

  AndroidCustomLoginBtn() {}

  factory AndroidCustomLoginBtn.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomLoginBtnFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomLoginBtnToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomNav {
  String? navColorIdName;
  String? navTextIdName;
  String? navTextColorIdName;
  bool? navHidden;
  bool? navTransparent;
  bool? navCloseImgHidden;
  int? navTextSize;
  String? navCloseImgPath;
  int? navCloseImgWidth;
  int? navCloseImgHeight;
  int? navCloseImgOffsetX;
  int? navCloseImgOffsetRightX;
  int? navCloseImgOffsetY;
  bool? navTextBold;
  ImageScaleType? navCloseImgScaleType;

  AndroidCustomNav() {}

  factory AndroidCustomNav.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomNavFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomNavToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomAuthPage {
  String? backgroundImgPath;
  bool? backgroundClickClose;
  bool? fullScreen;
  bool? virtualButtonTransparent;
  bool? immersiveTheme;
  bool? immersiveStatusTextColorBlack;

  AndroidCustomAuthPage() {}

  factory AndroidCustomAuthPage.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomAuthPageFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomAuthPageToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomAuthPageLogo {
  String? logoImgPath;
  int? logoWidth;
  int? logoHeight;
  int? logoOffsetX;
  int? logoOffsetY;
  int? logoOffsetBottomY;
  int? logoOffsetRightX;
  bool? logoAlignParentRight;
  bool? logoHidden;

  AndroidCustomAuthPageLogo() {}

  factory AndroidCustomAuthPageLogo.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomAuthPageLogoFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomAuthPageLogoToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomPhoneNumber {
  String? numberColorIdName;
  int? numberSize;
  int? numberOffsetX;
  int? numberOffsetY;
  int? numberOffsetBottomY;
  int? numberOffsetRightX;
  bool? numberAlignParentRight;
  bool? numberHidden;
  bool? numberBold;

  AndroidCustomPhoneNumber() {}

  factory AndroidCustomPhoneNumber.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomPhoneNumberFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomPhoneNumberToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomSwitchNumber {
  String? switchAccColorIdName;
  int? switchAccTextSize;
  bool? switchAccHidden;
  int? switchAccOffsetX;
  int? switchAccOffsetY;
  int? switchAccOffsetBottomY;
  int? switchAccOffsetRightX;
  bool? switchAccAlignParentRight;
  String? switchAccText;
  bool? switchAccTextBold;

  AndroidCustomSwitchNumber() {}

  factory AndroidCustomSwitchNumber.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomSwitchNumberFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomSwitchNumberToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomCheckBox {
  String? checkboxImgIdName;
  bool? checkboxDefaultState;
  bool? checkboxHidden;
  int? checkboxOffsetX;
  int? checkboxOffsetRightX;
  int? checkboxOffsetY;
  int? checkboxOffsetBottomY;
  String? checkboxScaleX;
  String? checkboxScaleY;
  String? checkedImgName;
  String? uncheckedImgName;
  int? checkboxWidth;
  int? checkboxHeight;

  AndroidCustomCheckBox() {}

  factory AndroidCustomCheckBox.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomCheckBoxFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomCheckBoxToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomPrivacy {
  String? agreementColor;
  int? agreementOffsetX;
  int? agreementOffsetRightX;
  int? agreementOffsetY;
  int? agreementOffsetBottomY;
  bool? agreementGravityLeft;
  String? agreementBaseTextColor;
  int? agreementTextSize;
  String? agreementTextStartIdName;
  String? agreementTextEndIdName;
  bool? agreementAlignParentRight;
  bool? agreementHidden;
  String? agreementCmccTextString;
  String? agreementCuccTextString;
  String? agreementCtccTextString;
  String? agreementTextStartString;
  String? agreementTextAndString1;
  String? agreementTextAndString2;
  String? agreementTextAndString3;
  String? agreementTextEndString;
  bool? agreementTextBold;
  bool? agreementTextWithUnderLine;
  String? cusAgreementNameId1;
  String? cusAgreementUrl1;
  String? cusAgreementColor1;
  String? cusAgreementNameId2;
  String? cusAgreementUrl2;
  String? cusAgreementColor2;
  String? cusAgreementNameId3;
  String? cusAgreementUrl3;
  String? cusAgreementColor3;
  String? cusAgreementNameText1;
  String? cusAgreementNameText2;
  String? cusAgreementNameText3;
  int? agreementUncheckHintType;
  String? agreementUncheckHintText;

  AndroidCustomPrivacy() {}

  factory AndroidCustomPrivacy.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomPrivacyFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomPrivacyToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomPrivacyContentPage {
  String? agreementPageTitleString;
  String? cusAgreementPageOneTitleString;
  String? cusAgreementPageTwoTitleString;
  String? cusAgreementPageThreeTitleString;
  String? agreementPageTitleStringId;
  String? cusAgreementPageOneTitleNameId;
  String? cusAgreementPageTwoTitleNameId;
  String? cusAgreementPageThreeTitleNameId;
  String? agreementPageCloseImg;
  bool? agreementPageCloseImgHidden;
  int? agreementPageCloseImgWidth;
  int? agreementPageCloseImgHeight;
  int? agreementPageTitleTextSize;
  String? agreementPageTitleTextColor;
  bool? agreementPageTitleTextBold;
  bool? agreementPageTitleHidden;

  AndroidCustomPrivacyContentPage() {}

  factory AndroidCustomPrivacyContentPage.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomPrivacyContentPageFromJson(json);
  Map<String, dynamic> toJson() =>
      _$AndroidCustomPrivacyContentPageToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomOperatorSlogan {
  int? sloganOffsetX;
  int? sloganOffsetY;
  int? sloganOffsetBottomY;
  int? sloganTextSize;
  String? sloganTextColor;
  int? sloganOffsetRightX;
  bool? sloganAlignParentRight;
  bool? sloganHidden;
  bool? sloganTextBold;

  AndroidCustomOperatorSlogan() {}

  factory AndroidCustomOperatorSlogan.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomOperatorSloganFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomOperatorSloganToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomDialog {
  bool? dialogTheme;
  bool? dialogAlignBottom;
  int? dialogOffsetX;
  int? dialogOffsetY;
  int? dialogWidth;
  int? dialogHeight;
  bool? dialogBackgroundClickClose;
  String? dialogBackground;

  AndroidCustomDialog() {}

  factory AndroidCustomDialog.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomDialogFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomDialogToJson(this);
}

// @JsonSerializable(explicitToJson: true, includeIfNull: false)
class AndroidCustomView {
  String? viewTag;
  String? viewClass;
  String? viewText;
  String? viewTextColor;
  int? viewTextFont;
  bool? viewTextBold;
  bool? viewAlignParentRight;
  bool? viewHorizontalCenter;
  bool? viewHorizontalCenterVertical;
  int? viewOffsetX;
  int? viewOffsetY;
  int? viewOffsetRightX;
  int? viewOffsetBottomY;
  int? viewWidth;
  int? viewHeight;
  String? viewImg;

  AndroidCustomView() {}

  factory AndroidCustomView.fromJson(Map<String, dynamic> json) =>
      _$AndroidCustomViewFromJson(json);
  Map<String, dynamic> toJson() => _$AndroidCustomViewToJson(this);
}
