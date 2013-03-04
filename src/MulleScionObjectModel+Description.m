//
//  MulleScionObjectModel+Debug.m
//  MulleScionTemplates
//
//  Created by Nat! on 25.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+Description.h"


#ifndef DONT_HAVE_MULLE_SCION_DESCRIPTION

@implementation MulleScionObject ( Description)


- (NSString *) _descriptionSeparator
{
   return( @"\n");
}

- (NSString *) _description
{
   return( @"");
}


- (NSString *) debugDescription
{
   NSString  *s;
   
   s = [self _description];
   return( [NSString stringWithFormat:@"<%@ %p = \"%.64s\">", isa, self, [s cString]]);
}


- (NSString *) shortDescription
{
   NSString  *s;
   
   s = [self _description];
   return( [NSString stringWithFormat:@"%ld: %@", (long) lineNumber_, s]);
}


- (NSString *) description
{
   NSString  *s;
   
   s = [self _description];
   if( next_)
      return( [NSString stringWithFormat:@"%ld: %@%@%@", (long) lineNumber_, s, [next_ _descriptionSeparator], [next_ description]]);
   return( s);
}

@end


@implementation MulleScionPlainText ( Description)

- (NSString *) _descriptionSeparator
{
   return( @"");
}


- (NSString *) _description
{
   return( value_);
}


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


- (NSString *) shortDescription
{
   NSString     *s;

   s = shortenedString( [self _description], 64);
   return( [NSString stringWithFormat:@"%ld: %@", (long) lineNumber_, s]);
}


- (NSString *) description
{
   NSString  *s;
   
   s = [self _description];
   if( next_)
      return( [NSString stringWithFormat:@"%ld: %@%@", (long) lineNumber_, s, [next_ description]]);
   return( s);
}

@end


@implementation MulleScionTemplate ( Description)

- (NSString *) _description
{
   return( [NSString stringWithFormat:@"%ld: template %@", (long) lineNumber_, value_]);
}

@end


@interface NSObject ( MulleScionDescription)

- (NSString *) mulleScionDescription;
@end



@implementation NSObject ( MulleScionDescription)

- (NSString *) mulleScionDescription
{
   return( [self description]);
}

@end


@implementation MulleScionValueObject ( Description)

- (NSString *) mulleScionDescription
{
   return( [value_ mulleScionDescription]);
}

@end


@implementation MulleScionString ( Description)

- (NSString *) shortDescription
{
   NSString     *s;
   
   s = shortenedString( value_, 64);
   return( [NSString stringWithFormat:@"%ld: @\"%@\"", (long) lineNumber_, s]);
}


- (NSString *) mulleScionDescription
{
   return( [NSString stringWithFormat:@"@\"%@\"", value_]);
}

@end


@implementation MulleScionSelector( Description)

- (NSString *) shortDescription
{
   return( [NSString stringWithFormat:@"%ld: @selector( %@)", (long) lineNumber_, value_]);
}


- (NSString *) mulleScionDescription
{
   return( [NSString stringWithFormat:@"@selector( %@)", value_]);
}

@end



@implementation MulleScionExpression ( Description)

- (NSString *) _descriptionSeparator
{
   return( @"");
}

- (NSString *) _description
{
   return( [NSString stringWithFormat:@"{{ %@ }}", [self mulleScionDescription]]);
}

@end

@implementation MulleScionArray ( Description)

- (NSString *) mulleScionDescription
{
   NSMutableString   *s;
   NSUInteger        i, n;
   
   s = [NSMutableString string];
   n = [value_ count];

   [s appendFormat:@"@("];
   if( n)
   {
      for( i = 0; i < n - 1; i++)
         [s appendFormat:@" %@,", [[value_ objectAtIndex:i] mulleScionDescription]];
      [s appendFormat:@" %@", [[value_ objectAtIndex:i] mulleScionDescription]];
   }
   [s appendString:@")"];

   return( s);
}

@end


@implementation MulleScionFunction ( Description)

- (NSString *) mulleScionDescription
{
   NSMutableString   *s;
   NSUInteger        i, n;
   
   s = [NSMutableString string];
   
   [s appendFormat:@"%@( ", [super mulleScionDescription]];
   n = [arguments_ count];
   if( n)
   {
      for( i = 0; i < n - 1; i++)
      {
         [s appendFormat:@" %@, ",
          [[arguments_ objectAtIndex:i] mulleScionDescription]];
      }
      [s appendFormat:@" %@",
       [[arguments_ objectAtIndex:i] mulleScionDescription]];
   }
   [s appendString:@")"];

   return( s);
}

@end


@implementation MulleScionMethod ( Description)

- (NSString *) mulleScionDescription
{
   NSString          *selName;
   NSArray           *components;
   NSMutableString   *s;
   NSUInteger        i, n, m;
   
   s       = [NSMutableString string];
   selName = NSStringFromSelector( action_);
   
   [s appendFormat:@"[%@", [super mulleScionDescription]];
   n = [arguments_ count];
   if( n)
   {
      components = [selName componentsSeparatedByString:@":"];
      m          = [components count] - 1;
      for( i = 0; i < m; i++)
      {
         [s appendFormat:@" %@:%@",
          [components objectAtIndex:i],
          [[arguments_ objectAtIndex:i] mulleScionDescription]];
      }
      for( ; i < n; i++)
      {
         [s appendFormat:@", %@",
          [[arguments_ objectAtIndex:i] mulleScionDescription]];
      }
   }
   else
      [s appendFormat:@" %@", selName];
   [s appendString:@"]"];
   return( s);
}

@end


@implementation MulleScionNot ( Description)

- (NSString *) mulleScionDescription
{
   return( [NSString stringWithFormat:@"not %@",
            [value_ mulleScionDescription]]);
}

@end


@implementation MulleScionBinaryOperatorExpression ( Description)

- (NSString *) mulleScionDescription
{
   return( [NSString stringWithFormat:@"%@ %@ %@",
            [value_ mulleScionDescription], [self operator], [right_ mulleScionDescription]]);
}

@end


@implementation MulleScionConditional ( Description)

- (NSString *) mulleScionDescription
{
   return( [NSString stringWithFormat:@"%@ ? %@ : %@",
            [value_ mulleScionDescription], [middle_ mulleScionDescription], [right_ mulleScionDescription]]);
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


- (NSString *) _description
{
   return( [NSString stringWithFormat:@"{%% %@ %%}", [self commandDescription]]);
}

@end


@implementation MulleScionSet ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ = %@", command, identifier_, [expression_ mulleScionDescription]]);
}

@end


@implementation MulleScionFor ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
   
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@ in %@", command, identifier_, [expression_ mulleScionDescription]]);
}

@end


@implementation MulleScionExpressionCommand ( Debug)

- (NSString *) commandDescription
{
   NSString   *command;
      
   command = [self _commandDescription];
   return( [NSString stringWithFormat:@"%@%@", command, [expression_ mulleScionDescription]]);
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

#endif

