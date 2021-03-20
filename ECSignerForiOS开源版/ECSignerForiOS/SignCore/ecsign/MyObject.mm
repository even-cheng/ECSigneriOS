//
//  MyObject.m
//  TestC++2
//
//  Created by Jacky on 2019/6/26.
//  Copyright © 2019 Jacky. All rights reserved.
//

#import "MyObject.h"
#include "MyObject-C-Interface.h"
#import "SSZipArchive.h"
#import "ECFileManager.h"
#import "NSDate+HandleDate.h"
#import "LCManager.h"
#import "AppDelegate.h"
#import "DDData.h"
#include <string.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#include <mach/mach_init.h>
#include <mach-o/dyld_images.h>

#import <AVOSCloud/AVOSCloud.h>
#import "NSFileManager+CustomAttribute.h"

typedef void(^RetainSelfBlock)(void);

@implementation MyObject
{
    RetainSelfBlock _retainBlock;//通过这个block持有对象，造成循环引用，避免被释放
}

MyClassImpl::MyClassImpl( void )
: self( NULL )
{
    
}


bool MyClassImpl::moveFile(char *fromPath, char *toPath, char *cer_name)
{
    return [(__bridge id)self moveFileFrom:fromPath to:toPath withCer:cer_name];
}

MyClassImpl::~MyClassImpl( void )
{
    [(__bridge id) self breakRetainCycly];
}

void MyClassImpl::init( void )
{
    MyObject *object = [[MyObject alloc] init];
    object->_retainBlock = ^{//循环引用
        [object class];
    };
    
    self = (__bridge void *)object;
    
//    NSLog(@"%p", self);
}

char* MyClassImpl::getAppCachePath(char* filePath)
{
    char *cache = [(__bridge id)self getAppCachePath:filePath];
    return cache;
}

char* MyClassImpl::getAppExecutablePath(char* appPath, char* executableName)
{
    char *cache = [(__bridge id)self getAppExecutablePath:appPath withExecutableName:executableName];
    return cache;
}

char* MyClassImpl::getFrameworkExecutablePath(char* filePath)
{
    char *cache = [(__bridge id)self getFrameworkExecutablePath:filePath];
    return cache;
}

bool MyClassImpl::unzip(char *zipPath, char *outPath)
{
    return [(__bridge id)self unzip:zipPath toPath:outPath];
}

void MyClassImpl::zip(char *filePath, char* zipPath, int level)
{
    [(__bridge id)self zip:filePath toPath:zipPath level:level];
}

- (bool) writeLib:(char *)libPath toBundle:(char *)bundlPath;{
    
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:bundlPath]];
    if (exist) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:bundlPath] error:nil];
    }
    
    BOOL existLib = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:libPath]];
    if (!existLib) {
        return false;
    }
    
    BOOL writeRes = [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithUTF8String:libPath] toPath:[NSString stringWithUTF8String:bundlPath] error:nil];
    
    return writeRes;
}

