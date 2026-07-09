#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// =====================================================================
// OFFSET FF - MÀY ĐIỀN OFFSET THẬT VÀO ĐÂY
// =====================================================================
#define OFFSET_MAINPLAYER          0x10F4F4
#define OFFSET_ENEMYPLAYER         0x10F4F8
#define OFFSET_HEALTH              0xF8
#define OFFSET_ARMOR               0xFC
#define OFFSET_POS_X               0x34
#define OFFSET_POS_Y               0x38
#define OFFSET_POS_Z               0x3C
#define OFFSET_MOUSE_X             0x40
#define OFFSET_MOUSE_Y             0x44
#define OFFSET_GOD_MODE            0x29D1F
#define OFFSET_IS_VISIBLE          0x11b1254
#define OFFSET_GET_HP              0x1207cbc
#define OFFSET_GET_MAX_HP          0x1207dfc
#define OFFSET_GET_NAME            0x11a18e0
#define OFFSET_IS_MOVING           0x11a13c
#define OFFSET_IS_FIRING           0x11a1844
#define OFFSET_IS_TEAMMATE         0x11bfe4
#define OFFSET_IS_DEAD             0x11a11e8
#define OFFSET_GET_POSITION        0x61b5e1c
#define OFFSET_GET_TRANSFORM       0x510212c
#define OFFSET_GET_ROTATION        0x61b6124
#define OFFSET_GET_AIM_ROTATION    0x11a1d82
#define OFFSET_GET_ATTACK_CENTER   0x11a1f7c
#define OFFSET_GET_HEAD_TF         0x12a0990
#define OFFSET_GET_SPEED_SCALE     0x17f7314
#define OFFSET_FAST_MEDKIT         0x17a104
#define OFFSET_SCREEN_WIDTH        0x5e43f6e
#define OFFSET_SCREEN_HEIGHT       0x5e43f6e
#define OFFSET_GET_ACTIVE_WEAPON   0x11b6f98
#define OFFSET_GHOST_HACK          0x2262f18
#define OFFSET_BYPASS              0x3ab11ec

// =====================================================================
// FIREBASE
// =====================================================================
static NSString *const FIREBASE_DB_URL = @"https://duchuy-99a4f-default-rtdb.firebaseio.com";
static NSString *const APP_ID = @"ff_v1";

// =====================================================================
// BIẾN TOÀN CỤC
// =====================================================================
static BOOL isKeyValidated = NO;
static NSString *currentUser = @"";
static NSTimeInterval expirationTime = 0;
static NSTimer *countdownTimer = nil;

static BOOL isEspEnabled = YES;
static BOOL isBoxEnabled = YES;
static BOOL isLineEnabled = YES;
static BOOL isSkeletonEnabled = YES;
static BOOL isNameEnabled = YES;
static BOOL isHealthEnabled = YES;
static BOOL isAimbotEnabled = NO;
static BOOL isFovCircleEnabled = YES;
static BOOL isAlwaysAim = NO;
static BOOL isAimThroughWall = NO;
static int aimTarget = 2;
static float fovSize = 150.0f;
static BOOL isGhostEnabled = NO;
static BOOL isBypassEnabled = NO;
static BOOL isGodMode = NO;
static BOOL isSpeedHack = NO;

static UIWindow *overlayWindow = nil;
static WKWebView *webView = nil;
static UIView *espCanvas = nil;
static CAShapeLayer *fovCircle = nil;
static NSMutableArray *espLayers = nil;
static CADisplayLink *displayLink = nil;

// =====================================================================
// STRUCT
// =====================================================================
typedef struct {
    int health;
    int armor;
    float x, y, z;
    float mouseX, mouseY;
    char name[64];
    bool isVisible;
    bool isDead;
    bool isTeammate;
} PlayerInfo;

