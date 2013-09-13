//
//  MulleScionParser+Parsing.m
//  MulleScionTemplates
//
//  Created by Nat! on 26.02.13.
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

#import "MulleScionParser+Parsing.h"

#define MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY  @public

#import "MulleScionObjectModel+Parsing.h"
#import "MulleScionObjectModel+NSCoding.h"
#import "MulleScionObjectModel+MacroExpansion.h"
#if ! TARGET_OS_IPHONE  
# import <Foundation/NSDebug.h>
#endif

@implementation MulleScionParser ( Parsing)

// parse it a little like Twig
// {# comment #}
// {{ identifier }}
// {{ #number }}
// {{ "string" }}
// {{ [ identifier string expr ... ] }}
// {% variable = expr %}
// {% if expr %}
// {% else %}
// {% endif %}
// {% for identifier in expr %}
// {% endfor %}
// {% while expr %}
// {% endwhile %}
// {% block identifier %}
// {% endblock %}
// {% includes "string" %}
// {% extends "string" %}  // with extends, the loaded template is searched for
//                         // blocks these are then substitued for the blocks
//                         // of the same name, that already exist
//
typedef enum
{
   eof        = -1,
   expression = 0,
   command    = 1,
   comment    = 2
} macro_type;


typedef struct _parser_memo
{
   unsigned char   *curr;
   NSUInteger      lineNumber;
} parser_memo;


typedef struct _parser
{
   unsigned char        *buf;
   unsigned char        *sentinel;
   
   unsigned char        *curr;
   NSUInteger           lineNumber;
   
   parser_memo          memo;
   parser_memo          memo_scion;
   
   MulleScionObject     *first;
   macro_type           type;
   
   void                 (*parser_do_error)( id self, SEL sel, NSString *filename, NSUInteger line, NSString *message);
   id                   self;
   SEL                  sel;
   int                  inMacro;
   int                  allowMacroCall;
   int                  wasMacroCall;
   NSString             *fileName;
   NSMutableDictionary  *blocksTable;
   NSMutableDictionary  *definitionTable;
   NSMutableDictionary  *macroTable;
   NSMutableDictionary  *dependencyTable;
} parser;


static void   parser_init( parser *p, unsigned char *buf, size_t len)
{
   memset( p, 0, sizeof( parser));
   if( buf && len)
   {
      p->buf        = p->curr = buf;
      p->sentinel   = &p->buf[ len];
      p->lineNumber = 1;
   }
}

static inline void   parser_set_error_callback( parser *p, id self, SEL sel)
{
   p->self        = self;
   p->sel         = sel;
   p->parser_do_error = (void *) [p->self methodForSelector:sel];
}


static inline void   parser_set_blocks_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->blocksTable = table;
}


static inline void   parser_set_definitions_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->definitionTable = table;
}


static inline void   parser_set_dependency_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->dependencyTable = table;
}


static inline void   parser_set_macro_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->macroTable = table;
}


static inline void   parser_set_filename( parser *p, NSString *s)
{
   p->fileName = s;
}


static void  MULLE_NO_RETURN  parser_error( parser *p, char *c_format, ...)
{

   NSString       *reason;
   size_t         len;
   unsigned char  *s;
   va_list        args;
   char           *prefix;
   
   if( p->parser_do_error)
   {
      va_start( args, c_format);
      reason = [[[NSString alloc] initWithFormat:[NSString stringWithCString:c_format]
                                       arguments:args] autorelease];

      prefix  = "";
      s   = (unsigned char *) p->memo_scion.curr - 2;
      len = p->curr - p->memo_scion.curr;
      if( len < 3)
      {
         s   = &p->memo.curr[ -16];
         len = 16;
         
         if( s < p->buf)
         {
            s   = p->buf;
            len = p->curr - p->buf;
         }
      }

      if( len > 64)
      {
         s      = &s[ len - 64];
         prefix = "...";
         len    = 64;
      }
      
      reason = [NSString stringWithFormat:@"at '%s%.*s': %@", prefix, (int) len, (char *) s, reason];
      va_end( args);
   
      (*p->parser_do_error)( p->self, p->sel, p->fileName, p->memo.lineNumber, reason);
   }
   abort();
}


static inline void   parser_memorize( parser *p, parser_memo *memo)
{
   memo->curr       = p->curr;
   memo->lineNumber = p->lineNumber;
}


static inline void   parser_recall( parser *p, parser_memo *memo)
{
   p->curr       = memo->curr;
   p->lineNumber = memo->lineNumber;
}


static inline void   parser_nl( parser *p)
{
   p->lineNumber++;
}


//
// this will stop at '{{' or '{%' even if they are in the middle of
// quotes. To print {{ use {{ "{{" }}
//
static macro_type   parser_grab_text_until_scion( parser *p)
{
   unsigned char   c, d;
   int             inquote;
   
   parser_memorize( p, &p->memo);
   
   inquote = 0;
   c = p->curr > p->buf ? p->curr[ -1] : 0;
   while( p->curr < p->sentinel)
   {
      d = c;
      c = *p->curr++;

      if( c == '\n')
         parser_nl( p);
      
      if( c == '"')
         inquote = ! inquote;
      
      if( d == '{')
      {
         parser_memorize( p, &p->memo_scion);
         if( c == '{')
         {
            p->curr -= 2;
            return( expression);
         }

         if( c == '%')
         {
            p->curr -= 2;
            return( command);
         }
         
         if( c == '#')
         {
            p->curr -= 2;
            return( comment);
         }
      }
   }
   return( eof);
}


static macro_type   parser_grab_text_until_scion_end( parser *p)
{
   unsigned char   c, d;
   int             inquote;
   
   parser_memorize( p, &p->memo);
   
   inquote = 0;
   c = p->curr > p->buf ? p->curr[ -1] : 0;
   while( p->curr < p->sentinel)
   {
      if( c == '\n')
         parser_nl( p);
      
      if( c == '"')
         inquote = ! inquote;
      if( inquote)
         continue;
      
      d = c;
      c = *p->curr++;
      
      if( c == '}')
      {
         if( d == '}')
            return( expression);
         
         if( d == '%')
            return( command);
         
         if( d == '#')
            return( comment);
      }
   }
   return( eof);
}


static void   parser_skip_white_if_terminated_by_newline( parser *p)
{
   parser_memo   memo;
   unsigned char   c;
   
   parser_memorize( p, &memo);
   
   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         return;
      }
      
      if( c > ' ')
      {
         parser_recall( p, &memo);
         break;
      }
   }
}


static void   parser_skip_whitespace( parser *p)
{
   unsigned char   c;
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      if( c == '\n')
         parser_nl( p);
      
      if( c > ' ')
         break;
   }
}


static macro_type   parser_skip_text_until_scion_end( parser *p, int type)
{
   unsigned char   c;
   unsigned char   d;
   int             inquote;
   
   inquote = 0;
   c       = 0;
   
   for( ; p->curr < p->sentinel;)
   {
      d = c;
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         continue;
      }
      if( c == '"')
         inquote = ! inquote;
      if( inquote)
         continue;
      
      if( c == '}')
         if( d == type)
            return( comment);
   }
   return( eof);
}


