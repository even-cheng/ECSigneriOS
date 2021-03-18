//
//  ECiCloudFileController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/9.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECiCloudFileController.h"

@interface ECiCloudFileController ()

@end

@implementation ECiCloudFileController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UITabBar appearance] setTranslucent:YES];
}
 
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UITabBar appearance] setTranslucent:NO];
}
 
-(void)dealloc
{
    [[UITabBar appearance] setTranslucent:NO];
}

@end
