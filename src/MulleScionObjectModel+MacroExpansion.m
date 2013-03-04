//
//  MulleScionObjectModel+VariableSubstitution.m
//  MulleScionTemplates
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

- (id) replaceVariableWithIdentifier:(NSString *)identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   if( ! [[self identifier] isEqualToString:identifier])
      return( nil);
   return( [expr copy]); 
}

@end


static NSMutableArray  * NS_RETURNS_RETAINED replaceVariablesWithIdentifierInArray( NSArray *array,
                                                                                    NSString *identifier,
                                                                                    MulleScionExpression *expr)
{
   NSEnumerator       *rover;
   NSMutableArray     *result;
   MulleScionObject   *obj;
   MulleScionObject   *copy;
   
   result = [NSMutableArray new];
   
   rover = [array objectEnumerator];
   while( obj = [rover nextObject])
   {
      copy = [obj replaceVariableWithIdentifier:identifier
                                 withExpression:expr];
      [result addObject:copy ? copy : obj];
      [copy release];
   }
   return( result);
}


@implementation MulleScionArray ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray     *result;
   
   result = replaceVariablesWithIdentifierInArray(  self->value_, identifier, expr);
   
   [self->value_ release];
   self->value_ = [result retain];
   
   return( nil);
}

@end


@implementation MulleScionFunction ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray   *result;
   
   result = replaceVariablesWithIdentifierInArray( self->arguments_, identifier, expr);
   
   [self->arguments_ release];
   self->arguments_ = result;
   
   return( nil);
}

@end


@implementation MulleScionMethod ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   NSArray                *result;
   MulleScionMethod       *copy;
   MulleScionExpression   *copy1;
   
   copy1  = [value_ replaceVariableWithIdentifier:identifier
                                  withExpression:expr];
   result = replaceVariablesWithIdentifierInArray( self->arguments_, identifier, expr);

   copy = nil;
   
   if( copy1)
   {
      copy = [isa newWithRetainedTarget:copy1
                             methodName:NSStringFromSelector( self->action_)
                              arguments:nil
                             lineNumber:[self lineNumber]];
      self = copy;
   }
   
   [self->arguments_ release];
   self->arguments_ = result;
   
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


@implementation MulleScionSet ( VariableSubstitution)

- (id) replaceVariableWithIdentifier:(NSString *) identifier
                     withExpression:(MulleScionExpression *) expr NS_RETURNS_RETAINED
{
   MulleScionUnaryOperatorExpression   *copy;
   MulleScionExpression                *copy1;
   
   copy1 = [expression_ replaceVariableWithIdentifier:identifier
                                       withExpression:expr];
   
   if( ! copy1)
      return( nil);
   
   copy = [isa newWithIdentifier:identifier_
               retainedExpression:copy1
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
   return( copy);
}


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
   
   copy = [[[self body] copyWithZone:NULL] autorelease];
   
   //
   // now walk through body replacing all variable instances who'se identifier
   // (also those in contained expressions)
   // This is not(!) very fast
   //
   rover = [parameters keyEnumerator];
   while( identifier = [rover nextObject])
   {
      expr = [parameters objectForKey:identifier];
      if( expr == [NSNull null])
         [NSException raise:NSInvalidArgumentException
                     format:@"%@ %ld: parameter \"%@\" in macro \"%@\" needs a value",
          fileName, (long) line, identifier, [self identifier]];
         
      for( prev = nil, curr = copy; curr; prev = curr, curr = next)
      {
         replacement = [curr replaceVariableWithIdentifier:identifier
                                            withExpression:expr];
         next = curr->next_;
         if( replacement)
         {
            assert( prev);  // must be because, copy starts with a template
            curr->next_ = nil;
            prev->next_ = replacement;

            [curr release];
            curr        = [replacement tail];
            curr->next_ = next;
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
      if( ! [expr isIdentifier] && ! [expr isVariableAssignment])
         [NSException raise:NSInvalidArgumentException
                     format:@"%@ %ld: parameters in macro \"%@\" must be identifiers or variable assignments", [self fileName], (long) [self lineNumber], [self identifier]];
      
      identifier = [expr identifier];
      value = nil;
      if( [expr isVariableAssignment])
         value = [(MulleScionVariableAssignment *) expr expression];
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
      
      if( [expr isVariableAssignment] || [expr isIdentifier])
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
      
      if( [expr isVariableAssignment])
         value = [(MulleScionVariableAssignment *) expr expression];
      else
         value = expr;
      
      [parameters setObject:value
                     forKey:identifier];
      ++i;
   }
   return( parameters);
}

@end
