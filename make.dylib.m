#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <dlfcn.h>

// =====================================================================
// OFFSET FF - TỪ FILE C# + ẢNH CỦA MÀY
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
// FIREBASE KEY SERVER
// =====================================================================
static NSString *const FIREBASE_DB_URL = @"https://duchuy-99a4f-default-rtdb.firebaseio.com";
static NSString *const APP_ID = @"ff_v1";

// =====================================================================
// BIẾN TOÀN CỤC
// =====================================================================
static BOOL isKeyValidated = NO;
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
static int aimTarget = 2; // 0:Head, 1:Neck, 2:Chest, 3:Body
static float fovSize = 150.0f;
static BOOL isGhostEnabled = NO;
static BOOL isBypassEnabled = NO;
static BOOL isGodMode = NO;
static BOOL isSpeedHack = NO;

static UIWindow *overlayWindow = nil;

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
// HÀM ĐỌC/GHI MEMORY (ĐÃ CÓ QUYỀN VÌ NẰM TRONG PROCESS)
// =====================================================================
static uintptr_t getFFBaseAddress(void) {
    // Lấy base address của FF (đã có sẵn trong process)
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

static void writeBoolFF(uintptr_t address, bool value) {
    if (address == 0) return;
    bool *ptr = (bool *)address;
    *ptr = value;
}

// =====================================================================
// HÀM LẤY PLAYER INFO
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

// =====================================================================
// HÀM LẤY DANH SÁCH ENEMY
// =====================================================================
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

// =====================================================================
// HÀM TÍNH KHOẢNG CÁCH
// =====================================================================
static float calcDistance3D(PlayerInfo from, PlayerInfo to) {
    float dx = to.x - from.x;
    float dy = to.y - from.y;
    float dz = to.z - from.z;
    return sqrtf(dx*dx + dy*dy + dz*dz);
}

// =====================================================================
// HÀM TÌM ENEMY GẦN NHẤT
// =====================================================================
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

// =====================================================================
// HÀM WORLD TO SCREEN
// =====================================================================
static CGPoint worldToScreen(PlayerInfo player, PlayerInfo camera, CGSize screenSize) {
    // Tạm thời return tọa độ giả
    return CGPointMake(player.x + 100, player.y + 100);
}

// =====================================================================
// HÀM AIMBOT
// =====================================================================
static void doAimbot(PlayerInfo source, PlayerInfo target) {
    if (target.health <= 0) return;
    if (!isAimThroughWall && !target.isVisible) return;
    
    float dist = calcDistance3D(source, target);
    if (dist < 0.1f) return;
    if (dist > fovSize) return;
    
    // Tính góc
    float pitch = asinf((target.z - source.z) / dist) * 180.0f / M_PI;
    float yaw = -atan2f((target.x - source.x), (target.y - source.y)) * 180.0f / M_PI + 180.0f;
    
    // Ghi vào memory
    uintptr_t playerAddr = getFFBaseAddress() + OFFSET_MAINPLAYER;
    writeFloatFF(playerAddr + OFFSET_MOUSE_X, yaw);
    writeFloatFF(playerAddr + OFFSET_MOUSE_Y, pitch);
}

// =====================================================================
// HÀM GOD MODE
// =====================================================================
static void doGodMode(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_GOD_MODE;
    if (enable) {
        uint32_t nop = 2341507216;
        writeIntFF(addr, nop);
    }
}

// =====================================================================
// HÀM SET FULL (MÁU, GIÁP)
// =====================================================================
static void setFull(void) {
    uintptr_t playerAddr = getFFBaseAddress() + OFFSET_MAINPLAYER;
    writeIntFF(playerAddr + OFFSET_HEALTH, 9337);
    writeIntFF(playerAddr + OFFSET_ARMOR, 9337);
    writeIntFF(playerAddr + 0x150, 9337);
    writeIntFF(playerAddr + 0x13C, 9337);
    writeIntFF(playerAddr + 0x158, 9337);
}

// =====================================================================
// HÀM GHOST HACK
// =====================================================================
static void doGhostHack(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_GHOST_HACK;
    if (enable) {
        // Patch On: 00 00 A0 E3 1E FF 2F E1
        uint32_t ghostOn[] = {0xE3A00000, 0xE12FFF1E};
        writeIntFF(addr, ghostOn[0]);
        writeIntFF(addr + 4, ghostOn[1]);
    } else {
        // Patch Off: F0 4F 2D E9 1C B0 8D E2
        uint32_t ghostOff[] = {0xE92D4FF0, 0xE28DB01C};
        writeIntFF(addr, ghostOff[0]);
        writeIntFF(addr + 4, ghostOff[1]);
    }
}

// =====================================================================
// HÀM BYPASS
// =====================================================================
static void doBypass(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_BYPASS;
    if (enable) {
        uint32_t retBytes[] = {0xE3A00001, 0xE12FFF1E};
        writeIntFF(addr, retBytes[0]);
        writeIntFF(addr + 4, retBytes[1]);
    }
}

// =====================================================================
// VIEW CONTROLLER - OVERLAY + WEB MENU
// =====================================================================
@interface OverlayViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) CAShapeLayer *fovCircle;
@property (nonatomic, strong) NSMutableArray *espLayers;
@property (nonatomic, strong) UIView *espCanvas;
@property (nonatomic, strong) NSTimer *espTimer;
@end

