#import "QCMyoPlugIn.h"

#import <myo/libmyo.h>


@interface QCMyoPlugIn ()
{
	libmyo_hub_t hub;
	dispatch_queue_t queue;
	
	NSLock *outputValueLock;
}

@property (nonatomic, strong) NSNumber *paired;
@property (nonatomic, strong) NSNumber *connected;
@property (nonatomic, strong) NSNumber *trained;

@property (nonatomic, strong) NSNumber *orientationX;
@property (nonatomic, strong) NSNumber *orientationY;
@property (nonatomic, strong) NSNumber *orientationZ;
@property (nonatomic, strong) NSNumber *orientationW;

@property (nonatomic, strong) NSNumber *pose;

@end


@implementation QCMyoPlugIn

@dynamic outputPaired;
@dynamic outputConnected;
@dynamic outputTrained;

@dynamic outputPose;

@dynamic outputOrientationX;
@dynamic outputOrientationY;
@dynamic outputOrientationZ;
@dynamic outputOrientationW;

+ (NSDictionary *)attributes
{
	return @{
		QCPlugInAttributeNameKey: @"Myo",
		QCPlugInAttributeDescriptionKey: @"Gesture detection and acceleration handling for Myo.",
		QCPlugInAttributeCopyrightKey: @"© 2013 Boinx Software Ltd."
	};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	if([key isEqualToString:@"inputMacAddress"])
	{
		return @{
			QCPortAttributeNameKey: @"Mac Address",
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
	// Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	[outputValueLock lock];
	
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
				self.paired = @YES;
				break;
			}
			
			case libmyo_event_connected:
			{
				self.connected = @YES;
				break;
			}
			
			case libmyo_event_disconnected:
			{
				self.connected = @NO;
				self.paired = @NO;
				break;
			}
			
			case libmyo_event_orientation:
			{
				self.orientationX = @(libmyo_event_get_orientation(event, libmyo_orientation_x));
				self.orientationY = @(libmyo_event_get_orientation(event, libmyo_orientation_y));
				self.orientationZ = @(libmyo_event_get_orientation(event, libmyo_orientation_z));
				self.orientationW = @(libmyo_event_get_orientation(event, libmyo_orientation_w));
				break;
			}
				
			case libmyo_event_pose:
			{
				self.pose = @(libmyo_event_get_pose(event));
				NSLog(@"POSE: %@", self.pose);
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
		libmyo_error_details_t error;
		libmyo_result_t result = libmyo_init_hub(&hub, &error);
		if(result != libmyo_success)
		{
			NSLog(@"%s:%d:%d", __FUNCTION__, __LINE__, result);
			success = NO;
			return;
		}
		
		result = libmyo_pair_any(hub, 1, &error);
		if(result != libmyo_success)
		{
			NSLog(@"%s:%d:%d", __FUNCTION__, __LINE__, result);
			success = NO;
			return;
		}
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			while(1)
			{
				libmyo_error_details_t error;
				libmyo_result_t result = libmyo_run(hub, 20, MyoHandler, (__bridge void *)self, &error);
				if(result != libmyo_success)
				{
					break;
				}
			}
		});
		
		success = YES;
	});
	
	return success;
}

- (void)shutdownHub
{
	dispatch_sync(queue, ^{
		if(hub != NULL)
		{
			libmyo_error_details_t error;
			libmyo_result_t result = libmyo_shutdown_hub(hub, &error);
			if(result != libmyo_success)
			{
				NSLog(@"%s:%d", __FUNCTION__, result);
			}
		}
	});
}

@end
