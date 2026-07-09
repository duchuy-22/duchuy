#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// =====================================================================
// OFFSET FF
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
static NSTimer *countdownTimer = nil;

static BOOL isEspEnabled = YES;
static BOOL isBoxEnabled = YES;
static BOOL isFullBoxEnabled = YES;
static BOOL isCornerBoxEnabled = NO;
static BOOL isLineEnabled = YES;
static BOOL isSkeletonEnabled = YES;
static BOOL isNameEnabled = YES;
static BOOL isDistanceEnabled = YES;
static BOOL isHPEnabled = YES;
static BOOL isMinimapEnabled = YES;

static BOOL isAimbotEnabled = NO;
static BOOL isFovEnabled = YES;
static BOOL isAutoFireEnabled = NO;
static BOOL isSkipKnockedEnabled = YES;
static float fovSize = 150.0f;
static int aimTarget = 1;
static int aimWhen = 0;

static BOOL isGodMode = NO;
static BOOL isGhostEnabled = NO;
static BOOL isSpeedHack = NO;
static BOOL isBypassEnabled = NO;
static BOOL isFastMedkit = NO;
static BOOL isNoRecoil = NO;

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
    bool isKnocked;
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
    if (isSkipKnockedEnabled && target.isKnocked) return;
    if (aimWhen == 1 && !source.isFiring) return;
    if (aimWhen == 2 && !source.isMoving) return;
    
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

static void doFastMedkit(bool enable) {
    uintptr_t addr = getFFBaseAddress() + OFFSET_FAST_MEDKIT;
    if (enable) {
        float speed = 2.0f;
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
// ===================== MENU VIEW =====================
// =====================================================================
@interface MainMenuViewController : UIViewController <UITabBarDelegate>
@property (nonatomic, strong) UITabBar *tabBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, strong) UITextField *keyField;
@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    self.view.layer.cornerRadius = 20;
    self.view.layer.borderWidth = 2;
    self.view.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    [self setupUI];
}

- (void)setupUI {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, w-40, 30)];
    title.text = @"⚡ NIGHTFALL MOD";
    title.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 45, w-40, 18)];
    self.userLabel.text = @"👤 User: Chưa đăng nhập";
    self.userLabel.textColor = [UIColor grayColor];
    self.userLabel.font = [UIFont systemFontOfSize:11];
    [self.view addSubview:self.userLabel];
    
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 65, w-40, 18)];
    self.timerLabel.text = @"⏳ Hết hạn: --:--:--";
    self.timerLabel.textColor = [UIColor greenColor];
    self.timerLabel.font = [UIFont systemFontOfSize:11];
    [self.view addSubview:self.timerLabel];
    
    self.keyField = [[UITextField alloc] initWithFrame:CGRectMake(20, 90, w-80, 35)];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.keyField.textColor = [UIColor whiteColor];
    self.keyField.placeholder = @"🔑 Nhập Key...";
    self.keyField.layer.cornerRadius = 8;
    [self.view addSubview:self.keyField];
    
    UIButton *keyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    keyBtn.frame = CGRectMake(w-55, 90, 35, 35);
    [keyBtn setTitle:@"✅" forState:UIControlStateNormal];
    keyBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.8];
    keyBtn.layer.cornerRadius = 8;
    [keyBtn addTarget:self action:@selector(checkKeyAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:keyBtn];
    
    NSArray *tabTitles = @[@"ESP", @"AIM", @"HACK", @"SET"];
    NSArray *tabIcons = @[@"👁️", @"🎯", @"⚡", @"⚙️"];
    
    self.tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, h-50, w, 50)];
    self.tabBar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.tabBar.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    self.tabBar.unselectedItemTintColor = [UIColor grayColor];
    self.tabBar.delegate = self;
    [self.view addSubview:self.tabBar];
    
    NSMutableArray *items = [NSMutableArray array];
    for (int i = 0; i < tabTitles.count; i++) {
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:tabTitles[i] image:[self imageFromText:tabIcons[i] fontSize:20] tag:i];
        [items addObject:item];
    }
    self.tabBar.items = items;
    self.tabBar.selectedItem = items[0];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(10, 130, w-20, h-190)];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    self.contentView.layer.cornerRadius = 12;
    [self.view addSubview:self.contentView];
    
    [self loadTab:0];
}

