//
//  MulleScionObjectModel+VariableSubstitution.m
//  MulleScion
//
//  Created by Nat! on 28.02.13.
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


#import "MulleScionObjectModel+MacroExpansion.h"

#import "MulleScionObjectModel+NSCoding.h"

// this is totally hackish


@implementation MulleScionObject ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *)identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   return( nil);
}

@end


@implementation MulleScionIdentifierExpression ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   if( ! [[self identifier] isEqualToString:identifier])
      return( nil);
#if 0
   if( ! [expr isIdentifier])
      [NSException raise:NSInvalidArgumentException
                  format:@"identifier %@ can not be replaced with non-identifier", identifier];
#endif
   return( [expr copy]);
}

@end


static NSMutableDictionary  *replaceVariablesWithIdentifierInDictionary( NSDictionary *dictionary,
                                                                         NSString *identifier,
                                                                         MulleScionExpression *expr)
{
   NSEnumerator          *rover;
   NSMutableDictionary   *result;
   MulleScionObject      *obj;
   MulleScionObject      *copy;
   MulleScionObject      *keyCopy;
   MulleScionObject      *key;
   BOOL                  hasChanges;
   
   hasChanges = NO;
   
   result = [NSMutableDictionary dictionary];
   
   rover = [dictionary keyEnumerator];
   while( key = [rover nextObject])
   {
      NSCParameterAssert( [key isKindOfClass:[MulleScionObject class]]);

      obj = [dictionary objectForKey:key];

      NSCParameterAssert( ! obj->next_);
      NSCParameterAssert( ! key->next_);
      
      keyCopy = [key replaceVariableWithIdentifier:identifier
                                    withExpression:expr];
      copy    = [obj replaceVariableWithIdentifier:identifier
                                    withExpression:expr];
      
      if( copy || keyCopy)
         hasChanges = YES;
      
      if( ! copy)
         copy = [obj retain];
      if( ! keyCopy)
         keyCopy = [key retain];
      [result setObject:copy
                 forKey:keyCopy];
      
      [copy release];
      [keyCopy release];
   }
   return( hasChanges ? result : nil);
}


static NSMutableArray  *replaceVariablesWithIdentifierInArray( NSArray *array,
                                                               NSString *identifier,
                                                               MulleScionExpression *expr)
{
   NSEnumerator       *rover;
   NSMutableArray     *result;
   MulleScionObject   *obj;
   MulleScionObject   *copy;
   BOOL               hasChanges;
   
   hasChanges = NO;
   
   result = [NSMutableArray array];
   
   rover = [array objectEnumerator];
   while( obj = [rover nextObject])
   {
      NSCParameterAssert( ! obj->next_);
      
      copy = [obj replaceVariableWithIdentifier:identifier
                                 withExpression:expr];
      if( copy)
      {
         [result addObject:copy];
         [copy release];
         hasChanges = YES;
      }
      else
         [result addObject:obj];
   }
   return( hasChanges ? result : nil);
}


@implementation MulleScionArray ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray           *result;
   MulleScionArray   *copy;
   
   result = replaceVariablesWithIdentifierInArray(  self->value_, identifier, expr);
   if( ! result)
      return( nil);
   
   copy = [isa newWithArray:result
                 lineNumber:self->lineNumber_];
   return( copy);
}

@end



@implementation MulleScionDictionary ( VariableSubstitution)
   
- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSDictionary           *result;
   MulleScionDictionary   *copy;
   
   result = replaceVariablesWithIdentifierInDictionary( self->value_, identifier, expr);
   if( ! result)
      return( nil);
   
   copy = [isa newWithDictionary:result
                      lineNumber:self->lineNumber_];
   return( copy);
}
   
@end


@implementation MulleScionFunction ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray              *result;
   MulleScionFunction   *copy;
   
   result = replaceVariablesWithIdentifierInArray(  self->arguments_, identifier, expr);
   if( ! result)
      return( nil);
   
   copy = [isa newWithIdentifier:[self identifier]
                       arguments:result
                     lineNumber:self->lineNumber_];
   return( copy);
}

