//
//  NSDate+HandleDate.m
//  JTime
//
//  Created by Even on 16/11/11.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "NSDate+HandleDate.h"

@implementation NSDate (HandleDate)


//获取当天的日期
+(NSString*)getTodayDate{
    
    NSDate* nowDate = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *date = [formatter stringFromDate:nowDate];
    
    return date;
}

//获取昨天的日期
+(NSString*)getYesterDay{
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *tomorrow = [[NSDate alloc] initWithTimeIntervalSinceNow:-secondsPerDay];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *date = [formatter stringFromDate:tomorrow];
    
    return date;
}

/**
 *  获取今天之前指定多少天的日期
 */
+(NSString *)getDayEarlyFromToday:(NSInteger)earlyDays;
{
    NSTimeInterval secondsPerDay = 24 * 60 * 60*earlyDays;
    NSDate *tomorrow = [[NSDate alloc] initWithTimeIntervalSinceNow:-secondsPerDay];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *date = [formatter stringFromDate:tomorrow];
    
    return date;
}

/**
 *  获取今天之后指定多少天的日期
 */
+(NSString *)getDayLaterFromToday:(NSInteger)laterDays;{
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60*laterDays;
    NSDate *tomorrow = [[NSDate alloc] initWithTimeIntervalSinceNow:secondsPerDay];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *date = [formatter stringFromDate:tomorrow];
    
    return date;
}

//获取明天日期
+(NSString *)getTomorrowDay
{
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    //明天时间
    NSDate *tomorrow = [[NSDate alloc] initWithTimeIntervalSinceNow:secondsPerDay];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *date = [formatter stringFromDate:tomorrow];
    
    return date;
}

//获取当前系统的yyyy-MM-dd HH:mm:ss:SSS格式时间
+(NSString *)getTime
{
    NSDate *fromdate=[NSDate date];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* string=[dateFormat stringFromDate:fromdate];
    return string;
}

+ (NSString *)getTimeStringByDate:(NSDate *)date;{

    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* string=[dateFormat stringFromDate:date];
    return string;
}


//根据时间字符串获取时间戳
+(long)getDateLongWithDateStr:(NSString*)timeStr;
{
    long time;
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *fromdate=[format dateFromString:timeStr];
    
    time= (long)[fromdate timeIntervalSince1970];
    
    return time;
}

+(long)getDateLongWithDateYMDStr:(NSString*)timeStr;
{
    long time;
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone = [NSTimeZone systemTimeZone];
    [format setDateFormat:@"yyyy-MM-dd"];
    NSDate *fromdate=[format dateFromString:timeStr];
    
    time= (long)[fromdate timeIntervalSince1970];
    
    return time;
}

+ (NSString *)chindDateFormate:(NSDate *)update{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *destDateString = [dateFormatter stringFromDate:update];
    return destDateString;
}

//获取当前时间戳
+(long)getLongDate{

    return [[self date]timeIntervalSince1970];
}
+(NSString*)getLongStrDate;
{
    return [NSString stringWithFormat:@"%ld",[NSDate getLongDate]];
}

//计算过滤时间，返回据现在的时间
+(NSString*)getFilterTimeFromNow:(long)timeLong;{

    long nowLong = [NSDate getLongDate];
    long time = nowLong-timeLong;
    
    if (time < 60*10) {
        
        return @"一分钟前";
        
    } else if (time >= 60*10 && time < 60*30) {
    
        return @"10分钟以前";
        
    }  else if (time >= 60*30 && time < 60*60) {
        
        return @"半个小时以前";
        
    } else if (time >= 60*60 && time < 60*60*2) {
        
        return @"1小时以前";
        
    } else if (time >= 60*60*2 && time < 60*60*48) {
        
        NSString* timeStr = [NSDate getTimeStrWithLong:timeLong];
        NSString* today = [NSDate getTodayDate];
        NSString* yesterDay = [NSDate getYesterDay];

        if ([timeStr containsString:today]) {
            
            return [NSString stringWithFormat:@"今天 %@",[timeStr substringFromIndex:10]];
            
        } else if ([timeStr containsString:yesterDay]){
        
            return [NSString stringWithFormat:@"昨天 %@",[timeStr substringFromIndex:10]];
            
        } else {
        
            return [NSString stringWithFormat:@"前天 %@",[timeStr substringFromIndex:10]];
        }
        
    }  else {
        
        NSString* timeStr = [[[NSDate getTimeStrWithLong:timeLong] substringToIndex:16] substringFromIndex:2];
        return timeStr;
    }
}

