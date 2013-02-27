//
//  MulleScionObjectModel.h
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import"MulleObjCCompilerSettings.h"


//
// after template expansion a MulleScionObject won't be mutated
// by MulleScion
//
@interface MulleScionObject : NSObject
{
@public
   MulleScionObject  *next_;
@protected
   NSUInteger        lineNumber_;   // where the object was read from
}


+ (id) newWithLineNumber:(NSUInteger) nr;
- (id) initWithLineNumber:(NSUInteger) nr;
- (id) appendRetainedObject:(MulleScionObject *) NS_CONSUMED obj;

- (BOOL) isTemplate;
- (BOOL) isIdentifier;
- (BOOL) isTerminator;

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

- (Class) terminatorClass;

- (NSUInteger) lineNumber;

- (MulleScionObject *) ownerOfBlockWithIdentifier:(NSString *) identifier;
- (void) replaceOwnedBlockWith:(MulleScionObject *) replacement;
- (MulleScionObject *) nextOwnerOfBlock;

- (MulleScionObject *) tail;
- (NSUInteger) count;

@end


@interface MulleScionValueObject : MulleScionObject
{
   id    value_;         // convenient to serialize
}
@end


//
// these objects can appear a few times in a template tree structure
// they reset the fileName on occasion (for includes)
//
@interface MulleScionTemplate : MulleScionValueObject

- (id) initWithFilename:(NSString *) s;
- (void) expandBlocksUsingTable:(NSDictionary *) table;

@end


@interface MulleScionPlainText : MulleScionValueObject

+ (id) newWithRetainedString:(NSString *) NS_CONSUMED s
                  lineNumber:(NSUInteger) nr;

@end


@interface MulleScionExpression : MulleScionValueObject
@end


// if nil, it's nil...

@interface MulleScionNumber : MulleScionExpression

+ (id) newWithNumber:(NSNumber *) s
          lineNumber:(NSUInteger) nr;

@end


@interface MulleScionString : MulleScionExpression

+ (id) newWithString:(NSString *) s
          lineNumber:(NSUInteger) nr;

@end


@interface MulleScionArray : MulleScionExpression

+ (id) newWithArray:(NSArray *) s
         lineNumber:(NSUInteger) nr;

@end



@interface MulleScionVariable : MulleScionExpression

+ (id) newWithIdentifier:(NSString *) s
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;

@end


@interface MulleScionBinaryOperatorExpression : MulleScionExpression
{
   MulleScionExpression       *right_;
}

+ (id) newWithRetainedLeftExpression:(MulleScionExpression *) NS_CONSUMED left
             retainedRightExpression:(MulleScionExpression *) NS_CONSUMED right
                          lineNumber:(NSUInteger) nr;

- (NSString *) operator;

@end


@interface MulleScionPipe : MulleScionBinaryOperatorExpression
@end


// might go away, it's a kludge (for NSRange really)
@interface MulleScionDot : MulleScionBinaryOperatorExpression
@end


@interface MulleScionFunction : MulleScionExpression
{
   NSArray   *arguments_;
}

+ (id) newWithIdentifier:(NSString *) s
               arguments:(NSArray *) arguments
              lineNumber:(NSUInteger) nr;

@end



// like assignment, but prints if just in an expession
@interface MulleScionVariableAssigment : MulleScionExpression
{
   MulleScionExpression   *expression_;
}

+ (id) newWithIdentifier:(NSString *) identifier
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr;

@end



@interface MulleScionMethod : MulleScionExpression
{
   SEL       action_;
   NSArray   *arguments_;  // MulleScionValues
}

+ (id) newWithRetainedTarget:(MulleScionExpression *) NS_CONSUMED target
                  methodName:(NSString *) methodName
                   arguments:(NSArray *) arguments
                  lineNumber:(NSUInteger) nr;

@end



// commands do not print anything
@interface MulleScionCommand : MulleScionObject

- (NSString *) commandName;

- (MulleScionObject *) terminateToEnd:(MulleScionObject *) curr;
- (MulleScionObject *) terminateToElse:(MulleScionObject *) curr;

@end


@interface MulleScionTerminator : MulleScionCommand
@end



@interface MulleScionLet : MulleScionCommand
{
   NSString               *identifier_;
   MulleScionExpression   *expression_;
}

+ (id) newWithIdentifier:(NSString *) identifier
      retainedExpression:(MulleScionExpression *) NS_CONSUMED expr
              lineNumber:(NSUInteger) nr;
@end


// "for" is pretty much the same as an assignment, just looped
@interface MulleScionFor : MulleScionLet
@end


@interface MulleScionEndFor : MulleScionTerminator
@end


@interface MulleScionExpressionCommand : MulleScionCommand
{
   MulleScionExpression   *expression_;
}

+ (id) newWithRetainedExpression:(MulleScionExpression *) NS_CONSUMED expr
                      lineNumber:(NSUInteger) nr;
@end


@interface MulleScionIf : MulleScionExpressionCommand
@end


@interface MulleScionElse : MulleScionTerminator
@end


@interface MulleScionEndIf : MulleScionTerminator
@end


// "while" is pretty much the same as an 'if', just looped

@interface MulleScionWhile : MulleScionIf
@end


@interface MulleScionEndWhile : MulleScionTerminator
@end


@interface MulleScionBlock : MulleScionCommand
{
   NSString   *identifier_;
}

+ (id) newWithIdentifier:(NSString *) identifier
              lineNumber:(NSUInteger) nr;

- (NSString *) identifier;

@end


@interface MulleScionEndBlock : MulleScionTerminator
@end


@interface MulleScionMethodCall : MulleScionExpressionCommand
@end


@interface MulleScionFunctionCall : MulleScionExpressionCommand
@end


@interface MulleScionFilter : MulleScionExpressionCommand
@end


@interface MulleScionEndFilter : MulleScionTerminator
@end


