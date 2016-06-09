//
//  NSObject+KVC_Compatibility.m
//  MulleScion
//
//  Created by Nat! on 07.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSObject+KVC_Compatibility.h"
#if ! __MULLE_OBJC_RUNTIME__
# import <objc/runtime.h>

@implementation NSObject ( KVC_Compatibility)

+ (void) load
{
   IMP   setValueForKeyPath;
   
   if( ! [self instancesRespondToSelector:@selector( setValue:forKeyPath:)])
      return;
   
   setValueForKeyPath = [self instanceMethodForSelector:@selector( setValue:forKeyPath:)];
   
   if( ! [self instancesRespondToSelector:@selector( takeValue:forKeyPath:)])
      class_addMethod( self, @selector( takeValue:forKeyPath:), setValueForKeyPath, "v@:@@");
      return;

   // just over write takeValue:forKeyPath: with setValue:forKeyPath:
   class_replaceMethod( self, @selector( takeValue:forKeyPath:),setValueForKeyPath,"v@:@@");
}


// this is only used where setValue:forKeyPath: doesn't exist

- (void) takeValue:(id) value
        forKeyPath:(NSString *) keyPath
{
   [self setValue:value
       forKeyPath:keyPath];
}

@end

#endif
