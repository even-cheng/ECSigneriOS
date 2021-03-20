//
//  ECFileManager.m
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECFileManager.h"
#import "NSDate+HandleDate.h"
#include "pkcs12.h"
#include "p12checker.h"
#include "dump-ios-mobileprovision.h"
#include "OCTET_STRING.h"
#import <Foundation/NSPropertyList.h>
#import "MyObject.h"
#include "pem.h"
#import "iCloudManager.h"
#import "NSFileManager+CustomAttribute.h"

static NSString*  kCacheDirectoryName = @"ECSigner";
static NSString*  kDownloadDirectoryName = @"Download";
static NSString*  kOriginIpaDirectoryName = @"OriginIpa";
static NSString*  kSignedIpaDirectoryName = @"SignedIpa";
static NSString*  kCertificateDirectoryName = @"Cer";
static NSString*  kMobileProvisionDirectoryName = @"Prov";
static NSString*  kDylibDirectoryName = @"Dylib";
static NSString*  kZipDirectoryName = @"Zip";
static NSString*  kUnzipDirectoryName = @"Unzip";

@interface ECFileManager ()
@property (nonatomic, strong) MyObject *_myobj;
@end

@implementation ECFileManager

+ (instancetype)sharedManager{
    
    static ECFileManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager->__myobj = [MyObject new];
    });
    return manager;
}

- (BOOL)removeAll:(NSString *)path{
    
    NSArray* allFiles = [self subFiles:path];
    for (NSString* filePath in allFiles) {
        BOOL result = [self removeFileWithPath:filePath];
        if (!result) {
            return NO;
        }
    }
    
    return YES;
}

- (NSArray*)subFiles:(NSString *)path;{
    
    NSMutableArray* files = [NSMutableArray array];
    
    NSArray* fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *fileName in fileNames) {
        NSString* fileAbsolutePath = [path stringByAppendingPathComponent:fileName];
        [files addObject:fileAbsolutePath];
    }

    return files.copy;
}


- (NSArray*)allFiles:(NSString *)path{
    
    NSMutableArray* files = [NSMutableArray array];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]){
        return @[];
    };
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:path] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        
        NSString* fileAbsolutePath = [path stringByAppendingPathComponent:fileName];
        [files addObject:fileAbsolutePath];
    }
    
    return files.copy;
}

- (BOOL)removeFileWithPath:(NSString *)filePath{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    NSError* error;
    if (![manager fileExistsAtPath:filePath]){
        return YES;
    };
    
    BOOL result = [manager removeItemAtPath:filePath error:&error];
    if (!result) {
        NSLog(@"%@",error);
    }
        
    ECFileType type = [self fileTypeForName:filePath];
    if (type == ECFileTypeApplication) {
        NSString* fileName = filePath.lastPathComponent;
        NSString* installPath = [[self.installPath stringByAppendingPathComponent:fileName] stringByReplacingOccurrencesOfString:@".app" withString:@".ipa"];
        NSString* plistPath = [[self.installPath stringByAppendingPathComponent:fileName] stringByReplacingOccurrencesOfString:@".app" withString:@".plist"];
        [manager removeItemAtPath:installPath error:nil];
        [manager removeItemAtPath:plistPath error:nil];
    }

    BOOL resign = [filePath.stringByDeletingLastPathComponent.lastPathComponent isEqualToString:self.signedIpaPath.lastPathComponent];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type), @"resignd":@(resign)}];

    return YES;
}

