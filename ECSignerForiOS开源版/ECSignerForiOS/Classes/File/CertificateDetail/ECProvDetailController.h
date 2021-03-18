//
//  ECProvDetailController.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface ECProvDetailController : UIViewController

@property (nonatomic, strong) ECMobileProvisionFile *prov;

@end

NS_ASSUME_NONNULL_END
