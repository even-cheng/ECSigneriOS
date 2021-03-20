//
//  LCSignModel.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/17.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCSignModel : AVObject <AVSubclassing>

@property (nonatomic, copy) NSString *file_name;
@property (nonatomic, copy) NSString *bundle_id;
@property (nonatomic, copy) NSString *bundle_name;
@property (nonatomic, copy) NSString * bundle_size;
@property (nonatomic, copy) NSString *cer_name;
@property (nonatomic, copy) NSString *prov_name;
@property (nonatomic, copy) NSDate* sign_time;
@property (nonatomic, copy) NSDate* lock_start_time;
@property (nonatomic, copy) NSDate* lock_end_time;
@property (nonatomic, copy) NSDate* install_update_time;
@property (nonatomic, copy) NSString * lock_maxCountOfDay;
@property (nonatomic, copy) NSString * lock_maxCountTotal;
@property (nonatomic, copy) NSString * install_countOfDay;
@property (nonatomic, copy) NSString * install_countTotal;
@property (nonatomic, copy) NSString * enable;
@property (nonatomic, strong) NSArray *devices;


@end

NS_ASSUME_NONNULL_END
