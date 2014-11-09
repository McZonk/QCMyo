#import "MYOHub.h"

#import <myo/libmyo.h>


NSString * const MYOHubDidPairNotification = @"MYOHubDidPairNotification";
NSString * const MYOHubDidUnpairNotification = @"MYOHubDidUnpairNotification";

NSString * const MYOHubDidConnectMyoNotification = @"MYOHubDidConnectMyoNotification";
NSString * const MYOHubDidDisconnectMyoNotification = @"MYOHubDidDisconnectMyoNotification";

NSString * const MYOHubDidArmDidChangeNotification = @"MYOHubDidArmDidChangeNotification";

NSString * const MYOHubArmKey = @"arm";

NSString * const MYOHubXDirectionKey = @"XDirection";

NSString * const MYOHubDidReceiveOrientationDataNotification = @"MYOHubDidReceiveOrientationDataNotification";

NSString * const MYOHubDidRecognizePoseNotification = @"MYOHubDidRecognizePoseNotification";

NSString * const MYOHubOrientationXKey = @"orientationX";
NSString * const MYOHubOrientationYKey = @"orientationY";
NSString * const MYOHubOrientationZKey = @"orientationZ";
NSString * const MYOHubOrientationWKey = @"orientationW";

NSString * const MYOHubAccelerometerDataXKey = @"accelerometerX";
NSString * const MYOHubAccelerometerDataYKey = @"accelerometerY";
NSString * const MYOHubAccelerometerDataZKey = @"accelerometerZ";

NSString * const MYOHubGyroscopeDataXKey = @"gyroscopeX";
NSString * const MYOHubGyroscopeDataYKey = @"gyroscopeY";
NSString * const MYOHubGyroscopeDataZKey = @"gyroscopeZ";

NSString * const MYOHubPoseKey = @"Pose";




@interface MYOHub ()
{
	dispatch_queue_t queue;
	
	libmyo_hub_t hub;
	libmyo_myo_t myo;
	
	NSUInteger usageCounter;
}

@property (assign) BOOL stopRunning;

- (void)handleEvent:(libmyo_event_t)event;

@end


static libmyo_handler_result_t MyoHandler(void* userData, libmyo_event_t event)
{
	MYOHub *self = (__bridge MYOHub *)userData;
	[self handleEvent:event];
	
	return libmyo_handler_continue;
}


@implementation MYOHub

+ (instancetype)sharedHub
{
	static MYOHub *hub = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		hub = [[MYOHub alloc] initWithError:nil];
	});
	
	return hub;
}

