//
//  NSObject+MulleScionDescription.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
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


#import "NSObject+MulleScionDescription.h"
#import "MulleObjCCompilerSettings.h"
#import "MulleScionNull.h"


NSString   *MulleScionDateFormatterKey        = @"MulleScionDateFormatter";
NSString   *MulleScionNumberFormatterKey      = @"MulleScionNumberFormatter";
NSString   *MulleScionDateFormatKey           = @"MulleScionDateFormat";
NSString   *MulleScionNumberFormatKey         = @"MulleScionNumberFormat";
NSString   *MulleScionLocaleKey               = @"MulleScionLocale";
NSString   *MulleScionNilDescriptionKey       = @"MulleScionNilDescription";
NSString   *MulleScionStringLengthKey         = @"MulleScionStringLength";
NSString   *MulleScionStringEllipsisKey       = @"MulleScionStringEllipsis";


extern void  MULLE_NO_RETURN   MulleScionPrintingException( NSString *exceptionName, NSString *format, ...);


@implementation NSObject ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   return( [self description]);
}

@end


@implementation NSNull ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   NSString  *s;
   
   s = [context objectForKey:MulleScionNilDescriptionKey];
   if( ! s)
      return( @"");
   return( [s mulleScionDescriptionWithLocalVariables:context]);
}

@end


@implementation _MulleScionNull ( MulleScionDescription)

+ (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   NSString  *s;
   
   s = [context objectForKey:MulleScionNilDescriptionKey];
   if( ! s)
      return( @"");
   return( [s mulleScionDescriptionWithLocalVariables:context]);
}

@end


@implementation NSString ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   NSString     *s;
   NSString     *cut;
   NSString     *ellipsis;
   NSUInteger   length;
   NSUInteger   max;
   
   s = [context objectForKey:MulleScionStringLengthKey];
   if( ! s)
      return( self);
   
   if( ! [s respondsToSelector:@selector( integerValue)])
      return( self);

   length = [self length];
   max    = [s integerValue];
   if( max >= length)
      return( self);

   cut      = [self substringToIndex:max];
   ellipsis = [context objectForKey:MulleScionStringEllipsisKey];
   if( ! ellipsis)
      return( cut);
   return( [NSString stringWithFormat:@"%@%@", cut, ellipsis]);
}

@end


static NSLocale   *getLocale( NSMutableDictionary *context)
{
   id   locale;
   
   locale = [context objectForKey:MulleScionLocaleKey];
   if( ! locale)
      return( nil);
   
   if( [locale isKindOfClass:[NSLocale class]])
      return( locale);
   
   locale = [locale description];
   locale = [[[NSLocale alloc] initWithLocaleIdentifier:locale] autorelease];
   if( ! locale)
      MulleScionPrintingException( NSInvalidArgumentException, @"%@ must be a locale name or a NSLocale",
                           MulleScionLocaleKey, context);
   return( nil);
}


static id   getFormatter( NSMutableDictionary *context, NSString *key, Class cls)
{
   id   formatter;
   
   formatter = [context objectForKey:key];
   if( ! formatter)
      return( nil);
   
   if( [formatter isKindOfClass:cls])
      return( formatter);

   MulleScionPrintingException( NSInvalidArgumentException, @"%@ must be a %@",
                          key, cls, context);
   return( nil);
}


static NSString   *getFormat( NSMutableDictionary *context, NSString *key)
{
   NSString *format;

   format = [context objectForKey:key];
   if( ! format)
      return( nil);
   format = [format description];
   if( ! [format length])
      return( nil);
   return( format);
}


@implementation NSNumber ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   NSLocale            *locale;
   NSNumberFormatter   *formatter;
   NSString            *format;
   
   locale    = getLocale( context);
   formatter = getFormatter( context, MulleScionNumberFormatterKey, [NSNumberFormatter class]);
   format    = getFormat( context, MulleScionNumberFormatKey);
   if( ! formatter)
   {
      if( ! format)
         return( [self descriptionWithLocale:locale]);
   
      formatter = [[NSNumberFormatter new] autorelease];
#if ! TARGET_OS_IPHONE
      if( [NSNumberFormatter defaultFormatterBehavior] == 1000)
         [formatter setLocalizesFormat:YES];
#endif
      
      [context setObject:formatter
                  forKey:MulleScionNumberFormatterKey];
   }
#if ! TARGET_OS_IPHONE
   [formatter setFormat:format];
#else
   {
      NSArray   *components;
      
      components = [format componentsSeparatedByString:@";"];
      if( [components count] == 3)
      {
         [formatter setPositiveFormat:[components objectAtIndex:0]];
         [formatter setZeroSymbol:[components objectAtIndex:1]];
         [formatter setNegativeFormat:[components objectAtIndex:2]];
      }
   }
#endif
   [formatter setLocale:locale];
   return( [formatter stringFromNumber:self]);
}

@end


@implementation NSDate ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context
{
   NSLocale          *locale;
   NSDateFormatter   *formatter;
   NSString          *format;
   BOOL              reformat;
   BOOL              relocalize;
   
   locale    = [context objectForKey:MulleScionLocaleKey];
   format    = [[context objectForKey:MulleScionDateFormatKey] description];
   formatter = [context objectForKey:MulleScionDateFormatterKey];

   if( formatter)
   {
      reformat   = format && ! [format isEqualToString:[formatter dateFormat]];
      relocalize = locale && ! [locale isEqual:[formatter locale]];

      if( (reformat || relocalize) && [formatter formatterBehavior] == 1000)
         formatter = nil;
   }
   
   if( ! formatter)
   {
      if( ! format)
         return( [self descriptionWithLocale:locale]);
      
#if ! TARGET_OS_IPHONE
      if( [NSDateFormatter defaultFormatterBehavior] == 1000)
      {
         // preferred for strftime compatibility
         formatter = [[[NSDateFormatter alloc] initWithDateFormat:format
                                             allowNaturalLanguage:YES] autorelease];
         [context setObject:formatter
                     forKey:MulleScionDateFormatterKey];
         return( [formatter stringForObjectValue:self]);
      }
#endif
      
      formatter = [[NSDateFormatter new] autorelease];
      [context setObject:formatter
                  forKey:MulleScionDateFormatterKey];
      
      reformat   = YES;
      relocalize = YES;
   }

   if( reformat)
      [formatter setDateFormat:format];
   if( relocalize)
      [formatter setLocale:locale];
   
   return( [formatter stringFromDate:self]);
}

@end

