#import <Quartz/Quartz.h>


@interface QCMyoPlugIn : QCPlugIn

@property (assign) NSString *inputMacAddress;

@property (assign) BOOL outputPaired;
@property (assign) BOOL outputConnected;
@property (assign) BOOL outputTrained;

@property (assign) double outputOrientationX;
@property (assign) double outputOrientationY;
@property (assign) double outputOrientationZ;
@property (assign) double outputOrientationW;

@property (assign) NSUInteger outputPose;

@end
