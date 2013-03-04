//
//  MulleScionObjectModel+BlockExpansion.h
//  MulleScionTemplates
//
//  Created by Nat! on 01.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleScionObjectModel+Parsing.h"


@interface MulleScionObject ( BlockExpansion)

- (MulleScionObject *) ownerOfBlockWithIdentifier:(NSString *) identifier;
- (MulleScionObject *) nextOwnerOfBlockCommand;
- (void) replaceOwnedBlockWith:(MulleScionBlock *) NS_CONSUMED replacement;

@end


@interface MulleScionTemplate( BlockExpansion)

- (void) expandBlocksUsingTable:(NSDictionary *) table;

@end
