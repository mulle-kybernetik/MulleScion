//
//  Liga.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Club;

@interface Liga : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *clubs;
@end

@interface Liga (CoreDataGeneratedAccessors)

- (void)addClubsObject:(Club *)value;
- (void)removeClubsObject:(Club *)value;
- (void)addClubs:(NSSet *)values;
- (void)removeClubs:(NSSet *)values;

@end
