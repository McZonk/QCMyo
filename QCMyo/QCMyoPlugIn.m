#import "QCMyoPlugIn.h"

#import <myo/libmyo.h>

typedef NS_ENUM(NSUInteger, QCMyoPlugInPairingMode)
{
	QCMyoPlugInPairingModeNone,
	QCMyoPlugInPairingModeAny,
	QCMyoPlugInPairingModeAdjacent,
	QCMyoPlugInPairingModeMacAddress,
};


@interface QCMyoPlugIn ()
{
	libmyo_hub_t hub;
	libmyo_myo_t myo;
	dispatch_queue_t queue;
	
	NSLock *outputValueLock;
}

@property (nonatomic, assign) QCMyoPlugInPairingMode pairingMode;
@property (nonatomic, copy) NSString *paringMacAddress;

@property (nonatomic, copy) NSString *trainingFilename;

@property (nonatomic, strong) NSNumber *paired;
@property (nonatomic, strong) NSNumber *connected;
@property (nonatomic, strong) NSNumber *trained;
@property (nonatomic, strong) NSString *macAddress;

@property (nonatomic, strong) NSNumber *orientationX;
@property (nonatomic, strong) NSNumber *orientationY;
@property (nonatomic, strong) NSNumber *orientationZ;
@property (nonatomic, strong) NSNumber *orientationW;

@property (nonatomic, strong) NSNumber *accelerometerX;
@property (nonatomic, strong) NSNumber *accelerometerY;
@property (nonatomic, strong) NSNumber *accelerometerZ;

@property (nonatomic, strong) NSNumber *gyroscopeX;
@property (nonatomic, strong) NSNumber *gyroscopeY;
@property (nonatomic, strong) NSNumber *gyroscopeZ;

@property (nonatomic, strong) NSNumber *pose;

@property (assign) BOOL stopRunning;

@end


@implementation QCMyoPlugIn

@dynamic inputPairingMode;
@dynamic inputPairingMacAddress;

@dynamic inputVibration;
@dynamic inputTrainingFilename;

@dynamic outputPaired;
@dynamic outputConnected;
@dynamic outputTrained;
@dynamic outputMacAddress;

@dynamic outputOrientationX;
@dynamic outputOrientationY;
@dynamic outputOrientationZ;
@dynamic outputOrientationW;

@dynamic outputAccelerometerX;
@dynamic outputAccelerometerY;
@dynamic outputAccelerometerZ;

@dynamic outputGyroscopeX;
@dynamic outputGyroscopeY;
@dynamic outputGyroscopeZ;

@dynamic outputPose;