// =====================================================================
// HÀM ĐỌC/GHI MEMORY
// =====================================================================
static uintptr_t getFFBaseAddress(void) {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

static float readFloatFF(uintptr_t address) {
    if (address == 0) return 0;
    float *ptr = (float *)address;
    return *ptr;
}

static int readIntFF(uintptr_t address) {
    if (address == 0) return 0;
    int *ptr = (int *)address;
    return *ptr;
}

static bool readBoolFF(uintptr_t address) {
    if (address == 0) return false;
    bool *ptr = (bool *)address;
    return *ptr;
}

static void writeFloatFF(uintptr_t address, float value) {
    if (address == 0) return;
    float *ptr = (float *)address;
    *ptr = value;
}

static void writeIntFF(uintptr_t address, int value) {
    if (address == 0) return;
    int *ptr = (int *)address;
    *ptr = value;
}

// =====================================================================
// LẤY PLAYER INFO
// =====================================================================
static PlayerInfo getMainPlayerInfo(void) {
    PlayerInfo info = {0};
    uintptr_t playerAddr = getFFBaseAddress() + OFFSET_MAINPLAYER;
    info.health = readIntFF(playerAddr + OFFSET_HEALTH);
    info.armor = readIntFF(playerAddr + OFFSET_ARMOR);
    info.x = readFloatFF(playerAddr + OFFSET_POS_X);
    info.y = readFloatFF(playerAddr + OFFSET_POS_Y);
    info.z = readFloatFF(playerAddr + OFFSET_POS_Z);
    info.mouseX = readFloatFF(playerAddr + OFFSET_MOUSE_X);
    info.mouseY = readFloatFF(playerAddr + OFFSET_MOUSE_Y);
    return info;
}

static PlayerInfo getEnemyInfo(uintptr_t enemyAddr) {
    PlayerInfo info = {0};
    info.health = readIntFF(enemyAddr + OFFSET_HEALTH);
    info.x = readFloatFF(enemyAddr + OFFSET_POS_X);
    info.y = readFloatFF(enemyAddr + OFFSET_POS_Y);
    info.z = readFloatFF(enemyAddr + OFFSET_POS_Z);
    info.isDead = readBoolFF(enemyAddr + OFFSET_IS_DEAD);
    info.isTeammate = readBoolFF(enemyAddr + OFFSET_IS_TEAMMATE);
    info.isVisible = readBoolFF(enemyAddr + OFFSET_IS_VISIBLE);
    return info;
}

static void getAllEnemies(PlayerInfo *enemies, int *count) {
    *count = 0;
    uintptr_t enemyBase = getFFBaseAddress() + OFFSET_ENEMYPLAYER;
    
    for (int i = 4; i <= 128; i += 4) {
        uintptr_t addr = enemyBase + i;
        PlayerInfo enemy = getEnemyInfo(addr);
        if (enemy.health > 0 && enemy.health <= 100 && enemy.x != 0 && !enemy.isDead && !enemy.isTeammate) {
            enemies[*count] = enemy;
            (*count)++;
            if (*count >= 31) break;
        }
    }
}

static float calcDistance3D(PlayerInfo from, PlayerInfo to) {
    float dx = to.x - from.x;
    float dy = to.y - from.y;
    float dz = to.z - from.z;
    return sqrtf(dx*dx + dy*dy + dz*dz);
}

static PlayerInfo findClosestEnemy(PlayerInfo source) {
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    
    if (count == 0) {
        PlayerInfo empty = {0};
        return empty;
    }
    
    PlayerInfo closest = enemies[0];
    float minDist = calcDistance3D(source, closest);
    
    for (int i = 1; i < count; i++) {
        float dist = calcDistance3D(source, enemies[i]);
        if (dist < minDist) {
            minDist = dist;
            closest = enemies[i];
        }
    }
    return closest;
}

static CGPoint worldToScreen(float x, float y, float z, CGSize screenSize) {
    // Cần camera matrix cho chính xác
    return CGPointMake(x + 100, y + 100);
}

// =====================================================================
// HACK FUNCTIONS
// =====================================================================
static void doAimbot(PlayerInfo source, PlayerInfo target) {
    if (target.health <= 0) return;
    if (!isAimThroughWall && !target.isVisible) return;
    
    float dist = calcDistance3D(source, target);
    if (dist < 0.1f || dist > fovSize) return;
    
    float pitch = asinf((target.z - source.z) / dist) * 180.0f / M_PI;
    float yaw = -atan2f((target.x - source.x), (target.y - source.y)) * 180.0f / M_PI + 180.0f;
    
    uintptr_t playerAddr = getFFBaseAddress() + OFFSET_MAINPLAYER;
    writeFloatFF(playerAddr + OFFSET_MOUSE_X, yaw);
    writeFloatFF(playerAddr + OFFSET_MOUSE_Y, pitch);
}

static void doGodMode(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_GOD_MODE;
    if (enable) {
        uint32_t nop = 2341507216;
        writeIntFF(addr, nop);
    }
}

static void doGhostHack(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_GHOST_HACK;
    if (enable) {
        uint32_t ghostOn[] = {0xE3A00000, 0xE12FFF1E};
        writeIntFF(addr, ghostOn[0]);
        writeIntFF(addr + 4, ghostOn[1]);
    } else {
        uint32_t ghostOff[] = {0xE92D4FF0, 0xE28DB01C};
        writeIntFF(addr, ghostOff[0]);
        writeIntFF(addr + 4, ghostOff[1]);
    }
}

static void doBypass(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_BYPASS;
    if (enable) {
        uint32_t retBytes[] = {0xE3A00001, 0xE12FFF1E};
        writeIntFF(addr, retBytes[0]);
        writeIntFF(addr + 4, retBytes[1]);
    }
}

// =====================================================================
// GỬI TIN LÊN WEB
// =====================================================================
static void sendToWeb(NSString *jsonString) {
    if (webView) {
        NSString *js = [NSString stringWithFormat:@"receiveFromDylib(%@);", jsonString];
        dispatch_async(dispatch_get_main_queue(), ^{
            [webView evaluateJavaScript:js completionHandler:nil];
        });
    }
}

static void updateWebSwitch(NSString *name, BOOL value) {
    NSDictionary *msg = @{
        @"type": @"updateSwitch",
        @"name": name,
        @"value": @(value)
    };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        sendToWeb(jsonString);
    }
}

