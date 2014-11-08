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

typedef NS_ENUM(NSUInteger, MYOHubArm)
{
	MYOHubArmRight = libmyo_arm_right,
	MYOHubArmLeft = libmyo_arm_left,
	MYOHubArmUnknown = libmyo_arm_unknown,
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


extern NSString * const MYOHubDidPairNotification;
extern NSString * const MYOHubDidUnpairNotification;

extern NSString * const MYOHubDidConnectMyoNotification;
extern NSString * const MYOHubDidDisconnectMyoNotification;

extern NSString * const MYOHubDidArmDidChangeNotification;

extern NSString * const MYOHubArmKey;

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

extern NSString * const MYOHubPoseKey;


@interface MYOHub : NSObject

+ (instancetype)sharedHub;

- (BOOL)setupWithError:(NSError **)error;
- (BOOL)shutdown;

- (void)vibrateWithType:(MYOHubVibrationType)vibration;

@end
