//
//  MulleScionObjectModel+Printing.m
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+Printing.h"

#import "MulleMutableLineNumber.h"
#import "MulleScionPrintingException.h"
#import "MulleScionDataSourceProtocol.h"
#import "NSObject+MulleScionDescription.h"
#import <Foundation/NSDebug.h>
#import <objc/objc-class.h>


NSString   *MulleScionPrintFormatKey     = @"MulleScionPrintFormat";
NSString   *MulleScionRenderOutputKey    = @"MulleScionRenderOutput";
NSString   *MulleScionCurrentFileKey     = @"__FILE__";
NSString   *MulleScionCurrentLineKey     = @"__LINE__";
NSString   *MulleScionCurrentFunctionKey = @"MulleScionCurrentFunction";
NSString   *MulleScionCurrentFilterKey   = @"__FILTER__";
NSString   *MulleScionPreviousFiltersKey = @"__FILTER_STACK__";
NSString   *MulleScionSelfReplacementKey = @"__SELF_REPLACEMENT__";

NSString   *MulleScionForOpenerKey       = @"MulleScionForOpener";
NSString   *MulleScionForSeparatorKey    = @"MulleScionForSeparator";
NSString   *MulleScionForCloserKey       = @"MulleScionForCloser";

NSString   *MulleScionEvenKey            = @"MulleScionEven";
NSString   *MulleScionOddKey             = @"MulleScionOdd";


@interface MulleScionExpression ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource;

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource;

@end



@implementation MulleScionObject ( Printing)

- (MulleScionObject *)   renderInto:(id <MulleScionOutput>) s
                     localVariables:(NSMutableDictionary *) locals
                         dataSource:(id <MulleScionDataSource>) dataSource
{
   return( self->next_);
}


- (void) updateLineNumberInlocalVariables:(NSMutableDictionary *) locals
{
   MulleMutableLineNumber   *nr;
   
   // linenumber is trusted and not funneled
   nr = [locals objectForKey:MulleScionCurrentLineKey];
   if( ! nr)
   {
      nr = [MulleMutableLineNumber new];
      [locals setObject:nr
                 forKey:MulleScionCurrentLineKey];
      [nr release];
   }
   [nr setUnsignedInteger:lineNumber_];
   
}


static void   MulleScionRenderString( NSString *value,
                                     id <MulleScionOutput> output,
                                     NSMutableDictionary *locals,
                                     id <MulleScionDataSource> dataSource)
{
   MulleScionExpression  *filter;
   
   filter = [locals objectForKey:MulleScionCurrentFilterKey];
   if( filter)
   {
      if( [filter isIdentifier])
      {
         value = [dataSource mulleScionPipeString:value
                                    throughMethod:[(MulleScionVariable *) filter identifier]
                                   localVariables:locals];
      }
      else
      {
         value = [filter evaluateValue:(id) value
                        localVariables:locals
                            dataSource:dataSource];
      }
   }
   [output appendString:value];
}

@end


@implementation MulleScionTemplate ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   
   //
   // expose everything to the dataSource for max. hackability
   // trusted (writing OK, reading ? your choice!)
   //
   [locals setObject:s
              forKey:MulleScionRenderOutputKey];
   [locals setObject:value_
              forKey:MulleScionCurrentFileKey];
   [self updateLineNumberInlocalVariables:locals];
   
   curr = self->next_;
   while( curr)
      curr = [curr renderInto:s
               localVariables:locals
                   dataSource:dataSource];
   return( curr);
}

@end


@implementation MulleScionPlainText ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   [self updateLineNumberInlocalVariables:locals];
   MulleScionRenderString( value_, s, locals, dataSource);
   return( self->next_);
}

@end


static id   MulleScionValueForKeyPath( NSString *keyPath,
                                       NSMutableDictionary * locals,
                                       id dataSource)
{
   id   value;
 
   if( [keyPath isEqualToString:@"self"])
   {
      id   replacement;
      
      replacement = [locals objectForKey:MulleScionSelfReplacementKey];
      if( replacement)
         return( replacement);
      return( dataSource);
   }
   
   value = [dataSource mulleScionValueForKeyPath:keyPath
                                inLocalVariables:locals];
   if( ! value)
      value = [dataSource mulleScionValueForKeyPath:keyPath
                                     localVariables:locals];
   return( value);
}


