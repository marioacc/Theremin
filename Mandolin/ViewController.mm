//
//  ViewController.m
//  Mandolin
//
//  Created by Ariel Elkin on 28/12/2013.
//
//  Copyright (c) 2013 Bellpipe. All rights reserved.
//
//Modified by Carla Prieto and Mario Contreras on 23/11/2014
//Theremin
//Note this ViewController is wrote on Obejective-C++.


//Basic Imports:
#import "ViewController.h"
#import "AppDelegate.h"
//Core Motion:
#import <CoreMotion/CoreMotion.h>
//Amazing audio engine and STK instrument (BeeThree)
#import "BeeThree.h"
#import "AEBlockChannel.h"

@implementation ViewController {
    //Set Audio and STK's BeeThree:
    AEBlockChannel *myBeeThreeChannel;
    stk::BeeThree *myBeeThree;
    //Outlets (Debugging purpuses):
    IBOutlet UISlider *slider;//changes frecuency
    IBOutlet UILabel *x_acc;//Indicator
    IBOutlet UILabel *y_acc;//Indicator
    IBOutlet UILabel *z_acc;//Indicator
    //Declaring Motion Manager:
    CMMotionManager *manager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Audio Setup:
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    NSError *errorAudioSetup = NULL;
    BOOL result = [[appDelegate audioController] start:&errorAudioSetup];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", errorAudioSetup.localizedDescription);
    }

    stk::Stk::setRawwavePath([[[NSBundle mainBundle] pathForResource:@"rawwaves" ofType:@"bundle"] UTF8String]);
    
    myBeeThree = new stk::BeeThree();
    myBeeThree->setFrequency(400);
    
    myBeeThreeChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                           UInt32 frames,
                                                           AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {
            
            ((float*)audio->mBuffers[0].mData)[i] =
            ((float*)audio->mBuffers[1].mData)[i] = myBeeThree->tick();
            
        }
    }];
    
    [[appDelegate audioController] addChannels:@[myBeeThreeChannel]];
    
    //Motion Manager set up:
    manager = [[CMMotionManager alloc] init];
    manager.gyroUpdateInterval=.2;
    
    [manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        [self outputRotationData:gyroData.rotationRate];
                                    }];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getValues:) userInfo:nil repeats:YES];
    manager.accelerometerUpdateInterval = 0.05;  // 20 Hz
    [manager startAccelerometerUpdates];
}

-(void) outputRotationData:(CMRotationRate)rotation{
    self.rotX.text = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    
    self.rotY.text = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    
    self.rotZ.text = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    
}
//Motion Manager callback for polling acc data:
-(void) getValues:(NSTimer *) timer {
    x_acc.text = [NSString stringWithFormat:@"%.2f",manager.accelerometerData.acceleration.x];
    y_acc.text = [NSString stringWithFormat:@"%.2f",manager.accelerometerData.acceleration.y];
    z_acc.text = [NSString stringWithFormat:@"%.2f",manager.accelerometerData.acceleration.z];
   
}

- (IBAction)changeFrequency:(UISlider *)sender {
    myBeeThree->setFrequency(sender.value);
}
- (IBAction)PlayTheremin:(id)sender {
    myBeeThree->noteOn(slider.value, 0.5);
}
- (IBAction)StopTheremin:(id)sender {
    myBeeThree->noteOff(0.5);
}

@end
