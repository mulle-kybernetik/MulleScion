//
//  MulleScionObjectModel+NSCoding.m
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+NSCoding.h"


@implementation MulleScionObject ( NSCoding)

+ (void) load
{
   [self setVersion:1848];
}


- (id) initWithCoder:(NSCoder *) decoder
{
   unsigned long  lineNumber;
   id             next;
   
   [decoder decodeValuesOfObjCTypes:"L@", &lineNumber, &next];

   self = [self initWithLineNumber:lineNumber];
   assert( self);

   self->next_ = next;
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   unsigned long  lineNumber;

   lineNumber = lineNumber_;
   [encoder encodeValuesOfObjCTypes:"L@", &lineNumber, &next_];
}

@end


@implementation MulleScionValueObject ( NSCoding)

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@", &value_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@", &value_];
}

@end


@implementation MulleScionFunction ( NSCoding )

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@", &arguments_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@", &arguments_];
}

@end


@implementation MulleScionMethod ( NSCoding )

- (id) initWithCoder:(NSCoder *) decoder
{
   NSString  *methodName;
   
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@@", &arguments_, &methodName];
   action_ = NSSelectorFromString( methodName);
   [methodName release];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   NSString  *methodName;

   [super encodeWithCoder:encoder];
   methodName = NSStringFromSelector( action_);
   [encoder encodeValuesOfObjCTypes:"@@", &arguments_, &methodName];
}

@end


@implementation MulleScionBinaryOperatorExpression  ( NSCoding )

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@", &right_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@", &right_];
}

@end


@implementation MulleScionLet ( NSCoding )

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@@", &identifier_, &expression_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@@", &identifier_, &expression_];
}

@end


@implementation MulleScionExpressionCommand ( NSCoding)

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@", &expression_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@", &expression_];
}

@end


@implementation MulleScionBlock ( NSCoding)

- (id) initWithCoder:(NSCoder *) decoder
{
   self = [super initWithCoder:decoder];
   assert( self);
   
   [decoder decodeValuesOfObjCTypes:"@", &identifier_];
   return( self);
}


- (void) encodeWithCoder:(NSCoder *) encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeValuesOfObjCTypes:"@", &identifier_];
}

@end



