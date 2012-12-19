//
//  EBSMailReader.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBSMailReader.h"
#import <MailCore/MailCore.h>
#include <sys/stat.h>

#define MAILSERVERURL @"imap.exmail.qq.com"
#define MAILSERVERPORT 143
#define VPNSENDER @"master@ldap.ebupt.com"

@interface EBSMailReader ()
{
    CTCoreAccount *account;
}
@property (nonatomic, strong) NSString *mailBodyFromLib;
@end

@implementation EBSMailReader
@synthesize mailBodyFromLib = _mailBodyFromLib;
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

static void check_error(int r, char * msg)
{
	if (r == MAILIMAP_NO_ERROR)
		return;
    if (r == MAILIMAP_NO_ERROR_AUTHENTICATED)
		return;
    if (r == MAILIMAP_NO_ERROR_NON_AUTHENTICATED)
		return;
    
	fprintf(stderr, "%s\n", msg);
	exit(EXIT_FAILURE);
}

static char * get_msg_att_msg_content(struct mailimap_msg_att * msg_att, size_t * p_msg_size)
{
	clistiter * cur;
    
    /* iterate on each result of one given message */
	for(cur = clist_begin(msg_att->att_list) ; cur != NULL ; cur = clist_next(cur)) {
		struct mailimap_msg_att_item * item;
        
		item = clist_content(cur);
		if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
			continue;
		}
        
        if (item->att_data.att_static->att_type != MAILIMAP_MSG_ATT_BODY_SECTION) {
			continue;
        }
        
		* p_msg_size = item->att_data.att_static->att_data.att_body_section->sec_length;
		return item->att_data.att_static->att_data.att_body_section->sec_body_part;
	}
    
	return NULL;
}

static char * get_msg_content(clist * fetch_result, size_t * p_msg_size)
{
	clistiter * cur;
    
    /* for each message (there will be probably only on message) */
	for(cur = clist_begin(fetch_result) ; cur != NULL ; cur = clist_next(cur)) {
		struct mailimap_msg_att * msg_att;
		size_t msg_size;
		char * msg_content;
        
		msg_att = clist_content(cur);
		msg_content = get_msg_att_msg_content(msg_att, &msg_size);
		if (msg_content == NULL) {
			continue;
		}
        
		* p_msg_size = msg_size;
		return msg_content;
	}
    
	return NULL;
}

static void fetch_msg(struct mailimap * imap, uint32_t uid, char *msg_content)
{
	struct mailimap_set * set;
	struct mailimap_section * section;
	size_t msg_len;
	//char * msg_content;
	struct mailimap_fetch_type * fetch_type;
	struct mailimap_fetch_att * fetch_att;
	int r;
	clist * fetch_result;
    
	set = mailimap_set_new_single(uid);
	fetch_type = mailimap_fetch_type_new_fetch_att_list_empty();
	section = mailimap_section_new(NULL);
	fetch_att = mailimap_fetch_att_new_body_peek_section(section);
	mailimap_fetch_type_new_fetch_att_list_add(fetch_type, fetch_att);
    
	r = mailimap_uid_fetch(imap, set, fetch_type, &fetch_result);
	check_error(r, "could not fetch");
	printf("fetch %u\n", (unsigned int) uid);
//    msg_content = malloc(512*sizeof(char));
    char *msgtmp = get_msg_content(fetch_result, &msg_len);
    NSLog(@"%zd", msg_len);
    strcpy(msg_content, msgtmp);
//    NSLog(@"%@", [NSString stringWithCString:msg_content encoding:NSUTF8StringEncoding]);
	if (msg_content == NULL) {
		fprintf(stderr, "no content\n");
		mailimap_fetch_list_free(fetch_result);
		return;
	}
	printf("%u has been fetched\n", (unsigned int) uid);
    
	mailimap_fetch_list_free(fetch_result);
    NSLog(@"%@", [NSString stringWithCString:msg_content encoding:NSUTF8StringEncoding]);
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
        NSLog(@"%@", subject);
        
        if([subject rangeOfString:@"VPN" options:NSCaseInsensitiveSearch].length>0 && [subject rangeOfString:@"Password" options:NSCaseInsensitiveSearch].length>0)
        {
            NSString *vpnPassword = nil;
            NSString *mailBody = msg.body;
            if([mailBody isEqualToString:@""])
            {
                char * msg_content = (char *)malloc(1024*sizeof(char));
                fetch_msg([msg imapSession], msg.uid, msg_content);
                NSLog(@"%s", msg_content);
                mailBody = [NSString stringWithCString:msg_content encoding:NSUTF8StringEncoding];
                free(msg_content);
                msg_content = NULL;
            }
            int start = 0;
            NSString *token0 = @"Your password: ";
            NSString *token = @"PASSWORD for this week: ";
            if([mailBody rangeOfString:token0 options:NSCaseInsensitiveSearch].length > 0)
            {
                start = [mailBody rangeOfString:token0 options:NSCaseInsensitiveSearch].location + 15;
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
            }
            break;
        }
    }
    return success;
}

- (void)disconnect
{
    [account disconnect];
}
@end
