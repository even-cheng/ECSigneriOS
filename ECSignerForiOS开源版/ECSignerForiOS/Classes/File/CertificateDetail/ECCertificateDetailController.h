//
//  ECCertificateDetailController.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECFile.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^ECFileChooseBlock)(NSArray<ECFile*>* _Nullable choosed_files);
typedef void(^UpdateCerBlock)(ECCertificateFile *cer);

@interface ECCertificateDetailController : UIViewController

@property (nonatomic, assign) BOOL choosed;
@property (nonatomic, copy) ECFileChooseBlock _Nullable fileChooseBlock;
@property (nonatomic, strong) ECCertificateFile* cer;
@property (nonatomic, copy) UpdateCerBlock updateCerBlock;

@end

NS_ASSUME_NONNULL_END
