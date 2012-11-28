//
//  EBSVersionCheck.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBSVersionCheck.h"
#import "ASIHTTPRequest.h"
#import "EBSMainViewController.h"

@implementation EBSVersionCheck
- (BOOL)checkVersion:(EBSMainViewController *)delegate
{
    BOOL updateAvailable = NO;
    NSURL *url = [NSURL URLWithString:@"http://mi.ebupt.net:9002/mobile/ebsurf_version_ios.php"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous];
    NSString *versionInfo = request.responseString;
    NSLog(@"%@", versionInfo);
    NSString *version;
    NSString *versionMessage;
    if([versionInfo rangeOfString:@"<br/>"].length > 0)
    {
        NSArray *versionInfoArray = [versionInfo componentsSeparatedByString:@"<br/>"];
        version = [versionInfoArray objectAtIndex:0];
        versionMessage = [versionInfoArray objectAtIndex:1];
    }else {
        version = versionInfo;
        versionMessage = @"当前有新版本可用，请下载更新";
    }
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSLog(@"%@, current:%@",version, currentVersion);
    if([version floatValue] > [currentVersion floatValue])
    {
        updateAvailable = YES;
        UIAlertView *updateVersionAlert = [[UIAlertView alloc] initWithTitle:@"版本更新" message:versionMessage delegate:delegate cancelButtonTitle:@"暂不升级" otherButtonTitles:@"在线升级", nil];
        [updateVersionAlert show];
        [updateVersionAlert release];
    }
    return updateAvailable;
}
@end
