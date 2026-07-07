#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ====== BIẾN TOÀN CỤC ======
static UIWindow *menuWindow = nil;
static BOOL isMenuVisible = NO;

// ====== VIEW CONTROLLER ======
@interface ModMenuVC : UIViewController
@end

@implementation ModMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Nền đen mờ
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self.view addSubview:dimView];
    
    // MENU
    UIView *menu = [[UIView alloc] initWithFrame:CGRectMake(30, 80, 340, 480)];
    menu.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    menu.layer.cornerRadius = 20;
    menu.layer.borderWidth = 2;
    menu.layer.borderColor = [UIColor redColor].CGColor;
    [self.view addSubview:menu];
    
    // ====== HEADER ======
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 100)];
    header.backgroundColor = [UIColor blackColor];
    [menu addSubview:header];
    
    // LOGO ANONYMOUS
    UILabel *l1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, 340, 20)];
    l1.text = @"WE DO NOT FORGIVE.";
    l1.textColor = [UIColor grayColor];
    l1.font = [UIFont systemFontOfSize:13];
    l1.textAlignment = NSTextAlignmentCenter;
    [header addSubview:l1];
    
    UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, 340, 20)];
    l2.text = @"WE DO NOT FORGET.";
    l2.textColor = [UIColor grayColor];
    l2.font = [UIFont systemFontOfSize:13];
    l2.textAlignment = NSTextAlignmentCenter;
    [header addSubview:l2];
    
    UILabel *l3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 48, 340, 30)];
    l3.text = @"A N O N Y M O U S";
    l3.textColor = [UIColor whiteColor];
    l3.font = [UIFont boldSystemFontOfSize:22];
    l3.textAlignment = NSTextAlignmentCenter;
    [header addSubview:l3];
    
    UILabel *l4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 78, 340, 15)];
    l4.text = @"WE ARE LEGION.";
    l4.textColor = [UIColor darkGrayColor];
    l4.font = [UIFont systemFontOfSize:11];
    l4.textAlignment = NSTextAlignmentCenter;
    [header addSubview:l4];
    
    // Nút X
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(300, 5, 35, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];
    
    // ====== NỘI DUNG ======
    int y = 120;
    
    // Aimbot
    UISwitch *sw1 = [[UISwitch alloc] initWithFrame:CGRectMake(260, y, 51, 31)];
    sw1.onTintColor = [UIColor redColor];
    [menu addSubview:sw1];
    UILabel *lb1 = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 30)];
    lb1.text = @"🔫 Aimbot";
    lb1.textColor = [UIColor whiteColor];
    [menu addSubview:lb1];
    y += 50;
    
    // ESP
    UISwitch *sw2 = [[UISwitch alloc] initWithFrame:CGRectMake(260, y, 51, 31)];
    sw2.onTintColor = [UIColor redColor];
    [menu addSubview:sw2];
    UILabel *lb2 = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 30)];
    lb2.text = @"👁️ ESP";
    lb2.textColor = [UIColor whiteColor];
    [menu addSubview:lb2];
    y += 50;
    
    // God Mode
    UISwitch *sw3 = [[UISwitch alloc] initWithFrame:CGRectMake(260, y, 51, 31)];
    sw3.onTintColor = [UIColor redColor];
    [menu addSubview:sw3];
    UILabel *lb3 = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 30)];
    lb3.text = @"🛡️ Bất tử";
    lb3.textColor = [UIColor whiteColor];
    [menu addSubview:lb3];
    y += 50;
    
    // Speed
    UISwitch *sw4 = [[UISwitch alloc] initWithFrame:CGRectMake(260, y, 51, 31)];
    sw4.onTintColor = [UIColor redColor];
    [menu addSubview:sw4];
    UILabel *lb4 = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 30)];
    lb4.text = @"⚡ Speed";
    lb4.textColor = [UIColor whiteColor];
    [menu addSubview:lb4];
    y += 50;
    
    // Nút Lưu
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(30, y + 20, 280, 45);
    [saveBtn setTitle:@"💾 LƯU SETTING" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8];
    saveBtn.layer.cornerRadius = 10;
    [saveBtn addTarget:self action:@selector(saveSetting) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:saveBtn];
    y += 70;
    
    // Nút Reset
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(30, y + 10, 280, 45);
    [resetBtn setTitle:@"🔴 TẮT TẤT CẢ" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:0.8];
    resetBtn.layer.cornerRadius = 10;
    [resetBtn addTarget:self action:@selector(resetAll) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:resetBtn];
    
    // Footer
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 450, 340, 20)];
    footer.text = @"Granny Mod | Anonymous";
    footer.textColor = [UIColor grayColor];
    footer.font = [UIFont systemFontOfSize:11];
    footer.textAlignment = NSTextAlignmentCenter;
    [menu addSubview:footer];
}

- (void)closeMenu {
    menuWindow.hidden = YES;
    isMenuVisible = NO;
}

- (void)saveSetting {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅" message:@"Đã lưu!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetAll {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔄" message:@"Đã tắt hết!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

// ====== HÀM MỞ MENU ======
void showMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isMenuVisible) {
            return;
        }
        
        if (!menuWindow) {
            menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuWindow.windowLevel = UIWindowLevelAlert + 1;
            menuWindow.backgroundColor = [UIColor clearColor];
            menuWindow.rootViewController = [[ModMenuVC alloc] init];
            menuWindow.userInteractionEnabled = YES;
        }
        menuWindow.hidden = NO;
        isMenuVisible = YES;
        NSLog(@"✅ MENU HIEN RA ROI!");
    });
}

// ====== CONSTRUCTOR - TỰ ĐỘNG CHẠY ======
__attribute__((constructor)) static void init() {
    NSLog(@"🔥 Granny Mod Loading...");
    
    // Đợi 3 giây rồi hiện menu
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showMenu();
        NSLog(@"✅ Granny Mod Ready!");
    });
}
