#import "PLRootViewController.h"
#import "PLHomeViewController.h"
#import "PLAccountsViewController.h"
#import "PLSettingsViewController.h"
#import "PLTheme.h"

@implementation PLRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLTheme canvas];

    PLHomeViewController *home = [[PLHomeViewController alloc] init];
    PLAccountsViewController *accounts = [[PLAccountsViewController alloc] init];
    PLSettingsViewController *settings = [[PLSettingsViewController alloc] init];

    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:home];
    UINavigationController *accountsNav = [[UINavigationController alloc] initWithRootViewController:accounts];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settings];

    for (UINavigationController *nav in @[homeNav, accountsNav, settingsNav]) {
        nav.navigationBar.prefersLargeTitles = YES;
        nav.navigationBar.tintColor = [PLTheme accent];
        UINavigationBarAppearance *barStyle = [[UINavigationBarAppearance alloc] init];
        [barStyle configureWithTransparentBackground];
        barStyle.backgroundColor = [[PLTheme canvas] colorWithAlphaComponent:0.92];
        barStyle.shadowColor = UIColor.clearColor;
        barStyle.titleTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]};
        barStyle.largeTitleTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:32 weight:UIFontWeightBold]};
        nav.navigationBar.standardAppearance = barStyle;
        nav.navigationBar.scrollEdgeAppearance = barStyle;
        nav.navigationBar.compactAppearance = barStyle;
    }

    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Instances"
                                                       image:[PLTheme symbol:@"square.stack.3d.up" pointSize:20 weight:UIFontWeightRegular]
                                               selectedImage:[PLTheme symbol:@"square.stack.3d.up.fill" pointSize:20 weight:UIFontWeightSemibold]];
    accountsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Accounts"
                                                          image:[PLTheme symbol:@"person.crop.circle" pointSize:20 weight:UIFontWeightRegular]
                                                  selectedImage:[PLTheme symbol:@"person.crop.circle.fill" pointSize:20 weight:UIFontWeightSemibold]];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings"
                                                          image:[PLTheme symbol:@"slider.horizontal.3" pointSize:20 weight:UIFontWeightRegular]
                                                  selectedImage:[PLTheme symbol:@"slider.horizontal.3" pointSize:20 weight:UIFontWeightSemibold]];

    self.viewControllers = @[homeNav, accountsNav, settingsNav];
    self.selectedIndex = 0;
    self.tabBar.tintColor = [PLTheme accent];
    self.tabBar.unselectedItemTintColor = [PLTheme secondaryText];

    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    appearance.shadowColor = UIColor.clearColor;

    NSMutableParagraphStyle *itemStyle = [NSMutableParagraphStyle new];
    itemStyle.alignment = NSTextAlignmentCenter;
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium],
        NSParagraphStyleAttributeName: itemStyle
    };
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold],
        NSParagraphStyleAttributeName: itemStyle
    };
    appearance.stackedLayoutAppearance.normal.iconColor = [PLTheme secondaryText];
    appearance.stackedLayoutAppearance.selected.iconColor = [PLTheme accent];

    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end