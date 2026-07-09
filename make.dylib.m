#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// =====================================================================
// ĐỊNH NGHĨA CỨNG TRÁNH LỖI BIÊN DỊCH GITHUB
// =====================================================================
#ifndef UIControlStateNormal
#define UIControlStateNormal 0
#endif
#ifndef UIControlEventTouchUpInside
#define UIControlEventTouchUpInside (1 << 6)
#endif

// Các phần tử giao diện tĩnh giữ trong bộ nhớ
static UIWindow *floatingButtonWindow = nil; 
static UIWindow *overlayMenuWindow = nil;    
static UIView *menuContainer = nil;
static WKWebView *menuWebView = nil;
static UIButton *floatingLogoBtn = nil;

// Nhãn hiển thị FPS thực tế
static UILabel *fpsLabel = nil;
static CADisplayLink *displayLink = nil;
static NSTimeInterval lastTimestamp = 0;
static NSInteger frameCount = 0;

// Trạng thái cấu hình lỏ
static BOOL isFpsEnabled = NO;
static NSString *savedSpeakerText = @"Chào sếp Đức Huy!";

@interface HuyMenuController : UIViewController <WKNavigationDelegate>
+ (void)toggleMenuGlobal;
+ (void)changeBorderColorWithHex:(NSString *)hexColor;
+ (void)updateFpsState:(BOOL)enabled;
+ (void)calculateFPS:(CADisplayLink *)link;
@end

// =====================================================================
// CƠ CHẾ XOÁ SẠCH DỮ LIỆU CÀI ĐẶT & THOÁT APP AN TOÀN
// =====================================================================
static void wipeDataAndExit() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"huy_saved_speaker_text"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"huy_saved_fps_state"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (displayLink) {
            [displayLink invalidate];
            displayLink = nil;
        }
        [overlayMenuWindow setHidden:YES];
        [floatingButtonWindow setHidden:YES];
        
        exit(0);
    });
}

