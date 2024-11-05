//
//  UIImage+Yjyz.m
//  FlyVerifyPlus
//
//  Created by Sands_Lee on 2020/2/28.
//  Copyright © 2020 李树志. All rights reserved.
//

#import "UIImage+Yjyz.h"


@implementation UIImage (Yjyz)

+ (UIImage *)lookupImageKeyForAsset:(NSString*)asset flutterRegister:(NSObject<FlutterPluginRegistrar>*)registrar fromPackage:(NSString*)package fromXcodeProject:(BOOL)fromXcodeProject
{
    if (!asset || asset.length <1) {
        return nil;
    }
    
    if (registrar != nil && fromXcodeProject == NO){
        NSString * assetString = [registrar lookupKeyForAsset:asset];
        if (package != nil) {
            assetString = [registrar lookupKeyForAsset:asset fromPackage:package];
        }
        if (assetString) {
            NSString * assetpath = [[NSBundle mainBundle] pathForResource:assetString ofType:nil];
            if (assetpath) {
                UIImage * assetImage = [UIImage imageWithContentsOfFile:assetpath];
                if (assetImage) {
                    return  assetImage;
                }
            }

        }
    }else{
        UIImage * assetImage = [UIImage imageNamed:@"asset"];
        if (assetImage) {
            return  assetImage;
        }
    }
    return nil;
}

+ (UIImage *)imageWithFileNameInWidgetRes:(NSString *)fileName
{
    if (!fileName || fileName.length <1) {
        return nil;
    }
    
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:nil inDirectory:@"widget/res"]];
    
}


+ (UIImage *)createImageWithColor:(UIColor *)color withSize:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@end
