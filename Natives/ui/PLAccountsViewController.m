#import "PLAccountsViewController.h"
#import "PLTheme.h"
#import "PLCore.h"
#import "LauncherPreferences.h"
#import "authenticator/BaseAuthenticator.h"

@interface PLAccountCell : UITableViewCell
@property(nonatomic) UIView *card;
@property(nonatomic) UIView *avatar;
@property(nonatomic) UILabel *initial;
@property(nonatomic) UILabel *nameLabel;
@property(nonatomic) UILabel *kindLabel;
@property(nonatomic) UIImageView *check;
- (void)applyName:(NSString *)name selected:(BOOL)selected;
@end

@implementation PLAccountCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = UIColor.clearColor;

    _card = [[UIView alloc] initWithFrame:CGRectZero];
    _card.translatesAutoresizingMaskIntoConstraints = NO;
    [PLTheme applyCardStyle:_card];
    [self.contentView addSubview:_card];

    _avatar = [[UIView alloc] initWithFrame:CGRectZero];
    _avatar.translatesAutoresizingMaskIntoConstraints = NO;
    _avatar.backgroundColor = [PLTheme accentSoft];
    _avatar.layer.cornerRadius = 23.0;
    _avatar.layer.cornerCurve = kCACornerCurveContinuous;
    [_card addSubview:_avatar];

    _initial = [[UILabel alloc] initWithFrame:CGRectZero];
    _initial.translatesAutoresizingMaskIntoConstraints = NO;
    _initial.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    _initial.textColor = [PLTheme accent];
    _initial.textAlignment = NSTextAlignmentCenter;
    [_avatar addSubview:_initial];

    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [PLTheme headlineFont];
    _nameLabel.textColor = [PLTheme primaryText];
    [_card addSubview:_nameLabel];

    _kindLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _kindLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _kindLabel.text = @"Offline account";
    _kindLabel.font = [PLTheme captionFont];
    _kindLabel.textColor = [PLTheme secondaryText];
    [_card addSubview:_kindLabel];

    _check = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"checkmark.circle.fill" pointSize:22]];
    _check.translatesAutoresizingMaskIntoConstraints = NO;
    _check.tintColor = [PLTheme accent];
    _check.contentMode = UIViewContentModeScaleAspectFit;
    [_card addSubview:_check];

    [NSLayoutConstraint activateConstraints:@[
        [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
        [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
        [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:[PLTheme gutter]],
        [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-[PLTheme gutter]],

        [_avatar.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
        [_avatar.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_avatar.widthAnchor constraintEqualToConstant:46],
        [_avatar.heightAnchor constraintEqualToConstant:46],

        [_initial.centerXAnchor constraintEqualToAnchor:_avatar.centerXAnchor],
        [_initial.centerYAnchor constraintEqualToAnchor:_avatar.centerYAnchor],

        [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatar.trailingAnchor constant:13],
        [_nameLabel.topAnchor constraintEqualToAnchor:_card.topAnchor constant:15],
        [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_check.leadingAnchor constant:-10],

        [_kindLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
        [_kindLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:3],

        [_check.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-16],
        [_check.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_check.widthAnchor constraintEqualToConstant:22],
        [_check.heightAnchor constraintEqualToConstant:22]
    ]];

    return self;
}

- (void)applyName:(NSString *)name selected:(BOOL)selected {
    self.nameLabel.text = name;
    self.initial.text = name.length > 0 ? [[name substringToIndex:1] uppercaseString] : @"?";
    self.check.hidden = !selected;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.card.transform = highlighted ? CGAffineTransformMakeScale(0.975, 0.975) : CGAffineTransformIdentity;
    } completion:nil];
}

@end

@interface PLAccountsViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) NSArray<NSString *> *accounts;
@property(nonatomic) NSString *selectedName;
@property(nonatomic) UIView *emptyView;
@end

@implementation PLAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLTheme canvas];
    self.navigationItem.title = @"Accounts";

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[PLTheme symbol:@"plus" pointSize:17 weight:UIFontWeightBold]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(addAccount)];
    self.navigationItem.rightBarButtonItem = add;
    [self reloadAccounts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadAccounts];
}

- (void)reloadAccounts {
    NSString *dir = [plc_home_dir() stringByAppendingPathComponent:@"accounts"];
    NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray *names = [NSMutableArray new];
    for (NSString *file in files) {
        if ([file.pathExtension isEqualToString:@"json"]) {
            [names addObject:file.stringByDeletingPathExtension];
        }
    }
    self.accounts = [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.selectedName = getPrefObject(@"internal.selected_account");
    [self.tableView reloadData];

    if (self.accounts.count == 0) {
        UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        hint.numberOfLines = 0;
        hint.textAlignment = NSTextAlignmentCenter;
        hint.font = [PLTheme bodyFont];
        hint.textColor = [PLTheme secondaryText];
        hint.text = @"No accounts\nTap + to add one";
        self.tableView.backgroundView = hint;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (void)addAccount {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Add account" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak PLAccountsViewController *weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Offline account" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakSelf promptOfflineName];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)promptOfflineName {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Offline account" message:@"Enter a username" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Steve";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak PLAccountsViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length == 0) {
            return;
        }
        LocalAuthenticator *auth = [[LocalAuthenticator alloc] initWithInput:name];
        [auth loginWithCallback:^(id status, BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success && [auth saveChanges]) {
                    setPrefObject(@"internal.selected_account", auth.authData[@"username"]);
                    [weakSelf reloadAccounts];
                }
            });
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.accounts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 78.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:@"acc"];
    if (!cell) {
        cell = [[PLAccountCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"acc"];
    }
    NSString *name = self.accounts[indexPath.row];
    [cell applyName:name selected:[name isEqualToString:self.selectedName]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.accounts[indexPath.row];
    BaseAuthenticator.current = [BaseAuthenticator loadSavedName:name];
    setPrefObject(@"internal.selected_account", name);
    self.selectedName = name;
    [self.tableView reloadData];
}

@end