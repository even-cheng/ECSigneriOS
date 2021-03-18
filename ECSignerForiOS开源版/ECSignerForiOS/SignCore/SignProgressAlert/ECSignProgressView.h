//
//  ECSignProgressView.h
//  ECSignerForiOS
//
//  Created by Even on 2020/9/11.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ECSignProgressView : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, copy) NSString *title;

@end

NS_ASSUME_NONNULL_END
