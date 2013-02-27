//
//  NSObject+MulleScionDescription.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSObject+MulleScionDescription.h"
#import "MulleObjCCompilerSettings.h"


NSString   *MulleScionDateFormatterKey        = @"MulleScionDateFormatter";
NSString   *MulleScionNumberFormatterKey      = @"MulleScionNumberFormatter";
NSString   *MulleScionDateFormatKey           = @"MulleScionDateFormat";
NSString   *MulleScionNumberFormatKey         = @"MulleScionNumberFormat";
NSString   *MulleScionLocaleKey               = @"MulleScionLocale";
NSString   *MulleScionNSNullDescriptionKey    = @"MulleScionNullDescription";
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
   
   s = [context objectForKey:MulleScionNSNullDescriptionKey];
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
      if( [NSDateFormatter defaultFormatterBehavior] == 1000)
         [formatter setLocalizesFormat:YES];
      else
         formatter = [[NSNumberFormatter new] autorelease];
      
      [context setObject:formatter
                  forKey:MulleScionNumberFormatterKey];
   }
   [formatter setFormat:format];
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
   
   locale    = [context objectForKey:MulleScionLocaleKey];
   format    = [[context objectForKey:MulleScionDateFormatKey] description];
   formatter = [context objectForKey:MulleScionDateFormatterKey];
   if( ! formatter)
   {
      if( ! format)
         return( [self descriptionWithLocale:locale]);
      
      if( [NSDateFormatter defaultFormatterBehavior] == 1000)
      {
         // preferred for strftime compatibility
         formatter = [[[NSDateFormatter alloc] initWithDateFormat:format
                                             allowNaturalLanguage:YES] autorelease];
      }
      else
         formatter = [[NSDateFormatter new] autorelease];
      [context setObject:formatter
                  forKey:MulleScionDateFormatterKey];
   }
   if( format)
      [formatter setDateFormat:format];
   [formatter setLocale:locale];
   return( [formatter stringFromDate:self]);
}

@end