- (BOOL)saveFile:(NSString*)filePath toPath:(NSString *)savePath extendedAttributes:(NSDictionary *_Nullable)attributes{
    if (!savePath || !filePath) {
        return NO;
    }
    
    NSError* error;
    BOOL saved_exist = [[NSFileManager defaultManager] fileExistsAtPath:savePath];
    if (saved_exist) {
                
        [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:savePath] withItemAtURL:[NSURL fileURLWithPath:filePath] backupItemName:nil options:0 resultingItemURL:nil error:&error];
        if (error) {
            NSLog(@"saved failed: %@",error);
            return NO;
        }

        if (attributes) {
            for (NSString* key in attributes.allKeys) {
                [[NSFileManager defaultManager] setExtendedAttribute:attributes[key] forKey:key withPath:savePath];
            }
        }

        ECFileType type = [self fileTypeForName:savePath];
        [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
        return YES;
    }
    
    BOOL move_res = [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:savePath error:&error];
    if (move_res) {

        if (attributes) {
            for (NSString* key in attributes.allKeys) {
                [[NSFileManager defaultManager] setExtendedAttribute:attributes[key] forKey:key withPath:savePath];
            }
        }
        ECFileType type = [self fileTypeForName:savePath];
        [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
        return YES;
    }

    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath] options:NSDataReadingMappedIfSafe error:&error];
    if (!data) {
        data = [NSData dataWithContentsOfFile:filePath];
        NSLog(@"saved failed: %@",error);
        return NO;
    }
    
    BOOL res = [self saveData:data toPath:savePath];
    if (res && attributes) {
        for (NSString* key in attributes.allKeys) {
            [[NSFileManager defaultManager] setExtendedAttribute:attributes[key] forKey:key withPath:savePath];
        }
    }
    
    return res;
}

- (BOOL)saveData:(NSData*)data toPath:(NSString *)filePath;{
    if (!filePath) {
        return NO;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO){
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    FILE *file = fopen([filePath UTF8String], [@"ab+" UTF8String]);
    if(file != NULL){
        
        fseek(file, 0, SEEK_END);
        long readSize = [data length];
        fwrite((const void *)[data bytes], readSize, 1, file);
        fclose(file);
        
    } else {
        
        NSLog(@"open %@ error!", filePath);
        return NO;
    }
    
    ECFileType type = [self fileTypeForName:filePath];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];

    return YES;
}

- (NSDictionary *_Nullable)getPlistInfo:(ECApplicationFile *)app{
    
    NSString* appPath = [[ECFileManager sharedManager] localPathForFile:app.file_name resigned:app.resigned];
    NSString* infoPath = [appPath stringByAppendingPathComponent:@"Info.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        NSDictionary* dic = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
        return dic;
    };
    
    return nil;
}

- (NSDictionary *_Nullable)getInfoAndProfilesInBundle:(ECApplicationFile *)app{
    
    NSString* appPath = [[ECFileManager sharedManager] localPathForFile:app.file_name resigned:app.resigned];

    NSDictionary* info;
    NSString* infoPath = [appPath stringByAppendingPathComponent:@"Info.plist"];
    NSString* profilePath = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    if([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        info = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
    };

    return @{@"info":info?:@{}, @"profile":profilePath};
}


- (NSString *)getExecutablePathFromApp:(NSString *)filePath withExecutableName:(NSString *_Nullable)executableName;{

    NSString* appPath = filePath;

    if (!executableName || executableName.length == 0) {
        
        NSString* infoPath = [appPath stringByAppendingPathComponent:@"Info.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
            NSDictionary* dic = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
            executableName = [dic objectForKey:@"CFBundleExecutable"];
        }
    }

        
    return [appPath stringByAppendingPathComponent:executableName];
}

- (NSString * _Nullable)getExecutablePathFromFramework:(NSString *)frameworkPath{

    BOOL isDir;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:frameworkPath isDirectory:&isDir];
    if (!exist) {
        return nil;
    } else if (!isDir) {
        return frameworkPath;
    }
    
    NSString* exePath;
    NSString* infoPath = [frameworkPath stringByAppendingPathComponent:@"Info.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        NSDictionary* dic = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
        NSString* exeName = [dic objectForKey:@"CFBundleExecutable"];
        exePath = [frameworkPath stringByAppendingPathComponent:exeName];
    } else {
        exePath = [frameworkPath stringByAppendingPathComponent:[frameworkPath.lastPathComponent stringByReplacingOccurrencesOfString:@".framework" withString:@""]];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exePath]) {
        return exePath;
    } else {
        return frameworkPath;
    }
}


