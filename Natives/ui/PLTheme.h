#import <UIKit/UIKit.h>

@interface PLTheme : NSObject

+ (UIColor *)accent;
+ (UIColor *)accentSoft;
+ (UIColor *)canvas;
+ (UIColor *)card;
+ (UIColor *)hairline;
+ (UIColor *)primaryText;
+ (UIColor *)secondaryText;
+ (UIColor *)badgeFill;
+ (UIColor *)success;
+ (UIColor *)warning;

+ (UIFont *)displayFont;
+ (UIFont *)titleFont;
+ (UIFont *)headlineFont;
+ (UIFont *)bodyFont;
+ (UIFont *)monoFont;
+ (UIFont *)captionFont;

+ (CGFloat)radius;
+ (CGFloat)radiusSmall;
+ (CGFloat)gutter;
+ (CGFloat)cardPadding;

+ (void)applyCardStyle:(UIView *)view;
+ (void)applyPillStyle:(UILabel *)label color:(UIColor *)color;
+ (UIImage *)symbol:(NSString *)name pointSize:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIImage *)symbol:(NSString *)name pointSize:(CGFloat)size;

@end