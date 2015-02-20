//
//  MulleScionParser+Parsing.m
//  MulleScion
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
#import "MulleScionObjectModel+TraceDescription.h"
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
   comment    = 2,
   garbage    = 3
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
   parser_memo          memo_interesting;
   
   MulleScionObject     *first;

   void                 (*parser_do_error)( id self, SEL sel, void *parser, NSString *filename, NSUInteger line, NSString *message);
   id                   self;
   SEL                  sel;
   int                  skipComments;
   int                  inMacro;
   int                  wasMacroCall;
   unsigned int         environment;
   NSString             *fileName;
   MulleScionParserTables  tables;
   NSMutableArray       *converterStack;
} parser;


enum
{
   MULLESCION_VERBATIM_INCLUDE_HASHBANG = 0x01,
   MULLESCION_NO_HASHBANG               = 0x02,
   MULLESCION_DUMP_MACROS               = 0x04,
   MULLESCION_DUMP_COMMANDS             = 0x08,
   MULLESCION_DUMP_EXPRESSIONS          = 0x10
};

static void   parser_skip_after_newline( parser *p);

static void   parser_skip_initial_hashbang_line_if_present( parser *p)
{
   if( p->sentinel - p->buf < 4)
      return;

   assert( p->lineNumber == 1);
   if( memcmp( "#!", p->buf, 2))
      return;
   
   // so assume mulle-scion was started as unix shellscrip
   parser_skip_after_newline( p);
}


static void   parser_init( parser *p, unsigned char *buf, size_t len)
{
   memset( p, 0, sizeof( parser));
   if( buf && len)
   {
      p->buf        = p->curr = buf;
      p->sentinel   = &p->buf[ len];
      p->lineNumber = 1;
   }

   p->environment |= getenv( "MULLESCION_DUMP_MACROS") ? MULLESCION_DUMP_MACROS : 0;
   p->environment |= getenv( "MULLESCION_VERBATIM_INCLUDE_HASHBANG") ? MULLESCION_VERBATIM_INCLUDE_HASHBANG : 0;
   p->environment |= getenv( "MULLESCION_NO_HASHBANG") ? MULLESCION_NO_HASHBANG : 0;
   p->environment |= getenv( "MULLESCION_DUMP_COMMANDS") ? MULLESCION_DUMP_COMMANDS : 0;
   p->environment |= getenv( "MULLESCION_DUMP_EXPRESSIONS") ? MULLESCION_DUMP_EXPRESSIONS : 0;
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
   
   p->tables.blockTable = table;
}


static inline void   parser_set_definitions_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->tables.definitionTable = table;
}


static inline void   parser_set_dependency_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->tables.dependencyTable = table;
}


static inline void   parser_set_macro_table( parser *p, NSMutableDictionary *table)
{
   NSCParameterAssert( ! table || [table isKindOfClass:[NSMutableDictionary class]]);
   
   p->tables.macroTable = table;
}


static inline void   parser_set_filename( parser *p, NSString *s)
{
   p->fileName = s;
}

//
// there is no return, stuff just leaks and we abort
//
static void  MULLE_NO_RETURN  parser_error( parser *p, char *c_format, ...)
{
   NSString       *reason;
   NSString       *s;
   size_t         p_len;
   size_t         s_len;
   size_t         i;
   va_list        args;
   unsigned char  *prefix;
   unsigned char  *suffix;
   
   if( p->parser_do_error)
   {
      va_start( args, c_format);
      reason = [[[NSString alloc] initWithFormat:[NSString stringWithCString:c_format]
                                       arguments:args] autorelease];
      va_end( args);

      //
      // p->memo_scion.curr is about the start of the parsed object
      // p->curr is where the parsage failed, try to print something interesting
      // near the parse failure (totally heuristic), but not too much
      //
      p_len = p->curr - p->memo_interesting.curr;
      if( p_len > 32)
         p_len = 32;
      if( p_len < 12)
         p_len += 3;

      s_len  = p_len >= 6 ? 12 : 12 + 6 - p_len;
      prefix = &p->curr[ -p_len];
      suffix = &p->curr[ 1];

      if( prefix < p->buf)
      {
         prefix = p->buf;
         p_len  = p->curr - p->buf;
      }

      if( &suffix[ s_len] > p->sentinel)
         s_len  = p->sentinel - p->curr;
      
      // stop tail at linefeed
      for( i = 0; i < s_len; i++)
         if( suffix[ i] == '\r' || suffix[ i] == '\n' || suffix[ i] == ';' || suffix[ i] == '}' || suffix[ i] == '%')
            break;
      s_len = i;

      // terminal escape sequences
#if HAVE_TERMINAL
#define RED   "\033[01;31m"
#define NONE  "\033[00m"
#else
#define RED   ""
#define NONE  ""
#endif
      
      s = [NSString stringWithFormat:@"%.*s" RED "%c" NONE "%.*s", (int) p_len, prefix, *p->curr, (int) s_len, suffix];
      s = [s stringByReplacingOccurrencesOfString:@"\n"
                                       withString:@" "];
      s = [s stringByReplacingOccurrencesOfString:@"\r"
                                       withString:@""];
      s = [s stringByReplacingOccurrencesOfString:@"\t"
                                       withString:@" "];
      s = [s stringByReplacingOccurrencesOfString:@"\""
                                       withString:@"\\\""];
      s = [s stringByReplacingOccurrencesOfString:@"'"
                                       withString:@"\\'"];
      
      s = [NSString stringWithFormat:@"at '%c' near \"%@\", %@", *p->curr, s, reason];
   
      (*p->parser_do_error)( p->self, p->sel, p, p->fileName, p->memo.lineNumber, s);
   }
   abort();
}

   
static unsigned char    *unescaped_string_if_needed( unsigned char *s,
                                                     NSUInteger len,
                                                     NSUInteger *result_len)
{
   unsigned char   *memo;
   unsigned char   *unescaped;
   unsigned char   *src;
   unsigned char   *dst;
   unsigned char   *sentinel;
   unsigned char   c;
   int             escaped;
   size_t          copy_len;
   
   assert( s);
   assert( len);
   assert( result_len);
   
   unescaped = NULL;
   dst       = NULL;
   memo      = s;
   sentinel  = &s[ len];

   escaped   = 0;
   
   for( src = s; src < sentinel; src++)
   {
      c = *src;
      
      if( escaped)
      {
         escaped = 0;
         switch( c)
         {
            case 'a'  : c = '\a'; break;
            case 'b'  : c = '\b'; break;
            case 'f'  : c = '\f'; break;
            case 'n'  : c = '\n'; break;
            case 'r'  : c = '\r'; break;
            case 't'  : c = '\t'; break;
            case 'v'  : c = '\v'; break;
            case '\"' : c = '\"'; break;
            case '\'' : c = '\''; break;
            case '?'  : c = '?';  break;
            case '\\' : c = '\\'; break;
            
            // can't do numeric codes yet
         }
         *dst++ = c;
         continue;
      }
      
      if( c == '\\')
      {
         escaped = 1;
         if( ! unescaped)
         {
            unescaped = malloc( len);
            if( ! unescaped)
               [NSException raise:NSMallocException
                           format:@"can't allocate %ld bytes", (long) len];

            copy_len = (ptrdiff_t) (src - memo);
            memcpy( unescaped, memo, copy_len);
            dst = &unescaped[ copy_len];
         }
         continue;
      }
      
      if( dst)
         *dst++ = c;
   }
   
   assert( ! escaped);  // malformed, but so what ?
   
   *result_len = dst - unescaped;
   
   // maybe a little bit pedantic ?
   if( unescaped)
   {
      unescaped = realloc( unescaped, *result_len);
      if( ! unescaped)
         [NSException raise:NSMallocException
                     format:@"can't shrink down to %ld bytes", (long) *result_len];
   }
   
   return( unescaped);
}
   
