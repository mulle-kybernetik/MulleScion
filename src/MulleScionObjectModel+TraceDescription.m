//
//  MulleScionObjectModel+Debug.m
//  MulleScionTemplates
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

//
// templateDescription should output something that is right parsable back into
// an identical functioning template
//
// templateDescription is used to actually generate printable output from the printer
//             do not override
// debugDescription just displays terse information about a single object
//
// traceDescription is a somewhat terser technical trace dump, that's useful
// for debugging of the whole chain
//
//
static NSString   *shortenedString( NSString *s, size_t max)
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


@implementation MulleScionObject ( TraceDescription)


- (NSString *) _templateDescriptionSeparator
{
   return( @"");
}


- (NSString *) _traceDescriptionSeparator
{
   return( @"\n");
}


- (NSString *) _templateDescription
{
   return( @"");
}


- (NSString *) templateDescription
{
   NSString  *s;
   
   s = [self _templateDescription];
   if( next_)
      return( [NSString stringWithFormat:@"%@%@%@", s, [self _templateDescriptionSeparator], [next_ templateDescription]]);
   return( s);
}


- (NSString *) _traceDescription
{
   return( [self shortDescription]);
}


- (NSString *) traceDescription
{
   NSString  *s;
   
   s = [self _traceDescription];
   if( next_)
      return( [NSString stringWithFormat:@"%ld: %@%@%@", (long) lineNumber_, s, [next_ _traceDescriptionSeparator], [next_ traceDescription]]);
   return( [NSString stringWithFormat:@"%ld: %@", (long) lineNumber_, s]);
}


- (NSString *) debugDescription
{
   NSString  *s;
   
   s = [self _templateDescription];
   s = shortenedString( s, 64);
   if( [s length])
      return( [NSString stringWithFormat:@"<%@ %p = \"%@\">", isa, self, s]);
   return( [NSString stringWithFormat:@"<%@ %p>", isa, self]);
}


// DO NOT CHANGE THIS CLEVERLY
- (NSString *) shortDescription
{
   return( [self _templateDescription]);
}

@end



@implementation MulleScionPlainText ( Description)

- (NSString *) _templateDescription
{
   return( value_);
}


- (NSString *) shortDescription
{
   NSString     *s;
   
   s = shortenedString( [self _templateDescription], 64);
   s = [[s componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\\n"];
   return( [NSString stringWithFormat:@"\"%@\"", s]);
}

@end



@implementation MulleScionTemplate ( Description)

- (NSString *) _traceDescription
{
   return( [NSString stringWithFormat:@"template %@", value_]);
}


- (NSString *) _templateDescription
{
   return( @"");
}


@end


@interface NSObject ( ExpressionDescription)

- (NSString *) _expressionDescription;

@end



@implementation NSObject (ExpressionDescription)

- (NSString *) _expressionDescription
{
   return( [self description]);
}

@end


@implementation MulleScionValueObject ( Description)

- (NSString *) _expressionDescription
{
   return( [value_ _expressionDescription]);
}

- (NSString *) _templateExpression
{
   return( [value_ _expressionDescription]);
}

@end


@implementation MulleScionString ( Description)

- (NSString *) shortDescription
{
   return( shortenedString( value_, 64));
}


- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"@\"%@\"", [value_ _expressionDescription]]);
}

@end


@implementation MulleScionSelector( Description)

- (NSString *) _templateDescription
{
   return( [NSString stringWithFormat:@"@selector( %@)", [value_ _expressionDescription]]);
}

@end



@implementation MulleScionExpression ( Description)

- (NSString *) _templateDescription
{
   return( [NSString stringWithFormat:@"{{ %@ }}", [self _expressionDescription]]);
}

@end


@implementation MulleScionArray ( Description)

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


@implementation MulleScionDictionary ( Description)

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


@implementation MulleScionFunction ( Description)

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


@implementation MulleScionMethod ( Description)

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


@implementation MulleScionNot ( Description)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"not %@",
            [value_ _expressionDescription]]);
}

@end


@implementation MulleScionBinaryOperatorExpression ( Description)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@ %@ %@",
            [value_ _expressionDescription], [self operator], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionIndexing ( Description)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@[ %@]",
            [value_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionConditional ( Description)

- (NSString *) _expressionDescription
{
   return( [NSString stringWithFormat:@"%@ ? %@ : %@",
            [value_ _expressionDescription], [middle_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionTerminator ( Description)

- (NSString *) commandDescription
{
   return( [self commandName]);
}

@end


@interface MulleScionCommand ( Description)

- (NSString *) _commandDescription;

@end


@implementation MulleScionCommand ( Description)

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


@implementation MulleScionSet ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ = %@", command, [left_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionFor ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ in %@", command, [left_ _expressionDescription], [right_ _expressionDescription]]);
}

@end


@implementation MulleScionExpressionCommand ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@", command, [expression_ _expressionDescription]]);
}

@end


@implementation MulleScionBlock ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"(%@) %@%@", fileName_, command, identifier_]);
}

@end
