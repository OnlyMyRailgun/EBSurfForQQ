//
//  EBSMainViewController.m
//  EBSurfForQQ
//
//  Created by Kissshot_Acerolaorion_Heartunderblade on 11/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBSMainViewController.h"
#import "ASIFormDataRequest.h"
#import "EBSMailReader.h"
#import "SEFilterControl.h"
#import "YLProgressBar.h"
#import "MAlertView.h"
#import "SimplePingHelper.h"
#import "Reachability.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import "EBSVersionCheck.h"

@interface EBSMainViewController ()
{
    SEFilterControl *filter;
    YLProgressBar *progressBar;
    SlideToCancelViewController *slideToCancel;
    id activeAlertView;
    UITextField *accountField;
    UITextField *passwdField;
    int loginCount;
    BOOL hasResendVPNPassword;
}
@end

@implementation EBSMainViewController
@synthesize appconsole;
@synthesize vpnUsername, vpnPassword, mailPassword, vpnPasswordDate, emailAddress;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        filter = [[SEFilterControl alloc]initWithFrame:CGRectMake(15, 70, 290, 70) Titles:[NSArray arrayWithObjects:@"检查网络", @"查询密码", @"登陆网关", @"登陆成功", nil]];
        filter.userInteractionEnabled = NO;
        [filter addTarget:self action:@selector(filterValueChanged:) forControlEvents:UIControlEventValueChanged];
        [filter setTitlesColor:[UIColor whiteColor]];
        [filter setProgressColor:[UIColor cyanColor]];
        [filter setTitlesFont:[UIFont fontWithName:@"Didot" size:16]];
        [self.view addSubview:filter];
        
        progressBar = [[YLProgressBar alloc] initWithFrame:CGRectMake(31, 104, 240, 12)];
        progressBar.progressTintColor = [UIColor cyanColor];
        progressBar.backgroundColor = [UIColor clearColor];
        [self.view addSubview:progressBar];
        
        loginCount = 0;
        hasResendVPNPassword = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    appconsole.text = @"";
    if (!slideToCancel) {
		// Create the slider
		slideToCancel = [[SlideToCancelViewController alloc] init];
		slideToCancel.delegate = self;
		
		// Position the slider off the bottom of the view, so we can slide it up
		CGRect sliderFrame = slideToCancel.view.frame;
		sliderFrame.origin.y = self.view.frame.size.height;
		slideToCancel.view.frame = sliderFrame;
		
		// Add slider to the view
		[self.view addSubview:slideToCancel.view];
	}
}

- (void)viewDidUnload
{
    [self setAppconsole:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startMyTask];
}

- (void)dealloc {
    [slideToCancel release];
    [filter release];
    [progressBar release];
    [appconsole release];
    [super dealloc];
}

- (void)startMyTask
{
    NSLog(@"startMyTask");
    if([self checkWifiStatus])
    {
        appconsole.text = [appconsole.text stringByAppendingFormat:@" WIFI可用\n 您正在使用的WIFI网络是%@", [self getSSIDName]];
        //[self pingGateway];
        EBSVersionCheck *versionCheck = [[EBSVersionCheck alloc] init];
        if([versionCheck checkVersion:self])
        {
            
        }
        else {
            [self pingGateway];
        }
        [versionCheck release];
    }
    else {
        if([[self getSSIDName] hasPrefix:@"EB-"])
        {
            [self pingGateway];
        }
        else {
            appconsole.text = [appconsole.text stringByAppendingString:@"\n WIFI不可用,请打开WIFI后重启EB畅游"];
        }
    }
}

- (void)checkUpdateAvailable
{
}