- (void)signDoneToCheck{
    
    NSArray* files = [[ECFileManager sharedManager] subFiles: [ECFileManager sharedManager].originIpaPath];
    NSArray* signfiles = [[ECFileManager sharedManager] subFiles: [ECFileManager sharedManager].signedIpaPath];
    for (NSString* file in files) {
        
        NSString* savedPath = file;
        if ([file hasSuffix:@"Payload"]) {
            
            NSArray* files = [[ECFileManager sharedManager] subFiles: file];
            for (NSString* sub in files) {
                
                if ([sub hasSuffix:@".app"]) {
                    NSString* appPath = sub;
                    savedPath = [[ECFileManager sharedManager].originIpaPath stringByAppendingPathComponent:appPath.lastPathComponent];
                    [[NSFileManager defaultManager] moveItemAtPath:appPath toPath:savedPath error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                    break;
                }
            }
        }
    }
    
    for (NSString* file in signfiles) {
        
        NSString* savedPath = file;
        if ([file hasSuffix:@"Payload"]) {
            
            NSArray* files = [[ECFileManager sharedManager] subFiles: file];
            for (NSString* sub in files) {
                
                if ([sub hasSuffix:@".app"]) {
                    NSString* appPath = sub;
                    savedPath = [[ECFileManager sharedManager].signedIpaPath stringByAppendingPathComponent:appPath.lastPathComponent];
                    [[NSFileManager defaultManager] moveItemAtPath:appPath toPath:savedPath error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                    break;
                }
            }
        }
    }
}

- (char *)getAppCachePath:(char* )filePath
{
    NSString* payloadPath = [[ECFileManager sharedManager].originIpaPath stringByAppendingPathComponent:@"Payload"];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:payloadPath];
    if (exist) {
        [[NSFileManager defaultManager] removeItemAtPath:payloadPath error:nil];
    }
    BOOL res = [[NSFileManager defaultManager] createDirectoryAtPath:payloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    res = [[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithUTF8String:filePath] toPath:[payloadPath stringByAppendingPathComponent:[NSString stringWithUTF8String:filePath].lastPathComponent] error:nil];
    if (!res) {
        NSLog(@"获取签名路径失败");
    }
    
    return (char *)[payloadPath UTF8String];
}

- (char *)getInjectLinkPath
{
    BOOL linkdRPath= [[NSUserDefaults standardUserDefaults] boolForKey:@"ecsigner_linkdRPath"];
    NSString* linkPath = @"@executable_path/Frameworks";
    if (linkdRPath) {
        linkPath = @"@rpath";
    }
    return (char *)[linkPath UTF8String];
}

- (bool)unzip:(char *)zipPath toPath:(nonnull char *)outPath
{
    BOOL success = [SSZipArchive unzipFileAtPath:[NSString stringWithUTF8String:zipPath] toDestination:[NSString stringWithUTF8String:outPath] progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ecsign_unzip_progress_notification" object:nil userInfo:@{@"file_name":[NSString stringWithUTF8String:zipPath].lastPathComponent, @"progress":@(entryNumber*1.0/total)}];

    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"unzip error :%@", error);
        }
    }];
   
    return success;
}

- (bool)zip:(char *)filePath toPath:(nonnull char *)zipPath level:(int)level
{
    return [self doZipAtPath:[NSString stringWithUTF8String:filePath] to:[NSString stringWithUTF8String:zipPath] level:level];
}


-(bool)doZipAtPath:(NSString*)sourceFile to:(NSString*)zipFile level:(int)level
{
    BOOL success = [SSZipArchive createZipFileAtPath:zipFile
                             withContentsOfDirectory:sourceFile keepParentDirectory:YES compressionLevel:level password:nil AES:NO progressHandler:^(NSUInteger entryNumber, NSUInteger total) {
//        NSLog(@"%.1fM  -->> %.f%%", total*0.1, 100*entryNumber*1.0/total);
    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ecsign_zip_progress_notification" object:nil userInfo:@{@"file_name":zipFile.lastPathComponent, @"progress":@(entryNumber*1.0/total)}];
    }];
    
    return success;
}

- (bool)moveFileFrom:(char *)fromPath to:(char *)toPath withCer:(char *)cer_name{
    
    NSString* fromFilePath = [NSString stringWithUTF8String:fromPath];
    NSString* toFilePath = [NSString stringWithUTF8String:toPath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:fromFilePath]) {
        return false;
    }
    
    BOOL res = YES;
    if (![fromFilePath isEqualToString:toFilePath]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:toFilePath]) {
            res = [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:toFilePath] withItemAtURL:[NSURL fileURLWithPath:fromFilePath] backupItemName:nil options:0 resultingItemURL:nil error:nil];
        } else {
            res = [[NSFileManager defaultManager] moveItemAtPath:fromFilePath toPath:toFilePath error:nil];
        }
    }
    
    if (res) {
        
        [[NSFileManager defaultManager] setExtendedAttribute:[NSString stringWithFormat:@"%ld", NSDate.getLongDate] forKey:@"resign_time" withPath:toFilePath];
        NSString* p12 = [[ECFileManager sharedManager].certificatePath stringByAppendingPathComponent:[NSString stringWithUTF8String:cer_name]];
        ECCertificateFile * cer = [[ECFileManager sharedManager] getCertificateFileForPath:p12 forceToUpdate:NO checkComplete:nil];
        [[NSFileManager defaultManager] setExtendedAttribute:cer.name?:@"" forKey:@"cer_name" withPath:toFilePath];
        
        NSString* infoPath = [toFilePath stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary* info = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
        NSString* bundle_name = [info objectForKey:@"CFBundleDisplayName"]?:[info objectForKey:@"CFBundleName"];
        [[NSFileManager defaultManager] setExtendedAttribute:bundle_name forKey:@"bundle_name" withPath:toFilePath];
    }
    
    return res;
}