//获取时间差
+(NSInteger)getTimeFrom:(NSString*)DateA ToDateB:(NSString*)dateB;
{
    
    NSString* secondA = [self getSecondFrom1970WithTime:[self getDateFromStr: DateA]];
    NSString* secondB = [self getSecondFrom1970WithTime:[self getDateFromStr: dateB]];
    
    return secondB.integerValue - secondA.integerValue;
}

+(NSDate*)getDateFromStr:(NSString*)str{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate* date1 = [formatter dateFromString:str];
    
    return date1;
}
//格式化字符串转nsdate(精确到日期)
+(NSDate*)getDateFromDateStr:(NSString*)str;{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate* date1 = [formatter dateFromString:str];
    
    return date1;
}


//获取日期差
+ (NSInteger)getDifferenceByDate:(NSString *)date {
    //获得当前时间
    NSDate *now = [NSDate date];
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *oldDate = [dateFormatter dateFromString:date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned int unitFlags = NSCalendarUnitDay;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:oldDate  toDate:now  options:0];
    return [comps day];
}


//将秒数转化为时间格式
+(NSString*)changeSecondToDate:(NSInteger)second;
{
    NSInteger sec = second%60;
    NSInteger min = second/60%60;
    NSInteger hour = second/60/60;
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hour, min, sec];
}

/**
 *  时间转换部分
 */
//从1970年开始到现在经过了多少秒
+(NSString *)getSecondFrom1970WithTime:(NSDate*)fromdate
{
    NSString *time;
    time = [NSString stringWithFormat:@"%f",[fromdate timeIntervalSince1970]];
    return time;
}


//根据时间戳获取格式化字符串 2017-01-01
+(NSString*)getDateStrWithLong:(long)timeLong;{
    
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}


//根据时间戳获取格式化字符串 2017:01:01
+(NSString*)getDateFormatStrWithLong:(long)timeLong;{
    
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy:MM:dd"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}


//根据时间戳获取格式化字符串 2017年01月01日
+(NSString*)getDateFormatDayWithLong:(long)timeLong;{
    
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}

+(NSString*)getDateFormatMonthToHourWithLong:(long)timeLong;{
    
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"MM月dd日HH点"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}

//根据时间戳获取格式化字符串 2017-01-01 10:30
+(NSString*)getTimeStrToMinutesWithLong:(long)timeLong;{
 
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}

//将时间戳转换成字符串
+(NSString*)getTimeStrWithLong:(long)timeLong;
{
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}


+(NSString*)getDateAndTimeMinuteWithLong:(long)timeLong;{
    
    NSTimeInterval time = timeLong;
    if ([[NSString stringWithFormat:@"%ld",timeLong] length] > 10) {
        time = timeLong / 1000;
    }
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    
    //实例化一个NSDateFormatter对象
    NSDateFormatter*dateFormatter = [[NSDateFormatter alloc]init];
    
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    
    NSString*currentDateStr = [dateFormatter stringFromDate:detaildate];
    
    return currentDateStr;
}


//比较给定NSDate与当前时间的时间差，返回相差的秒数
+(long)timeDifference:(NSDate *)date
{
    NSDate *localeDate = [NSDate date];
    long difference =fabs([localeDate timeIntervalSinceDate:date]);
    return difference;
}

//将NSDate按yyyy-MM-dd HH:mm:ss格式时间输出
+(NSString*)nsdateToString:(NSDate *)date
{
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* string=[dateFormat stringFromDate:date];
    return string;
}


//发送数据时,16进制数－>Byte数组->NSData,加上校验码部分
+(NSData *)hexToByteToNSData:(NSString *)str
{
    int j=0;
    Byte bytes[[str length]/2];                         ////Byte数组即字节数组,类似于C语言的char[],每个汉字占两个字节，每个数字或者标点、字母占一个字节
    for(int i=0;i<[str length];i++)
    {
        /**
         *  在iphone/mac开发中，unichar是两字节长的char，代表unicode的一个字符。
         *  两个单引号只能用于char。可以采用直接写文字编码的方式来初始化。采用下面方法可以解决多字符问题
         */
        int int_ch;                                     ///两位16进制数转化后的10进制数
        unichar hex_char1 = [str characterAtIndex:i];   ////两位16进制数中的第一位(高位*16)
        
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
        {
            int_ch1 = (hex_char1-48)*16;                //// 0 的Ascll - 48
        }
        else if(hex_char1 >= 'A' && hex_char1 <='F')
        {
            int_ch1 = (hex_char1-55)*16;                //// A 的Ascll - 65
        }
        else
        {
            int_ch1 = (hex_char1-87)*16;                //// a 的Ascll - 97
        }
        
        i++;
        
        unichar hex_char2 = [str characterAtIndex:i];   ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
        {
            int_ch2 = (hex_char2-48);                   //// 0 的Ascll - 48
        }
        else if(hex_char2 >= 'A' && hex_char2 <='F')
        {
            int_ch2 = hex_char2-55;                     //// A 的Ascll - 65
        }
        else
        {
            int_ch2 = hex_char2-87;                     //// a 的Ascll - 97
        }
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;                              ///将转化后的数放入Byte数组里
        
        //        if (j==[str length]/2-2) {
        //            int k=2;
        //            int_ch=bytes[0]^bytes[1];
        //            while (k
        //                int_ch=int_ch^bytes[k];
        //                k++;
        //            }
        //            bytes[j] = int_ch;
        //        }
        
        j++;
    }
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:[str length]/2 ];
    NSLog(@"%@",newData);
    return newData;
}


