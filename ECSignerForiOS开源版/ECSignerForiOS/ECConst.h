//
//  ECConst.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#ifndef ECConst_h
#define ECConst_h

#import "UIColor+HexColor.h"
#import "UIBarButtonItem+SXCreate.h"
#import "AppDelegate.h"
#import "UIView+Extension.h"
#import <sys/sysctl.h>

#define NSLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])


#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

#define HexColor(string) [UIColor colorWithHexString:string]
#define MAIN_COLOR HexColor(@"#00AF66") //主题色
#define BG_COLOR HexColor(@"#f5f5f5") //主题色

//通用样式、大小、颜色宏定义
#define kWindow [(AppDelegate*)[UIApplication sharedApplication].delegate window]
#define SCREEN_FRAME CGRectMake(0,0,SCREEN_WIDTH,SCREEN_HEIGHT)
#define SCREEN_SIZE CGSizeMake(SCREEN_WIDTH,SCREEN_HEIGHT)
#define SCREEN_HEIGHT [[UIScreen mainScreen]bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen]bounds].size.width
#define SCREEN_SCALE [UIScreen mainScreen].scale
#define iPhoneXSeries (SCREEN_HEIGHT == 812.0 || SCREEN_HEIGHT == 896.0)

#define isiPhone ^{\
    size_t size;\
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);\
    void *machine = malloc(size);\
    sysctlbyname("hw.machine", machine, &size, NULL, 0);\
    NSString *platform = [NSString stringWithCString:(const char*)machine encoding:NSUTF8StringEncoding];\
    free(machine);\
    BOOL isiPhone = [platform hasPrefix:@"iPhone"];\
    return isiPhone;\
}()

// 导航栏高度
#define NAV_HEIGHT (iPhoneXSeries ? 88 : 64)
//同上
#define SafeAreaTopHeight (iPhoneXSeries ? 88 : 64)
// 安全区域高度
#define SafeAreaBottomHeight (iPhoneXSeries ? 34 : 0)
// 状态栏高度
#define kStatusBarHeight (iPhoneXSeries ? 44.f : 20.f)
// tabBar高度
#define kTabBarHeight (iPhoneXSeries ? (49.f+34.f) : 49.f)

#define kQQKey @"qq177f024ef8e";

#endif /* ECConst_h */