- (BOOL)checkWifiStatus
{
    if([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable)
    {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSString *)getSSIDName
{
    NSDictionary *ifs = [self.class fetchSSIDInfo];
    NSString *ssid = [[ifs objectForKey:@"SSID"] uppercaseString];
    return ssid;
}

+ (id)fetchSSIDInfo
{
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    //NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CNCopyCurrentNetworkInfo((CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
        [info release];
    }
    [ifs release];
    return [info autorelease];
}

- (void)pingGateway
{
    [SimplePingHelper ping:@"10.1.1.7" target:self sel:@selector(resultPingGateway:)];
}

- (void)pingBaidu
{
    if([self respondsToSelector:@selector(resultPingBaidu:)])
        [SimplePingHelper ping:@"220.181.37.55" target:self sel:@selector(resultPingBaidu:)];
    else {
        appconsole.text = [appconsole.text stringByAppendingString:@"\n pingBaidu: no response to resultPingBaidu"];
    }/*220.181.37.55*/
}

- (void)resultPingGateway:(NSNumber *)success 
{ 
    if(success.boolValue)
    {
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 网络环境检查完毕,开始获取密码"];
        [filter setSelectedIndex:EBSPGetPassword];
        //[self pingBaidu];
        //[self showActiveAlertView];
        [self fetchVPNPassword];
    }
    else {
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 经检查EB的网络不可达"];
    }
}

- (void)resultPingBaidu:(NSNumber *)success
{ 
    if(success.boolValue)
    {
        //登陆成功
        [filter setSelectedIndex:EBSPLoginSuccess];
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 登陆成功!现在可以退出EB畅游去上网了"];
    }
    else {
        //进入获取密码
            if(loginCount == 1)
            {    //登陆失败,需要更新密码
                appconsole.text = [appconsole.text stringByAppendingString:@"\n VPN密码失效,正在更新VPN密码..."];
                [NSThread detachNewThreadSelector:@selector(refetchVPNPasswordThroughMail:) toTarget:self withObject:[NSNumber numberWithBool:NO]];
            }
            else {
                //登陆失败,给出VPN密码和日期,询问是否要复制到剪切板
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                vpnPasswordDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"vpnDate"];
                NSString *strDate = [dateFormatter stringFromDate:vpnPasswordDate];
                [dateFormatter release];
                appconsole.text = [appconsole.text stringByAppendingFormat:@"\n 登陆失败,最新获取到的VPN密码是%@的邮件中的%@,您可以尝试移动滑块将密码复制到剪贴板手动登陆", strDate, vpnPassword];
                [self showSlideView];
            }
    }        
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)loadDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    @try {       
        vpnUsername = [userDefaults valueForKey:@"vpnUsername"];
        vpnPassword = [userDefaults valueForKey:@"vpnPassword"];
        mailPassword = [userDefaults valueForKey:@"emailPassword"];
        vpnPasswordDate = [userDefaults objectForKey:@"vpnDate"];
    }
    @catch (NSException *exception) {
        NSLog(@"load userInfo err:%@",exception);
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 本地用户信息读取错误，请填写后点击[登陆]按钮"];
        [self showActiveAlertView];
    }
}

- (void)fetchVPNPassword
{
    [filter setSelectedIndex:EBSPGetPassword];
    [self loadDefaults];
    if(vpnUsername && vpnPassword)
    {
        //读取到上次的密码，检验密码是否有效
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 读取到上次的密码，检验密码是否有效"];
        [self loginToEB];
    }
    else if(vpnUsername && mailPassword){
        //需要登陆到邮箱更新密码
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 未读取到本地vpn密码，正在自动获取"];
        [NSThread detachNewThreadSelector:@selector(refetchVPNPasswordThroughMail:) toTarget:self withObject:[NSNumber numberWithBool:NO]];
    }
    else {
        //用户输入邮箱地址和密码
        [self showActiveAlertView];
    }
}

- (void)getPasswordDidSuccess
{
    [self loadDefaults];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [formatter stringFromDate:vpnPasswordDate];
    [formatter release];
    [self logConsole:[NSString stringWithFormat:@"\n 成功获取到%@邮件中的VPN密码，开始登陆", stringFromDate]];
    [self loginToEB];
}

