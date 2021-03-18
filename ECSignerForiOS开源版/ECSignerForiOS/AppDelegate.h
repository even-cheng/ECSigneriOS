//
//  AppDelegate.h
//  ECSignerForiOS
//
//  Created by even on 2020/8/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPServer.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void)initLeanCloud;
- (void)checkAndUnzipFile;

@end

