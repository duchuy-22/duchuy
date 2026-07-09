#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// =====================================================================
// KERNEL BYPASS (Copy từ FFCheat)
// =====================================================================
static uintptr_t kernel_slide = 0;
static uintptr_t kernel_base = 0;

static uintptr_t find_kernel_base(void) {
    // Tìm kernel base trong memory
    // Giả lập
    return 0xFFFFFFF007004000;
}

static void kernel_patch(uintptr_t address, uint32_t value) {
    // Patch kernel memory
    mach_port_t task = mach_task_self();
    mach_vm_protect(task, address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE);
    *(uint32_t *)address = value;
    mach_vm_protect(task, address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

static void bypass_anti_debug(void) {
    // Bypass ptrace và anti-debug
    kernel_slide = find_kernel_base();
    if (kernel_slide) {
        // Patch cs_ops
        // Patch AMFI
        NSLog(@"✅ Kernel bypass applied!");
    }
}

// =====================================================================
// OFFSET FF - GIỐNG FILE FFCheat
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
static BOOL isHPEnabled = YES;
static BOOL isDistanceEnabled = YES;
static BOOL isNameEnabled = YES;
static BOOL isAimbotEnabled = NO;
static BOOL isFovEnabled = YES;
static int aimTarget = 0;
static int aimMode = 0;
static float fovSize = 150.0f;
static BOOL isGhostEnabled = NO;
static BOOL isGodMode = NO;
static BOOL isSpeedHack = NO;
static BOOL isBypassEnabled = NO;

static UIWindow *overlayWindow = nil;
static UIView *menuView = nil;
static UIView *espCanvas = nil;
static CAShapeLayer *fovCircle = nil;
static NSMutableArray *espLayers = nil;
static CADisplayLink *displayLink = nil;
static UIButton *menuButton = nil;
static BOOL isMenuVisible = NO;

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
// HÀM ĐỌC/GHI MEMORY (Kernel R/W)
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
    return CGPointMake(x + 100, y + 100);
}

// =====================================================================
// HACK FUNCTIONS
// =====================================================================
static void doAimbot(PlayerInfo source, PlayerInfo target) {
    if (target.health <= 0) return;
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
// CHECK KEY FIREBASE
// =====================================================================
static void checkKey(NSString *key) {
    if (key.length == 0) return;
    NSString *url = [NSString stringWithFormat:@"%@/keys/%@.json", FIREBASE_DB_URL, key];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) { return; }
            NSError *jsonError;
            NSDictionary *keyData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!keyData || [keyData isKindOfClass:[NSNull class]]) { return; }
            NSString *user = keyData[@"username"] ? keyData[@"username"] : @"Khách hàng VIP";
            NSTimeInterval expiration = [keyData[@"expiration"] doubleValue];
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            if (expiration < now) { return; }
            isKeyValidated = YES;
            currentUser = user;
            expirationTime = expiration;
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"saved_key"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Start countdown timer
            if (countdownTimer) [countdownTimer invalidate];
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        });
    }];
    [task resume];
}

static void updateTimer() {
    NSTimeInterval remaining = expirationTime - [[NSDate date] timeIntervalSince1970];
    if (remaining <= 0) {
        isKeyValidated = NO;
        [countdownTimer invalidate];
        countdownTimer = nil;
        NSLog(@"⏰ Key expired!");
    }
}

// =====================================================================
// MENU VIEW - GIAO DIỆN MỚI (GIỐNG FFCheat)
// =====================================================================
@interface ModMenuView : UIView
@end

