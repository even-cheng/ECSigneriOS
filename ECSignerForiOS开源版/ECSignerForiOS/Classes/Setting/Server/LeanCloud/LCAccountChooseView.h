//
//  LCAccountChooseView.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCAccount.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^LCAccountChooseBlock)(LCAccount* account);
typedef void(^LCAccountAddBlock)(void);
typedef void(^LCAccountEditBlock)(LCAccount* account, BOOL is_delete);

@interface LCAccountChooseView : UIView

- (instancetype)initWithFrame:(CGRect)frame accounts:(NSArray<LCAccount *> *)accounts currentAccount:(NSString *)appID;
@property (nonatomic, copy) LCAccountChooseBlock chooseAccount;
@property (nonatomic, copy) LCAccountAddBlock addAccount;
@property (nonatomic, copy) LCAccountEditBlock editAccount;

@end

NS_ASSUME_NONNULL_END
