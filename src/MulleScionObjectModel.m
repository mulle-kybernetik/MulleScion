//
//  MulleScionObjectModel.m
//  MulleScion
//
//  Created by Nat! on 24.02.13.
//
//  Copyright (c) 2013 Nat! - Mulle kybernetiK
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "MulleScionObjectModel.h"

#import "MulleScionObjectModel+NSCoding.h"
#import "MulleCommonObjCRuntime.h"


@implementation MulleScionObject

#if DEBUG
- (id) init
{
   abort();
}


+ (id) allocWithZone:(NSZone *)zone NS_RETURNS_RETAINED
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
   NSParameterAssert( (NSInteger) nr >= 0);
   
   lineNumber_ = nr;
   return( self);
}


- (void) dealloc
{
   [self->next_ release];

#if defined( DEBUG) && defined( SIMPLE_SCOREBOARD)
   // take the output, sort it and check for even alive/dead pattern
   fprintf( stderr, "%0.*p dead  %s \n", (int) sizeof( void *) << 1, self, [NSStringFromClass( MulleGetClass( self)) cString]);  // sic!
#endif
   [super dealloc];
}


- (BOOL) isIdentifier  { return( NO); }
- (BOOL) isLexpr       { return( NO); }

- (BOOL) isTerminator { return( NO); }
- (BOOL) isTemplate   { return( NO); }
- (BOOL) isFunction   { return( NO); }
- (BOOL) isMethod     { return( NO); }
- (BOOL) isParameterAssignment { return( NO); }

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
- (BOOL) isIndexing   { return( NO); }

- (BOOL) isExtends    { return( NO); }
- (BOOL) isIncludes   { return( NO); }

- (BOOL) isDictionaryKey { return( NO); }
- (BOOL) isJustALinefeed { return( NO); }

- (BOOL) isMacro      { return( NO); }

   
- (Class) terminatorClass
{
   return( Nil);
}


- (Class) elseClass
{
   return( Nil);
}


- (NSUInteger) lineNumber
{
   return( lineNumber_);
}

@end


#pragma mark -

@implementation MulleScionValueObject

NS_RETURNS_RETAINED static id   newMulleScionValueObject( Class self, id value, NSUInteger nr)
{
   MulleScionValueObject   *p;
   
   p         = [self newWithLineNumber:nr];
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


//
// the exception of the rule, that we don't access the values in the parse
// but it's needed to get stuff out for dictionaries
//
- (id) value
{
   return( value_);
}


- (void) dealloc
{
   [value_ release];
   
   [super dealloc];
}

@end


#pragma mark -

@implementation MulleScionTemplate

#if DEBUG
- (void) dealloc
{
   [super dealloc];
}


- (oneway void) release
{
   [super release];
}

- (id) retain
{
   return( [super retain]);
}


- (id) autorelease
{
   return( [super autorelease]);
}

#endif


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


#pragma mark -

@implementation MulleScionPlainText

+ (id) newWithRetainedString:(NSString *) NS_CONSUMED s
                  lineNumber:(NSUInteger) nr
{
   MulleScionPlainText   *p;
   
   NSParameterAssert( [s isKindOfClass:[NSString class]]);

   p         = newMulleScionValueObject( self, nil, nr);
   p->value_ = s;
   return( p);
}

- (BOOL) isJustALinefeed
{
   return( [self->value_ isEqualToString:@"\n"]);
}
   
@end


#pragma mark -

@implementation MulleScionExpression
@end


#pragma mark -

@implementation MulleScionNumber

+ (id) newWithNumber:(NSNumber *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSNumber class]]);
   return( newMulleScionValueObject( self, value, nr));
}


- (BOOL) isDictionaryKey
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionString

+ (id) newWithString:(NSString *) value
          lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSString class]]);
   return( newMulleScionValueObject( self, value, nr));
}

- (BOOL) isDictionaryKey
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionSelector
@end


#pragma mark -

@implementation MulleScionArray

+ (id) newWithArray:(NSArray *) value
         lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSArray class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end

#pragma mark -

