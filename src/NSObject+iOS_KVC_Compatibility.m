//
//  NSObject+KVC_Compatibility.m
//  MulleScion
//
//  Created by Nat! on 07.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSObject+iOS_KVC_Compatibility.h"


@implementation NSObject (KVC_Compatibility)

- (void) takeValue:(id) value
        forKeyPath:(NSString *) keyPath
{
   [self setValue:value
       forKeyPath:keyPath];
}


@end
