//
//  HKManager.h
//  MyHealthKitProj
//
//  Created by Tereshkin Sergey on 10/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>

#define REQUEST_FALIED_WITH_ERROR   501
#define REQUEST_FALIED_NO_ERRORS    500
#define REQUEST_SUCCEEDED           200


#define HKSexNotSet -1
#define HKSexFemale 1
#define HKSexMale   0

typedef void(^myCompletion)(BOOL res);

@protocol HKManagerDelegate <NSObject>

- (void) requestSucceeded;
- (void) requestFailedWithError:(NSError *)error;
- (void) hkIsNotAvailable;

@end

@interface HKManager : NSObject

@property (strong, nonatomic) id<HKManagerDelegate> delegate;

+ (instancetype) sharedHKManager;
- (void) requestAccessWithDelegate:(id) delegate;

// read methods
- (NSDate *) getDateOfBirth;
- (int) getBiologicalSex;
- (void) getHeight:(void (^)(BOOL success, double weight, NSError *error))mCompletion;
- (void) getWeight:(void (^)(BOOL success, double weight, NSError *error))mCompletion;

// share methods
    // tests information
- (void) sharePeakExpiratoryFlowRate:(double)peakFlowPerMinute;
- (void) shareForcedExpiratoryVolume1:(double)forcedExpiratoryVolume1;

    // physical information
- (void) shareUsersHeight:(double)height_cm;
- (void) shareUsersWeight:(double)weight_kg;


@end
