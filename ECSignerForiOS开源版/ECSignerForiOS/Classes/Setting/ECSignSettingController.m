//
//  ECSignSettingController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/11/26.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECSignSettingController.h"

@interface ECSignSettingController ()

@property (weak, nonatomic) IBOutlet UISwitch *deleteSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *linkPathSegment;

@end

@implementation ECSignSettingController

-(instancetype)init{
    
    if (self = [super init]) {
        self =[[UIStoryboard storyboardWithName:@"ECSignSettingController" bundle:nil]instantiateViewControllerWithIdentifier:@"ECSignSettingController"];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"签名设置";
    
    BOOL autoDelete = [[NSUserDefaults standardUserDefaults] boolForKey:@"ecsigner_autoDeleteWhenSignDone"];
    [self.deleteSwitch setOn: autoDelete];
    
    BOOL linkdRPath= [[NSUserDefaults standardUserDefaults] boolForKey:@"ecsigner_linkdRPath"];
    self.linkPathSegment.selectedSegmentIndex = linkdRPath;
}

- (IBAction)linkPathChangeAction:(UISegmentedControl *)sender {
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.selectedSegmentIndex forKey:@"ecsigner_linkdRPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)switchAction:(UISwitch *)sender {

    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"ecsigner_autoDeleteWhenSignDone"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