static void   parser_skip_white_until_scion_or_after_newline( parser *p)
{
   unsigned char   c;
   unsigned char   d;
   int             inquote;
   
   inquote = 0;
   c       = 0;
   for( ; p->curr < p->sentinel;)
   {
      d = c;
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         break;
      }
      
      if( c == '"')
         inquote = ! inquote;
      if( inquote)
         continue;
      
      if( c > ' ')
      {
         p->curr--;
         break;
      }
      
      if( d == '{')
      {
         if( c == '{')
         {
            p->curr -= 2;
            break;
         }
         
         if( c == '%')
         {
            p->curr -= 2;
            break;
         }
      }
   }
}


// we consume white space to
static void   parser_adjust_memo_to_end_of_previous_line( parser *p, parser_memo *memo)
{
   unsigned char  *s;
   unsigned char  c;
   
   s = memo->curr;
   while( s > p->buf)
   {
      c = *--s;
      if( c == '\n')
      {
         memo->curr = s + 1;
         break;
      }
      
      if( c > ' ')  // any kind of non-whitespace preserves other whitespace
         break;
   }
}


// just a simple heuristic to grab enough characters
static BOOL   parser_grab_text_until_number_end( parser *p)
{
   unsigned char   c;
   BOOL            isFloat;
   
   parser_memorize( p, &p->memo);

   isFloat = NO;
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      if( c >= '0' && c <= '9')
         continue;

      if( c == '+' || c == '-')
         continue;

      if( c == '.' || c == 'e')
      {
         isFloat = YES;
         continue;
      }
      break;
   }
   return( isFloat);
}


static int   parser_grab_text_until_selector_end( parser *p, int partial)
{
   unsigned char   c;
   
   parser_memorize( p, &p->memo);
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      
      if( c >= '0' && c <= '9')
      {
         if( p->memo.curr  == p->curr)
            break;
         continue;
      }
      
      if( c >= 'A' && c <= 'Z')
         continue;
      
      if( c >= 'a' && c <= 'z')
         continue;
      
      if( c == '_')
         continue;
      
      if( c == ':')
      {
         if( ! partial)
            continue;
         p->curr++;
         return( 1);
      }
      
      break;
   }
   return( 0);
}


static void   parser_grab_text_until_key_path_end( parser *p)
{
   unsigned char   c;
   
   parser_memorize( p, &p->memo);
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      
      //
      // stuff that keypaths can't start with (but may contain)
      // MulleScion uses the '#'
      //
      if( (c >= '0' && c <= '9') ||  c == '#' || c == '@' || c == '.' || c == ':')
      {
         if( p->memo.curr == p->curr)
            break;
         continue;
      }
      
      if( c >= 'A' && c <= 'Z')
         continue;
      
      if( c >= 'a' && c <= 'z')
         continue;
      
      if( c == '_')
         continue;
      break;
   }
}


static void   parser_grab_text_until_identifier_end( parser *p)
{
   unsigned char   c;
   
   parser_memorize( p, &p->memo);
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      
      if( c >= '0' && c <= '9')
      {
         if( p->memo.curr == p->curr)
            break;
         continue;
      }
      
      if( c >= 'A' && c <= 'Z')
         continue;
      
      if( c >= 'a' && c <= 'z')
         continue;
      
      if( c == '_')
         continue;
      
      break;
   }
}


static int   parser_grab_text_until_command( parser *p, char *command)
{
   unsigned char   c;
   unsigned char   d;
   int             stage;
   size_t          len;
   int             inquote;
   parser_memo     memo;
   
   inquote = 0;
   len   = strlen( command);
   stage = -2;
   c     = 0;
   for( ; p->curr < p->sentinel;)
   {
      d = c;
      c = *p->curr++;
      if( c == '\n')
         parser_nl( p);
      
      if( c == '"')
         inquote = ! inquote;
      if( inquote)
      {
         stage = -2;
         continue;
      }
      
      switch( stage)
      {
      case -2 :
         if( c == '%')
            if( d == '{')
            {
               parser_memorize( p, &memo);
               stage++;
            }
         continue;
         
      case -1 :
         if( c <= ' ')
            continue;
         ++stage;
         
      default :
         if( stage == len)
         {
            if( c <= ' ' || c == '%')
            {
               parser_recall( p, &memo);
               p->curr -= 2;
               return( 1);
            }
         }
         else
            if( c == command[ stage])
            {
               ++stage;
               continue;
            }
         stage = -2;
         continue;
      }
   }
   return( 0);
}


static void   parser_grab_text_until_quote( parser *p)
{
   unsigned char   c;
   int             escaped;
   
   parser_memorize( p, &p->memo);
   
   escaped = 0;
   
   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
         parser_nl( p);
      
      if( escaped)
      {
         escaped = 0;
         continue;
      }
      if( c == '\\')
      {
         escaped  = 1;
         continue;
      }
      if( c == '"')
      {
         p->curr--;
         break;
      }
   }
}


static NSString   * NS_RETURNS_RETAINED parser_get_memorized_retained_string( parser_memo *start, parser_memo *end)
{
   NSInteger    length;
   NSString     *s;
   NSData       *data;
   
   length = end->curr - start->curr ;
   if( length <= 0)
      return( nil);
   
   data = [[NSData alloc] initWithBytesNoCopy:start->curr
                                       length:length
                                 freeWhenDone:NO];
   s = [[NSString alloc] initWithData:data
                             encoding:NSUTF8StringEncoding];
   [data release];
   
   return( s);
}


static NSString   * NS_RETURNS_RETAINED parser_get_retained_string( parser *p)
{
   NSUInteger   length;
   NSString     *s;
   
   length = p->curr - p->memo.curr ;
   if( ! length)
      return( nil);
   
   s = [[NSString alloc] initWithBytes:p->memo.curr
                                length:length
                              encoding:NSUTF8StringEncoding];
   return( s);
}


static NSString   *parser_get_string( parser *p)
{
   return( [parser_get_retained_string( p) autorelease]);
}


static unsigned char   parser_peek_character( parser *p)
{
   return( p->curr < p->sentinel ? *p->curr : 0);
}


static void   parser_undo_character( parser *p)
{
   if( p->curr <= p->buf)
      parser_error( p, "internal buffer underflow");
   p->curr--;
}


static inline unsigned char   parser_next_character( parser *p)
{
   return( p->curr < p->sentinel ? *p->curr++ : 0);
}


static NSString  *parser_do_key_path( parser *p)
{
   NSString   *s;
   
   parser_grab_text_until_key_path_end( p);
   s = parser_get_string( p);
   if( ! s)
      parser_error( p, "key path expected");
   parser_skip_whitespace( p);
   return( s);
}


static NSString  *parser_do_identifier( parser *p)
{
   NSString   *s;
   
   parser_grab_text_until_identifier_end( p);
   s = parser_get_string( p);
   if( ! s)
      parser_error( p, "identifier expected");
   parser_skip_whitespace( p);
   return( s);
}


