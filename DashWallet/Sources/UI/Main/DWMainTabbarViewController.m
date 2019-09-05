//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DWMainTabbarViewController.h"

#import "DWHomeModel.h"
#import "DWHomeViewController.h"
#import "DWNavigationController.h"
#import "DWPaymentsViewController.h"
#import "DWTabBarView.h"
#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const ANIMATION_DURATION = 0.35;

@interface DWMainTabbarViewController () <DWTabBarViewDelegate,
                                          DWPaymentsViewControllerDelegate,
                                          DWHomeViewControllerDelegate,
                                          UINavigationControllerDelegate>

@property (nullable, nonatomic, strong) UIViewController *currentController;
@property (nullable, nonatomic, strong) UIViewController *modalController;

@property (nullable, nonatomic, strong) UIView *contentView;
@property (nullable, nonatomic, strong) DWTabBarView *tabBarView;
@property (nullable, nonatomic, strong) NSLayoutConstraint *tabBarBottomConstraint;

@property (nullable, nonatomic, strong) DWHomeViewController *homeViewController;

@end

@implementation DWMainTabbarViewController

+ (instancetype)controller {
    DWMainTabbarViewController *controller = [[DWMainTabbarViewController alloc] init];

    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupView];
    [self setupControllers];
}

- (nullable UIViewController *)childViewControllerForStatusBarStyle {
    return self.modalController ?: self.currentController;
}

- (nullable UIViewController *)childViewControllerForStatusBarHidden {
    return self.modalController ?: self.currentController;
}

#pragma mark - DWTabBarViewDelegate

- (void)tabBarView:(DWTabBarView *)tabBarView didTapButtonType:(DWTabBarViewButtonType)buttonType {
}

- (void)tabBarViewDidOpenPayments:(DWTabBarView *)tabBarView {
    [self showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_None
                                     payAction:DWPaymentsViewControllerPayAction_None];
}

- (void)tabBarViewDidClosePayments:(DWTabBarView *)tabBarView {
    if (!self.modalController) {
        return;
    }

    tabBarView.userInteractionEnabled = NO;
    [tabBarView setPaymentsButtonOpened:NO];

    UIViewController *controller = self.modalController;
    self.modalController = nil;

    [self hideModalController:controller
                   completion:^{
                       tabBarView.userInteractionEnabled = YES;
                   }];
}

#pragma mark - DWPaymentsViewControllerDelegate

- (void)paymentsViewControllerDidCancel:(DWPaymentsViewController *)controller {
    [self tabBarViewDidClosePayments:self.tabBarView];
}

#pragma mark - DWHomeViewControllerDelegate

- (void)homeViewController:(DWHomeViewController *)controller payButtonAction:(UIButton *)sender {
    [self showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Pay
                                     payAction:DWPaymentsViewControllerPayAction_None];
}

- (void)homeViewController:(DWHomeViewController *)controller receiveButtonAction:(UIButton *)sender {
    [self showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Receive
                                     payAction:DWPaymentsViewControllerPayAction_None];
}

- (void)homeViewController:(DWHomeViewController *)controller payToAddressButtonAction:(UIView *)sender {
    [self showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Pay
                                     payAction:DWPaymentsViewControllerPayAction_PayToPasteboard];
}

- (void)homeViewController:(DWHomeViewController *)controller scanQRAction:(UIView *)sender {
    [self showPaymentsControllerWithActivePage:DWPaymentsViewControllerIndex_Pay
                                     payAction:DWPaymentsViewControllerPayAction_ScanToPay];
}