// =====================================================================
// GIAO DIỆN WEB HTML SIÊU LỎ CYBERPUNK (ĐÚNG KIỂU BO TRÒN)
// =====================================================================
static NSString* getLooHTMLContent() {
    return @""
    "<!DOCTYPE html>"
    "<html>"
    "<head>"
    "  <meta charset='UTF-8'>"
    "  <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>"
    "  <style>"
    "    * { box-sizing: border-box; -webkit-user-select: none; user-select: none; }"
    "    body {"
    "      margin: 0; padding: 15px; font-family: -apple-system, BlinkMacSystemFont, sans-serif;"
    "      background: rgba(10, 13, 20, 0.96); color: #fff; border-radius: 20px;"
    "      height: 100vh; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between;"
    "    }"
    "    .header { text-align: center; border-bottom: 1px solid rgba(0,255,204,0.15); padding-bottom: 8px; }"
    "    .header h1 { margin: 0; font-size: 16px; color: #00ffcc; text-shadow: 0 0 8px rgba(0, 255, 204, 0.4); }"
    "    .row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; background: rgba(255,255,255,0.03); padding: 8px 12px; border-radius: 10px; }"
    "    .row span { font-size: 13px; }"
    "    .switch { position: relative; display: inline-block; width: 44px; height: 22px; }"
    "    .switch input { opacity: 0; width: 0; height: 0; }"
    "    .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #232733; border-radius: 22px; transition: .3s; }"
    "    .slider:before { position: absolute; content: ''; height: 16px; width: 16px; left: 3px; bottom: 3px; background-color: #fff; border-radius: 50%; transition: .3s; }"
    "    input:checked + .slider { background-color: #00ffcc; }"
    "    input:checked + .slider:before { transform: translateX(22px); }"
    "    .input-box { width: 100%; height: 35px; background: #070913; border: 1px solid #1f2d3d; border-radius: 8px; color: #fff; padding: 0 10px; font-size: 12px; outline: none; margin-bottom: 8px; }"
    "    .btn-blue { width: 100%; background: #00ffcc; color: #000; border: none; padding: 8px; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 12px; margin-bottom: 5px; }"
    "    .btn-red { width: 100%; background: linear-gradient(135deg, #ff0055, #990022); border: none; color: #fff; padding: 10px; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 12px; }"
    "    .select-color { background: #070913; border: 1px solid #1f2d3d; color: #fff; padding: 5px; border-radius: 5px; font-size: 12px; outline: none; }"
    "  </style>"
    "</head>"
    "<body>"
    "  <div class='header'>"
    "    <h1>WHITE HAT TWEAK LỎ</h1>"
    "    <p style='margin:2px 0 0 0; font-size:9px; color:#8a99ad;'>Giao Diện Web Độc Quyền Sếp Huy</p>"
    "  </div>"
    "  "
    "  <div>"
    "    <div class='row'>"
    "      <span>📈 Đồng hồ đo FPS thực tế</span>"
    "      <label class='switch'>"
    "        <input type='checkbox' id='fpsCheck' onchange='sendAction(\"toggleFps\", this.checked)'>"
    "        <span class='slider'></span>"
    "      </label>"
    "    </div>"
    "    "
    "    <div class='row'>"
    "      <span>🎨 Màu viền Neon</span>"
    "      <select class='select-color' onchange='sendAction(\"changeColor\", this.value)'>"
    "        <option value='#00ffcc'>Xanh Cyan</option>"
    "        <option value='#ff0055'>Đỏ Hồng</option>"
    "        <option value='#33ff00'>Xanh Lá</option>"
    "        <option value='#ffcc00'>Vàng Neon</option>"
    "      </select>"
    "    </div>"
    "    "
    "    <div style='background: rgba(255,255,255,0.02); padding: 10px; border-radius: 10px; margin-bottom: 10px; border: 1px solid rgba(255,255,255,0.05);'>"
    "      <span style='font-size: 11px; color:#8a99ad; display:block; margin-bottom:6px;'>🗣️ Loa phát giọng nói (Google TTS)</span>"
    "      <input type='text' class='input-box' id='speakText' placeholder='Nhập chữ muốn máy phát âm...' value='Chào sếp Đức Huy!'>"
    "      <button class='btn-blue' onclick='speakNow()'>PHÁT GIỌNG NÓI</button>"
    "    </div>"
    "  </div>"
    "  "
    "  <button class='btn-red' onclick='sendAction(\"wipeAndExit\", null)'>💥 ĐÓNG APP & XOÁ SẠCH DỮ LIỆU</button>"
    "  "
    "  <script>"
    "    function sendAction(action, value) {"
    "      window.webkit.messageHandlers.HuyLooBridge.postMessage({ 'action': action, 'value': value });"
    "    }"
    "    function speakNow() {"
    "      var txt = document.getElementById('speakText').value;"
    "      sendAction('speak', txt);"
    "    }"
    "    window.onload = function() {"
    "      sendAction('requestSync', null);"
    "    };"
    "    function syncWebState(fpsState, text) {"
    "      document.getElementById('fpsCheck').checked = fpsState;"
    "      document.getElementById('speakText').value = text;"
    "    }"
    "  </script>"
    "</body>"
    "</html>";
}

// =====================================================================
// CẦU NỐI WEB-TO-NATIVE TƯƠNG TÁC THỰC TẾ
// =====================================================================
@interface HuyLooBridgeHandler : NSObject <WKScriptMessageHandler>
@end

@implementation HuyLooBridgeHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"HuyLooBridge"]) {
        NSDictionary *dict = message.body;
        NSString *action = dict[@"action"];
        id value = dict[@"value"];
        
        if ([action isEqualToString:@"toggleFps"]) {
            isFpsEnabled = [value boolValue];
            [HuyMenuController updateFpsState:isFpsEnabled];
        } 
        else if ([action isEqualToString:@"changeColor"]) {
            [HuyMenuController changeBorderColorWithHex:(NSString *)value];
        } 
        else if ([action isEqualToString:@"speak"]) {
            savedSpeakerText = (NSString *)value;
            dispatch_async(dispatch_get_main_queue(), ^{
                AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:savedSpeakerText];
                utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"vi-VN"];
                utterance.rate = 0.5;
                AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
                [synthesizer speakUtterance:utterance];
            });
        } 
        else if ([action isEqualToString:@"wipeAndExit"]) {
            wipeDataAndExit();
        } 
        else if ([action isEqualToString:@"requestSync"]) {
            NSString *js = [NSString stringWithFormat:@"syncWebState(%d, '%@')", isFpsEnabled, savedSpeakerText];
            [menuWebView evaluateJavaScript:js completionHandler:nil];
        }
    }
}

@end

