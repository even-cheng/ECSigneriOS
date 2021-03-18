//
//  NSFileManager+CustomAttribute.h
//  YouXiSDK
//
//  Created by 快游 on 2020/11/9.
//  Copyright © 2020 zhengcong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (CustomAttribute)

- (BOOL)setExtendedAttribute:(NSString*)attribute forKey:(NSString*)key withPath:(NSString*)path;
- (id)getExtendedAttributeForKey:(NSString*)key  withPath:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
