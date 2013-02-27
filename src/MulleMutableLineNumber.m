//
//  NSLineCountNumber.m
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleMutableLineNumber.h"


@implementation MulleMutableLineNumber

- (void) setUnsignedInteger:(NSUInteger) value;
{
   lineNumber_ = value;
}

- (char) charValue                           { return( (char) lineNumber_); }
- (unsigned char) unsignedCharValue          { return( (unsigned char) lineNumber_); }
- (short) shortValue                         { return( (short) lineNumber_); }
- (unsigned short) unsignedShortValue        { return( (unsigned short) lineNumber_); }
- (int) intValue                             { return( (int) lineNumber_); }
- (unsigned int) unsignedIntValue            { return( (unsigned int) lineNumber_); }
- (long) longValue                           { return( (long) lineNumber_); }
- (unsigned long) unsignedLongValue          { return( (unsigned long) lineNumber_); }
- (long long) longLongValue                  { return( (long long) lineNumber_); }
- (unsigned long long) unsignedLongLongValue { return( (unsigned long long) lineNumber_); }
- (float) floatValue                         { return( (float) lineNumber_); }
- (double) doubleValue                       { return( (double) lineNumber_); }
- (BOOL) boolValue                           { return( lineNumber_ ? YES : NO); }


// don't bother with these
- (NSString *) stringValue
{
   return( [[NSNumber numberWithUnsignedInteger:lineNumber_] stringValue]);
}

- (NSComparisonResult) compare:(NSNumber *) otherNumber
{
   return( [[NSNumber numberWithUnsignedInteger:lineNumber_] compare:otherNumber]);
}

- (BOOL) isEqualToNumber:(NSNumber *) number
{
   return( [[NSNumber numberWithUnsignedInteger:lineNumber_] isEqualToNumber:number]);
}

- (NSString *) descriptionWithLocale:(id) locale
{
   return( [[NSNumber numberWithUnsignedInteger:lineNumber_] descriptionWithLocale:locale]);
}

@end