@implementation OverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.espLayers = [NSMutableArray array];
    
    // ESP Canvas
    self.espCanvas = [[UIView alloc] initWithFrame:self.view.bounds];
    self.espCanvas.backgroundColor = [UIColor clearColor];
    self.espCanvas.userInteractionEnabled = NO;
    self.espCanvas.tag = 999;
    [self.view addSubview:self.espCanvas];
    
    // Web Menu
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"toggle"];
    [contentController addScriptMessageHandler:self name:@"fov"];
    [contentController addScriptMessageHandler:self name:@"aimTarget"];
    [contentController addScriptMessageHandler:self name:@"keyCheck"];
    [contentController addScriptMessageHandler:self name:@"closeApp"];
    [contentController addScriptMessageHandler:self name:@"features"];
    config.userContentController = contentController;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(20, 50, self.view.bounds.size.width - 40, self.view.bounds.size.height - 100) configuration:config];
    self.webView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    self.webView.layer.cornerRadius = 16;
    self.webView.layer.borderWidth = 2;
    self.webView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.webView.hidden = YES;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    
    [self loadHTMLMenu];
    
    // Menu Button
    UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.frame = CGRectMake(10, 50, 50, 50);
    menuBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9];
    menuBtn.layer.cornerRadius = 25;
    [menuBtn setTitle:@"⚡" forState:UIControlStateNormal];
    menuBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [menuBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuBtn];
    
    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(self.view.bounds.size.width - 60, 50, 50, 50);
    closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    closeBtn.layer.cornerRadius = 25;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [closeBtn addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
    // FOV Circle
    self.fovCircle = [CAShapeLayer layer];
    self.fovCircle.fillColor = [UIColor clearColor].CGColor;
    self.fovCircle.strokeColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:0.5].CGColor;
    self.fovCircle.lineWidth = 1.5;
    [self.view.layer addSublayer:self.fovCircle];
    
    // ESP Timer
    self.espTimer = [NSTimer scheduledTimerWithTimeInterval:0.016 target:self selector:@selector(updateLoop) userInfo:nil repeats:YES];
}

