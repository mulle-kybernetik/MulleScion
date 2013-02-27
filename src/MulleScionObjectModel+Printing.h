//
//  MulleScionObjectModel+Printing.h
//  MulleTwigLikeObjCTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel.h"

#import "MulleScionDataSourceProtocol.h"
#import "MulleScionOutputProtocol.h"



@interface MulleScionObject ( Printing)

- (MulleScionObject *) renderInto:(id <MulleScionOutput>) s
                   localVariables:(NSMutableDictionary *) locals
                       dataSource:(id <MulleScionDataSource>) dataSource;

@end


extern NSString   *MulleScionPrintFormatKey;
extern NSString   *MulleScionRenderOutputKey;
extern NSString   *MulleScionCurrentFileKey;
extern NSString   *MulleScionCurrentLineKey;
extern NSString   *MulleScionCurrentFunctionKey;

extern NSString   *MulleScionForOpenerKey;
extern NSString   *MulleScionForSeparatorKey;
extern NSString   *MulleScionForCloserKey;

extern NSString   *MulleScionEvenKey;
extern NSString   *MulleScionOddKey;