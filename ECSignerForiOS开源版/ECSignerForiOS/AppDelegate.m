//
//  AppDelegate.m
//  ECSignerForiOS
//
//  Created by even on 2020/8/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "AppDelegate.h"
#import "ECMainTabbarController.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "ECAlertView.h"
#import "ECAlertController.h"
#import "ECFileManager.h"
#import "LCManager.h"
#import "ECFileManageController.h"
#import "iCloudManager.h"
#import "UIWindow+Current.h"
#import "SSZipArchive.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCManager.h"
#import "ECAlertView.h"
#import "LCSignModel.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "ECHttpsConnection.h"
#include <string.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import "ECConst.h"
#import "MyObject.h"
//#import "ECSignerForiOS-Swift.h"
#import <sys/sysctl.h>
#import "ECSignProgressView.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@property (nonatomic,strong) HTTPServer *localHttpServer;

@property (nonatomic, assign) UIBackgroundTaskIdentifier task;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) ECSignProgressView *signProgressView;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [ECMainTabbarController new];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
        
    //全局键盘设置
    [IQKeyboardManager sharedManager].enableAutoToolbar = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [IQKeyboardManager sharedManager].toolbarDoneBarButtonItemText = @"收起";
    
    [self initLeanCloud];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self configLocalHttpServer];
    });
    
    [[LCManager sharedManager] deleteAllPlistFile];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:@"ECSigner_Launch_time"];
    [[NSUserDefaults standardUserDefaults] synchronize];
        
    //socket心跳包
    NSTimer *socketTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(socketTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:socketTimer forMode:NSRunLoopCommonModes];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"EC_HttpServer_RepushNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
        [self.localHttpServer stop];
        [self startServer];
    }];
        
    return YES;
}

- (void)socketTimer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SOCKETTIMER" object:nil];//计时器内周期性去调用socket心跳包，保持连接。
}


- (void)initLeanCloud{
    
    LCAccount* currentAccount = [LCManager sharedManager].current_account;
    if (!currentAccount) {
        return;
    }
    if ([[AVOSCloud getApplicationId] isEqualToString:currentAccount.appID]) {
        return;
    }
    
    [LCSignModel registerSubclass];
    [AVOSCloud setAllLogsEnabled:YES];
    [AVOSCloud setLogLevel:AVLogLevelInfo];
    [AVOSCloud setVerbosePolicy:kAVVerboseShow];
    [AVOSCloud setApplicationId:[LCManager sharedManager].current_account.appID ?:@""
                      clientKey:[LCManager sharedManager].current_account.appKey ?:@""
                serverURLString:[LCManager sharedManager].current_account.serverUrl ?:@""];
    
}

- (void)receiveFileSavedNotification:(NSNotification *)noti{
    
    ECFileType fileType = [noti.userInfo[@"file_type"] integerValue];
    if (fileType == ECFileTypeZip) {
        
        if ([NSThread isMainThread]) {
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self checkAndUnzipFile];
            });
            
        } else {
            
            [self checkAndUnzipFile];
        }
    }
}

- (void)checkAndUnzipFile{
    
    NSString* zipPath = [ECFileManager sharedManager].zipPath;
    NSString* unzipPath = [ECFileManager sharedManager].unzipPath;
    
    NSArray* files = [[ECFileManager sharedManager] subFiles:zipPath];
    for (NSString* filePath in files) {
        
        BOOL is_ipa = [SSZipArchive isIpa:filePath];
        if (is_ipa || [filePath hasSuffix:@".ipa"]) {
            
            NSString* ipaPath = [[ECFileManager sharedManager].originIpaPath stringByAppendingPathComponent:filePath.lastPathComponent];
            ipaPath = [ipaPath stringByReplacingOccurrencesOfString:@".zip" withString:@".ipa"];
            NSError* error;
            if ([[NSFileManager defaultManager] fileExistsAtPath:ipaPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:ipaPath error:&error];
            }
            BOOL res = [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:ipaPath error:&error];
            if (!res) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
                
            [ECAlertView alertMessageUnderNavigationBar:@"导入成功" subTitle:@"文件已自动分类，请前往文件下拉刷新查看" type:TSMessageNotificationTypeSuccess];
        
        } else {
    
            BOOL success = [SSZipArchive unzipFileAtPath:filePath toDestination:unzipPath];
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (success) {
                
                [self saveUnzipFileAndClean];
                NSLog(@"Success unzip");
            } else {
                NSLog(@"unzip IPA failed");
            }
        }
    }
    
    [[ECFileManager sharedManager] removeAll:zipPath];
}

- (void)saveUnzipFileAndClean{
    
    NSString* unzipPath = [ECFileManager sharedManager].unzipPath;

    NSArray* files = [self checkUpzipFileToSave:unzipPath];
    for (NSString* filePath in files) {
        
        NSString* savedPath = [[ECFileManager sharedManager] localPathForFile:filePath resigned:NO];
        if (!savedPath) {
            continue;
        }
        [[ECFileManager sharedManager] saveFile:filePath toPath:savedPath extendedAttributes:nil];
    }
    
    [ECAlertView alertMessageUnderNavigationBar:@"导入成功" subTitle:@"文件已自动分类，请前往文件下拉刷新查看" type:TSMessageNotificationTypeSuccess];
    [[ECFileManager sharedManager] removeAll:unzipPath];
}


