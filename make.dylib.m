#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Các biến trạng thái toàn cục
static BOOL isAimbotActive = NO;
static BOOL isEspActive = NO;
static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;
static BOOL isVietnamese = YES;

static UIWindow *menuWindow;
static UIView *menuContainer;
static UIViewController *rootVC;

// Lưu cấu hình
static void saveSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAimbotActive forKey:@"mod_aim"];
    [defaults setBool:isEspActive forKey:@"mod_esp"];
    [defaults setBool:isGodMode forKey:@"mod_god"];
    [defaults setBool:isHighSpeed forKey:@"mod_spd"];
    [defaults synchronize];
}

// Đọc cấu hình
static void loadSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isAimbotActive = [defaults boolForKey:@"mod_aim"];
    isEspActive = [defaults boolForKey:@"mod_esp"];
    isGodMode = [defaults boolForKey:@"mod_god"];
    isHighSpeed = [defaults boolForKey:@"mod_spd"];
}

// Reset tất cả chức năng
static void resetAllFeatures() {
    isAimbotActive = NO;
    isEspActive = NO;
    isGodMode = NO;
    isHighSpeed = NO;
    saveSettings();
}

@interface HuyModMenu : UIViewController
@end

@implementation HuyModMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Nền đen mờ phía sau (optional)
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    dimView.userInteractionEnabled = NO;
    [self.view addSubview:dimView];
    
    // Khung menu
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(50, 100, 300, 420)];
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    menuContainer.layer.cornerRadius = 15;
    menuContainer.layer.borderWidth = 1;
    menuContainer.layer.borderColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.6].CGColor;
    [self.view addSubview:menuContainer];
    
    // Tiêu đề
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 30)];
    titleLbl.text = @"🔥 HUY MOD MENU";
    titleLbl.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1];
    titleLbl.font = [UIFont boldSystemFontOfSize:18];
    [menuContainer addSubview:titleLbl];
    
    // Nút X - chỉ ẩn menu chứ không tắt chức năng
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(260, 10, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:closeBtn];
    
    // Y: 50 - Switch Aimbot
    UISwitch *aimSw = [[UISwitch alloc] initWithFrame:CGRectMake(20, 50, 51, 31)];
    aimSw.on = isAimbotActive;
    aimSw.onTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [aimSw addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:aimSw];
    UILabel *aimLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 50, 200, 30)];
    aimLbl.text = @"Aimbot";
    aimLbl.textColor = [UIColor whiteColor];
    aimLbl.font = [UIFont systemFontOfSize:16];
    [menuContainer addSubview:aimLbl];
    
    // Y: 100 - Switch ESP
    UISwitch *espSw = [[UISwitch alloc] initWithFrame:CGRectMake(20, 100, 51, 31)];
    espSw.on = isEspActive;
    espSw.onTintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:0.8];
    [espSw addTarget:self action:@selector(toggleEsp:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:espSw];
    UILabel *espLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 100, 200, 30)];
    espLbl.text = @"ESP";
    espLbl.textColor = [UIColor whiteColor];
    espLbl.font = [UIFont systemFontOfSize:16];
    [menuContainer addSubview:espLbl];
    
    // Y: 150 - Switch God Mode
    UISwitch *godSw = [[UISwitch alloc] initWithFrame:CGRectMake(20, 150, 51, 31)];
    godSw.on = isGodMode;
    godSw.onTintColor = [UIColor colorWithRed:0.2 green:0.4 blue:1.0 alpha:0.8];
    [godSw addTarget:self action:@selector(toggleGod:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:godSw];
    UILabel *godLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 150, 200, 30)];
    godLbl.text = @"God Mode";
    godLbl.textColor = [UIColor whiteColor];
    godLbl.font = [UIFont systemFontOfSize:16];
    [menuContainer addSubview:godLbl];
    
    // Y: 200 - Switch High Speed
    UISwitch *spdSw = [[UISwitch alloc] initWithFrame:CGRectMake(20, 200, 51, 31)];
    spdSw.on = isHighSpeed;
    spdSw.onTintColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:0.8];
    [spdSw addTarget:self action:@selector(toggleSpeed:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:spdSw];
    UILabel *spdLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 200, 200, 30)];
    spdLbl.text = @"High Speed";
    spdLbl.textColor = [UIColor whiteColor];
    spdLbl.font = [UIFont systemFontOfSize:16];
    [menuContainer addSubview:spdLbl];
    
    // Separator line
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, 245, 260, 1)];
    line.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
    [menuContainer addSubview:line];
    
    // Label "Tài Khoản" - Y: 260
    UILabel *accLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 260, 200, 25)];
    accLbl.text = @"📱 TÀI KHOẢN";
    accLbl.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1];
    accLbl.font = [UIFont boldSystemFontOfSize:15];
    [menuContainer addSubview:accLbl];
    
    // Y: 290 - Nút Lưu Setting
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(50, 290, 200, 40);
    [saveBtn setTitle:@"💾 LƯU SETTING" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:0.8];
    saveBtn.layer.cornerRadius = 10;
    saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [saveBtn addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:saveBtn];
    
    // Y: 340 - Nút Reset (Tắt tất cả)
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(50, 340, 200, 40);
    [resetBtn setTitle:@"🔴 TẮT TẤT CẢ" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.8];
    resetBtn.layer.cornerRadius = 10;
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [resetBtn addTarget:self action:@selector(resetPressed) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:resetBtn];
    
    // Version
    UILabel *verLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 390, 260, 20)];
    verLbl.text = @"Version 1.0 | Huy Mod";
    verLbl.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    verLbl.font = [UIFont systemFontOfSize:11];
    verLbl.textAlignment = NSTextAlignmentCenter;
    [menuContainer addSubview:verLbl];
}

