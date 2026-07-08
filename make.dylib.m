#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// =====================================================================
// ĐỊNH NGHĨA CỨNG CÁC ĐỊNH DANH ĐỂ TRÁNH LỖI PHÂN GIẢI TRÊN MÁY ẢO GITHUB
// =====================================================================
#ifndef UIControlStateNormal
#define UIControlStateNormal 0
#endif
#ifndef UIControlStateSelected
#define UIControlStateSelected 4
#endif
#ifndef UIControlEventTouchUpInside
#define UIControlEventTouchUpInside (1 << 6)
#endif

// =====================================================================
// BIẾN TRẠNG THÁI TOÀN CỤC CHẠY NGẦM LIÊN TỤC
// =====================================================================
static BOOL isAimbotActive = NO;
static BOOL isEspActive = NO;
static float aimbotFovRadius = 120.0f;
static BOOL showFovCircle = YES;
static float cameraFov = 60.0f;
static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;

// Đối tượng cửa sổ bảo vệ
static UIWindow *floatingButtonWindow = nil; 
static UIWindow *overlayMenuWindow = nil;    
static UIView *menuContainer = nil;
static WKWebView *menuWebView = nil;
static CAShapeLayer *fovCircleLayer = nil;
static UIButton *floatingLogoBtn = nil;

// Forward Declarations
@interface HuyMenuController : UIViewController <WKNavigationDelegate>
+ (void)drawFovCircleOnScreen;
+ (void)openMenuWithAnimation;
+ (void)toggleMenuGlobal;
@end

// =====================================================================
// CHỨC NĂNG HUỶ DIỆT TOÀN BỘ DỮ LIỆU & ĐÓNG APP SẠCH SẼ
// =====================================================================
static void wipeAllDataAndExitApp() {
    // 1. Quét sạch phân vùng bộ nhớ cài đặt lưu tạm (NSUserDefaults)
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 2. Xoá Keychain và tệp lưu trữ tạm thời trong thư mục ứng dụng
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        NSString *cachePath = paths[0];
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    }
    
    // 3. Giải phóng hoàn toàn bộ nhớ đồ họa dylib
    [overlayMenuWindow setHidden:YES];
    [floatingButtonWindow setHidden:YES];
    
    // 4. Gọi lệnh hệ thống tắt ứng dụng lập tức (Văng app an toàn)
    exit(0);
}