@end


@implementation MulleScionMethod ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray                *result;
   MulleScionMethod       *copy;
   MulleScionExpression   *copy1;

   copy1 = nil;
   if( ! [value_ isIdentifier])
      copy1  = [value_ replaceVariableWithIdentifier:identifier
                                      withExpression:expr];

   result = replaceVariablesWithIdentifierInArray( self->arguments_, identifier, expr);
   
   if( ! copy1 && ! result)
      return( nil);
   
   if( ! copy1)
      copy1 = [value_ copyWithZone:NULL];

   if( ! result)
      result = self->arguments_;
   copy   = [isa newWithRetainedTarget:copy1
                            methodName:NSStringFromSelector( self->action_)
                             arguments:result
                            lineNumber:[self lineNumber]];
   return( copy);
}

@end



@implementation MulleScionUnaryOperatorExpression ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionUnaryOperatorExpression   *copy;
   MulleScionExpression                *copy1;
   
   copy1 = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   
   if( ! copy1)
      return( nil);
   
   copy = [isa newWithRetainedExpression:copy1
                              lineNumber:[self lineNumber]];
   return( copy);
}

@end


@implementation MulleScionBinaryOperatorExpression ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionBinaryOperatorExpression   *copy;
   MulleScionExpression                 *copy1;
   MulleScionExpression                 *copy2;
   
   copy1 = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   copy2 = [right_ replaceVariableWithIdentifier:identifier
                                 withExpression:expr];

   if( ! copy1 && ! copy2)
      return( nil);

   if( ! copy1)
      copy1 = [value_ copyWithZone:NULL];
   if( ! copy2)
      copy2 = [right_ copyWithZone:NULL];
   
   copy = [isa newWithRetainedLeftExpression:copy1
                     retainedRightExpression:copy2
                                  lineNumber:[self lineNumber]];
   return( copy);
}

@end



//
// can't fully macro expand right side of a pipe
//
@implementation MulleScionPipe ( Printing)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionPipe          *copy;
   MulleScionExpression    *copy1;
   MulleScionExpression    *copy2;

   copy1 = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   copy2 = [right_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   if( copy2 && ! [copy2 isMethod] && ! [copy2 isPipe] && ! [copy2 isIdentifier])
   {
      [copy2 release];
      copy2 = nil;
   }

   if( ! copy1 && ! copy2)
      return( nil);

   if( ! copy2)
      copy2 = [right_ copyWithZone:NULL];
   copy  = [isa newWithRetainedLeftExpression:copy1
                      retainedRightExpression:copy2
                                   lineNumber:[self lineNumber]];
   return( copy);
}

@end


@implementation MulleScionDot ( Printing)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionDot           *copy;
   MulleScionExpression    *copy1;
   MulleScionExpression    *copy2;
   
   copy1 = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   copy2 = [right_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   if( copy2 && ! [copy2 isMethod] && ! [copy2 isPipe] && ! [copy2 isDot] && ! [copy2 isIdentifier])
   {
      [copy2 release];
      copy2 = nil;
   }
   
   if( ! copy1 && ! copy2)
      return( nil);
   
   if( ! copy2)
      copy2 = [right_ copyWithZone:NULL];
   copy  = [isa newWithRetainedLeftExpression:copy1
                      retainedRightExpression:copy2
                                   lineNumber:[self lineNumber]];
   return( copy);
}
@end


