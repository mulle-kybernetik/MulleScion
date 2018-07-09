//
//  MulleScionObjectModel.h
//  MulleScion
//
//  Created by Nat! on 24.02.13.
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


#import "import.h"
#import "MulleObjCCompilerSettings.h"


#ifndef MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY
# define MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY
#endif

#pragma mark -
//
// after template expansion a MulleScionObject won't be mutated
// by MulleScion
//
@interface MulleScionObject : NSObject
{
MULLE_SCION_OBJECT_NEXT_POINTER_VISIBILITY
   MulleScionObject  *next_;
@protected
   NSUInteger        lineNumber_;   // where the object was read from
}


+ (id) newWithLineNumber:(NSUInteger) nr;
- (id) initWithLineNumber:(NSUInteger) nr;

- (BOOL) isLexpr;

- (BOOL) isTemplate;
- (BOOL) isIdentifier;
- (BOOL) isTerminator;
- (BOOL) isFunction;
- (BOOL) isMethod;
- (BOOL) isParameterAssignment;  // not a set though

- (BOOL) isIf;
- (BOOL) isElse;
- (BOOL) isEndIf;

- (BOOL) isFor;
- (BOOL) isEndFor;

- (BOOL) isWhile;
- (BOOL) isEndWhile;

- (BOOL) isBlock;
- (BOOL) isEndBlock;

- (BOOL) isPipe;
- (BOOL) isDot;
- (BOOL) isIndexing;

- (BOOL) isJustALinefeed;
- (BOOL) isDictionaryKey;

- (BOOL) isMacro;

- (Class) terminatorClass;

- (NSUInteger) lineNumber;

@end


#pragma mark -
@interface MulleScionValueObject : MulleScionObject
{
   id    value_;         // convenient to serialize
}

- (id) value;

@end


#pragma mark -
//
// these objects can appear a few times in a template tree structure
// they reset the fileName on occasion (for includes)
//
@interface MulleScionTemplate : MulleScionValueObject

- (id) initWithFilename:(NSString *) s;
- (NSString *) fileName;

@end


#pragma mark -
@interface MulleScionPlainText : MulleScionValueObject

+ (id) newWithRetainedString:(NSString *) NS_CONSUMED s
                  lineNumber:(NSUInteger) nr;

- (BOOL) isJustALinefeed;

@end


#pragma mark -
@interface MulleScionExpression : MulleScionValueObject
@end


#pragma mark -
// if nil, you know it's nil...

@interface MulleScionNumber : MulleScionExpression

+ (id) newWithNumber:(NSNumber *) s
          lineNumber:(NSUInteger) nr;

@end

#pragma mark -

@interface MulleScionString : MulleScionExpression

+ (id) newWithString:(NSString *) s
          lineNumber:(NSUInteger) nr;

@end


#pragma mark -

@interface MulleScionSelector : MulleScionString
@end


#pragma mark -
@interface MulleScionArray : MulleScionExpression

+ (id) newWithArray:(NSArray *) s
         lineNumber:(NSUInteger) nr;

@end


#pragma mark -
@interface MulleScionDictionary : MulleScionExpression
   
+ (id) newWithDictionary:(NSDictionary *) s
              lineNumber:(NSUInteger) nr;
   
@end


#pragma mark -
@interface MulleScionIdentifierExpression : MulleScionExpression

+ (id) newWithIdentifier:(NSString *) s
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;

@end


#pragma mark -
@interface MulleScionVariable : MulleScionIdentifierExpression
@end


#pragma mark -
@interface MulleScionOperatorExpression : MulleScionExpression

- (NSString *) operator;

@end


#pragma mark -
@interface MulleScionUnaryOperatorExpression : MulleScionOperatorExpression

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED left
                      lineNumber:(NSUInteger) nr;
@end


#pragma mark -
@interface MulleScionNot  : MulleScionUnaryOperatorExpression
@end