# pragma mark -
# pragma mark Tokenizing 

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
// quotes or comments. To print {{ use {{ "{{" }}
//
static macro_type   parser_grab_text_until_scion( parser *p)
{
   unsigned char   c, d;
   int             inquote;
   
   assert( p->skipComments <= 0);

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


//
// assume whitespace and leading comments have been removed
//
static macro_type   parser_next_scion_end( parser *p)
{
   unsigned char   c, d;
   
   if( p->curr + 2 > p->sentinel)
      return( eof);
   
   d = *p->curr++;
   c = *p->curr++;
      
   if( c == '}')
      switch( d)
   {
      case '}' : return( expression);
      case '%' : return( command);
      case '#' : return( comment);
   }
   p->curr -= 2;
   return( garbage);
}


# pragma mark -
# pragma mark whitespace

static void   parser_skip_whitespace( parser *p)
{
   unsigned char   c;
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      switch( c)
      {
      case '\n' :
         parser_nl( p);
         break;
         
      case '#'  :
         if( p->skipComments > 0)
         {
            parser_skip_after_newline( p);
            --p->curr; // because we add it again in for
            break;
         }
         return;
         
      default :
         if( c > ' ')
            return;
      }
   }
}


static void   parser_skip_whitespace_and_comments_always( parser *p)
{
   unsigned char   c;
   
   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      switch( c)
      {
      case '\n' :
         parser_nl( p);
         break;
         
      case '#'  :
         parser_skip_after_newline( p);
         --p->curr; // because we add it again in for
         break;
         
      default :
         if( c > ' ')
            return;
      }
   }
}


static void   parser_skip_white_if_terminated_by_newline( parser *p)
{
   parser_memo   memo;
   unsigned char   c;
   
   assert( p->skipComments <= 0);

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


static void   parser_skip_after_newline( parser *p)
{
   unsigned char   c;
   
   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         break;
      }
   }
}


static void   parser_skip_white_until_after_newline( parser *p)
{
   unsigned char   c;
   
   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         break;
      }
      
      if( c > ' ')
      {
         p->curr--;
         break;
      }
   }
}


# pragma mark -
# pragma mark scion tags

static macro_type   parser_skip_text_until_scion_end( parser *p, int type)
{
   unsigned char   c;
   unsigned char   d;
   int             inquote;
   
   assert( p->skipComments <= 0);
   
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
      {
         if( d == type || type == 0xFF)
         {
            switch( d)
            {
               case '%' : return( command);
               case '#' : return( comment);
               case '}' : return( expression);
            }
         }
      }
   }
   return( eof);
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
         if( (size_t) stage == len)
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


static int   parser_grab_text_until_quote( parser *p)
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
         return( 1);
      }
   }
   return( 0);
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
   NSUInteger      length;
   NSUInteger      unescaped_length;
   NSString        *s;
   unsigned char   *unescaped;
   
   length = p->curr - p->memo.curr ;
   if( ! length)
      return( nil);
   
   unescaped = unescaped_string_if_needed( p->memo.curr, length, &unescaped_length);
   
   if( unescaped)
   {
      s = [[NSString alloc] initWithBytesNoCopy:unescaped
                                         length:unescaped_length
                                       encoding:NSUTF8StringEncoding
                                   freeWhenDone:YES];
      return( s);
   }
   
   
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


static unsigned char   parser_peek2_character( parser *p)
{
   return( p->curr + 1 < p->sentinel ? p->curr[ 1] : 0);
}


static inline unsigned char   parser_next_character( parser *p)
{
   unsigned char   c;
   
   if( p->curr >= p->sentinel)
      return( 0);

   c = *p->curr++;
   if( c == '\n')
      parser_nl( p);
   return( c);
}


// unused it seems
static void   parser_undo_character( parser *p)
{
   if( p->curr <= p->buf)
      parser_error( p, "internal buffer underflow");
   if( *--p->curr == '\n')
      p->lineNumber--;
}


static inline void  parser_skip_peeked_character( parser *p, char c)
{
   assert( p->curr < p->sentinel);
   assert( *p->curr == c);
   p->curr++;
}


static inline void   parser_peek_expected_character( parser *p, char expect, char *error)
{
   unsigned char   c;
   
   if( p->curr >= p->sentinel)
      parser_error( p, "end of file reached, %s", error);
   
   c = *p->curr;
   if( c != expect)
      parser_error( p, error);
   if( c == '\n')
      parser_nl( p);
}


static inline void   parser_next_expected_character( parser *p, char expect, char *error)
{
   parser_peek_expected_character( p, expect, error);
   p->curr++;
}


# pragma mark -
# pragma mark Simple Expressions

static NSString  *parser_do_key_path( parser *p)
{
   NSString   *s;
   
   parser_grab_text_until_key_path_end( p);
   s = parser_get_string( p);
   if( ! s)
      parser_error( p, "a key path was expected");
   parser_skip_whitespace( p);
   return( s);
}


static NSString  *parser_do_identifier( parser *p)
{
   NSString   *s;
   
   parser_grab_text_until_identifier_end( p);
   s = parser_get_string( p);
   if( ! s)
      parser_error( p, "an identifier was expected");
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
      parser_error( p, "a number was expected");
   parser_skip_whitespace( p);
   if( isFloat)
      return( [NSNumber numberWithDouble:[s doubleValue]]);
   return( [NSNumber numberWithLongLong:[s longLongValue]]);
}


static NSString  *parser_do_string( parser *p)
{
   NSString   *s;
   
   NSCParameterAssert( parser_peek_character( p) == '"');
   
   parser_skip_peeked_character( p, '\"');   // skip '"'
   if( ! parser_grab_text_until_quote( p))
      parser_error( p, "a closing '\"' was expected");

   s = parser_get_string( p);
   parser_skip_peeked_character( p, '\"');   // skip '"'
   parser_skip_whitespace( p);
   
   return( s ? s : @"");
}

# pragma mark -
# pragma mark Expressions

static MulleScionExpression * NS_RETURNS_RETAINED  parser_do_expression( parser *p);

static inline MulleScionExpression * NS_RETURNS_RETAINED  parser_do_unary_expression( parser *p);