@implementation MulleScionDictionary
   
+ (id) newWithDictionary:(NSDictionary *) value
              lineNumber:(NSUInteger) nr
{
   NSParameterAssert( ! value || [value isKindOfClass:[NSDictionary class]]);
   return( newMulleScionValueObject( self, value, nr));
}

@end



#pragma mark -

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

   
- (BOOL) hasIdentifier
{
   return( YES);
}
   
@end


#pragma mark -

@implementation MulleScionVariable

- (BOOL) isIdentifier
{
   return( YES);
}

- (BOOL) isLexpr
{
   return( YES);
}

@end


#pragma mark -

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


#pragma mark -

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


#if DEBUG
- (void) release
{
   [super release];
}

- (id) retain
{
   return( [super retain]);
}


- (id) autorelease
{
   return( [super autorelease]);
}
#endif

- (BOOL) isMethod
{
   return( YES);
}


- (BOOL) isSelfMethod
{
   return( [value_ isIdentifier] && [[(MulleScionVariable *) value_ identifier] isEqualToString:@"self"]);
}

@end


#pragma mark -

@implementation MulleScionParameterAssignment

+ (id) newWithIdentifier:(NSString *) s
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr
{
   MulleScionParameterAssignment   *p;

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


- (BOOL) isParameterAssignment
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionOperatorExpression

- (NSString *) operator
{
#if DEBUG
   abort();
#endif
   return( nil);
}

@end


#pragma mark -

@implementation MulleScionUnaryOperatorExpression

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                      lineNumber:(NSUInteger) nr
{
   MulleScionUnaryOperatorExpression   *p;
   
   NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);
   
   p         = newMulleScionValueObject( self, nil, nr);
   p->value_ = expr;
   return( p);
}

@end


#pragma mark -

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


- (MulleScionBinaryOperatorExpression *) hierarchicalExchange:(MulleScionBinaryOperatorExpression *) other
{
   NSParameterAssert( [other isKindOfClass:[MulleScionBinaryOperatorExpression class]]);
   NSParameterAssert( other->right_ == self);

   // this is done during parsing, to move an operator
   // up in precedence (used for dot / pipe)
   other->right_ = self->value_;
   self->value_  = other;
   
   return( self);
}

@end


#pragma mark -

@implementation  MulleScionAssignmentExpression

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr
{
   MulleScionAssignmentExpression   *p;
   
   NSParameterAssert( [left isLexpr]);
   NSParameterAssert( [right isKindOfClass:[MulleScionExpression class]]);
   
   p = newMulleScionValueObject( self, nil, nr);
   p->value_ = left;
   p->right_ = right;
   return( p);
}

@end



#pragma mark -

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
   case MulleScionNoComparison         : break;  // should never happen!
   }
   return( @"???");
}

@end


#pragma mark -

@implementation MulleScionLog
@end


#pragma mark -

@implementation MulleScionNot

- (NSString *) operator
{
   return( @"not");
}

@end


#pragma mark -

@implementation MulleScionAnd

- (NSString *) operator
{
   return( @"and");
}

@end


#pragma mark -

@implementation MulleScionOr

- (NSString *) operator
{
   return( @"or");
}

@end


#pragma mark -

@implementation MulleScionIndexing

- (NSString *) operator
{
   return( @"[]");
}

   
- (BOOL) isIndexing
{
   return( YES);
}


- (BOOL) isLexpr
{
   return( YES);
}

@end


#pragma mark -

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


#pragma mark -

@implementation MulleScionDot

- (BOOL) isDot
{
   return( YES);
}


- (NSString *) operator
{
   return( @".");
}

@end


#pragma mark -

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


#pragma mark -

@implementation MulleScionCommand

- (NSString *) commandName
{
   NSString  *s;
   
   s = NSStringFromClass( MulleGetClass( self));
   if( [s hasPrefix:@"MulleScion"])
   {
      s = [s substringFromIndex:10];
      s = [s lowercaseString];
   }
   return( s);
}


