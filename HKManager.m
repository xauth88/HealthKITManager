//
//  HKManager.m
//  MyHealthKitProj
//
//  Created by Tereshkin Sergey on 10/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "HKManager.h"
#import <HealthKit/HealthKit.h>

@interface HKManager ()

@property (strong, nonatomic) HKHealthStore *mHealthStore;
@property (strong, nonatomic) NSSet *shareDataTypes;
@property (strong, nonatomic) NSSet *readDataTypes;

@end

static HKManager *sharedManager;

@implementation HKManager

//#######################################
//############  Initialization     ######
//#######################################
#pragma mark Initialization

+ (instancetype) sharedHKManager
{
    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[HKManager alloc]init];
        }
    }
    return sharedManager;
}

- (void) generateDataTypes
{
    
    self.shareDataTypes = [NSSet setWithObjects:
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeakExpiratoryFlowRate],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedExpiratoryVolume1],
                           nil];
    
    self.readDataTypes = [NSSet setWithObjects:
                          [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                          [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                          [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                          [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                          nil];
}


//###############################################
//############  requestAccessWithDelegate  ######
//###############################################

- (void) requestAccessWithDelegate:(id) delegate
{

    [self setDelegate:delegate];
    
    if(!NSClassFromString(@"HKHealthStore") || ![HKHealthStore isHealthDataAvailable]){ [self.delegate hkIsNotAvailable]; return; }
    if(![self mHealthStore])
        [self setMHealthStore:[[HKHealthStore alloc]init]];
    
    [self generateDataTypes];
    [self.mHealthStore requestAuthorizationToShareTypes:self.shareDataTypes
                                              readTypes:self.readDataTypes
                                             completion:^(BOOL success, NSError *error) {
                                                 
        if(success){
            NSLog(@"HKManager SUCCEEDED: without errors");
            [self.delegate requestSucceeded];
            
        }else{
            NSLog(@"HKManager ERROR: %@", [error localizedDescription]);
            [self.delegate requestFailedWithError: error];
    
        }
        
    }];

}


//###############################################
//############      Read Values     #############
//###############################################
#pragma mark ReadHelthValues
// getBiologicalSex

- (int) getBiologicalSex
{
    NSError *error;
    HKBiologicalSexObject *bioSex = [self.mHealthStore biologicalSexWithError:&error];
    
    switch (bioSex.biologicalSex)
    {
            
        case HKBiologicalSexNotSet:
            NSLog(@"HKBiologicalSexNotSet");
            return HKSexNotSet;
        case HKBiologicalSexFemale:
            NSLog(@"HKBiologicalSexFemale");
            return HKSexFemale;
        case HKBiologicalSexMale:
            NSLog(@"HKBiologicalSexMale");
            return HKSexMale;

    }
    
    if(error)
        NSLog(@"HKManager ERROR: getBiologicalSex %@",[error localizedDescription]);
    
    return REQUEST_FALIED_NO_ERRORS;
}

// getDateOfBirth
- (NSDate *) getDateOfBirth
{
    NSError *error;
    NSDate *date = [self.mHealthStore dateOfBirthWithError:&error];
    
    if(error)
        NSLog(@"HKManager ERROR: getDateOfBirth %@",[error localizedDescription]);
    
    return date;
}

- (void) getHeight:(void (^)(BOOL success, double height, NSError *error))mCompletion
{
    /* who call this method is delageted to implement the "Function" mCompletion according to the "protocol" passed as argument.
     The call to mCompletion is then raised from here according to the local logic. The calling is performed in pure C style mCopmletion (X, Y, Z) .... no square brackets, no column (:) ....
     */
    
    HKSampleType        *sampleType         = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    NSPredicate         *predicate          = [HKQuery predicateForSamplesWithStartDate:nil endDate:nil options:HKQueryOptionStrictStartDate];
    NSSortDescriptor    *sortDescriptor     = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    /*
     the function initWithSampleType... has, in the argument "resultsHandler", the delegation to implement a function (a completion block) that is implemented here but is called later and asynchronusly by initWithSampleType... itself.
     */
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:1
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                if(!error && results && [results count] > 0){
                                                                        
                                                                    HKQuantitySample *height = [results objectAtIndex:0];
                                                                        
                                                                    double h = [[height quantity] doubleValueForUnit:[HKUnit unitFromString:@"cm"]];
                                                                        
                                                                    mCompletion(YES, h, nil);
                                                                        
                                                                }else if(error){
                                                                    mCompletion(NO, -1, error);
                                                                }else{
                                                                    mCompletion(NO, -1, nil);
                                                                }
                                                                
    }];
    
    // Execute the query
    [self.mHealthStore executeQuery:sampleQuery];
}

- (void) getWeight:(void (^)(BOOL success, double weight, NSError *error))mCompletion
{
    /* who call this method is delageted to implement the "function" mCompletion according to the "protocol" passed as argument.
     The call to mCompletion is then raised from here according to the local logic. The calling is performed in pure C style mCopmletion (X, Y, Z) .... no square brackets, no column (:) ....
     */
    
    HKSampleType        *sampleType         = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSPredicate         *predicate          = [HKQuery predicateForSamplesWithStartDate:nil endDate:nil options:HKQueryOptionNone];
    NSSortDescriptor    *sortDescriptor     = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    /*
     the function initWithSampleType... has, in the argument "resultsHandler", the delegation to implement a function (a completion block) that is implemented here but is called later and asynchronusly by initWithSampleType... itself.
     */
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:1
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                if(!error && results && [results count] > 0){
                                                                    
                                                                    HKQuantitySample *weight = [results objectAtIndex:0];
                                                                        
                                                                    double w = [[weight quantity] doubleValueForUnit:[HKUnit unitFromString:@"kg"]];
                                                                    
                                                                    mCompletion(YES, w, nil);
                                                                    
                                                                }else if(error){
                                                                    mCompletion(NO, -1, error);
                                                                }else{
                                                                    mCompletion(NO, -1, nil);
                                                                }
                                                                
    }];
    
    [self.mHealthStore executeQuery:sampleQuery];
    
}


