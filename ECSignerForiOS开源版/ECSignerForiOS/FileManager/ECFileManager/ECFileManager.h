//
//  ECFileManager.h
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECFile.h"
#include "x509.h"

NS_ASSUME_NONNULL_BEGIN

@interface ECFileManager : NSObject

@property (nonatomic, copy, readonly) NSString *cachePath;
@property (nonatomic, copy, readonly) NSString *downloadPath;
@property (nonatomic, copy, readonly) NSString *originIpaPath;
@property (nonatomic, copy, readonly) NSString *signedIpaPath;
@property (nonatomic, copy, readonly) NSString *certificatePath;
@property (nonatomic, copy, readonly) NSString *mobileProvisionPath;
@property (nonatomic, copy, readonly) NSString *dylibPath;
@property (nonatomic, copy, readonly) NSString *zipPath;
@property (nonatomic, copy, readonly) NSString *unzipPath;
@property (nonatomic, copy, readonly) NSString *tmpPath;
@property (nonatomic, copy, readonly) NSString *installPath;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (ECFileType)fileTypeForName:(NSString *)fileName;
- (NSString* _Nullable)localPathForFile:(NSString *)file_path resigned:(BOOL)resigned;
- (BOOL)saveFile:(NSString*)filePath toPath:(NSString *)savePath extendedAttributes:(NSDictionary *_Nullable)attributes;
- (BOOL)saveData:(NSData*)fileData toPath:(NSString *)savePath;
- (NSArray*)allFiles:(NSString *)path;
- (NSArray*)subFiles:(NSString *)path;
- (BOOL)removeAll:(NSString *)path;
- (BOOL)removeFileWithPath:(NSString*)filePath;
- (NSString *_Nullable)getExecutablePathFromFramework:(NSString *)frameworkPath;
- (ECCertificateFile * _Nullable)getCertificateFileForPath:(NSString *)cer_path forceToUpdate:(BOOL)forceToUpdate checkComplete:(void(^_Nullable)(ECCertificateFile*))checkComplete;
- (ECMobileProvisionFile * _Nullable)getMobileProvisionFileForPath:(NSString *)prov_path;
- (ECApplicationFile * _Nullable)getApplicationFileForPath:(NSString *)ipa_path;
- (ECFile * _Nullable)getFileForPath:(NSString *)file_path;
- (NSDictionary *_Nullable)getInfoAndProfilesInBundle:(ECApplicationFile *)app;
- (NSDictionary *_Nullable)getPlistInfo:(ECApplicationFile *)app;
- (NSString *)getExecutablePathFromApp:(NSString *)filePath withExecutableName:(NSString *_Nullable)executableName;
- (void)importFile:(id _Nonnull)object withComplete:(void(^_Nullable)(NSArray<NSString*>* _Nullable savedPath, NSString* _Nullable des))complete;

@end

NS_ASSUME_NONNULL_END