@implementation MulleScionConditional ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionConditional   *copy;
   MulleScionExpression    *copy1;
   MulleScionExpression    *copy2;
   MulleScionExpression    *copy3;
   
   copy1 = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   copy2 = [middle_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   copy3 = [right_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   
   if( ! copy1 && ! copy2 && ! copy3)
      return( nil);
   
   if( ! copy1)
      copy1 = [value_ copyWithZone:NULL];
   if( ! copy2)
      copy2 = [middle_ copyWithZone:NULL];
   if( ! copy3)
      copy3 = [right_ copyWithZone:NULL];
   
   copy = [isa newWithRetainedLeftExpression:copy1
                    retainedMiddleExpression:copy2
                     retainedRightExpression:copy3
                                  lineNumber:[self lineNumber]];
   return( copy);
}

@end


@implementation MulleScionAssignmentExpression ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionSet           *copy;
   MulleScionExpression    *copy1;
   MulleScionExpression    *copy2;
   
   // not useful, and also can make problems if the identifier changes
   // to null or something
   
   //   copy1 = [lexpr_ replaceVariableWithIdentifier:identifier
   //                                  withExpression:expr];
   copy2 = [right_ replaceVariableWithIdentifier:identifier
                                       withExpression:expr];
   
   if( ! copy2)
      return( nil);
   
   copy1 = [value_ copyWithZone:NULL];
   copy  = [isa newWithRetainedLeftExpression:copy1
                      retainedRightExpression:copy2
                                   lineNumber:[self lineNumber]];
   return( copy);
}

@end


@implementation MulleScionSet ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                     withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionSet           *copy;
   MulleScionExpression    *copy2;
   MulleScionExpression    *copy1;
   
   // not useful, and also can make problems if the identifier changes
   // to null or something
   
   //   copy1 = [lexpr_ replaceVariableWithIdentifier:identifier
   //                                  withExpression:expr];
   copy2 = [right_ replaceVariableWithIdentifier:identifier
                                 withExpression:expr];
   
   if( ! copy2)
      return( nil);
   
   copy1 = [left_ copyWithZone:NULL];
   copy  = [isa newWithRetainedLeftExpression:copy1
                      retainedRightExpression:copy2
                                   lineNumber:[self lineNumber]];
   return( copy);
}

@end


@implementation MulleScionExpressionCommand ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionUnaryOperatorExpression   *copy;
   MulleScionExpression                *copy1;
   
   copy1 = [expression_ replaceVariableWithIdentifier:identifier
                                       withExpression:expr];
   
   if( ! copy1)
      return( nil);
   
   copy = [isa newWithRetainedExpression:copy1
                              lineNumber:[self lineNumber]];
   return( copy);
}

@end


# pragma mark -
# pragma Expansion Works

@implementation MulleScionMacro ( MacroExpansion)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionUnaryOperatorExpression   *copy;
   MulleScionFunction                  *copy1;
   
   copy1 = [function_ replaceVariableWithIdentifier:identifier
                                     withExpression:expr];
   
   if( ! copy1)
      return( nil);

   copy = [isa newWithIdentifier:identifier_
                        function:copy1
                            body:body_
                        fileName:value_
                      lineNumber:[self lineNumber]];
   [copy1 release];
   return( copy);
}


typedef struct
{
   NSString  *identifier;
   id        expr;
} identifier_expr_assoc;


- (MulleScionTemplate *) expandedBodyWithParameters:(NSDictionary *) parameters
                                           fileName:(NSString *) fileName
                                         lineNumber:(NSUInteger) line
{
   id                   expr;
   MulleScionTemplate   *copy;
   MulleScionObject     *next;
   MulleScionObject     *curr;
   MulleScionObject     *prev;
   MulleScionObject     *replacement;
   NSEnumerator         *rover;
   NSString             *identifier;
   identifier_expr_assoc  *assoc;
   identifier_expr_assoc  *sentinel;
   identifier_expr_assoc  *p;
   NSUInteger             n;
   NSNull                 *null;
   
   n     = [parameters count];
   assoc = [[NSMutableData dataWithLength:n * sizeof(identifier_expr_assoc)] mutableBytes];

   p     = assoc;
   null  = [NSNull null];
   rover = [parameters keyEnumerator];
   while( identifier = [rover nextObject])
   {
      expr = [parameters objectForKey:identifier];
      if( expr == null)
         [NSException raise:NSInvalidArgumentException
                     format:@"%@ %ld: parameter \"%@\" in macro \"%@\" needs a value",
          fileName, (long) line, identifier, [self identifier]];
      p->identifier = identifier;
      p->expr       = expr;
      p++;
   }
   sentinel = p;
   
   copy = [[[self body] copyWithZone:NULL] autorelease];
   
   //
   // now walk through body replacing all variable instances who'se identifier
   // (also those in contained expressions)
   // This is not(!) very fast to avoid surprising double substitution we need
   // loop over the paramaters inside
   //
   for( prev = nil, curr = copy; curr; prev = curr, curr = next)
   {
      next = curr->next_;
      
      for( p = assoc; p < sentinel; p++)
      {
         replacement = [curr replaceVariableWithIdentifier:p->identifier
                                            withExpression:p->expr];
         if( replacement)
         {
            assert( prev);  // must be because, copy starts with a template
            curr->next_ = nil;
            prev->next_ = replacement;
            
            [curr release];
            curr        = [replacement tail];
            curr->next_ = next;
            break;
         }
      }
   }

   return( copy);
}


