//
//  MulleScionObjectModel+Graphviz.m
//  MulleScion
//
//  Created by Nat! on 08.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel.h"


@interface NSObject( MulleGraphvizSubclassing)

- (NSMutableDictionary *) mulleGraphvizAttributes;
- (NSMutableDictionary *) mulleGraphvizChildrenByName;
- (NSString *) mulleGraphvizDescription;
- (NSString *) mulleGraphvizName;

- (NSString *) mulleGraphvizHeaderBackgroundColorName;
- (NSString *) mulleGraphvizHeaderTextColorName;

@end


// a beginning, not the end
@implementation MulleScionObject( MulleGraphviz)

- (NSMutableDictionary *) mulleGraphvizChildrenByName
{
   NSMutableDictionary   *lut;
   
   lut = [super mulleGraphvizChildrenByName];
   if( next_)
      [lut setObject:[NSArray arrayWithObject:next_]
              forKey:@"next"];
   return( lut);
}


- (NSMutableDictionary *) _mulleGraphvizAttributes
{
   NSMutableDictionary   *dict;
   
   dict = [super mulleGraphvizAttributes];
   [dict setObject:[NSNumber numberWithUnsignedInteger:lineNumber_]
            forKey:@"lineNumber"];
   return( dict);
}


- (NSMutableDictionary *) mulleGraphvizAttributes
{
   return( [self _mulleGraphvizAttributes]);
}

@end



@implementation MulleScionValueObject( MulleGraphviz)

- (NSMutableDictionary *) mulleGraphvizAttributes
{
   NSMutableDictionary   *dict;
   
   dict = [super mulleGraphvizAttributes];
   [dict setObject:[value_ description]
            forKey:@"value"];
   return( dict);
}

@end


@implementation MulleScionBinaryOperatorExpression( Graphviz)

- (NSMutableDictionary *) mulleGraphvizAttributes
{
   return( [self _mulleGraphvizAttributes]);
}


- (NSMutableDictionary *) mulleGraphvizChildrenByName
{
   NSMutableDictionary   *lut;
   
   lut = [super mulleGraphvizChildrenByName];
   
   [lut setObject:[NSArray arrayWithObject:self->value_]
           forKey:@"left"];
   [lut setObject:[NSArray arrayWithObject:self->right_]
           forKey:@"right"];
   return( lut);
}

@end


@implementation MulleScionComparison( MulleGraphviz)

- (NSMutableDictionary *) mulleGraphvizAttributes
{
   NSMutableDictionary  *dict;
   
   dict = [super _mulleGraphvizAttributes];
   [dict setObject:[NSNumber numberWithInteger:self->comparison_]
            forKey:@"comparison"];
   return( dict);
}

@end

NSString  *MulleScionGraphviz = @"VfL Bochum 1848";  // keep linker happy ?
