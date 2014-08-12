#import "QCMyoPlugIn.h"

#import "MYOHub.h"


@interface QCMyoPlugIn ()

@property (nonatomic, strong) MYOHub *hub;
@property (nonatomic, strong) id<NSLocking> lock;

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

@property (weak) id pairedObserver;
@property (weak) id trainedObserver;
@property (weak) id connectedObserver;
@property (weak) id disconnectObserver;
@property (weak) id orientationObserver;
@property (weak) id poseObserver;

@end


@implementation QCMyoPlugIn

@dynamic inputVibration;

@dynamic outputPaired;
@dynamic outputConnected;
@dynamic outputTrained;

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
				@"Thumb To Pinky"
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
		self.hub = [MYOHub sharedHub];

		self.lock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL)startExecution:(id<QCPlugInContext>)context
{
	MYOHub *hub = self.hub;
	
	BOOL success = [hub setupWithError:nil];
	if(success)
	{
		NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
		
		__weak typeof(self) weakSelf = self;
		self.pairedObserver = [notificationCenter addObserverForName:MYOHubDidPairNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.paired = @YES;
			[lock unlock];
		}];
		
		self.trainedObserver = [notificationCenter addObserverForName:MYOHubDidLoadTrainingProfileNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.trained = @YES;
			[lock unlock];
		}];

		self.connectedObserver = [notificationCenter addObserverForName:MYOHubDidConnectMyoNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.connected = @YES;
			[lock unlock];
		}];

		self.disconnectObserver = [notificationCenter addObserverForName:MYOHubDidDisconnectMyoNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.trained = @NO;
			self.connected = @NO;
			self.paired = @NO;
			[lock unlock];
		}];

		self.orientationObserver = [notificationCenter addObserverForName:MYOHubDidReceiveOrientationData object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			NSDictionary *userInfo = notification.userInfo;

			id<NSLocking> lock = self.lock;
			[lock lock];
			self.orientationX = userInfo[MYOHubOrientationXKey];
			self.orientationY = userInfo[MYOHubOrientationYKey];
			self.orientationZ = userInfo[MYOHubOrientationZKey];
			self.orientationW = userInfo[MYOHubOrientationWKey];
			[lock unlock];
		}];
		
		self.poseObserver = [notificationCenter addObserverForName:MYOHubDidRecognizePose object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;

			NSDictionary *userInfo = notification.userInfo;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.pose = userInfo[MYOHubPoseKey];
			[lock unlock];
		}];
	}
	return success;
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
	
	id pairedObserver = self.pairedObserver;
	[notificationCenter removeObserver:pairedObserver];
	
	id trainedObserver = self.trainedObserver;
	[notificationCenter removeObserver:trainedObserver];

	id connectedObserver = self.connectedObserver;
	[notificationCenter removeObserver:connectedObserver];

	id disconnectObserver = self.disconnectObserver;
	[notificationCenter removeObserver:disconnectObserver];

	id orientationObserver = self.orientationObserver;
	[notificationCenter removeObserver:orientationObserver];

	id poseObserver = self.poseObserver;
	[notificationCenter removeObserver:poseObserver];

	[self.hub shutdown];
}

- (void)enableExecution:(id<QCPlugInContext>)context
{

}

- (void)disableExecution:(id <QCPlugInContext>)context
{

}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	id<NSLocking> lock = self.lock;
	[lock lock];
	
	if([self didValueForInputKeyChange:@"inputVibration"])
	{
		MYOHubVibrationType vibrationType = self.inputVibration - 1;
		[self.hub vibrateWithType:vibrationType];
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
	
	[lock unlock];
	
	return YES;
}

@end
