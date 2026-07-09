#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// === Chức năng mẫu ===
static BOOL isFeatureEnabled = NO;
static WKWebView *webView = nil;
static UIView *overlayView = nil;

// === HTML Dashboard nhúng sẵn ===
static NSString *dashboardHTML() {
    NSString *status = isFeatureEnabled ? @"🟢 Active" : @"🔴 Inactive";
    NSString *btnText = isFeatureEnabled ? @"Turn OFF" : @"Turn ON";
    NSString *btnAction = isFeatureEnabled ? @"stop" : @"start";
    
    return [NSString stringWithFormat:
    @"<!DOCTYPE html>"
    @"<html><head>"
    @"<meta name='viewport' content='width=device-width, initial-scale=1'>"
    @"<title>Dylib Control</title>"
    @"<style>"
    @"*{margin:0;padding:0;box-sizing:border-box}"
    @"body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;"
    @"background:linear-gradient(135deg,#667eea,#764ba2);"
    @"color:#fff;display:flex;align-items:center;justify-content:center;"
    @"min-height:100vh;padding:20px}"
    @".card{background:rgba(255,255,255,0.15);backdrop-filter:blur(20px);"
    @"border-radius:24px;padding:40px;width:100%%;max-width:400px;"
    @"text-align:center;border:1px solid rgba(255,255,255,0.2)}"
    @"h1{font-size:28px;margin-bottom:10px}"
    @".sub{font-size:14px;opacity:0.8;margin-bottom:30px}"
    @".status{padding:20px;border-radius:16px;font-size:22px;font-weight:600;"
    @"margin-bottom:25px;transition:0.3s}"
    @".on{background:rgba(46,204,113,0.3);border:2px solid #2ecc71}"
    @".off{background:rgba(231,76,60,0.3);border:2px solid #e74c3c}"
    @".btn{display:block;width:100%%;padding:16px;font-size:18px;"
    @"font-weight:600;border:none;border-radius:14px;cursor:pointer;"
    @"transition:0.3s;margin-bottom:12px}"
    @".btn-on{background:#2ecc71;color:#fff}"
    @".btn-off{background:#e74c3c;color:#fff}"
    @".btn-close{background:rgba(255,255,255,0.1);color:#fff;border:1px solid rgba(255,255,255,0.3)}"
    @".btn:hover{transform:translateY(-2px);opacity:0.9}"
    @".info{font-size:12px;margin-top:20px;opacity:0.5}"
    @"</style>"
    @"</head><body>"
    @"<div class='card'>"
    @"<h1>🎛 Dylib Controller</h1>"
    @"<div class='sub'>Injected &amp; Running</div>"
    @"<div class='status %@' id='status'>%@</div>"
    @"<button class='btn btn-on' onclick='toggle(\"start\")' id='btnStart'>Turn ON</button>"
    @"<button class='btn btn-off' onclick='toggle(\"stop\")' id='btnStop' style='display:none'>Turn OFF</button>"
    @"<button class='btn btn-close' onclick='closePanel()'>Close Panel</button>"
    @"<div class='info'>Device: %@ | iOS: %@</div>"
    @"</div>"
    @"<script>"
    @"function toggle(action){"
    @"window.location.href='dylib://'+action;"
    @"}"
    @"function closePanel(){"
    @"window.location.href='dylib://close';"
    @"}"
    @"</script>"
    @"</body></html>",
    isFeatureEnabled ? @"on" : @"off",
    status,
    [[UIDevice currentDevice] name],
    [[UIDevice currentDevice] systemVersion]];
}

// === Xử lý navigation từ WebView ===
@interface DylibWebViewNavDelegate : NSObject <WKNavigationDelegate>
@end

@implementation DylibWebViewNavDelegate

- (void)webView:(WKWebView *)webView 
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction 
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURL *url = navigationAction.request.URL;
    
    if ([url.scheme isEqualToString:@"dylib"]) {
        if ([url.host isEqualToString:@"start"]) {
            isFeatureEnabled = YES;
            NSLog(@"[Dylib] Feature ENABLED ✅");
            [webView loadHTMLString:dashboardHTML() baseURL:nil];
        } else if ([url.host isEqualToString:@"stop"]) {
            isFeatureEnabled = NO;
            NSLog(@"[Dylib] Feature DISABLED ❌");
            [webView loadHTMLString:dashboardHTML() baseURL:nil];
        } else if ([url.host isEqualToString:@"close"]) {
            [UIView animateWithDuration:0.3 animations:^{
                overlayView.alpha = 0;
            } completion:^(BOOL finished) {
                [overlayView removeFromSuperview];
                overlayView = nil;
                webView = nil;
            }];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end

// === Hook UIApplication để hiển thị WebView ===
%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Gọi original
    BOOL result = %orig;
    
    // Hiển thị dashboard sau 0.5s
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), 
                   dispatch_get_main_queue(), ^{
        [self showDylibDashboard];
    });
    
    return result;
}

%end

// === Hook UIViewController để show dashboard trên mọi app ===
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // Chỉ show 1 lần
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), 
                       dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] showDylibDashboard];
        });
    });
}

%end

// === Category để show dashboard ===
@interface UIApplication (DylibControl)
- (void)showDylibDashboard;
@end

@implementation UIApplication (DylibControl)

- (void)showDylibDashboard {
    if (overlayView) return;
    
    // Lấy window chính
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    if (!keyWindow) return;
    
    // Tạo overlay
    overlayView = [[UIView alloc] initWithFrame:keyWindow.bounds];
    overlayView.backgroundColor = [UIColor clearColor];
    
    // WKWebView configuration
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:overlayView.bounds configuration:config];
    webView.navigationDelegate = [[DylibWebViewNavDelegate alloc] init];
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.scrollView.bounces = NO;
    
    [webView loadHTMLString:dashboardHTML() baseURL:nil];
    
    [overlayView addSubview:webView];
    [keyWindow addSubview:overlayView];
    
    // Animation fade in
    overlayView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        overlayView.alpha = 1;
    }];
}

@end
