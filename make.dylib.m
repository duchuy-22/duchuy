#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <mach/vm_prot.h>
#import <mach/vm_sync.h>
#import <mach/task.h>
#import <mach/task_info.h>
#import <mach/thread_act.h>
#import <mach/thread_info.h>
#import <mach/thread_status.h>
#import <mach/mach_port.h>
#import <mach/mach_types.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// =====================================================================
// OFFSET FF - MÀY ĐIỀN OFFSET THẬT VÀO ĐÂY
// =====================================================================
#define OFF_MAIN        0x10F4F4
#define OFF_ENEMY       0x10F4F8
#define OFF_HEALTH      0xF8
#define OFF_ARMOR       0xFC
#define OFF_POS_X       0x34
#define OFF_POS_Y       0x38
#define OFF_POS_Z       0x3C
#define OFF_MOUSE_X     0x40
#define OFF_MOUSE_Y     0x44
#define OFF_GOD         0x29D1F
#define OFF_VISIBLE     0x11b1254
#define OFF_NAME        0x11a18e0
#define OFF_SPEED       0x17f7314
#define OFF_GHOST       0x2262f18
#define OFF_BYPASS      0x3ab11ec
#define OFF_FIRING      0x11a1844
#define OFF_MOVING      0x11a13c
#define OFF_TEAM        0x11bfe4
#define OFF_DEAD        0x11a11e8

// =====================================================================
// BIẾN TOÀN CỤC
// =====================================================================
static UIWindow *overlayWindow = nil;
static UIView *espCanvas = nil;
static CAShapeLayer *fovCircle = nil;
static NSMutableArray *espLayers = nil;
static CADisplayLink *displayLink = nil;
static UIButton *menuButton = nil;
static BOOL isMenuVisible = NO;