- (void)toggleAim:(UISwitch *)sw { 
    isAimbotActive = sw.on; 
    NSLog(@"🔫 Aimbot: %@", isAimbotActive ? @"ON" : @"OFF");
}

- (void)toggleEsp:(UISwitch *)sw { 
    isEspActive = sw.on; 
    NSLog(@"👁️ ESP: %@", isEspActive ? @"ON" : @"OFF");
}

- (void)toggleGod:(UISwitch *)sw { 
    isGodMode = sw.on; 
    NSLog(@"🛡️ God Mode: %@", isGodMode ? @"ON" : @"OFF");
}

- (void)toggleSpeed:(UISwitch *)sw { 
    isHighSpeed = sw.on; 
    NSLog(@"⚡ High Speed: %@", isHighSpeed ? @"ON" : @"OFF");
}

- (void)hideMenu { 
    // CHỈ ẨN menu, KHÔNG TẮT chức năng
    menuWindow.hidden = YES; 
    NSLog(@"📱 Menu hidden - features still active");
}

- (void)savePressed {
    saveSettings();
    NSLog(@"💾 Settings saved!");
    
    // Thông báo đã lưu
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅ Thành công" 
                                                                   message:@"Đã lưu cấu hình!" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetPressed {
    resetAllFeatures();
    
    // Cập nhật lại UI các switch
    for (UIView *view in menuContainer.subviews) {
        if ([view isKindOfClass:[UISwitch class]]) {
            UISwitch *sw = (UISwitch *)view;
            sw.on = NO;
        }
    }
    
    NSLog(@"🔴 All features reset!");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔄 Đã tắt" 
                                                                   message:@"Tất cả chức năng đã được tắt!" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // Chạm bên ngoài menu cũng ẩn menu (tùy chọn)
}

@end

// Hàm mở menu
void showMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!menuWindow) {
            menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuWindow.windowLevel = UIWindowLevelAlert + 1;
            menuWindow.backgroundColor = [UIColor clearColor];
            menuWindow.rootViewController = [[HuyModMenu alloc] init];
            menuWindow.userInteractionEnabled = YES;
        }
        menuWindow.hidden = NO;
        NSLog(@"📱 Menu opened!");
    });
}

// Hàm setup gesture - nhấp 3 ngón vào màn hình 2 lần
static void setupGestures() {
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    if (!win) {
        win = [[[UIApplication sharedApplication] windows] firstObject];
    }
    if (!win) return;
    
    // Xóa gesture cũ nếu có
    for (UIGestureRecognizer *gr in win.gestureRecognizers) {
        if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gr;
            if (tap.numberOfTouchesRequired == 3 && tap.numberOfTapsRequired == 2) {
                [win removeGestureRecognizer:gr];
            }
        }
    }
    
    // Tạo gesture mới: 3 ngón, chạm 2 lần
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:@selector(showMenu)];
    tap.numberOfTouchesRequired = 3;
    tap.numberOfTapsRequired = 2;
    [win addGestureRecognizer:tap];
    
    NSLog(@"👆 Gesture set: 3 fingers, 2 taps");
}

// Hàm khởi tạo khi load dylib
__attribute__((constructor)) static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Load settings từ bộ nhớ
        loadSettings();
        
        // Reset toàn bộ chức năng về OFF khi khởi động
        resetAllFeatures();
        
        // Setup gesture
        setupGestures();
        
        NSLog(@"🔥 Huy Mod loaded! All features OFF by default.");
    });
}
