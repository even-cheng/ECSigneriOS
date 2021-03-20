//
//  ECHttpsResponse.m
//  ECSignerForiOS
//
//  Created by Even on 2020/10/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECHttpsResponse.h"

@implementation ECHttpsResponse

- (NSInteger)status{
    return 301;
}

- (NSDictionary *)httpHeaders
{    
    return [NSDictionary dictionaryWithObjectsAndKeys:@"ecsignios://",@"Location",@"application/x-apple-aspen-config",@"contentType",@"UTF-8",@"charset", nil];
}


@end
