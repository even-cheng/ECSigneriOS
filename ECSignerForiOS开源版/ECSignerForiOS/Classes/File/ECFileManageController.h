//
//  ECFileManageController.h
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCertificateDetailController.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ECSegmenteTypeCers = 0,
    ECSegmenteTypeDylibs,
    ECSegmenteTypeOriginalIpas,
    ECSegmenteTypeSignedIpas
} ECSegmenteType;

@interface ECFileManageController : UIViewController

@property (nonatomic, assign) ECSegmenteType segmentType;
@property (nonatomic, assign) BOOL choosed;
@property (nonatomic, copy) ECFileChooseBlock fileChooseBlock;

@end


NS_ASSUME_NONNULL_END
