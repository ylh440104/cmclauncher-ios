#import "SceneDelegate.h"
#import "UIKit+hook.h"
#import "ui/PLRootViewController.h"

extern __weak UIWindow *mainWindow;

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    mainWindow = self.window;
    self.window.rootViewController = [[PLRootViewController alloc] init];
    [self.window makeKeyAndVisible];
}

@end