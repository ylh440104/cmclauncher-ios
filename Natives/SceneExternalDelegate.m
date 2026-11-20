#import "SceneExternalDelegate.h"

extern __weak UIWindow *externalWindow;

@implementation SceneExternalDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    externalWindow = self.window;
    self.window.rootViewController = [[UIViewController alloc] init];
}

@end