//接收数据时,NSData－>Byte数组->16进制数
+(NSString *)NSDataToByteTohex:(NSData *)data
{
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数,与 0xff 做 & 运算会将 byte 值变成 int 类型的值，也将 -128～0 间的负值都转成正值了。
        if([newHexStr length]==1)
        {
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        }
        else
        {
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    //    NSLog(@"hexStr:%@",hexStr);
    return hexStr;
}

+ (NSDate *)dateFromString:(NSString *)dateString {
    NSDateFormatter *dateForMatter = [[NSDateFormatter alloc] init];
    [dateForMatter setDateFormat:@"yyyy-MM-dd"];
    return [dateForMatter dateFromString:dateString];
}

+ (NSDate *)monthDateFromString:(NSString *)dateString {
    NSDateFormatter *dateForMatter = [[NSDateFormatter alloc] init];
    [dateForMatter setDateFormat:@"yyyy-MM"];
    return [dateForMatter dateFromString:dateString];
}
+ (NSDate *)currentMonth {
    NSString* dateString = [NSString stringWithFormat:@"%@-%@",[NSDate year],[NSDate month]];
    NSDateFormatter *dateForMatter = [[NSDateFormatter alloc] init];
    [dateForMatter setDateFormat:@"yyyy-MM"];
    return [dateForMatter dateFromString:dateString];
}

//比较两个日期大小
+(int)compareOneDay:(NSDate *)oneDay withAnotherDay:(NSDate *)anotherDay
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    
    NSString *oneDayStr = [dateFormatter stringFromDate:oneDay];
    
    NSString *anotherDayStr = [dateFormatter stringFromDate:anotherDay];
    
    NSDate *dateA = [dateFormatter dateFromString:oneDayStr];
    
    NSDate *dateB = [dateFormatter dateFromString:anotherDayStr];
    
    NSComparisonResult result = [dateA compare:dateB];
    
    if (result == NSOrderedDescending) {
        //NSLog(@"oneDay比 anotherDay时间晚");
        return 1;
    }
    else if (result == NSOrderedAscending){
        //NSLog(@"oneDay比 anotherDay时间早");
        return -1;
    }
    //NSLog(@"两者时间是同一个时间");
    return 0;
    
}


+ (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *dateForMatter = [[NSDateFormatter alloc] init];
    [dateForMatter setDateFormat:@"yyyy-MM-dd"];
    //[dateForMatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    return [dateForMatter stringFromDate:date];
}

+ (NSString *)getYearOfString:(NSString *)dateString {
    
    if (dateString.length > 4) {
        
        return [dateString substringWithRange:NSMakeRange(0, 4)];
    }
    
    return dateString;
}

+ (NSString *)getMonthOfString:(NSString *)dateString {
    return [dateString substringWithRange:NSMakeRange(5, 2)];
    
}

+(NSString *)getDayOfString:(NSString *)dateString {
    return [dateString substringWithRange:NSMakeRange(8, 2)];
}

