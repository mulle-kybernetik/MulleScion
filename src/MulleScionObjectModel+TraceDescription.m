//
//  MulleScionObjectModel+TraceDescription.m
//  MulleScion
//
//  Created by Nat! on 25.02.13.
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

#import "MulleScionObjectModel+TraceDescription.h"

#import "MulleCommonObjCRuntime.h"


//
// templateDescription should output something that is right parsable back into
// an identical functioning template
//
// debugDescription just displays terse information about a single object
//
// traceDescription is a somewhat terser technical trace dump, that's useful
// for debugging of a single element
//
// dumpDescription is dumps a chain of traceDescriptions
//
NSString   *mulleShortenedString( NSString *s, size_t max)
{
   NSUInteger   length;
   
   length = [s length];
   if( length > max)
   {
      if( max < 4)
         return( [s substringToIndex:max]);
      
      s = [s substringToIndex:max - 3];
      s = [s stringByAppendingString:@"..."];
   }
   return( s);
}



NSString   *mulleLinefeedEscapedString( NSString *s)
{
   return( [s stringByReplacingOccurrencesOfString:@"\n"
                                        withString:@"\\n"]);
}


NSString   *mulleLinefeedEscapedShortenedString( NSString *s, size_t max)
{
   return( mulleLinefeedEscapedString( mulleShortenedString( s, max)));
}


@implementation NSString( TraceValueDescription)

static Class   NSPlaceholderStringClass;

+ (void) load
{
   NSPlaceholderStringClass = [[[self alloc] autorelease] class];
}


- (NSString *) traceValueDescription
{
   if( MulleGetClass( self) == NSPlaceholderStringClass)
      return( @"NSPlaceholderStringClass");
   
   return( [NSString stringWithFormat:@"@\"%@\"", self]);
}

@end


@implementation NSObject( TraceValueDescription)


- (NSString *) traceValueDescription
{
   return( [self description]);
}

@end


@implementation NSArray( TraceValueDescription)

- (NSString *) traceValueDescription
{
   id                item;
   id                old;
   NSMutableString   *s;
   NSEnumerator      *rover;
   
   // this code gets around the if in the while, there is no other point to
   // this, just sport :D
   s     = [NSMutableString stringWithFormat:@"@("];
   rover = [self objectEnumerator];
   old   = [rover nextObject];
   if( old)
   {
      [s appendString:@" "];
      while( item = [rover nextObject])
      {
         [s appendString:[old traceValueDescription]];
         [s appendString:@", "];
         old = item;
      }
      [s appendString:[old traceValueDescription]];
   }
   [s appendString:@")"];
   
   return( s);
}

@end


@implementation NSDictionary( TraceValueDescription)

- (NSString *) traceValueDescription
{
   id                key;
   id                oldKey;
   id                oldValue;
   NSMutableString   *s;
   NSEnumerator      *rover;
   
   // this code gets arounf the if in the while, there is no other point to
   // this, just sport :D
   s      = [NSMutableString stringWithFormat:@"@{"];
   rover  = [[[self allKeys] sortedArrayUsingSelector:@selector( compare:)] objectEnumerator];
   oldKey = [rover nextObject];
   if( oldKey)
   {
      [s appendString:@" "];
      oldValue = [self objectForKey:oldKey];
      while( key = [rover nextObject])
      {
         [s appendString:[oldValue traceValueDescription]];
         [s appendString:@", "];
         [s appendString:[oldKey traceValueDescription]];
         [s appendString:@", "];
         oldKey   = key;
         oldValue = [self objectForKey:key];
      }
      [s appendString:[oldValue traceValueDescription]];
      [s appendString:@", "];
      [s appendString:[oldKey traceValueDescription]];
   }
   [s appendString:@"}"];
   
   return( s);
}

@end


@implementation MulleScionObject( TraceDescription)

- (NSString *) _templateDescriptionSeparator
{
   return( @"");
}


- (NSString *) _dumpDescriptionSeparator
{
   return( @"\n");
}


// just the object
- (NSString *) _templateDescription
{
   return( @"");
}


// chain
- (NSString *) templateDescription
{
   NSString  *s;
   
   s = [self _templateDescription];
   if( next_)
      return( [NSString stringWithFormat:@"%@%@%@", s, [self _templateDescriptionSeparator], [next_ templateDescription]]);
   return( s);
}


// just the object
- (NSString *) traceDescription
{
   return( mulleLinefeedEscapedShortenedString( [self _templateDescription], 64));
}


// chain
- (NSString *) dumpDescription
{
   NSString  *s;
   
   s = [self traceDescription];
   if( next_)
      return( [NSString stringWithFormat:@"%ld: %@%@%@", (long) lineNumber_, s, [next_ _dumpDescriptionSeparator], [next_ dumpDescription]]);
   return( [NSString stringWithFormat:@"%ld: %@", (long) lineNumber_, s]);
}


- (NSString *) debugDescription
{
   NSString  *s;
   
   s = [self _templateDescription];
   s = mulleShortenedString( s, 64);
   if( [s length])
      return( [NSString stringWithFormat:@"<%@ %p = \"%@\">", MulleGetClass( self), self, s]);
   return( [NSString stringWithFormat:@"<%@ %p>", MulleGetClass( self), self]);
}

@end


@implementation MulleScionPlainText( TraceDescription)

- (NSString *) _templateDescription
{
   return( value_);
}


- (NSString *) traceDescription
{
   NSString     *s;
   
   s = mulleLinefeedEscapedShortenedString( value_, 64);
   return( [NSString stringWithFormat:@"\"%@\"", s]);
}

@end



@implementation MulleScionTemplate( TraceDescription)

- (NSString *) traceDescription
{
   return( [NSString stringWithFormat:@"template %@", value_]);
}


