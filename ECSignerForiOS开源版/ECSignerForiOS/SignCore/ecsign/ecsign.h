//
//  ecsign.h
//  ECSignerForiOS
//
//  Created by even on 2020/8/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ecsign : NSObject

+ (int)signIPA:(NSString *)ipa_path
           size:(NSString*)size
            cer:(NSString *)cer_path
            pwd:(NSString *_Nullable)pwd
           prov:(NSString *)prov_path
       bundleID:(NSString *_Nullable)bundleID
     bundleName:(NSString *_Nullable)bundleName
  bundleVersion:(NSString *_Nullable)bundleVersion
       zipLevel:(NSInteger)zipLevel
         output:(NSString *)output_path;

@end

NS_ASSUME_NONNULL_END