// ====== HTML MENU ======
- (void)loadHTMLMenu {
    NSString *html = @"<!DOCTYPE html><html><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#0a0a0f;color:#fff;font-family:'Segoe UI',sans-serif;padding:15px;}.header{text-align:center;border-bottom:1px solid #ff6a00;padding-bottom:10px;margin-bottom:15px;}.header h1{color:#ff6a00;font-size:20px;}.header p{color:#888;font-size:11px;}.tab{display:flex;gap:5px;margin-bottom:15px;}.tab button{flex:1;padding:8px;background:#1a1a2e;border:1px solid #333;border-radius:6px;color:#aaa;font-size:12px;cursor:pointer;}.tab button.active{background:#ff6a00;color:#fff;border-color:#ff6a00;}.section{display:none;}.section.active{display:block;}.toggle-row{display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid #1a1a2e;}.toggle-row label{font-size:13px;color:#ddd;}.toggle-row input[type='range']{width:100px;}.switch{position:relative;width:44px;height:24px;background:#333;border-radius:12px;cursor:pointer;transition:0.3s;}.switch.on{background:#ff6a00;}.switch:after{content:'';position:absolute;top:2px;left:2px;width:20px;height:20px;background:#fff;border-radius:50%;transition:0.3s;}.switch.on:after{left:22px;}select{background:#1a1a2e;color:#fff;border:1px solid #333;padding:4px 8px;border-radius:4px;}.key-section{text-align:center;padding:20px 0;}.key-section input{width:80%;padding:10px;background:#1a1a2e;border:1px solid #333;border-radius:8px;color:#fff;text-align:center;font-size:14px;}.key-section button{margin-top:10px;padding:10px 30px;background:#ff6a00;border:none;border-radius:8px;color:#fff;font-size:14px;cursor:pointer;}.info{text-align:center;margin-top:15px;font-size:11px;color:#666;}</style></head><body><div class='header'><h1>⚡ FF MOD MENU</h1><p>Overlay ESP + Aimbot v2.0</p></div><div class='tab'><button class='active' onclick='showTab(0)'>ESP</button><button onclick='showTab(1)'>Aimbot</button><button onclick='showTab(2)'>Features</button><button onclick='showTab(3)'>Settings</button></div><div id='tab0' class='section active'><div class='toggle-row'><label>👁️ ESP</label><div class='switch on' onclick='toggleSwitch(this,\"esp\")'></div></div><div class='toggle-row'><label>📦 Box</label><div class='switch on' onclick='toggleSwitch(this,\"box\")'></div></div><div class='toggle-row'><label>📏 Line</label><div class='switch on' onclick='toggleSwitch(this,\"line\")'></div></div><div class='toggle-row'><label>🦴 Skeleton</label><div class='switch on' onclick='toggleSwitch(this,\"skeleton\")'></div></div><div class='toggle-row'><label>🏷️ Tên</label><div class='switch on' onclick='toggleSwitch(this,\"name\")'></div></div><div class='toggle-row'><label>❤️ Máu</label><div class='switch on' onclick='toggleSwitch(this,\"health\")'></div></div></div><div id='tab1' class='section'><div class='toggle-row'><label>🎯 Aimbot</label><div class='switch' onclick='toggleSwitch(this,\"aimbot\")'></div></div><div class='toggle-row'><label>⭕ Vòng FOV</label><div class='switch on' onclick='toggleSwitch(this,\"fovcircle\")'></div></div><div class='toggle-row'><label>📏 FOV Size: <span id='fovVal'>150</span></label><input type='range' min='30' max='300' value='150' oninput='updateFov(this.value)'></div><div class='toggle-row'><label>🎯 Aim Target</label><select id='aimTarget' onchange='updateAimTarget(this.value)'><option value='0'>Đầu</option><option value='1'>Cổ</option><option value='2' selected>Ngực</option><option value='3'>Body</option></select></div><div class='toggle-row'><label>🔒 Ghim xuyên tường</label><div class='switch' onclick='toggleSwitch(this,\"wall\")'></div></div><div class='toggle-row'><label>⚡ Bắn mới ghim</label><div class='switch on' onclick='toggleSwitch(this,\"always\")'></div></div></div><div id='tab2' class='section'><div class='toggle-row'><label>👻 Ghost Hack</label><div class='switch' onclick='toggleSwitch(this,\"ghost\")'></div></div><div class='toggle-row'><label>🛡️ God Mode</label><div class='switch' onclick='toggleSwitch(this,\"god\")'></div></div><div class='toggle-row'><label>⚡ Speed Hack</label><div class='switch' onclick='toggleSwitch(this,\"speed\")'></div></div><div class='toggle-row'><label>🔄 Bypass</label><div class='switch' onclick='toggleSwitch(this,\"bypass\")'></div></div></div><div id='tab3' class='section'><div class='key-section'><input type='text' id='keyInput' placeholder='🔑 Nhập Key...' style='width:80%;padding:10px;background:#1a1a2e;border:1px solid #333;border-radius:8px;color:#fff;text-align:center;font-size:14px;'><br><button onclick='checkKey()'>✅ KÍCH HOẠT</button><div style='margin-top:10px;font-size:12px;color:#888;' id='keyStatus'>Chưa kích hoạt</div></div><div style='text-align:center;margin-top:10px;'><button onclick='closeApp()' style='padding:10px 30px;background:#e74c3c;border:none;border-radius:8px;color:#fff;font-size:14px;cursor:pointer;'>🔴 ĐÓNG APP</button></div><div class='info'>⚡ Made by Anonymous | Overlay v2.0</div></div><script>function showTab(i){document.querySelectorAll('.section').forEach(el=>el.classList.remove('active'));document.getElementById('tab'+i).classList.add('active');document.querySelectorAll('.tab button').forEach((el,idx)=>{el.classList.toggle('active',idx===i);});}function toggleSwitch(el,name){el.classList.toggle('on');var value=el.classList.contains('on')?1:0;window.webkit.messageHandlers.toggle.postMessage({name:name,value:value});}function updateFov(v){document.getElementById('fovVal').innerText=v;window.webkit.messageHandlers.fov.postMessage({value:parseFloat(v)});}function updateAimTarget(v){window.webkit.messageHandlers.aimTarget.postMessage({value:parseInt(v)});}function checkKey(){var key=document.getElementById('keyInput').value;window.webkit.messageHandlers.keyCheck.postMessage({key:key});}function closeApp(){window.webkit.messageHandlers.closeApp.postMessage({});}</script></body></html>";
    [self.webView loadHTMLString:html baseURL:nil];
}