static void updateTimeRemaining() {
    if (isKeyValidated) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval remaining = expirationTime - now;
        if (remaining <= 0) {
            isKeyValidated = NO;
            [countdownTimer invalidate];
            countdownTimer = nil;
            NSDictionary *msg = @{
                @"type": @"keyStatus",
                @"text": @"⏰ Key đã hết hạn!"
            };
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:&error];
            if (!error) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                sendToWeb(jsonString);
            }
            return;
        }
        
        int days = (int)(remaining / 86400);
        int hours = (int)((remaining - days * 86400) / 3600);
        int minutes = (int)((remaining - days * 86400 - hours * 3600) / 60);
        int seconds = (int)(remaining - days * 86400 - hours * 3600 - minutes * 60);
        
        NSDictionary *msg = @{
            @"type": @"updateTime",
            @"days": @(days),
            @"hours": @(hours),
            @"minutes": @(minutes),
            @"seconds": @(seconds),
            @"user": currentUser
        };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            sendToWeb(jsonString);
        }
    }
}

// =====================================================================
// VIEW CONTROLLER - LOAD HTML TỪ FILE
// =====================================================================
@interface OverlayViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler>
@end

@implementation OverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    espLayers = [NSMutableArray array];
    
    // ESP Canvas
    espCanvas = [[UIView alloc] initWithFrame:self.view.bounds];
    espCanvas.backgroundColor = [UIColor clearColor];
    espCanvas.userInteractionEnabled = NO;
    espCanvas.tag = 999;
    [self.view addSubview:espCanvas];
    
    // WebView Menu
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"toggle"];
    [contentController addScriptMessageHandler:self name:@"fov"];
    [contentController addScriptMessageHandler:self name:@"aimTarget"];
    [contentController addScriptMessageHandler:self name:@"keyCheck"];
    [contentController addScriptMessageHandler:self name:@"closeApp"];
    [contentController addScriptMessageHandler:self name:@"init"];
    config.userContentController = contentController;
    
    webView = [[WKWebView alloc] initWithFrame:CGRectMake(20, 50, self.view.bounds.size.width - 40, self.view.bounds.size.height - 100) configuration:config];
    webView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    webView.layer.cornerRadius = 16;
    webView.layer.borderWidth = 2;
    webView.layer.borderColor = [UIColor orangeColor].CGColor;
    webView.hidden = YES;
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    
    // LOAD HTML TỪ FILE (menu.html)
    [self loadHTMLFromFile];
    
    // Menu Button
    UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.frame = CGRectMake(10, 50, 50, 50);
    menuBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9];
    menuBtn.layer.cornerRadius = 25;
    [menuBtn setTitle:@"⚡" forState:UIControlStateNormal];
    [menuBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuBtn];
    
    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(self.view.bounds.size.width - 60, 50, 50, 50);
    closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    closeBtn.layer.cornerRadius = 25;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
    // FOV Circle
    fovCircle = [CAShapeLayer layer];
    fovCircle.fillColor = [UIColor clearColor].CGColor;
    fovCircle.strokeColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:0.5].CGColor;
    fovCircle.lineWidth = 1.5;
    [self.view.layer addSublayer:fovCircle];
    
    // Timer cập nhật thời gian mỗi giây
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    // CADisplayLink - Vẽ ESP 25fps
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop)];
    displayLink.preferredFramesPerSecond = 25;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // Load key đã lưu
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"saved_key"];
    if (savedKey) {
        [self checkKey:savedKey];
    }
}