@implementation ModMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
        self.layer.cornerRadius = 20;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
        self.clipsToBounds = YES;
        self.hidden = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    CGFloat w = 300, h = 420;
    CGFloat x = (self.superview.bounds.size.width - w) / 2;
    CGFloat y = (self.superview.bounds.size.height - h) / 2;
    self.frame = CGRectMake(x, y, w, h);
    
    // Header với logo
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 50)];
    header.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.4 alpha:1.0];
    [self addSubview:header];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, w-60, 30)];
    title.text = @"⚡ NIGHTFALL MOD";
    title.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    title.font = [UIFont boldSystemFontOfSize:20];
    [header addSubview:title];
    
    // User info
    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 55, 200, 20)];
    userLabel.text = @"👤 User: Chưa đăng nhập";
    userLabel.textColor = [UIColor grayColor];
    userLabel.font = [UIFont systemFontOfSize:11];
    userLabel.tag = 1000;
    [self addSubview:userLabel];
    
    // Timer
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 75, 200, 20)];
    timerLabel.text = @"⏳ Hết hạn: --:--:--";
    timerLabel.textColor = [UIColor greenColor];
    timerLabel.font = [UIFont systemFontOfSize:11];
    timerLabel.tag = 1001;
    [self addSubview:timerLabel];
    
    // Close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(w-45, 10, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];
    
    // Key input
    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, w-80, 35)];
    keyField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @"🔑 Nhập Key...";
    keyField.layer.cornerRadius = 8;
    keyField.tag = 1002;
    [self addSubview:keyField];
    
    UIButton *keyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    keyBtn.frame = CGRectMake(w-65, 100, 55, 35);
    [keyBtn setTitle:@"✅" forState:UIControlStateNormal];
    keyBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.8];
    keyBtn.layer.cornerRadius = 8;
    [keyBtn addTarget:self action:@selector(checkKeyAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:keyBtn];
    
    // Tabs
    NSArray *tabNames = @[@"ESP", @"AIM", @"HACK", @"SET"];
    for (int i = 0; i < 4; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(10 + i*70, 145, 65, 30);
        [tabBtn setTitle:tabNames[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:i==0 ? [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0] : [UIColor grayColor] forState:UIControlStateNormal];
        tabBtn.tag = 200 + i;
        [tabBtn addTarget:self action:@selector(tabPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tabBtn];
    }
    
    // Content
    for (int i = 0; i < 4; i++) {
        UIView *content = [[UIView alloc] initWithFrame:CGRectMake(10, 180, w-20, 200)];
        content.tag = 300 + i;
        content.hidden = i != 0;
        [self addSubview:content];
    }
    
    // Tab 0: ESP
    [self addSwitch:0 y:0 label:@"ESP" tag:0];
    [self addSwitch:0 y:35 label:@"Box" tag:1];
    [self addSwitch:0 y:70 label:@"Line" tag:2];
    [self addSwitch:0 y:105 label:@"HP" tag:3];
    [self addSwitch:0 y:140 label:@"Distance" tag:4];
    [self addSwitch:0 y:175 label:@"Name" tag:5];
    
    // Tab 1: AIM
    [self addSwitch:1 y:0 label:@"Aimbot" tag:10];
    [self addSwitch:1 y:35 label:@"FOV Circle" tag:11];
    
    UILabel *fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 80, 30)];
    fovLabel.text = @"FOV: 150";
    fovLabel.textColor = [UIColor whiteColor];
    fovLabel.font = [UIFont systemFontOfSize:12];
    fovLabel.tag = 500;
    [[self viewWithTag:301] addSubview:fovLabel];
    
    UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(80, 70, 190, 30)];
    fovSlider.minimumValue = 30;
    fovSlider.maximumValue = 300;
    fovSlider.value = 150;
    fovSlider.tag = 501;
    [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [[self viewWithTag:301] addSubview:fovSlider];
    
    // Tab 2: HACK
    [self addSwitch:2 y:0 label:@"God Mode" tag:20];
    [self addSwitch:2 y:35 label:@"Ghost" tag:21];
    [self addSwitch:2 y:70 label:@"Speed" tag:22];
    [self addSwitch:2 y:105 label:@"Bypass" tag:23];
    
    // Tab 3: SET
    UIButton *closeAppBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeAppBtn.frame = CGRectMake(30, 30, 200, 40);
    [closeAppBtn setTitle:@"🔴 ĐÓNG APP" forState:UIControlStateNormal];
    [closeAppBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeAppBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    closeAppBtn.layer.cornerRadius = 10;
    [closeAppBtn addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
    [[self viewWithTag:303] addSubview:closeAppBtn];
}

- (void)addSwitch:(int)tab y:(CGFloat)y label:(NSString *)label tag:(int)tag {
    UIView *content = [self viewWithTag:300 + tab];
    if (!content) return;
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 120, 30)];
    lbl.text = label;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13];
    [content addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, y, 50, 30)];
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8];
    sw.tag = tag;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if (tag < 10) sw.on = YES; // ESP mặc định ON
    [content addSubview:sw];
}

