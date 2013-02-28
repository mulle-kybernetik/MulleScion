//
//  MulleScionObjectModel+VariableSubstitution.h
//  MulleScionTemplates
//
//  Created by Nat! on 28.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel.h"


@interface MulleScionMacro ( MacroExpansion)

- (NSDictionary *) parametersWithArguments:(NSArray *) arguments;
- (MulleScionTemplate *) expandedBodyWithParameters:(NSDictionary *) parameters;

@end


@interface MulleScionObject ( VariableSubstitution)

//
// will return nil, if the object itself needs not to be exchanged
// but may have changed internally! So operate on a copy!
//
- (id) replaceVariableWithIdentifier:(NSString *) identifier
                      withExpression:(MulleScionExpression *) expr  NS_RETURNS_RETAINED;


@end