- (ECCertificateFile * _Nullable)getCertificateFileForPath:(NSString *)cer_path forceToUpdate:(BOOL)forceToUpdate checkComplete:(void(^)(ECCertificateFile*))checkComplete{
    
    if (!cer_path) {
        return nil;
    }
    
    NSError* error;
    NSDictionary* attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:cer_path error:&error];
    if (error) {
        return nil;
    }

    NSString* password = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"password-%@", cer_path.lastPathComponent]];

    id addtime = attribute[NSFileCreationDate];
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *formatdateString= [format stringFromDate:addtime];

    ECCertificateFile* cer = [ECCertificateFile new];
    cer.file_name = cer_path.lastPathComponent;
    cer.file_type = [self fileTypeForName:cer_path.lastPathComponent];
    cer.file_size = [attribute[NSFileSize] longValue];
    cer.add_time = [NSDate getDateLongWithDateStr:formatdateString];
    cer.expire_time = NSDate.date.timeIntervalSince1970 + 24*60*60*365;
    cer.password = password;
    [self readP12:cer_path cerObj:cer forceToUpdate:forceToUpdate checkComplete:checkComplete];
    
    return cer;
}

- (void)readP12:(NSString *)p12_path cerObj:(ECCertificateFile *)cerObj forceToUpdate:(BOOL)forceToUpdate checkComplete:(void(^)(ECCertificateFile*))checkComplete{
    
    PKCS12 *p12 = NULL;
    X509* usrCert = NULL;
    EVP_PKEY* pkey = NULL;
    STACK_OF(X509)* ca = NULL;
    char* password = (char*)[cerObj.password cStringUsingEncoding:NSUTF8StringEncoding];
    BIO*bio = BIO_new_file([p12_path UTF8String], "r");
    char* x509Data = NULL;

    if ([p12_path hasSuffix:@".p12"]) {
        
        p12 = d2i_PKCS12_bio(bio, NULL); //得到p12结构
        PKCS12_parse(p12, password, &pkey, &usrCert, &ca); //得到x509结构

    } else {
        
        NSString* path = [[ECFileManager sharedManager] localPathForFile:cerObj.file_name resigned:NO];
        if (path) {
            FILE *pub_fp = fopen(path.UTF8String, "r");
            d2i_X509_fp(pub_fp, &usrCert);
        }
    }
    
    BIO_free_all(bio);
    if (usrCert)
    {
        fprintf(stdout, "Subject:");
        x509Data = X509_NAME_oneline(X509_get_subject_name(usrCert), NULL, 0);
        NSDictionary* subject = [self readSubjectFormX509:x509Data];
        cerObj.country = subject[@"U"];
        cerObj.name = subject[@"CN"];
        cerObj.organization = subject[@"O"];
        cerObj.organization_unit = subject[@"OU"];
        cerObj.user_ID = subject[@"UID"];
        cerObj.country = subject[@"C"];

        ASN1_TIME* before = X509_get_notBefore(usrCert);
        long start_time = [self readRealTimeForX509:(char *)before->data];
        cerObj.start_time = start_time;

        ASN1_TIME* after = X509_get_notAfter(usrCert);
        long expire_time = [self readRealTimeForX509:(char *)after->data];
        cerObj.expire_time = expire_time;

        BOOL revoked = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"revoked-%@", cerObj.name]];
        long last_revoke_checked_time = [[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"last_check_revoke-%@", cerObj.name]] longValue];
        long launch_time = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ECSigner_Launch_time"] longValue];
        long current_time = NSDate.date.timeIntervalSince1970;
        cerObj.revoked = revoked;
        if (forceToUpdate || last_revoke_checked_time <= launch_time) {
                    
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                bool g3 = [self isG3ForX509:usrCert];
                bool revoked = isP12Revoked(usrCert, g3);
                cerObj.revoked = revoked;
                if (checkComplete != nil) {
                    checkComplete(cerObj);
                }
                
                [[NSUserDefaults standardUserDefaults] setBool:revoked forKey:[NSString stringWithFormat:@"revoked-%@", cerObj.name]];
                [[NSUserDefaults standardUserDefaults] setObject:@(current_time) forKey:[NSString stringWithFormat:@"last_check_revoke-%@", cerObj.name]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
    }
}

- (bool)isG3ForX509:(X509 *)x509;{

    X509* usrCert = x509;
    X509_NAME* name = X509_get_issuer_name(usrCert);
    char* x509Data = X509_NAME_oneline(name, NULL, 0);
    NSDictionary* subject = [self readSubjectFormX509:x509Data];
    NSString* ou = [subject objectForKey:@"OU"];
    BOOL G3 = ou && [ou isEqualToString:@"G3"];
    return G3;
}

