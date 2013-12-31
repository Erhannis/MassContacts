//
//  MassContactsViewController.m
//  MassContacts
//
//  Created by Matthew Ewer on 12/30/13.
//  Copyright (c) 2013 Erhannis's Fine Goods. All rights reserved.
//

#import "MassContactsViewController.h"

@interface MassContactsViewController ()
@property (nonatomic) ABAddressBookRef book;
@property (strong, nonatomic) NSArray *unfilteredPeople;
@property (strong, nonatomic) NSArray *filteredPeople;
@property (strong, nonatomic) NSArray *antifilteredPeople;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)clickButtonSearch:(id)sender {
    CFErrorRef error = nil;
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, &error);
    [self checkError:error whenAttempting:@"creating book"];
    [self.activityIndicator startAnimating];
    __weak MassContactsViewController *weakself = self;
    ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted && !error) {
                NSLog(@"Success");
                weakself.book = book;
                NSArray *people = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(weakself.book);
                NSArray *filteredPeople = [weakself performSearchOnPeople:people];
                weakself.unfilteredPeople = people;
                weakself.filteredPeople = filteredPeople;
                NSMutableArray *antifilteredPeople = [people mutableCopy];
                [antifilteredPeople removeObjectsInArray:filteredPeople];
                weakself.antifilteredPeople = [antifilteredPeople copy];
                [weakself performAntiDelete];
            } else {
                NSLog(@"Failure");
                weakself.book = nil;
            }
            [weakself.activityIndicator stopAnimating];
        });
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

- (IBAction)clickButtonShow:(id)sender {
    if (self.filteredPeople) {
        //TODO This isn't really working.
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.addressBook = self.book;
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (void)performAntiDelete
{
    if (self.book && self.antifilteredPeople) {
        for (id r in self.antifilteredPeople) {
            ABRecordRef record = (__bridge ABRecordRef)r;
            CFErrorRef error = nil;
            ABAddressBookRemoveRecord(self.book, record, &error);
            [self checkError:error whenAttempting:@"antideleting"];
        }
    }
}

- (void)performDelete
{
    if (self.filteredPeople) {
        CFErrorRef error = nil;
        ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, &error);
        [self checkError:error whenAttempting:@"creating book"];
        for (id r in self.filteredPeople) {
            ABRecordRef record = (__bridge ABRecordRef)r;
            error = nil;
            ABAddressBookRemoveRecord(book, record, &error);
            [self checkError:error whenAttempting:@"deleting"];
        }
        error = nil;
        ABAddressBookSave(book, &error);
        [self checkError:error whenAttempting:@"saving"];
    }
}

- (void)checkError:(CFErrorRef)error
    whenAttempting:(NSString *)thingAttempted
{
    if (error) {
        NSError *err = (__bridge NSError*)error;
        NSLog(@"error %@: %@", thingAttempted, err);
        CFRelease(error);
    }
}

- (IBAction)clickButtonDelete:(id)sender {
    //TODO Add confirmation dialog
    if (self.book) {
        [self performDelete];
    }
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}

@end