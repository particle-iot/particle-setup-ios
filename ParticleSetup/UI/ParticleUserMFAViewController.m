//
//  ParticleUserForgotPasswordViewController.m
//  teacup-ios-app
//
//  Created by Ido on 2/13/15.
//  Copyright (c) 2015 particle. All rights reserved.
//

#import "ParticleUserMFAViewController.h"
#import "ParticleSetupCustomization.h"
#ifdef USE_FRAMEWORKS
#import <ParticleSDK/ParticleSDK.h>
#else
#import "Particle-SDK.h"
#endif
#import "ParticleSetupWebViewController.h"
#import "ParticleUserLoginViewController.h"
#import "ParticleSetupUIElements.h"
#ifdef ANALYTICS
#import <SEGAnalytics.h>
#endif

@interface ParticleUserMFAViewController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (weak, nonatomic) IBOutlet UIImageView *brandImageView;
@property (weak, nonatomic) IBOutlet UIImageView *brandBackgroundImageView;
@property (weak, nonatomic) IBOutlet ParticleSetupUISpinner *spinner;


@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@property (weak, nonatomic) IBOutlet UIButton *recoveryCodeButton;
@property (weak, nonatomic) IBOutlet UIButton *loginCodeButton;

@end

@implementation ParticleUserMFAViewController


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}



- (void)viewDidLoad {
    [super viewDidLoad];

    self.brandImageView.image = [ParticleSetupCustomization sharedInstance].brandImage;
    self.brandImageView.backgroundColor = [UIColor clearColor];
    self.brandBackgroundImageView.backgroundColor = [ParticleSetupCustomization sharedInstance].brandImageBackgroundColor;
    self.brandBackgroundImageView.image = [ParticleSetupCustomization sharedInstance].brandImageBackgroundImage;

    // Trick to add an inset from the left of the text fields
    CGRect  viewRect = CGRectMake(0, 0, 10, 32);
    UIView* emptyView = [[UIView alloc] initWithFrame:viewRect];
    
    self.codeTextField.leftView = emptyView;
    self.codeTextField.leftViewMode = UITextFieldViewModeAlways;
    self.codeTextField.delegate = self;
    self.codeTextField.returnKeyType = UIReturnKeyGo;
    self.codeTextField.font = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].normalTextFontName size:16.0];

}

- (IBAction)otpVerifyButtonTapped:(id)sender {
    [self.view endEditing:YES];
    [self trimTextFieldValue:self.codeTextField];
    [self.spinner startAnimating];

    if ([self.codeTextField.text isEqualToString:@""]) {
        [self.spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter the code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        [[ParticleCloud sharedInstance] loginWithUser:self.username mfaToken:self.mfaToken OTPToken:self.codeTextField.text completion:^(NSError *error) {
            if (!error) {
#ifdef ANALYTICS
                [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA Login success"];
#endif

                [self.delegate didFinishUserAuthentication:self loggedIn:YES];
            } else {
#ifdef ANALYTICS
                [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA failure"];
#endif

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Two-step Authentication Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
}

- (IBAction)recoveryVerifyButtonTapped:(id)sender {
    [self.view endEditing:YES];
    [self trimTextFieldValue:self.codeTextField];
    [self.spinner startAnimating];

    if ([self.codeTextField.text isEqualToString:@""]) {
        [self.spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter the code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        [[ParticleCloud sharedInstance] loginWithUser:self.username mfaToken:self.mfaToken recoveryCode:self.codeTextField.text completion:^(NSError *error) {
            if (!error) {
#ifdef ANALYTICS
                [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA Recovery Login success"];
#endif

                [self.delegate didFinishUserAuthentication:self loggedIn:YES];
            } else {
#ifdef ANALYTICS
                [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA Recovery failure"];
#endif

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Two-step Authentication Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];

            }
        }];
    }
}



-(void)viewWillAppear:(BOOL)animated
{
#ifdef ANALYTICS
    if (self.recoveryScreen) {
        [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA Recovery Screen"];
    } else {
        [[SEGAnalytics sharedAnalytics] track:@"Auth: MFA OTP Screen"];
    }
#endif
}



-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.codeTextField)
    {
        if (self.recoveryScreen) {
            [self recoveryVerifyButtonTapped:self];
        } else {
            [self otpVerifyButtonTapped:self];
        }

        return YES;

    }
    return NO;
}


- (IBAction)recoveryButtonTapped:(id)sender
{
    [self.delegate didRequestMFARecovery:self mfaToken:self.mfaToken username:self.username];
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self.delegate didTriggerMFA:self mfaToken:self.mfaToken username:self.username];
}

@end