///UID=U34K89P8TK/CN=Apple Development: danni li (LZ2JW32PMD)/OU=5U96AY492N/O=danni li/C=US
- (NSDictionary *)readSubjectFormX509:(char *)x509data{
    
    NSMutableDictionary* mdic = [NSMutableDictionary dictionary];
    NSString* x509String = [NSString stringWithUTF8String:x509data];
    NSArray* objs = [x509String componentsSeparatedByString:@"/"];
    for (NSString* obj in objs) {
        NSArray* content = [obj componentsSeparatedByString:@"="];
        if (content.count == 2) {
            NSDictionary* dic = @{content.firstObject:content.lastObject};
            [mdic addEntriesFromDictionary:dic];
        }
    }
    return mdic.copy;
}

- (long )readRealTimeForX509:(char *)x509data{
    
    NSString* x509TimeString = [NSString stringWithUTF8String:x509data];
    if (x509TimeString.length<12) {
        return 0;
    }
    NSString* start_time = [NSString stringWithFormat:@"20%@-%@-%@ %@:%@:%@",[x509TimeString substringWithRange:NSMakeRange(0, 2)], [x509TimeString substringWithRange:NSMakeRange(2, 2)], [x509TimeString substringWithRange:NSMakeRange(4, 2)], [x509TimeString substringWithRange:NSMakeRange(6, 2)], [x509TimeString substringWithRange:NSMakeRange(8, 2)], [x509TimeString substringWithRange:NSMakeRange(10, 2)]];
    long timeLong = [NSDate getDateLongWithDateStr:start_time];
    return timeLong+8*60*60;
}


- (ECMobileProvisionFile * _Nullable)getMobileProvisionFileForPath:(NSString *)prov_path;{
    
    NSError* error;
    NSDictionary* attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:prov_path error:&error];
    if (error) {
        return nil;
    }
    
    id addtime = attribute[NSFileCreationDate];
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *formatdateString= [format stringFromDate:addtime];
    
    ECMobileProvisionFile* prov = [ECMobileProvisionFile new];
    prov.file_name = prov_path.lastPathComponent;
    prov.file_type = [self fileTypeForName:prov_path.lastPathComponent];
    prov.file_size = [attribute[NSFileSize] longValue];
    prov.add_time = [NSDate getDateLongWithDateStr:formatdateString];
    
    BOOL res = [self readMobileProvision:prov_path andFile:prov];
    if (!res) {
    
        NSLog(@"描述文件格式错误：%@", prov_path);
        [[NSFileManager defaultManager] removeItemAtPath:prov_path error:nil];
        return nil;
    }
    
    return prov;
}


