#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
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

static BOOL isEspEnabled = YES;
static BOOL isBoxEnabled = YES;
static BOOL isLineEnabled = YES;
static BOOL isSkeletonEnabled = YES;
static BOOL isNameEnabled = YES;
static BOOL isDistanceEnabled = YES;
static BOOL isHPEnabled = YES;

static BOOL isAimbotEnabled = NO;
static float fovSize = 150.0f;
static int aimTarget = 1;

static BOOL isGodMode = NO;
static BOOL isGhostEnabled = NO;
static BOOL isSpeedHack = NO;
static BOOL isBypassEnabled = NO;

static UIWindow *overlayWindow = nil;
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
    bool isFiring;
    bool isMoving;
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

static void readStringFF(uintptr_t address, char *buffer, size_t size) {
    if (address == 0 || buffer == NULL) return;
    char *ptr = (char *)address;
    strncpy(buffer, ptr, size - 1);
    buffer[size - 1] = '\0';
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
    info.isFiring = readBoolFF(playerAddr + OFFSET_IS_FIRING);
    info.isMoving = readBoolFF(playerAddr + OFFSET_IS_MOVING);
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
    info.isFiring = readBoolFF(enemyAddr + OFFSET_IS_FIRING);
    info.isMoving = readBoolFF(enemyAddr + OFFSET_IS_MOVING);
    readStringFF(enemyAddr + OFFSET_GET_NAME, info.name, sizeof(info.name));
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

static void doSpeedHack(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_GET_SPEED_SCALE;
    if (enable) {
        float speed = 3.0f;
        writeFloatFF(addr, speed);
    } else {
        float speed = 1.0f;
        writeFloatFF(addr, speed);
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
            if (expiration < [[NSDate date] timeIntervalSince1970]) { return; }
            isKeyValidated = YES;
            currentUser = user;
            expirationTime = expiration;
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"saved_key"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });
    }];
    [task resume];
}

// =====================================================================
// MENU VIEW - UI ĐƠN GIẢN
// =====================================================================
@interface ModMenuView : UIView
@end

@implementation ModMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.layer.cornerRadius = 16;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor orangeColor].CGColor;
        self.hidden = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    CGFloat w = 300, h = 400;
    CGFloat x = (self.superview.bounds.size.width - w) / 2;
    CGFloat y = (self.superview.bounds.size.height - h) / 2;
    self.frame = CGRectMake(x, y, w, h);
    
    // Header
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, w-20, 30)];
    title.text = @"⚡ FF MOD";
    title.textColor = [UIColor orangeColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];
    
    // User info
    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 45, w-20, 18)];
    userLabel.text = @"👤 User: Chưa đăng nhập";
    userLabel.textColor = [UIColor grayColor];
    userLabel.font = [UIFont systemFontOfSize:11];
    userLabel.tag = 1000;
    [self addSubview:userLabel];
    
    // Timer
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 65, w-20, 18)];
    timerLabel.text = @"⏳ Hết hạn: --:--:--";
    timerLabel.textColor = [UIColor greenColor];
    timerLabel.font = [UIFont systemFontOfSize:11];
    timerLabel.tag = 1001;
    [self addSubview:timerLabel];
    
    // Key input
    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(10, 90, w-60, 35)];
    keyField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @"🔑 Nhập Key...";
    keyField.layer.cornerRadius = 8;
    keyField.tag = 1002;
    [self addSubview:keyField];
    
    UIButton *keyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    keyBtn.frame = CGRectMake(w-45, 90, 35, 35);
    [keyBtn setTitle:@"✅" forState:UIControlStateNormal];
    keyBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.8];
    keyBtn.layer.cornerRadius = 8;
    [keyBtn addTarget:self action:@selector(checkKeyAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:keyBtn];
    
    // Separator
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 135, w-20, 1)];
    line.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [self addSubview:line];
    
    // Switches
    int yPos = 150;
    [self addSwitch:@"👁️ ESP" y:&yPos tag:0];
    [self addSwitch:@"📦 Box" y:&yPos tag:1];
    [self addSwitch:@"📏 Line" y:&yPos tag:2];
    [self addSwitch:@"🦴 Skeleton" y:&yPos tag:3];
    [self addSwitch:@"🏷️ Name" y:&yPos tag:4];
    [self addSwitch:@"📡 Distance" y:&yPos tag:5];
    [self addSwitch:@"❤️ HP" y:&yPos tag:6];
    [self addSwitch:@"🎯 Aimbot" y:&yPos tag:7];
    [self addSwitch:@"🛡️ God Mode" y:&yPos tag:8];
    [self addSwitch:@"⚡ Speed" y:&yPos tag:9];
    [self addSwitch:@"👻 Ghost" y:&yPos tag:10];
    [self addSwitch:@"🔄 Bypass" y:&yPos tag:11];
    
    // FOV Slider
    UILabel *fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yPos, 100, 30)];
    fovLabel.text = @"FOV: 150";
    fovLabel.textColor = [UIColor whiteColor];
    fovLabel.font = [UIFont systemFontOfSize:12];
    fovLabel.tag = 500;
    [self addSubview:fovLabel];
    
    UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(110, yPos, 180, 30)];
    fovSlider.minimumValue = 30;
    fovSlider.maximumValue = 300;
    fovSlider.value = 150;
    fovSlider.tag = 501;
    [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:fovSlider];
    yPos += 40;
    
    // Close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(30, yPos, w-60, 40);
    [closeBtn setTitle:@"🔴 ĐÓNG APP" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeBtn];
}

