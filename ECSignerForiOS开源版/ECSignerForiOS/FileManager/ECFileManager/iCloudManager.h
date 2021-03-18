//
//  iCloudManager.h
//  FileAccess_iCloud_QQ_Wechat
//
//  Created by Hao on 2017/7/28.
//  Copyright © 2017年 zzh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^downloadBlock)(id obj);

@interface iCloudManager : NSObject

+ (BOOL)iCloudEnable;

+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block;

@end