static BOOL isEspEnabled = YES;
static BOOL isBoxEnabled = YES;
static BOOL isLineEnabled = YES;
static BOOL isSkeletonEnabled = YES;
static BOOL isNameEnabled = YES;
static BOOL isDistanceEnabled = YES;
static BOOL isHPEnabled = YES;
static BOOL isAimbotEnabled = NO;
static float fovSize = 150.0f;
static BOOL isGodMode = NO;
static BOOL isSpeedHack = NO;
static BOOL isGhostEnabled = NO;
static BOOL isBypassEnabled = NO;

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
static uintptr_t getBase(void) {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

static float rf(uintptr_t a) {
    if (a == 0) return 0;
    return *(float *)a;
}

static int ri(uintptr_t a) {
    if (a == 0) return 0;
    return *(int *)a;
}

static bool rb(uintptr_t a) {
    if (a == 0) return false;
    return *(bool *)a;
}

static void wf(uintptr_t a, float v) {
    if (a == 0) return;
    *(float *)a = v;
}

static void wi(uintptr_t a, int v) {
    if (a == 0) return;
    *(int *)a = v;
}

// =====================================================================
// LẤY PLAYER
// =====================================================================
static PlayerInfo getMainPlayer(void) {
    PlayerInfo p = {0};
    uintptr_t b = getBase();
    if (b == 0) return p;
    uintptr_t addr = b + OFF_MAIN;
    p.health = ri(addr + OFF_HEALTH);
    p.armor = ri(addr + OFF_ARMOR);
    p.x = rf(addr + OFF_POS_X);
    p.y = rf(addr + OFF_POS_Y);
    p.z = rf(addr + OFF_POS_Z);
    p.mouseX = rf(addr + OFF_MOUSE_X);
    p.mouseY = rf(addr + OFF_MOUSE_Y);
    p.isFiring = rb(addr + OFF_FIRING);
    p.isMoving = rb(addr + OFF_MOVING);
    return p;
}

static PlayerInfo getEnemyInfo(uintptr_t addr) {
    PlayerInfo e = {0};
    e.health = ri(addr + OFF_HEALTH);
    e.x = rf(addr + OFF_POS_X);
    e.y = rf(addr + OFF_POS_Y);
    e.z = rf(addr + OFF_POS_Z);
    e.isDead = rb(addr + OFF_DEAD);
    e.isTeammate = rb(addr + OFF_TEAM);
    e.isVisible = rb(addr + OFF_VISIBLE);
    e.isFiring = rb(addr + OFF_FIRING);
    e.isMoving = rb(addr + OFF_MOVING);
    char *namePtr = (char *)(addr + OFF_NAME);
    if (namePtr) {
        strncpy(e.name, namePtr, 63);
        e.name[63] = '\0';
    }
    return e;
}

static void getAllEnemies(PlayerInfo *enemies, int *count) {
    *count = 0;
    uintptr_t b = getBase();
    if (b == 0) return;
    uintptr_t eb = b + OFF_ENEMY;
    for (int i = 4; i <= 128; i += 4) {
        uintptr_t addr = eb + i;
        PlayerInfo e = getEnemyInfo(addr);
        if (e.health > 0 && e.health <= 100 && e.x != 0 && !e.isDead && !e.isTeammate) {
            enemies[*count] = e;
            (*count)++;
            if (*count >= 31) break;
        }
    }
}

static float calcDist(PlayerInfo a, PlayerInfo b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    float dz = a.z - b.z;
    return sqrtf(dx*dx + dy*dy + dz*dz);
}

static PlayerInfo findClosestEnemy(PlayerInfo p) {
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    PlayerInfo empty = {0};
    if (count == 0) return empty;
    PlayerInfo closest = enemies[0];
    float minD = calcDist(p, closest);
    for (int i = 1; i < count; i++) {
        float d = calcDist(p, enemies[i]);
        if (d < minD) {
            minD = d;
            closest = enemies[i];
        }
    }
    return closest;
}

static CGPoint worldToScreen(float x, float y, float z, CGSize size) {
    return CGPointMake(x + 100, y + 100);
}

// =====================================================================
// HACK FUNCTIONS
// =====================================================================
static void doAimbot(PlayerInfo p, PlayerInfo t) {
    if (t.health <= 0) return;
    float d = calcDist(p, t);
    if (d < 0.1f || d > fovSize) return;
    float pitch = asinf((t.z - p.z) / d) * 180.0f / M_PI;
    float yaw = -atan2f(t.x - p.x, t.y - p.y) * 180.0f / M_PI + 180.0f;
    uintptr_t b = getBase();
    if (b == 0) return;
    uintptr_t addr = b + OFF_MAIN;
    wf(addr + OFF_MOUSE_X, yaw);
    wf(addr + OFF_MOUSE_Y, pitch);
}

static void doGod(bool enable) {
    uintptr_t b = getBase();
    if (b == 0) return;
    if (enable) wi(b + OFF_GOD, 2341507216);
}

static void doGhost(bool enable) {
    uintptr_t b = getBase();
    if (b == 0) return;
    uintptr_t addr = b + OFF_GHOST;
    if (enable) { wi(addr, 0xE3A00000); wi(addr+4, 0xE12FFF1E); }
}

static void doBypass(bool enable) {
    uintptr_t b = getBase();
    if (b == 0) return;
    uintptr_t addr = b + OFF_BYPASS;
    if (enable) { wi(addr, 0xE3A00001); wi(addr+4, 0xE12FFF1E); }
}

static void doSpeed(bool enable) {
    uintptr_t b = getBase();
    if (b == 0) return;
    wf(b + OFF_SPEED, enable ? 3.0f : 1.0f);
}

// =====================================================================
// MENU UI
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
    CGFloat w = 300, h = 440;
    CGFloat x = (self.superview.bounds.size.width - w) / 2;
    CGFloat y = (self.superview.bounds.size.height - h) / 2;
    self.frame = CGRectMake(x, y, w, h);
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, w-20, 30)];
    title.text = @"⚡ FF MOD";
    title.textColor = [UIColor orangeColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(w-40, 5, 30, 30);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
    
    int yPos = 50;
    [self addSwitch:@"👁️ ESP" y:&yPos tag:0];
    [self addSwitch:@"📦 Box" y:&yPos tag:1];
    [self addSwitch:@"📏 Line" y:&yPos tag:2];
    [self addSwitch:@"🦴 Skeleton" y:&yPos tag:3];
    [self addSwitch:@"🏷️ Name" y:&yPos tag:4];
    [self addSwitch:@"📡 Distance" y:&yPos tag:5];
    [self addSwitch:@"❤️ HP" y:&yPos tag:6];
    [self addSwitch:@"🎯 Aimbot" y:&yPos tag:7];
    [self addSwitch:@"🛡️ God" y:&yPos tag:8];
    [self addSwitch:@"👻 Ghost" y:&yPos tag:9];
    [self addSwitch:@"⚡ Speed"( y:&yPos tag:1010];
    [self addSwitch:@"🔄 Bypass," y:&yPos tag:11];
    
    UILabel *fovLabel = [[UILabel alloc] initWithFrame:CGRectMake yPos, 100, 30)];
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
    yPos += 45;
    
    UIButton *closeApp = [UIButton buttonWithType:UIButtonTypeSystem];
    closeApp.frame = CGRectMake(30, yPos, w-60, 40);
    [closeApp setTitle:@"🔴 ĐÓNG APP" forState:UIControlStateNormal];
    [closeApp setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeApp.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    closeApp.layer.cornerRadius = 10;
    [closeApp addTarget:self action:@selector(closeApp) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeApp];
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
        case 8: isGodMode = sender.on; doGod(sender.on); break;
        case 9: isGhostEnabled = sender.on; doGhost(sender.on); break;
        case 10: isSpeedHack = sender.on; doSpeed(sender.on); break;
        case 11: isBypassEnabled = sender.on; doBypass(sender.on); break;
    }
}

