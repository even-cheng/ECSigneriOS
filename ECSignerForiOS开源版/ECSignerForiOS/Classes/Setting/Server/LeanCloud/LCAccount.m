//
//  LCAccount.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "LCAccount.h"

@interface LCAccount ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *appID;
@property (nonatomic, copy, readwrite) NSString *appKey;
@property (nonatomic, copy, readwrite) NSString *serverUrl;

@end

@implementation LCAccount

- (instancetype)initWithName:(NSString *)name appID:(NSString *)appID appKey:(NSString *)appKey serverUrl:(NSString *)serverUrl;{
    if (self = [super init]) {
        
        self.name = name;
        self.appID = appID;
        self.appKey = appKey;
        self.serverUrl = serverUrl;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.appID forKey:@"appID"];
    [aCoder encodeObject:self.appKey forKey:@"appKey"];
    [aCoder encodeObject:self.serverUrl forKey:@"serverUrl"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.appID = [aDecoder decodeObjectForKey:@"appID"];
    self.appKey = [aDecoder decodeObjectForKey:@"appKey"];
    self.serverUrl = [aDecoder decodeObjectForKey:@"serverUrl"];
    
    return self;
}

@end
