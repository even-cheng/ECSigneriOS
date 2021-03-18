//
//  ECAlertView.m
//  Ape_uni
//
//  Created by even Lan on 8/21/13.
//  Copyright (c) 2013 even_cheng. All rights reserved.
//

#import "ECAlertView.h"
#import "UIWindow+Current.h"

@implementation ECAlertView

+ (void)alertMessageUnderNavigationBar:(NSString *)message subTitle:(NSString *_Nullable)subtitle type:(TSMessageNotificationType)type {
    
    if (NSThread.currentThread.isMainThread) {
        
        [TSMessage showNotificationInViewController:[UIWindow currentViewController]
                                              title:message
                                           subtitle:subtitle
                                              image:nil
                                               type:type
                                           duration:TSMessageNotificationDurationAutomatic
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                               canBeDismissedByUser:YES];

    } else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [TSMessage showNotificationInViewController:[UIWindow currentViewController]
                                                  title:message
                                               subtitle:subtitle
                                                  image:nil
                                                   type:type
                                               duration:TSMessageNotificationDurationAutomatic
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        });
    }
    
}

+ (UIAlertController *)alertConfirmMessage:(NSString*)msg;{
   
    UIAlertController* alter = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionConfirm = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil];
    
    [alter addAction:actionConfirm];
    
    //ipad适配
    alter.popoverPresentationController.sourceView = [UIWindow currentViewController].view;
    alter.popoverPresentationController.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);

    return alter;
}

+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                          cancelBlock:(void (^)(void))cancelBlock
                         confirmBlock:(void (^)(void))cnfirmBlock;
{
    UIAlertController* alter = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionConfirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if (cnfirmBlock) {
            cnfirmBlock();
        }
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        if (cancelBlock) {
            cancelBlock();
        }
    }];

    [alter addAction:actionCancel];
    [alter addAction:actionConfirm];

    //ipad适配
    alter.popoverPresentationController.sourceView = [UIWindow currentViewController].view;
    alter.popoverPresentationController.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);

    return alter;
}

+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                                style:(UIAlertControllerStyle)style
                          cancelBlock:(void (^)(void))cancelBlock
                         confirmBlock:(void (^)(void))cnfirmBlock;
{
    UIAlertController* alter = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
    
    UIAlertAction* actionConfirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if (cnfirmBlock) {
            cnfirmBlock();
        }
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        if (cancelBlock) {
            cancelBlock();
        }
    }];

    [alter addAction:actionCancel];
    [alter addAction:actionConfirm];

    //ipad适配
    alter.popoverPresentationController.sourceView = [UIWindow currentViewController].view;
    alter.popoverPresentationController.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);

    return alter;
}

+ (UIAlertController *)alertWithTitle:(NSString *)title
                              message:(NSString *)message
                              actions:(NSArray *)actions;
{
    
    UIAlertController* alter = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSDictionary* obj in actions) {
        NSString* name = obj[@"name"];
        ECAlertActionBlock block = obj[@"action"];
        UIAlertActionStyle style = [[obj objectForKey:@"style"] integerValue];
        UIAlertAction* action = [UIAlertAction actionWithTitle:name style:style handler:^(UIAlertAction * _Nonnull action) {
            
            if (block) {
                block();
            }
        }];
     
        [alter addAction:action];
    }
    
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
   
    }];
    [alter addAction:actionCancel];

    //ipad适配
    alter.popoverPresentationController.sourceView = [UIWindow currentViewController].view;
    alter.popoverPresentationController.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);

    return alter;
}

@end
