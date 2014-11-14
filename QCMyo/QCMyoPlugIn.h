#import <Quartz/Quartz.h>


@interface QCMyoPlugIn : QCPlugIn

@property (assign) NSUInteger inputVibration;

@property (assign) BOOL outputPaired;
@property (assign) BOOL outputConnected;

@property (assign) NSString *outputArmName;
@property (assign) NSUInteger outputArmIndex;
@property (assign) NSString *outputXDirectionName;
@property (assign) NSUInteger outputXDirectionIndex;

@property (assign) double outputOrientationX;
@property (assign) double outputOrientationY;
@property (assign) double outputOrientationZ;
@property (assign) double outputOrientationW;

@property (assign) double outputAccelerometerX;
@property (assign) double outputAccelerometerY;
@property (assign) double outputAccelerometerZ;

@property (assign) double outputGyroscopeX;
@property (assign) double outputGyroscopeY;
@property (assign) double outputGyroscopeZ;

@property (assign) NSString *outputPoseName;
@property (assign) NSUInteger outputPoseIndex;

@property (assign) double outputRSSI;

@end
