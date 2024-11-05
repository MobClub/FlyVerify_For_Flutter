#import "FlyverifyPlugin.h"

#import "UIColor+Hex.h"
#import "UIImage+Yjyz.h"

#import <FlyVerify/FVSDKHyVerify.h>
#import <FlyVerifyCSDK/FlyVerifyCSDK.h>

static NSString *Method_Common_Channel_ID = @"com.fly.flyverify.methodChannel";
static NSString *Event_Verify_Channel_ID = @"com.fly.flyverify.verifyEventChannel";
static NSString *Event_CustomView_Event_Channel_ID = @"com.fly.flyverify.customSubViewEventChannel";

typedef NS_ENUM(NSUInteger, FVPluginMethod) {
    FVPluginMethodGetVersion        = 0,
    FVPluginMethodFVEnable          = 1,
    FVPluginMethodOperatorType      = 2,
    FVPluginMethodClearCache        = 3,
    FVPluginMethodEnableDebug       = 4,
    FVPluginMethodUploadPrivacy     = 5,
    FVPluginMethodFinishLoginVC     = 6,
    FVPluginMethodHideLoading       = 7,
    FVPluginMethodPreVerify         = 8,
    FVPluginMethodVerify            = 9,
    FVPluginMethodMobileAuthToken   = 10,
    FVPluginMethodMobileVerify      = 11,
    FVPluginMethodPlatformVersion   = 12,
    FVPluginMethodRegister          = 19
};

@interface FlyverifyPlugin() <FVSDKVerifyDelegate>

// Mehtods Info
@property (nonatomic, strong) NSDictionary *methodMap;

// Configure Dict
@property (nonatomic, strong) NSDictionary *uiConfigure;

// About EventChannel
@property (nonatomic, strong) NSDictionary *eventsData;
@property (nonatomic, copy) void (^eventCallBack) (id _Nullable event);

// 当前授权页面
@property (nonatomic, weak) UIViewController *authPage;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *customWidgets;


@property (nonatomic, weak)NSObject<FlutterPluginRegistrar>* registrar;

@end


@implementation FlyverifyPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:Method_Common_Channel_ID binaryMessenger:[registrar messenger]];
    FlutterEventChannel* verifyEventChannel = [FlutterEventChannel eventChannelWithName:Event_Verify_Channel_ID binaryMessenger:[registrar messenger]];

    FlyverifyPlugin* instance = [[FlyverifyPlugin alloc] init];

    [instance _addObserver];
    [instance _configMethodMap];
    instance.customWidgets = [NSMutableArray array];

    [verifyEventChannel setStreamHandler:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    instance.registrar = registrar;
}

- (void)_addObserver {
    [FVSDKHyVerify setDelegate:self];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber *methodType = [self.methodMap objectForKey:call.method];

    if (methodType) {
        switch (methodType.intValue) {
            case FVPluginMethodGetVersion:
                [self _getVersion:result];
                break;
            case FVPluginMethodFVEnable:
                [self _flyVerifyEnable:result];
                break;
            case FVPluginMethodOperatorType:
                [self _getCurrentOperatorType:call.arguments result:result];
                break;
            case FVPluginMethodClearCache:
                [self _clearPhoneScripCache:call.arguments result:result];
                break;
            case FVPluginMethodEnableDebug:
                [self _enableDebug:call.arguments result:result];
                break;
            case FVPluginMethodUploadPrivacy:
                [self _uploadPrivacyPermissionStatus:call.arguments result:result];
                break;
            case FVPluginMethodFinishLoginVC:
                [self _finishLoginVcAnimated:call.arguments result:result];
                break;
            case FVPluginMethodHideLoading:
                [self _hideLoadingWithResult:result];
                break;
            case FVPluginMethodPreVerify:
                [self _preLoginWith:call.arguments result:result];
                break;
            case FVPluginMethodVerify:
                [self _openAuthPageWithModel:call.arguments result:result];
                break;
            case FVPluginMethodMobileAuthToken:
                [self _mobileAuth:call.arguments result:result];
                break;
            case FVPluginMethodMobileVerify:
                [self _mobileVerify:call.arguments result:result];
                break;
            case FVPluginMethodPlatformVersion:
                [self _platformVersion:result];
                break;
            case FVPluginMethodRegister:
                [self _registerAppWith:call.arguments];
                break;
            default:
                result(FlutterMethodNotImplemented);
                break;
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventCallBack = events;
    if (self.eventsData) {
        events(self.eventsData);
    }
    self.eventsData = nil;

    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.eventCallBack = nil;
    return nil;
}

#pragma - Navtive Method
- (void)_registerAppWith:(NSDictionary *)params {
    @try {
        if (!params || ![params isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSString *appKey = [params objectForKey:@"appKey"] ? :@"";
        NSString *appSecret = [params objectForKey:@"appSecret"] ? :@"";
        if ([appKey isKindOfClass:[NSString class]]
            && [appKey length]
            && [appSecret isKindOfClass:[NSString class]]
            && [appSecret length]) {
            [FlyVerifyC initKey:appKey secret:appSecret privacyLevel:2];
        }
    } @catch (NSException *exception) {}
}

- (void)_platformVersion:(FlutterResult)result {
    return result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
}

- (void)_getVersion:(FlutterResult)result {
    return result([FVSDKHyVerify sdkVersion]);
}

- (void)_flyVerifyEnable:(FlutterResult)result {
    return result(@([FVSDKHyVerify isVerifyEnable]));
}

- (void)_getCurrentOperatorType:(NSDictionary *)params result:(FlutterResult)result {
    return result([FVSDKHyVerify getCurrentOperatorType]);
}

- (void)_clearPhoneScripCache:(NSDictionary *)params result:(FlutterResult)result {
    [FVSDKHyVerify clearPhoneScripCache];
}

- (void)_enableDebug:(NSDictionary *)params result:(FlutterResult)result {
    if (!params
        || ![params count]
        || ![[params allKeys] containsObject:@"enable"]) {
        return;
    }

    id enable = [params objectForKey:@"enable"];
    if ([enable respondsToSelector:@selector(boolValue)]) {
        [FVSDKHyVerify setDebug:[enable boolValue]];
    }
}

- (void)_uploadPrivacyPermissionStatus:(NSDictionary *)params result:(FlutterResult)result {
    if (!params
        || ![params isKindOfClass:[NSDictionary class]]
        || ![params count]
        || ![[params allKeys] containsObject:@"status"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"ret": @(NO)}];
        return result(dict);
    }

    BOOL status = [[params objectForKey:@"status"] boolValue];
    [FlyVerifyC agreePrivacy:status onResult:^(BOOL success) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"ret": @(success)}];
        result(dict);
    }];
}

- (void)_finishLoginVcAnimated:(NSDictionary *)params result:(FlutterResult)result {
    if (!params
        || [params isKindOfClass:[NSNull class]]
        || ![params count]
        || ![[params allKeys] containsObject:@"flag"]) {
        return result([FlutterError errorWithCode:@"-999" message:@"Manual Dismiss AuthPage Flag Can't Be Empty!" details:nil]);
    }

    id flag = [params objectForKey:@"flag"];
    if ([flag respondsToSelector:@selector(boolValue)]) {
        [FVSDKHyVerify finishLoginVcAnimated:[flag boolValue] Completion:^{
            result(@(YES));
        }];
    }
}

- (void)_hideLoadingWithResult:(FlutterResult)result {
    [FVSDKHyVerify hideLoading];
}