- (char *) getAppExecutablePath:(char* )appPath withExecutableName:(char *_Nullable)executableName{

    if (executableName == NULL) {
        executableName = "";
    }
    NSString* name = [[ECFileManager sharedManager] getExecutablePathFromApp:[NSString stringWithUTF8String:appPath] withExecutableName:[NSString stringWithUTF8String:executableName]];
    return (char *)[name UTF8String];
}


- (char *) getFrameworkExecutablePath:(char* )filePath;{
    
    NSString* name = [[ECFileManager sharedManager] getExecutablePathFromFramework:[NSString stringWithUTF8String:filePath]];
    return (char *)[name UTF8String];
}

- (bool)removeLibInAppPath:(char *)path libname:(char *)libname{
    
    NSString* appPath = [NSString stringWithUTF8String:path];

    NSString* libPath = [[[NSString stringWithUTF8String:libname] stringByReplacingOccurrencesOfString:@"@rpath/" withString:@"Frameworks/"] stringByReplacingOccurrencesOfString:@"@executable_path/" withString:@""];

    if ([libPath.lastPathComponent componentsSeparatedByString:@"."].count > 1) {//.a .dylib .xxx
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:libPath]]) {
            [[NSFileManager defaultManager] removeItemAtPath:[appPath stringByAppendingPathComponent:libPath] error:nil];
        }

    }else {//.framework
        
        NSString *libSuperDirectory = [libPath stringByDeletingLastPathComponent];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:libSuperDirectory]]) {
            [[NSFileManager defaultManager] removeItemAtPath:[appPath stringByAppendingPathComponent:libSuperDirectory] error:nil];
        }
    }
    
    return YES;
}

- (NSString *)createInstallPlistForApp:(ECApplicationFile *)app{
    
    NSDictionary* bundle = [[ECFileManager sharedManager] getPlistInfo:app];
    
    NSString* bundleId = bundle[@"CFBundleIdentifier"];
    NSString* bundleName = [bundle objectForKey:@"CFBundleDisplayName"]?:[bundle objectForKey:@"CFBundleName"];
    NSString* app_version = bundle[@"CFBundleShortVersionString"];
    
    NSString* plistName = bundleId;
    NSString* plistPath = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", plistName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        return plistPath;
    }
    
    BOOL res = [[NSFileManager defaultManager] createFileAtPath:plistPath contents:nil attributes:nil];
    if (res) {
        NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         bundleId, @"bundle-identifier",
                                         app_version, @"bundle-version",
                                         @"software", @"kind",
                                         bundleName, @"title", nil];
        NSDictionary* item = @{@"kind":@"software-package", @"url":[NSString stringWithFormat:@"http://127.0.0.1:13140/%@.ipa", plistName]};
        NSArray* assets = @[item];
        NSMutableDictionary* dictoryItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         metadata, @"metadata",
                                         assets, @"assets", nil];
        NSArray* arrayItems = @[dictoryItem];
        NSDictionary* root = @{@"items" : arrayItems};
        res = [root writeToFile:plistPath atomically:YES];
    }
    if (res) {
        return plistPath;
    }
    
    return nil;
}

//打破循环引用，释放对象
- (void) breakRetainCycly
{
    _retainBlock = nil;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

@end





