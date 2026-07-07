#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

// ====== CONFIG ======
#define MENU_WIDTH 380
#define MENU_HEIGHT 520
#define TAB_COUNT 4

// ====== SINGLETON ======
@interface GrannyMod : UIView {
    // UI
    UIView *menuView;
    UISegmentedControl *tabControl;
    UIButton *closeBtn;
    UIView *tabContent;
    BOOL isOpen;
    BOOL isAnimating;
    
    // Aimbot
    BOOL aimbotEnabled;
    int aimTarget; // 0:Đầu, 1:Ngực, 2:Cổ, 3:Bụng
    BOOL autoAim;
    BOOL wallHack;
    float fovSize;
    
    // ESP
    BOOL espEnabled;
    BOOL espBox;
    BOOL espLine;
    BOOL espSkeleton;
    float espDistance;
    UIColor *espColor;
    
    // Chức năng
    BOOL godMode;
    BOOL speedHack;
    float speedMultiplier;
    BOOL cameraBehind;
    BOOL killGranny;
    BOOL teleportItem;
    int selectedItemIndex;
    
    // Tài khoản
    NSString *userKey;
    NSString *userName;
    NSString *expiryDate;
    BOOL isKeyValid;
    
    // Touch detection
    int touchCount;
    CGPoint touchPositions[3];
    NSTimer *touchTimer;
}

@property (nonatomic, assign) BOOL godModeEnabled;
@property (nonatomic, assign) BOOL speedEnabled;
@property (nonatomic, assign) float speedMultiplier;
@property (nonatomic, assign) BOOL cameraBehind;

+ (instancetype)sharedInstance;
- (void)toggleMenu;

@end

// ====== IMPLEMENTATION ======
@implementation GrannyMod

@synthesize godModeEnabled = godMode;
@synthesize speedEnabled = speedHack;
@synthesize speedMultiplier = speedMultiplier;
@synthesize cameraBehind = cameraBehind;

+ (instancetype)sharedInstance {
    static GrannyMod *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GrannyMod alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        isOpen = NO;
        isAnimating = NO;
        
        // Default settings
        aimbotEnabled = NO;
        aimTarget = 0;
        autoAim = NO;
        wallHack = NO;
        fovSize = 150.0f;
        
        espEnabled = NO;
        espBox = YES;
        espLine = YES;
        espSkeleton = NO;
        espDistance = 100.0f;
        espColor = [UIColor redColor];
        
        godMode = NO;
        speedHack = NO;
        speedMultiplier = 2.0f;
        cameraBehind = NO;
        killGranny = NO;
        teleportItem = NO;
        selectedItemIndex = 0;
        
        userKey = @"";
        userName = @"";
        expiryDate = @"";
        isKeyValid = NO;
        
        [self setupMenu];
    }
    return self;
}

// ====== SETUP MENU ======
- (void)setupMenu {
    // Menu background
    menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MENU_WIDTH, MENU_HEIGHT)];
    menuView.center = self.center;
    menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    menuView.layer.cornerRadius = 20;
    menuView.layer.borderWidth = 2;
    menuView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8].CGColor;
    menuView.clipsToBounds = YES;
    menuView.hidden = YES;
    menuView.alpha = 0;
    menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self addSubview:menuView];
    
    // Header
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MENU_WIDTH, 50)];
    headerView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [menuView addSubview:headerView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 30)];
    titleLabel.text = @"🔥 GRANNY MOD MENU";
    titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [headerView addSubview:titleLabel];
    
    // Close button
    closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(MENU_WIDTH - 50, 10, 40, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:closeBtn];
    
    // Tab control
    NSArray *tabItems = @[@"Aimbot", @"ESP", @"Chức năng", @"Tài khoản"];
    tabControl = [[UISegmentedControl alloc] initWithItems:tabItems];
    tabControl.frame = CGRectMake(10, 55, MENU_WIDTH - 20, 35);
    tabControl.selectedSegmentIndex = 0;
    tabControl.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    tabControl.selectedSegmentTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [tabControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [menuView addSubview:tabControl];
    
    // Tab content
    tabContent = [[UIView alloc] initWithFrame:CGRectMake(10, 95, MENU_WIDTH - 20, MENU_HEIGHT - 120)];
    tabContent.backgroundColor = [UIColor clearColor];
    [menuView addSubview:tabContent];
    
    // Load first tab
    [self showTab:0];
}

