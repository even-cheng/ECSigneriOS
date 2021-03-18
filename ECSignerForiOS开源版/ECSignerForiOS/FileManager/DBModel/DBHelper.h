//
//  DBHelper.h
//  JTime
//
//  Created by Even on 16/12/12.
//  Copyright © 2016年 Cube. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface DBHelper : NSObject

@property (nonatomic, retain,readonly) FMDatabaseQueue *dbQueue;

+ (DBHelper *)shareInstance;

+ (NSString *)dbPath;

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName;

@end