- (NSString *) _templateDescription
{
   return( @"");
}


@end


@interface NSObject( ExpressionDescription)

- (NSString *) _expressionDescription;

@end



@implementation NSObject (ExpressionDescription)

- (NSString *) _expressionDescription
{
   return( [self description]);
}

@end



@implementation NSNull (ExpressionDescription)

- (NSString *) _expressionDescription
{
   return( @"<NSNull>");
}

@end



@implementation MulleScionValueObject( TraceDescription)

- (NSString *) _expressionDescription
{
   return( value_ ? [value_ _expressionDescription] : @"<nil>");
}

- (NSString *) _templateDescription
{
   return( value_ ? [value_ _expressionDescription] : @"<nil>");
}

@end


@implementation MulleScionString( TraceDescription)

- (NSString *) _traceDescription
{
   return( mulleShortenedString( value_, 64));
}


- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"@\"%@\"", [value_ _expressionDescription]]);
}

@end


@implementation MulleScionSelector( TraceDescription)

- (NSString *) _templateDescription
{
   return( [NSString stringWithFormat:@"@selector( %@)", [value_ _expressionDescription]]);
}

@end



@implementation MulleScionExpression( TraceDescription)

- (NSString *) _templateDescription
{
   return( [NSString stringWithFormat:@"{{ %@ }}", [self _expressionDescription]]);
}

@end


@implementation MulleScionArray( TraceDescription)

- (NSString *) _expressionDescription
{
   NSMutableString   *s;
   NSUInteger        i, n;
   
   s = [NSMutableString string];
   n = [value_ count];
   
   [s appendFormat:@"@("];
   if( n)
   {
      for( i = 0; i < n - 1; i++)
         [s appendFormat:@" %@,", [[value_ objectAtIndex:i] _expressionDescription]];
      [s appendFormat:@" %@", [[value_ objectAtIndex:i] _expressionDescription]];
   }
   [s appendString:@")"];
   
   return( s);
}

@end


@implementation MulleScionDictionary( TraceDescription)

- (NSString *) _expressionDescription
{
   NSMutableString   *s;
   NSEnumerator      *rover;
   id                key, value;
   
   s = [NSMutableString string];
   rover = [value_ keyEnumerator];
   
   [s appendFormat:@"@{"];
   while( key = [rover nextObject])
   {
      value = [value_ objectForKey:key];
      [s appendFormat:@" %@,", [value _expressionDescription]];
      [s appendFormat:@" %@", [key _expressionDescription]];
   }
   [s appendString:@"}"];
   
   return( s);
}

@end


@implementation MulleScionFunction( TraceDescription)

- (NSString *) _expressionDescription
{
   NSMutableString   *s;
   NSUInteger        i, n;
   
   s = [NSMutableString string];
   
   [s appendFormat:@"%@( ", [super _expressionDescription]];
   n = [arguments_ count];
   if( n)
   {
      for( i = 0; i < n - 1; i++)
      {
         [s appendFormat:@" %@, ",
          [[arguments_ objectAtIndex:i] _expressionDescription]];
      }
      [s appendFormat:@" %@",
       [[arguments_ objectAtIndex:i] _expressionDescription]];
   }
   [s appendString:@")"];
   
   return( s);
}

@end


@implementation MulleScionMethod( TraceDescription)

- (NSString *) _expressionDescription
{
   NSString          *selName;
   NSArray           *components;
   NSMutableString   *s;
   NSUInteger        i, n, m;
   
   s       = [NSMutableString string];
   selName = NSStringFromSelector( action_);
   
   [s appendFormat:@"[%@", [super _expressionDescription]];
   n = [arguments_ count];
   if( n)
   {
      components = [selName componentsSeparatedByString:@":"];
      m          = [components count] - 1;
      for( i = 0; i < m; i++)
      {
         [s appendFormat:@" %@:%@",
          [components objectAtIndex:i],
          [[arguments_ objectAtIndex:i] _expressionDescription]];
      }
      for( ; i < n; i++)
      {
         [s appendFormat:@", %@",
          [[arguments_ objectAtIndex:i] _expressionDescription]];
      }
   }
   else
      [s appendFormat:@" %@", selName];
   [s appendString:@"]"];
   return( s);
}

@end


@implementation MulleScionNot( TraceDescription)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"not %@",
            [value_ _expressionDescription]]);
}

@end


@implementation MulleScionBinaryOperatorExpression( TraceDescription)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@ %@ %@",
            [value_ _expressionDescription], [self operator], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionIndexing( TraceDescription)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@[ %@]",
            [value_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionConditional( TraceDescription)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@ ? %@ : %@",
            [value_ _expressionDescription], [middle_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionTerminator( TraceDescription)

- (NSString *) commandDescription
{
   return( [self commandName]);
}

@end


@interface MulleScionCommand( TraceDescription)

- (NSString *) _commandDescription;

@end


@implementation MulleScionCommand( TraceDescription)

- (NSString *) _templateDescriptionSeparator
{
   return( @"\n");
}


- (NSString *) _commandDescription
{
   NSString   *command;
   NSString   *spacer;
   
   command = [self commandName];
   spacer  = [command length] ? @" " : @"";
   
   return( [NSString stringWithFormat:@"%@%@", command, spacer]);
}


- (NSString *) commandDescription
{
   return( [self _commandDescription]);
}


- (NSString *) _templateDescription
{
   return( [NSString stringWithFormat:@"{%% %@ %%}", [self commandDescription]]);
}

@end


@implementation MulleScionSet( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ = %@", command, [left_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionFor( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ in %@", command, [left_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionExpressionCommand( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@", command, [expression_ _expressionDescription]]);
}

@end


@implementation MulleScionBlock( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"(%@) %@%@", fileName_, command, identifier_]);
}

@end