- (void)updateTime {
    updateTimeRemaining();
}

// ====== LOAD HTML TỪ FILE ======
- (void)loadHTMLFromFile {
    // Thử load từ bundle
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"menu" ofType:@"html"];
    if (htmlPath) {
        NSURL *url = [NSURL fileURLWithPath:htmlPath];
        [webView loadFileURL:url allowingReadAccessToURL:url];
        NSLog(@"✅ Loaded menu.html from bundle");
        return;
    }
    
    // Load từ Documents
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    htmlPath = [docPath stringByAppendingPathComponent:@"menu.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:htmlPath]) {
        NSURL *url = [NSURL fileURLWithPath:htmlPath];
        [webView loadFileURL:url allowingReadAccessToURL:url];
        NSLog(@"✅ Loaded menu.html from Documents");
        return;
    }
    
    NSLog(@"❌ menu.html not found!");
}

// ====== WEBVIEW DELEGATE ======
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self sendAllStatesToWeb];
}

- (void)sendAllStatesToWeb {
    NSDictionary *states = @{
        @"esp": @(isEspEnabled),
        @"box": @(isBoxEnabled),
        @"line": @(isLineEnabled),
        @"skeleton": @(isSkeletonEnabled),
        @"name": @(isNameEnabled),
        @"health": @(isHealthEnabled),
        @"aimbot": @(isAimbotEnabled),
        @"fovcircle": @(isFovCircleEnabled),
        @"wall": @(isAimThroughWall),
        @"always": @(isAlwaysAim),
        @"ghost": @(isGhostEnabled),
        @"god": @(isGodMode),
        @"speed": @(isSpeedHack),
        @"bypass": @(isBypassEnabled)
    };
    
    NSDictionary *msg = @{@"type": @"init", @"data": states};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        sendToWeb(jsonString);
    }
}

