//
//  NSFileManager+CustomAttribute.m
//  YouXiSDK
//
//  Created by 快游 on 2020/11/9.
//  Copyright © 2020 zhengcong. All rights reserved.
//

#import "NSFileManager+CustomAttribute.h"
#include <sys/xattr.h>

@implementation NSFileManager (CustomAttribute)

- (BOOL)setExtendedAttribute:(NSString*)attribute forKey:(NSString*)key withPath:(NSString*)path{
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:attribute format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSError *error;
    BOOL sucess = [[NSFileManager defaultManager] setAttributes:@{@"NSFileExtendedAttributes":@{key:data}}
                                                   ofItemAtPath:path error:&error];
    return sucess;
}
- (id)getExtendedAttributeForKey:(NSString*)key  withPath:(NSString*)path{
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (!attributes) {
        return nil;
    }
    NSDictionary *extendedAttributes = [attributes objectForKey:@"NSFileExtendedAttributes"];
    if (!extendedAttributes) {
        return nil;
    }
    NSData *data = [extendedAttributes objectForKey:key];
    if (!data) {
        return nil;
    }
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:0 error:nil];
    
    return [plist description];
}

- (BOOL)extended1WithPath:(NSString *)path key:(NSString *)key value:(NSData *)value
{
    ssize_t writelen = setxattr([path fileSystemRepresentation],
                                [key UTF8String],
                                [value bytes],
                                [value length],
                                0,
                                0);
    return writelen==0?YES:NO;
}

//读取文件扩展属性
- (NSData *)extended1WithPath:(NSString *)path key:(NSString *)key
{
    ssize_t readlen = 1024;
    do {
        char buffer[readlen];
        bzero(buffer, sizeof(buffer));
        size_t leng = sizeof(buffer);
        readlen = getxattr([path fileSystemRepresentation],
                           [key UTF8String],
                           buffer,
                           leng,
                           0,
                           0);
        if (readlen < 0){
            return nil;
        }
        else if (readlen > sizeof(buffer)) {
            continue;
        }else{
            NSData *result = [NSData dataWithBytes:buffer length:readlen];
            return result;
        }
    } while (YES);
    return nil;
}

@end
