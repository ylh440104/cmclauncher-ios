#import "PLRootViewController.h"
#import "PLHomeViewController.h"
#import "PLAccountsViewController.h"
#import "PLSettingsViewController.h"

@implementation PLRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    PLHomeViewController *home = [[PLHomeViewController alloc] init];
    PLAccountsViewController *accounts = [[PLAccountsViewController alloc] init];
    PLSettingsViewController *settings = [[PLSettingsViewController alloc] init];

    UIViewController *homeNav = [[UINavigationController alloc] initWithRootViewController:home];
    UIViewController *accountsNav = [[UINavigationController alloc] initWithRootViewController:accounts];
    UIViewController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settings];

    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage systemImageNamed:@"square.grid.2x2"] selectedImage:[UIImage systemImageNamed:@"square.grid.2x2.fill"]];
    accountsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Accounts" image:[UIImage systemImageNamed:@"person.crop.circle"] selectedImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] selectedImage:[UIImage systemImageNamed:@"gearshape.fill"]];

    self.viewControllers = @[homeNav, accountsNav, settingsNav];
    self.selectedIndex = 0;

    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end