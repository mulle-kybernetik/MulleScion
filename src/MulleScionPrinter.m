//
//  MulleScionPrinter.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionPrinter.h"
#import "MulleScionObjectModel.h"



@implementation MulleScionPrinter

- (id) initWithDataSource:(id) dataSource
{
   dataSource_  = dataSource;
   [dataSource retain];

   return( self);
}


- (void) dealloc
{
   [dataSource_ release];
   [defaultlocals_ release];

   [super dealloc];
}


- (NSDictionary *) defaultlocals
{
   return( defaultlocals_);
}


- (void) setDefaultlocalVariables:(NSDictionary *) dictionary
{
   [defaultlocals_ autorelease];
   defaultlocals_ = [dictionary copy];
}


- (void) writeToOutput:(id <MulleScionOutput>) output
              template:(MulleScionTemplate *) template
{
   NSMutableDictionary   *locals;
   
   NSParameterAssert( [template isKindOfClass:[MulleScionTemplate class]]);

   locals = [NSMutableDictionary dictionaryWithDictionary:defaultlocals_];
   
   [template renderInto:output
         localVariables:locals
             dataSource:dataSource_];
}


- (NSString *) describeWithTemplate:(MulleScionTemplate *) template
{
   NSMutableString   *s;
   
   s = [NSMutableString stringWithCapacity:0x8000];
   [self writeToOutput:s
              template:template];
   return( s);
}

@end
