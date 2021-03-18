//
//  CYAlertView.h
//  Ape_uni
//
//  Created by even on 8/21/13.
//  Copyright (c) 2013 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSMessage.h"

typedef void(^ECAlertActionBlock)(void);

@interface ECAlertView : NSObject

+ (void)alertMessageUnderNavigationBar:(NSString *)message subTitle:(NSString *_Nullable)subtitle type:(TSMessageNotificationType)type;

+ (UIAlertController *)alertConfirmMessage:(NSString*)msg;

+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                          cancelBlock:(void (^)(void))cancelBlock
                         confirmBlock:(void (^)(void))confirmBlock;
+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                                style:(UIAlertControllerStyle)style
                          cancelBlock:(void (^)(void))cancelBlock
                         confirmBlock:(void (^)(void))cnfirmBlock;

//@{@"title":@"", action:ECAlertActionBlock}
+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                              actions:(NSArray<NSDictionary *> *)actions;

@end