- (BOOL)readMobileProvision:(NSString *)prov_path andFile:(ECMobileProvisionFile *)prov{
    
    char* path = (char*)[prov_path UTF8String];
    OCTET_STRING_t* xml = dumpMobileProvision(path);
    if (xml == NULL) {
        return NO;
    }
    NSError* error;
    NSDictionary* obj = [NSPropertyListSerialization propertyListWithData:[NSData dataWithBytes:xml->buf length:xml->size] options:0 format:0 error:&error];
    
    NSString* AppIDName = [obj objectForKey:@"AppIDName"];
    NSString* TeamName = [obj objectForKey:@"TeamName"];
    NSArray* TeamIdentifier = [obj objectForKey:@"TeamIdentifier"];
    NSDate* ExpirationDate = [obj objectForKey:@"ExpirationDate"];
    NSDate* CreationDate = [obj objectForKey:@"CreationDate"];
    NSString* Name = [obj objectForKey:@"Name"];
    NSString* UUID = [obj objectForKey:@"UUID"];
    id ProvisionAllDevices = [obj objectForKey:@"ProvisionsAllDevices"];
    NSArray* ProvisionedDevices = [obj objectForKey:@"ProvisionedDevices"];
    NSDictionary* Entitlements = [obj objectForKey:@"Entitlements"];
    NSString* AppID = [Entitlements objectForKey:@"application-identifier"];
    NSString* BundleID = [AppID stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@.", [Entitlements objectForKey:@"com.apple.developer.team-identifier"]] withString:@""];
    NSArray* DeveloperCertificates = [obj objectForKey:@"DeveloperCertificates"];
    NSArray* CerNames = [self paserCertifiers:DeveloperCertificates];
    
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *startString= [format stringFromDate:CreationDate];
    NSString *endString= [format stringFromDate:ExpirationDate];
    
    prov.app_id = AppID;
    prov.bundle_id = BundleID;
    prov.name = Name;
    prov.app_id_name = AppIDName;
    prov.certificates = CerNames;
    prov.team = TeamName;
    prov.team_identifier = TeamIdentifier;
    prov.create_date = [NSDate getDateLongWithDateStr:startString];
    prov.expiration_date = [NSDate getDateLongWithDateStr:endString];
    prov.uuid = UUID;
    prov.provisions_all_devices = [ProvisionAllDevices boolValue];
    prov.device_udids = ProvisionedDevices;
    
    return YES;
}

- (NSArray *)paserCertifiers:(NSArray *)cers{
    
    NSMutableArray* cer_names = [NSMutableArray array];
    NSString* iphoneDeveloper = @"iPhone Developer";
    NSString* iphoneDistribution = @"iPhone Distribution";
    NSString* appleDeveloper = @"Apple Development";
    for (NSData* content in cers) {
     
        NSString* str = [[NSString alloc]initWithData:content encoding:1];
        NSRange startRange = [str rangeOfString:iphoneDeveloper];
        if (startRange.length == 0) {
            startRange = [str rangeOfString:iphoneDistribution];
        }
        if (startRange.length == 0) {
            startRange = [str rangeOfString:appleDeveloper];
        }
        if (startRange.length == 0) {
            continue;
        }

        NSString* sub_str = [str substringWithRange:NSMakeRange(startRange.location, startRange.length+50)];
        
        NSRange endRange = [sub_str rangeOfString:@")1"];
        
        if (endRange.length > 0) {
            
            NSString* name = [sub_str substringToIndex:endRange.location+1];
            if (name) {
                [cer_names addObject:name];
            }
            
        } else {
            [cer_names addObject:sub_str];
        }
    }
    
    return cer_names.copy;
}

//解码
- (NSString *)URLDecodedStringWithStr:(NSString*)str
{
    NSString *result = [str stringByRemovingPercentEncoding];
    return result;
}


- (ECApplicationFile * _Nullable)getApplicationFileForPath:(NSString *)ipa_path;{
    
    if (![ipa_path hasSuffix:@".app"]) {
        return nil;
    }
    ECApplicationFile* app = [ECApplicationFile new];
    app.file_name = ipa_path.lastPathComponent;
    app.file_type = [self fileTypeForName:ipa_path.lastPathComponent];
    NSString* size = [[NSFileManager defaultManager] getExtendedAttributeForKey:@"bundle_size" withPath:ipa_path];
    app.file_size = size.longLongValue;
    app.resigned = [[ipa_path stringByDeletingLastPathComponent] hasSuffix:kSignedIpaDirectoryName];
    app.resigned_cer_name = [[NSFileManager defaultManager] getExtendedAttributeForKey:@"cer_name" withPath:ipa_path];
    NSString* bundle_name = [[NSFileManager defaultManager] getExtendedAttributeForKey:@"bundle_name" withPath:ipa_path];
    if (!bundle_name || bundle_name.length == 0) {
        NSString* infoPath = [ipa_path stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary* info = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
        bundle_name = [info objectForKey:@"CFBundleDisplayName"]?:[info objectForKey:@"CFBundleName"];
    }
    app.bundle_name = bundle_name;
    NSString* resign_time = [[NSFileManager defaultManager] getExtendedAttributeForKey:@"resign_time" withPath:ipa_path];
    NSString* import_time = [[NSFileManager defaultManager] getExtendedAttributeForKey:@"import_time" withPath:ipa_path];
    app.resigned_time = resign_time.longLongValue;
    app.add_time = import_time.longLongValue;

    if (app.add_time == 0) {
        NSDictionary* attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:ipa_path error:nil];
        NSDate* create = attribute[NSFileCreationDate];
        app.add_time = create.timeIntervalSince1970;
    }
    
    return app;
}

- (ECFile * _Nullable)getFileForPath:(NSString *)file_path;{
    
    BOOL isDir;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:file_path isDirectory:&isDir];
    if (!exist) {
        return nil;
    }
    
    NSError* error;
    NSDictionary* attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:file_path error:&error];
    if (error) {
        return nil;;
    }
    
    id addtime = attribute[NSFileCreationDate];
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *formatdateString= [format stringFromDate:addtime];
    
    ECFile* file = [ECApplicationFile new];
    file.file_name = file_path.lastPathComponent;
    file.file_type = [self fileTypeForName:file_path.lastPathComponent];
    file.add_time = [NSDate getDateLongWithDateStr:formatdateString];

    if (isDir) {
        file.file_size = [self folderSizeAtPath:file_path];
    } else {
        file.file_size = [attribute[NSFileSize] longValue];
    }

    return file;
}

