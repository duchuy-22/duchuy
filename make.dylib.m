#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// =====================================================================
// DYLIB CÓ GIAO DIỆN WEB NHÚNG SẴN - GIỐNG FFDARKSWORD
// =====================================================================

@interface ModMenuVC : UIViewController <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation ModMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Tạo WebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"toggle"];
    [contentController addScriptMessageHandler:self name:@"fov"];
    [contentController addScriptMessageHandler:self name:@"aimTarget"];
    [contentController addScriptMessageHandler:self name:@"keyCheck"];
    [contentController addScriptMessageHandler:self name:@"closeApp"];
    config.userContentController = contentController;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    self.webView.layer.cornerRadius = 16;
    self.webView.layer.borderWidth = 2;
    self.webView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.webView.navigationDelegate = self;
    
    // Load HTML nhúng sẵn
    [self.webView loadHTMLString:[self getHTML] baseURL:nil];
    [self.view addSubview:self.webView];
}

- (NSString *)getHTML {
    return @"<!DOCTYPE html>"
    "<html><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'>"
    "<style>"
    "*{margin:0;padding:0;box-sizing:border-box;}"
    "body{background:#0a0a0f;color:#fff;font-family:'Segoe UI',sans-serif;padding:15px;}"
    ".header{text-align:center;border-bottom:1px solid #ff6a00;padding-bottom:10px;margin-bottom:15px;}"
    ".header h1{color:#ff6a00;font-size:20px;}"
    ".tab{display:flex;gap:5px;margin-bottom:15px;}"
    ".tab button{flex:1;padding:8px;background:#1a1a2e;border:1px solid #333;border-radius:6px;color:#aaa;font-size:12px;cursor:pointer;}"
    ".tab button.active{background:#ff6a00;color:#fff;border-color:#ff6a00;}"
    ".section{display:none;}.section.active{display:block;}"
    ".toggle-row{display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid #1a1a2e;}"
    ".toggle-row label{font-size:13px;color:#ddd;}"
    ".switch{position:relative;width:44px;height:24px;background:#333;border-radius:12px;cursor:pointer;transition:0.3s;}"
    ".switch.on{background:#ff6a00;}"
    ".switch:after{content:'';position:absolute;top:2px;left:2px;width:20px;height:20px;background:#fff;border-radius:50%;transition:0.3s;}"
    ".switch.on:after{left:22px;}"
    ".key-section{text-align:center;padding:10px 0;}"
    ".key-section input{width:80%;padding:10px;background:#1a1a2e;border:1px solid #333;border-radius:8px;color:#fff;text-align:center;font-size:14px;}"
    ".key-section button{margin-top:10px;padding:10px 30px;background:#ff6a00;border:none;border-radius:8px;color:#fff;font-size:14px;cursor:pointer;}"
    ".info{text-align:center;margin-top:15px;font-size:11px;color:#666;}"
    ".close-btn{padding:10px 30px;background:#e74c3c;border:none;border-radius:8px;color:#fff;font-size:14px;cursor:pointer;width:100%;margin-top:10px;}"
    "</style>"
    "</head><body>"
    "<div class='header'><h1>⚡ FF MOD</h1></div>"
    "<div class='tab'><button class='active' onclick='showTab(0)'>ESP</button><button onclick='showTab(1)'>Aimbot</button><button onclick='showTab(2)'>Settings</button></div>"
    "<div id='tab0' class='section active'>"
    "<div class='toggle-row'><label>ESP</label><div class='switch on' onclick='toggleSwitch(this,\"esp\")'></div></div>"
    "<div class='toggle-row'><label>Box</label><div class='switch on' onclick='toggleSwitch(this,\"box\")'></div></div>"
    "<div class='toggle-row'><label>Line</label><div class='switch on' onclick='toggleSwitch(this,\"line\")'></div></div>"
    "</div>"
    "<div id='tab1' class='section'>"
    "<div class='toggle-row'><label>Aimbot</label><div class='switch' onclick='toggleSwitch(this,\"aimbot\")'></div></div>"
    "<div class='toggle-row'><label>FOV Size: <span id='fovVal'>150</span></label><input type='range' min='30' max='300' value='150' oninput='updateFov(this.value)'></div>"
    "</div>"
    "<div id='tab2' class='section'>"
    "<div class='key-section'><input type='text' id='keyInput' placeholder='🔑 Key...'><br><button onclick='checkKey()'>KÍCH HOẠT</button><div id='keyStatus'>Chưa kích hoạt</div></div>"
    "<button class='close-btn' onclick='closeApp()'>🔴 ĐÓNG</button>"
    "</div>"
    "<script>"
    "function showTab(i){document.querySelectorAll('.section').forEach(el=>el.classList.remove('active'));document.getElementById('tab'+i).classList.add('active');document.querySelectorAll('.tab button').forEach((el,idx)=>{el.classList.toggle('active',idx===i);});}"
    "function toggleSwitch(el,name){el.classList.toggle('on');var value=el.classList.contains('on')?1:0;window.webkit.messageHandlers.toggle.postMessage({name:name,value:value});}"
    "function updateFov(v){document.getElementById('fovVal').innerText=v;window.webkit.messageHandlers.fov.postMessage({value:parseFloat(v)});}"
    "function checkKey(){var key=document.getElementById('keyInput').value;window.webkit.messageHandlers.keyCheck.postMessage({key:key});}"
    "function closeApp(){window.webkit.messageHandlers.closeApp.postMessage({});}"
    "function receiveFromDylib(msg){console.log(msg);if(msg.type==='keyStatus'){document.getElementById('keyStatus').innerText=msg.text;}}"
    "</script>"
    "</body></html>";
}

// ====== NHẬN LỆNH TỪ WEB ======
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *data = message.body;
    if ([message.name isEqualToString:@"toggle"]) {
        NSString *name = data[@"name"];
        int value = [data[@"value"] intValue];
        NSLog(@"🔄 %@ = %d", name, value);
    } else if ([message.name isEqualToString:@"fov"]) {
        NSLog(@"📏 FOV = %@", data[@"value"]);
    } else if ([message.name isEqualToString:@"keyCheck"]) {
        NSLog(@"🔑 Key: %@", data[@"key"]);
    } else if ([message.name isEqualToString:@"closeApp"]) {
        exit(0);
    }
}

@end

// =====================================================================
// CONSTRUCTOR - TỰ CHẠY KHI DYLIB LOAD
// =====================================================================
__attribute__((constructor)) static void init() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.windowLevel = UIWindowLevelNormal + 1000;
        window.backgroundColor = [UIColor clearColor];
        window.rootViewController = [[ModMenuVC alloc] init];
        window.hidden = NO;
    });
}
