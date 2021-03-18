//
//  ECFileQuestionView.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^ECFileQuestionAlertCloseBlock)(void);
@interface ECFileQuestionView : UIView

@property (nonatomic, copy) ECFileQuestionAlertCloseBlock alertCloseBlock;

@end

NS_ASSUME_NONNULL_END