static NSMutableDictionary  *parser_do_dictionary( parser *p)
{
   NSMutableDictionary    *dict;
   MulleScionExpression   *expr;
   MulleScionExpression   *keyExpr;
   unsigned char           c;
   
   NSCParameterAssert( parser_peek_character( p) == '{');
   parser_skip_peeked_character( p, '{');   // skip '"'
   
   dict = [NSMutableDictionary dictionary];
   expr  = nil;
   for(;;)
   {
      parser_skip_whitespace( p);
      c = parser_peek_character( p);
      if( c == '}')
      {
         parser_skip_peeked_character( p, '}');
         break;
      }
      
      if( c == ',')
      {
         if( ! expr)
            parser_error( p, "a lonely comma in an array was found");
         parser_skip_peeked_character( p, ',');
      }
      else
      {
         if( expr)
            parser_error( p, "a comma or closing curly brackets was expected");
      }
      
      expr = parser_do_expression( p);
      
      parser_skip_whitespace( p);
      c = parser_peek_character( p);
      if( c != ',')
         parser_error( p, "a comma and a key was expected");

      parser_skip_peeked_character( p, ',');
      keyExpr = parser_do_expression( p);
      if( ! [keyExpr isDictionaryKey])
         parser_error( p, "a number or string as a key was expected");
      [dict setObject:expr
               forKey:[keyExpr value]];
      [keyExpr release];
      [expr release];
   }
   return( dict);
}

   
static NSMutableArray   *parser_do_array_or_arguments( parser *p, int allow_arguments)
{
   NSMutableArray                   *array;
   MulleScionExpression             *expr;
   MulleScionIdentifierExpression   *key;
   unsigned char                    c;
   
   parser_skip_peeked_character( p, '(');

   array = [NSMutableArray array];
   expr  = nil;
   for(;;)
   {
      parser_skip_whitespace( p);
      c = parser_peek_character( p);
      if( c == ')')
      {
         parser_skip_peeked_character( p, ')');
         break;
      }
      
      if( c == '=' && allow_arguments)
      {
         MulleScionExpression   *value;
         
         if( ! expr)
            parser_error( p, "a lonely '=' without a key in an argument list was found");
         if( ! [expr isIdentifier])
            parser_error( p, "an identifier before '=' was expected");

         key  = (MulleScionIdentifierExpression *) [expr retain];
         [array removeLastObject];

         parser_skip_peeked_character( p, '=');
         value = parser_do_expression( p);
         if( ! value)
            parser_error( p, "a value after '=' was expected");
         
         expr  = [MulleScionParameterAssignment newWithIdentifier:[key identifier]
                                               retainedExpression:value
                                                       lineNumber:[key lineNumber]];
         [key release];
      }
      else
      {
         if( c == ',')
         {
            if( ! expr)
               parser_error( p, "a lonely comma in an array was found");
            parser_skip_peeked_character( p, ',');
         }
         else
         {
            if( expr)
               parser_error( p, "a comma or closing parenthesis was expected");
         }
         
         expr = parser_do_expression( p);
      }
      [array addObject:expr];
      [expr release];
   }
   return( array);
}


static NSMutableArray   *parser_do_array( parser *p)
{
   return( parser_do_array_or_arguments( p, NO));
}

          
static NSMutableArray   *parser_do_arguments( parser *p)
{
   return( parser_do_array_or_arguments( p, YES));
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
   
   parser_skip_peeked_character( p, '[');
   parser_skip_whitespace( p);
   
   line   = p->memo.lineNumber;
   target = parser_do_expression( p);
   
   hasColon = parser_grab_text_until_selector_end( p, YES);
   selName  = parser_get_string( p);
   if( ! selName)
      parser_error( p, "a selector was expected");
   
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
            [arguments addObject:expr];
            [expr release];
         
            parser_skip_whitespace( p);
            c = parser_peek_character( p);
            if( c != ',')
               break;

            parser_error( p, "sorry but varargs isn't in the cards yet");
            
            parser_skip_peeked_character( p, ',');
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
   parser_next_expected_character( p, ']', "a closing ']' was expected");
   
   return( [MulleScionMethod newWithRetainedTarget:target
                                        methodName:selName
                                         arguments:arguments
                                        lineNumber:line]);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_expand_macro_with_arguments( parser *p,
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
   obj = [body behead];
   // the tricky thing is, that 'obj' is now not autoreleased anymore
   // while body is
   [pool release];

   return( obj);
}


static MulleScionFunction  * NS_RETURNS_RETAINED _parser_do_function( parser *p, NSString *identifier, NSArray *arguments)
{
   MulleScionMacro   *macro;
   
   macro = [p->tables.macroTable objectForKey:identifier];
   if( macro)
      parser_error( p, "referencing a macro in an expression is not allowed");
   
   if( p->environment & MULLESCION_DUMP_MACROS)
      fprintf( stderr, "referencing function \"%s\"\n", [identifier cString]);
   
   return( [MulleScionFunction newWithIdentifier:identifier
                                       arguments:arguments
                                      lineNumber:p->memo.lineNumber]);
}


static MulleScionObject  * NS_RETURNS_RETAINED parser_do_function_or_macro( parser *p, NSString *identifier)
{
   NSArray           *arguments;
   MulleScionMacro   *macro;
   
   NSCParameterAssert( parser_peek_character( p) == '(');
   
   arguments       = parser_do_arguments( p);
   macro           = [p->tables.macroTable objectForKey:identifier];
   p->wasMacroCall = macro != nil;
   if( p->wasMacroCall)
      return( parser_expand_macro_with_arguments( p, macro, arguments, p->memo.lineNumber));

   return( _parser_do_function( p, identifier, arguments));
}


static MulleScionFunction  * NS_RETURNS_RETAINED parser_do_function( parser *p, NSString *identifier)
{
   NSArray   *arguments;
   
   arguments = parser_do_arguments( p);
   return( _parser_do_function( p, identifier, arguments));
}



static MulleScionFunction  * NS_RETURNS_RETAINED __parser_do_macro( parser *p, NSString *identifier)
{
   NSArray   *arguments;
   
   arguments = parser_do_arguments( p);
   return( [MulleScionFunction newWithIdentifier:identifier
                                       arguments:arguments
                                      lineNumber:p->memo.lineNumber]);
}


//static MulleScionParameterAssignment  * NS_RETURNS_RETAINED parser_do_assignment( parser *p, NSString *identifier)
//{
//   MulleScionExpression  *expr;
//   
//   NSCParameterAssert( parser_peek_character( p) == '=');
//   parser_next_character( p);
//   parser_skip_whitespace( p);
//   
//   expr = parser_do_expression( p);
//   return( [MulleScionParameterAssignment newWithIdentifier:identifier
//                                       retainedExpression:expr
//                                               lineNumber:p->memo.lineNumber]);
//}


static MulleScionIndexing  * NS_RETURNS_RETAINED parser_do_indexing( parser *p,
                                                                     MulleScionExpression * NS_CONSUMED left,
                                                                     MulleScionExpression * NS_CONSUMED right)
{
   parser_skip_whitespace( p);
   parser_next_expected_character( p, ']', "a closing ']' was expected");
   
   return( [MulleScionIndexing newWithRetainedLeftExpression:left
                                     retainedRightExpression:right
                                                  lineNumber:p->memo.lineNumber]);
}


static MulleScionConditional  * NS_RETURNS_RETAINED parser_do_conditional( parser *p,
                                                                           MulleScionExpression * NS_CONSUMED left,
                                                                           MulleScionExpression * NS_CONSUMED middle)
{
   MulleScionExpression   *right;
   
   parser_skip_whitespace( p);
   parser_next_expected_character( p, ':', "a conditional ':' was expected");

   right = parser_do_expression( p);
   return( [MulleScionConditional newWithRetainedLeftExpression:left
                                       retainedMiddleExpression:middle
                                        retainedRightExpression:right
                                                     lineNumber:p->memo.lineNumber]);
}


static MulleScionLog  * NS_RETURNS_RETAINED parser_do_log( parser *p, NSUInteger line)
{
   MulleScionExpression  *expr;
   
   parser_skip_whitespace( p);
   
   expr = parser_do_unary_expression( p);
   return( [MulleScionLog newWithRetainedExpression:expr
                                         lineNumber:line]);
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
   
   parser_skip_peeked_character( p, '(');

   expr = parser_do_expression( p);
   
   parser_skip_whitespace( p);
   parser_next_expected_character( p, ')', "a closing ')' was expected. (Hint: prefix arrays with @)");
   
   return( expr);
}


static MulleScionSelector * NS_RETURNS_RETAINED  parser_do_selector(  parser *p)
{
   NSString   *selectorName;
   
   parser_skip_whitespace( p);

   parser_next_expected_character( p, '(', "a '(' after the selector keyword was expected");
   parser_skip_whitespace( p);

   parser_grab_text_until_selector_end( p, NO);
   selectorName  = parser_get_string( p);
   if( ! [selectorName length])
      parser_error(p, "a selector name was expected");
   
   parser_skip_whitespace( p);
   parser_next_expected_character( p, ')', "a closing ')' after the selector name was expected");

   return( [MulleScionSelector newWithString:selectorName
                                  lineNumber:p->memo.lineNumber]);
}


//case '=' : parser_next_character( p);
//c = parser_peek_character( p);
//parser_undo_character( p);
//if( c == '=')
//break;
//return( parser_do_assignment( p, s));
static MulleScionObject * NS_RETURNS_RETAINED  parser_do_unary_expression_or_macro( parser *p, int allowMacroCall)
{
   NSString              *s;
   unsigned char         c;
   MulleScionExpression  *expr;
   int                   hasAt;
   
   parser_skip_whitespace( p);

   c     = parser_peek_character( p);
   hasAt = (c == '@');
   if( hasAt)  // skip adorning '@'s
   {
      parser_skip_peeked_character( p, '@');
      c = parser_peek_character( p);
   }
   
   switch( c)
   {
   case '!' : parser_skip_peeked_character( p, '!');
              return( parser_do_not( p));
   case '"' : return( [MulleScionString newWithString:parser_do_string( p)
                                           lineNumber:p->memo.lineNumber]);
   case '0' : case '1' : case '2' : case '3' : case '4' :
   case '5' : case '6' : case '7' : case '8' : case '9' :
   case '+' : case '-' : case '.' :  // valid starts of FP nrs
      return( [MulleScionNumber newWithNumber:parser_do_number( p)
                                   lineNumber:p->memo.lineNumber]);
   case '{' :  if( hasAt)
                  return( [MulleScionDictionary newWithDictionary:parser_do_dictionary( p)
                                                       lineNumber:p->memo.lineNumber]);
               break;
   case '(' :  if( hasAt)
                  return( [MulleScionArray newWithArray:parser_do_array( p)
                                             lineNumber:p->memo.lineNumber]);
                return( parser_do_parenthesized_expression( p));
   case '[' : return( parser_do_method( p));
   }
   
   // this laymes
   s = parser_do_key_path( p);
   while( [s hasPrefix:@"self."])
      s = [s substringFromIndex:5];
   
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
   case '(' : if( allowMacroCall)
                 return( parser_do_function_or_macro( p, s));
              return( parser_do_function( p, s));
   default  : break;
   }

   expr = [p->tables.definitionTable objectForKey:s];
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
      parser_skip_peeked_character( p, '=');
   
   switch( d)
   {
   case '<' : return( flag ? MulleScionLessThanOrEqualTo : MulleScionLessThan);
   case '>' : return( flag ? MulleScionGreaterThanOrEqualTo : MulleScionGreaterThan);
   case '!' : if( ! flag) break; return( MulleScionNotEqual);
   }

   parser_error( p, "an unexpected character %c was found", d);
}


