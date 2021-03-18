//
//  NSDate+HandleDate.h
//  JTime
//
//  Created by Even on 16/11/11.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HandleDate)
//获取当前日期yyyy-MM-dd
+(NSString*)getTodayDate;
//获取昨天日期yyyy-MM-dd
+(NSString *)getYesterDay;
//获取明天日期yyyy-MM-dd
+(NSString *)getTomorrowDay;
/**
 *  获取今天之前指定多少天的日期
 */
+(NSString *)getDayEarlyFromToday:(NSInteger)earlyDays;
/**
 *  获取今天之后指定多少天的日期
 */
//获取日期差
+ (NSInteger)getDifferenceByDate:(NSString *)date;

//比较两个日期大小
+(int)compareOneDay:(NSDate *)oneDay withAnotherDay:(NSDate *)anotherDay;

+(NSString *)getDayLaterFromToday:(NSInteger)laterDays;
//获取当前系统的yyyy-MM-dd HH:mm:ss格式时间
+(NSString *)getTime;
//根据时间字符串获取时间戳
+(long)getDateLongWithDateStr:(NSString*)timeStr;

+(long)getDateLongWithDateYMDStr:(NSString *)timeStr;

//计算过滤时间，返回据现在的时间
+(NSString*)getFilterTimeFromNow:(long)timeLong;

//获取当前时间戳
+(long)getLongDate;
//获取当前时间戳字符串
+(NSString*)getLongStrDate;

+ (NSString *)getTimeStringByDate:(NSDate *)date;

//根据时间戳获取格式化字符串 2017-01-01
+(NSString*)getDateStrWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 2017:01:01
+(NSString*)getDateFormatStrWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 01月01日00点
+(NSString*)getDateFormatMonthToHourWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 2017年01月01日
+(NSString*)getDateFormatDayWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 2017-01-01 10:30:20
+(NSString*)getTimeStrWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 01-01 10:30
+(NSString*)getDateAndTimeMinuteWithLong:(long)timeLong;
//根据时间戳获取格式化字符串 2017-01-01 10:30
+(NSString*)getTimeStrToMinutesWithLong:(long)timeLong;
//获取A到B的秒数差
+(NSInteger)getTimeFrom:(NSString*)DateA ToDateB:(NSString*)dateB;
//将秒数转化为时间格式10:10:10
+(NSString*)changeSecondToDate:(NSInteger)second;

//将NSDate按yyyy-MM-dd HH:mm:ss格式时间输出
+(NSString*)nsdateToString:(NSDate *)date;
//格式化字符串转nsdate(精确到时间)
+(NSDate*)getDateFromStr:(NSString*)str;
//格式化字符串转nsdate(精确到日期)
+(NSDate*)getDateFromDateStr:(NSString*)str;

+ (NSString *)chindDateFormate:(NSDate *)date;

/**
 *  时间转换部分
 */
//从1970年开始到现在经过了多少秒
+(NSString *)getSecondFrom1970WithTime:(NSDate*)fromdate;

//比较给定NSDate与当前时间的时间差，返回相差的秒数
+(long)timeDifference:(NSDate *)date;

//发送数据时,16进制数－>Byte数组->NSData,加上校验码部分
+(NSData *)hexToByteToNSData:(NSString *)str;

//接收数据时,NSData－>Byte数组->16进制数
+(NSString *)NSDataToByteTohex:(NSData *)data;

/**根据字符串返回日期 2017-01-01*/
+ (NSDate *)dateFromString:(NSString *)dateString;

/**根据日期返回日期字符串 yy-MM-dd*/
+ (NSString *)stringFromDate:(NSDate *)date;

/**返回指定日期的年月日 2016-10-11*/
+ (NSString *)getYearOfString:(NSString *)dateString;
+ (NSString *)getMonthOfString:(NSString *)dateString;
+ (NSString *)getDayOfString:(NSString *)dateString;

/**返回当前的年月日*/
+ (NSString *)year;
+ (NSString *)month;
+ (NSString *)day;

+ (NSDate *)currentMonth;
+ (NSDate *)monthDateFromString:(NSString *)dateString;

/**将秒转化为 00:00:00格式*/
+ (NSString *)getTimeWithSecond:(NSInteger )second;

//根据时间戳获取格式化字符串 模板A
+(NSString*)getDateFormatModuleAWithLong:(long long)timeLong;

//根据时间戳获取格式化字符串 模板B
+(NSString*)getDateFormatModuleBWithLong:(long long)timeLong;

@end