// =====================================================================
// CỬ SỔ TRONG SUỐT TOUCH PASSTHROUGH VẼ ĐÈ
// =====================================================================
@interface HuyPassthroughWindow : UIWindow
@end

@implementation HuyPassthroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (menuContainer && !menuContainer.hidden && menuContainer.alpha > 0) {
        CGPoint pointInContainer = [menuContainer convertPoint:point fromView:self];
        if ([menuContainer pointInside:pointInContainer withEvent:event]) {
            return hitView;
        }
    }
    return nil;
}

@end

// =====================================================================
// LỚP ĐIỀU KHIỂN GIAO DIỆN CHÍNH
// =====================================================================
@implementation HuyMenuController

- (void)viewDidLoad {
    [super XcodeHeader];
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 80, 25)];
    fpsLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    fpsLabel.textColor = [UIColor greenColor];
    fpsLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
    fpsLabel.textAlignment = NSTextAlignmentCenter;
    fpsLabel.layer.cornerRadius = 6;
    fpsLabel.layer.masksToBounds = YES;
    fpsLabel.layer.borderWidth = 1;
    fpsLabel.layer.borderColor = [UIColor greenColor].CGColor;
    fpsLabel.hidden = YES;
    [self.view addSubview:fpsLabel];
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 310, 410)];
    menuContainer.backgroundColor = [UIColor clearColor];
    menuContainer.layer.borderWidth = 2.0;
    menuContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
    menuContainer.layer.cornerRadius = 20;
    menuContainer.hidden = YES; 
    [self.view addSubview:menuContainer];
    
    UIPanGestureRecognizer *panDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuDrag:)];
    [menuContainer addGestureRecognizer:panDrag];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:[[HuyLooBridgeHandler alloc] init] name:@"HuyLooBridge"];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    menuWebView = [[WKWebView alloc] initWithFrame:menuContainer.bounds configuration:configuration];
    menuWebView.navigationDelegate = self;
    menuWebView.backgroundColor = [UIColor clearColor];
    menuWebView.scrollView.scrollEnabled = NO;
    menuWebView.scrollView.bounces = NO;
    menuWebView.layer.cornerRadius = 20;
    menuWebView.layer.masksToBounds = YES;
    [menuContainer addSubview:menuWebView];
    
    [menuWebView loadHTMLString:getLooHTMLContent() baseURL:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    menuContainer.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
}

- (void)handleMenuDrag:(UIPanGestureRecognizer *)gesture {
    CGPoint trans = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        menuContainer.center = CGPointMake(menuContainer.center.x + trans.x, menuContainer.center.y + trans.y);
        [gesture setTranslation:CGPointZero inView:self.view];
    }
}

+ (void)toggleMenuGlobal {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (menuContainer.hidden) {
            menuContainer.hidden = NO;
            menuContainer.transform = CGAffineTransformMakeScale(0.6, 0.6);
            menuContainer.alpha = 0.0;
            [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menuContainer.transform = CGAffineTransformIdentity;
                menuContainer.alpha = 1.0;
            } completion:nil];
            
            NSString *js = [NSString stringWithFormat:@"syncWebState(%d, '%@')", isFpsEnabled, savedSpeakerText];
            [menuWebView evaluateJavaScript:js completionHandler:nil];
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
                menuContainer.alpha = 0.0;
            } completion:^(BOOL finished) {
                menuContainer.hidden = YES;
            }];
        }
    });
}

+ (void)changeBorderColorWithHex:(NSString *)hexColor {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *cleanString = [hexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
        unsigned int baseValue;
        [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
        float red = ((baseValue >> 16) & 0xFF) / 255.0f;
        float green = ((baseValue >> 8) & 0xFF) / 255.0f;
        float blue = ((baseValue) & 0xFF) / 255.0f;
        
        UIColor *newColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        menuContainer.layer.borderColor = newColor.CGColor;
    });
}

+ (void)updateFpsState:(BOOL)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (enabled) {
            fpsLabel.hidden = NO;
            if (!displayLink) {
                lastTimestamp = 0;
                frameCount = 0;
                displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(calculateFPS:)];
                [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            }
        } else {
            fpsLabel.hidden = YES;
            if (displayLink) {
                [displayLink invalidate];
                displayLink = nil;
            }
        }
    });
}

