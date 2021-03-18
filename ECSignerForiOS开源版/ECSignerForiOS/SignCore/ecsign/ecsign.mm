//
//  ecsign.m
//  ECSignerForiOS
//
//  Created by even on 2020/8/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ecsign.h"
#include "zsign.h"
#import "NSDate+HandleDate.h"
#import "ECConst.h"
#import "LCManager.h"
#import "ECFileManager.h"

@implementation ecsign


+ (int)signIPA:(NSString *)ipa_path
           size:(NSString*)size
            cer:(NSString *)cer_path
            pwd:(NSString *_Nullable)pwd
           prov:(NSString *)prov_path
       bundleID:(NSString *_Nullable)bundleID
     bundleName:(NSString *_Nullable)bundleName
  bundleVersion:(NSString *_Nullable)bundleVersion
       zipLevel:(NSInteger)zipLevel
         output:(NSString *)output_path;{

    char *p12 = (char *)[cer_path UTF8String];
    char *password = (char *)[pwd?:@"" UTF8String];
    char *prov = (char *)[prov_path UTF8String];
    char *ipa = (char *)[ipa_path UTF8String];
    char *bID = (char *)[bundleID?:@"" UTF8String];
    char *bName = (char *)[bundleName?:@"" UTF8String];
    char *bVersion = (char *)[bundleVersion?:@"" UTF8String];
    char *zlevel = (char *)[@(zipLevel).stringValue UTF8String];
    char *output = (char *)[output_path UTF8String];

    char *argv[] = {"-k", p12, "-p", password, "-m", prov, "-v", bVersion, "-b", bID, "-n", bName, "-z", zlevel, "-i", ipa, "-o", output};
    int res = zsign(18, argv);

    return res;
}


@end
