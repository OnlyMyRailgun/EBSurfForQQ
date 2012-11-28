//
//  EBSMainViewController.h
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequestDelegate.h"
#import "UINavigationBar+CustomBackground.h"
#import "SlideToCancelViewController.h"

typedef enum{
    EBSPCheckNetwork = 0,
    EBSPGetPassword,
    EBSPLoginToEB,
    EBSPLoginSuccess,
}EBSurfPhase;

@interface EBSMainViewController : UIViewController<UIAlertViewDelegate, ASIHTTPRequestDelegate, SlideToCancelDelegate>

@property (retain, nonatomic) NSString *vpnUsername;
@property (retain, nonatomic) NSString *vpnPassword;
@property (retain, nonatomic) NSString *mailPassword;
@property (retain, nonatomic) NSString *emailAddress;
@property (retain, nonatomic) NSDate *vpnPasswordDate;

@property (retain, nonatomic) IBOutlet UITextView *appconsole;

@end
