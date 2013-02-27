//
//  MulleScionObjectModel.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel.h"
#import "MulleScionObjectModel+NSCoding.h"


@implementation MulleScionObject

#if DEBUG
- (id) init
{
   abort();
}
#endif


+ (id) newWithLineNumber:(NSUInteger) nr
{
   return( [[self alloc] initWithLineNumber:nr]);
}


- (id) initWithLineNumber:(NSUInteger) nr
{
   lineNumber_ = nr;
   return( self);
}


- (void) dealloc
{
   [self->next_ release];
   
   [super dealloc];
}


- (MulleScionObject *) tail
{
   MulleScionObject *obj;
   
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


- (id) appendRetainedObject:(MulleScionObject *) NS_CONSUMED  obj
{
   NSParameterAssert( [obj isKindOfClass:[MulleScionObject class]]);
   NSParameterAssert( ! self->next_);
   NSParameterAssert( ! obj->next_ || [obj isBlock] || [obj isKindOfClass:[MulleScionTemplate class]]);
   
   self->next_ = obj;
   while( obj->next_)
      obj = obj->next_;
   return( obj);
}

- (BOOL) isIdentifier { return( NO); }
- (BOOL) isTerminator { return( NO); }
- (BOOL) isTemplate   { return( NO); }

- (BOOL) isLet        { return( NO); }

- (BOOL) isIf         { return( NO); }
- (BOOL) isElse       { return( NO); }
- (BOOL) isEndIf      { return( NO); }

- (BOOL) isFor        { return( NO); }
- (BOOL) isEndFor     { return( NO); }

- (BOOL) isWhile      { return( NO); }
- (BOOL) isEndWhile   { return( NO); }

- (BOOL) isBlock      { return( NO); }
- (BOOL) isEndBlock   { return( NO); }

- (BOOL) isPipe       { return( NO); }
- (BOOL) isDot        { return( NO); }

- (BOOL) isExtends    { return( NO); }
- (BOOL) isIncludes   { return( NO); }

- (Class) terminatorClass
{
   return( Nil);
}


- (NSUInteger) lineNumber
{
   return( lineNumber_);
}

- (MulleScionObject *) nextOwnerOfBlock
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
      if( [curr->next_ isBlock])
         break;
   return( curr);
}


- (MulleScionObject *) ownerOfBlockWithIdentifier:(NSString *) identifier
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
      if( [curr->next_ isBlock])
         if( [identifier isEqualToString:[(MulleScionBlock *) curr->next_ identifier]])
            break;
   return( curr);
}


// replacement must be copy
- (void) replaceOwnedBlockWith:(MulleScionObject *) replacement
{
   MulleScionBlock      *block;
   MulleScionObject     *endBlock;
   MulleScionObject     *replacementEnd;
   
   NSParameterAssert( [self->next_ isBlock]);
   NSParameterAssert( [replacement isKindOfClass:[MulleScionObject class]]);
   
   block    = (MulleScionBlock *) self->next_;
   endBlock = [block terminateToEnd:block->next_];
   
   NSParameterAssert( [endBlock isEndBlock]);
   
   for( replacementEnd = replacement; replacementEnd; replacementEnd = replacementEnd->next_)
      if( ! replacementEnd->next_)
         break;
   
   self->next_           = [replacement retain];
   replacementEnd->next_ = endBlock->next_;
   endBlock->next_       = nil;

   [block release];
}

@end


@implementation MulleScionValueObject

static id   newMulleScionValueObject( Class self, id value, NSUInteger nr)
{
   MulleScionValueObject   *p;
   
   p = [self newWithLineNumber:nr];
   p->value_ = [value copy];
   return( p);
}


+ (id) newWithValue:(id <NSCopying>) value
         lineNumber:(NSUInteger) nr
{
   return( newMulleScionValueObject( self, value, nr));
}


- (id) initWithValue:(id) value
          lineNumber:(NSUInteger) nr
{
   self = [self initWithLineNumber:nr];
   assert( self);
   
   value_ = [value copy];
   return( self);
}


- (void) dealloc
{
   [value_ release];
   
   [super dealloc];
}

@end


@implementation MulleScionTemplate

- (id) initWithFilename:(NSString *) name
{
   NSParameterAssert( ! name || [name isKindOfClass:[NSString class]]);

   if( ! name)
      name = @"template";
   return( [self initWithValue:name
                    lineNumber:0]);
}