#pragma mark - refetchVPNPasswordThroughMail
- (void)refetchVPNPasswordThroughMail:(BOOL)needSleep
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if(needSleep)
        sleep(10);
    NSError *errorConnectToMailDidSuccess = [[EBSMailReader sharedInstance] establishMailConnectionWithEmailAddress:[NSString stringWithFormat:@"%@@ebupt.com", vpnUsername] password:mailPassword];
    if(errorConnectToMailDidSuccess == nil)
    {
        NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
        [self performSelectorOnMainThread:@selector(mailConnectDidSuccess) withObject:errorConnectToMailDidSuccess waitUntilDone:NO];
        [pool release];
        BOOL getPasswordDidSuccess = [[EBSMailReader sharedInstance] getPassword];
        if(getPasswordDidSuccess)
        {
            //获取密码成功
            NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
            [self performSelectorOnMainThread:@selector(getPasswordDidSuccess) withObject:nil waitUntilDone:NO];
            [pool release];

        }
        else {
            //近3周的邮件中没有找到包含VPN密码的邮件，是否请求服务器重新发送一封到邮箱中
            if(!hasResendVPNPassword)
            {
                [self showNoMailFoundAlert];
            }
            else {
                NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
                [self performSelectorOnMainThread:@selector(logConsole:) withObject:@"\n 新的VPN密码邮件尚未抵达,稍后将启动重试" waitUntilDone:NO];
                [pool release];
                [NSThread detachNewThreadSelector:@selector(refetchVPNPasswordThroughMail:) toTarget:self withObject:[NSNumber numberWithBool:YES]];
            }
        }
    }
    else {
        // connect to mail server error
        NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
        [self performSelectorOnMainThread:@selector(mailConnectDidFail:) withObject:errorConnectToMailDidSuccess waitUntilDone:NO];
        [pool release];
    }
    [[EBSMailReader sharedInstance] disconnect];
    [pool release];
}

- (void)showNoMailFoundAlert
{
    NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
    [self performSelectorOnMainThread:@selector(logConsole:) withObject:@"\n 获取VPN密码失败,您最近3周的邮件里没有找到包含VPN密码的邮件" waitUntilDone:NO];
    [pool release];
    
    UIAlertView *noMailFoundAlertView = [[[UIAlertView alloc] initWithTitle:@"未找到邮件"
                                                                    message:@"您最近3周的邮件里没有VPN密码邮件，是否向邮箱重新发一封包含VPN密码的邮件以便获取密码(如果您的pc上邮件客户端设置了[不在服务器保存副本]，请暂时关闭邮件客户端)" delegate:self cancelButtonTitle:@"不用了" otherButtonTitles:@"获取", nil] autorelease];
    if(![noMailFoundAlertView isVisible])
        [noMailFoundAlertView show];
}

- (void)mailConnectDidSuccess
{
    [self logConsole:@"\n 连接邮件服务器成功,开始查找邮件"];
}

- (void)mailConnectDidFail:(NSError *)error
{
    if([error.localizedDescription rangeOfString:@"Invalid username or password"].length > 0)
    {
        [self logConsole:[NSString stringWithFormat:@"\n 连接邮件服务器失败,失败原因:%@(用户名或者密码错误)", error.localizedDescription]];
        [self showActiveAlertView];
    }
    else {
        [self logConsole:[NSString stringWithFormat:@"\n 连接邮件服务器失败,失败原因:%@", error.localizedDescription]];
    }
}

- (void)logConsole:(NSString *)string
{
    appconsole.text = [appconsole.text stringByAppendingString:string];
}

#pragma mark - loginToEB
- (void)loginToEB
{
    [filter setSelectedIndex:EBSPLoginToEB];
    NSURL *ebLoginUrl = [NSURL URLWithString:@"http://10.1.1.7:8000/"];
    ASIFormDataRequest *formDataRequest = [ASIFormDataRequest requestWithURL:ebLoginUrl];
    [formDataRequest addPostValue:vpnUsername forKey:@"auth_user"];
    NSLog(@"%@",vpnPassword);
    [formDataRequest addPostValue:vpnPassword forKey:@"auth_pass"];
    [formDataRequest addPostValue:@"登录" forKey:@"accept"];
    [formDataRequest setDelegate:self];
    formDataRequest.tag = EBSPLoginToEB;
    loginCount++;
    [formDataRequest startAsynchronous];
}