+ (NSString *)year {
    return [[self getTodayDate] substringToIndex:4];
}

+ (NSString *)month {
    return [[self getTodayDate] substringWithRange:NSMakeRange(5, 2)];
}

+ (NSString *)day {
    return [[self getTodayDate] substringWithRange:NSMakeRange(8, 2)];
}

+ (NSString *)getTimeWithSecond:(NSInteger)second {
    
    NSInteger h = second / 3600;
    NSInteger m = second % 3600 / 60;
    NSInteger s = second % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",h,m,s];
}

+(NSString*)getDateFormatModuleAWithLong:(long long)timeLong;{
    
    if ([[NSString stringWithFormat:@"%lld",timeLong] length] > 10) {
        timeLong = timeLong / 1000;
    }
    
    NSInteger currentYearStr = [NSDate year].integerValue;
    
    NSString* timeStr = [NSDate getTimeStrWithLong:timeLong];
    NSInteger showYear = [timeStr substringToIndex:4].integerValue;
    
    NSString* showMonth = [[timeStr substringToIndex:7] substringFromIndex:5];
    NSString* showDay = [[timeStr substringToIndex:10] substringFromIndex:8];
    NSString* showHour = [[timeStr substringToIndex:13] substringFromIndex:11];
    NSString* showMinute = [[timeStr substringToIndex:16] substringFromIndex:14];

//    NSString* hourString = @"";
//    if (showHour.integerValue <= 5) {
//        hourString = @"凌晨";
//    } else if (showHour.integerValue <= 11) {
//        hourString = @"上午";
//    } else if (showHour.integerValue == 12) {
//        hourString = @"中午";
//    } else if (showHour.integerValue <= 18) {
//        hourString = @"下午";
//    } else {
//        hourString = @"晚上";
//    }
    
    if (currentYearStr != showYear) {
        return [NSString stringWithFormat:@"%ld/%@/%@ %@:%@",showYear,showMonth,showDay,showHour,showMinute];
    } else {
        
        long nowLong = [NSDate getLongDate];
        long time = nowLong-timeLong;
        if (time <= 60*2) {
            
            return @"刚刚";
            
        } else if (time >= 60*2 && time < 60*60*48) {
            
            NSString* timeStr = [NSDate getTimeStrWithLong:timeLong];
            NSString* today = [NSDate getTodayDate];
            NSString* yesterDay = [NSDate getYesterDay];
            
            if ([timeStr containsString:today]) {
                
                return [NSString stringWithFormat:@"%@:%@",showHour,showMinute];
                
            } else if ([timeStr containsString:yesterDay]){
                
                return [NSString stringWithFormat:@"昨天%@:%@",showHour,showMinute];
                
            } else {
                
                return [NSString stringWithFormat:@"前天%@:%@",showHour,showMinute];
            }
            
        } else {
            
            return [NSString stringWithFormat:@"%@月%@日 %@:%@",showMonth,showDay,showHour,showMinute];
        }
    }
    
    return timeStr;
}


+(NSString*)getDateFormatModuleBWithLong:(long long)timeLong;{
    
    if ([[NSString stringWithFormat:@"%lld",timeLong] length] > 10) {
        timeLong = timeLong / 1000;
    }
    NSString* timeStr = [NSDate getTimeStrWithLong:timeLong];
    NSString* timeDayStr = [timeStr substringToIndex:10];
    
    NSString* currentDayStr = [NSDate getTodayDate];
    NSString* tomorrowDayStr = [NSDate getTomorrowDay];
   
    NSString* showMonth = [[timeStr substringToIndex:7] substringFromIndex:5];
    NSString* showDay = [[timeStr substringToIndex:10] substringFromIndex:8];
    NSString* showHour = [[timeStr substringToIndex:13] substringFromIndex:11];
    NSString* showMinute = [[timeStr substringToIndex:16] substringFromIndex:14];
    
    if ([timeDayStr isEqualToString:currentDayStr]) {
        return [NSString stringWithFormat:@"今日 %@:%@",showHour,showMinute];
    } else if ([timeDayStr isEqualToString:tomorrowDayStr]) {
        return [NSString stringWithFormat:@"明日 %@:%@",showHour,showMinute];
    } else {
        return [NSString stringWithFormat:@"%@月%@日 %@:%@",showMonth,showDay,showHour,showMinute];
    }
    
    return timeStr;
}



@end
