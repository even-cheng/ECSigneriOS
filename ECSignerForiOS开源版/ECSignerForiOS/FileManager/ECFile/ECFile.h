//
//  ECFile.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/9.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    ECFileTypeUnknown         = -1,
    ECFileTypeCertificate     = 0,
    ECFlieTypeDylib           = 1,
    ECFileTypeApplication     = 2,
    ECFileTypeMobileprovision = 3,
    ECFileTypeZip             = 4,
    ECFileTypeP8              = 5
} ECFileType;

static NSString* const ECFileChangedSuccessNotification = @"ECFileChangedSuccessNotification";

@interface ECFile : NSObject

@property (nonatomic, copy)   NSString *file_name;
@property (nonatomic, assign) ECFileType file_type;
@property (nonatomic, assign) long long add_time;
@property (nonatomic, assign) long long file_size;

@end

@interface ECApplicationFile : ECFile

@property (nonatomic, assign) BOOL resigned;
@property (nonatomic, assign) long long resigned_time;
@property (nonatomic, copy) NSString *resigned_cer_name;
@property (nonatomic, copy) NSString *bundle_name;

@end

@interface ECCertificateFile: ECFile

@property (nonatomic, assign) long long start_time;
@property (nonatomic, assign) long long expire_time;

@property (nonatomic, copy) NSString * _Nullable password;

@property (nonatomic, copy) NSString *country;          //国家或地区 C
@property (nonatomic, copy) NSString *name;             //常用名词  CN
@property (nonatomic, copy) NSString *organization;     //组织 O
@property (nonatomic, copy) NSString *organization_unit;//组织单位 OU
@property (nonatomic, copy) NSString *user_ID;          //用户ID UID

@property (nonatomic, assign) BOOL revoked;

@end

@interface ECMobileProvisionFile: ECFile

//info
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *app_id_name;
@property (nonatomic, copy) NSString *app_id;
@property (nonatomic, copy) NSString *bundle_id;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) BOOL provisions_all_devices;
@property (nonatomic, assign) long long create_date;
@property (nonatomic, assign) long long expiration_date;
@property (nonatomic, strong) NSArray<NSString *> *certificates;

@property (nonatomic, strong) NSArray<NSString *> *team_identifier;
@property (nonatomic, strong) NSString *team;
//devices
@property (nonatomic, strong) NSArray<NSString *> *device_udids;

@end


NS_ASSUME_NONNULL_END
