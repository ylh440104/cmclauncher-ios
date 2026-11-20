#import "PLTheme.h"

static UIColor *PLColor(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0];
}

static UIColor *PLDynamic(UIColor *light, UIColor *dark) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light;
    }];
}

@implementation PLTheme

+ (UIColor *)accent {
    return PLDynamic(PLColor(47, 107, 214), PLColor(96, 148, 244));
}

+ (UIColor *)accentSoft {
    return PLDynamic(PLColor(232, 240, 254), PLColor(30, 48, 78));
}

+ (UIColor *)canvas {
    return PLDynamic(PLColor(244, 246, 249), PLColor(12, 14, 18));
}

+ (UIColor *)card {
    return PLDynamic(PLColor(255, 255, 255), PLColor(26, 29, 36));
}

+ (UIColor *)hairline {
    return PLDynamic(PLColor(233, 236, 241), PLColor(42, 46, 55));
}

+ (UIColor *)primaryText {
    return PLDynamic(PLColor(18, 21, 27), PLColor(240, 242, 246));
}

+ (UIColor *)secondaryText {
    return PLDynamic(PLColor(122, 130, 145), PLColor(140, 148, 162));
}

+ (UIColor *)badgeFill {
    return PLDynamic(PLColor(240, 243, 248), PLColor(36, 40, 49));
}

+ (UIColor *)success {
    return PLDynamic(PLColor(38, 158, 96), PLColor(72, 190, 124));
}

+ (UIColor *)warning {
    return PLDynamic(PLColor(214, 138, 30), PLColor(238, 172, 72));
}

+ (UIFont *)displayFont {
    UIFontDescriptor *base = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleLargeTitle];
    return [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
}

+ (UIFont *)titleFont {
    return [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
}

+ (UIFont *)headlineFont {
    return [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
}

+ (UIFont *)bodyFont {
    return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
}

+ (UIFont *)monoFont {
    UIFont *base = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
    return base;
}

+ (UIFont *)captionFont {
    return [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
}

+ (CGFloat)radius {
    return 16.0;
}

+ (CGFloat)radiusSmall {
    return 9.0;
}

+ (CGFloat)gutter {
    return 18.0;
}

+ (CGFloat)cardPadding {
    return 16.0;
}

+ (void)applyCardStyle:(UIView *)view {
    view.backgroundColor = [self card];
    view.layer.cornerRadius = [self radius];
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.shadowColor = UIColor.blackColor.CGColor;
    view.layer.shadowOpacity = 0.05;
    view.layer.shadowRadius = 14.0;
    view.layer.shadowOffset = CGSizeMake(0, 4);
}

+ (void)applyPillStyle:(UILabel *)label color:(UIColor *)color {
    label.font = [self captionFont];
    label.textColor = color;
    label.backgroundColor = [color colorWithAlphaComponent:0.12];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7.0;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.layer.masksToBounds = YES;
}

+ (UIImage *)symbol:(NSString *)name pointSize:(CGFloat)size weight:(UIFontWeight)weight {
    UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:size weight:weight];
    return [UIImage systemImageNamed:name withConfiguration:config];
}

+ (UIImage *)symbol:(NSString *)name pointSize:(CGFloat)size {
    return [self symbol:name pointSize:size weight:UIFontWeightSemibold];
}

@end