- (void) expandBlocksUsingTable:(NSDictionary *) table
{
   NSString             *identifier;
   MulleScionBlock      *block;
   MulleScionObject     *owner;
   MulleScionObject     *chain;
   
   owner = self;
   while( owner = [owner nextOwnerOfBlock])
   {
      block      = (MulleScionBlock *) owner->next_;
      identifier = [block identifier];
      chain      = [table objectForKey:identifier];
      if( ! chain)
      {
         owner = block;
         continue;
      }

      //
      // use NSCoding to make a copy, so I don't have to write all those
      // copy routines
      //
      chain = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:chain]];
      [owner replaceOwnedBlockWith:chain];
   }
}


- (BOOL) isTemplate
{
   return( YES);
}

@end


@implementation MulleScionPlainText

+ (id) newWithRetainedString:(NSString *) NS_CONSUMED s
                  lineNumber:(NSUInteger) nr
{
   MulleScionPlainText   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]]);

   p = newMulleScionValueObject( self, nil, nr);
   p->value_ = s;
   return( p);
}

@end


@implementation MulleScionExpression
@end



@implementation MulleScionNumber

+ (id) newWithNumber:(NSNumber *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSNumber class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end



@implementation MulleScionString

+ (id) newWithString:(NSString *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSString class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end


@implementation MulleScionArray

+ (id) newWithArray:(NSArray *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSArray class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end


@implementation MulleScionVariable

+ (id) newWithIdentifier:(NSString *) s
              lineNumber:(NSUInteger) nr
{
   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   return( newMulleScionValueObject( self, s, nr));
}


- (BOOL) isIdentifier
{
   return( YES);
}


- (NSString *) identifier
{
   return( value_);
}

@end


@implementation MulleScionFunction : MulleScionExpression

+ (id) newWithIdentifier:(NSString *) s
               arguments:(NSArray *) arguments
              lineNumber:(NSUInteger) nr;
{
   MulleScionFunction   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]]);
   NSParameterAssert( ! arguments || [arguments isKindOfClass:[NSArray class]]);
   
   p             = newMulleScionValueObject( self, s, nr);
   p->arguments_ = [arguments copy];
   return( p);
}

@end


@implementation MulleScionVariableAssigment

+ (id) newWithIdentifier:(NSString *) s
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr
{
   MulleScionVariableAssigment   *p;

   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);

   p = newMulleScionValueObject( self, s, nr);
   p->expression_ = expr;
   return( p);
}


- (void) dealloc
{
   [expression_ release];
   
   [super dealloc];
}

@end


@implementation MulleScionBinaryOperatorExpression

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr
{
   MulleScionBinaryOperatorExpression   *p;
   
   NSParameterAssert( [left isKindOfClass:[MulleScionExpression class]]);
   NSParameterAssert( [right isKindOfClass:[MulleScionExpression class]]);
   
   p = newMulleScionValueObject( self, nil, nr);
   p->value_ = left;  // pipe is funny that way
   p->right_ = right;
   return( p);
}

- (void) dealloc
{
   [right_ release];
   
   [super dealloc];
}


- (NSString *) operator
{
#if DEBUG
   abort();
#endif
}

@end



@implementation MulleScionPipe : MulleScionBinaryOperatorExpression

- (BOOL) isPipe
{
   return( YES);
}


- (NSString *) operator
{
   return( @"|");
}


@end


@implementation MulleScionDot : MulleScionBinaryOperatorExpression

- (BOOL) isDot
{
   return( YES);
}


- (NSString *) operator
{
   return( @",");
}


@end


@implementation MulleScionMethod

+ (id) newWithRetainedTarget:(MulleScionExpression *) NS_CONSUMED target
                  methodName:(NSString *) methodName
                   arguments:(NSArray *) arguments
                  lineNumber:(NSUInteger) nr

{
   MulleScionMethod   *p;

   NSParameterAssert( [target isKindOfClass:[MulleScionExpression class]]);
   NSParameterAssert( [methodName isKindOfClass:[NSString class]] && [methodName length]);
   NSParameterAssert( ! arguments || [arguments isKindOfClass:[NSArray class]]);

   p             = newMulleScionValueObject( self, nil, nr);
   p->value_     = target;
   p->action_    = NSSelectorFromString( methodName);
   p->arguments_ = [arguments copy];
   return( p);
}


- (void) dealloc
{
   [arguments_ release];

   [super dealloc];
}

@end


@implementation MulleScionCommand