// ====== TAB CHANGED ======
- (void)tabChanged:(UISegmentedControl *)sender {
    [self showTab:sender.selectedSegmentIndex];
}

- (void)showTab:(int)index {
    // Clear tab content
    for (UIView *view in tabContent.subviews) {
        [view removeFromSuperview];
    }
    
    switch (index) {
        case 0: [self drawAimbotTab]; break;
        case 1: [self drawESPTab]; break;
        case 2: [self drawChucNangTab]; break;
        case 3: [self drawTaiKhoanTab]; break;
    }
}

// ====== TAB: AIMBOT ======
- (void)drawAimbotTab {
    float y = 0;
    float spacing = 45;
    
    // Aimbot toggle
    UISwitch *aimbotSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:aimbotEnabled tag:100];
    [self addLabel:@"🔫 Aimbot" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:aimbotSwitch];
    y += spacing;
    
    // Auto aim toggle
    UISwitch *autoAimSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:autoAim tag:101];
    [self addLabel:@"🎯 Tự động ngắm" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:autoAimSwitch];
    y += spacing;
    
    // Wall hack toggle
    UISwitch *wallSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:wallHack tag:102];
    [self addLabel:@"🧱 Xuyên tường" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:wallSwitch];
    y += spacing;
    
    // Aim target
    [self addLabel:@"🎯 Vị trí ngắm:" frame:CGRectMake(0, y, 200, 30) toView:tabContent];
    y += 35;
    
    UISegmentedControl *targetSeg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Ngực", @"Cổ", @"Bụng"]];
    targetSeg.frame = CGRectMake(0, y, 300, 35);
    targetSeg.selectedSegmentIndex = aimTarget;
    targetSeg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    targetSeg.selectedSegmentTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [targetSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [targetSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [targetSeg addTarget:self action:@selector(targetChanged:) forControlEvents:UIControlEventValueChanged];
    [tabContent addSubview:targetSeg];
    y += spacing + 10;
    
    // FOV slider
    [self addLabel:[NSString stringWithFormat:@"📏 FOV: %.0f", fovSize] frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(150, y, 150, 30)];
    fovSlider.minimumValue = 30;
    fovSlider.maximumValue = 300;
    fovSlider.value = fovSize;
    [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [tabContent addSubview:fovSlider];
}

// ====== TAB: ESP ======
- (void)drawESPTab {
    float y = 0;
    float spacing = 45;
    
    // ESP toggle
    UISwitch *espSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:espEnabled tag:200];
    [self addLabel:@"👁️ ESP" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:espSwitch];
    y += spacing;
    
    // Box toggle
    UISwitch *boxSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:espBox tag:201];
    [self addLabel:@"📦 Box" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:boxSwitch];
    y += spacing;
    
    // Line toggle
    UISwitch *lineSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:espLine tag:202];
    [self addLabel:@"📏 Line" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:lineSwitch];
    y += spacing;
    
    // Skeleton toggle
    UISwitch *skeletonSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:espSkeleton tag:203];
    [self addLabel:@"🦴 Skeleton" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:skeletonSwitch];
    y += spacing;
    
    // Color button
    UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    colorBtn.frame = CGRectMake(0, y, 200, 35);
    [colorBtn setTitle:@"🎨 Chọn màu ESP" forState:UIControlStateNormal];
    colorBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    colorBtn.layer.cornerRadius = 10;
    [colorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [colorBtn addTarget:self action:@selector(chooseColor) forControlEvents:UIControlEventTouchUpInside];
    [tabContent addSubview:colorBtn];
    y += spacing + 10;
    
    // Distance slider
    [self addLabel:[NSString stringWithFormat:@"📡 Khoảng cách: %.0fm", espDistance] frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    UISlider *distSlider = [[UISlider alloc] initWithFrame:CGRectMake(150, y, 150, 30)];
    distSlider.minimumValue = 10;
    distSlider.maximumValue = 200;
    distSlider.value = espDistance;
    [distSlider addTarget:self action:@selector(distChanged:) forControlEvents:UIControlEventValueChanged];
    [tabContent addSubview:distSlider];
}

// ====== TAB: CHỨC NĂNG ======
- (void)drawChucNangTab {
    float y = 0;
    float spacing = 45;
    
    // God mode
    UISwitch *godSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:godMode tag:300];
    [self addLabel:@"🛡️ Bất tử" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:godSwitch];
    y += spacing;
    
    // Speed hack
    UISwitch *speedSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:speedHack tag:301];
    [self addLabel:@"⚡ Speed Hack" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:speedSwitch];
    y += spacing;
    
    // Speed slider
    [self addLabel:[NSString stringWithFormat:@"Tốc độ: %.1fx", speedMultiplier] frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(150, y, 150, 30)];
    speedSlider.minimumValue = 1.0;
    speedSlider.maximumValue = 10.0;
    speedSlider.value = speedMultiplier;
    [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [tabContent addSubview:speedSlider];
    y += spacing;
    
    // Camera behind
    UISwitch *camSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:cameraBehind tag:302];
    [self addLabel:@"📷 Camera sau lưng" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:camSwitch];
    y += spacing;
    
    // Kill Granny
    UISwitch *killSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:killGranny tag:303];
    [self addLabel:@"💀 Kill bà ngoại" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:killSwitch];
    y += spacing;
    
    // Teleport items
    UISwitch *teleSwitch = [self createSwitch:CGRectMake(180, y, 51, 31) value:teleportItem tag:304];
    [self addLabel:@"📦 Teleport vật phẩm" frame:CGRectMake(0, y, 150, 30) toView:tabContent];
    [tabContent addSubview:teleSwitch];
    y += spacing;
    
    // Item selection
    [self addLabel:@"Chọn vật phẩm:" frame:CGRectMake(0, y, 200, 30) toView:tabContent];
    y += 35;
    
    UISegmentedControl *itemSeg = [[UISegmentedControl alloc] initWithItems:@[@"Key", @"Búa", @"Đạn", @"Thuốc", @"Súng"]];
    itemSeg.frame = CGRectMake(0, y, 300, 35);
    itemSeg.selectedSegmentIndex = selectedItemIndex;
    itemSeg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    itemSeg.selectedSegmentTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [itemSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [itemSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [itemSeg addTarget:self action:@selector(itemChanged:) forControlEvents:UIControlEventValueChanged];
    [tabContent addSubview:itemSeg];
}

// ====== TAB: TÀI KHOẢN ======
- (void)drawTaiKhoanTab {
    float y = 0;
    float spacing = 45;
    
    [self addLabel:@"🔑 KEY:" frame:CGRectMake(0, y, 60, 30) toView:tabContent];
    
    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(70, y, 180, 35)];
    keyField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @"Nhập key...";
    keyField.text = userKey;
    keyField.layer.cornerRadius = 8;
    keyField.layer.borderWidth = 1;
    keyField.layer.borderColor = [UIColor grayColor].CGColor;
    [keyField addTarget:self action:@selector(keyChanged:) forControlEvents:UIControlEventEditingChanged];
    [tabContent addSubview:keyField];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    confirmBtn.frame = CGRectMake(260, y, 60, 35);
    [confirmBtn setTitle:@"✅" forState:UIControlStateNormal];
    confirmBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:0.5];
    confirmBtn.layer.cornerRadius = 8;
    [confirmBtn addTarget:self action:@selector(confirmKey) forControlEvents:UIControlEventTouchUpInside];
    [tabContent addSubview:confirmBtn];
    y += spacing + 10;
    
    [self addLabel:[NSString stringWithFormat:@"👤 User: %@", userName] frame:CGRectMake(0, y, 300, 30) toView:tabContent];
    y += spacing - 10;
    
    [self addLabel:[NSString stringWithFormat:@"⏳ Hết hạn: %@", expiryDate] frame:CGRectMake(0, y, 300, 30) toView:tabContent];
    y += spacing - 10;
    
    if (isKeyValid) {
        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 300, 30)];
        status.text = @"✅ Đã kích hoạt!";
        status.textColor = [UIColor greenColor];
        status.font = [UIFont boldSystemFontOfSize:16];
        [tabContent addSubview:status];
    } else {
        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 300, 30)];
        status.text = @"❌ Chưa kích hoạt!";
        status.textColor = [UIColor redColor];
        status.font = [UIFont boldSystemFontOfSize:16];
        [tabContent addSubview:status];
    }
}