- (void)addSwitch:(NSString *)title y:(int *)y tag:(int)tag {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, *y, 140, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13];
    [self addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(230, *y, 50, 30)];
    sw.onTintColor = [UIColor orangeColor];
    sw.tag = tag;
    if (tag < 7) sw.on = YES;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:sw];
    *y += 35;
}

- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 0: isEspEnabled = sender.on; break;
        case 1: isBoxEnabled = sender.on; break;
        case 2: isLineEnabled = sender.on; break;
        case 3: isSkeletonEnabled = sender.on; break;
        case 4: isNameEnabled = sender.on; break;
        case 5: isDistanceEnabled = sender.on; break;
        case 6: isHPEnabled = sender.on; break;
        case 7: isAimbotEnabled = sender.on; break;
        case 8: isGodMode = sender.on; doGodMode(sender.on); break;
        case 9: isSpeedHack = sender.on; doSpeedHack(sender.on); break;
        case 10: isGhostEnabled = sender.on; doGhostHack(sender.on); break;
        case 11: isBypassEnabled = sender.on; doBypass(sender.on); break;
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

- (void)closeApp {
    exit(0);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self endEditing:YES];
}

@end

// =====================================================================
// OVERLAY VIEW CONTROLLER
// =====================================================================
@interface OverlayViewController : UIViewController
@property (nonatomic, strong) ModMenuView *menuView;
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
    [self.view addSubview:espCanvas];
    
    // Menu Button
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(10, 50, 50, 50);
    menuButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9];
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
    fovCircle.strokeColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:0.5].CGColor;
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
    if (isBypassEnabled) { doBypass(YES); }
    if (isSpeedHack) { doSpeedHack(YES); }
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
    
    if (isAimbotEnabled) {
        UIBezierPath *fovPath = [UIBezierPath bezierPathWithArcCenter:center radius:fovSize startAngle:0 endAngle:2*M_PI clockwise:YES];
        fovCircle.path = fovPath.CGPath;
        fovCircle.hidden = NO;
    } else {
        fovCircle.hidden = YES;
    }
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    UIBezierPath *boxPath = [UIBezierPath bezierPath];
    UIBezierPath *skeletonPath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < count; i++) {
        PlayerInfo enemy = enemies[i];
        if (enemy.health <= 0 || enemy.isDead) continue;
        
        CGPoint screenPos = worldToScreen(enemy.x, enemy.y, enemy.z, screenSize);
        if (screenPos.x < 0 || screenPos.y < 0) continue;
        
        float boxSize = 40.0;
        CGRect box = CGRectMake(screenPos.x - boxSize/2, screenPos.y - boxSize, boxSize, boxSize);
        
        if (isLineEnabled) { [linePath moveToPoint:center]; [linePath addLineToPoint:screenPos]; }
        if (isBoxEnabled) { [boxPath appendPath:[UIBezierPath bezierPathWithRect:box]]; }
        if (isSkeletonEnabled) {
            [skeletonPath moveToPoint:CGPointMake(box.origin.x, box.origin.y)];
            [skeletonPath addLineToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y + boxSize)];
            [skeletonPath moveToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y)];
            [skeletonPath addLineToPoint:CGPointMake(box.origin.x, box.origin.y + boxSize)];
        }
        
        if (isNameEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-30, screenPos.y-boxSize-20, 60, 15)];
            label.text = [NSString stringWithUTF8String:enemy.name];
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:9];
            label.textAlignment = NSTextAlignmentCenter;
            label.tag = 9999;
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
            label.tag = 9998;
            [espCanvas addSubview:label];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
        }
        
        if (isHPEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-20, screenPos.y-boxSize-5, 40, 12)];
            label.text = [NSString stringWithFormat:@"❤️ %d", enemy.health];
            label.textColor = enemy.health > 50 ? [UIColor greenColor] : [UIColor redColor];
            label.font = [UIFont systemFontOfSize:8];
            label.textAlignment = NSTextAlignmentCenter;
            label.tag = 9997;
            [espCanvas addSubview:label];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
        }
    }
    
    if (linePath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = linePath.CGPath;
        layer.strokeColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.5].CGColor;
        layer.lineWidth = 0.8;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    if (boxPath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = boxPath.CGPath;
        layer.strokeColor = [UIColor redColor].CGColor;
        layer.lineWidth = 1.5;
        layer.fillColor = [UIColor clearColor].CGColor;
        [espCanvas.layer addSublayer:layer];
        [espLayers addObject:layer];
    }
    if (skeletonPath.CGPath != NULL) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = skeletonPath.CGPath;
        layer.strokeColor = [UIColor orangeColor].CGColor;
        layer.lineWidth = 1.0;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelNormal + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[OverlayViewController alloc] init];
        overlayWindow.hidden = NO;
    });
}
