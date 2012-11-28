//
//  Singleton.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Singleton.h"

@implementation Singleton

static Singleton *sharedSingleton_ = nil;
+ (id) sharedInstance 
{
    if (sharedSingleton_ == nil) 
    {
        sharedSingleton_ = [NSAllocateObject([self class], 0, NULL) init];
    }
    return sharedSingleton_; 
}

+ (id) allocWithZone:(NSZone *)zone 
{
    return [[self sharedInstance] retain]; 
}

- (id) copyWithZone:(NSZone*)zone 
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount 
{
    return NSUIntegerMax; // denotes an object that cannot be released 
}

- (oneway void) release {
    // do nothing
}

- (id) autorelease {
    return self;
}
@end