// ====== WEBVIEW MESSAGE HANDLER ======
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *data = message.body;
    
    if ([message.name isEqualToString:@"toggle"]) {
        NSString *name = data[@"name"];
        int value = [data[@"value"] intValue];
        BOOL boolValue = (value == 1);
        
        if ([name isEqualToString:@"esp"]) { isEspEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"box"]) { isBoxEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"line"]) { isLineEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"skeleton"]) { isSkeletonEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"name"]) { isNameEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"health"]) { isHealthEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"aimbot"]) { isAimbotEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"fovcircle"]) { isFovCircleEnabled = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"wall"]) { isAimThroughWall = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"always"]) { isAlwaysAim = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"ghost"]) { isGhostEnabled = boolValue; doGhostHack(boolValue); updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"god"]) { isGodMode = boolValue; doGodMode(boolValue); updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"speed"]) { isSpeedHack = boolValue; updateWebSwitch(name, boolValue); }
        else if ([name isEqualToString:@"bypass"]) { isBypassEnabled = boolValue; doBypass(boolValue); updateWebSwitch(name, boolValue); }
    } else if ([message.name isEqualToString:@"fov"]) {
        fovSize = [data[@"value"] floatValue];
    } else if ([message.name isEqualToString:@"aimTarget"]) {
        aimTarget = [data[@"value"] intValue];
    } else if ([message.name isEqualToString:@"closeApp"]) {
        [self closeApp];
    } else if ([message.name isEqualToString:@"keyCheck"]) {
        [self checkKey:data[@"key"]];
    } else if ([message.name isEqualToString:@"init"]) {
        [self sendAllStatesToWeb];
        updateTimeRemaining();
    }
}

// ====== CHECK KEY FIREBASE ======
- (void)checkKey:(NSString *)key {
    if (key.length == 0) {
        [self sendKeyStatus:@"⚠️ Vui lòng nhập Key!"];
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/keys/%@.json", FIREBASE_DB_URL, key];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) { [self sendKeyStatus:@"❌ Lỗi kết nối!"]; return; }
            
            NSError *jsonError;
            NSDictionary *keyData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (!keyData || [keyData isKindOfClass:[NSNull class]]) {
                [self sendKeyStatus:@"❌ Key không tồn tại!"];
                return;
            }
            
            NSString *user = keyData[@"username"] ? keyData[@"username"] : @"Khách hàng VIP";
            NSTimeInterval expiration = [keyData[@"expiration"] doubleValue];
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            
            if (expiration < now) {
                [self sendKeyStatus:@"❌ Key đã hết hạn!"];
                return;
            }
            
            isKeyValidated = YES;
            currentUser = user;
            expirationTime = expiration;
            
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"saved_key"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self sendKeyStatus:@"✅ Kích hoạt thành công!"];
            [self enableAllFeatures];
            updateTimeRemaining();
        });
    }];
    [task resume];
}

- (void)sendKeyStatus:(NSString *)msg {
    NSDictionary *status = @{@"type": @"keyStatus", @"text": msg};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:status options:0 error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        sendToWeb(jsonString);
    }
}

- (void)enableAllFeatures {
    isEspEnabled = YES;
    isAimbotEnabled = YES;
    isBoxEnabled = YES;
    isLineEnabled = YES;
    isSkeletonEnabled = YES;
    isNameEnabled = YES;
    isHealthEnabled = YES;
    isFovCircleEnabled = YES;
    isAimThroughWall = YES;
    isAlwaysAim = YES;
    [self sendAllStatesToWeb];
}

- (void)toggleMenu {
    webView.hidden = !webView.hidden;
    if (!webView.hidden) {
        [self sendAllStatesToWeb];
        updateTimeRemaining();
    }
}

- (void)closeApp {
    exit(0);
}

// =====================================================================
// UPDATE LOOP - VẼ ESP
// =====================================================================
- (void)updateLoop {
    if (isEspEnabled) {
        [self drawESP];
    }
    
    if (isAimbotEnabled && isKeyValidated) {
        PlayerInfo player = getMainPlayerInfo();
        PlayerInfo target = findClosestEnemy(player);
        if (target.health > 0) {
            doAimbot(player, target);
        }
    }
    
    if (isGodMode) {
        doGodMode(YES);
    }
}