static MulleScionComparisonOperator  parser_check_equal_or_set_op( parser *p, char c)
{
   c = parser_peek2_character( p);
   if( c != '=')
      return( MulleScionNoComparison);
   
   parser_skip_peeked_character( p, '=');
   parser_skip_peeked_character( p, '=');
   return( MulleScionEqual);
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
                 parser_skip_peeked_character( p, '|');
              break;
   case 'a' : if( ! parser_next_matching_string( p, "and", 3))
                 return( left);
              break;
   case 'o' : if( ! parser_next_matching_string( p, "or", 2))
                 return( left);
              break;
   case '<' :
   case '>' :
   case '!' : operator = parser_check_comparison_op( p, operator);
              break;
         
   case '=' : operator = parser_check_equal_or_set_op( p, operator);
              if( operator == MulleScionNoComparison)
                 return( left);
              break;
   case '?' :
   case '.' : // the irony, that I have to support "modern" ObjC to do C :)
              parser_skip_peeked_character( p, operator);
              break;
         // this is problematic, because it could also be the start of a
         // unrelated method call... so lets request a new line between
   case '[' :
              if( p->lineNumber != [left lineNumber])
                 return( left);
              parser_skip_peeked_character( p, operator);
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
         left = parser_do_indexing( p, left, right);
         return( _parser_do_expression( p, left));

   case '?' :
      return( parser_do_conditional( p, left, right));
         
   case '|' :
      if( ! [right isMethod] && ! [right isPipe] && ! [right isIdentifier])
         parser_error( p, "an identifier was expected after '|'");
      return( [MulleScionPipe newWithRetainedLeftExpression:left
                                    retainedRightExpression:right
                                                 lineNumber:p->memo.lineNumber]);
   case '.' :
      if( ! [right isMethod] && ! [right isPipe] && ! [right isDot] && ! [right isIdentifier])
         parser_error( p, "an identifier was expected after '.'");
      return( [MulleScionDot newWithRetainedLeftExpression:left
                                   retainedRightExpression:right
                                                lineNumber:p->memo.lineNumber]);
   }
   return( nil);  // can't happen
}

// this is the path to arithmetic expression also, but DO NOT WANT right now
//
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


static char  *_macro_type_names[] =
{
   "end of file",
   "}}",
   "%}",
   "#}",
   "garbage"
};

static char  **macro_type_names = &_macro_type_names[ 1];


static void   parser_error_different_closer( parser *p, macro_type found, macro_type expected)
{
   assert( found >= -1 && found <= 3);
   assert( expected >= -1 && expected <= 3);
   
   if( found == garbage)
      parser_error( p, "a '%s' was expected",
               macro_type_names[ expected]);
   else
      parser_error( p, "a '%s' was expected, but '%s' was found",
               macro_type_names[ expected],
               macro_type_names[ found]);
}


static inline void   parser_error_if_different_closer( parser *p, macro_type found, macro_type expected)
{
   if( found != expected)
      parser_error_different_closer( p, found, expected);
}