@implementation MulleScionVariable ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( MulleScionValueForKeyPath( value_, locals, dataSource));
}

@end


@implementation MulleScionFunction ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator           *rover;
   NSMutableArray         *array;
   MulleScionExpression   *expr;
   id                     value;
   
   array = [NSMutableArray array];
   rover = [arguments_ objectEnumerator];
   while( expr = [rover nextObject])
   {
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( ! value)
         value = [NSNull null];
      [array addObject:value];
   }
   return( [dataSource mulleScionFunction:value_
                                arguments:array
                           localVariables:locals]);
}

@end


@implementation MulleScionMethod ( Printing)

char   *_NSObjCSkipRuntimeTypeQualifier( char *type)
{
   char   c;
   
   assert( type != NULL);
   
   while( (c = *type) == _C_CONST
#ifdef _C_IN
         || c == _C_IN
#endif
#ifdef _C_INOUT
         || c == _C_INOUT
#endif
#ifdef _C_OUT
         || c == _C_OUT
#endif
#ifdef _C_BYCOPY
         || c == _C_BYCOPY
#endif
#ifdef _C_ONEWAY
         || c == _C_ONEWAY
#endif
         )
   {
      type++;
   }
   
   return( type);
}



static void   _pop( NSAutoreleasePool *pool)
{
   [pool release];
}


static void   pop( NSAutoreleasePool *pool, id value)
{
   [value retain];
   _pop( pool);
   [value autorelease];
}


static void   *numberBuffer( char *type, NSNumber *value)
{
   NSUInteger          size;
   NSUInteger          alignment;
   void                *buf;
   char                *myType;
   
   if( value && ! [value isKindOfClass:[NSValue class]])
      return( NULL);
   
   NSGetSizeAndAlignment( type, &size, &alignment);
   
   buf = (void *) [[NSMutableData dataWithLength:size] mutableBytes];
   if( ! value)
      return( buf);
   
   switch( *type)
   {
   case _C_CHR      : *(char *) buf = [value charValue]; return( buf);
   case _C_UCHR     : *(unsigned char *) buf = [value unsignedCharValue]; return( buf);
   case _C_SHT      : *(short *) buf = [value shortValue]; return( buf);
   case _C_USHT     : *(unsigned short *) buf = [value unsignedShortValue]; return( buf);
   case _C_INT      : *(int *) buf = [value intValue]; return( buf);
   case _C_UINT     : *(unsigned int *) buf = [value unsignedIntValue]; return( buf);
   case _C_LNG      : *(long *) buf = [value longValue]; return( buf);
   case _C_ULNG     : *(unsigned long *) buf = [value unsignedLongValue]; return( buf);
   case _C_LNG_LNG  : *(long long *) buf = [value longLongValue]; return( buf);
   case _C_ULNG_LNG : *(unsigned long long *) buf = [value unsignedLongLongValue]; return( buf);
   case _C_FLT      : *(float *) buf = [value floatValue]; return( buf);
   case _C_DBL      : *(double *) buf = [value doubleValue]; return( buf);
   }
   
   myType = (char *) [value objCType];
   myType = _NSObjCSkipRuntimeTypeQualifier( myType);
   if( strcmp( myType, type))
      return( NULL);
   
   [value getValue:buf];
   return( buf);
}