static NSNumber *parser_do_number( parser *p)
{
   NSString   *s;
   BOOL       isFloat;
   
   isFloat = parser_grab_text_until_number_end( p);
   s       = parser_get_string( p);
   if( ! s)
      parser_error( p, "number expected");
   parser_skip_whitespace( p);
   if( isFloat)
      return( [NSNumber numberWithDouble:[s doubleValue]]);
   return( [NSNumber numberWithLongLong:[s longLongValue]]);
}


static NSString  *parser_do_string( parser *p)
{
   NSString   *s;
   
   NSCParameterAssert( parser_peek_character( p) == '"');
   
   parser_next_character( p);   // skip '"'
   parser_grab_text_until_quote( p);
   s = parser_get_string( p);
   parser_next_character( p); // skip "
   parser_skip_whitespace( p);
   
   return( s ? s : @"");
}


static MulleScionExpression * NS_RETURNS_RETAINED  parser_do_expression( parser *p);

static inline MulleScionExpression * NS_RETURNS_RETAINED  parser_do_unary_expression( parser *p);


static NSMutableArray   *parser_do_array( parser *p)
{
   NSMutableArray         *array;
   MulleScionExpression   *expr;
   unsigned char           c;
   
   NSCParameterAssert( parser_peek_character( p) == '(');
   parser_next_character( p);

   array = [NSMutableArray array];
   expr  = nil;
   for(;;)
   {
      parser_skip_whitespace( p);
      c = parser_peek_character( p);
      if( c == ')')
      {
         parser_next_character( p);
         break;
      }
      
      if( c == ',')
      {
         if( ! expr)
            parser_error( p, "lonely comma in array");
         parser_next_character( p);
      }
      else
      {
         if( expr)
            parser_error( p, "comma or closing parenthesis expected");
      }

      expr = parser_do_expression( p);
      
      [array addObject:expr];
      [expr release];
   }
   return( array);
}


static MulleScionMethod  * NS_RETURNS_RETAINED parser_do_method( parser *p)
{
   NSMutableString        *selBuf;
   NSString              *selName;
   NSMutableArray         *arguments;
   NSUInteger             line;
   MulleScionExpression   *target;
   MulleScionExpression   *expr;
   int                    hasColon;
   unsigned char          c;
   
   NSCParameterAssert( parser_peek_character( p) == '[');
   parser_next_character( p);   // skip '['
   parser_skip_whitespace( p);
   
   line   = p->memo.lineNumber;
   target = parser_do_expression( p);
   
   hasColon = parser_grab_text_until_selector_end( p, YES);
   selName  = parser_get_string( p);
   if( ! selName)
      parser_error( p, "selector expected");
   
   arguments = nil;
   if( hasColon)
   {
      arguments = [NSMutableArray array];
      selBuf    = [NSMutableString string];
      for( ;;)
      {
         [selBuf appendString:selName];
         
         for(;;)
         {
            expr = parser_do_expression( p);
            if( ! expr)
               parser_error( p, "expression expected");
            [arguments addObject:expr];
            [expr release];
         
            parser_skip_whitespace( p);
            c = parser_peek_character( p);
            if( c != ',')
               break;

            parser_error( p, "sorry but varargs isn't in the cards yet");
            
            parser_next_character( p);
            parser_skip_whitespace( p);
         }
         
         hasColon = parser_grab_text_until_selector_end( p, YES);
         if( hasColon)
         {
            selName = parser_get_string( p);
            continue;
         }
         break;
      }
      
      selName = selBuf;
   }
   
   parser_skip_whitespace( p);
   if( parser_next_character( p) != ']')
      parser_error( p, "closing ']' expected");
   
   return( [MulleScionMethod newWithRetainedTarget:target
                                        methodName:selName
                                         arguments:arguments
                                        lineNumber:line]);
}


static MulleScionObject  * NS_RETURNS_RETAINED parser_expand_macro_with_arguments( parser *p,
                                                              MulleScionMacro *macro,
                                                              NSArray *arguments,
                                                              NSUInteger line)
{
   MulleScionTemplate  *body;
   NSDictionary        *parameters;
   MulleScionObject    *obj;
   NSAutoreleasePool   *pool;

   pool       = [NSAutoreleasePool new];
   parameters = [macro parametersWithArguments:arguments
                                      fileName:p->fileName
                                    lineNumber:p->memo.lineNumber];
   body       = [macro expandedBodyWithParameters:parameters
                                         fileName:p->fileName
                                       lineNumber:p->memo.lineNumber];
   
   // so hat do we do with the body now ?
   // snip off the head
   obj   = [body behead];
   // the tricky thing is, that 'obj' is now not autoreleased anymore
   // while body is
   [pool release];

   return( obj);
}


static MulleScionObject  * NS_RETURNS_RETAINED parser_do_function_or_macro( parser *p, NSString *identifier)
{
   NSMutableArray   *arguments;
   MulleScionMacro  *macro;
   
   NSCParameterAssert( parser_peek_character( p) == '(');
   
   arguments       = parser_do_array( p);
   macro           = [p->macroTable objectForKey:identifier];
   p->wasMacroCall = macro != nil;
   if( macro)
      return( parser_expand_macro_with_arguments( p, macro, arguments, p->memo.lineNumber));

   return( [MulleScionFunction newWithIdentifier:identifier
                                       arguments:arguments
                                      lineNumber:p->memo.lineNumber]);
}


static MulleScionFunction  * NS_RETURNS_RETAINED parser_do_function( parser *p, NSString *identifier)
{
   NSMutableArray   *arguments;
   
   arguments = parser_do_array( p);
   return( [MulleScionFunction newWithIdentifier:identifier
                                       arguments:arguments
                                      lineNumber:p->memo.lineNumber]);
}


static MulleScionVariableAssignment  * NS_RETURNS_RETAINED parser_do_assignment( parser *p, NSString *identifier)
{
   MulleScionExpression  *expr;
   
   NSCParameterAssert( parser_peek_character( p) == '=');
   parser_next_character( p);
   parser_skip_whitespace( p);
   
   expr = parser_do_expression( p);
   return( [MulleScionVariableAssignment newWithIdentifier:identifier
                                       retainedExpression:expr
                                               lineNumber:p->memo.lineNumber]);
}


static MulleScionIndexing  * NS_RETURNS_RETAINED parser_do_indexing( parser *p,
                                                                     MulleScionExpression * NS_CONSUMED left,
                                                                     MulleScionExpression * NS_CONSUMED right)
{
   unsigned char   c;
   
   parser_skip_whitespace( p);
   
   c = parser_next_character( p);
   if( c != ']')
      parser_error( p, "closing ']' expected");
   
   return( [MulleScionIndexing newWithRetainedLeftExpression:left
                                     retainedRightExpression:right
                                                  lineNumber:p->memo.lineNumber]);
}

