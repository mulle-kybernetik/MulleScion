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

+ (void) beginMulleGraphvizSet
{
   NSMutableSet   *set;
   
   set = [NSMutableSet set];
   [[[NSThread currentThread] threadDictionary] setObject:set
                                                   forKey:@"MulleGraphVizSet"];
   
}


+ (void) endMulleGraphvizSet
{
   [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"MulleGraphVizSet"];
}


+ (NSMutableSet *) mulleGraphvizSet
{
   NSMutableSet   *set;
   
   set = [[[NSThread currentThread] threadDictionary] objectForKey:@"MulleGraphVizSet"];
   return( set);
}


- (NSString *) mulleDotDescriptionLeftToRight:(BOOL) dir
{
   NSMutableString   *s;
   NSException       *exception;
   
   exception = nil;
   [isa beginMulleGraphvizSet];
NS_DURING
   s = [NSMutableString string];
   [s appendFormat:@"digraph %@\n{\n", [self mulleGraphvizName]];
   if( dir)
   [s appendString:@"\trankdir=LR;\n"];
   [s appendString:@"\tnode [shape=none];\n\n"];
   [s appendString:[self mulleGraphvizDescription]];
   [s appendString:@"}"];
NS_HANDLER
   exception = localException;
NS_ENDHANDLER
   [isa endMulleGraphvizSet];
   [exception raise];
   
   return( s);
}
   
   
- (NSString *) mulleDotDescription
{
   return( [self mulleDotDescriptionLeftToRight:NO]);
}
   
   
- (NSString *) mulleDotDescriptionLeftToRight
{
   return( [self mulleDotDescriptionLeftToRight:YES]);
}
   
@end


@implementation NSObject ( MulleGraphvizSubclassing)

- (NSString *) mulleGraphvizName
{
   return( [NSString stringWithFormat:@"%@_%p", isa, self]);
}


// premade dictionries, nicer for subclass code
- (NSMutableDictionary *) mulleGraphvizAttributes
{
   return( [NSMutableDictionary dictionary]);
}


- (NSMutableDictionary *) mulleGraphvizChildrenByName
{
   return( [NSMutableDictionary dictionary]);
}


- (NSString *) mulleGraphvizHeaderBackgroundColorName
{
   return( @"dodgerBlue");
}


- (NSString *) mulleGraphvizHeaderTextColorName
{
   return( @"black");
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
   NSMutableSet      *set;
   
   // nice, if nothing is active, this will just pass
   set = [isa mulleGraphvizSet];
   if( [set containsObject:self])
      return( nil);
   [set addObject:self];
   
   name           = [self mulleGraphvizName];
   dict           = [self mulleGraphvizAttributes];
   childrenByName = [self mulleGraphvizChildrenByName];
   
   s = [NSMutableString string];
   [s appendFormat:@"\t%@ [label=<<TABLE>\n", name];
   [s appendFormat:@"\t\t<TR><TD COLSPAN=\"2\" BGCOLOR=\"%@\"><FONT COLOR=\"%@\">%@</FONT></TD></TR>\n",
    [self mulleGraphvizHeaderBackgroundColorName],
    [self mulleGraphvizHeaderTextColorName],
    [name htmlEscapedString]];
   
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
         [s appendFormat:@"\t%@ -> %@ [label=\"%@[ %lu]\"]; \n", name, [child mulleGraphvizName], key, (unsigned long) i];
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
         if( ! [set containsObject:child])
            [s appendFormat:@"\n%@", [child mulleGraphvizDescription]];
      }
   }
   
   return( s);
}

@end