static void   parser_finish_comment( parser *p)
{
   macro_type  end_type;
   
   end_type = parser_skip_text_until_scion_end( p, '#');
   parser_skip_white_if_terminated_by_newline( p);
   parser_error_if_different_closer( p, end_type, comment);
}


static void   parser_finish_expression( parser *p)
{
   macro_type  end_type;
   
   parser_skip_whitespace_and_comments_always( p);
   end_type = parser_next_scion_end( p);
   parser_error_if_different_closer( p, end_type, expression);
}


static void   parser_finish_command( parser *p)
{
   macro_type  end_type;
   
   parser_skip_whitespace_and_comments_always( p);
   end_type = parser_next_scion_end( p);
   parser_skip_white_until_after_newline( p);

   parser_error_if_different_closer( p, end_type, command);
}


typedef enum
{
   ImplicitSetOpcode = 0,  // still used ??

   BlockOpcode,
   DefineOpcode,
   ElseOpcode,
   ElseforOpcode,
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
   LogOpcode,
   MacroOpcode,
   RequiresOpcode,
   SetOpcode,
   VerbatimOpcode,
   WhileOpcode,
} MulleScionOpcode;


static char   *mnemonics[] =
{
   "set",
   
   "block",
   "define",
   "else",
   "elsefor",
   "endblock",
   "endfilter",
   "endfor",
   "endif",
   "endverbatim"
   "endwhile",
   "extends",
   "filter",
   "for",
   "if",
   "includes",
   "log",
   "macro",
   "requires",
   "set",
   "verbatim",
   "while"
};