// =====================================================================
// GIAO DIỆN WEB HTML CAO CẤP TỰ CHỨA - KHÔNG CẦN FILE MAIN.HTML NGOÀI
// =====================================================================
static NSString* getMenuHTMLContent() {
    return @""
    "<!DOCTYPE html>"
    "<html>"
    "<head>"
    "  <meta charset='UTF-8'>"
    "  <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>"
    "  <style>"
    "    * { box-sizing: border-box; -webkit-user-select: none; user-select: none; }"
    "    body {"
    "      margin: 0; padding: 15px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
    "      background: rgba(10, 12, 18, 0.95); color: #fff; border-radius: 20px;"
    "      border: 2px solid #00f0ff; box-shadow: 0 0 20px rgba(0, 240, 255, 0.3);"
    "      height: 100vh; overflow: hidden;"
    "    }"
    "    .header { text-align: center; margin-bottom: 20px; border-bottom: 1px solid rgba(0,240,255,0.2); padding-bottom: 10px; }"
    "    .header h1 { margin: 0; font-size: 18px; color: #00f0ff; text-shadow: 0 0 10px rgba(0, 240, 255, 0.5); }"
    "    .header p { margin: 5px 0 0 0; font-size: 10px; color: #8a99ad; }"
    "    .row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; background: rgba(255,255,255,0.03); padding: 8px 12px; border-radius: 10px; border: 1px solid rgba(255,255,255,0.05); }"
    "    .row span { font-size: 13px; font-weight: 500; }"
    "    /* Custom Switch style */"
    "    .switch { position: relative; display: inline-block; width: 44px; height: 22px; }"
    "    .switch input { opacity: 0; width: 0; height: 0; }"
    "    .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #2a2f3d; border-radius: 22px; transition: .3s; border: 1px solid rgba(255,255,255,0.1); }"
    "    .slider:before { position: absolute; content: ''; height: 16px; width: 16px; left: 2px; bottom: 2px; background-color: #fff; border-radius: 50%; transition: .3s; }"
    "    input:checked + .slider { background-color: #00f0ff; box-shadow: 0 0 10px rgba(0,240,255,0.4); }"
    "    input:checked + .slider:before { transform: translateX(22px); }"
    "    /* Slider FOV style */"
    "    .slider-container { display: flex; flex-direction: column; width: 100%; gap: 8px; background: rgba(255,255,255,0.03); padding: 8px 12px; border-radius: 10px; border: 1px solid rgba(255,255,255,0.05); margin-bottom: 15px; }"
    "    .slider-title { display: flex; justify-content: space-between; font-size: 12px; color: #8a99ad; }"
    "    .range-input { -webkit-appearance: none; width: 100%; height: 5px; background: #2a2f3d; border-radius: 3px; outline: none; }"
    "    .range-input::-webkit-slider-thumb { -webkit-appearance: none; width: 14px; height: 16px; background: #00f0ff; border-radius: 3px; cursor: pointer; box-shadow: 0 0 8px #00f0ff; }"
    "    /* Action Buttons */"
    "    .btn-wipe { width: 100%; background: linear-gradient(135deg, #ff0055, #990022); border: none; color: #fff; padding: 12px; border-radius: 10px; font-weight: bold; cursor: pointer; margin-top: 10px; box-shadow: 0 4px 15px rgba(255,0,85,0.2); transition: 0.2s; font-size: 12px; }"
    "    .btn-wipe:active { transform: scale(0.98); }"
    "  </style>"
    "</head>"
    "<body>"
    "  <div class='header'>"
    "    <h1>WHITE HAT WEB MENU</h1>"
    "    <p>Premium Real-time Web Tweak by Dong Duc Huy</p>"
    "  </div>"
    "  "
    "  <div class='row'>"
    "    <span>🎯 Khóa mục tiêu (Aimbot)</span>"
    "    <label class='switch'>"
    "      <input type='checkbox' id='aimbot' onchange='toggleAction(\"setAimbot\", this.checked)'>"
    "      <span class='slider'></span>"
    "    </label>"
    "  </div>"
    "  "
    "  <div class='row'>"
    "    <span>👁️ Vẽ định vị (ESP)</span>"
    "    <label class='switch'>"
    "      <input type='checkbox' id='esp' onchange='toggleAction(\"setEsp\", this.checked)'>"
    "      <span class='slider'></span>"
    "    </label>"
    "  </div>"
    "  "
    "  <div class='row'>"
    "    <span>❤️ Bất tử máu (God Mode)</span>"
    "    <label class='switch'>"
    "      <input type='checkbox' id='godmode' onchange='toggleAction(\"setGodMode\", this.checked)'>"
    "      <span class='slider'></span>"
    "    </label>"
    "  </div>"
    "  "
    "  <div class='row'>"
    "    <span>⚡ Chạy siêu tốc (High Speed)</span>"
    "    <label class='switch'>"
    "      <input type='checkbox' id='highspeed' onchange='toggleAction(\"setHighSpeed\", this.checked)'>"
    "      <span class='slider'></span>"
    "    </label>"
    "  </div>"
    "  "
    "  <div class='slider-container'>"
    "    <div class='slider-title'>"
    "      <span>Bán kính vòng ngắm (FOV)</span>"
    "      <span id='fovVal'>120px</span>"
    "    </div>"
    "    <input type='range' min='30' max='300' value='120' class='range-input' id='fovRange' oninput='sliderAction(\"setFov\", this.value)'>"
    "  </div>"
    "  "
    "  <button class='btn-wipe' onclick='sendNativeAction(\"wipeAndExit\")'>💥 ĐÓNG APP & XOÁ SẠCH DỮ LIỆU</button>"
    "  "
    "  <script>"
    "    function sendNativeAction(action) {"
    "      window.webkit.messageHandlers.HuyBridge.postMessage({ 'action': action });"
    "    }"
    "    function toggleAction(action, value) {"
    "      window.webkit.messageHandlers.HuyBridge.postMessage({ 'action': action, 'value': value });"
    "    }"
    "    function sliderAction(action, value) {"
    "      document.getElementById('fovVal').innerText = value + 'px';"
    "      window.webkit.messageHandlers.HuyBridge.postMessage({ 'action': action, 'value': parseFloat(value) });"
    "    }"
    "    window.onload = function() {"
    "      window.webkit.messageHandlers.HuyBridge.postMessage({ 'action': 'requestSync' });"
    "    };"
    "    function syncWebState(aim, esp, god, speed, fov) {"
    "      document.getElementById('aimbot').checked = aim;"
    "      document.getElementById('esp').checked = esp;"
    "      document.getElementById('godmode').checked = god;"
    "      document.getElementById('highspeed').checked = speed;"
    "      document.getElementById('fovRange').value = fov;"
    "      document.getElementById('fovVal').innerText = fov + 'px';"
    "    }"
    "  </script>"
    "</body>"
    "</html>";
}