#pragma mark -
@interface MulleScionBinaryOperatorExpression : MulleScionOperatorExpression
{
   MulleScionExpression   *right_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr;

- (MulleScionBinaryOperatorExpression *) hierarchicalExchange:(MulleScionBinaryOperatorExpression *) other;

@end


#pragma mark -
@interface MulleScionAnd  : MulleScionBinaryOperatorExpression
@end

#pragma mark -
@interface MulleScionOr   : MulleScionBinaryOperatorExpression
@end

#pragma mark -
@interface MulleScionPipe : MulleScionBinaryOperatorExpression
@end

#pragma mark -
@interface MulleScionIndexing : MulleScionBinaryOperatorExpression
@end


#pragma mark -

typedef enum
{
   MulleScionEqual,
   MulleScionNotEqual,
   MulleScionLessThan,
   MulleScionGreaterThan,
   MulleScionLessThanOrEqualTo,
   MulleScionGreaterThanOrEqualTo,
   MulleScionNoComparison = 0xFF
} MulleScionComparisonOperator;


@interface MulleScionComparison : MulleScionBinaryOperatorExpression
{
   MulleScionComparisonOperator  comparison_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          comparison:(MulleScionComparisonOperator) op
                          lineNumber:(NSUInteger) nr;
@end

#pragma mark -
// might go away, it's a kludge (for NSRange really)
@interface MulleScionDot : MulleScionBinaryOperatorExpression
@end

#pragma mark -

@interface MulleScionFunction : MulleScionIdentifierExpression
{
   NSArray   *arguments_;
}

+ (id) newWithIdentifier:(NSString *) s
               arguments:(NSArray *) arguments
              lineNumber:(NSUInteger) nr;

- (NSArray *) arguments;

@end

#pragma mark -

// is this really an expression ???
@interface MulleScionParameterAssignment : MulleScionIdentifierExpression
{
@public
   MulleScionExpression   *expression_;
}

+ (id) newWithIdentifier:(NSString *) identifier
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr;

- (MulleScionExpression *) expression;

@end


#pragma mark -
//
// used in if, while. NOT used in set/for and also not used as a
// subexpression
//
@interface MulleScionAssignmentExpression : MulleScionExpression
{
   MulleScionExpression   *right_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr;
@end


#pragma mark -
@interface MulleScionMethod : MulleScionExpression
{
   SEL       action_;
   NSArray   *arguments_;  // MulleScionValues
}

+ (id) newWithRetainedTarget:(MulleScionExpression *) NS_CONSUMED target
                  methodName:(NSString *) methodName
                   arguments:(NSArray *) arguments
                  lineNumber:(NSUInteger) nr;

- (BOOL) isSelfMethod;  // if

@end


#pragma mark -
//
@interface MulleScionConditional : MulleScionExpression
{
   MulleScionExpression   *middle_;
   MulleScionExpression   *right_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
            retainedMiddleExpression:(MulleScionExpression *) NS_CONSUMED middle
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr;
@end


#pragma mark -
//
// Commands do not print anything
//
@interface MulleScionCommand : MulleScionObject

- (NSString *) commandName;

- (MulleScionObject *) terminateToEnd:(MulleScionObject *) curr;
- (MulleScionObject *) terminateToElse:(MulleScionObject *) curr;

@end


#pragma mark -
@interface MulleScionTerminator : MulleScionCommand
@end



#pragma mark -
@interface MulleScionEndFor : MulleScionTerminator
@end


#pragma mark -
@interface MulleScionExpressionCommand : MulleScionCommand
{
   MulleScionExpression   *expression_;
}

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                      lineNumber:(NSUInteger) nr;

@end


#pragma mark -
@interface MulleScionLog : MulleScionExpressionCommand
@end


#pragma mark -
@interface MulleScionSet : MulleScionCommand
{
   MulleScionExpression   *left_;
   MulleScionExpression   *right_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr;

@end


#pragma mark -
// "for" is pretty much the same as an assignment, just looped
@interface MulleScionFor : MulleScionSet
@end

#pragma mark -

@interface MulleScionIf : MulleScionExpressionCommand
@end

#pragma mark -

@interface MulleScionElse : MulleScionTerminator
@end

#pragma mark -

@interface MulleScionElseFor : MulleScionElse
@end

#pragma mark -

@interface MulleScionEndIf : MulleScionTerminator
@end


#pragma mark -
// "while" is pretty much the same as an 'if', just looped

@interface MulleScionWhile : MulleScionIf
@end

#pragma mark -

@interface MulleScionEndWhile : MulleScionTerminator
@end

#pragma mark -

@interface MulleScionBlock : MulleScionCommand
{
   NSString   *identifier_;
   NSString   *fileName_;
}

+ (id) newWithIdentifier:(NSString *) identifier
                fileName:(NSString *) fileName
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;
- (NSString *) fileName;

@end

#pragma mark -

@interface MulleScionEndBlock : MulleScionTerminator
@end

#pragma mark -

@interface MulleScionMethodCall : MulleScionExpressionCommand
@end

#pragma mark -

@interface MulleScionFunctionCall : MulleScionExpressionCommand
@end


#pragma mark -

enum
{
   FilterPlaintext          = 0x1,
   FilterOutput              = 0x2,
   FilterApplyStackedFilters = 0x4
};


@interface MulleScionFilter : MulleScionExpressionCommand
{
   unsigned int   _flags;
}

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                           flags:(NSUInteger) flags
                      lineNumber:(NSUInteger) nr;
@end

#pragma mark -

@interface MulleScionEndFilter : MulleScionTerminator
@end

#pragma mark -

@interface MulleScionMacro : MulleScionTemplate
{
   NSString             *identifier_;
   MulleScionFunction   *function_;
   MulleScionTemplate   *body_;
}

+ (id) newWithIdentifier:(NSString *) s
                function:(MulleScionFunction *) function
                    body:(MulleScionTemplate *) body
                fileName:(NSString *) fileName
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;
- (MulleScionFunction *) function;
- (MulleScionTemplate *) body;

@end

#pragma mark -

@interface MulleScionRequires : MulleScionCommand
{
   NSString   *identifier_;
}

+ (id) newWithIdentifier:(NSString *) identifier
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;

@end

