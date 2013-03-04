//
//  MulleScionException.m
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionPrintingException.h"

#import "MulleScionObjectModel+Printing.h"
#import "MulleScionNull.h"


void  MULLE_NO_RETURN   MulleScionPrintingException( NSString *exceptionName, NSDictionary *locals, NSString *format, ...)
{
   va_list        args;
   NSString       *s;

   NSCParameterAssert( [exceptionName isKindOfClass:[NSString class]]);
   NSCParameterAssert( [locals isKindOfClass:[NSDictionary class]]);
   NSCParameterAssert( [format isKindOfClass:[NSString class]]);
   
   va_start( args, format);
   s = [[[NSString alloc] initWithFormat:format
                               arguments:args] autorelease];
   
   va_end( args);
   
   [NSException raise:exceptionName
               format:@"%@ %@: %@",
    [locals valueForKey:MulleScionCurrentFileKey],
    [locals valueForKey:MulleScionCurrentLineKey],
    s];
   abort();
}


void  MulleScionPrintingValidateArgumentCount( NSArray *arguments, NSUInteger n,  NSDictionary *locals)
{
   if( [arguments count] == n)
      return;
   
   MulleScionPrintingException( NSInvalidArgumentException, locals,
                               @"%@ expects %ld arguments",
                               [locals valueForKey:MulleScionCurrentFunctionKey],
                               (long) n,
                               locals);
}


id   MulleScionPrintingValidatedArgument( NSArray *arguments, NSUInteger i,  Class cls, NSDictionary *locals)
{
   id   value;
   
   value = [arguments objectAtIndex:i];
   if( value == MulleScionNull)
      return( nil);
   
   if( ! cls || [value isKindOfClass:cls])
      return( value);
   
   MulleScionPrintingException( NSInvalidArgumentException, locals,
                               @"%@ expects a %@ as argument #%ld",
                               [locals valueForKey:MulleScionCurrentFunctionKey],
                               cls,
                               (long) i);
}