// ====== UI HELPERS ======
- (UISwitch *)createSwitch:(CGRect)frame value:(BOOL)value tag:(int)tag {
    UISwitch *switchControl = [[UISwitch alloc] initWithFrame:frame];
    switchControl.on = value;
    switchControl.tag = tag;
    switchControl.onTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    return switchControl;
}

- (void)addLabel:(NSString *)text frame:(CGRect)frame toView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:16];
    [view addSubview:label];
}

// ====== SWITCH HANDLERS ======
- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 100: aimbotEnabled = sender.on; break;
        case 101: autoAim = sender.on; break;
        case 102: wallHack = sender.on; break;
        case 200: espEnabled = sender.on; break;
        case 201: espBox = sender.on; break;
        case 202: espLine = sender.on; break;
        case 203: espSkeleton = sender.on; break;
        case 300: godMode = sender.on; break;
        case 301: speedHack = sender.on; break;
        case 302: cameraBehind = sender.on; break;
        case 303: killGranny = sender.on; [self killGrannyNow]; break;
        case 304: teleportItem = sender.on; if (sender.on) [self teleportSelectedItem]; break;
    }
}

- (void)targetChanged:(UISegmentedControl *)sender {
    aimTarget = (int)sender.selectedSegmentIndex;
}

- (void)itemChanged:(UISegmentedControl *)sender {
    selectedItemIndex = (int)sender.selectedSegmentIndex;
}