- (unsigned long long)folderSizeAtPath:(NSString *)folderPath{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString *fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}

//单个文件的大小(字节)
- (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (ECFileType)fileTypeForName:(NSString *)fileName{
    
    if ([fileName hasSuffix:@".p12"]) {
        return ECFileTypeCertificate;
    } else if ([fileName hasSuffix:@".mobileprovision"]) {
        return ECFileTypeMobileprovision;
    } else if ([fileName hasSuffix:@".ipa"] || [fileName hasSuffix:@".app"]) {
        return ECFileTypeApplication;
    } else if ([fileName hasSuffix:@".dylib"] || [fileName hasSuffix:@".framework"] || [fileName hasSuffix:@".a"]) {
        return ECFlieTypeDylib;
    } else if ([fileName hasSuffix:@".zip"] || [fileName hasSuffix:@".rar"]) {
        return ECFileTypeZip;
    } else if ([fileName hasSuffix:@".p8"]) {
        return ECFileTypeP8;
    }

    return ECFileTypeUnknown;
}

- (NSString* _Nullable)localPathForFile:(NSString *)file_path resigned:(BOOL)resigned{
    
    NSString* fileName = file_path.lastPathComponent;
    NSString* savedPath;
    
    if ([fileName hasSuffix:@".p12"]) {
        savedPath = [[ECFileManager sharedManager].certificatePath stringByAppendingPathComponent:fileName];
    } else if ([fileName hasSuffix:@".mobileprovision"] || [fileName hasSuffix:@".mobileProvision"]) {
        savedPath = [[ECFileManager sharedManager].mobileProvisionPath stringByAppendingPathComponent:fileName];
    } else if ([fileName hasSuffix:@".app"]) {
        if (resigned) {
            savedPath = [[ECFileManager sharedManager].signedIpaPath stringByAppendingPathComponent:fileName];
        } else {
            savedPath = [[ECFileManager sharedManager].originIpaPath stringByAppendingPathComponent:fileName];
        }
    } else if ([fileName hasSuffix:@".ecsigner"]) {
        savedPath = [[ECFileManager sharedManager].originIpaPath stringByAppendingPathComponent:[fileName stringByReplacingOccurrencesOfString:@".ecsigner" withString:@".app"]];
    } else if ([fileName hasSuffix:@".rename"] && [fileName containsString:@".ipa"]) {
        NSString* fullPath = [NSString stringWithFormat:@"%@.ipa",[fileName componentsSeparatedByString:@".ipa"].firstObject];
        savedPath = [[ECFileManager sharedManager].zipPath stringByAppendingPathComponent:fullPath];
    } else if ([fileName hasSuffix:@".dylib"] || [fileName hasSuffix:@".framework"] || [fileName hasSuffix:@".a"]) {
        savedPath = [[ECFileManager sharedManager].dylibPath stringByAppendingPathComponent:fileName];
    } else if ([fileName hasSuffix:@".ipa"] || [fileName hasSuffix:@".zip"] || [fileName hasSuffix:@".rar"]) {
        savedPath = [[ECFileManager sharedManager].zipPath stringByAppendingPathComponent:fileName];
    } else if ([fileName hasSuffix:@".cer"]) {
        savedPath = [[ECFileManager sharedManager].tmpPath stringByAppendingPathComponent:fileName];
    }
    
    return savedPath;
}

- (void)importFile:(id _Nonnull)object withComplete:(void(^_Nullable)(NSArray<NSString*>* _Nullable savedPath, NSString* _Nullable des))complete;{

//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
        NSString* savedPath;
        BOOL isZip = NO;
        if ([object isKindOfClass:NSURL.class]) {
            
            NSURL* url = (NSURL *)object;
            savedPath = [self localPathForFile:url.path resigned:NO];
            isZip = [[savedPath stringByDeletingLastPathComponent] hasSuffix:self.zipPath.lastPathComponent];
            [iCloudManager downloadWithDocumentURL:url callBack:^(id obj) {
                
                if ([obj isKindOfClass:[NSData class]]) {
                    
                    NSData *data = obj;
                    BOOL res = [[ECFileManager sharedManager] saveData:data toPath:savedPath];
                    if (res) {
                        
                        if (isZip) {
                            NSArray<NSString*> *savedPaths = [self checkAndUnzipFile:savedPath];
                            if (savedPaths) {
//                                dispatch_async(dispatch_get_main_queue(), ^{
                                    ECFileType type = [self fileTypeForName:savedPath];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                                    complete(savedPaths, nil);
//                                });
                            } else {
//                                dispatch_async(dispatch_get_main_queue(), ^{
                                    complete(nil, @"导入数据中未解压出可用文件");
//                                });
                            }
                            [[NSFileManager defaultManager] removeItemAtPath:savedPath error:nil];

                        } else {
//                            dispatch_async(dispatch_get_main_queue(), ^{
                                ECFileType type = [self fileTypeForName:savedPath];
                                [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                                complete(@[savedPath], nil);
//                            });
                        }
                        
                    } else {
//                        dispatch_async(dispatch_get_main_queue(), ^{
                            complete(nil, @"保存文件数据失败");
//                        });
                    }
                    
                } else if ([obj isKindOfClass:[NSURL class]]) {
                    
                    NSURL* file_url = (NSURL *)obj;
                    BOOL res = [self saveFile:file_url.path toPath:savedPath extendedAttributes:nil];
                    if (res) {
                        
                        if (isZip) {
                            NSArray<NSString*> *savedPaths = [self checkAndUnzipFile:savedPath];
                            if (savedPaths) {
//                                dispatch_async(dispatch_get_main_queue(), ^{
                                    ECFileType type = [self fileTypeForName:savedPath];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                                    complete(savedPaths, nil);
//                                });
                            } else {
//                                dispatch_async(dispatch_get_main_queue(), ^{
                                    complete(nil, @"导入路径中未解压出可用文件");
//                                });
                            }
                            [[NSFileManager defaultManager] removeItemAtPath:savedPath error:nil];

                        } else {
//                            dispatch_async(dispatch_get_main_queue(), ^{
                                ECFileType type = [self fileTypeForName:savedPath];
                                [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                                complete(@[savedPath], nil);
//                            });
                        }
                        
                    } else {
//                        dispatch_async(dispatch_get_main_queue(), ^{
                            complete(nil, @"保存文件路径失败");
//                        });
                    }
                }
                
            }];
            
        } else if ([object isKindOfClass:NSString.class]) {
            
            NSString* formPath = (NSString *)object;
            savedPath = [self localPathForFile:formPath resigned:NO];
            isZip = [[savedPath stringByDeletingLastPathComponent] hasSuffix:self.zipPath.lastPathComponent];

            BOOL res = [self saveFile:formPath toPath:savedPath extendedAttributes:nil];
            if (res) {

                if (isZip) {
                    NSArray<NSString*> *savedPaths = [self checkAndUnzipFile:savedPath];
                    if (savedPaths) {
//                        dispatch_async(dispatch_get_main_queue(), ^{
                            ECFileType type = [self fileTypeForName:savedPath];
                            [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                            complete(savedPaths, nil);
//                        });
                    } else {
//                        dispatch_async(dispatch_get_main_queue(), ^{
                            complete(nil, @"导入地址未解压出可用文件");
//                        });
                    }
                    [[NSFileManager defaultManager] removeItemAtPath:savedPath error:nil];
    
                } else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
                        ECFileType type = [self fileTypeForName:savedPath];
                        [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type)}];
                        complete(@[savedPath], nil);
//                    });
                }
            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(nil, @"保存文件地址失败");
//                });
            }
        
        } else {
//            dispatch_async(dispatch_get_main_queue(), ^{
                complete(nil, @"导入格式异常");
//            });
        }
    
//    });
}


- (NSArray<NSString *> * _Nullable)checkAndUnzipFile:(NSString *)filePath{
    
    NSString* unzipPath = [ECFileManager sharedManager].unzipPath;
    NSDictionary* attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    BOOL success = [[MyObject new] unzip:(char *)[filePath UTF8String] toPath:(char *)[unzipPath UTF8String]];
    NSMutableArray* savedFiles;
    
    if (success) {
    
        NSArray* files = [self checkUpzipFileToSave:unzipPath];
        savedFiles = [NSMutableArray array];
        for (NSString* filePath in files) {
            
            NSString* savedPath = [[ECFileManager sharedManager] localPathForFile:filePath resigned:NO];
            if (!savedPath) {
                continue;
            }
            BOOL isZip = [[savedPath stringByDeletingLastPathComponent] hasSuffix:self.zipPath.lastPathComponent];
            NSString* bundleName = @"";
            if ([filePath hasSuffix:@".app"]) {
                
                NSString* infoPath = [filePath stringByAppendingPathComponent:@"Info.plist"];
                NSDictionary* info = [[NSDictionary alloc]initWithContentsOfFile:infoPath];
                NSString* bundleID = [info objectForKey:@"CFBundleIdentifier"];
                bundleName = [info objectForKey:@"CFBundleDisplayName"]?:[info objectForKey:@"CFBundleName"];
                savedPath = [NSString stringWithFormat:@"%@/%@.app", savedPath.stringByDeletingLastPathComponent ,bundleID];
            
            } else if (isZip) {
                
                [[ECFileManager sharedManager] saveFile:filePath toPath:savedPath extendedAttributes:nil];
                NSArray* files = [self checkAndUnzipFile:savedPath];
                if (files) {
                    [savedFiles addObjectsFromArray:files];
                }
                continue;
            }
            
            BOOL res = [[ECFileManager sharedManager] saveFile:filePath toPath:savedPath extendedAttributes:@{@"bundle_name":bundleName, @"bundle_size":attribute[NSFileSize], @"import_time":[NSString stringWithFormat:@"%ld", NSDate.getLongDate]}];
            if (res) {
                [savedFiles addObject:savedPath];
            }
        }
    }
    
    [[ECFileManager sharedManager] removeAll:filePath];
    [[ECFileManager sharedManager] removeAll:unzipPath];
    return savedFiles;
}


//遍历读取子文件
- (NSArray <NSString *>* _Nullable)checkUpzipFileToSave:(NSString *)unzipPath{
    
    NSArray* files = [[ECFileManager sharedManager] subFiles:unzipPath];
    NSMutableArray* filePaths = [NSMutableArray array];
    for (NSString* filePath in files) {
        BOOL isDir;
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
        if (!res) {
            continue;
        }
        if (isDir && ![filePath hasSuffix:@".framework"] && ![filePath hasSuffix:@".app"]) {
            NSArray* paths = [self checkUpzipFileToSave:filePath];
            [filePaths addObjectsFromArray:paths];
        }
     
        [filePaths addObject:filePath];
    }

    return filePaths.copy;
}

#pragma mark Paths
- (NSString *)cachePath{
    
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:kCacheDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)downloadPath{

    NSString* path = [[self cachePath] stringByAppendingPathComponent:kDownloadDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)originIpaPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:kOriginIpaDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)signedIpaPath{

    NSString* path = [[self cachePath] stringByAppendingPathComponent:kSignedIpaDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)certificatePath{

    NSString* path = [[self cachePath] stringByAppendingPathComponent:kCertificateDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)mobileProvisionPath{

    NSString* path = [[self cachePath] stringByAppendingPathComponent:kMobileProvisionDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

- (NSString *)dylibPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:kDylibDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

- (NSString *)zipPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:kZipDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

- (NSString *)unzipPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:kUnzipDirectoryName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


- (NSString *)tmpPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:@"TMP"];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

- (NSString *)installPath{
    
    NSString* path = [[self cachePath] stringByAppendingPathComponent:@"install"];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}


@end