// LAYME!!
static int   _parser_opcode_for_string( parser *p, NSString *s)
{
   NSUInteger  len;
   
   len = [s length];
   switch( len)
   {
   case 2 : if( [s isEqualToString:@"if"]) return( IfOpcode); break;
   case 3 : if( [s isEqualToString:@"for"]) return( ForOpcode);
            if( [s isEqualToString:@"set"]) return( SetOpcode);
            if( [s isEqualToString:@"log"]) return( LogOpcode); break;
   case 4 : if( [s isEqualToString:@"else"]) return( ElseOpcode); break;
   case 5 : if( [s isEqualToString:@"endif"]) return( EndifOpcode);
            if( [s isEqualToString:@"while"]) return( WhileOpcode);
            if( [s isEqualToString:@"block"]) return( BlockOpcode);
            if( [s isEqualToString:@"macro"]) return( MacroOpcode); break;
   case 6 : if( [s isEqualToString:@"define"]) return( DefineOpcode);
            if( [s isEqualToString:@"endfor"]) return( EndforOpcode);
            if( [s isEqualToString:@"filter"]) return( FilterOpcode); break;
   case 7 : if( [s isEqualToString:@"extends"]) return( ExtendsOpcode);
            if( [s isEqualToString:@"elsefor"]) return( ElseforOpcode); break;
   case 8 : if( [s isEqualToString:@"endblock"]) return( EndblockOpcode);
            if( [s isEqualToString:@"endwhile"]) return( EndwhileOpcode);
            if( [s isEqualToString:@"endmacro"]) return( EndmacroOpcode);
            if( [s isEqualToString:@"includes"]) return( IncludesOpcode);
            if( [s isEqualToString:@"requires"]) return( RequiresOpcode);
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
      for( i = 0; i < (int) (sizeof( mnemonics) / sizeof( char *)); i++)
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
      parser_error( p, "an identifier was expected");
   parser_finish_command( p);
   
   block = [MulleScionBlock newWithIdentifier:identifier
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
      parser_error( p, "an endblock was expected");
   
   [p->tables.blockTable setObject:block
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
      parser_error( p, "an identifier was expected");
   
   return( [MulleScionBlock newWithIdentifier:identifier
                                     fileName:p->fileName
                                   lineNumber:line]);
}


static void  parser_add_dependency( parser *p, NSString *fileName, NSString *include)
{
   NSMutableSet  *set;
   
   if( ! p->tables.dependencyTable)
      return;
   
   set = [p->tables.dependencyTable objectForKey:fileName];
   if( ! set)
   {
      set = [NSMutableSet new];
      [p->tables.dependencyTable setObject:set
                             forKey:fileName];
      [set release];
   }
   [set addObject:include];
}


static NSString  * NS_RETURNS_RETAINED parser_remove_hashbang_from_string_if_desired( NSString NS_CONSUMED *s)
{
   NSRange   range;
   NSString  *memo;
   
   if( ! [s hasPrefix:@"#!"])
      return( s);
   
   range = [s rangeOfString:@"\n"];
   if( ! range.length)
      return( @"");
   
   memo = s;
   s    = [[s substringFromIndex:range.location + 1] retain];
   [memo release];
   return( s);
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_requires( parser *p, NSUInteger line)
{
   NSString               *identifier;
   
   parser_skip_whitespace( p);
   
   identifier = parser_do_string( p);
   if( ! [identifier length])
      parser_error( p, "a bundle identifier was expected as a quoted string");
   
   return( [MulleScionRequires newWithIdentifier:identifier
                                      lineNumber:line]);
}

/*
 * How Extends works.
 * when you read a file, the parser collects statement for the template.
 * when it finds the keyword "extends" it stops collecting for the the template
 * and builds up the blockTable, all other stuff is discarded. This works
 * recursively.
 */
static MulleScionObject * NS_RETURNS_RETAINED  _parser_do_includes( parser *p, BOOL allowConverter)
{
   MulleScionTemplate     *inferior;
   MulleScionTemplate     *marker;
   NSString               *fileName;
   BOOL                   verbatim;
   NSString               *converter;
   SEL                    sel;
   NSString               *s;
   
   if( p->inMacro)
      parser_error( p, "no including or extending in macro");
   
   verbatim = NO;
   sel      = 0;
   
retry:
   parser_skip_whitespace( p);
   if( parser_peek_character( p) != '"')
   {
      if( ! allowConverter)
         parser_error( p, "a filename was expected as a quoted string");
      
      converter = parser_do_identifier( p);
      if( [converter isEqualToString:@"verbatim"])
      {
         verbatim  = YES;
         converter = nil;
         goto retry;
      }

      //
      // markdown -> markdownedData or some other variety
      // (rarely useful)
      sel = NSSelectorFromString( converter);
      if( ! [NSData instancesRespondToSelector:sel])
         parser_error( p, "converter method \"%s\" not found on NSData", [converter cString]);
   }
   
   fileName = parser_do_string( p);
   if( ! [fileName length])
      parser_error( p, "a filename was expected as a quoted string");
   
   if( verbatim)
   {
      s = [[NSString alloc] initWithContentsOfFile:fileName];
      if( ! s)
         parser_error( p, "could not load include file \"%@\"", fileName);
      
      if( ! (p->environment & MULLESCION_VERBATIM_INCLUDE_HASHBANG) &&
          ! (p->environment & MULLESCION_NO_HASHBANG))
      {
         s = parser_remove_hashbang_from_string_if_desired( s);
      }
      return( [MulleScionPlainText newWithRetainedString:s
                                              lineNumber:p->memo.lineNumber]);
   }

   parser_finish_command( p);

NS_DURING
   inferior = [p->self templateWithContentsOfFile:fileName
                                           tables:&p->tables
                                        converter:sel];
NS_HANDLER
   parser_error( p, "\n%@", [localException reason]);
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


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_includes( parser *p, BOOL allowVerbatim)
{
   MulleScionObject   *obj;
   int                memo;
   
   memo            = p->skipComments;
   p->skipComments = 0;
   obj             = _parser_do_includes( p, allowVerbatim);
   p->skipComments = memo;

   return( obj);
}


static MulleScionTemplate * NS_RETURNS_RETAINED  _parser_do_extends( parser *p)
{
   MulleScionTemplate    *inferior;
   macro_type            last_type;
   MulleScionObject      *obj;
   
   inferior  = (MulleScionTemplate *) _parser_do_includes( p, NO);
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


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_extends( parser *p)
{
   MulleScionObject   *obj;
   int                memo;
   
   memo            = p->skipComments;
   p->skipComments = 0;
   obj             = _parser_do_extends( p);
   p->skipComments = memo;

   return( obj);
}


#if 0
static MulleScionFunctionCall  * NS_RETURNS_RETAINED  parser_do_function_call( parser *p, NSString *identifier)
{
   MulleScionExpression  *expr;
   
   expr = parser_do_function( p, identifier);
   return( [MulleScionFunctionCall newWithRetainedExpression:expr
                                                  lineNumber:p->memo.lineNumber]);
}
#endif


static MulleScionMethodCall  *NS_RETURNS_RETAINED parser_do_method_call( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   expr = parser_do_method( p);
   return( [MulleScionMethodCall newWithRetainedExpression:expr
                                                lineNumber:line]);
}


typedef struct
{
   MulleScionExpression   *lexpr;
   MulleScionExpression   *expr;
   char                   *separator;
   int                    allow_expr_only;
} assignment_or_expr_info;


static void  init_assignment_or_expr_info( assignment_or_expr_info *p, char *separator, int allow_expr_only)
{
   p->lexpr           = nil;
   p->expr            = nil;
   p->separator       = separator;
   p->allow_expr_only = allow_expr_only;
}


static int   _parser_do_assignment_or_expr( parser *p, assignment_or_expr_info *info,  NSUInteger line)
{
   parser_memo     memo;
   unsigned char   *s;
   
   NSCParameterAssert( info->expr && ! info->lexpr);
   
   parser_memorize( p, &memo);
   for( s = (unsigned char *) info->separator; *s; s++)
      if( *s != parser_next_character( p))
      {
         if( info->allow_expr_only)
         {
            parser_recall( p, &memo);
            return( NO);
         }
         parser_error( p, "\'%s\' expected", info->separator);
      }
   
   if( ! [info->expr isLexpr])
      parser_error( p, "left side not an assignable expression");
   
   info->lexpr = info->expr;
   parser_skip_whitespace( p);
   info->expr = parser_do_expression( p);
   
   return( YES);
}


static int   parser_do_assignment_or_expr( parser *p, assignment_or_expr_info *info, NSUInteger line)
{
   info->expr = parser_do_expression( p);
   return( _parser_do_assignment_or_expr( p, info, line));
}


static MulleScionSet  * NS_RETURNS_RETAINED parser_do_set( parser *p, NSUInteger line)
{
   assignment_or_expr_info   info;
   
   init_assignment_or_expr_info( &info, "=", NO);
   parser_do_assignment_or_expr( p, &info, line);
   return( [MulleScionSet newWithRetainedLeftExpression:info.lexpr
                                retainedRightExpression:info.expr
                                         lineNumber:line]);
}


static MulleScionObject  * NS_RETURNS_RETAINED parser_do_implicit_set( parser *p, MulleScionExpression * NS_CONSUMED lexpr, NSUInteger line)
{
   MulleScionExpression  *expr;
   unsigned char         c;
   char                  *suggestion;
   NSString              *identifier;
   
   NSCParameterAssert( [lexpr isFunction] || [lexpr isIndexing] || [lexpr isIdentifier]);
   
   c = parser_peek_character( p);
   if( c != '=')
   {
      if( [lexpr isIdentifier])
      {
         identifier = [(MulleScionVariable *)  lexpr identifier];
         suggestion = parser_best_match_for_string( p, identifier);
         if( suggestion)
            parser_error( p, "unknown keyword \"%@\" (did you mean \"%s\" ?)", identifier, suggestion);
      }
      parser_error( p, "unknown keyword (maybe you forgot the keyword \"set\" ?)");
   }
   
   parser_skip_peeked_character( p, '=');
   parser_skip_whitespace( p);
   expr = parser_do_expression( p);
   
   return( [MulleScionSet newWithRetainedLeftExpression:lexpr
                                retainedRightExpression:expr
                                             lineNumber:line]);
}


static MulleScionFor  * NS_RETURNS_RETAINED parser_do_for( parser *p, NSUInteger line)
{
   assignment_or_expr_info   info;
   
   init_assignment_or_expr_info( &info, "in", NO);
   parser_do_assignment_or_expr( p, &info, line);
   return( [MulleScionFor newWithRetainedLeftExpression:info.lexpr
                                retainedRightExpression:info.expr
                                             lineNumber:line]);
}


static MulleScionIf  * NS_RETURNS_RETAINED parser_do_if( parser *p, NSUInteger line)
{
   assignment_or_expr_info   info;
   MulleScionExpression      *expr;
   int                       is_assignment;

   init_assignment_or_expr_info( &info, "=", YES);
   is_assignment =  parser_do_assignment_or_expr( p, &info, line);

   expr = info.expr;
   if( is_assignment)
   {
      expr = [MulleScionAssignmentExpression newWithRetainedLeftExpression:info.lexpr
                                                   retainedRightExpression:info.expr
                                                                lineNumber:line];
   }
   
   return( [MulleScionIf newWithRetainedExpression:expr
                                     lineNumber:line]);
}


// while expr || while lexpr = expr
static MulleScionWhile  * NS_RETURNS_RETAINED parser_do_while( parser *p, NSUInteger line)
{
   assignment_or_expr_info   info;
   MulleScionExpression      *expr;
   int                       is_assignment;
   
   init_assignment_or_expr_info( &info, "=", YES);
   is_assignment =  parser_do_assignment_or_expr( p, &info, line);
   
   expr = info.expr;
   if( is_assignment)
   {
      expr = [MulleScionAssignmentExpression newWithRetainedLeftExpression:info.lexpr
                                                   retainedRightExpression:info.expr
                                                                lineNumber:line];
   }
   
   return( [MulleScionWhile newWithRetainedExpression:expr
                                           lineNumber:line]);
}


static MulleScionFilter  * NS_RETURNS_RETAINED parser_do_filter( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   NSMutableArray         *array;
   NSEnumerator           *rover;
   NSString               *keyword;
   NSUInteger             flags;
   MulleScionVariable     *var;
   
   expr = parser_do_expression( p);
   if( ! [expr isIdentifier] && ! [expr isPipe]  && ! [expr isMethod])
      parser_error( p, "identifier or pipe expected");
   
   flags = FilterOutput|FilterPlaintext;

   parser_skip_whitespace( p);
   if( parser_peek_character( p) == ',')
   {
      parser_next_character( p);
      parser_skip_whitespace( p);
      parser_peek_expected_character( p, '(', "array expected after filter declaration");
      
      // array ? -- allow plaintext and output as keywords
      flags = 0;
      array = parser_do_array_or_arguments( p, NO);
      rover = [array objectEnumerator];
      while( var = [rover nextObject])
      {
         if( [var isIdentifier])
         {
            keyword = [var identifier];
            if( [keyword isEqual:@"plaintext"])
            {
               flags |= FilterPlaintext;  // plaintext ok
               continue;
            }
            if( [keyword isEqual:@"output"])
            {
               flags |= FilterOutput;
               continue;
            }
         }
         parser_error( p, "only plaintext or output are valid");
      }
   }

   if( ! flags)
      parser_error( p, "nothing left to filter");
   
   return( [MulleScionFilter newWithRetainedExpression:expr
                                                 flags:flags
                                            lineNumber:line]);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_define( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   NSString               *identifier;
   
   identifier = parser_do_identifier( p);
   if( ! identifier)
      parser_error( p, "an identifier after define was expected");
   
   if( [identifier hasPrefix:@"MulleScion"] || [identifier hasPrefix:@"__"])
      parser_error( p, "you can't define internal constants");

   if( parser_opcode_for_string( p, identifier))
      parser_error( p, "you can't override existing commands");
   
   if( [p->tables.definitionTable objectForKey:identifier])
      parser_error( p, "\"%@\" is already defined", identifier);
   
   parser_skip_whitespace( p);
   parser_next_expected_character( p, '=', "a '=' was expected after the identifier");
   
   expr = parser_do_expression( p);
   
   [p->tables.definitionTable setObject:expr
                          forKey:identifier];
   [expr release];
   
   return( nil);
}


static MulleScionObject  * NS_RETURNS_RETAINED   _parser_do_macro( parser *p, NSUInteger line)
{
   MulleScionTemplate  *root;
   MulleScionFunction  *function;
   macro_type          last_type;
   MulleScionObject    *node;
   MulleScionObject    *last;
   MulleScionMacro     *macro;
   NSString            *identifier;
   
   if( p->inMacro)
      parser_error( p, "no macro definitions in a macro definition.");
   
   parser_skip_whitespace( p);
   identifier = parser_do_identifier( p);
   
   parser_skip_whitespace( p);
   parser_peek_expected_character( p, '(', "'(' after identifier expected");

   function = [__parser_do_macro( p, identifier) autorelease];
   
   identifier = [(MulleScionParameterAssignment *) function identifier];
   if( [identifier hasPrefix:@"MulleScion"])
      parser_error( p, "you can't define MulleScion macros");
   
   if( [p->tables.macroTable objectForKey:identifier])
      parser_error( p, "macro %@ is already defined", identifier);

   // macro %} must be a terminated by %}\n
   parser_finish_command( p);
   
   // do this once and store in parser
   if( p->environment & MULLESCION_DUMP_MACROS)
      fprintf( stderr, "defining macro \"%s\"\n", [identifier cString]);
   
   // now just grab stuff until we hit an endmacro
   
   root       = [[[MulleScionTemplate alloc] initWithFilename:p->fileName] autorelease];
   last_type  = eof;
   p->inMacro = YES;

   last = nil;
   node = root;
   while( node)
   {
      last = node;
      node = parser_next_object( p, node, &last_type);
   }

   p->inMacro = NO;
   if( last_type != command)
      parser_error( p, "endmacro expected", identifier);
   
   //
   // take out single trailing linefeed from macro, which is just ugly
   //
   if( last)
   {
      while( last->next_)
         last = last->next_;
   
      if( [last isJustALinefeed])
      {
         for( node = root; node->next_ != last; node = node->next_);
         
         node->next_ = nil;
         [last release];
      }
   }
   
   macro = [MulleScionMacro newWithIdentifier:identifier
                                     function:function
                                         body:root
                                     fileName:p->fileName
                                   lineNumber:line];
   [p->tables.macroTable setObject:macro
                     forKey:identifier];
   [macro autorelease];

#if 0
   parser_undo_character( p);
   if( parser_peek_character( p) == '\n')
      parser_undo_character( p);
   parser_undo_character( p);
#endif

   return( macro);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_macro( parser *p, NSUInteger line)
{
   MulleScionObject   *obj;
   int                memo;
   
   memo            = p->skipComments;
   p->skipComments = 0;
   obj             = _parser_do_macro( p, line);
   p->skipComments = memo;
   return( obj);
}


static MulleScionObject  * NS_RETURNS_RETAINED   _parser_do_verbatim( parser *p, NSUInteger line)
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
   
   parser_undo_character( p);
   parser_undo_character( p);

   if( ! s)
      return( nil);

   return( [MulleScionPlainText newWithRetainedString:s
                                           lineNumber:plaintext_start.lineNumber]);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_verbatim( parser *p, NSUInteger line)
{
   MulleScionObject   *obj;
   int                memo;
   
   memo            = p->skipComments;
   p->skipComments = 0;
   obj             = _parser_do_verbatim( p, line);
   p->skipComments = memo;
   return( obj);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_endmacro( parser *p, NSUInteger line)
{
   if( ! p->inMacro)
      parser_error( p, "stray endmacro detected");
   return( nil);
}


static MulleScionObject  * NS_RETURNS_RETAINED   parser_do_print( parser *p, NSUInteger line)
{
   MulleScionExpression   *expr;
   
   parser_skip_peeked_character( p, '{');
   expr = parser_do_expression( p);
   
   parser_skip_whitespace( p);
   parser_next_expected_character( p, '}', "closing }} expected");
   parser_next_expected_character( p, '}', "closing }} expected");
   
   if( p->environment & MULLESCION_DUMP_EXPRESSIONS)
      fprintf( stderr, "%s\n", [[expr dumpDescription] cString]);
   return( expr);
}



static MulleScionObject * NS_RETURNS_RETAINED  parser_do_command( parser *p)
{
   NSUInteger             line;
   unsigned char          c;
   MulleScionOpcode       op;
   MulleScionExpression   *expr;
   NSString               *identifier;

   line = p->lineNumber;
   
   parser_grab_text_until_identifier_end( p);
   identifier = parser_get_string( p);
   parser_skip_whitespace( p);
   
   if( identifier)
   {
      op = parser_opcode_for_string( p, identifier);

   //if( p->inMacro && op != EndmacroOpcode)
   //   parser_error( p, "no commands in macros");
      
      switch( op)
      {
         case BlockOpcode    : return( parser_do_block( p, line));
         case DefineOpcode   : return( parser_do_define( p, line));
         case ElseOpcode     : return( [MulleScionElse newWithLineNumber:line]);
         case ElseforOpcode  : return( [MulleScionElseFor newWithLineNumber:line]);
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
         case LogOpcode      : return( parser_do_log( p, line));
         case MacroOpcode    : return( parser_do_macro( p, line));
         case RequiresOpcode : return( parser_do_requires( p, line));
         case SetOpcode      : return( parser_do_set( p, line));
         case VerbatimOpcode : return( parser_do_verbatim( p, line));
         case WhileOpcode    : return( parser_do_while( p, line));
      }
   
      //
      // otherwise an implicit set or macro call
      // dial back and parse expression properly, somewhat wasted effort...
      //
      parser_recall( p, &p->memo);
      expr = (MulleScionIdentifierExpression *) parser_do_expression_or_macro( p);
      if( expr)
      {
         if( p->wasMacroCall)
         {
            p->wasMacroCall = NO;  // reset now
            return( expr);
         }
         //if( [expr isFunction])  // not that great an idea, produces surprising
         //   return( expr);       // output as a side effect
         return( parser_do_implicit_set( p, expr, line));
      }
      return( nil);
   }
   
   c  = parser_peek_character( p);
   if( c == '[')
      return( parser_do_method_call( p, line));
   
   // handle inline print commands
   if( c == '{')
   {
      parser_skip_peeked_character( p, '{');
      c  = parser_peek_character( p);
      
      if( c == '{')
         return( parser_do_print( p, line));

      parser_error( p, "a lonely '{' was found, when a command was expected");
   }
   
      // hmmm....
   parser_error( p, "an unexpected character '%c' at the beginning of a command was found", c);
   return( nil);
}


//
// one or more semicolon separated commands
//
static MulleScionObject * NS_RETURNS_RETAINED  _parser_do_command_or_nothing( parser *p)
{
   MulleScionObject   *expr;
   unsigned char      c;
   
   parser_memorize( p, &p->memo_interesting);

   // skip semicolons
   for( ;;)
   {
      parser_skip_whitespace( p);
      c = parser_peek_character( p);
      if( c != ';')
         break;

      parser_skip_peeked_character( p, ';');
   }

   //
   // allow empty commands, i don't like parser_peek2_character
   // but couldn't think of something better
   //
   if( parser_peek_character( p) == '{')
   {
      if( parser_peek2_character( p) == '%')
         parser_error( p, "command nested within command");
      if( parser_peek2_character( p) == '#')
         parser_error( p, "comment nested within command");
   }
   
   if( parser_peek_character( p) == '%' && parser_peek2_character( p) == '}')
      return( nil);
   
   parser_skip_whitespace( p);
   expr = parser_do_command( p);
   
   if( p->environment & MULLESCION_DUMP_COMMANDS)
      fprintf( stderr, "%s\n", [[expr dumpDescription] cString]);
   return( expr);
}


static MulleScionObject * NS_RETURNS_RETAINED  _parser_do_commands( parser *p)
{
   MulleScionObject   *first;
   MulleScionObject   *expr;
   MulleScionObject   *next;
 
   expr = _parser_do_command_or_nothing( p);
   if( ! expr)
      return( expr);

   // commands like includes, extends, block, endblock can not be in multiline
   // statements (but requires can, but really shouldn't)
   
   if( [expr snarfsScion])
      return( expr);
   
   first = expr;
   while( next = _parser_do_command_or_nothing( p))
   {
      expr->next_ = next;

      // dial down the macro chain, if any
      while( next->next_)
         next = next->next_;
      
      expr = next;
   }
   return( first);
}


static MulleScionObject * NS_RETURNS_RETAINED  parser_do_commands( parser *p)
{
   MulleScionObject   *obj;

   assert( p->skipComments <= 0);
   
   p->skipComments++;
   obj = _parser_do_commands( p);
   p->skipComments--;
   return( obj);
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
   parser_next_character( p);  // laissez faire
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

      [owner appendRetainedObject:next];
      owner    = [next tail];
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
      parser_memorize( p, &p->memo_interesting);
      next = parser_do_expression_or_macro( p);
      parser_finish_expression( p);
      break;
      
   case command :
      parser_skip_whitespace( p);
      next = parser_do_commands( p);
      if( ! [next snarfsScion])
         parser_finish_command( p);
      if( ! next && p->inMacro)
         return( nil);  // endmacro ...
      if( [next isMacro])
         next = nil;
      break;
   }
   
   //
   // the problem, is that the analyzer thinks with NS_CONSUMED that the
   // object is dead, while we know it's alive
   //
   if( next)
   {
      if( ! p->first)
         p->first = next;
   
      [owner appendRetainedObject:next];  // analyzer mistake
      owner = [next tail];
   }
   return( owner);
}


# pragma mark -
# pragma mark External Interface (API)

- (void) parseData:(NSData *) data
     intoRootObject:(MulleScionObject *) root
            tables:(MulleScionParserTables *) tables
      ignoreErrors:(BOOL) ignoreErrors
{
   parser              parser;
   macro_type          last_type;

   parser_init( &parser, (void *) [data_ bytes], [data_ length]);
   parser_set_filename( &parser, fileName_);
   parser_set_blocks_table( &parser, tables->blockTable);
   parser_set_definitions_table( &parser, tables->definitionTable);
   parser_set_macro_table( &parser, tables->macroTable);
   parser_set_dependency_table( &parser, tables->dependencyTable);
   parser_set_error_callback( &parser, self, @selector( parser:errorInFileName:lineNumber:reason:));

   //
   // this make it possible to have scion templates as executable unix scripts
   // lets do this also on includes, because otherwise the output of the dox
   // looks funny. Well because they include it verbatim, they still look funny
   //   if( ! [self parent])
   //
   if( ! (parser.environment & MULLESCION_NO_HASHBANG))
      parser_skip_initial_hashbang_line_if_present( &parser);

   // useful to just run dependency, even if syntactically garbage
   if( ignoreErrors)
   {
      volatile MulleScionObject    *node;
      
      // reset environment to not talkative
      parser.environment &= MULLESCION_NO_HASHBANG | MULLESCION_VERBATIM_INCLUDE_HASHBANG;
      
      last_type = eof;
      node      = root;
      
retry:
NS_DURING
      while( node)
         node = parser_next_object( &parser, node, &last_type);
NS_HANDLER
      // skip to next %}
      parser.skipComments = 0;
      if( parser_skip_text_until_scion_end( &parser, '%') != eof)
      {
         while( node->next_)
            node = node->next_;
         
         goto retry;
      }
NS_ENDHANDLER
      return;
   }
   else
   {
      MulleScionObject    *node;
      
      last_type = eof;
      for( node = root; node; node = parser_next_object( &parser, node, &last_type));
   }
}


- (MulleScionTemplate *) templateParsedWithTables:(MulleScionParserTables *) tables
{
   MulleScionTemplate  *root;
   
   root = [[[MulleScionTemplate alloc] initWithFilename:[fileName_ lastPathComponent]] autorelease];
   
   [self parseData:data_
    intoRootObject:root
            tables:tables
      ignoreErrors:NO];
   
   return( root);
}


- (MulleScionTemplate *) templateWithContentsOfFile:(NSString *) fileName
                                             tables:(MulleScionParserTables *) tables
                                          converter:(SEL) converterSel
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
   
   if( getenv( "MULLESCION_DUMP_FILEPATHS"))
      fprintf( stderr, "parsing \"%s\"\n", [path fileSystemRepresentation]);
   
   /* run data through converter if needed */
   if( converterSel)
      data = [data performSelector:converterSel
                        withObject:nil];
   
   parser = [[[MulleScionParser alloc] initWithData:data
                                           fileName:path] autorelease];
   template = [parser templateParsedWithTables:tables];
   return( template);
}

@end
