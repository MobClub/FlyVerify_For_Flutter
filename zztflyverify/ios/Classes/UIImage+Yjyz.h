//
//  UIImage+Yjyz.h
//  FlyVerifyPlus
//
//  Created by Sands_Lee on 2020/2/28.
//  Copyright © 2020 李树志. All rights reserved.
//
#import <Flutter/Flutter.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Yjyz)

//从flutter读取Image
+ (UIImage *)lookupImageKeyForAsset:(NSString*)asset flutterRegister:(NSObject<FlutterPluginRegistrar>*)registrar fromPackage:(NSString*)package fromXcodeProject:(BOOL)fromXcodeProject;

/// 读取 widget/res 文件夹中的图片文件
/// @param fileName 图片名称
+ (UIImage *)imageWithFileNameInWidgetRes:(NSString *)fileName;

/// 由颜色创建图片
/// @param color 颜色
/// @param size 图片大小
+ (UIImage *)createImageWithColor:(UIColor *)color withSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