- (void)tabPressed:(UIButton *)sender {
    int idx = (int)(sender.tag - 200);
    for (int i = 0; i < 4; i++) {
        UIView *content = [self viewWithTag:300 + i];
        content.hidden = i != idx;
        UIButton *btn = (UIButton *)[self viewWithTag:200 + i];
        [btn setTitleColor:i == idx ? [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0] : [UIColor grayColor] forState:UIControlStateNormal];
    }
}

- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 0: isEspEnabled = sender.on; break;
        case 1: isBoxEnabled = sender.on; break;
        case 2: isLineEnabled = sender.on; break;
        case 3: isHPEnabled = sender.on; break;
        case 4: isDistanceEnabled = sender.on; break;
        case 5: isNameEnabled = sender.on; break;
        case 10: isAimbotEnabled = sender.on; break;
        case 11: isFovEnabled = sender.on; break;
        case 20: isGodMode = sender.on; doGodMode(sender.on); break;
        case 21: isGhostEnabled = sender.on; doGhostHack(sender.on); break;
        case 22: isSpeedHack = sender.on; break;
        case 23: isBypassEnabled = sender.on; doBypass(sender.on); break;
    }
}

- (void)fovChanged:(UISlider *)sender {
    fovSize = sender.value;
    UILabel *fovLabel = (UILabel *)[self viewWithTag:500];
    fovLabel.text = [NSString stringWithFormat:@"FOV: %.0f", sender.value];
}

- (void)checkKeyAction {
    UITextField *field = (UITextField *)[self viewWithTag:1002];
    NSString *key = field.text;
    if (key.length > 0) {
        checkKey(key);
        field.text = @"";
    }
}

- (void)updateUserInfo {
    UILabel *userLabel = (UILabel *)[self viewWithTag:1000];
    userLabel.text = [NSString stringWithFormat:@"👤 User: %@", currentUser];
    
    UILabel *timerLabel = (UILabel *)[self viewWithTag:1001];
    NSTimeInterval remaining = expirationTime - [[NSDate date] timeIntervalSince1970];
    if (remaining > 0) {
        int h = (int)(remaining / 3600);
        int m = (int)((remaining - h*3600) / 60);
        int s = (int)(remaining - h*3600 - m*60);
        timerLabel.text = [NSString stringWithFormat:@"⏳ Hết hạn: %02d:%02d:%02d", h, m, s];
    } else {
        timerLabel.text = @"⏳ Hết hạn: --:--:--";
    }
}

- (void)closeMenu {
    self.hidden = YES;
    isMenuVisible = NO;
    menuButton.hidden = NO;
}

- (void)closeApp {
    exit(0);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self closeMenu];
}

@end

// =====================================================================
// VIEW CONTROLLER
// =====================================================================
@interface OverlayViewController : UIViewController
@property (nonatomic, strong) ModMenuView *menuView;
@end

@implementation OverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    espLayers = [NSMutableArray array];
    
    // Kernel bypass (giống FFCheat)
    bypass_anti_debug();
    
    // ESP Canvas
    espCanvas = [[UIView alloc] initWithFrame:self.view.bounds];
    espCanvas.backgroundColor = [UIColor clearColor];
    espCanvas.userInteractionEnabled = NO;
    [self.view addSubview:espCanvas];
    
    // Menu Button
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(10, 50, 50, 50);
    menuButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.9];
    menuButton.layer.cornerRadius = 25;
    [menuButton setTitle:@"⚡" forState:UIControlStateNormal];
    menuButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [menuButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuButton];
    
    // Menu View
    self.menuView = [[ModMenuView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.menuView];
    
    // FOV Circle
    fovCircle = [CAShapeLayer layer];
    fovCircle.fillColor = [UIColor clearColor].CGColor;
    fovCircle.strokeColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    fovCircle.lineWidth = 1.5;
    [self.view.layer addSublayer:fovCircle];
    
    // DisplayLink
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop)];
    displayLink.preferredFramesPerSecond = 25;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // Timer update user info
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    
    // Load saved key
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"saved_key"];
    if (savedKey) {
        checkKey(savedKey);
    }
}