- (UIImage *)imageFromText:(NSString *)text fontSize:(CGFloat)fontSize {
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    CGSize size = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [text drawAtPoint:CGPointMake(0, 0) withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor whiteColor]}];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [self loadTab:(int)item.tag];
}

- (void)loadTab:(int)idx {
    for (UIView *v in self.contentView.subviews) [v removeFromSuperview];
    
    int y = 10;
    if (idx == 0) {
        [self addSwitch:self.contentView y:&y label:@"👁️ ESP" tag:0];
        [self addSwitch:self.contentView y:&y label:@"📦 Box" tag:1];
        [self addSwitch:self.contentView y:&y label:@"📦 Full Box" tag:2];
        [self addSwitch:self.contentView y:&y label:@"🔲 Corner Box" tag:3];
        [self addSwitch:self.contentView y:&y label:@"📏 Line" tag:4];
        [self addSwitch:self.contentView y:&y label:@"🦴 Skeleton" tag:5];
        [self addSwitch:self.contentView y:&y label:@"🏷️ Name" tag:6];
        [self addSwitch:self.contentView y:&y label:@"📡 Distance" tag:7];
        [self addSwitch:self.contentView y:&y label:@"❤️ HP" tag:8];
        [self addSwitch:self.contentView y:&y label:@"🗺️ Minimap" tag:9];
    } else if (idx == 1) {
        [self addSwitch:self.contentView y:&y label:@"🎯 Aimbot" tag:10];
        [self addSwitch:self.contentView y:&y label:@"⭕ FOV" tag:11];
        [self addSwitch:self.contentView y:&y label:@"🔥 Auto Fire" tag:12];
        [self addSwitch:self.contentView y:&y label:@"⏭️ Skip Knocked" tag:13];
        
        UILabel *fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 80, 30)];
        fovLabel.text = @"FOV: 150";
        fovLabel.textColor = [UIColor whiteColor];
        fovLabel.font = [UIFont systemFontOfSize:12];
        fovLabel.tag = 500;
        [self.contentView addSubview:fovLabel];
        
        UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(80, y, self.contentView.bounds.size.width-90, 30)];
        fovSlider.minimumValue = 30;
        fovSlider.maximumValue = 300;
        fovSlider.value = 150;
        fovSlider.tag = 501;
        [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:fovSlider];
        y += 45;
        
        UILabel *targetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 80, 30)];
        targetLabel.text = @"Aim Target";
        targetLabel.textColor = [UIColor whiteColor];
        targetLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:targetLabel];
        
        UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"Head", @"Neck", @"Body"]];
        targetSeg.frame = CGRectMake(80, y, self.contentView.bounds.size.width-90, 30);
        targetSeg.selectedSegmentIndex = aimTarget;
        targetSeg.tag = 502;
        [targetSeg addTarget:self action:@selector(targetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:targetSeg];
        y += 45;
        
        UILabel *whenLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 80, 30)];
        whenLabel.text = @"Aim When";
        whenLabel.textColor = [UIColor whiteColor];
        whenLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:whenLabel];
        
        UISegmentedControl *whenSeg = [[UISegmentedControl alloc] initWithItems:@[@"Always", @"Firing", @"Scope"]];
        whenSeg.frame = CGRectMake(80, y, self.contentView.bounds.size.width-90, 30);
        whenSeg.selectedSegmentIndex = aimWhen;
        whenSeg.tag = 503;
        [whenSeg addTarget:self action:@selector(whenChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:whenSeg];
        y += 45;
    } else if (idx == 2) {
        [self addSwitch:self.contentView y:&y label:@"🛡️ God Mode" tag:20];
        [self addSwitch:self.contentView y:&y label:@"👻 Ghost" tag:21];
        [self addSwitch:self.contentView y:&y label:@"⚡ Speed" tag:22];
        [self addSwitch:self.contentView y:&y label:@"🔄 Bypass" tag:23];
        [self addSwitch:self.contentView y:&y label:@"💊 Fast Medkit" tag:24];
        [self addSwitch:self.contentView y:&y label:@"🔫 No Recoil" tag:25];
    } else if (idx == 3) {
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(20, 20, self.contentView.bounds.size.width-40, 45);
        [closeBtn setTitle:@"🔴 ĐÓNG APP" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
        closeBtn.layer.cornerRadius = 10;
        [closeBtn addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:closeBtn];
        
        UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.contentView.bounds.size.width-40, 20)];
        ver.text = @"v3.0 | Firebase";
        ver.textColor = [UIColor grayColor];
        ver.font = [UIFont systemFontOfSize:11];
        ver.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:ver];
    }
}

