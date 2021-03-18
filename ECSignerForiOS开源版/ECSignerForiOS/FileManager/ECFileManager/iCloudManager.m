//
//  iCloudManager.m
//  FileAccess_iCloud_QQ_Wechat
//
//  Created by Hao on 2017/7/28.
//  Copyright © 2017年 zzh. All rights reserved.
//

#import "iCloudManager.h"
#import "ZHDocument.h"

@implementation iCloudManager

+ (BOOL)iCloudEnable {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSURL *url = [manager URLForUbiquityContainerIdentifier:nil];

    if (url != nil) {
        
        return YES;
    }
    
    NSLog(@"iCloud 不可用");
    return NO;
}

+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block {
    
    ZHDocument *iCloudDoc = [[ZHDocument alloc]initWithFileURL:url];
    
    [iCloudDoc openWithCompletionHandler:^(BOOL success) {
        if (success) {
            
            if (block) {
                
                if ([iCloudDoc.data isKindOfClass:[NSData class]]) {
                    block(iCloudDoc.data);
                } else {
                    block(iCloudDoc.fileURL);
                }
            }
            
            
            [iCloudDoc closeWithCompletionHandler:^(BOOL success) {
                NSLog(@"关闭成功");
            }];
        }
    }];
}

@end