- (id) valueOfTarget:(id) target
  withLocalVariables:(NSMutableDictionary *) locals
         dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression *expr;
   NSAutoreleasePool   *pool;
   NSInvocation        *invocation;
   NSMethodSignature   *signature;
   id                  *buf;
   id                  original;
   id                  value;
   char                *returnType;
   char                *type;
   NSUInteger          i, n, m;
   NSUInteger          length;
   // static char         id_type[ 2] = { _C_ID, 0 };
   
   pool = [NSAutoreleasePool new];
   
   signature = [dataSource mulleScionMethodSignatureForSelector:action_
                                                         target:target];
   if( ! signature)
      [NSException raise:NSInvalidArgumentException
                  format:@"Method \"%@\" is unknown on \"%@\" (which evaluates to: %@)", NSStringFromSelector( action_), original, target];
   
   // remember varargs, there can be more arguments
   m = [signature numberOfArguments];
   n = [arguments_ count] + 2;
   if( m  != n)
      [NSException raise:NSInvalidArgumentException
                  format:@"Method \"%@\" expects %ld arguments", NSStringFromSelector( action_), (long) n];
   
   
   invocation = [NSInvocation invocationWithMethodSignature:signature];
   [invocation setSelector:action_];
   
   for( i = 2; i < n; i++)
   {
      expr  = [arguments_ objectAtIndex:i - 2];
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( value == dataSource) // security hole
         [NSException raise:NSInvalidArgumentException
                     format:@"You can't use the dataSource as an argument"];
      
      
      // type = id_type;  // ok, varargs with non-objects won't work
      // if( i < m)
      {
         type = (char *) [signature getArgumentTypeAtIndex:i];
         type = _NSObjCSkipRuntimeTypeQualifier( type);
      }
      
      switch( *type)
      {
      case _C_ID       : buf = &value; break;
      case _C_CLASS    : buf = &value; break;
      case _C_SEL      : buf = &value; break;
      default          : buf = numberBuffer( type, value); break;
      }
      
      if( ! buf)
         [NSException raise:NSInvalidArgumentException
                     format:@"Method \"%@\" is not callable from MulleScion (argument #%ld)",
          NSStringFromSelector( action_), (long) i - 2];
      
      // unfortunately NSInvocation is too dumb for varargs
      [invocation setArgument:buf
                      atIndex:i];
   }
   
   [invocation retainArguments];
   [invocation invokeWithTarget:target];
   
   value  = nil;
   length = [signature methodReturnLength];
   if( length)
   {
      buf    = (id *) [[NSMutableData dataWithLength:length] mutableBytes];
      [invocation getReturnValue:buf];
      
      returnType =  (char *) [signature methodReturnType];
      returnType = _NSObjCSkipRuntimeTypeQualifier( returnType);
      
      switch( *returnType)
      {
      case _C_ID       : value = *buf; break;
      case _C_CLASS    : value = *buf; _pop( pool); return( value);
      case _C_SEL      : value = (id) *(SEL *) buf; _pop( pool); return( value);
      case _C_CHARPTR  : value = [NSString stringWithCString:(char *) buf]; break;
      case _C_CHR      : value = [NSNumber numberWithChar:*(char *) buf]; break;
      case _C_UCHR     : value = [NSNumber numberWithUnsignedChar:*(unsigned char *) buf]; break;
      case _C_SHT      : value = [NSNumber numberWithShort:*(short *) buf]; break;
      case _C_USHT     : value = [NSNumber numberWithUnsignedShort:*(unsigned short *) buf]; break;
      case _C_INT      : value = [NSNumber numberWithInt:*(int *) buf]; break;
      case _C_UINT     : value = [NSNumber numberWithUnsignedInt:*(unsigned int *) buf]; break;
      case _C_LNG      : value = [NSNumber numberWithLong:*(long *) buf]; break;
      case _C_ULNG     : value = [NSNumber numberWithUnsignedLong:*(unsigned long *) buf]; break;
      case _C_LNG_LNG  : value = [NSNumber numberWithLongLong:*(long long *) buf]; break;
      case _C_ULNG_LNG : value = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *) buf]; break;
      case _C_FLT      : value = [NSNumber numberWithFloat:*(float *) buf]; break;
      case _C_DBL      : value = [NSNumber numberWithDouble:*(double *) buf]; break;
#ifdef _C_LNG_DBL
            //   case _C_LNG_DBL  : value = [NSNumber numberWithLongDouble: *(long double *) buf]; break;
#endif
#ifdef _C_BOOL
      case _C_BOOL     : value = [NSNumber numberWithBool:*(BOOL *) buf]; break;
#endif
      default          : value = [NSNumber value:buf withObjCType:returnType]; break;
      }
   }
   pop( pool, value);
   
   return( value);
}


- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   target;
   id   original;
   id   replacement;
   
   original = nil;
   if( [value_ isIdentifier])
      original = [(MulleScionVariable *) value_ identifier];
   
   target = [value_ valueWithLocalVariables:locals
                                 dataSource:dataSource];
   
   if( ! target && original)
      target = [dataSource mulleScionClassFromString:original];
   
   if( ! target)
      [NSException raise:NSInvalidArgumentException
                  format:@"Class or variable named \"%@\" is unknown", original];
   
   return( [self valueOfTarget:target
            withLocalVariables:locals
                    dataSource:dataSource]);
}

