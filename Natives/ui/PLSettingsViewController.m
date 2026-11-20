#import "PLSettingsViewController.h"
#import "PLTheme.h"
#import "PLCore.h"
#import "LauncherPreferences.h"

@class PLSettingRow;

@protocol PLSettingRowDelegate <NSObject>
- (void)settingRowTapped:(PLSettingRow *)row;
- (void)settingRowSwitched:(PLSettingRow *)row value:(BOOL)value;
@end

@interface PLSettingRow : UIView
@property(nonatomic, weak) id<PLSettingRowDelegate> delegate;
@property(nonatomic, copy) NSString *key;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *valueLabel;
@property(nonatomic) UISwitch *toggle;
@property(nonatomic) UIImageView *chevron;
- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title key:(NSString *)key;
- (void)setValueText:(NSString *)text;
- (void)setToggleValue:(BOOL)on;
- (void)hideSeparator:(BOOL)hidden;
@end

@implementation PLSettingRow {
    UIView *_separator;
}

- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title key:(NSString *)key {
    self = [super initWithFrame:CGRectZero];
    if (!self) {
        return nil;
    }
    self.key = key;
    self.backgroundColor = UIColor.clearColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *iconBox = [[UIView alloc] initWithFrame:CGRectZero];
    iconBox.translatesAutoresizingMaskIntoConstraints = NO;
    iconBox.backgroundColor = [PLTheme accentSoft];
    iconBox.layer.cornerRadius = 7.0;
    iconBox.layer.cornerCurve = kCACornerCurveContinuous;
    [self addSubview:iconBox];

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[PLTheme symbol:icon pointSize:14 weight:UIFontWeightSemibold]];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.tintColor = [PLTheme accent];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [iconBox addSubview:iconView];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = title;
    _titleLabel.font = [PLTheme bodyFont];
    _titleLabel.textColor = [PLTheme primaryText];
    [self addSubview:_titleLabel];

    _valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    _valueLabel.textColor = [PLTheme secondaryText];
    _valueLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:_valueLabel];

    _chevron = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"chevron.right" pointSize:12 weight:UIFontWeightSemibold]];
    _chevron.translatesAutoresizingMaskIntoConstraints = NO;
    _chevron.tintColor = [PLTheme secondaryText];
    _chevron.contentMode = UIViewContentModeScaleAspectFit;
    _chevron.hidden = YES;
    [self addSubview:_chevron];

    _toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    _toggle.translatesAutoresizingMaskIntoConstraints = NO;
    _toggle.onTintColor = [PLTheme accent];
    _toggle.hidden = YES;
    [_toggle addTarget:self action:@selector(onSwitch) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_toggle];

    _separator = [[UIView alloc] initWithFrame:CGRectZero];
    _separator.translatesAutoresizingMaskIntoConstraints = NO;
    _separator.backgroundColor = [PLTheme hairline];
    [self addSubview:_separator];

    [NSLayoutConstraint activateConstraints:@[
        [self.heightAnchor constraintEqualToConstant:54],

        [iconBox.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
        [iconBox.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [iconBox.widthAnchor constraintEqualToConstant:28],
        [iconBox.heightAnchor constraintEqualToConstant:28],

        [iconView.centerXAnchor constraintEqualToAnchor:iconBox.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:iconBox.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:16],
        [iconView.heightAnchor constraintEqualToConstant:16],

        [_titleLabel.leadingAnchor constraintEqualToAnchor:iconBox.trailingAnchor constant:12],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_valueLabel.trailingAnchor constraintEqualToAnchor:_chevron.leadingAnchor constant:-8],
        [_valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:10],

        [_chevron.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_chevron.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_chevron.widthAnchor constraintEqualToConstant:8],
        [_chevron.heightAnchor constraintEqualToConstant:13],

        [_toggle.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [_toggle.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_separator.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_separator.heightAnchor constraintEqualToConstant:1]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self addGestureRecognizer:tap];
    return self;
}

- (void)onTap {
    if (!self.toggle.hidden) {
        return;
    }
    [self.delegate settingRowTapped:self];
}

- (void)onSwitch {
    [self.delegate settingRowSwitched:self value:self.toggle.isOn];
}

- (void)setValueText:(NSString *)text {
    self.valueLabel.text = text;
    self.chevron.hidden = text == nil;
}

- (void)setToggleValue:(BOOL)on {
    self.toggle.hidden = NO;
    self.valueLabel.hidden = YES;
    self.chevron.hidden = YES;
    self.toggle.on = on;
}

- (void)hideSeparator:(BOOL)hidden {
    _separator.hidden = hidden;
}

- (void)setHighlightedBackground:(BOOL)on {
    self.backgroundColor = on ? [[PLTheme secondaryText] colorWithAlphaComponent:0.06] : UIColor.clearColor;
}

@end

@interface PLSettingsViewController () <PLSettingRowDelegate>
@property(nonatomic) UIScrollView *scrollView;
@property(nonatomic) NSArray<PLSettingRow *> *rows;
@property(nonatomic) PLSettingRow *memoryRow;
@property(nonatomic) PLSettingRow *argsRow;
@property(nonatomic) PLSettingRow *rendererRow;
@property(nonatomic) PLSettingRow *runtimeRow;
@property(nonatomic) PLSettingRow *loggingRow;
@property(nonatomic) PLSettingRow *directoryRow;
@end

@implementation PLSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLTheme canvas];
    self.navigationItem.title = @"Settings";

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.scrollView.contentLayoutGuide.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]
    ]];

    self.memoryRow = [[PLSettingRow alloc] initWithIcon:@"memorychip" title:@"Memory" key:@"java.allocated_memory"];
    self.argsRow = [[PLSettingRow alloc] initWithIcon:@"terminal" title:@"JVM arguments" key:@"java.java_args"];
    self.runtimeRow = [[PLSettingRow alloc] initWithIcon:@"cup.and.saucer" title:@"Java runtime" key:nil];
    self.rendererRow = [[PLSettingRow alloc] initWithIcon:@"cpu" title:@"Renderer" key:@"video.renderer"];
    self.loggingRow = [[PLSettingRow alloc] initWithIcon:@"doc.text.magnifyingglass" title:@"Verbose logging" key:@"general.debug_logging"];
    self.directoryRow = [[PLSettingRow alloc] initWithIcon:@"folder" title:@"Game directory" key:nil];

    for (PLSettingRow *row in @[self.memoryRow, self.argsRow, self.runtimeRow, self.rendererRow, self.loggingRow, self.directoryRow]) {
        row.delegate = self;
    }

    NSMutableArray *all = [NSMutableArray array];
    CGFloat y = 8.0;
    y = [self addSection:@"JAVA" rows:@[self.memoryRow, self.argsRow, self.runtimeRow] atY:y];
    y = [self addSection:@"VIDEO" rows:@[self.rendererRow] atY:y];
    y = [self addSection:@"DEBUG" rows:@[self.loggingRow] atY:y];
    y = [self addSection:@"STORAGE" rows:@[self.directoryRow] atY:y];
    [all addObjectsFromArray:@[self.memoryRow, self.argsRow, self.runtimeRow, self.rendererRow, self.loggingRow, self.directoryRow]];
    self.rows = all;

    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *version = [[UILabel alloc] initWithFrame:CGRectZero];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = @"CMCLauncher";
    version.font = [PLTheme captionFont];
    version.textColor = [PLTheme secondaryText];
    version.textAlignment = NSTextAlignmentCenter;
    [footer addSubview:version];
    [self.scrollView addSubview:footer];

    [NSLayoutConstraint activateConstraints:@[
        [footer.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:y],
        [footer.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [footer.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [footer.heightAnchor constraintEqualToConstant:70],
        [version.centerXAnchor constraintEqualToAnchor:footer.centerXAnchor],
        [version.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor]
    ]];

    [self refreshValues];
}

- (CGFloat)addSection:(NSString *)title rows:(NSArray<PLSettingRow *> *)rows atY:(CGFloat)y {
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectZero];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.text = title;
    header.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    header.textColor = [PLTheme secondaryText];
    [self.scrollView addSubview:header];

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [PLTheme applyCardStyle:card];
    card.layer.masksToBounds = NO;
    [self.scrollView addSubview:card];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:y],
        [header.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:[PLTheme gutter] + 4],
        [card.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [card.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:[PLTheme gutter]],
        [card.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-[PLTheme gutter]]
    ]];

    UIView *previous = nil;
    for (NSUInteger i = 0; i < rows.count; i++) {
        PLSettingRow *row = rows[i];
        [card addSubview:row];
        [NSLayoutConstraint activateConstraints:@[
            [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor]
        ]];
        if (previous) {
            [row.topAnchor constraintEqualToAnchor:previous.bottomAnchor].active = YES;
        } else {
            [row.topAnchor constraintEqualToAnchor:card.topAnchor].active = YES;
        }
        [row hideSeparator:(i == rows.count - 1)];
        previous = row;
    }
    if (previous) {
        [previous.bottomAnchor constraintEqualToAnchor:card.bottomAnchor].active = YES;
    }

    CGFloat cardHeight = 54.0 * rows.count;
    return y + 22 + 8 + cardHeight + 22;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshValues];
}