// ====== WEBVIEW MESSAGE HANDLER ======
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *data = message.body;
    
    if ([message.name isEqualToString:@"toggle"]) {
        NSString *name = data[@"name"];
        int value = [data[@"value"] intValue];
        if ([name isEqualToString:@"esp"]) isEspEnabled = value;
        else if ([name isEqualToString:@"box"]) isBoxEnabled = value;
        else if ([name isEqualToString:@"line"]) isLineEnabled = value;
        else if ([name isEqualToString:@"skeleton"]) isSkeletonEnabled = value;
        else if ([name isEqualToString:@"name"]) isNameEnabled = value;
        else if ([name isEqualToString:@"health"]) isHealthEnabled = value;
        else if ([name isEqualToString:@"aimbot"]) isAimbotEnabled = value;
        else if ([name isEqualToString:@"fovcircle"]) isFovCircleEnabled = value;
        else if ([name isEqualToString:@"wall"]) isAimThroughWall = value;
        else if ([name isEqualToString:@"always"]) isAlwaysAim = value;
        else if ([name isEqualToString:@"ghost"]) { isGhostEnabled = value; doGhostHack(value); }
        else if ([name isEqualToString:@"god"]) { isGodMode = value; doGodMode(value); }
        else if ([name isEqualToString:@"speed"]) isSpeedHack = value;
        else if ([name isEqualToString:@"bypass"]) { isBypassEnabled = value; doBypass(value); }
    } else if ([message.name isEqualToString:@"fov"]) {
        fovSize = [data[@"value"] floatValue];
    } else if ([message.name isEqualToString:@"aimTarget"]) {
        aimTarget = [data[@"value"] intValue];
    } else if ([message.name isEqualToString:@"closeApp"]) {
        [self closeApp];
    } else if ([message.name isEqualToString:@"keyCheck"]) {
        [self checkKey:data[@"key"]];
    }
}

// ====== CHECK KEY FIREBASE ======
- (void)checkKey:(NSString *)key {
    if (key.length == 0) {
        [self showWebMessage:@"⚠️ Vui lòng nhập Key!"];
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/keys/%@.json", FIREBASE_DB_URL, key];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) { [self showWebMessage:@"❌ Lỗi kết nối!"]; return; }
            NSError *jsonError;
            NSDictionary *keyData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!keyData || [keyData isKindOfClass:[NSNull class]]) { [self showWebMessage:@"❌ Key không tồn tại!"]; return; }
            NSTimeInterval expiration = [keyData[@"expiration"] doubleValue];
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            if (expiration < now) { [self showWebMessage:@"❌ Key đã hết hạn!"]; return; }
            isKeyValidated = YES;
            [self showWebMessage:@"✅ Kích hoạt thành công!"];
            [self enableAllFeatures];
        });
    }];
    [task resume];
}