- (void)addSwitch:(UIView *)content y:(int *)y label:(NSString *)label tag:(int)tag {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, *y, 150, 35)];
    lbl.text = label;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13];
    [content addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(content.bounds.size.width-60, *y, 50, 30)];
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8];
    sw.tag = tag;
    if (tag < 10 || tag == 8) sw.on = YES;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:sw];
    *y += 45;
}

- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 0: isEspEnabled = sender.on; break;
        case 1: isBoxEnabled = sender.on; break;
        case 2: isFullBoxEnabled = sender.on; break;
        case 3: isCornerBoxEnabled = sender.on; break;
        case 4: isLineEnabled = sender.on; break;
        case 5: isSkeletonEnabled = sender.on; break;
        case 6: isNameEnabled = sender.on; break;
        case 7: isDistanceEnabled = sender.on; break;
        case 8: isHPEnabled = sender.on; break;
        case 9: isMinimapEnabled = sender.on; break;
        case 10: isAimbotEnabled = sender.on; break;
        case 11: isFovEnabled = sender.on; break;
        case 12: isAutoFireEnabled = sender.on; break;
        case 13: isSkipKnockedEnabled = sender.on; break;
        case 20: isGodMode = sender.on; doGodMode(sender.on); break;
        case 21: isGhostEnabled = sender.on; doGhostHack(sender.on); break;
        case 22: isSpeedHack = sender.on; doSpeedHack(sender.on); break;
        case 23: isBypassEnabled = sender.on; doBypass(sender.on); break;
        case 24: isFastMedkit = sender.on; doFastMedkit(sender.on); break;
        case 25: isNoRecoil = sender.on; break;
    }
}

- (void)fovChanged:(UISlider *)sender {
    fovSize = sender.value;
    UILabel *fovLabel = (UILabel *)[self.view viewWithTag:500];
    fovLabel.text = [NSString stringWithFormat:@"FOV: %.0f", sender.value];
}

- (void)targetChanged:(UISegmentedControl *)sender {
    aimTarget = (int)sender.selectedSegmentIndex;
}

- (void)whenChanged:(UISegmentedControl *)sender {
    aimWhen = (int)sender.selectedSegmentIndex;
}

- (void)checkKeyAction {
    NSString *key = self.keyField.text;
    if (key.length > 0) {
        checkKey(key);
        self.keyField.text = @"";
    }
}

- (void)updateUserInfo {
    self.userLabel.text = [NSString stringWithFormat:@"👤 User: %@", currentUser];
    if (expirationTime > 0) {
        NSTimeInterval remaining = expirationTime - [[NSDate date] timeIntervalSince1970];
        if (remaining > 0) {
            int h = (int)(remaining / 3600);
            int m = (int)((remaining - h*3600) / 60);
            int s = (int)(remaining - h*3600 - m*60);
            self.timerLabel.text = [NSString stringWithFormat:@"⏳ Hết hạn: %02d:%02d:%02d", h, m, s];
        } else {
            self.timerLabel.text = @"⏳ Hết hạn: --:--:--";
        }
    }
}

