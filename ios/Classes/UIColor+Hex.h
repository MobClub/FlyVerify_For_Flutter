//
//  UIColor+Hex.h
//  FlyVerifyPlus
//
//  Created by 李树志 on 2020/2/27.
//  Copyright © 2020 李树志. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hex)

// 透明度固定为1，以0x开头的十六进制转换成的颜色
+ (UIColor *)colorWithHex:(long)hexColor;

// 0x开头的十六进制转换成的颜色,透明度可调整
+ (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity;

/// iOS中十六进制的颜色转换为UIColor
/// @param colorString 十六进制的颜色字符串（支持以#或0x开头）
+ (UIColor *)colorWithHexString:(NSString *)colorString;

@end

NS_ASSUME_NONNULL_END
