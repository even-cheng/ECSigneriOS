//
//  optool.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/25.
//  Copyright © 2020 even_cheng. All rights reserved.
//
#import "optool.h"

extern"C" {
    int optool_do(NSArray* arguments);
    NSArray* checkAllDyLibs(NSString* targetPath);
    NSArray* checkAllDyLibsForExecutable(NSString* executablePath);
}
