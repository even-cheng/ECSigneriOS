//
//  DK_DatePicker.m
//  douke_video
//
//  Created by Even on 2018/8/28.
//  Copyright © 2018年 Leon-Yang. All rights reserved.
//

#import "DK_DatePicker.h"
#import "PickerTopView.h"
#import "NSDate+HandleDate.h"
#import "TM_CoverView.h"
#import "ECConst.h"
#import "ECAlertController.h"
#import "UIWindow+Current.h"

@interface DK_DatePicker ()
@property (nonatomic, strong) PickerTopView *birthTopView;
@property (nonatomic, strong) ECAlertController *alertController;
@property (nonatomic, weak) UIDatePicker *datePicker;
@property (nonatomic, assign) BOOL onWindow;
@property (nonatomic, weak) TM_CoverView *coverView;
@end

@implementation DK_DatePicker

-(instancetype)init{
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 250)]) {
        [self setupViewsWithDefaultDate:[NSDate date] minDate:[NSDate dateFromString:@"1900-01-01"] maxDate:[NSDate date]];
    }
    return self;
}

-(instancetype)initWithDate:(NSDate*)currentDate;{
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 250)]) {
        [self setupViewsWithDefaultDate:currentDate minDate:[NSDate dateFromString:@"1900-01-01"] maxDate:[NSDate date]];
    }
    return self;
}

-(instancetype)initWithCurrentDate:(NSDate*)currentDate andMinDate:(NSDate*)minDate andMaxDate:(NSDate*)maxDate;{
 
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 250)]) {
        [self setupViewsWithDefaultDate:currentDate minDate:minDate maxDate:maxDate];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor{
    [super setBackgroundColor:backgroundColor];
    self.birthTopView.backgroundColor = backgroundColor;
}

- (void)setCancelTitle:(NSString *)cancelTitle{
    _cancelTitle = cancelTitle;
    
    [self.birthTopView.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title{
    _title = title;
    
    self.birthTopView.titleLabel.text = title;
}

- (void)showOnWindow:(BOOL)onWindow{
    _onWindow = onWindow;
    if (onWindow) {
        self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 250);

        TM_CoverView* coverView = [[TM_CoverView alloc]initWithFrame:kWindow.bounds];
        _coverView = coverView;
        [coverView coverWithView:self andPopCoverViewBlock:^{
            
            [UIView animateWithDuration:0.3 animations:^{
                self.y = SCREEN_HEIGHT-250;
            }];
            
        } andCloseBlock:^{
            
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.y = SCREEN_HEIGHT;
            } completion:nil];
        }];

    } else {
        self.alertController = [ECAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:ECAlertControllerStyleActionSheet animationType:ECAlertAnimationTypeRaiseUp customView:self];
        [[UIWindow currentViewController] presentViewController:self.alertController animated:YES completion:nil];
    }
}

- (void)setMinDate:(NSDate *)minDate{
    _datePicker.minimumDate = minDate;
}

- (void)setCurrentDate:(NSDate *)currentDate{
    [_datePicker setDate:currentDate animated:NO];
    [self reloadYearTitle];
}

- (void)setMaxDate:(NSDate *)maxDate{
    _datePicker.maximumDate = maxDate;
}

- (void)setupViewsWithDefaultDate:(NSDate*)date minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate{
    _minDate = minDate;
    _maxDate = maxDate;
    
    self.backgroundColor = [UIColor colorWithHexString:@"FFFFFF"];

    [self addSubview:self.birthTopView];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.height-206, SCREEN_WIDTH, 206)];
    _datePicker = datePicker;
    if (@available(iOS 13.4, *)) {
        [datePicker setPreferredDatePickerStyle:UIDatePickerStyleWheels];
    }
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh"];
    datePicker.tag = 130;
    datePicker.minimumDate = minDate;
    datePicker.maximumDate = maxDate;
    datePicker.date = [NSDate dateWithTimeIntervalSinceNow:0];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [datePicker addTarget:self action:@selector(changeDateAction:) forControlEvents:UIControlEventValueChanged];
    
    [self addSubview:datePicker];
    datePicker.centerX = self.centerX;
    
    [datePicker setDate:date animated:NO];
    [self reloadYearTitle];
}

- (void)changeDateAction:(UIDatePicker*)datePicker{

    int compareWithMax = [NSDate compareOneDay:datePicker.date withAnotherDay:self.maxDate];
    int compareWithMin = [NSDate compareOneDay:datePicker.date withAnotherDay:self.minDate];

    // >
    if (compareWithMax == 1) {
        [datePicker setDate:self.maxDate animated:NO];
    // <
    }
    if (compareWithMin == -1) {
        [datePicker setDate:self.minDate animated:NO];
    }
    
    [self reloadYearTitle];
}

- (void)reloadYearTitle{
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy年";
    NSString *dateStr = [formatter stringFromDate:self.datePicker.date];
    self.birthTopView.titleLabel.text = dateStr;
}

- (PickerTopView *)birthTopView {
    if (!_birthTopView) {
        @weakify(self);
        _birthTopView = [[PickerTopView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44) pickViewCancelBlock:^{
            @strongify(self);
            
            if (!self.onWindow) {
                [self.alertController dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.coverView removeCover];
            }
            if (self.pickerChooseBlock) {
                self.pickerChooseBlock(YES, nil);
            }
            
        } pickViewSureBlock:^{
            @strongify(self);

            if (!self.onWindow) {
                [self.alertController dismissViewControllerAnimated:YES completion:^{
                    
                    UIDatePicker *picker =  [self viewWithTag:130];
                    if (self.pickerChooseBlock) {
                        self.pickerChooseBlock(NO, picker.date);
                    }
                }];
            } else {
                UIDatePicker *picker =  [self viewWithTag:130];
                if (self.pickerChooseBlock) {
                    self.pickerChooseBlock(NO, picker.date);
                }
                [self.coverView removeCover];
            }
        }];
        _birthTopView.backgroundColor = [UIColor whiteColor];
    }
    _birthTopView.titleLabel.text = @"选择时间";
    
    return _birthTopView;
}

@end