- (void)homeViewControllerDidWipeWallet:(DWHomeViewController *)controller {
    [self.delegate mainTabbarViewControllerDidWipeWallet:self];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [self setTabBarHiddenAnimated:viewController.hidesBottomBarWhenPushed animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [self setTabBarHiddenAnimated:viewController.hidesBottomBarWhenPushed animated:NO];
}

#pragma mark - Private

- (void)setupView {
    self.view.backgroundColor = [UIColor dw_secondaryBackgroundColor];

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:contentView];
    self.contentView = contentView;

    DWTabBarView *tabBarView = [[DWTabBarView alloc] initWithFrame:CGRectZero];
    tabBarView.translatesAutoresizingMaskIntoConstraints = NO;
    tabBarView.delegate = self;
    [self.view addSubview:tabBarView];
    self.tabBarView = tabBarView;

    self.tabBarBottomConstraint = [tabBarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [tabBarView.topAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [tabBarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tabBarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.tabBarBottomConstraint,
    ]];
}

- (void)showPaymentsControllerWithActivePage:(DWPaymentsViewControllerIndex)pageIndex
                                   payAction:(DWPaymentsViewControllerPayAction)payAction {
    if (self.modalController) {
        return;
    }

    self.tabBarView.userInteractionEnabled = NO;
    [self.tabBarView setPaymentsButtonOpened:YES];

    DWHomeModel *homeModel = self.homeViewController.model;
    NSParameterAssert(homeModel);
    DWReceiveModel *receiveModel = homeModel.receiveModel;
    DWPayModel *payModel = homeModel.payModel;
    DWPaymentsViewController *controller = [DWPaymentsViewController controllerWithReceiveModel:receiveModel
                                                                                       payModel:payModel];
    controller.delegate = self;
    controller.currentIndex = pageIndex;
    controller.payAction = payAction;
    DWNavigationController *navigationController =
        [[DWNavigationController alloc] initWithRootViewController:controller];
    navigationController.delegate = self;
    self.modalController = navigationController;

    [self displayModalViewController:navigationController
                          completion:^{
                              self.tabBarView.userInteractionEnabled = YES;
                          }];
}

- (void)setupControllers {
    DWHomeViewController *homeController = [[DWHomeViewController alloc] init];
    homeController.delegate = self;
    self.homeViewController = homeController;

    DWNavigationController *navigationController =
        [[DWNavigationController alloc] initWithRootViewController:homeController];

    [self displayViewController:navigationController];
}

- (void)displayViewController:(UIViewController *)controller {
    NSParameterAssert(controller);
    if (!controller) {
        return;
    }

    UIView *contentView = self.contentView;
    UIView *childView = controller.view;

    [self addChildViewController:controller];

    childView.frame = contentView.bounds;
    childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [contentView addSubview:childView];

    [controller didMoveToParentViewController:self];

    self.currentController = controller;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)displayModalViewController:(UIViewController *)controller completion:(void (^)(void))completion {
    NSParameterAssert(controller);
    if (!controller) {
        return;
    }

    [self.currentController beginAppearanceTransition:NO animated:YES];

    UIView *contentView = self.contentView;
    UIView *childView = controller.view;

    [self addChildViewController:controller];

    childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [contentView addSubview:childView];

    CGRect frame = contentView.bounds;
    frame.origin.y = CGRectGetHeight(frame);
    childView.frame = frame;

    [UIView animateWithDuration:ANIMATION_DURATION
        delay:0.0
        usingSpringWithDamping:1.0
        initialSpringVelocity:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            childView.frame = contentView.bounds;

            [self setNeedsStatusBarAppearanceUpdate];
        }
        completion:^(BOOL finished) {
            [controller didMoveToParentViewController:self];

            [self.currentController endAppearanceTransition];

            if (completion) {
                completion();
            }
        }];
}

- (void)hideModalController:(UIViewController *)controller completion:(void (^)(void))completion {
    NSParameterAssert(controller);
    if (!controller) {
        return;
    }

    [self.currentController beginAppearanceTransition:YES animated:YES];

    UIView *childView = controller.view;
    [controller willMoveToParentViewController:nil];

    [UIView animateWithDuration:ANIMATION_DURATION
        delay:0.0
        usingSpringWithDamping:1.0
        initialSpringVelocity:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            CGRect frame = childView.frame;
            frame.origin.y = CGRectGetHeight(frame);
            childView.frame = frame;

            [self setNeedsStatusBarAppearanceUpdate];
        }
        completion:^(BOOL finished) {
            [childView removeFromSuperview];
            [controller removeFromParentViewController];

            [self.currentController endAppearanceTransition];

            if (completion) {
                completion();
            }
        }];
}

- (void)setTabBarHiddenAnimated:(BOOL)hidden animated:(BOOL)animated {
    const CGFloat constant = hidden ? DW_TABBAR_HEIGHT : 0.0;
    const CGFloat alpha = hidden ? 0.0 : 1.0;

    self.tabBarBottomConstraint.constant = constant;

    [UIView animateWithDuration:animated ? ANIMATION_DURATION : 0.0
                     animations:^{
                         [self.view layoutIfNeeded];
                         self.tabBarView.alpha = alpha;
                     }];
}

@end

NS_ASSUME_NONNULL_END