- (void)_preLoginWith:(NSDictionary *)params result:(FlutterResult)result {
    if (params
        && ![params isKindOfClass:[NSNull class]]
        && [params count]
        && [[params allKeys] containsObject:@"timeout"]) {
        id timeout = [params objectForKey:@"timeout"];
        if ([timeout respondsToSelector:@selector(doubleValue)]) {
            // 设置预取号的超时时间
            [FVSDKHyVerify setPreGetPhonenumberTimeOut:[timeout doubleValue]];
        }
    }

    // 开始进行预取号操作
    [FlyVerifyC agreePrivacy:YES onResult:nil];
    [FVSDKHyVerify preLogin:^(NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];

        if (resultDic
            && ![resultDic isKindOfClass:[NSNull class]]
            && [resultDic count]) {
            [mDict setObject:resultDic forKey:@"ret"];
        } else {
            NSDictionary *errDict = @{@"err_code": @(error.code), @"err_desc": error.localizedDescription};
            [mDict setObject:[errDict copy] forKey:@"err"];
        }

        result(mDict);
    }];
}

- (void)_openAuthPageWithModel:(NSDictionary *)configDict result:(FlutterResult)result {
    if (!configDict
        || ![configDict isKindOfClass:[NSDictionary class]]
        || ![configDict count]
        || ![[configDict allKeys] containsObject:@"iOSConfig"]
        || ![[configDict objectForKey:@"iOSConfig"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *err = @{@"err_code": @"-999", @"err_desc": @"Open AuthPage Params Can't Be Empty!"};
        return result(@{@"ListenerType": @(0), @"err": err});
    }

    /**
     Convert Dict To UIConfigure
     */
    self.uiConfigure = [configDict objectForKey:@"iOSConfig"];
    FVSDKHyUIConfigure *configure = [self _convertToUIConfigure:self.uiConfigure];

    NSDictionary * (^sendResultToFlutter)(NSInteger, NSDictionary * _Nullable, NSError * _Nullable) = ^(NSInteger type, NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        NSMutableDictionary *mResult = [NSMutableDictionary dictionary];

        [mResult setObject:@(type) forKey:@"ListenerType"];
        if (resultDic
            && !error
            && ![resultDic isKindOfClass:[NSNull class]]) {
            [mResult setObject:resultDic forKey:@"ret"];
        } else if (error) {
            NSDictionary *errDict = @{@"err_code": @(error.code), @"err_desc": error.localizedDescription};
            [mResult setObject:[errDict copy] forKey:@"err"];
        }

        return [mResult copy];
    };


    __weak typeof(self) weakSelf = self;
    [FVSDKHyVerify openAuthPageWithModel:configure
                    openAuthPageListener:^(NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        if (weakSelf.eventCallBack) {
            weakSelf.eventCallBack(sendResultToFlutter(0, resultDic, error));
        } else {
            weakSelf.eventsData = sendResultToFlutter(0, resultDic, error);
        }
    } cancelAuthPageListener:^(NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        if (weakSelf.eventCallBack) {
            weakSelf.eventCallBack(sendResultToFlutter(1, resultDic, error));
        } else {
            weakSelf.eventsData = sendResultToFlutter(1, resultDic, error);
        }

    } oneKeyLoginListener:^(NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        if (weakSelf.eventCallBack) {
            weakSelf.eventCallBack(sendResultToFlutter(2, resultDic, error));
        } else {
            weakSelf.eventsData = sendResultToFlutter(2, resultDic, error);
        }

    }];
}

- (void)_mobileAuth:(NSDictionary *)params result:(FlutterResult)result {
    if (params
        && [params count]
        && ![params isKindOfClass:[NSNull class]]
        && [[params allKeys] containsObject:@"timeout"]
        && [[params objectForKey:@"timeout"] respondsToSelector:@selector(doubleValue)]) {
        double timeout = [[params objectForKey:@"timeout"] doubleValue];
        [FVSDKHyVerify setLoginAuthTimeOut:timeout];
    }

    [FVSDKHyVerify mobileAuth:^(NSDictionary * _Nullable resultDic, NSError * _Nullable error) {
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];

        if (resultDic
            && ![resultDic isKindOfClass:[NSNull class]]
            && [resultDic count]) {
            [mDict setObject:resultDic forKey:@"ret"];
        } else {
            NSDictionary *errDict = @{@"err_code": @(error.code), @"err_desc": error.localizedDescription};
            [mDict setObject:[errDict copy] forKey:@"err"];
        }

        result(mDict);
    }];
}

- (void)_mobileVerify:(NSDictionary *)params result:(FlutterResult)result {
    if (!params
        || [params isKindOfClass:[NSNull class]]
        || ![params count]) {
        return result([FlutterError errorWithCode:@"-999" message:@"Mobile Verify Params Can't Be Empty!" details:nil]);
    }

    if (![[params allKeys] containsObject:@"phoneNum"]) {
        return result([FlutterError errorWithCode:@"-999" message:@"Mobile Verify Params Can't Be Empty!" details:nil]);
    }

    if (![[params allKeys] containsObject:@"tokenInfo"]) {
        return result([FlutterError errorWithCode:@"-999" message:@"Mobile Verify Params Can't Be Empty!" details:nil]);
    }

    NSString *phoneNum = [params objectForKey:@"phoneNum"];
    NSDictionary *tokenInfo = [params objectForKey:@"tokenInfo"];

    double timeout = 4.0;
    if ([[params allKeys] containsObject:@"timeout"]
        && [[params objectForKey:@"timeout"] respondsToSelector:@selector(doubleValue)]) {
        timeout = [[params objectForKey:@"timeout"] doubleValue];
    }

    [FVSDKHyVerify mobileAuthWith:phoneNum
                            token:tokenInfo
                          timeOut:timeout
                       completion:^(NSDictionary * _Nullable resultDict, NSError * _Nullable error) {
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];

        if (resultDict
            && ![resultDict isKindOfClass:[NSNull class]]
            && [resultDict count]) {
            [mDict setObject:resultDict forKey:@"ret"];
        } else {
            NSDictionary *errDict = @{@"err_code": @(error.code), @"err_desc": error.localizedDescription};
            [mDict setObject:[errDict copy] forKey:@"err"];
        }

        result(mDict);
    }];
}

#pragma mark - FVSDKVerifyDelegate Methods
//授权页生命周期相关事件
-(void)fvVerifyAuthPageViewDidLoad:(UIViewController *)authVC
                          userInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    // 持有当前授权页面
    self.authPage = authVC;

    if (self.uiConfigure
        && ![self.uiConfigure isKindOfClass:[NSNull class]]
        && userInfo) {
        // 当前页面的所有子视图
        [self _configureAuthPageSubViewsWith:userInfo];

        // 新增视图
        [self _configureAddedSubviews];
    }
}

- (void)fvVerifyAuthPageViewWillAppear:(UIViewController *)authVC
                              userInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    // 实现所有子视图布局
    if (self.uiConfigure
        && ![self.uiConfigure isKindOfClass:[NSNull class]]
        && userInfo) {
        [self _configureAuthPageSubViewsLayoutWithUserInfo:userInfo];
    }
}

-(void)fvVerifyAuthPageViewWillTransition:(UIViewController *)authVC
                                   toSize:(CGSize)size
                withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
                                 userInfo:(FVSDKHyProtocolUserInfo*)userInfo {
    /// 横竖屏切换
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        NSDictionary *iOSConfig = [self uiConfigure];
        if (!iOSConfig
            || [iOSConfig isKindOfClass:[NSNull class]]) {
            return;
        }

        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
            NSDictionary *layouts = [iOSConfig objectForKey:@"portraitLayouts"];
            if (!layouts
                || [layouts isKindOfClass:[NSDictionary class]]) {
                return;
            }
            //布局_竖屏
            [self _reload_layoutSubViews:layouts withUserInfo:userInfo];
            [self _reload_layoutCustomSubViews:@"portraitLayout"];
        }else{
            //布局_横屏
            NSDictionary *layouts = [iOSConfig objectForKey:@"landscapeLayouts"];
            if (!layouts
                || ![layouts isKindOfClass:[NSDictionary class]]) {
                return;
            }

            [self _reload_layoutSubViews:layouts withUserInfo:userInfo];
            [self _reload_layoutCustomSubViews:@"landscapeLayout"];
        }
    } completion:nil];
}