// =====================================================================
// LỚP CỬA SỔ TRONG SUỐT CHẠM XUYÊN THẤU (TOUCH PASSTHROUGH)
// =====================================================================
@interface HuyPassthroughWindow : UIWindow
@end

@implementation HuyPassthroughWindow

// Chạm xuyên thấu: Chỉ nhận sự kiện chạm nếu bấm trúng vùng điều khiển menu
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
// CẦU NỐI XỬ LÝ SỰ KIỆN TỪ WEB SANG NATIVE (WKScriptMessageHandler)
// =====================================================================
@interface HuyWebBridgeHandler : NSObject <WKScriptMessageHandler>
@end

@implementation HuyWebBridgeHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"HuyBridge"]) {
        NSDictionary *dict = message.body;
        NSString *action = dict[@"action"];
        id value = dict[@"value"];
        
        if ([action isEqualToString:@"setAimbot"]) {
            isAimbotActive = [value boolValue];
            [HuyMenuController drawFovCircleOnScreen];
        } else if ([action isEqualToString:@"setEsp"]) {
            isEspActive = [value boolValue];
        } else if ([action isEqualToString:@"setGodMode"]) {
            isGodMode = [value boolValue];
        } else if ([action isEqualToString:@"setHighSpeed"]) {
            isHighSpeed = [value boolValue];
        } else if ([action isEqualToString:@"setFov"]) {
            aimbotFovRadius = [value floatValue];
            [HuyMenuController drawFovCircleOnScreen];
        } else if ([action isEqualToString:@"wipeAndExit"]) {
            wipeAllDataAndExitApp();
        } else if ([action isEqualToString:@"requestSync"]) {
            NSString *js = [NSString stringWithFormat:@"syncWebState(%d, %d, %d, %d, %f)", 
                            isAimbotActive, isEspActive, isGodMode, isHighSpeed, aimbotFovRadius];
            [menuWebView evaluateJavaScript:js completionHandler:nil];
        }
    }
}

@end

// =====================================================================
// LỚP ĐIỀU KHIỂN GIAO DIỆN CHÍNH
// =====================================================================
@implementation HuyMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Khung viền bo tròn chứa Menu Web
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 350, 460)];
    menuContainer.backgroundColor = [UIColor clearColor];
    menuContainer.hidden = YES; 
    [self.view addSubview:menuContainer];
    
    // Kéo thả Menu
    UIPanGestureRecognizer *panDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuDrag:)];
    [menuContainer addGestureRecognizer:panDrag];
    
    // Thiết lập cầu nối sự kiện Web Bridge
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:[[HuyWebBridgeHandler alloc] init] name:@"HuyBridge"];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    
    // Khởi tạo trình duyệt WebView tích hợp
    menuWebView = [[WKWebView alloc] initWithFrame:menuContainer.bounds configuration:configuration];
    menuWebView.navigationDelegate = self;
    menuWebView.backgroundColor = [UIColor clearColor];
    menuWebView.scrollView.scrollEnabled = NO;
    menuWebView.scrollView.bounces = NO;
    menuWebView.layer.cornerRadius = 20;
    menuWebView.layer.masksToBounds = YES;
    [menuContainer addSubview:menuWebView];
    
    // Load mã HTML trực tiếp từ bộ nhớ dylib
    [menuWebView loadHTMLString:getMenuHTMLContent() baseURL:nil];
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

