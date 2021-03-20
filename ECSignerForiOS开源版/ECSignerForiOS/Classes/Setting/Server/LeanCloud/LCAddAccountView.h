//
//  LCAddAccountView.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCAccount.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^LCAddAccountViewConfirmBlock)(NSString* name, NSString* appid, NSString* appkey, NSString* appurl);
@interface LCAddAccountView : UIView

+ (instancetype)addView;
@property (nonatomic, copy) LCAddAccountViewConfirmBlock confirmBlock;
@property (nonatomic, strong) LCAccount *account;

@end

NS_ASSUME_NONNULL_END