//#######################################
//############  ShareHealthValues  ######
//#######################################
#pragma mark ShareHealthValues

// sharePeakExpiratoryFlowRate
- (void) sharePeakExpiratoryFlowRate:(double)peakFlowPerMinute
{
    HKUnit *litrPerMinuteUnit = [[HKUnit literUnit] unitDividedByUnit:[HKUnit minuteUnit]];

    NSDate          *now = [NSDate date];
    HKQuantityType  *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeakExpiratoryFlowRate];
    HKQuantity      *hkQuantity = [HKQuantity quantityWithUnit:litrPerMinuteUnit doubleValue:peakFlowPerMinute];
    
    // Create the concrete sample
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
                                                                     quantity:hkQuantity
                                                                    startDate:now
                                                                      endDate:now];
    
    // Update the weight in the health store
    [self.mHealthStore saveObject:weightSample
                   withCompletion:^(BOOL success, NSError *error) {
                       
                       if(success)
                           NSLog(@"PEAKFLOW updated");
                       
                       if(error)
                           NSLog(@"PEAKFLOW %@", [error localizedDescription]);
    }];
    
}

// shareForcedExpiratoryVolume1
- (void) shareForcedExpiratoryVolume1:(double)forcedExpiratoryVolume1
{

    NSDate          *now = [NSDate date];
    HKQuantityType  *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedExpiratoryVolume1];
    HKQuantity      *hkQuantity = [HKQuantity quantityWithUnit:[HKUnit literUnit]  doubleValue:forcedExpiratoryVolume1];
    
    // Create the concrete sample
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
                                                                     quantity:hkQuantity
                                                                    startDate:now
                                                                      endDate:now];
    
    // Update the weight in the health store
    [self.mHealthStore saveObject:weightSample
                   withCompletion:^(BOOL success, NSError *error) {
                       
                       if(success)
                           NSLog(@"PEAKFLOW updated");
                       
                       if(error)
                           NSLog(@"PEAKFLOW %@", [error localizedDescription]);
                   }];
    
}

// shareUsersHeight
- (void) shareUsersHeight:(double)height_cm
{
    
    NSDate          *now = [NSDate date];
    HKQuantityType  *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantity      *hkQuantity = [HKQuantity quantityWithUnit:[HKUnit meterUnit] doubleValue:height_cm];
    
    // Create the concrete sample
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
                                                                     quantity:hkQuantity
                                                                    startDate:now
                                                                      endDate:now];
    
    // Update the weight in the health store
    [self.mHealthStore saveObject:weightSample
                   withCompletion:^(BOOL success, NSError *error) {
                       
                       if(success)
                           NSLog(@"PEAKFLOW updated");
                       
                       if(error)
                           NSLog(@"PEAKFLOW %@", [error localizedDescription]);
                   }];
    
}

// shareUsersWeight
- (void) shareUsersWeight:(double)weight_kg
{
    
    NSDate          *now = [NSDate date];
    HKQuantityType  *hkQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantity      *hkQuantity = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"kg"] doubleValue:weight_kg];
    
    // Create the concrete sample
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:hkQuantityType
                                                                     quantity:hkQuantity
                                                                    startDate:now
                                                                      endDate:now];
    
    // Update the weight in the health store
    [self.mHealthStore saveObject:weightSample
                   withCompletion:^(BOOL success, NSError *error) {
                       
                       if(success)
                           NSLog(@"PEAKFLOW updated");
                       
                       if(error)
                           NSLog(@"PEAKFLOW %@", [error localizedDescription]);
                   }];
    
}

@end