+ (void)openMenuWithAnimation {
    menuContainer.hidden = NO;
    menuContainer.transform = CGAffineTransformMakeScale(0.6, 0.6);
    menuContainer.alpha = 0.0;
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
        menuContainer.alpha = 1.0;
    } completion:nil];
}

+ (void)toggleMenuGlobal {
    if (menuContainer.hidden) {
        [HuyMenuController openMenuWithAnimation];
        [HuyMenuController drawFovCircleOnScreen];
        
        NSString *js = [NSString stringWithFormat:@"syncWebState(%d, %d, %d, %d, %f)", 
                        isAimbotActive, isEspActive, isGodMode, isHighSpeed, aimbotFovRadius];
        [menuWebView evaluateJavaScript:js completionHandler:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
            menuContainer.alpha = 0.0;
        } completion:^(BOOL finished) {
            menuContainer.hidden = YES;
        }];
    }
}

+ (void)drawFovCircleOnScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fovCircleLayer) {
            [fovCircleLayer removeFromSuperlayer];
            fovCircleLayer = nil;
        }
        
        if (!overlayMenuWindow || !showFovCircle || !isAimbotActive) return;
        
        CGPoint center = overlayMenuWindow.center;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:aimbotFovRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
        
        fovCircleLayer = [CAShapeLayer layer];
        fovCircleLayer.path = path.CGPath;
        fovCircleLayer.fillColor = [UIColor clearColor].CGColor;
        fovCircleLayer.strokeColor = [UIColor colorWithRed:0.0 green:0.94 blue:1.0 alpha:1.0].CGColor; 
        fovCircleLayer.lineWidth = 1.2f;
        fovCircleLayer.opacity = 0.7f;
        
        [overlayMenuWindow.layer addSublayer:fovCircleLayer];
    });
}

@end

// =====================================================================
// KHỞI CHẠY GIAO DIỆN & TẠO LOGO WHITE HAT CHỐNG NUỐT CẢM ỨNG
// =====================================================================
@interface HuyMenuInitializer : NSObject
+ (void)tryInitializeUI;
@end

@implementation HuyMenuInitializer

+ (void)tryInitializeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        
        if (@available(iOS 13.0, *)) {
            scene = getActiveWindowScene();
            if (!scene) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [HuyMenuInitializer tryInitializeUI];
                });
                return;
            }
        }
        
        // 1. TẠO CỬ SỔ LOGO WHITE HAT DI ĐỘNG KÉO THẢ
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
        floatingLogoBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        floatingLogoBtn.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:0.9];
        floatingLogoBtn.layer.cornerRadius = 28;
        floatingLogoBtn.layer.borderWidth = 1.5;
        floatingLogoBtn.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor; 
        
        [floatingLogoBtn setTitle:@"🕵️‍♂️" forState:UIControlStateNormal];
        floatingLogoBtn.titleLabel.font = [UIFont systemFontOfSize:28];
        
        floatingLogoBtn.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
        floatingLogoBtn.layer.shadowOffset = CGSizeZero;
        floatingLogoBtn.layer.shadowRadius = 8;
        floatingLogoBtn.layer.shadowOpacity = 0.9;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFloatingPan:)];
        [floatingLogoBtn addGestureRecognizer:pan];
        
        [floatingLogoBtn addTarget:self action:@selector(toggleHuyMenuViaLogo) forControlEvents:UIControlEventTouchUpInside];
        [btnRootVC.view addSubview:floatingLogoBtn];
        floatingButtonWindow.hidden = NO;

        // 2. TẠO CỬ SỔ TRONG SUỐT HOẠT ĐỘNG 24/24 CHỨA MENU WEB & FOV
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

+ (void)toggleHuyMenuViaLogo {
    [HuyMenuController toggleMenuGlobal];
}

@end

// Khởi chạy dylib tự động khi được tải vào app
__attribute__((constructor)) static void initialize() {
    if ([UIApplication sharedApplication].keyWindow || [[UIApplication sharedApplication] windows].count > 0) {
        [HuyMenuInitializer tryInitializeUI];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [HuyMenuInitializer tryInitializeUI];
        }];
    }
}

