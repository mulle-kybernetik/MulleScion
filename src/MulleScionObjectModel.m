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


+ (id) allocWithZone:(NSZone *)zone
{
   id  p;
   
   p = [super allocWithZone:zone];
   // we will take undefined behaviour, thank you :)
#ifdef SIMPLE_SCOREBOARD
   fprintf( stderr, "%0.*p alive %s\n", (int) sizeof( void *) << 1, p, [NSStringFromClass( self) cString]);
#endif
   return( p);
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

#if defined( DEBUG) && defined( SIMPLE_SCOREBOARD)
   // take the output, sort it and check for even alive/dead pattern
   fprintf( stderr, "%0.*p dead  %s \n", (int) sizeof( void *) << 1, self, [NSStringFromClass( isa) cString]);  // sic!
#endif
   [super dealloc];
}


- (BOOL) isIdentifier { return( NO); }
- (BOOL) isTerminator { return( NO); }
- (BOOL) isTemplate   { return( NO); }
- (BOOL) isFunction   { return( NO); }
- (BOOL) isMethod     { return( NO); }
- (BOOL) isVariableAssignment { return( NO); }

- (BOOL) isSet        { return( NO); }

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


- (BOOL) isTemplate
{
   return( YES);
}


- (NSString *) fileName
{
   return( value_);
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


@implementation MulleScionSelector
@end


@implementation MulleScionArray

+ (id) newWithArray:(NSArray *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSArray class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end


@implementation MulleScionIdentifierExpression

+ (id) newWithIdentifier:(NSString *) s
              lineNumber:(NSUInteger) nr
{
   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   return( newMulleScionValueObject( self, s, nr));
}


- (NSString *) identifier
{
   return( value_);
}

@end



@implementation MulleScionVariable

- (BOOL) isIdentifier
{
   return( YES);
}

@end


@implementation MulleScionFunction

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


- (void) dealloc
{
   [arguments_ release];

   [super dealloc];
}


- (BOOL) isFunction
{
   return( YES);
}


- (NSArray *) arguments
{
   return( arguments_);
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


- (BOOL) isMethod
{
   return( YES);
}

@end


@implementation MulleScionVariableAssignment

+ (id) newWithIdentifier:(NSString *) s
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr
{
   MulleScionVariableAssignment   *p;

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


- (NSString *) identifier
{
   return( self->value_);
}


- (MulleScionExpression *) expression
{
   return( self->expression_);
}


- (BOOL) isVariableAssignment
{
   return( YES);
}

@end


@implementation MulleScionOperatorExpression

- (NSString *) operator
{
#if DEBUG
   abort();
#endif
   return( nil);
}

@end


@implementation MulleScionUnaryOperatorExpression

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                      lineNumber:(NSUInteger) nr
{
   MulleScionUnaryOperatorExpression   *p;
   
   NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);
   
   p = newMulleScionValueObject( self, nil, nr);
   p->value_ = expr;
   return( p);
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

@end


@implementation MulleScionComparison

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          comparison:(MulleScionComparisonOperator) op
                          lineNumber:(NSUInteger) nr;
{
   MulleScionComparison   *p;
   
   NSParameterAssert( [left isKindOfClass:[MulleScionExpression class]]);
   NSParameterAssert( [right isKindOfClass:[MulleScionExpression class]]);
   
   p = newMulleScionValueObject( self, nil, nr);
   p->value_      = left;  
   p->right_      = right;
   p->comparison_ = op;
   return( p);
}


- (NSString *) operator
{
   switch( comparison_)
   {
   case MulleScionEqual                : return( @"==");
   case MulleScionNotEqual             : return( @"!=");
   case MulleScionLessThan             : return( @"<");
   case MulleScionGreaterThan          : return( @">");
   case MulleScionLessThanOrEqualTo    : return( @"<=");
   case MulleScionGreaterThanOrEqualTo : return( @">=");
   }
}

@end


@implementation MulleScionNot

- (NSString *) operator
{
   return( @"not");
}

@end


@implementation MulleScionAnd

- (NSString *) operator
{
   return( @"and");
}

@end


@implementation MulleScionOr

- (NSString *) operator
{
   return( @"or");
}

@end


@implementation MulleScionIndexing

- (NSString *) operator
{
   return( @"[]");
}

@end


@implementation MulleScionPipe

- (BOOL) isPipe
{
   return( YES);
}


- (NSString *) operator
{
   return( @"|");
}

@end


@implementation MulleScionDot

- (BOOL) isDot
{
   return( YES);
}


- (NSString *) operator
{
   return( @",");
}


@end


@implementation MulleScionConditional

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
            retainedMiddleExpression:(MulleScionExpression *) NS_CONSUMED middle
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr
{
   MulleScionConditional   *p;
   
   NSParameterAssert( [left isKindOfClass:[MulleScionExpression class]]);
   NSParameterAssert( [middle isKindOfClass:[MulleScionExpression class]]);
   NSParameterAssert( [right isKindOfClass:[MulleScionExpression class]]);
   
   p = newMulleScionValueObject( self, nil, nr);
   p->value_      = left;
   p->middle_     = middle;
   p->right_      = right;
   return( p);
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
         if( stack == 1)
            return( curr);
      
      if( cls == terminatorCls)
         if( ! --stack)
            return( curr);
   }
   return( curr);
}

@end


@implementation MulleScionTerminator

- (BOOL) isTerminator
{
   return( YES);
}

@end


@implementation MulleScionSet

- (NSString *) commandName
{
   return( @"");
}

+ (id) newWithIdentifier:(NSString *) s
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr
{
   MulleScionSet   *p;
   
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


- (BOOL) isSet
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
                fileName:(NSString *) fileName
              lineNumber:(NSUInteger) nr
{
   MulleScionBlock   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]] && [s length]);
   
   p              = [self newWithLineNumber:nr];
   p->identifier_ = [s copy];
   p->fileName_   = [fileName copy];
   return( p);
}


- (void) dealloc
{
   [identifier_ release];
   [fileName_ release];
   
   [super dealloc];
}


- (BOOL) isBlock
{
   return( YES);
}


- (NSString *) fileName
{
   return( fileName_);
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


@implementation MulleScionMacro

+ (id) newWithIdentifier:(NSString *) s
                function:(MulleScionFunction *) function
                    body:(MulleScionTemplate *) body
                fileName:(NSString *) fileName
              lineNumber:(NSUInteger) nr
{
   MulleScionMacro   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]]);
   NSParameterAssert( [function isKindOfClass:[MulleScionFunction class]]);
   NSParameterAssert( [body isKindOfClass:[MulleScionTemplate class]]);
   
   p              = [self newWithValue:fileName
                            lineNumber:nr];
   p->identifier_ = [s copy];
   p->function_   = [function retain];
   p->body_       = [body retain];
   
   return( p);
}


- (void) dealloc
{
   [body_ release];
   [function_ release];
   [identifier_ release];
   
   [super dealloc];
}


- (NSString *) identifier
{
   return( identifier_);
}


- (MulleScionFunction *) function
{
   return( function_);
}


- (MulleScionTemplate *) body
{
   return( body_);
}


- (BOOL) isTemplate
{
   return( NO);
}

@end