// =====================================================================
// DRAW ESP - BATCH VẼ TỐI ƯU (ĐÃ FIX LỖI)
// =====================================================================
- (void)drawESP {
    if (!isEspEnabled) return;
    
    for (CALayer *layer in espLayers) {
        [layer removeFromSuperlayer];
    }
    [espLayers removeAllObjects];
    
    PlayerInfo player = getMainPlayerInfo();
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    
    CGSize screenSize = self.view.bounds.size;
    CGPoint center = CGPointMake(screenSize.width/2, screenSize.height/2);
    
    if (isFovCircleEnabled && isAimbotEnabled) {
        UIBezierPath *fovPath = [UIBezierPath bezierPathWithArcCenter:center radius:fovSize startAngle:0 endAngle:2 * M_PI clockwise:YES];
        fovCircle.path = fovPath.CGPath;
        fovCircle.hidden = NO;
    } else {
        fovCircle.hidden = YES;
    }
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    UIBezierPath *boxPath = [UIBezierPath bezierPath];
    UIBezierPath *skeletonPath = [UIBezierPath bezierPath];
    NSMutableArray *nameLabels = [NSMutableArray array];
    NSMutableArray *healthLabels = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        PlayerInfo enemy = enemies[i];
        if (enemy.health <= 0 || enemy.isDead) continue;
        
        CGPoint screenPos = worldToScreen(enemy.x, enemy.y, enemy.z, screenSize);
        if (screenPos.x < 0 || screenPos.y < 0) continue;
        
        float boxSize = 40.0;
        CGRect box = CGRectMake(screenPos.x - boxSize/2, screenPos.y - boxSize, boxSize, boxSize);
        
        if (isLineEnabled) {
            [linePath moveToPoint:center];
            [linePath addLineToPoint:screenPos];
        }
        
        if (isBoxEnabled) {
            [boxPath appendPath:[UIBezierPath bezierPathWithRect:box]];
        }
        
        if (isSkeletonEnabled) {
            [skeletonPath moveToPoint:CGPointMake(box.origin.x, box.origin.y)];
            [skeletonPath addLineToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y + boxSize)];
            [skeletonPath moveToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y)];
            [skeletonPath addLineToPoint:CGPointMake(box.origin.x, box.origin.y + boxSize)];
        }
        
        if (isNameEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x - 30, screenPos.y - boxSize - 20, 60, 15)];
            label.text = [NSString stringWithFormat:@"Enemy %d", i];
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:9];
            label.textAlignment = NSTextAlignmentCenter;
            label.tag = 9999;
            [nameLabels addObject:label];
        }
        
        if (isHealthEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x - 20, screenPos.y - boxSize - 5, 40, 12)];
            label.text = [NSString stringWithFormat:@"❤️ %d", enemy.health];
            label.textColor = enemy.health > 50 ? [UIColor greenColor] : [UIColor redColor];
            label.font = [UIFont systemFontOfSize:8];
            label.textAlignment = NSTextAlignmentCenter;
            label.tag = 9998;
            [healthLabels addObject:label];
        }
    }
    
    // ====== VẼ BATCH LAYER - FIX HASPATH ======
    
    // Vẽ LINE - 1 layer duy nhất
    if (linePath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = linePath.CGPath;
        layer.strokeColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.5].CGColor;
        layer.lineWidth = 0.8;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    
    // Vẽ BOX - 1 layer duy nhất
    if (boxPath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = boxPath.CGPath;
        layer.strokeColor = [UIColor redColor].CGColor;
        layer.lineWidth = 1.5;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    
    // Vẽ SKELETON - 1 layer duy nhất
    if (skeletonPath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = skeletonPath.CGPath;
        layer.strokeColor = [UIColor orangeColor].CGColor;
        layer.lineWidth = 1.0;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    
    // NAME & HEALTH Labels
    for (UILabel *label in nameLabels) {
        [espCanvas addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    }
    for (UILabel *label in healthLabels) {
        [espCanvas addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    }
}

- (void)dealloc {
    [displayLink invalidate];
    displayLink = nil;
}

@end

// =====================================================================
// CONSTRUCTOR
// =====================================================================
__attribute__((constructor)) static void init() {
    dispatch_async(dispatch_get_main_queue(), ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelNormal + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[OverlayViewController alloc] init];
        overlayWindow.hidden = NO;
    });
}