- (void)closeApp {
    exit(0);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end

// =====================================================================
// OVERLAY VIEW CONTROLLER
// =====================================================================
@interface OverlayViewController : UIViewController
@property (nonatomic, strong) MainMenuViewController *menuVC;
@property (nonatomic, strong) UIButton *menuBtn;
@end

@implementation OverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    espLayers = [NSMutableArray array];
    
    espCanvas = [[UIView alloc] initWithFrame:self.view.bounds];
    espCanvas.backgroundColor = [UIColor clearColor];
    espCanvas.userInteractionEnabled = NO;
    [self.view addSubview:espCanvas];
    
    self.menuVC = [[MainMenuViewController alloc] init];
    self.menuVC.view.frame = CGRectMake(20, 50, self.view.bounds.size.width-40, self.view.bounds.size.height-80);
    self.menuVC.view.hidden = YES;
    [self addChildViewController:self.menuVC];
    [self.view addSubview:self.menuVC.view];
    [self.menuVC didMoveToParentViewController:self];
    
    self.menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.menuBtn.frame = CGRectMake(10, 50, 50, 50);
    self.menuBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.9];
    self.menuBtn.layer.cornerRadius = 25;
    [self.menuBtn setTitle:@"⚡" forState:UIControlStateNormal];
    self.menuBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [self.menuBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.menuBtn];
    
    fovCircle = [CAShapeLayer layer];
    fovCircle.fillColor = [UIColor clearColor].CGColor;
    fovCircle.strokeColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    fovCircle.lineWidth = 1.5;
    [self.view.layer addSublayer:fovCircle];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop)];
    displayLink.preferredFramesPerSecond = 25;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"saved_key"];
    if (savedKey) {
        checkKey(savedKey);
    }
}

- (void)updateUI {
    [self.menuVC updateUserInfo];
}

- (void)toggleMenu {
    self.menuVC.view.hidden = !self.menuVC.view.hidden;
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
    if (isFastMedkit) { doFastMedkit(YES); }
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
    UIBezierPath *skeletonPath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < count; i++) {
        PlayerInfo enemy = enemies[i];
        if (enemy.health <= 0 || enemy.isDead) continue;
        if (isSkipKnockedEnabled && enemy.isKnocked) continue;
        
        CGPoint screenPos = worldToScreen(enemy.x, enemy.y, enemy.z, screenSize);
        if (screenPos.x < 0 || screenPos.y < 0) continue;
        
        float boxSize = 40.0;
        CGRect box = CGRectMake(screenPos.x - boxSize/2, screenPos.y - boxSize, boxSize, boxSize);
        
        if (isLineEnabled) { [linePath moveToPoint:center]; [linePath addLineToPoint:screenPos]; }
        
        if (isBoxEnabled || isFullBoxEnabled) {
            [boxPath appendPath:[UIBezierPath bezierPathWithRect:box]];
        }
        if (isCornerBoxEnabled) {
            float cornerSize = 10;
            [boxPath moveToPoint:CGPointMake(box.origin.x, box.origin.y + cornerSize)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x, box.origin.y)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x + cornerSize, box.origin.y)];
            
            [boxPath moveToPoint:CGPointMake(box.origin.x + boxSize - cornerSize, box.origin.y)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y + cornerSize)];
            
            [boxPath moveToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y + boxSize - cornerSize)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x + boxSize, box.origin.y + boxSize)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x + boxSize - cornerSize, box.origin.y + boxSize)];
            
            [boxPath moveToPoint:CGPointMake(box.origin.x + cornerSize, box.origin.y + boxSize)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x, box.origin.y + boxSize)];
            [boxPath addLineToPoint:CGPointMake(box.origin.x, box.origin.y + boxSize - cornerSize)];
        }
        
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
        NSLog(@"✅ Nightfall Mod loaded!");
    });
}