//遍历读取子文件
- (NSArray <NSString *>* _Nullable)checkUpzipFileToSave:(NSString *)unzipPath{
    
    NSArray* files = [[ECFileManager sharedManager] subFiles:unzipPath];
    NSMutableArray* filePaths = [NSMutableArray array];
    for (NSString* filePath in files) {
        BOOL isDir;
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
        if (!res) {
            continue;
        }
        if (isDir && ![filePath hasSuffix:@".framework"] && ![filePath hasSuffix:@".app"]) {
            NSArray* paths = [self checkUpzipFileToSave:filePath];
            [filePaths addObjectsFromArray:paths];
        }
     
        [filePaths addObject:filePath];
    }

    return filePaths.copy;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if (_task) {
        [[UIApplication sharedApplication] endBackgroundTask:_task];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    /** 播放声音 */
    [self.player play];

    __weak typeof(self) weakSelf = self;
    _task = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"ecsigner_backgroundTask" expirationHandler:^{
        [application endBackgroundTask:weakSelf.task];
        weakSelf.task = UIBackgroundTaskInvalid;
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (AVAudioPlayer *)player{
    if (!_player){
        NSURL *url=[[NSBundle mainBundle]URLForResource:@"backgroundTask.mp3" withExtension:nil];
        _player = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        [_player prepareToPlay];
        //一直循环播放
        _player.numberOfLoops = -1;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        [session setActive:YES error:nil];
    }
    return _player;
}

- (void)configLocalHttpServer{
    
    [DDLog addLogger:DDTTYLogger.sharedInstance];
    
    _localHttpServer = [[HTTPServer alloc] init];
    [_localHttpServer setType:@"_http._tcp."];
    [_localHttpServer setPort:13140];
    [_localHttpServer setDomain:@"http://127.0.0.1"];
    [_localHttpServer setConnectionClass:[ECHttpsConnection class]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [ECFileManager sharedManager].installPath;
    if (![fileManager fileExistsAtPath:path]){
        NSLog(@">>>> File path error!");
    }else{
        [_localHttpServer setDocumentRoot:path];
//        NSLog(@">>webLocalPath:%@",path);
        [self startServer];
    }
}

- (bool)startServer{
    NSError *error;
    if([_localHttpServer start:&error]){
        [self.timer fire];
//        NSLog(@"Started HTTP Server on port %hu", [_localHttpServer listeningPort]);
        return YES;
    }
    else{
        NSLog(@"Error starting HTTP Server: %@", error);
        return NO;;
    }
}


- (NSTimer *)timer{
    if (nil == _timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setRunLoop) userInfo:nil repeats:YES];
        NSRunLoop *curRun = [NSRunLoop currentRunLoop];
        [curRun addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

-(void)setRunLoop{
//    NSLog(@"运行中");
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options{
    
    if (url == nil) {
        return NO;
    }
    if ([url.absoluteString isEqualToString:@"ecsignios://"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ECSigner_GetUDID" object:nil userInfo:nil];
        return YES;
    }

    [ECAlertView alertMessageUnderNavigationBar:@"文件正在导入" subTitle:@"导入完成后将自动进行分类" type:TSMessageNotificationTypeMessage];
    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    [alert setTapBackgroundViewDismiss:NO];
    [[UIWindow currentViewController] presentViewController:alert animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ecsign_unzip_progress_notification" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSDictionary* userinfo = note.userInfo;
        self.signProgressView.progress = [userinfo[@"progress"] floatValue];
    }];
    
    [[ECFileManager sharedManager] importFile:url withComplete:^(NSArray<NSString *>* _Nullable savedPath, NSString* _Nullable des) {
        
        //删除数据与文稿的临时文件
        [NSFileManager.defaultManager removeItemAtURL:url error:nil];
        if (!savedPath) {
            [alert dismissViewControllerAnimated:YES completion:^{
                [ECAlertView alertMessageUnderNavigationBar:@"文件导入失败" subTitle:des type:TSMessageNotificationTypeError];
            }];
            return;
        }
        
        [alert dismissViewControllerAnimated:YES completion:^{

            [ECAlertView alertMessageUnderNavigationBar:@"导入成功" subTitle:@"文件已自动分类，请前往文件中心刷新查看" type:TSMessageNotificationTypeSuccess];
        }];
    }];
    
    return YES;
}


- (void)didReceiveMemoryWarning{
    NSLog(@"App Memory warning...");
}


- (ECSignProgressView *)signProgressView{
    if (!_signProgressView) {
        _signProgressView = [[ECSignProgressView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
        _signProgressView.progress = 0.5;
        _signProgressView.title = @"正在导入..";
    }
    return _signProgressView;
}

@end
