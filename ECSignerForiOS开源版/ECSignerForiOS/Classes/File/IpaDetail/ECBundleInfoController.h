//
//  ECBundleInfoController.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/25.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECFile.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^ECBundleDylibsChooseBlock)(NSArray<NSDictionary*>* _Nullable choosed_files);
/*
 @{@"inject_name":@"", @"executable_name":@""}
 */

@interface ECBundleInfoController : UIViewController

@property (nonatomic, strong) ECApplicationFile* app;
@property (nonatomic, assign) BOOL choosed;
@property (nonatomic, copy) ECBundleDylibsChooseBlock choosedLibBlock;

@end

NS_ASSUME_NONNULL_END
