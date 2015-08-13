//
//  SettingsViewController.h
//  WebBrowser
//
//  Created by Chris Lesch on 6/8/14.
//  Copyright (c) 2014 iD Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *HomepageURL;
- (IBAction)SaveSettings:(id)sender;
@end
