//
//  LCAccount.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCAccount : NSObject<NSCoding>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, copy, readonly) NSString *appKey;
@property (nonatomic, copy, readonly) NSString *serverUrl;

- (instancetype)initWithName:(NSString *)name appID:(NSString *)appID appKey:(NSString *)appKey serverUrl:(NSString *)serverUrl;

@end

NS_ASSUME_NONNULL_END
