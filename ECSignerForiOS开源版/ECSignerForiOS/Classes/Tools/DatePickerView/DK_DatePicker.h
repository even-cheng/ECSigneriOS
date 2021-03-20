//
//  DK_DatePicker.h
//  douke_video
//
//  Created by Even on 2018/8/28.
//  Copyright © 2018年 Leon-Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^DK_DatePickerChooseBlock)(BOOL cancel, NSDate* _Nullable chooseDate);
@interface DK_DatePicker : UIView

@property (nonatomic, weak) NSDate *minDate;
@property (nonatomic, weak) NSDate *maxDate;
@property (nonatomic, weak) NSDate *currentDate;
@property (nonatomic, copy) NSString *cancelTitle;
@property (nonatomic, copy) NSString *title;
@property(copy,nonatomic)DK_DatePickerChooseBlock pickerChooseBlock;
-(instancetype)initWithDate:(NSDate*)currentDate;
-(instancetype)initWithCurrentDate:(NSDate*)currentDate andMinDate:(NSDate*)minDate andMaxDate:(NSDate*)maxDate;
- (void)showOnWindow:(BOOL)onWindow;

@end

/*
 - (DK_DatePicker *)birthPickerView{
     if (!_birthPickerView) {
         NSDate *currentDate = [NSDate date];
         if (self.changeModel.birthday.length >= 8){
             NSString* birthday = [NSString stringWithFormat:@"%@-%@-%@",[self.changeModel.birthday substringToIndex:4],[self.changeModel.birthday substringWithRange:NSMakeRange(4, 2)],[self.changeModel.birthday substringWithRange:NSMakeRange(6, 2)]];
                 currentDate = [NSDate dateFromString:birthday];
         }
         _birthPickerView = [[DK_DatePicker alloc]initWithDate:currentDate];
     }
     return _birthPickerView;
 }
 
 
 -(void)birthdayChangeAction{
     
     [self.birthPickerView show];
     WEAKSELF
     self.birthPickerView.pickerChooseBlock = ^(NSDate *date) {
       
         NSString* oldBirthday = weakSelf.changeModel.birthday;
         NSString *dateString = [NSDate stringFromDate:date];
         weakSelf.changeModel.birthday = [dateString stringByReplacingOccurrencesOfString:@"-" withString:@""];
         [weakSelf saveActionWithComplete:^(BOOL success) {
             
             if (success) {
                 
                 [weakSelf.settingTableView reloadRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] withRowAnimation:UITableViewRowAnimationNone];
             } else {
                 weakSelf.changeModel.birthday = oldBirthday;
             }
         }];
     };
 }
 */