- (void) getDefaultArguments:(NSMutableDictionary **) defaultArguments
             identifierOrder:(NSArray **) identifierOrder
{
   NSMutableDictionary             *parameters;
   MulleScionIdentifierExpression  *expr;
   NSEnumerator                    *rover;
   id                              value;
   NSString                        *identifier;
   NSMutableArray                  *identifiers;
   
   parameters  = [NSMutableDictionary dictionary];
   identifiers = [NSMutableArray array];
   
   // first setup default values for macro and remember where what is
   rover = [[[self function] arguments] objectEnumerator];
   
   while( expr = [rover nextObject])
   {
      if( ! [expr isIdentifier] && ! [expr isParameterAssignment])
         [NSException raise:NSInvalidArgumentException
                     format:@"%@ %ld: parameters in macro \"%@\" must be identifiers or variable assignments", [self fileName], (long) [self lineNumber], [self identifier]];
      
      identifier = [expr identifier];
      value = nil;
      if( [expr isParameterAssignment])
         value = [(MulleScionParameterAssignment *) expr expression];
      if( ! value)
         value = [NSNull null];
      
      [parameters setObject:value
                     forKey:identifier];
      [identifiers addObject:identifier];
   }
   *defaultArguments = parameters;
   *identifierOrder  = identifiers;
}


- (NSDictionary *) parametersWithArguments:(NSArray *) arguments
                                  fileName:(NSString *) fileName
                                lineNumber:(NSUInteger) line
{
   NSMutableDictionary             *parameters;
   MulleScionIdentifierExpression  *expr;
   NSEnumerator                    *rover;
   id                              value;
   NSString                        *identifier;
   NSMutableArray                  *identifiers;
   NSUInteger                      i, n;

   [self getDefaultArguments:&parameters
             identifierOrder:&identifiers];
   
   // now take supplied arguments and override the defaults
   n     = [identifiers count];
   i     = 0;
   rover = [arguments objectEnumerator];
   while( expr = [rover nextObject])
   {
      NSParameterAssert( [expr isKindOfClass:[MulleScionExpression class]]);
      
      if( [expr isParameterAssignment] || [expr isIdentifier])
         identifier = [expr identifier];
      else
      {
         if( i >= n)
            [NSException raise:NSInvalidArgumentException
                        format:@"%@ %ld:too many parameters for macro \"%@\"", fileName, (long) line, [self identifier]];
         identifier = [identifiers objectAtIndex:i];
      }
      if( ! [parameters objectForKey:identifier])
             [NSException raise:NSInvalidArgumentException
                         format:@"%@ %ld:parameter \"%@\" is unknown to macro \"%@\"", fileName, (long) line, identifier, [self identifier]];
      
      if( [expr isParameterAssignment])
         value = [(MulleScionParameterAssignment *) expr expression];
      else
         value = expr;
      
      [parameters setObject:value
                     forKey:identifier];
      ++i;
   }
   return( parameters);
}

@end
