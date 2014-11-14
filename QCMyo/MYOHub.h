//
//  MYOHub.h
//  QCMyo
//
//  Created by Maximilian Christ on 11/07/14.
//  Copyright (c) 2014 McZonk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <myo/libmyo.h>


typedef NS_ENUM(NSUInteger, MYOHubVibrationType)
{
	MYOHubVibrationTypeShort = libmyo_vibration_short,
	MYOHubVibrationTypeMedium = libmyo_vibration_medium,
	MYOHubVibrationTypeLong = libmyo_vibration_long,
};


extern NSString * const MYOHubDidPairNotification;
extern NSString * const MYOHubDidUnpairNotification;

extern NSString * const MYOHubDidConnectMyoNotification;
extern NSString * const MYOHubDidDisconnectMyoNotification;

extern NSString * const MYOHubDidArmDidChangeNotification;

extern NSString * const MYOHubArmNameKey;
extern NSString * const MYOHubArmNameValueRight;
extern NSString * const MYOHubArmNameValueLeft;

extern NSString * const MYOHubArmIndexKey;

extern NSString * const MYOHubXDirectionNameKey;
extern NSString * const MYOHubXDirectionNameValueTowardsWrist;
extern NSString * const MYOHubXDirectionNameValueTowardsElbow;

extern NSString * const MYOHubXDirectionIndexKey;

extern NSString * const MYOHubDidReceiveOrientationDataNotification;

extern NSString * const MYOHubOrientationXKey;
extern NSString * const MYOHubOrientationYKey;
extern NSString * const MYOHubOrientationZKey;
extern NSString * const MYOHubOrientationWKey;

extern NSString * const MYOHubAccelerometerDataXKey;
extern NSString * const MYOHubAccelerometerDataYKey;
extern NSString * const MYOHubAccelerometerDataZKey;

extern NSString * const MYOHubGyroscopeDataXKey;
extern NSString * const MYOHubGyroscopeDataYKey;
extern NSString * const MYOHubGyroscopeDataZKey;

extern NSString * const MYOHubDidRecognizePoseNotification;

extern NSString * const MYOHubPoseNameKey;

extern NSString * const MYOHubPoseIndexKey;

extern NSString * const MYOHubPoseValueRest;
extern NSString * const MYOHubPoseValueFist;
extern NSString * const MYOHubPoseValueWaveIn;
extern NSString * const MYOHubPoseValueWaveOut;
extern NSString * const MYOHubPoseValueFingersSpread;
extern NSString * const MYOHubPoseValueThumbToPinky;


@interface MYOHub : NSObject

+ (instancetype)sharedHub;

- (BOOL)setupWithError:(NSError **)error;
- (BOOL)shutdown;

- (void)vibrateWithType:(MYOHubVibrationType)vibration;

@end
