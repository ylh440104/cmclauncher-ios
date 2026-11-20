#import <Foundation/Foundation.h>

@interface PLJavaVM : NSObject

+ (BOOL)isRunning;
+ (BOOL)prepareEnvironmentWithError:(NSError **)error;
+ (int)launchWithUsername:(NSString *)username
                 versionId:(NSString *)versionId
                   width:(int)width
                  height:(int)height
              javaVersion:(int)javaVersion;

@end