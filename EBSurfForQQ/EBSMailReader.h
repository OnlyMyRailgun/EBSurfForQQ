//
//  EBSMailReader.h
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

@interface EBSMailReader : Singleton
- (NSError *)establishMailConnectionWithEmailAddress:(NSString *)email password:(NSString *)pwd;
- (BOOL)getPassword;
- (void)disconnect;
@end