- (void)fovChanged:(UISlider *)sender {
    fovSize = sender.value;
    [self refreshTab:0];
}

- (void)distChanged:(UISlider *)sender {
    espDistance = sender.value;
    [self refreshTab:1];
}

- (void)speedChanged:(UISlider *)sender {
    speedMultiplier = sender.value;
    [self refreshTab:2];
}

- (void)refreshTab:(int)index {
    [self showTab:index];
    tabControl.selectedSegmentIndex = index;
}

// ====== KEY FUNCTIONS ======
- (void)keyChanged:(UITextField *)sender {
    userKey = sender.text;
}

- (void)confirmKey {
    if ([userKey isEqualToString:@""]) {
        [self showAlert:@"⚠️" message:@"Vui lòng nhập key!"];
        return;
    }
    
    // MOCK - Thực tế gọi Firebase
    if ([userKey length] > 5) {
        isKeyValid = YES;
        userName = @"User_" + userKey;
        expiryDate = @"2026-12-31";
        [self showAlert:@"✅" message:@"Key hợp lệ!"];
        [self refreshTab:3];
    } else {
        [self showAlert:@"❌" message:@"Key không hợp lệ!"];
    }
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = [self topViewController];
    if (rootVC) [rootVC presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)topViewController {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    return rootVC;
}

// ====== COLOR PICKER ======
- (void)chooseColor {
    // Mở color picker (iOS 14+)
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
        picker.delegate = self;
        picker.selectedColor = espColor;
        UIViewController *rootVC = [self topViewController];
        if (rootVC) [rootVC presentViewController:picker animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    espColor = viewController.selectedColor;
    [self refreshTab:1];
}

// ====== CHỨC NĂNG GAME ======
- (void)killGrannyNow {
    // Tìm object Granny và kill
    // Cần dump game để biết class
    NSLog(@"💀 Killing Granny...");
}

- (void)teleportSelectedItem {
    // Teleport item được chọn về trước mặt
    NSArray *items = @[@"Key", @"Hammer", @"Ammo", @"Medkit", @"Weapon"];
    NSLog(@"📦 Teleport: %@", items[selectedItemIndex]);
}

// ====== TOUCH DETECTION (3 ngón) ======
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touches.count == 3) {
        touchCount = 0;
        for (UITouch *touch in touches) {
            if (touch.phase == UITouchPhaseBegan) {
                touchCount++;
            }
        }
        if (touchCount >= 3) {
            [self toggleMenu];
        }
    }
}

// ====== TOGGLE MENU ======
- (void)toggleMenu {
    if (isAnimating) return;
    isOpen = !isOpen;
    isAnimating = YES;
    
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        if (self->isOpen) {
            self->menuView.hidden = NO;
            self->menuView.alpha = 1;
            self->menuView.transform = CGAffineTransformIdentity;
        } else {
            self->menuView.alpha = 0;
            self->menuView.transform = CGAffineTransformMakeScale(0.7, 0.7);
        }
    } completion:^(BOOL finished) {
        if (!self->isOpen) {
            self->menuView.hidden = YES;
        }
        self->isAnimating = NO;
    }];
}

@end

// ====== ENTRY POINT (Tự động load) ======
__attribute__((constructor))
static void init() {
    dispatch_async(dispatch_get_main_queue(), ^{
        GrannyMod *menu = [GrannyMod sharedInstance];
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
        }
        if (keyWindow) {
            [keyWindow addSubview:menu];
            NSLog(@"🔥 GrannyMod loaded!");
        }
    });
}
