//
//  ViewController.m
//  MyHealthKitProj
//
//  Created by Tereshkin Sergey on 10/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "ViewController.h"
#import "HKManager.h"
#import "Validator.h"
#import "Patient.h"

@interface ViewController () <HKManagerDelegate>

@end

@implementation ViewController

// Units for various countries
// WEIGHT: kg - lbs
// HEIGHT: cm - in

//###################################################
//##                ViewMethods                    ##
//###################################################
#pragma mark ViewDidSomething

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationItem.rightBarButtonItem setTag:RIGHT_BTN_TAG_SAVE];
    [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    [self setTextfieldsEnabled:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //#######################################
    //#  Request access to health kit data  #
    //#######################################
    [[HKManager sharedHKManager] requestAccessWithDelegate:self];
    
}

//###############################################################
//####                   HKManagerDelegate                  #####
//###############################################################
#pragma mark HKManagerDelegate

-(void)requestSucceeded
{
    //###############################################################
    //##  Query methods are executed on background queue.          ##
    //##  If you need to update UI with received data, use:        ##
    //##  dispatch_async() with main queue                         ##
    //###############################################################
    
    int sex             = [[HKManager sharedHKManager] getBiologicalSex];
    NSDate *dateOfBirth = [[HKManager sharedHKManager] getDateOfBirth];
    
    // deliver result from background queue to ui
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // try to retrieve sex
        switch (sex)
        {
            case HKSexMale:
                [self.genderTf setText:@"Male"];
                [self setGender:GENDER_MALE];
                break;
                
            case HKSexFemale:
                [self.genderTf setText:@"Female"];
                [self setGender:GENDER_FEMALE];

                break;
                
            default:
                [self.genderTf setText:@""];
                [self setGender:-1];
                break;
        }
        
        // try to retrieve BIRTHDate
        if(dateOfBirth)
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"dd MMM yyyy"];
            
            [self setDateOfBirth:dateOfBirth];
            [self.birthDateTf setText:[formatter stringFromDate:dateOfBirth]];
        }
        else
        {
            [self.birthDateTf setText:@""];
        }
        
    });
    
    // query available HEIGHT
    
    /*
     the function getHeight has, as the argument mCompletion, the delegation to implement a completion block (of code) that is implemented here but is called later and asynchronusly by getHeigth itself.
     The code which implements mCompletion (running in a backgroud queue because linked to a healthkit quey method)  is nested into a dispatch_async block to allow its results to be written as quick as possible into the user interface (main queue).
     */
    
    [[HKManager sharedHKManager] getHeight:^(BOOL success, double height, NSError *error) {
        
        // deliver result from background queue to ui
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(success){
            
                if([Validator validateHeight:height] != nil)
                    return;
                
                [self setHeight:height];
                
                if(![Validator isMetricSystem])
                    [self.heightTf setText:[NSString stringWithFormat:@"%0.2f", (height / INCHES_NORMALIZER)]];
                else
                    [self.heightTf setText:[NSString stringWithFormat:@"%0.2f", height]];
            
                return;

            }else if(error){
                NSLog(@"sharedHKManager getHeight COMPLETION ERROR: %@", [error localizedDescription]);
            }else{
                NSLog(@"sharedHKManager getHeight COMPLETION ERROR");
            }
        
            
        });
        
    }];
    
    // query available WEIGHT
    
    /*
     the function getWeight has, as the argument mCompletion, the delegation to implement a completion block (of code)  that is implemented here but is called later and asynchronusly by getWeigth itself.
     The code which implements mCompletion  (running in a backgroud queue because linked to a healthkit quey method)  is nested into a dispatch_async block to allow its results to be written as quick as possible into the user interface (main queue).
     */
    
    [[HKManager sharedHKManager] getWeight:^(BOOL success, double weight, NSError *error) {
        
        // deliver result from background queue to ui
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(success){
            
                if([Validator validateHeight:weight] != nil)
                    return;
                
                [self setWeight:weight];
                
                if(![Validator isMetricSystem])
                    [self.weightTf setText:[NSString stringWithFormat:@"%.2f", (weight * LBS_NORMALIZER)]];
                else
                    [self.weightTf setText:[NSString stringWithFormat:@"%.2f", weight]];
            
                return;
            
            }else if(error){
                NSLog(@"sharedHKManager getWeight COMPLETION ERROR: %@", [error localizedDescription]);
            }else{
                NSLog(@"sharedHKManager getWeight COMPLETION ERROR");
            }

    
        });
        
    }];

}

-(void)requestFailedWithError:(NSError *)error
{
    NSLog(@"HKManager: failed to grant access");
}

-(void)hkIsNotAvailable
{
    NSLog(@"HKManager: HealthKit is not available on this device");
}

//#################################
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
