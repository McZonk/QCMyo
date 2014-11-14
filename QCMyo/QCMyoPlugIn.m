#import "QCMyoPlugIn.h"

#import "MYOHub.h"


@interface QCMyoPlugIn ()

@property (nonatomic, strong) MYOHub *hub;
@property (nonatomic, strong) id<NSLocking> lock;

@property (nonatomic, strong) NSNumber *paired;
@property (nonatomic, strong) NSNumber *connected;

@property (nonatomic, strong) NSString *armName;
@property (nonatomic, strong) NSNumber *armIndex;
@property (nonatomic, strong) NSString *XDirectionName;
@property (nonatomic, strong) NSNumber *XDirectionIndex;

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

@property (nonatomic, strong) NSString *poseName;
@property (nonatomic, strong) NSNumber *poseIndex;

@property (weak) id pairedObserver;
@property (weak) id unpairedObserver;
@property (weak) id connectedObserver;
@property (weak) id disconnectObserver;
@property (weak) id orientationObserver;
@property (weak) id armObserver;
@property (weak) id poseObserver;

@end


@implementation QCMyoPlugIn

@dynamic inputVibration;

@dynamic outputPaired;
@dynamic outputConnected;

@dynamic outputArmName;
@dynamic outputArmIndex;
@dynamic outputXDirectionName;
@dynamic outputXDirectionIndex;

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

@dynamic outputPoseName;
@dynamic outputPoseIndex;


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
	
	// arm
	
	if([key isEqualToString:@"outputArmName"])
	{
		return @{ QCPortAttributeNameKey: @"Arm Name" };
	}
	
	if([key isEqualToString:@"outputArmIndex"])
	{
		return @{ QCPortAttributeNameKey: @"Arm Index" };
	}
	
	if([key isEqualToString:@"outputXDirectionName"])
	{
		return @{ QCPortAttributeNameKey: @"X-Direction Name" };
	}

	if([key isEqualToString:@"outputXDirectionIndex"])
	{
		return @{ QCPortAttributeNameKey: @"X-Direction Index" };
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
	
	if([key isEqualToString:@"outputPoseName"])
	{
		return @{ QCPortAttributeNameKey: @"Pose Name" };
	}
	
	if([key isEqualToString:@"outputPoseIndex"])
	{
		return @{ QCPortAttributeNameKey: @"Pose Index" };
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
		
		self.unpairedObserver = [notificationCenter addObserverForName:MYOHubDidUnpairNotification object:hub queue:nil usingBlock:^(NSNotification *notifiction) {
			typeof(self) self = weakSelf;
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.paired = @NO;
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
			self.connected = @NO;
			[lock unlock];
		}];
		
		self.armObserver = [notificationCenter addObserverForName:MYOHubDidArmDidChangeNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;

			NSDictionary *userInfo = notification.userInfo;
			
			NSString *armName = userInfo[MYOHubArmNameKey];
			if(armName == nil)
			{
				armName = @"";
			}
			
			NSString *XDirectionName = userInfo[MYOHubXDirectionNameKey];
			if(XDirectionName == nil)
			{
				XDirectionName = @"";
			}
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.armName = armName;
			self.XDirectionName = XDirectionName;
			[lock unlock];
		}];

		self.orientationObserver = [notificationCenter addObserverForName:MYOHubDidReceiveOrientationDataNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;
			
			NSDictionary *userInfo = notification.userInfo;

			id<NSLocking> lock = self.lock;
			[lock lock];
			self.orientationX = userInfo[MYOHubOrientationXKey];
			self.orientationY = userInfo[MYOHubOrientationYKey];
			self.orientationZ = userInfo[MYOHubOrientationZKey];
			self.orientationW = userInfo[MYOHubOrientationWKey];
			self.accelerometerX = userInfo[MYOHubAccelerometerDataXKey];
			self.accelerometerY = userInfo[MYOHubAccelerometerDataYKey];
			self.accelerometerZ = userInfo[MYOHubAccelerometerDataZKey];
			self.gyroscopeX = userInfo[MYOHubGyroscopeDataXKey];
			self.gyroscopeY = userInfo[MYOHubGyroscopeDataYKey];
			self.gyroscopeZ = userInfo[MYOHubGyroscopeDataZKey];
			[lock unlock];
		}];
		
		self.poseObserver = [notificationCenter addObserverForName:MYOHubDidRecognizePoseNotification object:hub queue:nil usingBlock:^(NSNotification *notification) {
			typeof(self) self = weakSelf;

			NSDictionary *userInfo = notification.userInfo;
			
			NSString *poseName = userInfo[MYOHubPoseNameKey];
			if(poseName == nil)
			{
				poseName = @"";
			}
			
			NSNumber *poseIndex = userInfo[MYOHubPoseIndexKey];
			
			id<NSLocking> lock = self.lock;
			[lock lock];
			self.poseName = poseName;
			self.poseIndex = poseIndex;
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
	
	id unpairedObserver = self.unpairedObserver;
	[notificationCenter removeObserver:unpairedObserver];

	id connectedObserver = self.connectedObserver;
	[notificationCenter removeObserver:connectedObserver];

	id disconnectObserver = self.disconnectObserver;
	[notificationCenter removeObserver:disconnectObserver];

	id armObserver = self.armObserver;
	[notificationCenter removeObserver:armObserver];
	
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
	
	// arm
	
	NSString *armName = self.armName;
	if(armName != nil)
	{
		self.outputArmName = armName;
		self.armName = nil;
	}
	
	NSNumber *armIndex = self.armIndex;
	if(armIndex != nil)
	{
		self.outputArmIndex = armIndex.unsignedIntegerValue;
		self.armIndex = nil;
	}
	
	NSString *XDirectionName = self.XDirectionName;
	if(XDirectionName != nil)
	{
		self.outputXDirectionName = XDirectionName;
		self.XDirectionName = nil;
	}
	
	NSNumber *XDirectionIndex = self.XDirectionIndex;
	if(XDirectionIndex != nil)
	{
		self.outputXDirectionIndex = XDirectionIndex.unsignedIntegerValue;
		self.XDirectionIndex = nil;
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
	
	NSString *poseName = self.poseName;
	if(poseName != nil)
	{
		self.outputPoseName = poseName;
		self.poseName = nil;
	}
	
	NSNumber *poseIndex = self.poseIndex;
	if(poseIndex != nil)
	{
		self.outputPoseIndex = poseIndex.unsignedIntegerValue;
		self.poseIndex = nil;
	}
	
	[lock unlock];
	
	return YES;
}

@end