static MulleScionConditional  * NS_RETURNS_RETAINED parser_do_conditional( parser *p,
                                                                           MulleScionExpression * NS_CONSUMED left,
                                                                           MulleScionExpression * NS_CONSUMED middle)
{
   MulleScionExpression   *right;
   unsigned char          c;
   
   parser_skip_whitespace( p);
   c = parser_next_character( p);
   if( c != ':')
      parser_error( p, "conditional ':' expected");
   right = parser_do_expression( p);
   return( [MulleScionConditional newWithRetainedLeftExpression:left
                                       retainedMiddleExpression:middle
                                        retainedRightExpression:right
                                                     lineNumber:p->memo.lineNumber]);
}



static MulleScionNot  * NS_RETURNS_RETAINED parser_do_not( parser *p)
{
   MulleScionExpression  *expr;
   
   parser_skip_whitespace( p);

   // gives not implicit precedence over and / or
   expr = parser_do_unary_expression( p);
   return( [MulleScionNot newWithRetainedExpression:expr
                                         lineNumber:p->memo.lineNumber]);
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_parenthesized_expression(  parser *p)
{
   MulleScionExpression  *expr;
   unsigned char         c;
   
   parser_next_character( p);

   expr = parser_do_expression( p);
   
   parser_skip_whitespace( p);
   c = parser_peek_character( p);
   if( c != ')')
      parser_error( p, "closing ')' in parenthesis expression expected. (Hint: prefix arrays with @)");
   return( expr);
}


static MulleScionSelector * NS_RETURNS_RETAINED  parser_do_selector(  parser *p)
{
   unsigned char         c;
   NSString              *selectorName;
   
   parser_skip_whitespace( p);

   c = parser_next_character( p);
   if( c != '(')
      parser_error(p, "expected '(' after selector");
   parser_skip_whitespace( p);

   parser_grab_text_until_selector_end( p, NO);
   selectorName  = parser_get_string( p);
   if( ! [selectorName length])
      parser_error(p, "selector name expected");
   
   parser_skip_whitespace( p);
   c = parser_next_character( p);
   if( c != ')')
      parser_error(p, "expected closing ')' after selector");

   return( [MulleScionSelector newWithString:selectorName
                                  lineNumber:p->memo.lineNumber]);
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_unary_expression_or_macro( parser *p, int allowMacroCall)
{
   NSString              *s;
   unsigned char         c;
   MulleScionExpression  *expr;
   int                   hasAt;
   
   parser_skip_whitespace( p);
   c = parser_peek_character( p);
   hasAt = (c == '@');
   if( hasAt)  // skip adorning '@'s
   {
      parser_next_character( p);
      c = parser_peek_character( p);
   }
   switch( c)
   {
   case '!' : parser_next_character( p);
              return( parser_do_not( p));
   case '"' : return( [MulleScionString newWithString:parser_do_string( p)
                                           lineNumber:p->memo.lineNumber]);
   case '0' : case '1' : case '2' : case '3' : case '4' :
   case '5' : case '6' : case '7' : case '8' : case '9' :
   case '+' : case '-' : case '.' :  // valid starts of FP nrs
      return( [MulleScionNumber newWithNumber:parser_do_number( p)
                                   lineNumber:p->memo.lineNumber]);
   case '(' :  if( hasAt)
                  return( [MulleScionArray newWithArray:parser_do_array( p)
                                             lineNumber:p->memo.lineNumber]);
                return( parser_do_parenthesized_expression( p));
   case '[' : return( parser_do_method( p));
   }
   
   // this laymes
   s = parser_do_key_path( p);
   if( [s isEqualToString:@"nil"])
      return( [MulleScionNumber newWithNumber:nil
                                   lineNumber:p->memo.lineNumber]);
   if( [s isEqualToString:@"YES"])
      return( [MulleScionNumber newWithNumber:[NSNumber numberWithBool:YES]
                                   lineNumber:p->memo.lineNumber]);
   if( [s isEqualToString:@"NO"])
      return( [MulleScionNumber newWithNumber:[NSNumber numberWithBool:NO]
                                   lineNumber:p->memo.lineNumber]);
   if( [s isEqualToString:@"not"])
      return( parser_do_not( p));
   if( [s isEqualToString:@"selector"])
      return( parser_do_selector( p));
   
   parser_skip_whitespace( p);
   c = parser_peek_character( p);
   switch( c )
   {
   case '=' : parser_next_character( p);
              c = parser_peek_character( p);
              parser_undo_character( p);
              if( c == '=')
                 break;
              return( parser_do_assignment( p, s));
   case '(' : if( allowMacroCall)
                 return( parser_do_function_or_macro( p, s));
              return( parser_do_function( p, s));
   default  : break;
   }

   expr = [p->definitionTable objectForKey:s];
   if( expr)
      return( [expr copyWithZone:NULL]);

   return( [MulleScionVariable newWithIdentifier:s
                                      lineNumber:p->memo.lineNumber]);
}


static inline MulleScionExpression * NS_RETURNS_RETAINED  parser_do_unary_expression( parser *p)
{
   return( (MulleScionExpression *) parser_do_unary_expression_or_macro( p, NO));
}


static BOOL  parser_next_matching_string( parser *p, char *expect, size_t len_expect)
{
   parser_memo   memo;
   size_t        len;
   
   parser_memorize( p, &memo);
   parser_grab_text_until_identifier_end( p);
   len = p->curr - memo.curr;
   if( len != len_expect)
   {
      parser_recall( p, &memo);
      return( NO);
   }

   return( ! memcmp( (char *) memo.curr, expect, len_expect));
}


static MulleScionComparisonOperator  parser_check_comparison_op( parser *p, char c)
{
   char   d;
   BOOL   flag;
   
   d = parser_next_character( p);
   c = parser_peek_character( p);
   flag = (c == '=');
   if( flag)
      parser_next_character( p);
   
   switch( d)
   {
   case '<' : return( flag ? MulleScionLessThanOrEqualTo : MulleScionLessThan);
   case '>' : return( flag ? MulleScionGreaterThanOrEqualTo : MulleScionGreaterThan);
   case '!' : if( ! flag) break; return( MulleScionNotEqual);
   case '=' : if( ! flag) break; return( MulleScionNotEqual);
   }

   parser_error( p, "unexpected character %c", d);
}


static MulleScionExpression * NS_RETURNS_RETAINED  _parser_do_expression( parser *p, MulleScionExpression *left)
{
   MulleScionExpression          *right;
   unsigned char                 operator;
   
   parser_skip_whitespace( p);
   
   /* get the operator */
   operator = parser_peek_character( p);
   switch( operator)
   {
   default  : return( left);
   case '&' : if( ! parser_next_matching_string( p, "&&", 2))
                  return( left);
               operator = 'a';
               break;
   case '|' : if( parser_next_matching_string( p, "||", 2))
                 operator = 'o';
              else
                 parser_next_character( p);
              break;
   case 'a' : if( ! parser_next_matching_string( p, "and", 3))
                 return( left);
              break;
   case 'o' : if( ! parser_next_matching_string( p, "or", 2))
                 return( left);
              break;
   case '<' :
   case '>' :
   case '!' :
   case '=' : operator = parser_check_comparison_op( p, operator); break;
   case '?' :
   case '[' :
   case '.' : // the irony, that I have to support "modern" ObjC to do C :)
         parser_next_character( p);
         break;
   }
   
   parser_skip_whitespace( p);
   
   right = parser_do_expression( p);
   
   switch( operator)
   {
   default :
      return( [MulleScionComparison newWithRetainedLeftExpression:left
                                          retainedRightExpression:right
                                                       comparison:operator
                                                       lineNumber:p->memo.lineNumber]);
   case 'a' :
      return( [MulleScionAnd newWithRetainedLeftExpression:left
                                   retainedRightExpression:right
                                                lineNumber:p->memo.lineNumber]);
   case 'o' :
      return( [MulleScionOr newWithRetainedLeftExpression:left
                                  retainedRightExpression:right
                                               lineNumber:p->memo.lineNumber]);
   case '[' :
      return( parser_do_indexing( p, left, right));

   case '?' :
      return( parser_do_conditional( p, left, right));
         
   case '|' :
      if( ! [right isMethod] && ! [right isPipe] && ! [right isIdentifier])
         parser_error( p, "identifier expected after '|'");
      return( [MulleScionPipe newWithRetainedLeftExpression:left
                                    retainedRightExpression:right
                                                 lineNumber:p->memo.lineNumber]);
   case '.' :
      if( ! [right isMethod] && ! [right isPipe] && ! [right isDot] && ! [right isIdentifier])
         parser_error( p, "identifier expected after '.'");
      return( [MulleScionDot newWithRetainedLeftExpression:left
                                   retainedRightExpression:right
                                                lineNumber:p->memo.lineNumber]);
   }
   return( nil);  // can't happen
}

// this is the path to arithmetic expression also, but DO NOT WANT right now
// chief use is rea
static MulleScionExpression * NS_RETURNS_RETAINED  parser_do_expression( parser *p)
{
   MulleScionExpression  *left;
   
   left = parser_do_unary_expression( p);
   return( _parser_do_expression( p, left));
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_expression_or_macro( parser *p)
{
   MulleScionObject  *left;
   
   left = parser_do_unary_expression_or_macro( p, YES);
   if( p->wasMacroCall)
      return( left);
   
   return( _parser_do_expression( p, (MulleScionExpression *) left));
}


static MulleScionObject  *_parser_next_object( parser *p,  MulleScionObject *owner, macro_type *last_type);

static inline MulleScionObject  *parser_next_object( parser *p,  MulleScionObject *owner, macro_type *last_type)
{
   NSAutoreleasePool   *pool;
   MulleScionObject    *curr;
   
   pool  = [NSAutoreleasePool new];
   curr  = _parser_next_object( p, owner, last_type);
   // we know that curr has been retained by owner, so don't need to "save"
   [pool release];
   
   return( curr);
}

static MulleScionObject  *_parser_next_object_after_extend( parser *p, macro_type *last_type);

static inline MulleScionObject  *parser_next_object_after_extend( parser *p, macro_type *last_type)
{
   NSAutoreleasePool   *pool;
   MulleScionObject    *curr;
   
   pool  = [NSAutoreleasePool new];
   curr  = _parser_next_object_after_extend( p, last_type);
   [curr retain];
   [pool release];
   
   return( [curr autorelease]);
}


static void   parser_finish_comment( parser *p)
{
   macro_type  end_type;
   
   end_type = parser_skip_text_until_scion_end( p, '#');
   parser_skip_white_if_terminated_by_newline( p);
   if( end_type != comment)
      parser_error( p, "no comment closer found '#}'");
}


static void   parser_finish_expression( parser *p)
{
   macro_type  end_type;
   
   end_type = parser_grab_text_until_scion_end( p);
   if( end_type != expression)
      parser_error( p, "non matching closer found instead of '}}'");
}


static void   parser_finish_command( parser *p)
{
   macro_type  end_type;
   
   end_type = parser_grab_text_until_scion_end( p);
   parser_skip_white_until_scion_or_after_newline( p);
   
   if( end_type != command)
      parser_error( p, "non matching closer found instead of '%}'");
}


typedef enum
{
   ImplicitSetOpcode = 0,

   BlockOpcode,
   DefineOpcode,
   ElseOpcode,
   EndblockOpcode,
   EndfilterOpcode,
   EndforOpcode,
   EndifOpcode,
   EndmacroOpcode,
   EndverbatimOpcode,
   EndwhileOpcode,
   ExtendsOpcode,
   FilterOpcode,
   ForOpcode,
   IfOpcode,
   IncludesOpcode,
   MacroOpcode,
   SetOpcode,
   VerbatimOpcode,
   WhileOpcode
} MulleScionOpcode;


static char   *mnemonics[] =
{
   "set",
   
   "block",
   "define",
   "else",
   "endblock",
   "endfilter",
   "endfor",
   "endif",
   "endverbatim"
   "endwhile",
   "extends",
   "filter",
   "for",
   "for",
   "if",
   "includes",
   "macro",
   "set",
   "verbatim",
   "while",
};

// LAYME!!
static int   _parser_opcode_for_string( parser *p, NSString *s)
{
   NSUInteger  len;
   
   len = [s length];
   switch( len)
   {
   case 2 : if( [s isEqualToString:@"if"]) return( IfOpcode); break;
   case 3 : if( [s isEqualToString:@"set"]) return( SetOpcode);
            if( [s isEqualToString:@"for"]) return( ForOpcode); break;
   case 4 : if( [s isEqualToString:@"else"]) return( ElseOpcode); break;
   case 5 : if( [s isEqualToString:@"endif"]) return( EndifOpcode);
            if( [s isEqualToString:@"while"]) return( WhileOpcode);
            if( [s isEqualToString:@"macro"]) return( MacroOpcode);
            if( [s isEqualToString:@"block"]) return( BlockOpcode); break;
   case 6 : if( [s isEqualToString:@"define"]) return( DefineOpcode);
            if( [s isEqualToString:@"endfor"]) return( EndforOpcode);
            if( [s isEqualToString:@"filter"]) return( FilterOpcode); break;
   case 7 : if( [s isEqualToString:@"extends"]) return( ExtendsOpcode); break;
   case 8 : if( [s isEqualToString:@"endblock"]) return( EndblockOpcode);
            if( [s isEqualToString:@"endwhile"]) return( EndwhileOpcode);
            if( [s isEqualToString:@"endmacro"]) return( EndmacroOpcode);
            if( [s isEqualToString:@"includes"]) return( IncludesOpcode);
            if( [s isEqualToString:@"verbatim"]) return( VerbatimOpcode); break;
   case 9 : if( [s isEqualToString:@"endfilter"]) return( EndfilterOpcode); break;
   case 11: if( [s isEqualToString:@"endverbatim"]) return( EndverbatimOpcode); break;
   }
   return( -1);
}


static MulleScionOpcode   parser_opcode_for_string( parser *p, NSString *s)
{
   int   opcode;
   
   opcode = _parser_opcode_for_string( p, s);
   if( opcode < 0)
      return( ImplicitSetOpcode);
   return( (MulleScionOpcode) opcode);
}


static char  *parser_best_match_for_string( parser *p, NSString *s)
{
   NSUInteger   length;
   char         *c_s;
   int          i;
   
   s      = [s lowercaseString];
   length = [s length];
   c_s    = (char *) [s cString];
   while( length)
   {
      for( i = 0; i < sizeof( mnemonics) / sizeof( char *); i++)
         if( ! strncmp( mnemonics[ i], c_s, length))
            return( mnemonics[ i]);
      
      --length;
   }
   return( NULL);
}


// grabs a whole block and put it into the table
static void  parser_do_whole_block_to_block_table( parser *p)
{
   MulleScionBlock      *block;
   MulleScionObject     *next;
   MulleScionObject     *node;
   NSString             *identifier;
   NSUInteger           stack;
   macro_type           last_type;
   
   parser_skip_whitespace( p);
   identifier = parser_do_identifier( p);
   if( ! [identifier length])
      parser_error( p, "identifier expected");
   parser_finish_command( p);
   
   block     = [MulleScionBlock newWithIdentifier:identifier
                                         fileName:p->fileName
                                       lineNumber:p->memo.lineNumber];
   assert( block);
   
   stack     = 1;
   last_type = command;
   for( node = block; next = parser_next_object( p, node, &last_type); node = next)
   {
      if( [next isBlock])
      {
         ++stack;
         continue;
      }
      if( [next isEndBlock])
      {
         if( ! --stack)
            break;
         continue;
      }
   }

   if( ! next)
      parser_error( p, "endblock expected");
   
   [p->blocksTable setObject:block
                     forKey:identifier];
   [block release];
}


static MulleScionBlock * NS_RETURNS_RETAINED  parser_do_block( parser *p, NSUInteger line)
{
   NSString   *identifier;
   
   //
   // this is actually not really necessary, but I can't decide if to expand
   // the identifer in the macro or not. Lets have a use case first
   //
   if( p->inMacro)
      parser_error( p, "no block definitions in a macro definition.");
   
   identifier = parser_do_identifier( p);
   if( ! [identifier length])
      parser_error( p, "identifier expected");
   
   return( [MulleScionBlock newWithIdentifier:identifier
                                     fileName:p->fileName
                                   lineNumber:line]);
}


static void  parser_add_dependency( parser *p, NSString *fileName, NSString *include)
{
   NSMutableSet  *set;
   
   if( ! p->dependencyTable)
      return;
   
   set = [p->dependencyTable objectForKey:fileName];
   if( ! set)
   {
      set = [NSMutableSet new];
      [p->dependencyTable setObject:set
                             forKey:fileName];
      [set release];
   }
   [set addObject:include];
}


/*
 * How Extends works.
 * when you read a file, the parser collect statement for the template
 * when it finds the keyword "extends" it stops collecting for the the template
 * and builds up the blockTable all other stuff is discarded. This works
 * recursively.
 */
static MulleScionObject * NS_RETURNS_RETAINED  parser_do_includes( parser *p, BOOL allowVerbatim)
{
   MulleScionTemplate     *inferior;
   MulleScionTemplate     *marker;
   NSString               *fileName;
   BOOL                   verbatim;
   NSString               *s;

   if( p->inMacro)
      parser_error( p, "no including or extending in macro");
   
   verbatim = NO;
   parser_skip_whitespace( p);
   if( parser_peek_character( p) != '"')
   {
      if( ! allowVerbatim || ! parser_next_matching_string( p, "verbatim", 8))
         parser_error( p, "filename expected as a quoted string");

      parser_skip_whitespace( p);
      if( parser_peek_character( p) != '"')
         parser_error( p, "filename expected as a quoted string");
      verbatim = YES;
   }
   
   fileName = parser_do_string( p);
   if( ! [fileName length])
      parser_error( p, "filename expected as a quoted string");
   
   if( verbatim)
   {
      s = [[NSString alloc] initWithContentsOfFile:fileName];
      if( ! s)
         parser_error( p, "could not load include file \"%@\"", fileName);
      
      return( [MulleScionPlainText newWithRetainedString:s
                                              lineNumber:p->memo.lineNumber]);
   }

   parser_finish_command( p);

NS_DURING
   inferior = [p->self templateWithContentsOfFile:fileName
                                       blockTable:p->blocksTable
                                  definitionTable:p->definitionTable
                                       macroTable:p->macroTable
                                  dependencyTable:p->dependencyTable];
NS_HANDLER
   parser_error( p, "%@", [localException reason]);
NS_ENDHANDLER
   if( ! inferior)
      parser_error( p, "could not load include file \"%@\"", fileName);
   
   parser_add_dependency( p, p->fileName, [inferior fileName]);
   
   //
   // make a marker, that we are back. If we are extending all but
   // the blocks are discarded. That's IMO OK
   //
   
   marker = [[MulleScionTemplate alloc] initWithFilename:[p->self fileName]];
   [[inferior tail] appendRetainedObject:marker];
   
   return( [inferior retain]);
}


static MulleScionTemplate * NS_RETURNS_RETAINED  parser_do_extends( parser *p)
{
   MulleScionTemplate    *inferior;
   macro_type            last_type;
   MulleScionObject      *obj;
   
   inferior  = (MulleScionTemplate *) parser_do_includes( p, NO);
   last_type = command;
   
   for(;;)
   {
      obj = parser_next_object_after_extend( p, &last_type);
      if( obj)
         [[inferior tail] appendRetainedObject:obj];
      if( last_type == eof)
         break;
   }
   return( inferior);
}


static MulleScionFunctionCall  * NS_RETURNS_RETAINED  parser_do_function_call( parser *p, NSString *identifier)
{
   MulleScionExpression  *expr;
   
   expr = parser_do_function( p, identifier);
   return( [MulleScionFunctionCall newWithRetainedExpression:expr
                                                  lineNumber:p->memo.lineNumber]);
}


static MulleScionMethodCall  *NS_RETURNS_RETAINED parser_do_method_call( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   expr = parser_do_method( p);
   return( [MulleScionMethodCall newWithRetainedExpression:expr
                                                lineNumber:line]);
}


static MulleScionSet  * NS_RETURNS_RETAINED parser_do_set( parser *p, NSUInteger line)
{
   MulleScionExpression  *expr;
   unsigned char         c;
   NSString              *identifier;
   
   identifier = parser_do_identifier( p);
   if( ! [identifier length])
      parser_error( p, "identifier expected");
   
   c = parser_next_character( p);
   if( c != '=')
      parser_error( p, "'=' expected in set command");

   parser_skip_whitespace( p);
   expr = parser_do_expression( p);
   
   return([MulleScionSet newWithIdentifier:identifier
                        retainedExpression:expr
                                lineNumber:line]);
}



static MulleScionObject  * NS_RETURNS_RETAINED parser_do_implicit_set( parser *p, NSString *identifier, NSUInteger line)
{
   MulleScionExpression  *expr;
   unsigned char         c;
   char                  *suggestion;
   
   c = parser_peek_character( p);
   if( c == '(')  // we iz a function call
      return( parser_do_function_call( p, identifier));
   
   if( c != '=')
   {
      suggestion = parser_best_match_for_string( p, identifier);
      if( suggestion)
         parser_error( p, "unknown keyword \"%@\" (did you mean \"%s\" ?)", identifier, suggestion);
      parser_error( p, "unknown keyword \"%@\" (maybe you forgot the keyword \"set\" ?)", identifier);
   }
   parser_next_character( p);
   parser_skip_whitespace( p);
   expr = parser_do_expression( p);
   
   return([MulleScionSet newWithIdentifier:identifier
                        retainedExpression:expr
                                lineNumber:line]);
}


static MulleScionFor  * NS_RETURNS_RETAINED parser_do_for( parser *p, NSUInteger line)
{
   NSString               *identifier;
   NSString               *s;
   MulleScionExpression   *expr;
   
   parser_skip_whitespace( p);
   identifier = parser_do_identifier( p);
   
   parser_skip_whitespace( p);
   s = parser_do_identifier( p);
   if( ! [s isEqualToString:@"in"])
      parser_error( p, "keyword \"in\" expected in for statement");
   
   expr = parser_do_expression( p);
   return( [MulleScionFor newWithIdentifier:identifier
                         retainedExpression:expr
                                 lineNumber:line]);
}


static MulleScionIf  * NS_RETURNS_RETAINED parser_do_if( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   expr = parser_do_expression( p);
   return( [MulleScionIf newWithRetainedExpression:expr
                                     lineNumber:line]);
}


static MulleScionWhile  * NS_RETURNS_RETAINED parser_do_while( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   expr = parser_do_expression( p);
   return( [MulleScionWhile newWithRetainedExpression:expr
                                           lineNumber:line]);
}


static MulleScionFilter  * NS_RETURNS_RETAINED parser_do_filter( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   expr = parser_do_expression( p);
   if( ! [expr isIdentifier] && ! [expr isPipe]  && ! [expr isMethod])
      parser_error( p, "identifier or pipe expected");
   
   return( [MulleScionFilter newWithRetainedExpression:expr
                                            lineNumber:line]);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_define( parser *p, NSUInteger line)
{
   MulleScionVariableAssignment   *expr;
   MulleScionExpression          *right;
   NSString                      *identifier;
   
   expr = (MulleScionVariableAssignment *) parser_do_unary_expression( p);
   if( ! [expr isVariableAssignment])
      parser_error( p, "identifier with assignment expected");

   identifier = [(MulleScionVariableAssignment *) expr identifier];
   if( [identifier hasPrefix:@"MulleScion"] || [identifier hasPrefix:@"__"])
      parser_error( p, "you can't define internal constants");

   if( parser_opcode_for_string( p, identifier))
      parser_error( p, "you can't override existing commands");
   
   if( [p->definitionTable objectForKey:identifier])
      parser_error( p, "\"%@\" is already defined", identifier);
   
   right             = expr->expression_;
   expr->expression_ = nil;
   
   [p->definitionTable setObject:right
                          forKey:identifier];
   
   [right release];
   [expr release];
   
   return( nil);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_macro( parser *p, NSUInteger line)
{
   MulleScionTemplate  *root;
   MulleScionFunction  *function;
   macro_type          last_type;
   MulleScionObject    *node;
   MulleScionMacro     *macro;
   NSString            *identifier;
   unsigned char       c;
   
   if( p->inMacro)
      parser_error( p, "no macro definitions in a macro definition.");
   
   parser_skip_whitespace( p);
   identifier = parser_do_identifier( p);
   
   parser_skip_whitespace( p);
   c = parser_peek_character( p);
   if( c != '(')
      parser_error( p, "'(' after identifier expected");

   function = [parser_do_function( p, identifier) autorelease];
   
   identifier = [(MulleScionVariableAssignment *) function identifier];
   if( [identifier hasPrefix:@"MulleScion"])
      parser_error( p, "you can't define MulleScion macros");
   
   if( [p->macroTable objectForKey:identifier])
      parser_error( p, "macro %@ is already defined", identifier);

   // complete macro command closing
   parser_finish_command( p);
   
   // now just grab stuff until we hit an endmacro
   
   root       = [[[MulleScionTemplate alloc] initWithFilename:p->fileName] autorelease];
   last_type  = eof;
   p->inMacro = YES;

   for( node = root; node; node = parser_next_object( p, node, &last_type));

   p->inMacro = NO;
   if( last_type != command)
      parser_error( p, "endmacro expected", identifier);
   
   
   macro = [MulleScionMacro newWithIdentifier:identifier
                                     function:function
                                         body:root
                                     fileName:p->fileName
                                   lineNumber:line];
   [p->macroTable setObject:macro
                     forKey:identifier];
   [macro autorelease];
   
   p->curr -= 2;  // dial back to undfinish endmacro command
   
   return( nil);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_verbatim( parser *p, NSUInteger line)
{
   parser_memo   plaintext_start;
   parser_memo   plaintext_end;
   NSString      *s;
   
   parser_finish_command( p);
   parser_memorize( p, &plaintext_start);

   if( ! parser_grab_text_until_command( p, "endverbatim"))
      parser_error( p, "no matching endverbatim found");

   parser_memorize( p, &plaintext_end);
   
   s = parser_get_memorized_retained_string( &plaintext_start, &plaintext_end);
   
   // completely forget about endverbatim
   parser_skip_text_until_scion_end( p, '%');
   p->curr -= 2;  // but dial back for verbatim to finish nicely
   if( ! s)
      return( nil);

   return( [MulleScionPlainText newWithRetainedString:s
                                           lineNumber:plaintext_start.lineNumber]);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_endmacro( parser *p, NSUInteger line)
{
   if( ! p->inMacro)
      parser_error( p, "stray endmacro detected");
   return( nil);
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_command( parser *p)
{
   NSString          *s;
   NSUInteger        line;
   unsigned char     c;
   MulleScionOpcode  op;
   
   line = p->lineNumber;
   c    = parser_peek_character( p);
   if( c == '[')
      return( parser_do_method_call( p, line));
   
   s    = parser_do_identifier( p);
   parser_skip_whitespace( p);
   
   op = parser_opcode_for_string( p, s);
   //if( p->inMacro && op != EndmacroOpcode)
   //   parser_error( p, "no commands in macros");
      
   switch( op)
   {
   case ImplicitSetOpcode : return( parser_do_implicit_set( p, s, line));

   case BlockOpcode    : return( parser_do_block( p, line));
   case DefineOpcode   : return( parser_do_define( p, line));
   case ElseOpcode     : return( [MulleScionElse newWithLineNumber:line]);
   case EndblockOpcode : return( [MulleScionEndBlock newWithLineNumber:line]);
   case EndfilterOpcode: return( [MulleScionEndFilter newWithLineNumber:line]);
   case EndforOpcode   : return( [MulleScionEndFor newWithLineNumber:line]);
   case EndifOpcode    : return( [MulleScionEndIf newWithLineNumber:line]);
   case EndmacroOpcode : return( parser_do_endmacro( p, line));
   case EndverbatimOpcode : parser_error( p, "stray endverbatim command");
   case EndwhileOpcode : return( [MulleScionEndWhile newWithLineNumber:line]);
   case ExtendsOpcode  : return( parser_do_extends( p));
   case FilterOpcode   : return( parser_do_filter( p, line));
   case ForOpcode      : return( parser_do_for( p, line));
   case IfOpcode       : return( parser_do_if( p, line));
   case IncludesOpcode : return( parser_do_includes( p, YES));
   case MacroOpcode    : return( parser_do_macro( p, line));
   case SetOpcode      : return( parser_do_set( p, line));
   case VerbatimOpcode : return( parser_do_verbatim( p, line));
   case WhileOpcode    : return( parser_do_while( p, line));
   }
   return( nil);  // for gcc
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_block_break_on_extends_skip_others( parser *p)
{
   NSString   *s;
   
   parser_skip_whitespace( p);
   s = parser_do_identifier( p);
   
   switch( parser_opcode_for_string( p, s))
   {
   case BlockOpcode :
      parser_do_whole_block_to_block_table( p);
      break;
         
   case ExtendsOpcode :
      return( parser_do_extends( p));
         
   default :
      break;
   }
   return( nil);
}


static MulleScionObject  * NS_RETURNS_RETAINED _parser_next_object_after_extend( parser *p, macro_type *last_type)
{
   macro_type         type;
   MulleScionObject   *obj;
   
   obj = nil;
retry:
   type = parser_grab_text_until_scion( p);
   parser_next_character( p);
   parser_next_character( p);
   
   *last_type = type;
   switch( type)
   {
   case eof :
      return( nil);
      
   case comment :
      parser_finish_comment( p);
      goto retry;
      
   case expression :
      parser_finish_expression( p);
      break;
      
   case command :
      obj = parser_do_block_break_on_extends_skip_others( p);
      break;
   }
   
   return( obj);
}


static MulleScionObject  *_parser_next_object( parser *p,  MulleScionObject *owner, macro_type *last_type)
{
   MulleScionObject    *next;
   parser_memo         plaintext_start;
   parser_memo         plaintext_end;
   NSString            *s;
   macro_type          type;

retry:
   next     = nil;
   p->first = nil;
   
   parser_memorize( p, &plaintext_start);
   type = parser_grab_text_until_scion( p);
   parser_memorize( p, &plaintext_end);
   parser_next_character( p);
   parser_next_character( p);
   
   if( type == comment || type == command)
      parser_adjust_memo_to_end_of_previous_line( p, &plaintext_end);
   
   s = parser_get_memorized_retained_string( &plaintext_start, &plaintext_end);
   if( s)
   {
      next     = [MulleScionPlainText newWithRetainedString:s
                                                 lineNumber:plaintext_start.lineNumber];
      p->first = next;
      owner    = [owner appendRetainedObject:next];
   }
   
   *last_type = type;
   
   switch( type)
   {
   case eof :
      return( nil);
      
   case comment :
      parser_finish_comment( p);
      goto retry;
      
   case expression :
      parser_skip_whitespace( p);
      next = parser_do_expression_or_macro( p);
      parser_finish_expression( p);
      break;
      
   case command :
      parser_skip_whitespace( p);
      next = parser_do_command( p);
      if( ! [next isTemplate])
         parser_finish_command( p);
      if( ! next && p->inMacro)
         return( nil);  // endmacro ...
      break;
   }
   
   //
   // the problem, is that the analyzer things with NS_CONSUMED that the
   // object is dead, while we know it's alive
   //
   if( next)
   {
      if( ! p->first)
         p->first = next;
   
      owner = [owner appendRetainedObject:next];  // analyzer mistake
   }
   return( owner);
}


- (void) parseData:(NSData *) data
    intoRootObject:(MulleScionObject *) root
          fileName:(NSString *) fileName
        blockTable:(NSMutableDictionary *) blockTable
   definitionTable:(NSMutableDictionary *) definitionTable
        macroTable:(NSMutableDictionary *) macroTable
   dependencyTable:(NSMutableDictionary *) dependencyTable
{
   MulleScionObject    *node;
   parser              parser;
   macro_type          last_type;

   parser_init( &parser, (void *) [data_ bytes], [data_ length]);
   parser_set_filename( &parser, fileName_);
   parser_set_error_callback( &parser, self, @selector( parserErrorInFileName:lineNumber:reason:));
   parser_set_blocks_table( &parser, blockTable);
   parser_set_definitions_table( &parser, definitionTable);
   parser_set_macro_table( &parser, macroTable);
   parser_set_dependency_table( &parser, dependencyTable);
   
   last_type = eof;
   for( node = root; node; node = parser_next_object( &parser, node, &last_type));
}


- (MulleScionTemplate *) templateParsedWithBlockTable:(NSMutableDictionary *) blockTable
                                      definitionTable:(NSMutableDictionary *) definitionsTable
                                           macroTable:(NSMutableDictionary *) macroTable
                                      dependencyTable:(NSMutableDictionary *) dependencyTable
{
   MulleScionTemplate  *root;
   
   root = [[[MulleScionTemplate alloc] initWithFilename:[fileName_ lastPathComponent]] autorelease];
   
   [self parseData:data_
    intoRootObject:root
          fileName:fileName_
        blockTable:blockTable
   definitionTable:definitionsTable
        macroTable:macroTable
   dependencyTable:dependencyTable];
   
   return( root);
}


- (MulleScionTemplate *) templateWithContentsOfFile:(NSString *) fileName
                                         blockTable:(NSMutableDictionary *) blockTable
                                    definitionTable:(NSMutableDictionary *) definitionTable
                                         macroTable:(NSMutableDictionary *) macroTable
                                    dependencyTable:(NSMutableDictionary *) dependencyTable
{
   MulleScionParser    *parser;
   MulleScionTemplate  *template;
   NSData              *data;
   NSString            *dir;
   NSString            *path;
   
retry:
   path = fileName;
   data = [NSData dataWithContentsOfFile:path];
   if( ! data)
   {
      dir  = [fileName_ stringByDeletingLastPathComponent];
      path = [dir stringByAppendingPathComponent:path];
      
      data = [NSData dataWithContentsOfFile:path];
      if( ! data)
      {
         if( ! [[fileName pathExtension] length])
         {
            fileName = [fileName stringByAppendingPathExtension:@"scion"];
            goto retry;
         }
         return( nil);
      }
   }
   
   parser   = [[[MulleScionParser alloc] initWithData:data
                                             fileName:path] autorelease];
   template = [parser templateParsedWithBlockTable:blockTable
                                   definitionTable:definitionTable
                                        macroTable:macroTable
                                   dependencyTable:dependencyTable];
   return( template);
}

@end
