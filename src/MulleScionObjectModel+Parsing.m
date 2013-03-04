//
//  MulleScionObjectModel+Parsing.m
//  MulleScionTemplates
//
//  Created by Nat! on 01.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+Parsing.h"


@implementation MulleScionObject (Parsing)

- (MulleScionObject *) behead
{
   MulleScionObject   *obj;
   
   obj = self->next_;
   self->next_ = nil;
   return( obj);
}


- (MulleScionObject *) tail
{
   MulleScionObject   *obj;
   
   for( obj = self; obj->next_; obj = obj->next_);
   return( obj);
}


- (NSUInteger) count;
{
   MulleScionObject  *obj;
   NSUInteger        n;
   
   n = 1;
   for( obj = self; obj->next_; obj = obj->next_)
      ++n;
   return( n);
}


- (id) appendRetainedObject:(MulleScionObject *) NS_CONSUMED  p
{
   MulleScionObject  *obj;
   
   NSParameterAssert( [p isKindOfClass:[MulleScionObject class]]);
   NSParameterAssert( ! self->next_);
   // NSParameterAssert( ! p->next_ || [p isBlock] || [p isKindOfClass:[MulleScionTemplate class]]);
   
   self->next_ = p;
   for( obj = p; obj->next_; obj = obj->next_);
   return( obj);
}

@end
