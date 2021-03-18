//
//  MyObject.h
//  TestC++2
//
//  Created by Jacky on 2019/6/26.
//  Copyright © 2019 Jacky. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "x509.h"

NS_ASSUME_NONNULL_BEGIN
@class ECApplicationFile;
@interface MyObject : NSObject

- (char *) getAppCachePath:(char* )filePath;
- (char *) getAppExecutablePath:(char *)appPath withExecutableName:(char *_Nullable)executableName;
- (char *) getFrameworkExecutablePath:(char* )filePath;
- (bool) unzip:(char *)zipPath toPath:(char *)outPath;
- (bool) zip:(char *)filePath toPath:(char *)zipPath level:(int)level;
- (bool) moveFileFrom:(char *)fromPath to:(char *)toPath withCer:(char *)cer_name;
- (bool) writeLib:(char *)libPath toBundle:(char *)bundlPath;
- (int) optool_do:(int)count parmas:(char* [])params;
- (void)signDoneToCheck;

- (NSString *)createInstallPlistForApp:(ECApplicationFile *)app;

- (NSArray <NSString*> *)checkLibsFromExecutable:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