- (void)fovChanged:(UISlider *)sender {
    fovSize = sender.value;
    UILabel *label = (UILabel *)[self viewWithTag:500];
    label.text = [NSString stringWithFormat:@"FOV: %.0f", sender.value];
}

- (void)closeMenu {
    self.hidden = YES;
    isMenuVisible = NO;
    menuButton.hidden = NO;
}

- (void)closeApp {
    exit(0);
}

@end

// =====================================================================
// OVERLAY
// =====================================================================
@interface OverlayViewController : UIViewController
@property (nonatomic, strong) ModMenuView *menuView;
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
    
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(10, 50, 50, 50);
    menuButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9];
    menuButton.layer.cornerRadius = 25;
    [menuButton setTitle:@"⚡" forState:UIControlStateNormal];
    menuButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [menuButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuButton];
    
    self.menuView = [[ModMenuView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.menuView];
    
    fovCircle = [CAShapeLayer layer];
    fovCircle.fillColor = [UIColor clearColor].CGColor;
    fovCircle.strokeColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:0.5].CGColor;
    fovCircle.lineWidth = 1.5;
    [self.view.layer addSublayer:fovCircle];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop)];
    displayLink.preferredFramesPerSecond = 25;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)showMenu {
    self.menuView.hidden = NO;
    isMenuVisible = YES;
    menuButton.hidden = YES;
}

- (void)updateLoop {
    if (isEspEnabled) [self drawESP];
    if (isAimbotEnabled) {
        PlayerInfo player = getMainPlayer();
        PlayerInfo target = findClosestEnemy(player);
        if (target.health > 0) doAimbot(player, target);
    }
    if (isGodMode) doGod(YES);
    if (isBypassEnabled) doBypass(YES);
    if (isSpeedHack) doSpeed(YES);
}

- (void)drawESP {
    if (!isEspEnabled) return;
    for (CALayer *layer in espLayers) { [layer removeFromSuperlayer]; }
    [espLayers removeAllObjects];
    
    PlayerInfo player = getMainPlayer();
    PlayerInfo enemies[32];
    int count = 0;
    getAllEnemies(enemies, &count);
    CGSize screenSize = self.view.bounds.size;
    CGPoint center = CGPointMake(screenSize.width/2, screenSize.height/2);
    
    if (isAimbotEnabled) {
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:fovSize startAngle:0 endAngle:2*M_PI clockwise:YES];
        fovCircle.path = path.CGPath;
        fovCircle.hidden = NO;
    } else {
        fovCircle.hidden = YES;
    }
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    UIBezierPath *boxPath = [UIBezierPath bezierPath];
    UIBezierPath *skeletonPath = [UIBezierPath bezierPath];
    NSMutableArray *labels = [NSMutableArray array];
    
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
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-30, screenPos.y-boxSize-20, 60, 15)];
            label.text = [NSString stringWithUTF8String:enemy.name];
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:9];
            label.textAlignment = NSTextAlignmentCenter;
            [labels addObject:label];
        }
        if (isDistanceEnabled) {
            float dist = calcDist(player, enemy);
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-20, screenPos.y+boxSize+2, 40, 12)];
            label.text = [NSString stringWithFormat:@"%.0fm", dist];
            label.textColor = [UIColor yellowColor];
            label.font = [UIFont systemFontOfSize:8];
            [labels addObject:label];
        }
        if (isHPEnabled) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenPos.x-20, screenPos.y-boxSize-5, 40, 12)];
            label.text = [NSString stringWithFormat:@"❤️ %d", enemy.health];
            label.textColor = enemy.health > 50 ? [UIColor greenColor] : [UIColor redColor];
            label.font = [UIFont systemFontOfSize:8];
            [labels addObject:label];
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
    
    for (UILabel *label in labels) {
        [espCanvas addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
