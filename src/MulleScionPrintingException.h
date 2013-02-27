//
//  MulleScionException.h
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MulleObjCCompilerSettings.h"


void  MULLE_NO_RETURN   MulleScionPrintingException( NSString *exceptionName, NSString *format, ...);

void  MulleScionPrintingValidateArgumentCount( NSArray *arguments, NSUInteger n,  NSMutableDictionary *locals);
id    MulleScionPrintingValidatedArgument( NSArray *arguments, NSUInteger i,  Class cls, NSMutableDictionary *locals);