- (void)refreshValues {
    [self.memoryRow setValueText:[NSString stringWithFormat:@"%ld MB", (long)getPrefInt(@"java.allocated_memory")]];
    NSString *args = getPrefObject(@"java.java_args");
    [self.argsRow setValueText:(args.length > 0 ? args : @"default")];

    NSArray<NSString *> *majors = plc_installed_java_majors();
    [self.runtimeRow setValueText:(majors.count > 0 ? [majors componentsJoinedByString:@", "] : @"none")];
    [self.rendererRow setValueText:(getPrefObject(@"video.renderer") ?: @"auto")];
    [self.loggingRow setToggleValue:getPrefBool(@"general.debug_logging")];
    [self.directoryRow setValueText:@"open"];
}

- (void)settingRowSwitched:(PLSettingRow *)row value:(BOOL)value {
    if (row == self.loggingRow) {
        setPrefBool(@"general.debug_logging", value);
    }
}

- (void)settingRowTapped:(PLSettingRow *)row {
    if (row == self.memoryRow) {
        [self promptNumber:@"Memory" message:@"Allocated heap in MB" current:getPrefInt(@"java.allocated_memory") minimum:128 apply:^(NSInteger value) {
            setPrefInt(@"java.allocated_memory", value);
        }];
    } else if (row == self.argsRow) {
        [self promptText:@"JVM arguments" current:getPrefObject(@"java.java_args") apply:^(NSString *text) {
            setPrefObject(@"java.java_args", text ?: @"");
        }];
    } else if (row == self.rendererRow) {
        [self promptRenderer];
    } else if (row == self.directoryRow) {
        NSURL *url = [NSURL fileURLWithPath:plc_game_dir()];
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeOpen];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)promptNumber:(NSString *)title message:(NSString *)message current:(NSInteger)current minimum:(NSInteger)minimum apply:(void (^)(NSInteger))apply {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.text = [NSString stringWithFormat:@"%ld", (long)current];
    }];
    __weak PLSettingsViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSInteger value = alert.textFields.firstObject.text.integerValue;
        apply(MAX(value, minimum));
        [weakSelf refreshValues];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptText:(NSString *)title current:(NSString *)current apply:(void (^)(NSString *))apply {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = current;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak PLSettingsViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        apply(alert.textFields.firstObject.text);
        [weakSelf refreshValues];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptRenderer {
    NSArray *keys = getRendererKeys(NO);
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Renderer" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak PLSettingsViewController *weakSelf = self;
    for (NSString *key in keys) {
        [sheet addAction:[UIAlertAction actionWithTitle:key style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            setPrefObject(@"video.renderer", key);
            [weakSelf refreshValues];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1);
    [self presentViewController:sheet animated:YES completion:nil];
}

@end