- (instancetype)initWithError:(NSError **)error
{
	self = [super init];
	if(self != nil)
	{
		queue = dispatch_queue_create("MyoHub", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (void)dealloc
{
	
}

#pragma mark - Myo

- (BOOL)setupWithError:(NSError **)error
{
	__block BOOL success = NO;
	
	dispatch_sync(queue, ^{
		if(usageCounter == 0)
		{
			libmyo_error_details_t error = NULL;
			libmyo_result_t result = libmyo_init_hub(&hub, "de.mczonk.QCMyo", &error);
			if(result != libmyo_success)
			{
				NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
				libmyo_free_error_details(error), error = NULL;
				return;
			}
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				while(!self.stopRunning)
				{
					libmyo_error_details_t error = NULL;
					libmyo_result_t result = libmyo_run(hub, 20, MyoHandler, (__bridge void *)self, &error);
					if(result != libmyo_success)
					{
						NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
						libmyo_free_error_details(error), error = NULL;
					}
				}
				
				dispatch_async(queue, ^{
					myo = NULL;
					
					if(hub != NULL)
					{
						libmyo_error_details_t error = NULL;
						libmyo_result_t result = libmyo_shutdown_hub(hub, &error);
						if(result != libmyo_success)
						{
							NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
							libmyo_free_error_details(error), error = NULL;
						}
						
						hub = NULL;
					}
					
					self.stopRunning = NO;
				});
			});
		}
		
		usageCounter += 1;
		success = YES;
	});
	
	return success;
}

- (BOOL)shutdown
{
	__block BOOL success = NO;
	
	dispatch_sync(queue, ^{
		if(usageCounter > 0)
		{
			usageCounter -= 1;
			
			if(usageCounter == 0)
			{
				self.stopRunning = YES;
			}
		}
	});
	
	return success;
}

- (void)vibrateWithType:(MYOHubVibrationType)vibration
{
	dispatch_async(queue, ^{
		if(myo != NULL)
		{
			libmyo_error_details_t error = NULL;
			libmyo_result_t result = libmyo_vibrate(myo, (libmyo_vibration_type_t)vibration, &error);
			if(result != libmyo_success)
			{
				NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
				libmyo_free_error_details(error), error = NULL;
			}
		}
	});
}

- (void)handleEvent:(libmyo_event_t)event
{
	dispatch_sync(queue, ^{
		libmyo_event_type_t type = libmyo_event_get_type(event);
		
		switch(type)
		{
			case libmyo_event_paired:
			{
				myo = libmyo_event_get_myo(event);
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidPairNotification object:self userInfo:nil];
				});
				
				break;
			}
				
			case libmyo_event_unpaired:
			{
				myo = NULL;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidUnpairNotification object:self userInfo:nil];
				});
				
				break;
			}
			
			case libmyo_event_connected:
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidConnectMyoNotification object:self userInfo:nil];
				});
				
				break;
			}
				
			case libmyo_event_disconnected:
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidDisconnectMyoNotification object:self userInfo:nil];
				});
				
				break;
			}
				
			case libmyo_event_arm_recognized:
			{
				libmyo_arm_t arm = libmyo_event_get_arm(event);
				libmyo_x_direction_t XDirection = libmyo_event_get_x_direction(event);
				
				NSDictionary *userInfo = @{
					MYOHubArmKey: @(arm),
					MYOHubXDirectionKey: @(XDirection),
				};

				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidArmDidChangeNotification object:self userInfo:userInfo];
				});
				
				break;
			}
				
			case libmyo_event_arm_lost:
			{
				NSDictionary *userInfo = @{
					MYOHubArmKey: @(MYOHubArmUnknown),
					MYOHubXDirectionKey: @(MYOHubXDirectionUnknown),
				};
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidArmDidChangeNotification object:self userInfo:userInfo];
				});
				
				break;
			}
				
			case libmyo_event_orientation:
			{
				float orientationX = libmyo_event_get_orientation(event, libmyo_orientation_x);
				float orientationY = libmyo_event_get_orientation(event, libmyo_orientation_y);
				float orientationZ = libmyo_event_get_orientation(event, libmyo_orientation_z);
				float orientationW = libmyo_event_get_orientation(event, libmyo_orientation_w);

				float accelerometerX = libmyo_event_get_accelerometer(event, 0);
				float accelerometerY = libmyo_event_get_accelerometer(event, 1);
				float accelerometerZ = libmyo_event_get_accelerometer(event, 2);

				float gyroscopeX = libmyo_event_get_gyroscope(event, 0);
				float gyroscopeY = libmyo_event_get_gyroscope(event, 1);
				float gyroscopeZ = libmyo_event_get_gyroscope(event, 2);

				dispatch_async(dispatch_get_main_queue(), ^{
					NSDictionary *orientationUserInfo = @{
						MYOHubOrientationXKey: @(orientationX),
						MYOHubOrientationYKey: @(orientationY),
						MYOHubOrientationZKey: @(orientationZ),
						MYOHubOrientationWKey: @(orientationW),
						MYOHubAccelerometerDataXKey: @(accelerometerX),
						MYOHubAccelerometerDataYKey: @(accelerometerY),
						MYOHubAccelerometerDataZKey: @(accelerometerZ),
						MYOHubGyroscopeDataXKey: @(gyroscopeX),
						MYOHubGyroscopeDataYKey: @(gyroscopeY),
						MYOHubGyroscopeDataZKey: @(gyroscopeZ),
					};
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidReceiveOrientationDataNotification object:self userInfo:orientationUserInfo];
				});
				
				break;
			}
				
			case libmyo_event_pose:
			{
				libmyo_pose_t pose = libmyo_event_get_pose(event);
				
				dispatch_async(dispatch_get_main_queue(), ^{
					NSDictionary *userInfo = @{
						MYOHubPoseKey: @(pose),
					};
					[NSNotificationCenter.defaultCenter postNotificationName:MYOHubDidRecognizePoseNotification object:self userInfo:userInfo];
				});
				
				break;
			}
				
			default:
				NSLog(@"%s:%d:%d", __FUNCTION__, __LINE__, type);
				break;
		}
	});
}

@end