#pragma mark - sendAnotherPassMail
- (void)sendAnotherPassMail
{
    NSURL *resendURL = [NSURL URLWithString:@"http://sendpass.ldap.ebupt.com/sendpass.php"];
    ASIFormDataRequest *formDataRequest = [ASIFormDataRequest requestWithURL:resendURL];
    [formDataRequest addPostValue:vpnUsername forKey:@"user"];
    [formDataRequest setDelegate:self];
    formDataRequest.tag = EBSPGetPassword;
    [formDataRequest startAsynchronous];
}

#pragma mark - ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request
{
    if(request.tag == EBSPLoginToEB)
    {
        if (request.delegate == nil) {
            appconsole.text = [appconsole.text stringByAppendingString:@"\n delegate == nil"];
        }
        if(request.delegate != nil && [request.delegate respondsToSelector:@selector(pingBaidu)])
            [request.delegate pingBaidu];
        else {
            appconsole.text = [appconsole.text stringByAppendingString:@"\n no pingBaidu"];
        }
    }
    else if (request.tag == EBSPGetPassword) {
        if([request.responseString rangeOfString:@"has been sent to your email account"].length > 0)
        {
            appconsole.text = [appconsole.text stringByAppendingString:@"\n 邮件发送成功,10秒后自动去邮箱中获取"];
            hasResendVPNPassword = YES;
            [NSThread detachNewThreadSelector:@selector(refetchVPNPasswordThroughMail:) toTarget:self withObject:[NSNumber numberWithBool:YES]];
        }
        else {
            appconsole.text = [appconsole.text stringByAppendingFormat:@"\n %@", request.responseString];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    if(request.tag == EBSPLoginToEB)
    {
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 向EB网关投递登陆请求时发生错误,正在重试"];
        [self loginToEB];
    }
    else if (request.tag == EBSPGetPassword) {
        appconsole.text = [appconsole.text stringByAppendingString:@"\n 向EB网关投递重发VPN密码邮件的请求发生错误"];
        [self sendAnotherPassMail];
    }
}

#pragma mark - Slide To Cancel
- (void)showSlideView
{
    // Start the slider animation
	slideToCancel.enabled = YES;
	
	// Slowly move up the slider from the bottom of the screen
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	CGPoint sliderCenter = slideToCancel.view.center;
	sliderCenter.y -= slideToCancel.view.bounds.size.height;
	slideToCancel.view.center = sliderCenter;
	[UIView commitAnimations];
    
    float height = appconsole.frame.size.height - slideToCancel.view.bounds.size.height;
    appconsole.frame =  CGRectMake(appconsole.frame.origin.x, appconsole.frame.origin.y, appconsole.frame.size.width, height);
    [appconsole scrollRangeToVisible:NSMakeRange(appconsole.text.length-1, 1)];
}

// SlideToCancelDelegate method is called when the slider is slid all the way
// to the right
- (void) cancelled {
	// Disable the slider and re-enable the button
    [self slideToPaste];
	slideToCancel.enabled = NO;
    
	// Slowly move down the slider off the bottom of the screen
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	CGPoint sliderCenter = slideToCancel.view.center;
	sliderCenter.y += slideToCancel.view.bounds.size.height;
	slideToCancel.view.center = sliderCenter;
	[UIView commitAnimations];
    
    float height = appconsole.frame.size.height + slideToCancel.view.bounds.size.height;
    appconsole.frame =  CGRectMake(appconsole.frame.origin.x, appconsole.frame.origin.y, appconsole.frame.size.width, height);
    
    appconsole.text = [appconsole.text stringByAppendingString:@"\n 复制成功,现在可以打开safari登陆了"];
}

- (void)slideToPaste
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = vpnPassword;
}

- (void)filterValueChanged:(SEFilterControl *) sender{
    //
    int selectedIndex = sender.SelectedIndex;
    if(selectedIndex == 0)
    {
        progressBar.progress = 0;
    }
    else {
        progressBar.progress = (0.33*selectedIndex) - 0.024f;
    }
}

- (void)initializeMailLoginAlertView
{
    UILabel *mail = [[UILabel alloc] init];
    mail.frame = CGRectMake(0, 0, 100, 20);
    mail.backgroundColor = [UIColor clearColor];
    mail.text = @"@ebupt.com";
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) {
        activeAlertView = [[UIAlertView alloc] initWithTitle:@"用户验证"
                                                     message:@"请输入您公司邮箱的用户名和密码" delegate:self
                                           cancelButtonTitle:nil otherButtonTitles:@"验证", nil];
        [activeAlertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        [activeAlertView textFieldAtIndex:0].rightView = mail;
        [activeAlertView textFieldAtIndex:0].placeholder = @"公司邮箱";
        [activeAlertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeASCIICapable;
        [activeAlertView textFieldAtIndex:0].rightViewMode = UITextFieldViewModeAlways;
        [activeAlertView textFieldAtIndex:1].placeholder = @"邮箱密码";
    }
    else {
        activeAlertView = [[MAlertView alloc] initWithTitle:@"用户验证"
                                                    message:@"请输入您公司邮箱的用户名和邮箱密码" delegate:self
                                          cancelButtonTitle:nil otherButtonTitles:@"验证", nil];
        accountField = [[UITextField alloc] init];
        [accountField setKeyboardType:UIKeyboardTypeASCIICapable];
        [accountField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [accountField setAutocorrectionType:UITextAutocorrectionTypeNo];
        accountField.rightView = mail;
        accountField.rightViewMode = UITextFieldViewModeAlways;
        accountField.keyboardType = UIKeyboardTypeEmailAddress;
        passwdField = [[UITextField alloc] init];
        [passwdField setSecureTextEntry:YES];
        
        [activeAlertView addTextField:accountField placeHolder:@"邮箱用户名"];
        [activeAlertView addTextField:passwdField placeHolder:@"邮箱密码"];
        
        [accountField release];
        [passwdField release];
    }
    [mail release];
}

- (void)showActiveAlertView
{
    if(activeAlertView == nil)
        [self initializeMailLoginAlertView];
    if(![activeAlertView isVisible])
        [activeAlertView show];
}

#pragma mark - alertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"验证"])
    {
        UITextField *textFieldName;
        UITextField *textFieldPassword;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) 
        {
            textFieldName = [alertView textFieldAtIndex:0];
            textFieldPassword = [alertView textFieldAtIndex:1];
        }
        else {
            textFieldName = accountField;
            textFieldPassword = passwdField;
        }
        
        if(textFieldName.text.length < 1)
        {
            UIAlertView *shortName = [[UIAlertView alloc] initWithTitle:@"信息错误" message:@"公司邮箱用户名不能为空" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [shortName show];
            [shortName release];
        }
        else if(textFieldPassword.text.length < 1)
        {
            UIAlertView *shortName = [[UIAlertView alloc] initWithTitle:@"信息错误" message:@"公司邮箱密码不能为空" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [shortName show];
            [shortName release];
        }
        else{
            //[self alertVerify:@"正在联网验证，请稍后..."];
            vpnUsername = textFieldName.text;
            mailPassword = textFieldPassword.text;
            [mailPassword retain];
            NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
            [accountDefaults setValue:vpnUsername forKey:@"vpnUsername"];
            [accountDefaults synchronize];
//            appconsole.text = [appconsole.text stringByAppendingString:@"\n 连接邮件服务器"];
            [NSThread detachNewThreadSelector:@selector(refetchVPNPasswordThroughMail:) toTarget:self withObject:[NSNumber numberWithBool:NO]];
        }
    }
    else if ([buttonTitle isEqualToString:@"确定"]) {
        [self showActiveAlertView];
    }
    else if ([buttonTitle isEqualToString:@"在线升级"]) {
        NSString *urlString = @"itms-services://?action=download-manifest&url=http://mi.ebupt.net:9002/mobile/EBSurf.plist";
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    }
    else if ([buttonTitle isEqualToString:@"获取"]) {
        [self sendAnotherPassMail];
    }
    else if ([buttonTitle isEqualToString:@"暂不升级"]){
        [self pingGateway];
    }
}
@end