@end



@implementation MulleScionExpression ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   return( self);
}


- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [value_ valueWithLocalVariables:locals
                                dataSource:dataSource];
   return( [self evaluateValue:value
                localVariables:locals
                    dataSource:dataSource]);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   [self updateLineNumberInlocalVariables:locals];
   value = [self valueWithLocalVariables:locals
                              dataSource:dataSource];
   if( value)
   {
      value = [value mulleScionDescriptionWithLocalVariables:locals];
      MulleScionRenderString( value, s, locals, dataSource);
   }
   return( self->next_);
}

@end


@implementation MulleScionNumber ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( value_);
}

@end



@implementation MulleScionString ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   return( value_);
}

@end


@implementation MulleScionArray ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   NSEnumerator          *rover;
   NSMutableArray        *array;
   id                    value;
   MulleScionExpression  *expr;
   
   array = [NSMutableArray array];
   
   rover = [value_ objectEnumerator];
   while( expr = [rover nextObject])
   {
      value = [expr valueWithLocalVariables:locals
                                 dataSource:dataSource];
      if( value == nil)
         value = [NSNull null];
      [array addObject:value];
   }
   return( array);
}

@end


@implementation MulleScionVariableAssigment ( Printing)

- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];
   
   if( value)
      [locals setObject:value
                 forKey:value_];
   else
      [locals removeObjectForKey:value_];

   return( value);
}


- (MulleScionObject *)   renderInto:(id <MulleScionOutput>) s
                         localVariables:(NSMutableDictionary *) locals
                             dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   [self updateLineNumberInlocalVariables:locals];
   value = [self valueWithLocalVariables:locals
                              dataSource:dataSource];

   if( value)
   {
      value = [value mulleScionDescriptionWithLocalVariables:locals];
      MulleScionRenderString( value, s, locals, dataSource);
   }
   return( self->next_);
}

@end


@interface MulleScionCommand( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) s
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource;
@end


@implementation MulleScionCommand ( Printing)

- (MulleScionObject *) renderBlock:(MulleScionObject *) curr
                              into:(id <MulleScionOutput>) s
                    localVariables:(NSMutableDictionary *) locals
                        dataSource:(id <MulleScionDataSource>) dataSource
{
   Class   terminatorCls;
   
   terminatorCls = [self terminatorClass];

   while( curr)
   {
      if( [curr isElse])
         return( curr);
      
      if( [curr class] == terminatorCls)
         return( curr);
      
      curr = [curr renderInto:s
               localVariables:locals
                   dataSource:dataSource];
   }
   return( curr);
}

@end


@implementation MulleScionSet ( Printing)


- (id) valueWithLocalVariables:(NSMutableDictionary *) locals
                    dataSource:(id <MulleScionDataSource>) dataSource
{
   id   value;
   
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];
   
   if( value)
      [locals setObject:value
                 forKey:identifier_];
   else
      [locals removeObjectForKey:identifier_];
   
   return( value);
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   // assignment doesn't render
   
   [self updateLineNumberInlocalVariables:locals];
   [self valueWithLocalVariables:locals
                      dataSource:dataSource];
   
   return( self->next_);
}

@end


@implementation MulleScionTerminator ( Printing)


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionPrintingException( NSInternalInconsistencyException, @"stray %@ in template", [self commandName], locals);
}


@end


@implementation MulleScionExpressionCommand ( Printing)

// just executes the expression, but discards the value
- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;
   
   [self updateLineNumberInlocalVariables:locals];
   [expression_ valueWithLocalVariables:locals
                             dataSource:dataSource];
   
   curr = self->next_;
   return( curr);
}

@end


@implementation MulleScionIf ( Printing)

static Class  _nsNumberClass;


static BOOL  isTrue( id value)
{
   return( value && (! [value isKindOfClass:_nsNumberClass] || [value boolValue]));
}


+ (void) load
{
   _nsNumberClass = [NSNumber class];
}


- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   id                 value;
   MulleScionObject   *curr;
   BOOL               flag;
   
   [self updateLineNumberInlocalVariables:locals];
   value = [expression_ valueWithLocalVariables:locals
                                     dataSource:dataSource];

   curr = self->next_;

   flag = isTrue( value);
   if( flag)
      curr = [self renderBlock:curr
                          into:s
                localVariables:locals
                    dataSource:dataSource];

   // here curr is still pointing to else or endif or the first block
   curr = [self terminateToElse:curr];
   if( [curr isElse])
   {
      if( ! flag)
         curr = [self renderBlock:curr->next_
                             into:s
                   localVariables:locals
                       dataSource:dataSource];
      else
         curr = [self terminateToEnd:curr];
   }
   
   if( [curr isEndIf])
      curr = curr->next_;
   
   return( curr);
}

@end


@implementation MulleScionFor ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   BOOL                  isEven;
   BOOL                  isFirst;
   BOOL                  isLast;
   MulleScionObject      *curr;
   MulleScionObject      *memo;
   NSArray               *release;
   NSAutoreleasePool     *pool;
   NSEnumerator          *rover;
   NSMutableDictionary   *info;
   NSString              *closer;
   NSString              *even;
   NSString              *infoKey;
   NSString              *key;
   NSString              *odd;
   NSString              *opener;
   NSString              *separator;
   NSUInteger            i;
   NSUInteger            n;
   NSNumber              *yes, *no;
   id                    value;
   
   pool = [NSAutoreleasePool new];
   
   [self updateLineNumberInlocalVariables:locals];
   
   opener    = [locals objectForKey:MulleScionForOpenerKey];
   separator = [locals objectForKey:MulleScionForSeparatorKey];
   closer    = [locals objectForKey:MulleScionForCloserKey];

   if( ! opener)
      opener = @"";
   if( ! separator)
      separator = @", ";
   if( ! closer)
      closer = @"";

   even = [locals objectForKey:MulleScionEvenKey];
   odd  = [locals objectForKey:MulleScionOddKey];
   
   if( ! even)
      even = @"even";
   if( ! odd)
      odd = @"odd";

   release = nil;
   value   = [expression_ valueWithLocalVariables:locals
                                       dataSource:dataSource];
   
   if( ! [value respondsToSelector:@selector( objectEnumerator)])
      value = release = [[[NSArray alloc] initWithObjects:value, nil] autorelease];
   
   curr  = self->next_;
   memo  = curr;

   rover = [value objectEnumerator];

   i     = 0;
   n     = [[rover allObjects] count];  
   rover = [value objectEnumerator];

   info  = [NSMutableDictionary dictionary];
   [info setObject:[NSNumber numberWithInteger:n]
            forKey:@"n"];
   
   infoKey = [NSString stringWithFormat:@"%@#", identifier_];
   [locals setObject:info
              forKey:infoKey];
   
   yes = [NSNumber numberWithBool:YES];
   no  = [NSNumber numberWithBool:NO];
   while( key = [rover nextObject])
   {
      isFirst = i == 0;
      isLast  = i == n - 1;
      isEven  = !(i & 1);
      
      [info setObject:[NSNumber numberWithInteger:i]
               forKey:@"i"];
      [info setObject:isFirst ? opener : @""
               forKey:@"header"];
      [info setObject:isLast ? closer : separator
               forKey:@"footer"];
      [info setObject:isEven ? even : odd
               forKey:@"evenOdd"];
      [info setObject:isFirst ? yes : no
               forKey:@"isFirst"];
      [info setObject:isLast ? yes : no
               forKey:@"isLast"];
      [info setObject:isEven ? yes : no
               forKey:@"isEven"];
      
      [locals setObject:key
                 forKey:identifier_];

      curr = [self renderBlock:memo
                          into:s
                localVariables:locals
                    dataSource:dataSource];
      ++i;
   }

   curr = [self terminateToEnd:curr];
   if( [curr isEndFor])
      curr = curr->next_;
   
   [pool release];
   
   return( curr);
}

@end


@implementation MulleScionWhile ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   id                     value;
   MulleScionObject       *curr;
   MulleScionObject       *memo;
   
   [self updateLineNumberInlocalVariables:locals];

   curr = self->next_;
   memo = curr;
   
   for(;;)
   {
      value = [expression_ valueWithLocalVariables:locals
                                        dataSource:dataSource];
   
      if( ! isTrue( value))
         break;
      
      curr = [self renderBlock:memo
                          into:s
                localVariables:locals
                    dataSource:dataSource];
   }
   
   curr = [self terminateToEnd:curr];
   if( [curr isEndWhile])
      curr = curr->next_;
   return( curr);
}

