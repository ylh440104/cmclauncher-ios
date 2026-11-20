#import "PLAccountsViewController.h"
#import "PLCore.h"
#import "LauncherPreferences.h"
#import "authenticator/BaseAuthenticator.h"
#import "utils.h"

@interface PLAccountsViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) NSArray<NSString *> *accounts;
@property(nonatomic) NSString *selectedName;
@end

@implementation PLAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Accounts";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccount)];
    [self reloadAccounts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadAccounts];
}

- (void)reloadAccounts {
    NSString *dir = [[plc_home_dir() stringByAppendingPathComponent:@"accounts"] copy];
    NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray *names = [NSMutableArray new];
    for (NSString *file in files) {
        if (![file.pathExtension isEqualToString:@"json"]) {
            continue;
        }
        [names addObject:file.stringByDeletingPathExtension];
    }
    self.accounts = [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.selectedName = getPrefObject(@"internal.selected_account");
    [self.tableView reloadData];
}

- (void)addAccount {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Add account" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Offline account" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self promptOfflineName];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"acc"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"acc"];
    }
    NSString *name = self.accounts[indexPath.row];
    cell.textLabel.text = name;
    cell.imageView.image = [UIImage systemImageNamed:@"person.crop.circle"];
    cell.accessoryType = [name isEqualToString:self.selectedName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *name = self.accounts[indexPath.row];
    BaseAuthenticator.current = [BaseAuthenticator loadSavedName:name];
    setPrefObject(@"internal.selected_account", name);
    self.selectedName = name;
    [self.tableView reloadData];
}

@end