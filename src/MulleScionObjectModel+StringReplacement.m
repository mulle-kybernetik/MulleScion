//
//  MulleScionObjectModel+StringReplacement.m
//  MulleScionTemplates
//
//  Created by Nat! on 03.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+StringReplacement.h"
#import <Foundation/Foundation.h>


@implementation MulleScionObject(StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags
{
}

@end


@implementation MulleScionTemplate (StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags
{
   MulleScionObject   *curr;
   
   for( curr = self->next_; curr; curr = curr->next_)
      [curr replaceOccurrencesOfString:s
                            withString:other
                               options:options
                       templateOptions:flags];
}

@end


static void  replace( NSString  **value, NSString *s, NSString *other, NSStringCompareOptions options)
{
   NSString  *result;
   
   result = [*value stringByReplacingOccurrencesOfString:s
                                              withString:other
                                                 options:options
                                                   range:NSMakeRange( 0, [*value length])];
   if( result == *value)
      return;
   
   [*value release];
   *value = [result retain];
}


static void  array_replace( NSArray *array, NSString *s, NSString *other, NSStringCompareOptions options, NSUInteger flags)
{
   NSEnumerator           *rover;
   MulleScionExpression   *expr;
   
   rover = [array objectEnumerator];
   while( expr = [rover nextObject])
      [expr replaceOccurrencesOfString:s
                            withString:other
                               options:options
                       templateOptions:flags];
}


@implementation MulleScionPlainText( StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags
{
   if( flags & 2)
      replace( &value_, s, other, options);
}

@end


@implementation MulleScionString( StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags
{
   if( flags & 1)
      replace( &value_, s, other, options);
}

@end


@implementation MulleScionFunction( StringReplacement)

- (void) replaceOccurrencesOfString:(NSString *) s
                         withString:(NSString *) other
                            options:(NSStringCompareOptions) options
                    templateOptions:(unsigned int) flags
{
   array_replace( [self arguments], s, other, options, flags);
}

@end

