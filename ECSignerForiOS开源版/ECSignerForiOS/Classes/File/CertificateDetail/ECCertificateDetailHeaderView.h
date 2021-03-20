//
//  ECCertificateDetailHeaderView.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECFile.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^ECCertificateReloadBlock)(void);
@interface ECCertificateDetailHeaderView : UIView

@property (nonatomic, strong) ECCertificateFile* file;
@property (nonatomic, assign) BOOL modify;
@property (nonatomic, copy) ECCertificateReloadBlock reloadBlock;

- (void)update;

@end

NS_ASSUME_NONNULL_END
