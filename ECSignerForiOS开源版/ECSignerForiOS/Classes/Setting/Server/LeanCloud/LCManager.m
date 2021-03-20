//
//  LCManager.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "LCManager.h"
#import <YYCache/YYCache.h>
#import "NSDate+HandleDate.h"
//#import "ECSignerForiOS-Swift.h"
#import "ECFileManager.h"

static NSString *const ECLeanCloudAccountCacheKey = @"ECLeanCloudAccountCacheKey";
static NSString *const ECLeanCloudAppIDKey = @"ECLeanCloudAppIDKey";
static NSString *const ECLeanCloudID = @"ec3eaf6d3f5";

@implementation LCManager

static YYCache *_dataCache;

+ (instancetype)sharedManager;{
    
    static LCManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [LCManager new];
        _dataCache = [YYCache cacheWithName:@"ECSignerLeanCloudCache"];
    });
    
    return manager;
}

- (NSArray<LCAccount *> *)accounts {

    NSArray<LCAccount *>* cachedAccounts = (NSArray *)[_dataCache objectForKey:ECLeanCloudAccountCacheKey];
    return cachedAccounts;
}

- (NSString *)account_id {
    
    NSString* ID = ECLeanCloudID;
    NSString * temp10 = [NSString stringWithFormat:@"%lu",strtoul([ID UTF8String],0,16)];
    ID = [temp10 substringToIndex:2];
    
    return ID;
}

- (LCAccount *)current_account {

    NSArray* accounts = self.accounts;
    NSString* appID = ( NSString*)[_dataCache objectForKey:ECLeanCloudAppIDKey];
    for (LCAccount* acc in accounts) {
        if ([acc.appID isEqualToString:appID]) {
            return acc;
        }
    }
    
    return nil;
}

- (BOOL)switchToAccount:(NSString *)appID;{
    
    NSArray* accounts = self.accounts;
    for (LCAccount* acc in accounts) {
        if ([acc.appID isEqualToString:appID]) {
            [_dataCache setObject:appID forKey:ECLeanCloudAppIDKey];
            return YES;
        }
    }
    
    return NO;
}


- (void)cacheAccountWithName:(NSString *)name andAppID:(NSString *)appID andAppKey:(NSString *)appKey andServerUrl:(NSString *)serverUrl{

    NSArray<LCAccount *>* cachedAccounts = (NSArray *)[_dataCache objectForKey:ECLeanCloudAccountCacheKey];
    NSMutableArray* savedAccounts = [NSMutableArray arrayWithArray:cachedAccounts];
    
    int index = 0;
    BOOL removed = NO;
    for (LCAccount* account in cachedAccounts) {
        if ([account.appID isEqualToString:appID]) {
            [savedAccounts removeObject:account];
            removed = YES;
            break;
        }
        index ++;
    }
    
    LCAccount* account = [[LCAccount alloc]initWithName:name appID:appID appKey:appKey serverUrl:serverUrl];
    if (removed) {
        [savedAccounts insertObject:account atIndex:index];
    } else {
        [savedAccounts addObject:account];
    }
    
    [_dataCache setObject:appID forKey:ECLeanCloudAppIDKey];
    [_dataCache setObject:savedAccounts.copy forKey:ECLeanCloudAccountCacheKey];
}

- (void)removeAccount:(NSString *)appID;{

    NSArray<LCAccount *>* cachedAccounts = (NSArray *)[_dataCache objectForKey:ECLeanCloudAccountCacheKey];
    NSMutableArray* savedAccounts = [NSMutableArray arrayWithArray:cachedAccounts];
    
    for (LCAccount* account in savedAccounts) {
        if ([account.appID isEqualToString:appID]) {
            
            [savedAccounts removeObject:account];
            break;
        }
    }
    
    [_dataCache setObject:savedAccounts.copy forKey:ECLeanCloudAccountCacheKey];
}

- (BOOL)changeSignStateToServer:(LCSignModel *)changedSignModel; {
 
    if (![LCManager sharedManager].current_account.appID || [LCManager sharedManager].current_account.appID.length == 0) {
        return NO;
    }
    
    LCSignModel *account = [LCSignModel objectWithObjectId:changedSignModel.objectId];
    account.enable = changedSignModel.enable;
    account.lock_end_time = changedSignModel.lock_end_time;
    BOOL res = [account save];
    return res;
}

- (void)uploadFileToServer:(NSString *)filePath complete:(void(^)(BOOL success, NSString* url))complete;{

    NSError *error;
    AVFile *file = [AVFile fileWithLocalPath:filePath error:&error];
    [file uploadWithCompletionHandler:^(BOOL succeeded, NSError *error) {
        
        complete?complete(succeeded, file.url):nil;
    }];
}


- (void)deleteAllPlistFile{
    if (![LCManager sharedManager].current_account.appID || [LCManager sharedManager].current_account.appID.length == 0) {
        return;
    }
    
    AVFileQuery *query = [AVFile query];
    [query deleteAllInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
    }];
}


@end
