//
//  EBSMailReader.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBSMailReader.h"
#import <MailCore/MailCore.h>

#define MAILSERVERURL @"imap.exmail.qq.com"
#define MAILSERVERPORT 143
#define VPNSENDER @"master@ldap.ebupt.com"

@interface EBSMailReader ()
{
    CTCoreAccount *account;
}
@end

@implementation EBSMailReader
- (id)init
{
    if(self = [super init])
    {
        account = [[CTCoreAccount alloc] init];
    }
    return self;
}

- (void)dealloc
{    
    [account release];
    account = nil;
    [super dealloc];
}

- (NSError *)establishMailConnectionWithEmailAddress:(NSString *)email password:(NSString *)pwd
{    
    BOOL success = [account connectToServer:MAILSERVERURL
                                       port:MAILSERVERPORT
                             connectionType:CTConnectionTypePlain
                                   authType:CTImapAuthTypePlain
                                      login:email
                                   password:pwd];
    if (!success) {
        // Display the error contained in account.lastError
        NSLog(@"%@", account.lastError);
        return account.lastError;
    }
    else {
        NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
        [accountDefaults setValue:email forKey:@"emailAddress"];
        [accountDefaults setValue:pwd forKey:@"emailPassword"];
        [accountDefaults synchronize];
    }
    return nil;
}

- (BOOL)getPassword
{
    BOOL success = NO;
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];
    NSUInteger messageCount;
    [inbox totalMessageCount:&messageCount];
    NSArray *messages = [[NSArray alloc] initWithArray:[inbox messagesFromSequenceNumber:1 to:0 withFetchAttributes:CTFetchAttrEnvelope]];
    for(int i = messageCount; i > 0; i--)
    {
        CTCoreMessage *msg = [messages objectAtIndex:(i-1)];
        NSString *subject = msg.subject;
        int day = msg.senderDate.timeIntervalSince1970/60/60/24;
        int currentDay = [[NSDate date] timeIntervalSince1970]/60/60/24;
        if((currentDay - day) > 21)
            break;
        if([subject rangeOfString:@"VPN"].length>0 && [subject rangeOfString:@"PASSWORD"].length>0)
        {
            NSString *vpnPassword = nil;
            NSString *mailBody = msg.body;
            
            int start = 0;
            NSString *token = @"PASSWORD for this week: ";
            
            if([mailBody rangeOfString:@"Your password: "].length > 0)
            {
                start = [mailBody rangeOfString:@"Your password: "].location + 15;
            }
            else if([mailBody rangeOfString:token].length > 0)
            {
                
                start = [mailBody rangeOfString:token].location + token.length;
            }
            if(start != 0)
                vpnPassword = [mailBody substringWithRange:NSMakeRange(start, 8)];
            
            if(vpnPassword != nil)
            {
                success = YES;
                NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
                [accountDefaults setValue:vpnPassword forKey:@"vpnPassword"];
                [accountDefaults setObject:msg.senderDate forKey:@"vpnDate"];
                [accountDefaults synchronize];
                break;
            }
        }
    }
    return success;
}

- (void)disconnect
{
    [account disconnect];
}
@end
