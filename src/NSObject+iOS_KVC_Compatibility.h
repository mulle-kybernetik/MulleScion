//
//  NSObject+KVC_Compatibility.h
//  MulleScion
//
//  Created by Nat! on 07.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (iOS_KVC_Compatibility)

- (void) takeValue:(id) value
        forKeyPath:(NSString *) keyPath;

@end
