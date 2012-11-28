//
//  UINavigationBar+CustomBackground.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UINavigationBar+CustomBackground.h"

@implementation UINavigationBar (CustomBackground)

- (UIImage *)barBackground
{
    return [UIImage imageNamed:@"titlebar_bg"];
}

- (void)didMoveToSuperview
{
    //iOS5 only
    if ([self respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
    {
        [self setBackgroundImage:[self barBackground] forBarMetrics:UIBarMetricsDefault];
    }
}

//this doesn't work on iOS5 but is needed for iOS4 and earlier
- (void)drawRect:(CGRect)rect
{
    //draw image
    [[self barBackground] drawInRect:rect];
}

@end