- (MulleScionObject *) terminateToEnd:(MulleScionObject *) curr
{
   Class        selfCls;
   Class        currCls;
   Class        terminatorCls;
   NSUInteger   stack;
   
   stack         = 1;
   terminatorCls = [self terminatorClass];
   
   selfCls = MulleGetClass( self);
   for( ; curr; curr = curr->next_)
   {
      currCls = MulleGetClass( curr);
      if( currCls == selfCls)
      {
         ++stack;
         continue;
      }
      
      if( currCls == terminatorCls)
         if( ! --stack)
            return( curr);
   }
   return( curr);
}


#pragma mark -

- (MulleScionObject *) terminateToElse:(MulleScionObject *) curr
{
   Class        selfCls;
   Class        currCls;
   Class        elseCls;
   Class        terminatorCls;
   NSUInteger   stack;
   
   stack         = 1;
   terminatorCls = [self terminatorClass];
   elseCls       = [self elseClass];
   
   selfCls = MulleGetClass( self);
   for( ; curr; curr = curr->next_)
   {
      currCls = MulleGetClass( curr);
      if( currCls == selfCls)
      {
         ++stack;
         continue;
      }
      
      if( currCls == elseCls)
         if( stack == 1)
            return( curr);
      
      if( currCls == terminatorCls)
         if( ! --stack)
            return( curr);
   }
   return( curr);
}

@end


#pragma mark -

@implementation MulleScionTerminator

- (BOOL) isTerminator
{
   return( YES);
}

@end


#pragma mark - 

@implementation MulleScionSet

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr
{
   MulleScionSet   *p;
   
   p = [self newWithLineNumber:nr];
   p->left_  = left;
   p->right_ = right;
   
   return( p);
}


- (NSString *) commandName
{
   return( @""); // O RLY ?
}

   
- (BOOL) isSet
{
   return( YES);
}

@end


#pragma mark -

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


- (Class) elseClass
{
   return( [MulleScionElseFor class]);
}

@end


@implementation MulleScionEndFor

- (BOOL) isEndFor
{
   return( YES);
}

@end


#pragma mark -

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


#pragma mark -

@implementation MulleScionIf

- (BOOL) isIf
{
   return( YES);
}


- (Class) terminatorClass
{
   return( [MulleScionEndIf class]);
}


- (Class) elseClass
{
   return( [MulleScionElse class]);
}

@end


#pragma mark -

@implementation MulleScionElse

- (BOOL) isElse
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionElseFor
@end


#pragma mark -

@implementation MulleScionEndIf

- (BOOL) isEndIf
{
   return( YES);
}

@end


#pragma mark -

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


#pragma mark -

@implementation MulleScionEndWhile

- (BOOL) isEndWhile
{
   return( YES);
}

@end


#pragma mark -

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


#pragma mark -

@implementation MulleScionEndBlock

- (BOOL) isEndBlock
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionMethodCall

- (NSString *) commandName
{
   return( @"");
}

@end


#pragma mark -

@implementation MulleScionFunctionCall

- (NSString *) commandName
{
   return( @"");
}

@end


#pragma mark -

@implementation MulleScionFilter

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                           flags:(NSUInteger) flags
                      lineNumber:(NSUInteger) nr
{
   MulleScionFilter   *p;
   
   p = [super newWithRetainedExpression:expr
                             lineNumber:nr];
   p->_flags = (unsigned int) flags;
   
   return( p);
}

@end


#pragma mark -

@implementation MulleScionEndFilter

@end


#pragma mark -

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


- (BOOL) isMacro
{
   return( YES);
}

@end


#pragma mark -

@implementation MulleScionRequires

+ (id) newWithIdentifier:(NSString *) identifier
              lineNumber:(NSUInteger) nr;
{
   MulleScionRequires   *p;
   
   NSParameterAssert( [identifier isKindOfClass:[NSString class]]);
   
   p = [super newWithLineNumber:nr];
   p->identifier_ = [identifier copy];
   
   return( p);
}

- (void) dealloc
{
   [identifier_ release];
   [super dealloc];
}

- (NSString *) identifier
{
   return( identifier_);
}

@end