@end


@implementation MulleScionBlock ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionObject   *curr;

   [self updateLineNumberInlocalVariables:locals];
   
   curr = [self renderBlock:self->next_
                       into:s
             localVariables:locals
                 dataSource:dataSource];
   if( [curr isEndBlock])
      curr = curr->next_;
   return( curr);
}

@end


@implementation MulleScionPipe ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   NSString        *identifier;
   MulleScionPipe  *next;
   
   // make it string
   value = [value mulleScionDescriptionWithLocalVariables:locals];
   
   if( ! [self->right_ isPipe])
   {
      if( [self->right_ isMethod])
      {
         [locals setObject:value
                    forKey:MulleScionSelfReplacementKey];
         value = [(MulleScionMethod *) self->right_ valueWithLocalVariables:locals
                                                                 dataSource:dataSource];
         [locals removeObjectForKey:MulleScionSelfReplacementKey];
         
         return( value);
      }
      
      identifier = [(MulleScionVariable *) self->right_ identifier];
      value      = [dataSource mulleScionPipeString:value
                                      throughMethod:identifier
                                     localVariables:locals];
      return( value);
   }

   next = (MulleScionPipe *) self->right_;
   NSParameterAssert( [next->value_ isKindOfClass:[MulleScionVariable class]]);
   
   identifier = [(MulleScionVariable *) next->value_ identifier];
   value      = [dataSource mulleScionPipeString:value
                                   throughMethod:identifier
                                  localVariables:locals];
   return( [self->right_ evaluateValue:value
                        localVariables:locals
                            dataSource:dataSource]);
}

@end


@implementation MulleScionDot ( Printing)

- (id) evaluateValue:(id) value
      localVariables:(NSMutableDictionary *) locals
          dataSource:(id <MulleScionDataSource>) dataSource
{
   NSString        *identifier;
   MulleScionDot   *next;
   
   if( ! [self->right_ isDot])
   {
      if( [self->right_ isMethod])
      {
         [locals setObject:value
                    forKey:MulleScionSelfReplacementKey];
         value = [(MulleScionMethod *) self->right_ valueWithLocalVariables:locals
                                                                 dataSource:dataSource];
         [locals removeObjectForKey:MulleScionSelfReplacementKey];

         return( value);
      }
      
      identifier = [(MulleScionVariable *) self->right_ identifier];
      value      = [value mulleScionValueForKeyPath:identifier
                                     localVariables:locals];
      return( value);
   }
   
   next = (MulleScionDot *) self->right_;
   if( [next->value_ isIdentifier])
   {
      identifier = [(MulleScionVariable *) next->value_ identifier];
      value      = [value mulleScionValueForKeyPath:identifier
                                     localVariables:locals];
   }
   return( [self->right_ evaluateValue:value
                        localVariables:locals
                            dataSource:dataSource]);
}

@end


@implementation MulleScionFilter ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   MulleScionExpression  *prev;
   NSMutableArray        *stack;
   
   [self updateLineNumberInlocalVariables:locals];
   
   prev = [locals objectForKey:MulleScionCurrentFilterKey];
   if( prev)
   {
      stack = [locals objectForKey:MulleScionPreviousFiltersKey];
      if( ! stack)
      {
         stack = [NSMutableArray new];
         [locals setObject:stack
                    forKey:MulleScionPreviousFiltersKey];
         [stack release];
      }
      [stack addObject:prev];
   }
   
   // filters don't stack ( sorry)
   [locals setObject:self->expression_
              forKey:MulleScionCurrentFilterKey];
   
   return( self->next_);
}

@end


@implementation MulleScionEndFilter ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource
{
   NSMutableArray   *stack;
   
   [self updateLineNumberInlocalVariables:locals];

   if( ! [locals objectForKey:MulleScionCurrentFilterKey])
      MulleScionPrintingException( NSInvalidArgumentException, @"stray endfilter", locals);
   
   stack = [locals objectForKey:MulleScionPreviousFiltersKey];
   [stack removeLastObject];
   
   return( self->next_);
}

@end



