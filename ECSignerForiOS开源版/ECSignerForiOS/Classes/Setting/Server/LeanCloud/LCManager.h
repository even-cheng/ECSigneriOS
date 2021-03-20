//
//  LCManager.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCAccount.h"
#import "LCSignModel.h"
#import <AVOSCloud/AVOSCloud.h>

NS_ASSUME_NONNULL_BEGIN
@interface LCManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) LCAccount * _Nullable current_account;

@property (nonatomic, strong, readonly) NSArray<LCAccount *> * _Nullable accounts;

- (BOOL)switchToAccount:(NSString *)appID;

- (void)cacheAccountWithName:(NSString *)name andAppID:(NSString *)appID andAppKey:(NSString *)appKey andServerUrl:(NSString *)serverUrl;

- (void)removeAccount:(NSString *)appID;

- (void)uploadFileToServer:(NSString *)filePath complete:(void(^)(BOOL success, NSString* url))complete;
- (void)deleteAllPlistFile;

@end

NS_ASSUME_NONNULL_END
