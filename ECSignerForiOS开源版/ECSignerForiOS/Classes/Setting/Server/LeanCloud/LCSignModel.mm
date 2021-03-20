//
//  LCSignModel.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/17.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "LCSignModel.h"

@implementation LCSignModel

@dynamic file_name;
@dynamic bundle_id;
@dynamic bundle_name;
@dynamic cer_name;
@dynamic prov_name;
@dynamic lock_start_time;
@dynamic lock_end_time;
@dynamic lock_maxCountOfDay;
@dynamic lock_maxCountTotal;
@dynamic enable;
@dynamic install_countOfDay;
@dynamic install_countTotal;
@dynamic sign_time;
@dynamic bundle_size;
@dynamic devices;
@dynamic install_update_time;

+ (NSString *)parseClassName {
    return @"ECSigner";
}

@end