+ (void)calculateFPS:(CADisplayLink *)link {
    if (lastTimestamp == 0) {
        lastTimestamp = link.timestamp;
        return;
    }
    frameCount++;
    NSTimeInterval delta = link.timestamp - lastTimestamp;
    if (delta >= 1.0) {
        double fps = frameCount / delta;
        fpsLabel.text = [NSString stringWithFormat:@"FPS: %.0f", fps];
        if (fps >= 55) {
            fpsLabel.textColor = [UIColor greenColor];
            fpsLabel.layer.borderColor = [UIColor greenColor].CGColor;
        } else if (fps >= 30) {
            fpsLabel.textColor = [UIColor orangeColor];
            fpsLabel.layer.borderColor = [UIColor orangeColor].CGColor;
        } else {
            fpsLabel.textColor = [UIColor redColor];
            fpsLabel.layer.borderColor = [UIColor redColor].CGColor;
        }
        frameCount = 0;
        lastTimestamp = link.timestamp;
    }
}

@end

// =====================================================================
// KHỞI CHẠY GIAO DIỆN & TẠO LOGO WHITE HAT DI ĐỘNG CHỐNG NUỐT CHẠM
// =====================================================================
@interface HuyMenuInitializer : NSObject
+ (void)tryInitializeUI;
@end

@implementation HuyMenuInitializer

+ (void)tryInitializeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
                    scene = (UIWindowScene *)s;
                    break;
                }
            }
            if (!scene) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [HuyMenuInitializer tryInitializeUI];
                });
                return;
            }
        }
        
        if (@available(iOS 13.0, *)) {
            floatingButtonWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            floatingButtonWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 180, 56, 56)];
        }
        floatingButtonWindow.frame = CGRectMake(20, 180, 56, 56);
        floatingButtonWindow.backgroundColor = [UIColor clearColor];
        floatingButtonWindow.windowLevel = UIWindowLevelAlert + 1001;
        
        UIViewController *btnRootVC = [[UIViewController alloc] init];
        btnRootVC.view.backgroundColor = [UIColor clearColor];
        floatingButtonWindow.rootViewController = btnRootVC;
        
        floatingLogoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingLogoBtn.frame = btnRootVC.view.bounds;
        floatingLogoBtn.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:0.9];
        floatingLogoBtn.layer.cornerRadius = 28;
        floatingLogoBtn.layer.borderWidth = 1.5;
        floatingLogoBtn.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
        [floatingLogoBtn setTitle:@"🕵️‍♂️" forState:UIControlStateNormal];
        floatingLogoBtn.titleLabel.font = [UIFont systemFontOfSize:28];
        
        floatingLogoBtn.layer.shadowColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
        floatingLogoBtn.layer.shadowOffset = CGSizeZero;
        floatingLogoBtn.layer.shadowRadius = 8;
        floatingLogoBtn.layer.shadowOpacity = 0.9;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFloatingPan:)];
        [floatingLogoBtn addGestureRecognizer:pan];
        
        [floatingLogoBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [btnRootVC.view addSubview:floatingLogoBtn];
        floatingButtonWindow.hidden = NO;

        if (@available(iOS 13.0, *)) {
            overlayMenuWindow = [[HuyPassthroughWindow alloc] initWithWindowScene:scene];
        } else {
            overlayMenuWindow = [[HuyPassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        overlayMenuWindow.frame = [UIScreen mainScreen].bounds;
        overlayMenuWindow.backgroundColor = [UIColor clearColor];
        overlayMenuWindow.windowLevel = UIWindowLevelAlert + 1000;
        
        HuyMenuController *controller = [[HuyMenuController alloc] init];
        overlayMenuWindow.rootViewController = controller;
        overlayMenuWindow.hidden = NO;
    });
}

+ (void)handleFloatingPan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        floatingButtonWindow.center = CGPointMake(floatingButtonWindow.center.x + translation.x, floatingButtonWindow.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:btn.superview];
    }
}

+ (void)toggleMenu {
    [HuyMenuController toggleMenuGlobal];
}

@end

// =====================================================================
// KHỞI CHẠY KHÔNG PHỤ THUỘC VÀO TRỄ THỜI GIAN LOAD APP
// =====================================================================
__attribute__((constructor)) static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([UIApplication sharedApplication].keyWindow || [[UIApplication sharedApplication] windows].count > 0) {
            [HuyMenuInitializer tryInitializeUI];
        }
#pragma clang diagnostic pop
    });
}