+ (NSDictionary *)attributes
{
	return @{
		QCPlugInAttributeNameKey: @"Myo",
		QCPlugInAttributeDescriptionKey: @"Gesture detection and orientation handling for Myo.",
		QCPlugInAttributeCopyrightKey: @"© 2014 mczonk.de",
		QCPlugInAttributeCategoriesKey: @[
			@"Source",
			@"Source/Device",
		],
		QCPlugInAttributeExamplesKey: @[
			[NSURL URLWithString:@"http://developer.thalmic.com/"],
			[NSURL URLWithString:@"https://github.com/McZonk/QCMyo/"],
		],
	};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	if([key isEqualToString:@"inputPairingMode"])
	{
		return @{
			QCPortAttributeNameKey: @"Paring Mode",
			QCPortAttributeTypeKey: QCPortTypeIndex,
			QCPortAttributeMinimumValueKey: @0,
			QCPortAttributeMaximumValueKey: @3,
			QCPortAttributeMenuItemsKey: @[
				@"None",
				@"Any",
				@"Adjacent",
				@"Mac Address",
			],
		};
	}
	
	if([key isEqualToString:@"inputPairingMacAddress"])
	{
		return @{ QCPortAttributeNameKey: @"Pairing Mac Address" };
	}
	
	if([key isEqualToString:@"inputTrainingFilename"])
	{
		return @{ QCPortAttributeNameKey: @"Training Filename" };
	}
	
	if([key isEqualToString:@"inputVibration"])
	{
		return @{
			QCPortAttributeNameKey: @"Vibration",
			QCPortAttributeTypeKey: QCPortTypeIndex,
			QCPortAttributeMinimumValueKey: @0,
			QCPortAttributeMaximumValueKey: @3,
			QCPortAttributeMenuItemsKey: @[
				@"Off",
				@"Short",
				@"Medium",
				@"Long",
			],
		};
	}
	
	// status
	
	if([key isEqualToString:@"outputPaired"])
	{
		return @{ QCPortAttributeNameKey: @"Paired" };
	}
	if([key isEqualToString:@"outputConnected"])
	{
		return @{ QCPortAttributeNameKey: @"Connected" };
	}
	if([key isEqualToString:@"outputTrained"])
	{
		return @{ QCPortAttributeNameKey: @"Trained" };
	}
	if([key isEqualToString:@"outputMacAddress"])
	{
		return @{ QCPortAttributeNameKey: @"Mac Address" };
	}
	
	// orientation
	
	if([key isEqualToString:@"outputOrientationX"])
	{
		return @{ QCPortAttributeNameKey: @"Orientation X" };
	}
	if([key isEqualToString:@"outputOrientationY"])
	{
		return @{ QCPortAttributeNameKey: @"Orientation Y" };
	}
	if([key isEqualToString:@"outputOrientationZ"])
	{
		return @{ QCPortAttributeNameKey: @"Orientation Z" };
	}
	if([key isEqualToString:@"outputOrientationW"])
	{
		return @{ QCPortAttributeNameKey: @"Orientation W" };
	}
	
	// accelerometer
	
	if([key isEqualToString:@"outputAccelerometerX"])
	{
		return @{ QCPortAttributeNameKey: @"Accelerometer X" };
	}
	if([key isEqualToString:@"outputAccelerometerY"])
	{
		return @{ QCPortAttributeNameKey: @"Accelerometer Y" };
	}
	if([key isEqualToString:@"outputAccelerometerZ"])
	{
		return @{ QCPortAttributeNameKey: @"Accelerometer Z" };
	}
	
	// gyroscpe
	
	if([key isEqualToString:@"outputGyroscopeX"])
	{
		return @{ QCPortAttributeNameKey: @"Gyroscope X" };
	}
	if([key isEqualToString:@"outputGyroscopeY"])
	{
		return @{ QCPortAttributeNameKey: @"Gyroscope Y" };
	}
	if([key isEqualToString:@"outputGyroscopeZ"])
	{
		return @{ QCPortAttributeNameKey: @"Gyroscope Z" };
	}
	
	// pose
	
	if([key isEqualToString:@"outputPose"])
	{
		return @{
			QCPortAttributeNameKey: @"Pose",
			QCPortAttributeTypeKey: QCPortTypeIndex,
			QCPortAttributeMinimumValueKey: @0,
			QCPortAttributeMaximumValueKey: @(libmyo_num_poses-1),
			QCPortAttributeMenuItemsKey: @[
				@"Rest",
				@"Fist",
				@"Wave In",
				@"Wave Out",
				@"Fingers Spread",
				@"Twist In"
			],
		};
	}

	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode
{
	return kQCPlugInTimeModeIdle;
}

- (instancetype)init
{
	self = [super init];
	if(self != nil)
	{
		queue = dispatch_queue_create("Myo", DISPATCH_QUEUE_SERIAL);
		
		outputValueLock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL)startExecution:(id<QCPlugInContext>)context
{
	BOOL success = [self setupHubWithError:nil];
	
	return success;
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	[self shutdownHub];
}

- (void)enableExecution:(id<QCPlugInContext>)context
{

}

- (void)disableExecution:(id <QCPlugInContext>)context
{

}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	[outputValueLock lock];
	
	if([self didValueForInputKeyChange:@"inputPairingMacAddress"])
	{
		self.paringMacAddress = self.inputPairingMacAddress;
	}
	
	if([self didValueForInputKeyChange:@"inputPairingMode"])
	{
		self.pairingMode = self.inputPairingMode;
		
		[self pair];
	}

	if([self didValueForInputKeyChange:@"inputTrainingFilename"])
	{
		self.trainingFilename = self.inputTrainingFilename;
		
		[self loadTraining];
	}
	
	if([self didValueForInputKeyChange:@"inputVibration"])
	{
		switch(self.inputVibration)
		{
			case 1:
				[self vibrateWithType:libmyo_vibration_short];
				break;
				
			case 2:
				[self vibrateWithType:libmyo_vibration_medium];
				break;
				
			case 3:
				[self vibrateWithType:libmyo_vibration_long];
				break;
		}
	}
	
	// status
	
	NSNumber *paired = self.paired;
	if(paired != nil)
	{
		self.outputPaired = paired.boolValue;
		self.paired = nil;
	}
	NSNumber *connected = self.connected;
	if(connected != nil)
	{
		self.outputConnected = connected.boolValue;
		self.connected = nil;
	}
	NSNumber *trained = self.trained;
	if(trained != nil)
	{
		self.outputTrained = trained.boolValue;
		self.trained = nil;
	}
	NSString *macAddress = self.macAddress;
	if(macAddress != nil)
	{
		self.outputMacAddress = macAddress;
		self.macAddress = nil;
	}
	
	// orientation
	
	NSNumber *orientationX = self.orientationX;
	if(orientationX != nil)
	{
		self.outputOrientationX = orientationX.doubleValue;
		self.orientationX = nil;
	}
	NSNumber *orientationY = self.orientationY;
	if(orientationY != nil)
	{
		self.outputOrientationY = orientationY.doubleValue;
		self.orientationY = nil;
	}
	NSNumber *orientationZ = self.orientationZ;
	if(orientationZ != nil)
	{
		self.outputOrientationZ = orientationZ.doubleValue;
		self.orientationZ = nil;
	}
	NSNumber *orientationW = self.orientationW;
	if(orientationW != nil)
	{
		self.outputOrientationW = orientationW.doubleValue;
		self.orientationW = nil;
	}
	
	// accelerometer
	
	NSNumber *accelerometerX = self.accelerometerX;
	if(accelerometerX != nil)
	{
		self.outputAccelerometerX = accelerometerX.doubleValue;
		self.accelerometerX = nil;
	}
	NSNumber *accelerometerY = self.accelerometerY;
	if(accelerometerY != nil)
	{
		self.outputAccelerometerY = accelerometerY.doubleValue;
		self.accelerometerY = nil;
	}
	NSNumber *accelerometerZ = self.accelerometerZ;
	if(accelerometerZ != nil)
	{
		self.outputAccelerometerZ = accelerometerZ.doubleValue;
		self.accelerometerZ = nil;
	}
	
	// gyroscope
	
	NSNumber *gyroscopeX = self.gyroscopeX;
	if(gyroscopeX != nil)
	{
		self.outputGyroscopeX = gyroscopeX.doubleValue;
		self.gyroscopeX = nil;
	}
	NSNumber *gyroscopeY = self.gyroscopeY;
	if(gyroscopeY != nil)
	{
		self.outputGyroscopeY = gyroscopeY.doubleValue;
		self.gyroscopeY = nil;
	}
	NSNumber *gyroscopeZ = self.gyroscopeZ;
	if(gyroscopeZ != nil)
	{
		self.outputGyroscopeZ = gyroscopeZ.doubleValue;
		self.gyroscopeZ = nil;
	}
	
	// pose
	
	NSNumber *pose = self.pose;
	if(pose != nil)
	{
		self.outputPose = pose.unsignedIntegerValue;
		self.pose = nil;
	}
	
	[outputValueLock unlock];
	
	return YES;
}

#pragma mark - Myo

static libmyo_handler_result_t MyoHandler(void* userData, libmyo_event_t event)
{
	QCMyoPlugIn *self = (__bridge QCMyoPlugIn *)userData;
	[self handleEvent:event];
	
	return libmyo_handler_continue;
}

- (void)handleEvent:(libmyo_event_t)event
{
	dispatch_sync(queue, ^{
		libmyo_event_type_t type = libmyo_event_get_type(event);
		
		[outputValueLock lock];

		switch(type)
		{
			case libmyo_event_paired:
			{
				myo = libmyo_event_get_myo(event);
				
				self.paired = @YES;
				
				{
					uint64_t macAddress = libmyo_get_mac_address(myo);
					libmyo_string_t macAddressString = libmyo_mac_address_to_string(macAddress);
					self.macAddress = [NSString stringWithUTF8String:libmyo_string_c_str(macAddressString)];
					libmyo_string_free(macAddressString), macAddressString = NULL;
				}
				break;
			}
			
			case libmyo_event_connected:
			{
				self.connected = @YES;

				[self loadTraining];
				break;
			}
			
			case libmyo_event_disconnected:
			{
				self.trained = @NO;
				self.connected = @NO;
				self.paired = @NO;
				
				self.orientationX = @0.0;
				self.orientationY = @0.0;
				self.orientationZ = @0.0;
				self.orientationW = @0.0;

				self.accelerometerX = @0.0;
				self.accelerometerY = @0.0;
				self.accelerometerZ = @0.0;
				
				self.gyroscopeX = @0.0;
				self.gyroscopeY = @0.0;
				self.gyroscopeZ = @0.0;

				self.pose = @(libmyo_pose_rest);
				
				break;
			}
			
			case libmyo_event_orientation:
			{
				self.orientationX = @(libmyo_event_get_orientation(event, libmyo_orientation_x));
				self.orientationY = @(libmyo_event_get_orientation(event, libmyo_orientation_y));
				self.orientationZ = @(libmyo_event_get_orientation(event, libmyo_orientation_z));
				self.orientationW = @(libmyo_event_get_orientation(event, libmyo_orientation_w));
				
				self.accelerometerX = @(libmyo_event_get_accelerometer(event, 0));
				self.accelerometerY = @(libmyo_event_get_accelerometer(event, 1));
				self.accelerometerZ = @(libmyo_event_get_accelerometer(event, 2));

				self.gyroscopeX = @(libmyo_event_get_gyroscope(event, 0));
				self.gyroscopeY = @(libmyo_event_get_gyroscope(event, 1));
				self.gyroscopeZ = @(libmyo_event_get_gyroscope(event, 2));

				break;
			}
				
			case libmyo_event_pose:
			{
				self.pose = @(libmyo_event_get_pose(event));
				
				break;
			}
				
			default:
				NSLog(@"%s:%d:%d", __FUNCTION__, __LINE__, type);
				break;
		}

		[outputValueLock unlock];
	});
}

- (BOOL)setupHubWithError:(NSError **)error
{
	__block BOOL success = NO;
	dispatch_sync(queue, ^{
		libmyo_error_details_t error = NULL;
		libmyo_result_t result = libmyo_init_hub(&hub, &error);
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
		
		success = YES;
	});
	
	return success;
}

- (void)shutdownHub
{
	self.stopRunning = YES;
}

- (void)pair
{
	dispatch_async(queue, ^{
		if(myo == NULL)
		{
			[outputValueLock lock];
			
			switch(self.pairingMode)
			{
				case QCMyoPlugInPairingModeNone:
				{
					break;
				}
					
				case QCMyoPlugInPairingModeAny:
				{
					libmyo_error_details_t error = NULL;
					libmyo_result_t result = libmyo_pair_any(hub, 1, &error);
					if(result != libmyo_success)
					{
						NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
						libmyo_free_error_details(error), error = NULL;
					}
					break;
				}
					
				case QCMyoPlugInPairingModeAdjacent:
				{
					libmyo_error_details_t error = NULL;
					libmyo_result_t result = libmyo_pair_adjacent(hub, 1, &error);
					if(result != libmyo_success)
					{
						NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
						libmyo_free_error_details(error), error = NULL;
					}
					break;
				}
					
				case QCMyoPlugInPairingModeMacAddress:
				{
					uint64 macAddress = libmyo_string_to_mac_address(self.paringMacAddress.UTF8String);
					if(macAddress != 0)
					{
						libmyo_error_details_t error = NULL;
						libmyo_result_t result = libmyo_pair_by_mac_address(hub, macAddress, &error);
						if(result != libmyo_success)
						{
							NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
							libmyo_free_error_details(error), error = NULL;
						}
					}
					break;
				}
			}
			
			[outputValueLock unlock];
		}
	});
}

- (void)loadTraining
{
	dispatch_async(queue, ^{
		if(myo != NULL)
		{
			[outputValueLock lock];
			
			NSString *trainingFilename = self.trainingFilename;
			if(trainingFilename.length == 0)
			{
				trainingFilename = nil;
			}
			
			libmyo_error_details_t error = NULL;
			libmyo_result_t result = libmyo_training_load_profile(myo, trainingFilename.UTF8String, &error);
			if(result != libmyo_success)
			{
				NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
				libmyo_free_error_details(error), error = NULL;
				self.trained = @NO;
			}
			else
			{
				self.trained = @YES;
			}
			
			[outputValueLock unlock];
		}
	});
}

- (void)vibrateWithType:(libmyo_vibration_type_t)vibration
{
	dispatch_async(queue, ^{
		if(myo != NULL)
		{
			libmyo_error_details_t error = NULL;
			libmyo_result_t result = libmyo_vibrate(myo, vibration, &error);
			if(result != libmyo_success)
			{
				NSLog(@"%s:%d:ERROR %d %s", __FUNCTION__, __LINE__, result, libmyo_error_cstring(error));
				libmyo_free_error_details(error), error = NULL;
			}
		}
	});
}

@end
