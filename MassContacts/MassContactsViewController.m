//
//  MassContactsViewController.m
//  MassContacts
//
//  Created by Matthew Ewer on 12/30/13.
//  Copyright (c) 2013 Erhannis's Fine Goods. All rights reserved.
//

#import "MassContactsViewController.h"
#import <AddressBook/AddressBook.h>

@interface MassContactsViewController ()
@property (nonatomic) ABAddressBookRef book;
@property (strong, nonatomic) NSArray *unfilteredPeople;
@property (strong, nonatomic) NSArray *filteredPeople;
@property (weak, nonatomic) IBOutlet UILabel *labelResults;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation MassContactsViewController

//TODO Decide whether to make this more exact.
#define FILTER_PRESET_EMAILS @".*@.*\\..*"

- (void)setFilteredPeople:(NSArray *)filteredPeople
{
    _filteredPeople = filteredPeople;
    if (filteredPeople) {
        self.labelResults.text = [NSString stringWithFormat:@"Results: %d of %d", filteredPeople.count, self.unfilteredPeople.count];
    } else {
        self.labelResults.text = @"Results: -";
    }
    NSLog(@"setFilteredPeople");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)clickButtonSearch:(id)sender {
    //TODO Add error handling.
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, NULL);
    [self.activityIndicator startAnimating];
    __weak MassContactsViewController *weakself = self;
    ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
        if (granted && !error) {
            NSLog(@"Success");
            weakself.book = book;
            NSArray *people = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(weakself.book);
            NSArray *filteredPeople = [weakself performSearchOnPeople:people];
            weakself.unfilteredPeople = people;
            weakself.filteredPeople = filteredPeople;
        } else {
            NSLog(@"Failure");
            weakself.book = nil;
        }
        [weakself.activityIndicator stopAnimating];
    });
}

- (NSArray *)performSearchOnPeople:(NSArray *)people
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        ABRecordRef record = (__bridge ABRecordRef)evaluatedObject;

/*
        NSArray *allPropertiesForABPerson = @[[NSNumber numberWithInt:kABPersonFirstNameProperty],
                                              [NSNumber numberWithInt:kABPersonLastNameProperty],
                                              [NSNumber numberWithInt:kABPersonMiddleNameProperty],
                                              [NSNumber numberWithInt:kABPersonPrefixProperty],
                                              [NSNumber numberWithInt:kABPersonSuffixProperty],
                                              [NSNumber numberWithInt:kABPersonNicknameProperty],
                                              [NSNumber numberWithInt:kABPersonFirstNamePhoneticProperty],
                                              [NSNumber numberWithInt:kABPersonLastNamePhoneticProperty],
                                              [NSNumber numberWithInt:kABPersonMiddleNamePhoneticProperty],
                                              [NSNumber numberWithInt:kABPersonOrganizationProperty],
                                              [NSNumber numberWithInt:kABPersonJobTitleProperty],
                                              [NSNumber numberWithInt:kABPersonDepartmentProperty],
                                              [NSNumber numberWithInt:kABPersonEmailProperty],
                                              [NSNumber numberWithInt:kABPersonBirthdayProperty],
                                              [NSNumber numberWithInt:kABPersonNoteProperty],
                                              [NSNumber numberWithInt:kABPersonCreationDateProperty],
                                              [NSNumber numberWithInt:kABPersonModificationDateProperty]];
 */

        NSArray *relevantPropertiesForPerson = @[[NSNumber numberWithInt:kABPersonFirstNameProperty],
                                                 [NSNumber numberWithInt:kABPersonLastNameProperty],
                                                 [NSNumber numberWithInt:kABPersonMiddleNameProperty],
                                                 [NSNumber numberWithInt:kABPersonPrefixProperty],
                                                 [NSNumber numberWithInt:kABPersonSuffixProperty],
                                                 [NSNumber numberWithInt:kABPersonNicknameProperty],
                                                 [NSNumber numberWithInt:kABPersonFirstNamePhoneticProperty],
                                                 [NSNumber numberWithInt:kABPersonLastNamePhoneticProperty],
                                                 [NSNumber numberWithInt:kABPersonMiddleNamePhoneticProperty],
                                                 [NSNumber numberWithInt:kABPersonOrganizationProperty],
                                                 [NSNumber numberWithInt:kABPersonJobTitleProperty],
                                                 [NSNumber numberWithInt:kABPersonDepartmentProperty],
                                                 [NSNumber numberWithInt:kABPersonBirthdayProperty],
                                                 [NSNumber numberWithInt:kABPersonNoteProperty]];
        
        for (NSNumber *property in relevantPropertiesForPerson) {
            CFTypeRef valueForProperty = ABRecordCopyValue(record, property.intValue);
            if (valueForProperty) {
                CFRelease(valueForProperty);
                return NO;
            }
        }
        
        return YES;
    }];
    return [people filteredArrayUsingPredicate:predicate];
}

- (IBAction)clickButtonDelete:(id)sender {
}

@end
