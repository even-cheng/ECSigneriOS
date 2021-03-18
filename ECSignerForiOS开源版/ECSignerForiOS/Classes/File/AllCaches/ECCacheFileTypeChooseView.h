//
//  ECCacheFileTypeChooseView.h
//  ECSignerForiOS
//
//  Created by 快游 on 2020/11/6.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ECCacheFileTypeCertificate,
    ECCacheFileTypeProfile,
    ECCacheFileTypeLibs,
    ECCacheFileTypeOriginalPackages,
    ECCacheFileTypeResignedPackages,
    ECCacheFileTypeZipFile,
    ECCacheFileTypeDownloadFile,
    ECCacheFileTypeP8File,
    ECCacheFileTypeInstall,
} ECCacheFileType;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ECCacheFileTypeChooseBlock)(ECCacheFileType chooseType);
@interface ECCacheFileTypeChooseView : UIView

@property (nonatomic, copy) ECCacheFileTypeChooseBlock chooseBlock;
@property (nonatomic, strong) NSArray *fileTypes;

@end

NS_ASSUME_NONNULL_END