- (void)showWebMessage:(NSString *)msg {
    NSString *js = [NSString stringWithFormat:@"document.getElementById('keyStatus').innerText = '%@';", msg];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)enableAllFeatures {
    isEspEnabled = YES;
    isAimbotEnabled = YES;
    NSString *js = @"document.querySelectorAll('.switch').forEach(el => el.classList.add('on'));";
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

// ====== TOGGLE MENU ======
- (void)toggleMenu {
    self.webView.hidden = !self.webView.hidden;
}

// ====== CLOSE APP ======
- (void)closeApp {
    exit(0);
}

// ====== UPDATE LOOP ======
- (void)updateLoop {
    // ESP
    if (isEspEnabled) {
        [self drawESP];
    }
    
    // Aimbot
    if (isAimbotEnabled && isKeyValidated) {
        PlayerInfo player = getMainPlayerInfo();
        PlayerInfo target = findClosestEnemy(player);
        if (target.health > 0) {
            doAimbot(player, target);
        }
    }
    
    // God Mode (duy trì)
    if (isGodMode) {
        doGodMode(YES);
    }
    
    // Full (duy trì)
    if (isKeyValidated) {
        setFull();
    }
}

// ====== DRAW ESP ======
- (void)drawESP {
    if (!isEspEnabled) return;
    
    // Xóa layer cũ
    for (CALayer *layer in self.espLayers) {
        [layer removeFromSuperlayer];
    }
    [self.espLayers removeAllObjects];
    
    PlayerInfo player = getMainPlayerInfo();
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    
    CGSize screenSize = self.view.bounds.size;
    CGPoint center = CGPointMake(screenSize.width/2, screenSize.height/2);
    
    // FOV
    if (isFovCircleEnabled && isAimbotEnabled) {
        UIBezierPath *fovPath = [UIBezierPath bezierPathWithArcCenter:center radius:fovSize startAngle:0 endAngle:2 * M_PI clockwise:YES];
        self.fovCircle.path = fovPath.CGPath;
        self.fovCircle.hidden = NO;
    } else {
        self.fovCircle.hidden = YES;
    }
    
    for (int i = 0; i < count; i++) {
        PlayerInfo enemy = enemies[i];
        if (enemy.health <= 0 || enemy.isDead) continue;
        
        CGPoint screenPos = worldToScreen(enemy, player, screenSize);
        if (screenPos.x < 0 || screenPos.y < 0) continue;
        
        CGFloat boxSize = 40.0;
        CGRect boxRect = CGRectMake(screenPos.x - boxSize/2, screenPos.y - boxSize, boxSize, boxSize);
        
        // BOX
        if (isBoxEnabled) {
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:boxRect];
            CAShapeLayer *layer = [CAShapeLayer layer];
            layer.path = path.CGPath;
            layer.strokeColor = enemy.isVisible ? [UIColor redColor].CGColor : [UIColor grayColor].CGColor;
            layer.lineWidth = 1.5;
            layer.fillColor = [UIColor clearColor].CGColor;
            [self.espCanvas.layer addSublayer:layer];
            [self.espLayers addObject:layer];
        }
        
        // LINE
        if (isLineEnabled) {
            UIBezierPath *linePath = [UIBezierPath bezierPath];
            [linePath moveToPoint:center];
            [linePath addLineToPoint:screenPos];
            CAShapeLayer *lineLayer = [CAShapeLayer layer];
            lineLayer.path = linePath.CGPath;
            lineLayer.strokeColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.5].CGColor;
            lineLayer.lineWidth = 0.8;
            [self.espCanvas.layer addSublayer:lineLayer];
            [self.espLayers addObject:lineLayer];
        }
        
        // SKELETON
        if (isSkeletonEnabled) {
            UIBezierPath *skelPath = [UIBezierPath bezierPath];
            [skelPath moveToPoint:CGPointMake(boxRect.origin.x, boxRect.origin.y)];
            [skelPath addLineToPoint:CGPointMake(boxRect.origin.x + boxSize, boxRect.origin.y + boxSize)];
            [skelPath moveToPoint:CGPointMake(boxRect.origin.x + boxSize, boxRect.origin.y)];
            [skelPath addLineToPoint:CGPointMake(boxRect.origin.x, boxRect.origin.y + boxSize)];
            CAShapeLayer *skelLayer = [CAShapeLayer layer];
            skelLayer.path = skelPath.CGPath;
            skelLayer.strokeColor = [UIColor orangeColor].CGColor;
            skelLayer.lineWidth = 1;
            [self.espCanvas.layer addSublayer:skelLayer];
            [self.espLayers addObject:skelLayer];
        }
        
        // NAME
        if (isNameEnabled) {
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x - 30, screenPos.y - boxSize - 20, 60, 15)];
            nameLabel.text = [NSString stringWithFormat:@"Enemy %d", i];
            nameLabel.textColor = [UIColor whiteColor];
            nameLabel.font = [UIFont systemFontOfSize:9];
            nameLabel.textAlignment = NSTextAlignmentCenter;
            nameLabel.tag = 9999;
            [self.espCanvas addSubview:nameLabel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [nameLabel removeFromSuperview];
            });
        }
        
        // HEALTH
        if (isHealthEnabled) {
            UILabel *healthLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x - 20, screenPos.y - boxSize - 5, 40, 12)];
            healthLabel.text = [NSString stringWithFormat:@"❤️ %d", enemy.health];
            healthLabel.textColor = enemy.health > 50 ? [UIColor greenColor] : [UIColor redColor];
            healthLabel.font = [UIFont systemFontOfSize:8];
            healthLabel.textAlignment = NSTextAlignmentCenter;
            healthLabel.tag = 9998;
            [self.espCanvas addSubview:healthLabel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [healthLabel removeFromSuperview];
            });
        }
    }
}

@end

// =====================================================================
// CONSTRUCTOR
// =====================================================================
__attribute__((constructor)) static void init() {
    dispatch_async(dispatch_get_main_queue(), ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[OverlayViewController alloc] init];
        overlayWindow.hidden = NO;
    });
}
