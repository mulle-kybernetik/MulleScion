//
//  Example.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import "ExampleBase.h"


@interface Example : ExampleBase

+ (id) mulleScionDataSource;
- (id) valueForKeyPath:(NSString *) keyPath;

@end
