//
//  Example.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import "ExampleBase.h"


//
// specific interface code for MulleScion
// instances of Example will act as the DataSource for MulleScion
// it minimally needs to provide a -valueForKeyPath method.
//
// The +mulleScionDataSource method is used as a rendezvous point for
// mulle-scion since we want to load this code from a bundle.
//
// Example has to be the NSPrincipalClass in the Info.plist
// of this bundle
//
@interface Example : ExampleBase

+ (id) mulleScionDataSource;
- (id) valueForKeyPath:(NSString *) keyPath;

@end
