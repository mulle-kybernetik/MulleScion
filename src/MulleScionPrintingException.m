//
//  MulleScionException.m
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionPrintingException.h"

#import "MulleScionObjectModel+Printing.h"


void  MULLE_NO_RETURN   MulleScionPrintingException( NSString *exceptionName, NSString *format, ...)
{
   va_list               args;
   NSString              *s;
   NSMutableDictionary   *locals;
   
   va_start( args, format);
   s = [[[NSString alloc] initWithFormat:format
                               arguments:args] autorelease];
   locals = va_arg( args, NSMutableDictionary *);
   NSCParameterAssert( [locals isKindOfClass:[NSMutableDictionary class]]);
   
   va_end( args);
   
   [NSException raise:exceptionName
               format:@"%@ %@: %@",
    [locals valueForKey:MulleScionCurrentFileKey],
    [locals valueForKey:MulleScionCurrentLineKey],
    s];
}


void  MulleScionPrintingValidateArgumentCount( NSArray *arguments, NSUInteger n,  NSMutableDictionary *locals)
{
   if( [arguments count] == n)
      return;
   
   MulleScionPrintingException( NSInvalidArgumentException, @"%@ expects %ld arguments",
                       [locals valueForKey:MulleScionCurrentFunctionKey],
                       (long) n,
                       locals);
}


id   MulleScionPrintingValidatedArgument( NSArray *arguments, NSUInteger i,  Class cls, NSMutableDictionary *locals)
{
   id   value;
   
   value = [arguments objectAtIndex:i];
   if( ! value || [value isKindOfClass:cls])
      return( value);
   
   MulleScionPrintingException( NSInvalidArgumentException, @"%@ expects a %@ as argument #%ld",
                       [locals valueForKey:MulleScionCurrentFunctionKey],
                       cls,
                       (long) i,
                       locals);
}

