//
//  MassContactsViewController.m
//  MassContacts
//
//  Created by Matthew Ewer on 12/30/13.
//  Copyright (c) 2013 Erhannis's Fine Goods. All rights reserved.
//

#import "MassContactsViewController.h"

@interface MassContactsViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editSearchFilter;
@end

@implementation MassContactsViewController

//TODO Decide whether to make this more exact.
#define FILTER_PRESET_EMAILS @".*@.*\\..*"

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)clickButtonEmail:(id)sender {
    self.editSearchFilter.text = FILTER_PRESET_EMAILS;
}

@end