- (void)fvVerifyAuthPageWillPresent:(UIViewController *)authVC
                           userInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    /// 自定义转场动画
}

//授权页释放
-(void)fvVerifyAuthPageDealloc {
    NSLog(@"授权页面已经释放");

    if ([[self customWidgets] count]) {
        [[self customWidgets] removeAllObjects];
    }
}

#pragma mark  - Custom View Click Method
- (void)_customBtnClicked:(UIButton *)btn {
    NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:@{@"ret": @{@"tag": @(btn.tag)}, @"ListenerType": @(3)}];
    
    if (self.eventCallBack) {
        self.eventCallBack(mDict);
    } else {
        self.eventsData = mDict;
    }
}

#pragma mark - Private Method
- (void)_configMethodMap {
    self.methodMap = @{
        @"getVersion": @(FVPluginMethodGetVersion),
        @"flyVerifyEnable": @(FVPluginMethodFVEnable),
        @"currentOperatorType": @(FVPluginMethodOperatorType),
        @"clearPhoneScripCache": @(FVPluginMethodClearCache),
        @"enableDebug": @(FVPluginMethodEnableDebug),
        @"uploadPrivacyStatus": @(FVPluginMethodUploadPrivacy),
        @"finishLoginVC": @(FVPluginMethodFinishLoginVC),
        @"hideLoading": @(FVPluginMethodHideLoading),
        @"preVerify": @(FVPluginMethodPreVerify),
        @"verify": @(FVPluginMethodVerify),
        @"mobileAuthToken": @(FVPluginMethodMobileAuthToken),
        @"mobileVerify": @(FVPluginMethodMobileVerify),
        @"platformVersion": @(FVPluginMethodPlatformVersion),
        @"register": @(FVPluginMethodRegister)
    };
}

