#import <Security/Security.h>

#import "KeychainWrapper.h"

/* ********************************************************************** */

@interface KeychainWrapper (PrivateMethods)


//The following two methods translate dictionaries between the format used by
// the view controller (NSString *) and the Keychain Services API:
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
// Method used to write data to the keychain:
- (void)writeToKeychain;

@end

@implementation KeychainWrapper

//Synthesize the getter and setter:
@synthesize keychainData, genericQuery, identifier;

- (id)initWithIdentifier:(NSString*)theIdentifier requestClass:(CFTypeRef)requestClass
{
    if ((self = [super init])) {
        self.identifier = theIdentifier;
        
        OSStatus keychainErr = noErr;
        // Set up the keychain search dictionary:
        genericQuery = [[NSMutableDictionary alloc] init];
        
        [genericQuery setObject:(__bridge id)(requestClass) forKey:(__bridge id<NSCopying>)(kSecClass)];
        
        // The kSecAttrGeneric attribute is used to store a unique string that is used
        // to easily identify and find this keychain item. The string is first
        // converted to an NSData object:
        NSData *keychainItemID = [identifier dataUsingEncoding:NSUTF8StringEncoding];
        [genericQuery setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
        // Return the attributes of the first match only:
        [genericQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        // Return the attributes of the keychain item (the password is
        //  acquired in the secItemFormatToDictionary: method):
        [genericQuery setObject:(id)kCFBooleanTrue
                                 forKey:(__bridge id)kSecReturnAttributes];
        
        //Initialize the dictionary used to hold return data from the keychain:
        NSMutableDictionary *outDictionary = nil;
        CFMutableDictionaryRef cfDictionary = nil;
        // If the keychain item exists, return the attributes of the item:
        keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)genericQuery,
                                          (CFTypeRef*)&cfDictionary);
        outDictionary = (__bridge NSMutableDictionary*)cfDictionary;

        if (keychainErr == noErr) {
            // Convert the data dictionary into the format used by the view controller:
            self.keychainData = [self secItemFormatToDictionary:outDictionary];
        } else if (keychainErr == errSecItemNotFound) {
            // Put default values into the keychain if no matching
            // keychain item is found:
            [self resetKeychainItem];
        } else {
            // Any other error is unexpected.
            NSAssert(NO, @"Serious error %ld.\n", keychainErr);
        }
    }
    return self;
}

// Implement the mySetObject:forKey method, which writes attributes to the keychain:
- (void)mySetObject:(id)inObject forKey:(id)key
{
    if (inObject == nil) return;
    id currentObject = [keychainData objectForKey:key];
    if (![currentObject isEqual:inObject])
    {
        [keychainData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

// Implement the myObjectForKey: method, which reads an attribute value from a dictionary:
- (id)myObjectForKey:(id)key
{
    return [keychainData objectForKey:key];
}

// Reset the values in the keychain item, or create a new item if it
// doesn't already exist:

- (void)resetKeychainItem
{
    if (!keychainData) //Allocate the keychainData dictionary if it doesn't exist yet.
    {
        self.keychainData = [[NSMutableDictionary alloc] init];
    }
    else if (keychainData)
    {
        // Format the data in the keychainData dictionary into the format needed for a query
        //  and put it into tmpDictionary:
        NSMutableDictionary *tmpDictionary =
        [self dictionaryToSecItemFormat:keychainData];
        // Delete the keychain item in preparation for resetting the values:
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)tmpDictionary);
        NSAssert(status == noErr, @"Problem deleting current keychain item." );
    }
    
    // Default generic data for Keychain Item:
    [keychainData setObject:@"Item label" forKey:(__bridge id)kSecAttrLabel];
    [keychainData setObject:@"Item description" forKey:(__bridge id)kSecAttrDescription];
    [keychainData setObject:@"Account" forKey:(__bridge id)kSecAttrAccount];
    [keychainData setObject:@"Service" forKey:(__bridge id)kSecAttrService];
    [keychainData setObject:@"Your comment here." forKey:(__bridge id)kSecAttrComment];
    [keychainData setObject:@"none" forKey:(__bridge id)kSecValueData];
}

// Implement the dictionaryToSecItemFormat: method, which takes the attributes that
//   you want to add to the keychain item and sets up a dictionary in the format
//  needed by Keychain Services:
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for a keychain item search.
    
    // Create the return dictionary:
    NSMutableDictionary *returnDictionary =
    [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    // Add the keychain item class and the generic attribute:
    NSData *keychainItemID = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [returnDictionary setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    // Convert the password NSString to NSData to fit the API paradigm:
    NSString *passwordString = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(__bridge id)kSecValueData];
    return returnDictionary;
}

// Implement the secItemFormatToDictionary: method, which takes the attribute dictionary
//  obtained from the keychain item, acquires the password from the keychain, and
//  adds it to the attribute dictionary:
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for the keychain item.
    
    // Create a return dictionary populated with the attributes:
    NSMutableDictionary *returnDictionary = [NSMutableDictionary
                                             dictionaryWithDictionary:dictionaryToConvert];
    
    // To acquire the password data from the keychain item,
    // first add the search key and class attribute required to obtain the password:
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    // Then call Keychain Services to get the password:
    NSData *passwordData = nil;
    OSStatus keychainError = noErr; //
    CFDataRef cfPasswordData = nil;
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary,
                                        (CFTypeRef *)&cfPasswordData);
    passwordData = (__bridge NSData*)cfPasswordData;

    if (keychainError == noErr)
    {
        // Remove the kSecReturnData key; we don't need it anymore:
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        // Convert the password to an NSString and add it to the return dictionary:
        NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                                       length:[passwordData length] encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
    }
    // Don't do anything if nothing is found.
    else if (keychainError == errSecItemNotFound) {
        NSAssert(NO, @"Nothing was found in the keychain.\n");
    }
    // Any other error is unexpected.
    else
    {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return returnDictionary;
}

// Implement the writeToKeychain method, which is called by the mySetObject routine,
//   which in turn is called by the UI when there is new data for the keychain. This
//   method modifies an existing keychain item, or--if the item does not already
//   exist--creates a new keychain item with the new attribute value plus
//  default values for the other attributes.
- (void)writeToKeychain
{
    NSMutableDictionary *updateItem = nil;
    
    // If the keychain item already exists, modify it:
    CFDictionaryRef cfAttributes = nil;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)genericQuery,
                            (CFTypeRef *)&cfAttributes) == noErr)
    {
        NSDictionary *attributes = (__bridge NSDictionary*)cfAttributes;

        // First, get the attributes returned from the keychain and add them to the
        // dictionary that controls the update:
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        // Second, get the class value from the generic password query dictionary and
        // add it to the updateItem dictionary:
        [updateItem setObject:[genericQuery objectForKey:(__bridge id)kSecClass]
                       forKey:(__bridge id)kSecClass];
        
        // Finally, set up the dictionary that contains new values for the attributes:
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainData];
        //Remove the class--it's not a keychain attribute:
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        // You can update only a single keychain item at a time.
        NSAssert(SecItemUpdate((__bridge CFDictionaryRef)updateItem,
                               (__bridge CFDictionaryRef)tempCheck) == noErr,
                 @"Couldn't update the Keychain Item." );
    }
    else
    {
        // No previous item found; add the new item.
        // The new value was added to the keychainData dictionary in the mySetObject routine,
        //  and the other values were added to the keychainData dictionary previously.
        
        // No pointer to the newly-added items is needed, so pass NULL for the second parameter:
        NSAssert(SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:keychainData],
                            NULL) == noErr, @"Couldn't add the Keychain Item." );
    }
}


@end
