//
//  NSObject+MulleGraphviz.m
//  MulleScion
//
//  Created by Nat! on 08.11.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "NSObject+MulleGraphviz.h"

#import "NSString+HTMLEscape.h"


@implementation  NSObject ( MulleGraphviz)

- (NSString *) mulleGraphvizName
{
   return( [NSString stringWithFormat:@"%@_%p", isa, self]);
}


- (NSMutableDictionary *) mulleGraphvizAttributes
{
   return( nil);
}


- (NSMutableDictionary *) mulleGraphvizChildrenByName
{
   return( nil);
}


- (NSString *) mulleGraphvizDescription
{
   
   NSArray           *children;
   NSDictionary      *childrenByName;
   NSDictionary      *dict;
   NSEnumerator      *rover;
   NSMutableString   *s;
   NSString          *key;
   NSString          *name;
   NSUInteger        i, n;
   id                child;
   id                value;
   
   name           = [self mulleGraphvizName];
   dict           = [self mulleGraphvizAttributes];
   childrenByName = [self mulleGraphvizChildrenByName];
   
   s = [NSMutableString string];
   [s appendFormat:@"\t%@ [label=<<TABLE>\n", name];
   [s appendFormat:@"\t\t<TR><TD COLSPAN=\"2\" BGCOLOR=\"%@\"><FONT COLOR=\"%@\">%@</FONT></TD></TR>\n",
    @"dodgerBlue", @"black", [name htmlEscapedString]];
   
   rover = [dict keyEnumerator];
   while( key = [rover nextObject])
   {
      value = [dict objectForKey:key];
      [s appendFormat:@"\t\t<TR><TD>%@</TD><TD>%@</TD></TR>\n", [key htmlEscapedString], [value htmlEscapedString]];
   }
   [s appendFormat:@"\t\t</TABLE>>];\n"];
   
   rover = [childrenByName keyEnumerator];
   while( key = [rover nextObject])
   {
      children = [childrenByName objectForKey:key];
      
      n = [children count];
      for( i = 0; i < n; i++)
      {
         child = [children objectAtIndex:i];
         [s appendFormat:@"\t%@ -> %@ [label=\"%@\"]; \n", name, [child mulleGraphvizName], key];
      }
   }
   
   rover = [childrenByName keyEnumerator];
   while( key = [rover nextObject])
   {
      children = [childrenByName objectForKey:key];
      
      n = [children count];
      for( i = 0; i < n; i++)
      {
         child = [children objectAtIndex:i];
         [s appendFormat:@"\n%@", [child mulleGraphvizDescription]];
      }
   }
   
   return( s);
}


- (NSString *) mulleDotDescription
{
   NSMutableString   *s;
   
   s = [NSMutableString string];
   [s appendFormat:@"digraph %@\n{\n", [self mulleGraphvizName]];
   //   [s appendString:@"\trankdir=LR;\n"];
   [s appendString:@"\tnode [shape=none];\n\n"];
   [s appendString:[self mulleGraphvizDescription]];
   [s appendString:@"}"];
   
   return( s);
}

@end
