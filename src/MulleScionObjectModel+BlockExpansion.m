//
//  MulleScionObjectModel+BlockExpansion.m
//  MulleScionTemplates
//
//  Created by Nat! on 01.03.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import "MulleScionObjectModel+BlockExpansion.h"

#import "MulleScionObjectModel+NSCoding.h"


@implementation MulleScionObject ( BlockExpansion)

- (MulleScionObject *) nextOwnerOfBlockCommand
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
   {
      if( [curr->next_ isBlock])
         break;
      if( [curr->next_ isEndBlock])
         break;
   }
   return( curr);
}


- (MulleScionObject *) ownerOfBlockWithIdentifier:(NSString *) identifier
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
      if( [curr->next_ isBlock])
         if( [identifier isEqualToString:[(MulleScionBlock *) curr->next_ identifier]])
            break;
   return( curr);
}


// replacement must be copy
- (void) replaceOwnedBlockWith:(MulleScionBlock *) NS_CONSUMED replacement
{
   MulleScionBlock      *block;
   MulleScionObject     *endBlock;
   MulleScionObject     *replacementEnd;
   
   NSParameterAssert( [replacement isBlock]);
   NSParameterAssert( [self->next_ isBlock]);
   
   replacementEnd = [replacement tail];
   block          = (MulleScionBlock *) self->next_;
   endBlock       = [block terminateToEnd:block->next_];
   
   NSParameterAssert( [endBlock isEndBlock]);
   NSParameterAssert( [replacementEnd isEndBlock]);
   
   self->next_           = replacement;
   replacementEnd->next_ = endBlock->next_;
   endBlock->next_       = nil;
   
   [block release];
}

@end


@implementation MulleScionTemplate (BlockExpansion)

- (void) expandBlocksUsingTable:(NSDictionary *) table
{
   NSString           *identifier;
   MulleScionBlock    *block;
   MulleScionObject   *owner;
   MulleScionBlock    *chain;
   NSMutableArray     *stack;
   
   stack = [NSMutableArray array];
   
   owner = self;
   while( owner = [owner nextOwnerOfBlockCommand])
   {
      block = (MulleScionBlock *) owner->next_;
      if( [block isEndBlock])
      {
         [stack removeLastObject];
         owner = owner->next_;
         continue;
      }
      
      identifier = [block identifier];
      if( [stack containsObject:identifier])
         [NSException raise:NSInvalidArgumentException
                     format:@"%ld: block \"%@\" has already been expanded by (%@)",
          (long) [block lineNumber], identifier, [stack componentsJoinedByString:@", "]];
      [stack addObject:identifier];

      chain = [table objectForKey:identifier];
      if( ! chain)
      {
         owner = block;
         continue;
      }
      
      chain = [chain copyWithZone:NULL];
      [owner replaceOwnedBlockWith:chain];
      owner = chain;
   }
}

@end
