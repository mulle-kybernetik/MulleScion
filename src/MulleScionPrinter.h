//
//  MulleScionPrinter.h
//  MulleScionTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MulleScionObjectModel+Printing.h"


@class MulleScionTemplate;


@interface MulleScionPrinter : NSObject
{
   id                   dataSource_;
   NSMutableDictionary  *defaultlocals_;
}

- (id) initWithDataSource:(id) dataSource;

- (NSString *) describeWithTemplate:(MulleScionTemplate *) template;
- (void) writeToOutput:(id <MulleScionOutput>) output
              template:(MulleScionTemplate *) template;

- (NSDictionary *) defaultlocals;
- (void) setDefaultlocalVariables:(NSDictionary *) dictionary;


@end
