//
//  ECHttpsConnection.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/18.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECHttpsConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import <UIKit/UIKit.h>
#import "ECHttpsResponse.h"

@implementation ECHttpsConnection

#pragma mark - get & post

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    // Add support for POST
    if ([method isEqualToString:@"POST"])
    {
        if ([path isEqualToString:@"/udid"])
        {
            // Let's be extra cautious, and make sure the upload isn't 5 gigs
            return YES;
        }
    }
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    // Inform HTTP server that we expect a body to accompany a POST request
    if([method isEqualToString:@"POST"]) return YES;
    
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([request.url.path isEqualToString:@"/udid"]) {
        NSString* raw = [[NSString alloc]initWithData:request.body encoding:NSISOLatin1StringEncoding];
        NSString* plistString = [raw substringWithRange:NSMakeRange([raw rangeOfString:@"<?xml"].location, [raw rangeOfString:@"</plist>"].location + [raw rangeOfString:@"</plist>"].length)];
        
        NSDictionary* plist = [NSPropertyListSerialization propertyListWithData:[plistString dataUsingEncoding:NSISOLatin1StringEncoding] options:NSPropertyListImmutable format:nil error:nil];
        NSString* imei = plist[@"IMEI"];
        NSString* udid = plist[@"UDID"];
        [[NSUserDefaults standardUserDefaults] setObject:udid forKey:@"ecsigner_udid"];
        [[NSUserDefaults standardUserDefaults] setObject:imei forKey:@"ecsigner_imei"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        return [[ECHttpsResponse alloc] initWithPath:@"ecsignios://"];
    }
    
    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    
    // If we supported large uploads,
    // we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
    
    // Remember: In order to support LARGE POST uploads, the data is read in chunks.
    // This prevents a 50 MB upload from being stored in RAM.
    // The size of the chunks are limited by the POST_CHUNKSIZE definition.
    // Therefore, this method may be called multiple times for the same POST request.
    
    BOOL result = [request appendData:postDataChunk];
    if (!result)
    {
        NSLog(@"Couldn't append bytes!");
    }
}


//- (NSData *)preprocessResponse:(HTTPMessage *)response{
//
//    if ([request.url.path isEqualToString:@"udid"]) {
//        NSString* raw = [[NSString alloc]initWithData:request.body encoding:NSISOLatin1StringEncoding];
//        NSString* plistString = [raw substringWithRange:NSMakeRange([raw rangeOfString:@"<?xml"].location, [raw rangeOfString:@"</plist>"].location + [raw rangeOfString:@"</plist>"].length)];
//
//        NSDictionary* plist = [NSPropertyListSerialization propertyListWithData:[plistString dataUsingEncoding:NSISOLatin1StringEncoding] options:NSPropertyListImmutable format:nil error:nil];
//        NSString* imei = plist[@"IMEI"];
//        NSString* udid = plist[@"UDID"];
//
//        [response initResponseWithStatusCode:301 description:nil version:nil];
//        return response;
//    }
//}


#pragma mark - 私有方法

//获取上行参数
- (NSDictionary *)getRequestParam:(NSData *)rawData
{
    if (!rawData) return nil;
    
    NSString *raw = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    NSArray *array = [raw componentsSeparatedByString:@"&"];
    for (NSString *string in array) {
        NSArray *arr = [string componentsSeparatedByString:@"="];
        NSString *value = [arr.lastObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [paramDic setValue:value forKey:arr.firstObject];
    }
    return [paramDic copy];
}

@end