- (NSString *) commandName
{
   NSString  *s;
   
   s = NSStringFromClass( isa);
   if( [s hasPrefix:@"MulleScion"])
   {
      s = [s substringFromIndex:10];
      s = [s lowercaseString];
   }
   return( s);
}


- (MulleScionObject *) terminateToEnd:(MulleScionObject *) curr
{
   Class        cls;
   Class        terminatorCls;
   NSUInteger   stack;
   
   stack         = 1;
   terminatorCls = [self terminatorClass];
   
   for( ; curr; curr = curr->next_)
   {
      cls = [curr class];
      if( cls == isa)
      {
         ++stack;
         continue;
      }
      
      if( cls == terminatorCls)
      {
         if( ! --stack)
            return( curr);
      }
      
      // nested codes ? slurp them
      if( [curr terminatorClass])
         curr = [self terminateToEnd:curr];
      
   }
   return( curr);
}


- (MulleScionObject *) terminateToElse:(MulleScionObject *) curr
{
   Class        cls;
   Class        terminatorCls;
   NSUInteger   stack;
   
   stack         = 1;
   terminatorCls = [self terminatorClass];
   
   for( ; curr; curr = curr->next_)
   {
      cls = [curr class];
      if( cls == isa)
      {
         ++stack;
         continue;
      }
      
      if( [curr isElse])
         return( curr);
      
      if( cls == terminatorCls)
         if( ! --stack)
            return( curr);
      
      // nested codes ? slurp them
      if( [curr terminatorClass])
         curr = [self terminateToEnd:curr];
   }
   return( curr);
}

@end


@implementation MulleScionTerminator : MulleScionCommand

- (BOOL) isTerminator
{
   return( YES);
}

@end


@implementation MulleScionLet

- (NSString *) commandName
{
   return( @"");
}

+ (id) newWithIdentifier:(NSString *) s
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr
{
   MulleScionLet   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);
   
   p              = [self newWithLineNumber:nr];
   p->identifier_ = [s copy];
   p->expression_ = expr;
   return( p);
}


- (void) dealloc
{
   [expression_ release];
   [identifier_ release];
   
   [super dealloc];
}


- (BOOL) isLet
{
   return( YES);
}

@end


@implementation MulleScionFor

- (NSString *) commandName
{
   return( @"for");
}


- (BOOL) isFor
{
   return( YES);
}


- (Class) terminatorClass
{
   return( [MulleScionEndFor class]);
}

@end


@implementation MulleScionEndFor

- (BOOL) isEndFor
{
   return( YES);
}

@end


@implementation MulleScionExpressionCommand

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                      lineNumber:(NSUInteger) nr
{
   MulleScionExpressionCommand   *p;
   
   NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);
   
   p = [self newWithLineNumber:nr];
   p->expression_ = expr;
   return( p);
}


- (void) dealloc
{
   [expression_ release];
   [super dealloc];
}

@end


@implementation MulleScionIf

- (BOOL) isIf
{
   return( YES);
}


- (Class) terminatorClass
{
   return( [MulleScionEndIf class]);
}


@end


@implementation MulleScionElse

- (BOOL) isElse
{
   return( YES);
}

@end


@implementation MulleScionEndIf

- (BOOL) isEndIf
{
   return( YES);
}

@end


@implementation MulleScionWhile

- (BOOL) isWhile
{
   return( YES);
}


- (Class) terminatorClass
{
   return( [MulleScionEndWhile class]);
}

@end


@implementation MulleScionEndWhile

- (BOOL) isEndWhile
{
   return( YES);
}

@end


@implementation MulleScionBlock

+ (id) newWithIdentifier:(NSString *) s
              lineNumber:(NSUInteger) nr
{
   MulleScionBlock   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   
   p              = [self newWithLineNumber:nr];
   p->identifier_ = [s copy];
   return( p);
}


- (void) dealloc
{
   [identifier_ release];
   
   [super dealloc];
}


- (BOOL) isBlock
{
   return( YES);
}


- (NSString *) identifier
{
   return( identifier_);
}


- (Class) terminatorClass
{
   return( [MulleScionEndBlock class]);
}

@end


@implementation MulleScionEndBlock

- (BOOL) isEndBlock
{
   return( YES);
}

@end


@implementation MulleScionMethodCall

- (NSString *) commandName
{
   return( @"");
}

@end


@implementation MulleScionFunctionCall

- (NSString *) commandName
{
   return( @"");
}

@end


@implementation MulleScionFilter

@end


@implementation MulleScionEndFilter

@end

