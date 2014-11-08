//
//  MYOHub.h
//  QCMyo
//
//  Created by Maximilian Christ on 11/07/14.
//  Copyright (c) 2014 McZonk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <myo/libmyo.h>


typedef NS_ENUM(NSUInteger, MYOHubPairingMode)
{
	MYOHubPairingModeAny,
	MYOHubPairingModeAdjacent,
	MYOHubPairingModeMacAddress,
};

typedef NS_ENUM(NSUInteger, MYOHubVibrationType)
{
	MYOHubVibrationTypeShort = libmyo_vibration_short,
	MYOHubVibrationTypeMedium = libmyo_vibration_medium,
	MYOHubVibrationTypeLong = libmyo_vibration_long,
};

typedef NS_ENUM(NSUInteger, MYOHubPose)
{
	MYOHubPoseRest = libmyo_pose_rest,
	MYOHubPoseFist = libmyo_pose_fist,
	MYOHubPoseWaveIn = libmyo_pose_wave_in,
	MYOHubPoseWaveOut = libmyo_pose_wave_out,
	MYOHubPoseFingersSpread = libmyo_pose_fingers_spread,
	MYOHubPoseThumbToPinky = libmyo_pose_thumb_to_pinky,
};


extern NSString * MYOHubDidPairNotification;
extern NSString * MYOHubDidUnpairNotification;

extern NSString * MYOHubDidConnectMyoNotification;
extern NSString * MYOHubDidDisconnectMyoNotification;

extern NSString * MYOHubDidReceiveOrientationData;
extern NSString * MYOHubDidReceiveAccelerometerData;
extern NSString * MYOHubDidReceiveGyroscopeData;

extern NSString * MYOHubDidRecognizePose;

extern NSString * MYOHubOrientationXKey;
extern NSString * MYOHubOrientationYKey;
extern NSString * MYOHubOrientationZKey;
extern NSString * MYOHubOrientationWKey;

extern NSString * MYOHubAccelerometerDataXKey;
extern NSString * MYOHubAccelerometerDataYKey;
extern NSString * MYOHubAccelerometerDataZKey;

extern NSString * MYOHubGyroscopeDataXKey;
extern NSString * MYOHubGyroscopeDataYKey;
extern NSString * MYOHubGyroscopeDataZKey;

extern NSString * MYOHubPoseKey;


@interface MYOHub : NSObject

+ (instancetype)sharedHub;

- (BOOL)setupWithError:(NSError **)error;
- (BOOL)shutdown;

- (void)vibrateWithType:(MYOHubVibrationType)vibration;

@end
