//
//  NSLineCountNumber.m
//  MulleScion
//
//  Created by Nat! on 25.02.13.
//
//  Copyright (c) 2013 Nat! - Mulle kybernetiK
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//


#import "MulleMutableLineNumber.h"


@implementation MulleMutableLineNumber

- (void) setUnsignedInteger:(NSUInteger) value
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