- (FVSDKHyUIConfigure *)_convertToUIConfigure:(NSDictionary *)dict {
    FVSDKHyUIConfigure *configure = [[FVSDKHyUIConfigure alloc] init];
    configure.currentViewController = [self dc_findCurrentShowingViewController];
    
    if (!dict
        || ![dict isKindOfClass:[NSDictionary class]]
        || ![dict count]) {
        return configure;
    }

    // 隐藏NavBar
    if ([[dict allKeys] containsObject:@"navBarHidden"]
        && [[dict objectForKey:@"navBarHidden"] respondsToSelector:@selector(boolValue)]) {
        [configure setNavBarHidden:@([[dict objectForKey:@"navBarHidden"] boolValue])];
    }

    // 是否手动关闭授权页面
    if ([[dict allKeys] containsObject:@"manualDismiss"]
        && [[dict objectForKey:@"manualDismiss"] respondsToSelector:@selector(boolValue)]) {
        [configure setManualDismiss:@([[dict objectForKey:@"manualDismiss"] boolValue])];
    }

    // Status Bar
    if ([[dict allKeys] containsObject:@"prefersStatusBarHidden"]
        && [[dict objectForKey:@"prefersStatusBarHidden"] respondsToSelector:@selector(boolValue)]) {
        [configure setPrefersStatusBarHidden:@([[dict objectForKey:@"prefersStatusBarHidden"] boolValue])];
    }

    if ([[dict allKeys] containsObject:@"preferredStatusBarStyle"]
        && [[dict objectForKey:@"preferredStatusBarStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setPreferredStatusBarStyle:@([[dict objectForKey:@"preferredStatusBarStyle"] intValue])];
    }

    // 横竖屏支持
    if ([[dict allKeys] containsObject:@"shouldAutorotate"]
        && [[dict objectForKey:@"shouldAutorotate"] respondsToSelector:@selector(boolValue)]) {
        [configure setShouldAutorotate:@([[dict objectForKey:@"shouldAutorotate"] boolValue])];
    }

    if ([[dict allKeys] containsObject:@"supportedInterfaceOrientations"]
        && [[dict objectForKey:@"supportedInterfaceOrientations"] respondsToSelector:@selector(intValue)]) {
        [configure setSupportedInterfaceOrientations:@([[dict objectForKey:@"supportedInterfaceOrientations"] intValue])];
    }

    if ([[dict allKeys] containsObject:@"preferredInterfaceOrientationForPresentation"]
        && [[dict objectForKey:@"preferredInterfaceOrientationForPresentation"] respondsToSelector:@selector(intValue)]) {
        [configure setPreferredInterfaceOrientationForPresentation:@([[dict objectForKey:@"preferredInterfaceOrientationForPresentation"] intValue])];
    }

    //presnet方法的animate参数
    if ([[dict allKeys] containsObject:@"presentingWithAnimate"]
        && [[dict objectForKey:@"presentingWithAnimate"] respondsToSelector:@selector(boolValue)]) {
        [configure setPresentingWithAnimate:@([[dict objectForKey:@"presentingWithAnimate"] boolValue])];
    }

    /**modalTransitionStyle系统自带的弹出方式 仅支持以下三种
     UIModalTransitionStyleCoverVertical 底部弹出
     UIModalTransitionStyleCrossDissolve 淡入
     UIModalTransitionStyleFlipHorizontal 翻转显示
     */
    if ([[dict allKeys] containsObject:@"modalTransitionStyle"]
        && [[dict objectForKey:@"modalTransitionStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setModalTransitionStyle:@([[dict objectForKey:@"modalTransitionStyle"] intValue])];
    }

    /* UIModalPresentationStyle
     * 设置为UIModalPresentationOverFullScreen，可使模态背景透明，可实现弹窗授权页
     * 默认UIModalPresentationFullScreen
     * eg. @(UIModalPresentationOverFullScreen)
     */
    /*授权页 ModalPresentationStyle*/
    if ([[dict allKeys] containsObject:@"modalPresentationStyle"]
        && [[dict objectForKey:@"modalPresentationStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setModalPresentationStyle:@([[dict objectForKey:@"modalPresentationStyle"] intValue])];
    }

    /* UIUserInterfaceStyle
     * UIUserInterfaceStyleUnspecified - 不指定样式，跟随系统设置进行展示
     * UIUserInterfaceStyleLight       - 明亮
     * UIUserInterfaceStyleDark,       - 暗黑 仅对iOS13+系统有效
     */
    /*授权页 UIUserInterfaceStyle,默认:UIUserInterfaceStyleLight,eg. @(UIUserInterfaceStyleLight)*/
    if ([[dict allKeys] containsObject:@"overrideUserInterfaceStyle"]
        && [[dict objectForKey:@"overrideUserInterfaceStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setOverrideUserInterfaceStyle:@([[dict objectForKey:@"overrideUserInterfaceStyle"] intValue])];
    }

    // Check Box Value
    if ([[dict allKeys] containsObject:@"checkDefaultState"]
        && [[dict objectForKey:@"checkDefaultState"] respondsToSelector:@selector(boolValue)]) {
        [configure setCheckDefaultState:@([[dict objectForKey:@"checkDefaultState"] boolValue])];
    }

    // 协议相关
    if ([[dict allKeys] containsObject:@"privacySettings"]
        && [[dict objectForKey:@"privacySettings"] isKindOfClass:[NSArray class]]
        && [[dict objectForKey:@"privacySettings"] count]) {
        NSArray<NSDictionary *> *list = [dict objectForKey:@"privacySettings"];
        NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:list.count];
        for (NSDictionary *privacyDict in list) {
            FVSDKHyPrivacyText *privacyText = [[FVSDKHyPrivacyText alloc] init];

            privacyText.text = [privacyDict objectForKey:@"text"];
            if ([[privacyDict allKeys] containsObject:@"textFontName"]
                && [[privacyDict objectForKey:@"textFontName"] isKindOfClass:[NSString class]]
                && [self _isFontValueJudeName:[privacyDict objectForKey:@"textFontName"]]
                && [[privacyDict allKeys] containsObject:@"textFont"]) {
                privacyText.textFont = [UIFont fontWithName:[privacyDict objectForKey:@"textFontName"]
                                                       size:[[privacyDict objectForKey:@"textFont"] floatValue]];
            } else if ([[privacyDict allKeys] containsObject:@"textFont"]) {
                privacyText.textFont = [UIFont systemFontOfSize:[[privacyDict objectForKey:@"textFont"] floatValue]];
            }

            if ([[privacyDict allKeys] containsObject:@"textColor"]) {
                privacyText.textColor = [UIColor colorWithHexString:[privacyDict objectForKey:@"textColor"]];
            }

            privacyText.webTitleText = [privacyDict objectForKey:@"webTitleText"];
            privacyText.textLinkString = [privacyDict objectForKey:@"textLinkString"];
            if ([[privacyDict objectForKey:@"isOperatorPlaceHolder"] respondsToSelector:@selector(boolValue)]) {
                privacyText.isOperatorPlaceHolder = [[privacyDict objectForKey:@"isOperatorPlaceHolder"] boolValue];
            }

            // 文字富文本样式需和iOS原生代码一致
            if ([[privacyDict allKeys] containsObject:@"textAttribute"]
                && [[privacyDict objectForKey:@"textAttribute"] isKindOfClass:[NSDictionary class]]
                && [[privacyDict objectForKey:@"textAttribute"] count]) {
                privacyText.textAttribute = [privacyDict objectForKey:@"textAttribute"];
            }

            [mArray addObject:privacyText];
        }

        if (mArray
            && [mArray count]) {
            [configure setPrivacySettings:[mArray copy]];
        }
    }
    // 隐私条款对其方式(例:@(NSTextAlignmentCenter)
    if ([[dict allKeys] containsObject:@"privacyTextAlignment"]
        && [[dict objectForKey:@"privacyTextAlignment"] respondsToSelector:@selector(intValue)]) {
        [configure setPrivacyTextAlignment:@([[dict objectForKey:@"privacyTextAlignment"] intValue])];
    }
    // 隐私条款多行时行距 CGFloat (例:@(4.0))
    if ([[dict allKeys] containsObject:@"privacyLineSpacing"]
        && [[dict objectForKey:@"privacyLineSpacing"] respondsToSelector:@selector(floatValue)]) {
        [configure setPrivacyLineSpacing:@([[dict objectForKey:@"privacyLineSpacing"] floatValue])];
    }

    /*协议页使用模态弹出（默认使用Push)*/
    if ([[dict allKeys] containsObject:@"showPrivacyWebVCByPresent"]
        && [[dict objectForKey:@"showPrivacyWebVCByPresent"] respondsToSelector:@selector(boolValue)]) {
        [configure setShowPrivacyWebVCByPresent:@([[dict objectForKey:@"showPrivacyWebVCByPresent"] boolValue])];
    }
    /*协议页状态栏样式 默认：UIStatusBarStyleDefault*/
    if ([[dict allKeys] containsObject:@"privacyWebVCPreferredStatusBarStyle"]
        && [[dict objectForKey:@"privacyWebVCPreferredStatusBarStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setPrivacyWebVCPreferredStatusBarStyle:@([[dict objectForKey:@"privacyWebVCPreferredStatusBarStyle"] intValue])];
    }
    /*协议页 ModalPresentationStyle （协议页使用模态弹出时生效）*/
    if ([[dict allKeys] containsObject:@"privacyWebVCModalPresentationStyle"]
        && [[dict objectForKey:@"privacyWebVCModalPresentationStyle"] respondsToSelector:@selector(intValue)]) {
        [configure setPrivacyWebVCModalPresentationStyle:@([[dict objectForKey:@"privacyWebVCModalPresentationStyle"] intValue])];
    }

    return configure;
}

#pragma mark - Configure Layouts
- (void)_configureAuthPageSubViewsLayoutWithUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if (!userInfo) {
        // 如果UserInfo为空则直接返回
        return;
    }

    NSDictionary *iOSConfig = [self uiConfigure];
    if (!iOSConfig
        || [iOSConfig isKindOfClass:[NSNull class]]) {
        return;
    }

    // 默认设置Portrait Layouts
    if ([[iOSConfig allKeys] containsObject:@"portraitLayouts"]
        && [[iOSConfig objectForKey:@"portraitLayouts"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *portaitLayouts = [iOSConfig objectForKey:@"portraitLayouts"];
        [self _reload_layoutSubViews:portaitLayouts withUserInfo:userInfo];
    }

    [self _reload_layoutCustomSubViews:@"portraitLayout"];
}

- (void)_reload_layoutCustomSubViews:(NSString *)layoutOrientation {
    if ([self customWidgets]
        && [[self customWidgets] count]) {
        for (NSDictionary *widgetConfig in [self customWidgets]) {
            UIView *subView = [[[self authPage] view] viewWithTag:[[widgetConfig objectForKey:@"widgetID"] intValue]];
            if (!subView) {
                continue;
            }

            NSDictionary *layout = [widgetConfig objectForKey:layoutOrientation];
            if (!layout
                || ![layout isKindOfClass:[NSDictionary class]]
                || ![layout count]) {
                continue;
            }

            [self _updateConstraintsAt:[[self authPage] view]
                               subView:subView
                                layout:layout];
        }
    }
}

- (void)_reload_layoutSubViews:(NSDictionary *)layouts withUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if (!self.authPage) {
        // 如果授权页面为空，则直接返回
        return;
    }

    // 授权页面自带的子视图
    if ([[layouts allKeys] containsObject:@"loginBtnLayout"]
        && [[layouts objectForKey:@"loginBtnLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo loginButton]
        && ![[userInfo loginButton] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *loginBtnLayout = [layouts objectForKey:@"loginBtnLayout"];
        [self _updateConstraintsAt:[[self authPage] view]
                           subView:[userInfo loginButton]
                            layout:loginBtnLayout];
    }

    if ([[layouts allKeys] containsObject:@"phoneLabelLayout"]
        && [[layouts objectForKey:@"phoneLabelLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo phoneLabel]
        && ![[userInfo phoneLabel] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *phoneLabelLayout = [layouts objectForKey:@"phoneLabelLayout"];
        [self _updateConstraintsAt:[[self authPage] view]
                           subView:[userInfo phoneLabel]
                            layout:phoneLabelLayout];
    }

    if ([[layouts allKeys] containsObject:@"sloganLabelLayout"]
        && [[layouts objectForKey:@"sloganLabelLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo sloganLabel]
        && ![[userInfo sloganLabel] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *solganLabelLayout = [layouts objectForKey:@"sloganLabelLayout"];
        [self _updateConstraintsAt:[[self authPage] view]
                           subView:[userInfo sloganLabel]
                            layout:solganLabelLayout];
    }

    if ([[layouts allKeys] containsObject:@"logoImageViewLayout"]
        && [[layouts objectForKey:@"logoImageViewLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo logoImageView]
        && ![[userInfo logoImageView] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *logoIVLayout = [layouts objectForKey:@"logoImageViewLayout"];
        [self _updateConstraintsAt:[[self authPage] view]
                           subView:[userInfo logoImageView]
                            layout:logoIVLayout];
    }

    if ([[layouts allKeys] containsObject:@"privacyTextViewLayout"]
        && [[layouts objectForKey:@"privacyTextViewLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo privacyTextView]
        && ![[userInfo privacyTextView] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *privacyTVLayout = [layouts objectForKey:@"privacyTextViewLayout"];
        [self _updateConstraintsAt:[[self authPage] view]
                           subView:[userInfo privacyTextView]
                            layout:privacyTVLayout];
    }

    if ([[layouts allKeys] containsObject:@"checkBoxLayout"]
        && [[layouts objectForKey:@"checkBoxLayout"] isKindOfClass:[NSDictionary class]]
        && [userInfo checkBox] && [userInfo privacyTextView]
        && ![[userInfo checkBox] isHidden]) { // 如果已经隐藏，则不再配置
        NSDictionary *checkBoxLayout = [layouts objectForKey:@"checkBoxLayout"];
        [self _updatePrivacyCheckBoxConstraintsAt:[userInfo privacyTextView]
                                          subView:[userInfo checkBox]
                                         subView2:[[self authPage] view]
                                           layout:checkBoxLayout];
    }
}

- (void)_updateConstraintsAt:(UIView *)superView
                     subView:(UIView *)subView
                      layout:(NSDictionary *)layoutInfo {
    NSDictionary *layouts = [NSDictionary dictionaryWithDictionary:layoutInfo];

    [self _removeConstraintsWith:subView];
    subView.translatesAutoresizingMaskIntoConstraints = NO;

    BOOL (^layoutIFValid) (NSString *) = ^(NSString *key) {
        BOOL isContains = [[layouts allKeys] containsObject:key];
        BOOL iFValid = [[layouts objectForKey:key] respondsToSelector:@selector(floatValue)];
        BOOL result = isContains && iFValid;
        return result;
    };

    if (layoutIFValid(@"layoutTop")) {
        CGFloat layoutTop = [[layouts objectForKey:@"layoutTop"] floatValue];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:superView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:layoutTop];
        [superView addConstraint:topConstraint];
    }

    if (layoutIFValid(@"layoutLeading")) {
        CGFloat layoutLeading = [[layouts objectForKey:@"layoutLeading"] floatValue];
        NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1.0
                                                                              constant:layoutLeading];
        [superView addConstraint:leadingConstraint];
    }

    if (layoutIFValid(@"layoutBottom")) {
        CGFloat layoutBottom = [[layouts objectForKey:@"layoutBottom"] floatValue];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:superView
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:layoutBottom];
        [superView addConstraint:bottomConstraint];
    }

    if (layoutIFValid(@"layoutTrailing")) {
        CGFloat layoutTrailing = [[layouts objectForKey:@"layoutTrailing"] floatValue];
        NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                              attribute:NSLayoutAttributeTrailing
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:superView
                                                                              attribute:NSLayoutAttributeTrailing
                                                                             multiplier:1.0
                                                                               constant:layoutTrailing];
        [superView addConstraint:trailingConstraint];
    }

    if (layoutIFValid(@"layoutCenterX")) {
        CGFloat layoutCenterX = [[layouts objectForKey:@"layoutCenterX"] floatValue];
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:layoutCenterX];
        [superView addConstraint:centerXConstraint];
    }

    if (layoutIFValid(@"layoutCenterY")) {
        CGFloat layoutCenterY = [[layouts objectForKey:@"layoutCenterY"] floatValue];
        NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:layoutCenterY];
        [superView addConstraint:centerYConstraint];
    }

    if (layoutIFValid(@"layoutWidth")) {
        CGFloat layoutWidth = [[layouts objectForKey:@"layoutWidth"] floatValue];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:layoutWidth];
        [superView addConstraint:widthConstraint];
    }

    if (layoutIFValid(@"layoutHeight")) {
        CGFloat layoutHeight = [[layouts objectForKey:@"layoutHeight"] floatValue];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:1.0
                                                                             constant:layoutHeight];
        [superView addConstraint:heightConstraint];
    }

    [superView layoutIfNeeded];
}

- (void)_updatePrivacyCheckBoxConstraintsAt:(UIView *)superView
                                    subView:(UIView *)subView
                                    subView2:(UIView *)subView2
                                     layout:(NSDictionary *)layoutInfo {
    NSDictionary *layouts = [NSDictionary dictionaryWithDictionary:layoutInfo];

    [self _removeConstraintsWith:subView];
    subView.translatesAutoresizingMaskIntoConstraints = NO;

    BOOL (^layoutIFValid) (NSString *) = ^(NSString *key) {
        BOOL isContains = [[layouts allKeys] containsObject:key];
        BOOL iFValid = [[layouts objectForKey:key] respondsToSelector:@selector(floatValue)];
        BOOL result = isContains && iFValid;
        return result;
    };
    
    BOOL (^layoutIFValidBool) (NSString *) = ^(NSString *key) {
        BOOL isContains = [[layouts allKeys] containsObject:key];
        BOOL iFValid = [[layouts objectForKey:key] respondsToSelector:@selector(boolValue)];
        BOOL result = isContains && iFValid;
        return result;
    };
    
    
    //相对授权页
    if (layoutIFValidBool(@"layoutToSuperView")) {
        bool layoutToSuperView = [[layouts objectForKey:@"layoutToSuperView"] boolValue];
        if (layoutToSuperView) {
            superView = subView2;
        }

    }
    

    if (layoutIFValid(@"layoutTop")) {
        CGFloat layoutTop = [[layouts objectForKey:@"layoutTop"] floatValue];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:superView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:layoutTop];
        [_authPage.view addConstraint:topConstraint];
        [topConstraint setActive:YES];
    }

    if (layoutIFValid(@"layoutLeading")) {
        CGFloat layoutLeading = [[layouts objectForKey:@"layoutLeading"] floatValue];
        NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1.0
                                                                              constant:layoutLeading];
        [_authPage.view addConstraint:leadingConstraint];
    }

    if (layoutIFValid(@"layoutBottom")) {
        CGFloat layoutBottom = [[layouts objectForKey:@"layoutBottom"] floatValue];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:superView
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:layoutBottom];
        [_authPage.view addConstraint:bottomConstraint];
    }

    if (layoutIFValid(@"layoutTrailing")) {
        CGFloat layoutTrailing = [[layouts objectForKey:@"layoutTrailing"] floatValue];
        NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                              attribute:NSLayoutAttributeTrailing
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:superView
                                                                              attribute:NSLayoutAttributeTrailing
                                                                             multiplier:1.0
                                                                               constant:layoutTrailing];
        [_authPage.view addConstraint:trailingConstraint];
    }

    if (layoutIFValid(@"layoutCenterX")) {
        CGFloat layoutCenterX = [[layouts objectForKey:@"layoutCenterX"] floatValue];
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:layoutCenterX];
        [_authPage.view addConstraint:centerXConstraint];
    }

    if (layoutIFValid(@"layoutCenterY")) {
        CGFloat layoutCenterY = [[layouts objectForKey:@"layoutCenterY"] floatValue];
        NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:superView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:layoutCenterY];
        [_authPage.view addConstraint:centerYConstraint];
    }

    if (layoutIFValid(@"layoutWidth")) {
        CGFloat layoutWidth = [[layouts objectForKey:@"layoutWidth"] floatValue];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:layoutWidth];
        [_authPage.view addConstraint:widthConstraint];
    }

    if (layoutIFValid(@"layoutHeight")) {
        CGFloat layoutHeight = [[layouts objectForKey:@"layoutHeight"] floatValue];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:1.0
                                                                             constant:layoutHeight];
        [_authPage.view addConstraint:heightConstraint];
    }
    if (layoutIFValid(@"layoutRightSpaceToPrivacyLeft")) {
        CGFloat layoutTop = [[layouts objectForKey:@"layoutRightSpaceToPrivacyLeft"] floatValue];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                         attribute:NSLayoutAttributeRight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:superView
                                                                         attribute:NSLayoutAttributeLeft
                                                                        multiplier:1.0
                                                                          constant:layoutTop];
        [_authPage.view addConstraint:topConstraint];
        [topConstraint setActive:YES];
    }
    if (layoutIFValid(@"layoutLeftSpaceToPrivacyRight")) {
        CGFloat layoutTop = [[layouts objectForKey:@"layoutLeftSpaceToPrivacyRight"] floatValue];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:subView
                                                                         attribute:NSLayoutAttributeLeft
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:superView
                                                                         attribute:NSLayoutAttributeRight
                                                                        multiplier:1.0
                                                                          constant:layoutTop];
        [_authPage.view addConstraint:topConstraint];
        [topConstraint setActive:YES];
    }

    [superView layoutIfNeeded];
}

#pragma mark - Configure SubViews

- (void)_configureAddedSubviews {
    if (!self.authPage) {
        return;
    }

    NSDictionary *iOSConfig = [self uiConfigure];
    if (![[iOSConfig allKeys] containsObject:@"widgets"]
        || ![[iOSConfig objectForKey:@"widgets"] isKindOfClass:[NSArray class]]
        || ![[iOSConfig objectForKey:@"widgets"] count]) {
        return;
    }

    if ([self customWidgets]
        && [[self customWidgets] count]) {
        [[self customWidgets] removeAllObjects];
    }
    
    NSArray<NSDictionary *> *widgets = [iOSConfig objectForKey:@"widgets"];
    for (NSDictionary *widgetConfig in widgets) {
        if (![[widgetConfig allKeys] containsObject:@"widgetType"]
            || [[widgetConfig objectForKey:@"widgetType"] isKindOfClass:[NSNull class]]
            || ![[widgetConfig allKeys] containsObject:@"widgetID"]
            || ![[widgetConfig objectForKey:@"widgetID"] respondsToSelector:@selector(intValue)]) {
            // 如果不包含widgetID 或widgetType，则直接下一轮
            continue;
        }

        if ([[widgetConfig allKeys] containsObject:@"navPosition"]
            && [[widgetConfig objectForKey:@"navPosition"] isKindOfClass:[NSString class]]
            && [[widgetConfig objectForKey:@"navPosition"] length]) {
            // 配置自定义导航栏
            [self _configureNavBarCustomView:widgetConfig];
            return;
        }

        UIView *customView = [self _createCustomSubView:widgetConfig];
        [self _setupCustomSubView:customView config:widgetConfig];
        [[[self authPage] view] addSubview:customView];
        [[[self authPage] view] sendSubviewToBack:customView];
        


        [[self customWidgets] addObject:widgetConfig];
    }
}

- (void)_configureNavBarCustomView:(NSDictionary *)widgetConfig {

    CGFloat width = 0.0;
    CGFloat height = 0.0;
    NSDictionary *portraitLayout = [widgetConfig objectForKey:@"portraitLayout"];
    if ([[portraitLayout allKeys] containsObject:@"layoutWidth"]
        && [[portraitLayout objectForKey:@"layoutWidth"] respondsToSelector:@selector(floatValue)]) {
        width = [[portraitLayout objectForKey:@"layoutWidth"] floatValue];
    }

    if ([[portraitLayout allKeys] containsObject:@"layoutHeight"]
        && [[portraitLayout objectForKey:@"layoutHeight"] respondsToSelector:@selector(floatValue)]) {
        height = [[portraitLayout objectForKey:@"layoutHeight"] floatValue];
    }

    UIView *customSubView = [self _createCustomSubView:widgetConfig];
    [self _setupCustomSubView:customSubView config:widgetConfig];
    if (!customSubView) {
        NSLog(@"创建自定义视图失败!");
        return;
    }
    customSubView.frame = CGRectMake(0, 0, width, height);

    UIBarButtonItem * barItem = [[UIBarButtonItem alloc] initWithCustomView:customSubView];

    NSString *navPosition = [widgetConfig objectForKey:@"navPosition"];
    if ([navPosition isEqualToString:@"navLeft"]) {
        [[[self authPage] navigationItem] setLeftBarButtonItem:barItem];
    } else if ([navPosition isEqualToString:@"navRight"]) {
        [[[self authPage] navigationItem] setRightBarButtonItem:barItem];
    }
}

- (UIView *)_createCustomSubView:(NSDictionary *)widgetConfig {
    NSString *widgetType = [widgetConfig objectForKey:@"widgetType"];
    int tag = [[widgetConfig objectForKey:@"widgetID"] intValue];

    // Tools method
    NSString *(^toGetStringContent)(NSString *) = ^(NSString *key) {
        NSString *content = nil;

        if (!key
            || ![key length]) {
            return content;
        }

        if ([[widgetConfig allKeys] containsObject:key]
            && [[widgetConfig objectForKey:key] isKindOfClass:[NSString class]]
            && [[widgetConfig objectForKey:key] length]) {
            content = [widgetConfig objectForKey:key];
        }
        return content;
    };

    if ([widgetType isEqualToString:@"label"]) { // 自定义视图类型为Label
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        NSString *text = toGetStringContent(@"text");
        if (text) {
            label.text = text;
        }
        
        NSString *textColor = toGetStringContent(@"textColor");
        if (textColor) {
            label.textColor = [UIColor colorWithHexString:textColor];
        }
        
        float fontSize = [widgetConfig[@"fontSize"] floatValue];
        if (fontSize > 0) {
            BOOL isBodyFont = [widgetConfig[@"isBodyFont"] boolValue];
            if (isBodyFont) {
                label.font = [UIFont boldSystemFontOfSize:fontSize];
            }else{
                label.font = [UIFont systemFontOfSize:fontSize];
            }
        }
        
        NSInteger labelTextAlignment = [widgetConfig[@"textAlignment"] integerValue];
        if (widgetConfig[@"textAlignment"]) {
            label.textAlignment = labelTextAlignment;
        }

        label.tag = tag;

        return label;
    } else if ([widgetType isEqualToString:@"imageView"]) { // 自定义视图类型为ImageView
        UIImageView *imageView = [[UIImageView alloc] init];

        NSString *imaName = toGetStringContent(@"image");
        if (imaName) {
            [imageView setImage:[UIImage lookupImageKeyForAsset:imaName flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false]];
        }
        
        NSInteger contentMode = [widgetConfig[@"contentMode"] integerValue];
        if (widgetConfig[@"contentMode"]) {
            imageView.contentMode = contentMode;
        }

        imageView.tag = tag;

        return imageView;
    } else if ([widgetType isEqualToString:@"button"]) { // 自定义视图类型为button
        __block UIButton *btn = [[UIButton alloc]init];
        
        NSString *title = toGetStringContent(@"title");
        if (title) {
            [btn setTitle:title forState:(UIControlStateNormal)];
        }
        NSString *titleColor = toGetStringContent(@"titleColor");
        if (title) {
            [btn setTitleColor:[UIColor colorWithHexString:titleColor] forState:UIControlStateNormal];
        }
        float titleFontSize = [widgetConfig[@"titleFontSize"] floatValue];
        if (titleFontSize > 0) {
            BOOL isBodyFont = [widgetConfig[@"isBodyFont"] boolValue];
            if (isBodyFont) {
                btn.titleLabel.font = [UIFont boldSystemFontOfSize:titleFontSize];
            }else{
                btn.titleLabel.font = [UIFont systemFontOfSize:titleFontSize];
            }
        }

        //image
        NSString * normalImage = widgetConfig[@"normalImage"];
        if ([normalImage isKindOfClass:NSString.class] && normalImage.length > 0) {
            [btn setImage:[UIImage lookupImageKeyForAsset:normalImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateNormal];
        }
        NSString * highlightedImage = widgetConfig[@"highlightedImage"];
        if ([highlightedImage isKindOfClass:NSString.class] && highlightedImage.length > 0) {
            [btn setImage:[UIImage lookupImageKeyForAsset:highlightedImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
        NSString * disabledImage = widgetConfig[@"disabledImage"];
        if ([disabledImage isKindOfClass:NSString.class] && disabledImage.length > 0) {
            [btn setImage:[UIImage lookupImageKeyForAsset:disabledImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
        NSString * selectedImage = widgetConfig[@"selectedImage"];
        if ([selectedImage isKindOfClass:NSString.class] && selectedImage.length > 0) {
            [btn setImage:[UIImage lookupImageKeyForAsset:selectedImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
        
        
        NSString * normalBackgroundImage = widgetConfig[@"normalBackgroundImage"];
        if ([normalBackgroundImage isKindOfClass:NSString.class] && normalBackgroundImage.length > 0) {
            [btn setBackgroundImage:[UIImage lookupImageKeyForAsset:normalBackgroundImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateNormal];
        }
        NSString * highlightedBackgroundImage = widgetConfig[@"highlightedBackgroundImage"];
        if ([highlightedBackgroundImage isKindOfClass:NSString.class] && highlightedBackgroundImage.length > 0) {
            [btn setBackgroundImage:[UIImage lookupImageKeyForAsset:highlightedBackgroundImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
        NSString * disabledBackgroundImage = widgetConfig[@"disabledBackgroundImage"];
        if ([disabledBackgroundImage isKindOfClass:NSString.class] && disabledBackgroundImage.length > 0) {
            [btn setBackgroundImage:[UIImage lookupImageKeyForAsset:disabledBackgroundImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
        NSString * selectedBackgroundImage = widgetConfig[@"selectedBackgroundImage"];
        if ([selectedBackgroundImage isKindOfClass:NSString.class] && selectedBackgroundImage.length > 0) {
            [btn setBackgroundImage:[UIImage lookupImageKeyForAsset:selectedBackgroundImage flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
        }
   
        [btn addTarget:self action:@selector(_customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];

        btn.tag = tag;

        return btn;
    }

    return nil;
}

- (void)_setupCustomSubView:(UIView*)customview config:(NSDictionary *)widgetConfig {
    
    if (customview == nil) {
        return;
    }
    

    NSString * backgroundColor = widgetConfig[@"backgroundColor"];
    if (backgroundColor) {
        customview.backgroundColor = [UIColor colorWithHexString:backgroundColor];
    }
    
    float cornerRadius = [widgetConfig[@"cornerRadius"] floatValue];
    if (widgetConfig[@"cornerRadius"]) {
        customview.layer.cornerRadius = cornerRadius;
        customview.layer.masksToBounds = true;
    }
    float borderWidth = [widgetConfig[@"borderWidth"] floatValue];
    if (widgetConfig[@"borderWidth"]) {
        customview.layer.borderWidth = borderWidth;
    }

    NSString * borderColor = widgetConfig[@"borderColor"];
    if (borderColor) {
        customview.layer.borderColor = [UIColor colorWithHexString:borderColor].CGColor;
    }
    
//    FlutterEngine;
    
//    customview.layer.shadowColor;
//    customview.layer.shadowOffset;
//    customview.layer.shadowOpacity;


}

- (void)_configureAuthPageSubViewsWith:(FVSDKHyProtocolUserInfo *)userInfo {
    if (!userInfo) {
        // 如果UserInfo为空，则直接返回
        return;
    }

    NSDictionary *iOSConfig = [self uiConfigure];
    for (NSString *configureKey in [iOSConfig allKeys]) {
        if ([configureKey hasPrefix:@"loginBtn"]) {
            // Config Login Btn
            [self _configureLoginBtn:configureKey withConfig:iOSConfig atUserInfo:userInfo];
        } else if ([configureKey hasPrefix:@"logo"]) {
            // Config Logo
            [self _configureLogoIV:configureKey withConfig:iOSConfig atUserInfo:userInfo];
        } else if ([configureKey hasPrefix:@"phone"] || [configureKey hasPrefix:@"number"]) {
            // Config Phone Label
            [self _configurePhoneLabel:configureKey withConfig:iOSConfig atUserInfo:userInfo];
        } else if ([configureKey hasPrefix:@"check"] || [configureKey hasPrefix:@"unchecked"]) {
            // Config Check Box
            [self _configureCheckBox:configureKey withConfig:iOSConfig atUserInfo:userInfo];
        } else if ([configureKey hasPrefix:@"slogan"]) {
            // Config Slogan
            [self _configureSlogan:configureKey withConfig:iOSConfig atUserInfo:userInfo];
        } else if ([configureKey hasPrefix:@"privacy"]) {
            // Config Privacy
            if ([configureKey isEqualToString:@"privacyHidden"]
                && [[iOSConfig objectForKey:configureKey] respondsToSelector:@selector(boolValue)]) {
                BOOL isHidden = [[iOSConfig objectForKey:configureKey] boolValue];
                [[userInfo privacyTextView] setHidden:isHidden];
            }
        } else if ([configureKey hasPrefix:@"backBtn"]) {
            // Config Back Button
            if ([configureKey isEqualToString:@"backBtnHidden"]
                && [[iOSConfig objectForKey:configureKey] respondsToSelector:@selector(boolValue)]) {
                BOOL isHidden = [[iOSConfig objectForKey:configureKey] boolValue];
                [[userInfo backButton] setHidden:isHidden];
            } else if ([configureKey isEqualToString:@"backBtnImageName"]
                       && [[iOSConfig objectForKey:configureKey] isKindOfClass:[NSString class]]
                       && [[iOSConfig objectForKey:configureKey] length]) {
                [[userInfo backButton] setImage:[UIImage lookupImageKeyForAsset:[iOSConfig objectForKey:configureKey] flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)_configureLoginBtn:(NSString *)key withConfig:(NSDictionary *)config atUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if ([key isEqualToString:@"loginBtnText"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo loginButton] setTitle:[config objectForKey:key] forState:UIControlStateNormal];
    }

    if ([key isEqualToString:@"loginBtnTextColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo loginButton] setTitleColor:[UIColor colorWithHexString:[config objectForKey:key]] forState:UIControlStateNormal];
    }

    if ([key isEqualToString:@"loginBtnBgColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo loginButton] setBackgroundColor:[UIColor colorWithHexString:[config objectForKey:key]]];
    }

    if ([key isEqualToString:@"loginBtnBorderWidth"]
        && [config objectForKey:key]) {
        [[userInfo loginButton].layer setBorderWidth:[[config objectForKey:key] floatValue]];
    }

    if ([key isEqualToString:@"loginBtnCornerRadius"]
        && [config objectForKey:key]) {
        [[userInfo loginButton].layer setCornerRadius:[[config objectForKey:key] floatValue]];
        [[[userInfo loginButton] layer] setMasksToBounds:YES];
    }

    if ([key isEqualToString:@"loginBtnBorderColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[[userInfo loginButton] layer] setBorderColor:[UIColor colorWithHexString:[config objectForKey:key]].CGColor];
    }

    if ([key isEqualToString:@"loginBtnBgImgNames"]
        && [[config objectForKey:key] isKindOfClass:[NSArray class]]
        && [[config objectForKey:key] count]) {
        NSArray<NSString *> *imageNames = [config objectForKey:key];
        [imageNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj
                && [obj isKindOfClass:[NSString class]]
                && [obj length]) {
                switch (idx) {
                    case 0:
                        [[userInfo loginButton] setBackgroundImage:[UIImage lookupImageKeyForAsset:obj flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateNormal];
                        break;
                    case 1:
                        [[userInfo loginButton] setBackgroundImage:[UIImage lookupImageKeyForAsset:obj flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateDisabled];
                        break;
                    case 2:
                        [[userInfo loginButton] setBackgroundImage:[UIImage lookupImageKeyForAsset:obj flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateHighlighted];
                        break;
                    default:
                        *stop = YES;
                        break;
                }
            }
        }];
    }
}

- (void)_configureLogoIV:(NSString *)key withConfig:(NSDictionary *)config atUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if ([key isEqualToString:@"logoHidden"]
        && [[config objectForKey:@"logoHidden"] respondsToSelector:@selector(boolValue)]) {
        BOOL isHidden = [[config objectForKey:@"logoHidden"] boolValue];

        [[userInfo logoImageView] setHidden:isHidden];
        if (isHidden) { // 如果LogoImageView Hidden，则不再额外配置
            return;
        }
    }

    if ([key isEqualToString:@"logoImageName"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo logoImageView] setImage:[UIImage lookupImageKeyForAsset:[config objectForKey:key] flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false]];
    }

    if ([key isEqualToString:@"logoCornerRadius"]
        && [[config objectForKey:key] respondsToSelector:@selector(floatValue)]) {
        [[[userInfo logoImageView] layer] setCornerRadius:[[config objectForKey:key] floatValue]];
        [[[userInfo logoImageView] layer] setMasksToBounds:YES];
    }
}

- (void)_configurePhoneLabel:(NSString *)key withConfig:(NSDictionary *)config atUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
//    if ([key isEqualToString:@"phoneHidden"]
//        && [[config objectForKey:key] respondsToSelector:@selector(boolValue)]) {
//        BOOL isHidden = [[config objectForKey:key] boolValue];
//
//        [[userInfo phoneLabel] setHidden:isHidden];
//        if (isHidden) { // 如果隐藏PhoneLabel，则不需要其他配置
//            return;
//        }
//    }

    if ([key isEqualToString:@"numberColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo phoneLabel] setTextColor:[UIColor colorWithHexString:[config objectForKey:key]]];
    }

    if ([key isEqualToString:@"numberBgColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo phoneLabel] setBackgroundColor:[UIColor colorWithHexString:[config objectForKey:key]]];
    }

    if ([key isEqualToString:@"phoneBorderWidth"]
        && [[config objectForKey:key] respondsToSelector:@selector(floatValue)]) {
        [[[userInfo phoneLabel] layer] setBorderWidth:[[config objectForKey:key] floatValue]];
    }

    if ([key isEqualToString:@"phoneCorner"]
        && [[config objectForKey:key] respondsToSelector:@selector(floatValue)]) {
        [[[userInfo phoneLabel] layer] setCornerRadius:[[config objectForKey:key] floatValue]];
        [[[userInfo phoneLabel] layer] setMasksToBounds:YES];
    }

    if ([key isEqualToString:@"phoneBorderColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[[userInfo phoneLabel] layer] setBorderColor:[UIColor colorWithHexString:[config objectForKey:key]].CGColor];
    }

    if ([key isEqualToString:@"numberTextAlignment"]
        && [[config objectForKey:key] respondsToSelector:@selector(intValue)]) {
        [[userInfo phoneLabel] setTextAlignment:[[config objectForKey:key] intValue]];
    }
}

- (void)_configureCheckBox:(NSString *)key withConfig:(NSDictionary *)config atUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if ([key isEqualToString:@"checkHidden"]
        && [[config objectForKey:key] respondsToSelector:@selector(boolValue)]) {
        BOOL isHidden = [[config objectForKey:key] boolValue];

        [[userInfo checkBox] setHidden:isHidden];

        if (isHidden) {
            return;
        }
    }

    if ([key isEqualToString:@"checkDefaultState"]
        && [[config objectForKey:key] respondsToSelector:@selector(boolValue)]) {
        BOOL isSelected = [[config objectForKey:key] boolValue];

        [[userInfo checkBox] setSelected:isSelected];
    }

    if ([key isEqualToString:@"checkedImgName"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo checkBox] setImage:[UIImage lookupImageKeyForAsset:[config objectForKey:key] flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateSelected];
    }

    if ([key isEqualToString:@"uncheckedImgName"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo checkBox] setImage:[UIImage lookupImageKeyForAsset:[config objectForKey:key] flutterRegister:self.registrar fromPackage:nil fromXcodeProject:false] forState:UIControlStateNormal];
    }
}

- (void)_configureSlogan:(NSString *)key withConfig:(NSDictionary *)config atUserInfo:(FVSDKHyProtocolUserInfo *)userInfo {
    if ([key isEqualToString:@"sloganHidden"]
        && [[config objectForKey:key] respondsToSelector:@selector(boolValue)]) {
        BOOL isHidden = [[config objectForKey:key] boolValue];

        [[userInfo sloganLabel] setHidden:isHidden];
        if (isHidden) {
            return;
        }
    }

    if ([key isEqualToString:@"sloganText"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo sloganLabel] setText:[config objectForKey:key]];
    }

    if ([key isEqualToString:@"sloganTextColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo sloganLabel] setTextColor:[UIColor colorWithHexString:[config objectForKey:key]]];
    }

    if ([key isEqualToString:@"sloganBgColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[userInfo sloganLabel] setBackgroundColor:[UIColor colorWithHexString:[config objectForKey:key]]];
    }

    if ([key isEqualToString:@"sloganTextAlignment"]
        && [[config objectForKey:key] respondsToSelector:@selector(intValue)]) {
        [[userInfo sloganLabel] setTextAlignment:[[config objectForKey:key] intValue]];
    }

    if ([key isEqualToString:@"sloganBorderWidth"]
        && [[config objectForKey:key] respondsToSelector:@selector(floatValue)]) {
        [[[userInfo sloganLabel] layer] setBorderWidth:[[config objectForKey:key] floatValue]];
    }

    if ([key isEqualToString:@"sloganCorner"]
        && [[config objectForKey:key] respondsToSelector:@selector(floatValue)]) {
        [[[userInfo sloganLabel] layer] setCornerRadius:[[config objectForKey:key] floatValue]];
        [[[userInfo sloganLabel] layer] setMasksToBounds:YES];
    }

    if ([key isEqualToString:@"sloganBorderColor"]
        && [[config objectForKey:key] isKindOfClass:[NSString class]]
        && [[config objectForKey:key] length]) {
        [[[userInfo sloganLabel] layer] setBorderColor:[UIColor colorWithHexString:[config objectForKey:key]].CGColor];
    }
}

#pragma mark - Tools

// 获取当前显示的 UIViewController
- (UIViewController *)dc_findCurrentShowingViewController {
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}


- (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc {
    // 递归方法 Recursive method
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) {
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }

    return currentShowingVC;
}

- (void)_removeConstraintsWith:(UIView *)view {
    if (![[view constraints] count]) {
        return;
    }

    NSArray *constraints = [view constraints];
    for (NSLayoutConstraint *constraint in constraints) {
        [view removeConstraint:constraint];
    }
}

- (BOOL)_isFontValueJudeName:(NSString *)fontName{
    BOOL  isConst = NO;
    if (!fontName
        || ![fontName isKindOfClass:[NSString class]]
        || ![fontName length]) {
        return isConst;
    }

    NSArray* familys = [UIFont familyNames];
    for (NSString *fontFamily in familys) {
        NSArray* fonts = [UIFont fontNamesForFamilyName:fontFamily];
        if ([fonts containsObject:fontName]) {
            isConst = YES;
            break;
        }
    }

    return isConst;
}

@end
