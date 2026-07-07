
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Các biến trạng thái toàn cục (luôn sống sót khi đóng/mở menu)
static BOOL isAimbotActive = NO;
static BOOL isEspActive = NO;
static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;
static BOOL isVietnamese = YES;

static UIWindow *menuWindow;
static UIView *menuContainer;

// Lưu cấu hình
static void saveSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAimbotActive forKey:@"mod_aim"];
    [defaults setBool:isEspActive forKey:@"mod_esp"];
    [defaults setBool:isGodMode forKey:@"mod_god"];
    [defaults setBool:isHighSpeed forKey:@"mod_spd"];
    [defaults synchronize];
}

@interface HuyModMenu : UIViewController
@end

@implementation HuyModMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Khung menu
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 300, 400)];
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    menuContainer.layer.cornerRadius = 15;
    [self.view addSubview:menuContainer];
    
    // Nút X
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(260, 10, 30, 30);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:closeBtn];
    
    // Switch Aimbot
    UISwitch *aimSw = [[UISwitch alloc] initWithFrame:CGRectMake(20, 50, 50, 30)];
    aimSw.on = isAimbotActive;
    [aimSw addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:aimSw];
    UILabel *aimLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 50, 200, 30)];
    aimLbl.text = @"Aimbot";
    aimLbl.textColor = [UIColor whiteColor];
    [menuContainer addSubview:aimLbl];
    
    // Nút Lưu
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(50, 350, 200, 40);
    [saveBtn setTitle:@"LƯU CẤU HÌNH" forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:saveBtn];
}

- (void)toggleAim:(UISwitch *)sw { isAimbotActive = sw.on; }
- (void)hideMenu { menuWindow.hidden = YES; }
- (void)savePressed { saveSettings(); }

@end

// Khởi tạo
static void setupGestures() {
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:@selector(showMenu)];
    tap.numberOfTouchesRequired = 3;
    tap.numberOfTapsRequired = 2;
    [win addGestureRecognizer:tap];
}

void showMenu() {
    if (!menuWindow) {
        menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        menuWindow.windowLevel = UIWindowLevelAlert;
        menuWindow.rootViewController = [[HuyModMenu alloc] init];
    }
    menuWindow.hidden = NO;
}

__attribute__((constructor)) static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
    });
}


