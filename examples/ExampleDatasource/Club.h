//
//  Club.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Liga;

@interface Club : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Liga *liga;

@end