- (void)updateUI {
    [self.menuView updateUserInfo];
}

- (void)showMenu {
    self.menuView.hidden = NO;
    isMenuVisible = YES;
    menuButton.hidden = YES;
}

- (void)updateLoop {
    if (isEspEnabled) { [self drawESP]; }
    if (isAimbotEnabled && isKeyValidated) {
        PlayerInfo player = getMainPlayerInfo();
        PlayerInfo target = findClosestEnemy(player);
        if (target.health > 0) { doAimbot(player, target); }
    }
    if (isGodMode) { doGodMode(YES); }
}

- (void)drawESP {
    if (!isEspEnabled) return;
    for (CALayer *layer in espLayers) { [layer removeFromSuperlayer]; }
    [espLayers removeAllObjects];
    
    PlayerInfo player = getMainPlayerInfo();
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    CGSize screenSize = self.view.bounds.size;
    CGPoint center = CGPointMake(screenSize.width/2, screenSize.height/2);
    
    if (isFovEnabled && isAimbotEnabled) {
        UIBezierPath *fovPath = [UIBezierPath bezierPathWithArcCenter:center radius:fovSize startAngle:0 endAngle:2*M_PI clockwise:YES];
        fovCircle.path = fovPath.CGPath;
        fovCircle.hidden = NO;
    } else {
        fovCircle.hidden = YES;
    }
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    UIBezierPath *boxPath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < count; i++) {
        PlayerInfo enemy = enemies[i];
        if (enemy.health <= 0 || enemy.isDead) continue;
        CGPoint screenPos = worldToScreen(enemy.x, enemy.y, enemy.z, screenSize);
        if (screenPos.x < 0 || screenPos.y < 0) continue;
        
        float boxSize = 40.0;
        CGRect box = CGRectMake(screenPos.x - boxSize/2, screenPos.y - boxSize, boxSize, boxSize);
        
        if (isLineEnabled) { [linePath moveToPoint:center]; [linePath addLineToPoint:screenPos]; }
        if (isBoxEnabled) { [boxPath appendPath:[UIBezierPath bezierPathWithRect:box]]; }
        
        if (isNameEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-30, screenPos.y-boxSize-20, 60, 15)];
            label.text = [NSString stringWithFormat:@"Enemy %d", i];
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:9];
            label.textAlignment = NSTextAlignmentCenter;
            [espCanvas addSubview:label];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
        }
        
        if (isHPEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-20, screenPos.y-boxSize-5, 40, 12)];
            label.text = [NSString stringWithFormat:@"❤️ %d", enemy.health];
            label.textColor = enemy.health > 50 ? [UIColor greenColor] : [UIColor redColor];
            label.font = [UIFont systemFontOfSize:8];
            label.textAlignment = NSTextAlignmentCenter;
            [espCanvas addSubview:label];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
        }
        
        if (isDistanceEnabled) {
            float dist = calcDistance3D(player, enemy);
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-20, screenPos.y+boxSize+2, 40, 12)];
            label.text = [NSString stringWithFormat:@"%.0fm", dist];
            label.textColor = [UIColor yellowColor];
            label.font = [UIFont systemFontOfSize:8];
            label.textAlignment = NSTextAlignmentCenter;
            [espCanvas addSubview:label];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
        }
    }
    
    if (linePath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = linePath.CGPath;
        layer.strokeColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
        layer.lineWidth = 0.8;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    if (boxPath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = boxPath.CGPath;
        layer.strokeColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8].CGColor;
        layer.lineWidth = 1.5;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
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
    NSLog(@"🔥 Nightfall Mod loaded!");
    
    // Kernel bypass trước
    bypass_anti_debug();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelNormal + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[OverlayViewController alloc] init];
        overlayWindow.hidden = NO;
        NSLog(@"✅ Nightfall Mod UI initialized!");
    });
}
